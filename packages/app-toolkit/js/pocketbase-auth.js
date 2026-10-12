/**
 * Shared PocketBase + Keycloak OAuth popup and authentication storage helpers.
 *
 * Used by event-calendar and service-map to manage authentication lifecycle,
 * token persistence in localStorage, and port subscriptions.
 */

export function readStoredAuth() {
  return {
    authToken: localStorage.getItem('pb_auth_token') || null,
    authModel: localStorage.getItem('pb_auth_model') || null,
  }
}

export function saveStoredAuth(token, model) {
  localStorage.setItem('pb_auth_token', token)
  localStorage.setItem('pb_auth_model', typeof model === 'string' ? model : JSON.stringify(model))
}

export function clearStoredAuth() {
  localStorage.removeItem('pb_auth_token')
  localStorage.removeItem('pb_auth_model')
}

export function isInvalidAuthError(err) {
  return err?.status === 401 || err?.status === 403
}

export function getInitAuth() {
  const stored = readStoredAuth()
  if (!stored.authToken || !stored.authModel) {
    return { authToken: null, authModel: null }
  }
  return stored
}

/**
 * Wires the standard Elm auth ports: initiateOAuth, getCallbackParams, saveAuthToken, clearAuthToken.
 *
 * @param {object} app - The initialized Elm application object with `ports`
 * @param {object} [options] - Configuration options:
 *   - PocketBase: PocketBase constructor (if pre-imported; otherwise dynamically imported)
 *   - provider: OAuth provider name (defaults to 'oidc')
 */
export function wirePocketBaseAuthPorts(app, options = {}) {
  const providerName = options.provider || 'oidc'

  if (app.ports.initiateOAuth) {
    app.ports.initiateOAuth.subscribe(async (pbBaseUrl) => {
      try {
        const PB = options.PocketBase || (await import('pocketbase')).default
        const pb = new PB(pbBaseUrl)

        const authMethods = await pb.collection('users').listAuthMethods()
        const provider = authMethods.oauth2.providers.find((p) => p.name === providerName)
        if (provider) {
          sessionStorage.setItem('pb_code_verifier', provider.codeVerifier)
          sessionStorage.setItem('pb_provider_state', provider.state)
        }

        const authData = await pb.collection('users').authWithOAuth2({ provider: providerName })
        if (app.ports.oauthPopupResult) {
          app.ports.oauthPopupResult.send({
            token: authData.token,
            model: JSON.stringify({
              id: authData.record.id,
              name: authData.record.name || '',
              email: authData.record.email || '',
            }),
          })
        }
      } catch (err) {
        console.error('OAuth2 login failed:', err)
        if (app.ports.oauthPopupResult) {
          app.ports.oauthPopupResult.send({ token: '', model: '{}' })
        }
      }
    })
  }

  if (app.ports.getCallbackParams) {
    app.ports.getCallbackParams.subscribe(() => {
      if (app.ports.callbackParams) {
        app.ports.callbackParams.send({
          codeVerifier: sessionStorage.getItem('pb_code_verifier') || '',
          state: sessionStorage.getItem('pb_provider_state') || '',
        })
      }
    })
  }

  if (app.ports.saveAuthToken) {
    app.ports.saveAuthToken.subscribe(({ token, model }) => {
      saveStoredAuth(token, model)
    })
  }

  if (app.ports.clearAuthToken) {
    app.ports.clearAuthToken.subscribe(() => {
      clearStoredAuth()
    })
  }
}

/**
 * Triggers a background auth refresh if a stored token exists.
 *
 * @param {string} pbBaseUrl - PocketBase API endpoint URL
 * @param {object} initAuth - Object with { authToken, authModel }
 * @param {object} [options] - Configuration options:
 *   - PocketBase: PocketBase constructor (if pre-imported)
 *   - onInvalidAuth: callback when token is expired/invalid (defaults to reload)
 */
export function triggerBackgroundAuthRefresh(pbBaseUrl, initAuth, options = {}) {
  if (!initAuth || !initAuth.authToken) return

  setTimeout(async () => {
    try {
      const PB = options.PocketBase || (await import('pocketbase')).default
      const pb = new PB(pbBaseUrl)
      pb.authStore.save(initAuth.authToken, null)
      const authData = await pb.collection('users').authRefresh()
      const refreshedModel = JSON.stringify({
        id: authData.record.id,
        name: authData.record.name || '',
        email: authData.record.email || '',
      })
      saveStoredAuth(authData.token, refreshedModel)
    } catch (err) {
      if (isInvalidAuthError(err)) {
        clearStoredAuth()
        if (options.onInvalidAuth) {
          options.onInvalidAuth()
        } else {
          window.location.reload()
        }
      } else {
        console.warn('Auth refresh failed during background check:', err)
      }
    }
  }, 0)
}
