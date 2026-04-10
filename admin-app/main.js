// SECURITY: Never log GitHub tokens. This app is static and stores tokens only
// in sessionStorage unless the editor explicitly chooses "remember this browser".

import "../style.css";
import { insertSnippet, mountEditor, setContent } from './Editor.js';
import { createMultiFileCommit, githubJson } from './GitHubCommit.mjs';

const SESSION_TOKEN_KEY = 'admin-gh-token-session';
const LOCAL_TOKEN_KEY = 'admin-gh-token-local';

async function boot() {
  let cfg = {};
  try {
    const res = await fetch('/site-config.json', { cache: 'no-store' });
    cfg = await res.json();
  } catch (_) {
    // Boot with empty config; Elm will render the disabled/login state.
  }

  const app = window.Elm.Main.init({
    node: document.getElementById('admin-root'),
    flags: cfg,
  });

  wireAdminPorts(app);
}

boot();

function wireAdminPorts(app) {
  app.ports.loadToken.subscribe(() => {
    const sessionToken = sessionStorage.getItem(SESSION_TOKEN_KEY);
    const localToken = localStorage.getItem(LOCAL_TOKEN_KEY);
    if (sessionToken) {
      app.ports.tokenLoaded.send({ token: sessionToken, remember: false });
    } else if (localToken) {
      app.ports.tokenLoaded.send({ token: localToken, remember: true });
    } else {
      app.ports.tokenLoaded.send(null);
    }
  });

  app.ports.storeToken.subscribe(({ token, remember }) => {
    sessionStorage.removeItem(SESSION_TOKEN_KEY);
    localStorage.removeItem(LOCAL_TOKEN_KEY);
    if (remember) {
      localStorage.setItem(LOCAL_TOKEN_KEY, token);
    } else {
      sessionStorage.setItem(SESSION_TOKEN_KEY, token);
    }
  });

  app.ports.clearToken.subscribe(() => {
    sessionStorage.removeItem(SESSION_TOKEN_KEY);
    localStorage.removeItem(LOCAL_TOKEN_KEY);
  });

  app.ports.listFiles.subscribe(async ({ token, owner, repo, branch, contentPath }) => {
    try {
      const root = normalizePrefix(contentPath);
      const res = await githubJson(
        token,
        `https://api.github.com/repos/${owner}/${repo}/git/trees/${encodeURIComponent(branch)}?recursive=1`
      );
      const files = (res.tree || [])
        .filter(item => item.type === 'blob')
        .filter(item => item.path.endsWith('.md'))
        .filter(item => !root || item.path === root.slice(0, -1) || item.path.startsWith(root))
        .map(item => ({
          path: item.path,
          name: item.path.split('/').pop(),
          sha: item.sha,
        }))
        .sort((a, b) => a.path.localeCompare(b.path));
      app.ports.filesListed.send({ files });
    } catch (err) {
      app.ports.filesListed.send({ error: err.message });
    }
  });

  app.ports.fetchFile.subscribe(async ({ token, owner, repo, branch, path }) => {
    try {
      const item = await githubJson(
        token,
        `https://api.github.com/repos/${owner}/${repo}/contents/${encodePath(path)}?ref=${encodeURIComponent(branch)}`
      );
      app.ports.fileLoaded.send({
        meta: { path: item.path, name: item.name, sha: item.sha },
        content: decodeBase64(item.content || ''),
      });
    } catch (err) {
      app.ports.fileLoaded.send({ error: err.message });
    }
  });

  app.ports.mountEditor.subscribe(() => {
    requestAnimationFrame(() => {
      mountEditor((newContent) => {
        app.ports.editorContentChanged.send(newContent);
      });
    });
  });

  app.ports.setEditorContent.subscribe((content) => {
    setContent(content);
  });

  app.ports.insertSnippet.subscribe((snippet) => {
    insertSnippet(snippet);
  });

  app.ports.loadWorkspace.subscribe((key) => {
    try {
      app.ports.workspaceLoaded.send(JSON.parse(localStorage.getItem(key) || '[]'));
    } catch (_) {
      app.ports.workspaceLoaded.send([]);
    }
  });

  app.ports.saveWorkspace.subscribe(({ key, drafts }) => {
    localStorage.setItem(key, JSON.stringify(drafts));
  });

  app.ports.commitStaged.subscribe(async ({ token, owner, repo, branch, message, files }) => {
    try {
      const result = await createMultiFileCommit({ token, owner, repo, branch, message, files });
      app.ports.commitDone.send({ sha: result.sha });
    } catch (err) {
      if (err.conflicts) {
        app.ports.commitDone.send({ conflicts: err.conflicts });
      } else {
        app.ports.commitDone.send({ error: err.message });
      }
    }
  });
}

function normalizePrefix(path) {
  const trimmed = (path || '').replace(/^\/+|\/+$/g, '');
  return trimmed ? `${trimmed}/` : '';
}

function encodePath(path) {
  return path.split('/').map(encodeURIComponent).join('/');
}

function decodeBase64(raw) {
  const clean = raw.replace(/\n/g, '');
  const bytes = Uint8Array.from(atob(clean), c => c.charCodeAt(0));
  return new TextDecoder('utf-8').decode(bytes);
}
