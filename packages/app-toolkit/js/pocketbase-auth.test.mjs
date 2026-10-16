import { test, beforeEach } from 'node:test'
import assert from 'node:assert/strict'
import {
  getInitAuth,
  resolveInitAuth,
  triggerBackgroundAuthRefresh,
  wirePocketBaseAuthPorts,
} from './pocketbase-auth.js'

function memoryStorage() {
  const m = new Map()
  return {
    getItem: (k) => (m.has(k) ? m.get(k) : null),
    setItem: (k, v) => void m.set(k, String(v)),
    removeItem: (k) => void m.delete(k),
    has: (k) => m.has(k),
  }
}

let reloads
let warnings

beforeEach(() => {
  globalThis.localStorage = memoryStorage()
  globalThis.sessionStorage = memoryStorage()
  reloads = 0
  globalThis.window = { location: { reload: () => void reloads++ } }
  warnings = []
  console.warn = (...a) => void warnings.push(a)
  console.error = () => {}
})

/** Fake PocketBase class. `behaviour` decides what authRefresh/authWithOAuth2 do. */
function fakePocketBase(behaviour = {}) {
  const calls = { saved: [], urls: [], authMethods: 0 }
  class FakePB {
    constructor(url) {
      calls.urls.push(url)
      this.authStore = { save: (token, model) => calls.saved.push([token, model]) }
    }
    collection() {
      return {
        authRefresh: async () => {
          if (behaviour.refreshError) throw behaviour.refreshError
          return { token: 'new-token', record: { id: 'u1', name: 'Alice', email: 'a@x.fi' } }
        },
        listAuthMethods: async () => {
          calls.authMethods++
          return { oauth2: { providers: [{ name: 'oidc', codeVerifier: 'ver', state: 'st' }] } }
        },
        authWithOAuth2: async () => {
          if (behaviour.oauthError) throw behaviour.oauthError
          return { token: 'oauth-token', record: behaviour.record ?? { id: 'u2', name: 'Bob', email: 'b@x.fi' } }
        },
      }
    }
  }
  return { FakePB, calls }
}

function fakeApp() {
  const handlers = {}
  const sent = { oauthPopupResult: [], callbackParams: [] }
  const port = (name) => ({ subscribe: (fn) => (handlers[name] = fn) })
  return {
    handlers,
    sent,
    ports: {
      initiateOAuth: port('initiateOAuth'),
      getCallbackParams: port('getCallbackParams'),
      saveAuthToken: port('saveAuthToken'),
      clearAuthToken: port('clearAuthToken'),
      oauthPopupResult: { send: (v) => sent.oauthPopupResult.push(v) },
      callbackParams: { send: (v) => sent.callbackParams.push(v) },
    },
  }
}

const httpError = (status) => Object.assign(new Error('http'), { status })

test('getInitAuth returns nulls unless both keys are stored', () => {
  assert.deepEqual(getInitAuth(), { authToken: null, authModel: null })
  localStorage.setItem('pb_auth_token', 't')
  assert.deepEqual(getInitAuth(), { authToken: null, authModel: null })
  localStorage.removeItem('pb_auth_token')
  localStorage.setItem('pb_auth_model', '{}')
  assert.deepEqual(getInitAuth(), { authToken: null, authModel: null })
  localStorage.setItem('pb_auth_token', 't')
  assert.deepEqual(getInitAuth(), { authToken: 't', authModel: '{}' })
})

test('resolveInitAuth without stored auth does not load PocketBase', async () => {
  const result = await resolveInitAuth('http://pb', {
    loadPocketBase: () => assert.fail('should not load'),
  })
  assert.deepEqual(result, { authToken: null, authModel: null })
})

test('resolveInitAuth success stores and returns the refreshed token', async () => {
  localStorage.setItem('pb_auth_token', 'old')
  localStorage.setItem('pb_auth_model', '{"id":"u1"}')
  const { FakePB, calls } = fakePocketBase()
  const result = await resolveInitAuth('http://pb', { PocketBase: FakePB })
  const model = '{"id":"u1","name":"Alice","email":"a@x.fi"}'
  assert.deepEqual(result, { authToken: 'new-token', authModel: model })
  assert.equal(localStorage.getItem('pb_auth_token'), 'new-token')
  assert.equal(localStorage.getItem('pb_auth_model'), model)
  assert.deepEqual(calls.urls, ['http://pb'])
  assert.deepEqual(calls.saved, [['old', null]])
})

for (const status of [401, 403]) {
  test(`resolveInitAuth ${status} clears storage without reloading`, async () => {
    localStorage.setItem('pb_auth_token', 'old')
    localStorage.setItem('pb_auth_model', '{"id":"u1"}')
    const { FakePB } = fakePocketBase({ refreshError: httpError(status) })
    const result = await resolveInitAuth('http://pb', { PocketBase: FakePB })
    assert.deepEqual(result, { authToken: null, authModel: null })
    assert.equal(localStorage.has('pb_auth_token'), false)
    assert.equal(localStorage.has('pb_auth_model'), false)
    assert.equal(reloads, 0)
  })
}

