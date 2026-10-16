# palikkaharrastajat/app-toolkit

Shared Elm app plumbing for Suomen Palikkaharrastajat ry applications (`event-calendar`, `service-map`, `planet`).

## Modules

- **`FinnishTime`**: Helsinki timezone conversion (EET/EEST, daylight saving transitions), date and time formatting and parsing in a given `Locale` (`formatShortDate`, `formatTime`, `formatFullDate`, `parseDate`, `formatDate`), form input converters, and 6×7 calendar month grid generation (`monthGrid`).
- **`Locale`**: a language's date and time conventions (month and weekday names, separators, date input placeholder); `fi`, `en` and `forCode`. Tested against `packages/site-config/locales.json`.
- **`PocketBaseAuth`**: `AuthState`/`AuthUser` with `isAuthenticated` and `getToken`; msg-polymorphic OAuth2 token exchange (`fetchOAuthToken`, `fetchOAuthUser`); auth state restoration from flags (`restoreAuthFromFlags`); user decoding and encoding (`decodeAuthUser`, `encodeAuthUser`, `authUserModelJson`); the sign-in popup result (`userFromPopupResult`); and the `#/callback?code=&state=` redirect (`callbackQuery`, `callbackRedirectUrl`). Error messages and the `state` check stay in the app, which owns the texts and the update loop.
- **`View.MapOverlay`**: Responsive, accessible overlays for interactive maps without inline styles (`panel`, `filterGroup`, `detailPanel`, `detailPanelWithHeaderActions`).
- **`View.MapWidget`**: Container element for Leaflet and MapLibre map initialization.
- **`View.Icons`**: Accessible Feather icon renderer (`featherIcon`) with `aria-hidden="true"` and `focusable="false"`.
- **`Geocoding`**: OpenStreetMap / Nominatim geocoding and reverse geocoding API clients.

## PocketBase Auth Ports

Elm packages cannot define ports directly. Consuming applications define the following port signatures in their app-local `Ports.elm`:

```elm
port initiateOAuth : String -> Cmd msg
port saveAuthToken : { token : String, model : String } -> Cmd msg
port clearAuthToken : () -> Cmd msg
port getCallbackParams : () -> Cmd msg
port callbackParams : ({ codeVerifier : String, state : String } -> msg) -> Sub msg
port oauthPopupResult : ({ token : String, model : String } -> msg) -> Sub msg
```

### JavaScript Helper

`packages/app-toolkit/js/pocketbase-auth.js` provides ready-to-use helpers to wire these ports and handle token caching in `localStorage` (`pb_auth_token`, `pb_auth_model`). Import it through the app's vendored hub; its tests are in `pocketbase-auth.test.mjs`.

**Loading PocketBase.** The file lives in the hub, which has no PocketBase SDK, and the apps pin different SDK versions, so pass the SDK in: `PocketBase` (the class, when the app imports it statically) or `loadPocketBase` (`() => import('pocketbase').then((m) => m.default)`, which keeps the SDK a lazy chunk). Without either, a bare `import('pocketbase')` is tried.

**Refreshing a stored token at start-up** has two variants:

- `resolveInitAuth(pbBaseUrl, options)` blocks: it refreshes before the Elm app starts. A refreshed token goes into the flags; a 401/403 clears the storage and starts signed out (no reload); a network error keeps the stored token.
- `getInitAuth()` + `triggerBackgroundAuthRefresh(pbBaseUrl, initAuth, options)` start at once with the stored token and refresh afterwards; a 401/403 clears the storage and reloads the page (or calls `options.onInvalidAuth`).

```javascript
import PocketBase from 'pocketbase'
import {
  resolveInitAuth,
  wirePocketBaseAuthPorts,
} from './packages/app-toolkit/js/pocketbase-auth.js'

const initAuth = await resolveInitAuth(pbBaseUrl, { PocketBase })
const app = Elm.Main.init({ node, flags: { ...initAuth, pbBaseUrl } })

wirePocketBaseAuthPorts(app, { PocketBase })
```

The background variant, with a lazy SDK:

```javascript
import {
  getInitAuth,
  wirePocketBaseAuthPorts,
  triggerBackgroundAuthRefresh,
} from './packages/app-toolkit/js/pocketbase-auth.js'

const loadPocketBase = () => import('pocketbase').then((m) => m.default)
const initAuth = getInitAuth()
const app = Elm.Main.init({ node, flags: { ...initAuth, pbBaseUrl } })

wirePocketBaseAuthPorts(app, { loadPocketBase })
triggerBackgroundAuthRefresh(pbBaseUrl, initAuth, { loadPocketBase })
```

`initiateOAuth` also stores the PKCE `codeVerifier` and `state` in `sessionStorage`, for the `#/callback` redirect path (`getCallbackParams` reads them back).

## Focus Management (`focusElement` Port Pattern)

For accessible focus transitions when opening and closing panels (such as `View.MapOverlay.detailPanel` or mobile drawers), apps use a `focusElement` port:

```elm
port focusElement : String -> Cmd msg
```

JavaScript subscriber implementation in `main.js`:

```javascript
app.ports.focusElement.subscribe(function (id) {
  requestAnimationFrame(function () {
    const el = document.getElementById(id)
    if (el) {
      const target = el.matches('button, a, input, select, textarea, [tabindex]')
        ? el
        : (el.querySelector('button, a, input, select, textarea, [tabindex]') || el)
      target.focus({ focusVisible: true })
    }
  })
})
```

`View.MapOverlay.detailPanel` assigns `id="map-detail-panel"` to the container and `id="map-detail-close"` to the close button. When opening the detail panel (e.g. on marker click), dispatch `Ports.focusElement "map-detail-close"` so keyboard focus lands inside the panel immediately, allowing the built-in Escape key listener and close button to be operated by keyboard users.


## Non-Unified Modules (`Api`, `Route`, `I18n`)

The following modules remain intentionally application-specific and are **not** unified into `app-toolkit`:

1. **`Api`**: Each application defines unique PocketBase collections, query expand parameters, filters, and domain record schemas (`Event`, `Location`, `FeedItem`).
2. **`Route`**: URL structures and hash-routing variants are unique to each app's page hierarchy.
3. **`I18n`**: Localized translation keys and vocabularies are tailored to the distinct domain concepts of each app.
