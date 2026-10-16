/**
 * Shared PocketBase + Keycloak OAuth popup and authentication storage helpers.
 *
 * Used by event-calendar and service-map to manage authentication lifecycle,
 * token persistence in localStorage, and port subscriptions.
 *
 * Starting up, pick one of two ways to refresh a stored token:
 *   - `resolveInitAuth` (blocking): refreshes before the Elm app starts, so the
 *     first render already has the fresh token or is signed out. No reload.
 *   - `getInitAuth` + `triggerBackgroundAuthRefresh`: start at once with the
 *     stored token and refresh afterwards; an invalid token reloads the page
 *     (or calls `onInvalidAuth`).
 *
 * Loading the PocketBase SDK: this file is reached through the vendored hub, where
 * a bare `import('pocketbase')` finds no SDK, and the apps pin different SDK
 * versions. So `options.PocketBase` (the class, for apps that import it
 * statically) or `options.loadPocketBase` (`() => import('pocketbase').then((m) =>
 * m.default)`, which keeps the SDK a lazy chunk) should be passed. Without either
 * the fallback is a bare `import('pocketbase')`.
 */

async function resolvePocketBase(options) {
  if (options.PocketBase) return options.PocketBase
  if (options.loadPocketBase) return options.loadPocketBase()
  return (await import('pocketbase')).default
}

function modelFromRecord(record) {
  return JSON.stringify({
    id: record.id,
    name: record.name || '',
    email: record.email || '',
  })
}

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
 * Blocking start-up auth: refreshes a stored token before the Elm app starts.
 *
 * - Success: stores and returns the refreshed token and model.
 * - 401/403: clears the stored auth and returns a signed-out result (no reload).
 * - Any other error (network down): keeps and returns the stored auth.
 *
 * @param {string} pbBaseUrl - PocketBase API endpoint URL
 * @param {object} [options] - `PocketBase` or `loadPocketBase`, see the file header
 * @returns {Promise<{authToken: string|null, authModel: string|null}>}
 */
export async function resolveInitAuth(pbBaseUrl, options = {}) {
  const stored = getInitAuth()
  if (!stored.authToken) return stored

  try {
    const PB = await resolvePocketBase(options)
    const pb = new PB(pbBaseUrl)
    pb.authStore.save(stored.authToken, null)
    const authData = await pb.collection('users').authRefresh()
    const refreshedModel = modelFromRecord(authData.record)
    saveStoredAuth(authData.token, refreshedModel)
    return { authToken: authData.token, authModel: refreshedModel }
  } catch (err) {
    if (isInvalidAuthError(err)) {
      clearStoredAuth()
      return { authToken: null, authModel: null }
    }
    console.warn('Auth refresh failed during app init, keeping stored auth:', err)
    return stored
  }
}

/**
 * Wires the standard Elm auth ports: initiateOAuth, getCallbackParams, saveAuthToken, clearAuthToken.
 *
 * @param {object} app - The initialized Elm application object with `ports`
 * @param {object} [options] - Configuration options:
 *   - PocketBase / loadPocketBase: how to get the SDK, see the file header
 *   - provider: OAuth provider name (defaults to 'oidc')
 */
export function wirePocketBaseAuthPorts(app, options = {}) {
  const providerName = options.provider || 'oidc'

  if (app.ports.initiateOAuth) {
    app.ports.initiateOAuth.subscribe(async (pbBaseUrl) => {
      try {
        const PB = await resolvePocketBase(options)
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
            model: modelFromRecord(authData.record),
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
 *   - PocketBase / loadPocketBase: how to get the SDK, see the file header
 *   - onInvalidAuth: callback when token is expired/invalid (defaults to reload)
 */
export function triggerBackgroundAuthRefresh(pbBaseUrl, initAuth, options = {}) {
  if (!initAuth || !initAuth.authToken) return

  setTimeout(async () => {
    try {
      const PB = await resolvePocketBase(options)
      const pb = new PB(pbBaseUrl)
      pb.authStore.save(initAuth.authToken, null)
      const authData = await pb.collection('users').authRefresh()
      const refreshedModel = modelFromRecord(authData.record)
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