test('resolveInitAuth keeps stored auth on a network error', async () => {
  localStorage.setItem('pb_auth_token', 'old')
  localStorage.setItem('pb_auth_model', '{"id":"u1"}')
  const { FakePB } = fakePocketBase({ refreshError: new TypeError('fetch failed') })
  const result = await resolveInitAuth('http://pb', { PocketBase: FakePB })
  assert.deepEqual(result, { authToken: 'old', authModel: '{"id":"u1"}' })
  assert.equal(localStorage.getItem('pb_auth_token'), 'old')
  assert.equal(warnings.length, 1)
})

test('triggerBackgroundAuthRefresh does nothing without a token', async () => {
  triggerBackgroundAuthRefresh('http://pb', { authToken: null }, {
    loadPocketBase: () => assert.fail('should not load'),
  })
  await new Promise((r) => setTimeout(r, 5))
})

test('triggerBackgroundAuthRefresh stores the refreshed token', async () => {
  const { FakePB } = fakePocketBase()
  triggerBackgroundAuthRefresh('http://pb', { authToken: 'old', authModel: '{}' }, { PocketBase: FakePB })
  await new Promise((r) => setTimeout(r, 10))
  assert.equal(localStorage.getItem('pb_auth_token'), 'new-token')
  assert.equal(reloads, 0)
})

test('triggerBackgroundAuthRefresh 401 clears storage and calls onInvalidAuth', async () => {
  localStorage.setItem('pb_auth_token', 'old')
  localStorage.setItem('pb_auth_model', '{}')
  const { FakePB } = fakePocketBase({ refreshError: httpError(401) })
  let invalid = 0
  triggerBackgroundAuthRefresh('http://pb', { authToken: 'old', authModel: '{}' }, {
    PocketBase: FakePB,
    onInvalidAuth: () => void invalid++,
  })
  await new Promise((r) => setTimeout(r, 10))
  assert.equal(invalid, 1)
  assert.equal(reloads, 0)
  assert.equal(localStorage.has('pb_auth_token'), false)
})

test('triggerBackgroundAuthRefresh 403 reloads by default', async () => {
  const { FakePB } = fakePocketBase({ refreshError: httpError(403) })
  triggerBackgroundAuthRefresh('http://pb', { authToken: 'old', authModel: '{}' }, { PocketBase: FakePB })
  await new Promise((r) => setTimeout(r, 10))
  assert.equal(reloads, 1)
})

test('initiateOAuth stores verifier and state and sends the user', async () => {
  const { FakePB, calls } = fakePocketBase()
  const app = fakeApp()
  wirePocketBaseAuthPorts(app, { PocketBase: FakePB })
  await app.handlers.initiateOAuth('http://pb')
  assert.equal(calls.authMethods, 1)
  assert.equal(sessionStorage.getItem('pb_code_verifier'), 'ver')
  assert.equal(sessionStorage.getItem('pb_provider_state'), 'st')
  assert.deepEqual(app.sent.oauthPopupResult, [
    { token: 'oauth-token', model: '{"id":"u2","name":"Bob","email":"b@x.fi"}' },
  ])
})

test('initiateOAuth falls back to empty name and email', async () => {
  const { FakePB } = fakePocketBase({ record: { id: 'u3', name: null } })
  const app = fakeApp()
  wirePocketBaseAuthPorts(app, { PocketBase: FakePB })
  await app.handlers.initiateOAuth('http://pb')
  assert.equal(app.sent.oauthPopupResult[0].model, '{"id":"u3","name":"","email":""}')
})

test('initiateOAuth reports a failure as an empty token', async () => {
  const { FakePB } = fakePocketBase({ oauthError: new Error('popup closed') })
  const app = fakeApp()
  wirePocketBaseAuthPorts(app, { PocketBase: FakePB })
  await app.handlers.initiateOAuth('http://pb')
  assert.deepEqual(app.sent.oauthPopupResult, [{ token: '', model: '{}' }])
})

test('initiateOAuth uses loadPocketBase', async () => {
  const { FakePB } = fakePocketBase()
  let loads = 0
  const app = fakeApp()
  wirePocketBaseAuthPorts(app, {
    loadPocketBase: async () => {
      loads++
      return FakePB
    },
  })
  await app.handlers.initiateOAuth('http://pb')
  assert.equal(loads, 1)
  assert.equal(app.sent.oauthPopupResult[0].token, 'oauth-token')
})

test('saveAuthToken and clearAuthToken write and clear both keys', () => {
  const app = fakeApp()
  wirePocketBaseAuthPorts(app, {})
  app.handlers.saveAuthToken({ token: 't', model: '{"id":"1"}' })
  assert.equal(localStorage.getItem('pb_auth_token'), 't')
  assert.equal(localStorage.getItem('pb_auth_model'), '{"id":"1"}')
  app.handlers.clearAuthToken()
  assert.equal(localStorage.has('pb_auth_token'), false)
  assert.equal(localStorage.has('pb_auth_model'), false)
})

test('getCallbackParams answers from sessionStorage', () => {
  const app = fakeApp()
  wirePocketBaseAuthPorts(app, {})
  app.handlers.getCallbackParams()
  sessionStorage.setItem('pb_code_verifier', 'v')
  sessionStorage.setItem('pb_provider_state', 's')
  app.handlers.getCallbackParams()
  assert.deepEqual(app.sent.callbackParams, [
    { codeVerifier: '', state: '' },
    { codeVerifier: 'v', state: 's' },
  ])
})
