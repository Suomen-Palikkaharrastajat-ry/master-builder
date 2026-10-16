/**
 * Shared PocketBase OAuth2 popup sign-in and authentication storage helpers.
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
 * Sign-in is PocketBase's popup flow (`authWithOAuth2`): the popup returns to
 * `<pocketbase>/api/oauth2-redirect` and the result arrives over PocketBase's
 * realtime connection. The app's own `#/callback` route is never involved.
 * Safari only allows the popup inside the click, so `initiateOAuth` calls
 * `authWithOAuth2` synchronously from the port callback, with nothing awaited
 * before it.
 *
 * Loading the PocketBase SDK: this file is reached through the vendored hub, and
 * the apps pin different SDK versions, so the app must pass either
 * `options.PocketBase` (the class, for apps that import it statically) or
 * `options.loadPocketBase` (`() => import('pocketbase').then((m) => m.default)`,
 * which keeps the SDK a lazy chunk). Passing neither throws an error.
 */

async function resolvePocketBase(options) {
  if (options.PocketBase) return options.PocketBase
  if (options.loadPocketBase) return options.loadPocketBase()
  throw new Error('pocketbase-auth: pass PocketBase or loadPocketBase in the options')
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
 * With `loadPocketBase` the SDK starts loading at once, so that the sign-in
 * click can call `authWithOAuth2` synchronously. If the click comes before the
 * SDK has loaded, sign-in waits for it, and Safari may then block the popup.
 *
 * `getCallbackParams` is legacy: sign-in no longer stores a code verifier or
 * state, so it answers with empty strings.
 *
 * @param {object} app - The initialized Elm application object with `ports`
 * @param {object} [options] - Configuration options:
 *   - PocketBase / loadPocketBase: how to get the SDK, see the file header
 *   - provider: OAuth provider name (defaults to 'oidc')
 */
export function wirePocketBaseAuthPorts(app, options = {}) {
  const providerName = options.provider || 'oidc'

  let PB = options.PocketBase || null
  let loading = null

  function load() {
    if (!loading) {
      loading = resolvePocketBase(options).then(
        (cls) => (PB = cls),
        (err) => {
          loading = null // a later sign-in retries
          throw err
        },
      )
    }
    return loading
  }

  // Eager load; a failure is reported at the first sign-in.
  if (!PB && options.loadPocketBase) load().catch(() => {})

  function sendFailure(err) {
    console.error('OAuth2 login failed:', err)
    if (app.ports.oauthPopupResult) {
      app.ports.oauthPopupResult.send({ token: '', model: '{}' })
    }
  }

  async function signIn(Class, pbBaseUrl) {
    try {
      const pb = new Class(pbBaseUrl)
      // No await before this call: it opens the popup, which must happen inside the click.
      const authData = await pb.collection('users').authWithOAuth2({ provider: providerName })
      if (app.ports.oauthPopupResult) {
        app.ports.oauthPopupResult.send({
          token: authData.token,
          model: modelFromRecord(authData.record),
        })
      }
    } catch (err) {
      sendFailure(err)
    }
  }

  if (app.ports.initiateOAuth) {
    app.ports.initiateOAuth.subscribe((pbBaseUrl) => {
      if (PB) return signIn(PB, pbBaseUrl)
      // Rare path: the SDK is not loaded yet, so the popup may be blocked on Safari.
      return load().then((cls) => signIn(cls, pbBaseUrl), sendFailure)
    })
  }

  if (app.ports.getCallbackParams) {
    // Legacy (see above): kept so apps that still subscribe get an answer.
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
