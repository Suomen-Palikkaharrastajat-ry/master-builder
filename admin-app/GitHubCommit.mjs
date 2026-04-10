export async function createMultiFileCommit({ token, owner, repo, branch, message, files }) {
  const base = `https://api.github.com/repos/${owner}/${repo}`;
  const ref = await githubJson(token, `${base}/git/ref/heads/${encodeURIComponent(branch)}`);
  const currentCommitSha = ref.object.sha;
  const currentCommit = await githubJson(token, `${base}/git/commits/${currentCommitSha}`);
  const baseTreeSha = currentCommit.tree.sha;
  const currentTree = await githubJson(token, `${base}/git/trees/${baseTreeSha}?recursive=1`);
  const conflicts = findCommitConflicts(files, currentTree.tree || []);

  if (conflicts.length > 0) {
    const err = new Error('Remote content changed before commit.');
    err.conflicts = conflicts;
    throw err;
  }

  const tree = files.map(file => ({
    path: file.path,
    mode: '100644',
    type: 'blob',
    content: file.content,
  }));

  const newTree = await githubJson(token, `${base}/git/trees`, {
    method: 'POST',
    body: JSON.stringify({ base_tree: baseTreeSha, tree }),
  });
  const newCommit = await githubJson(token, `${base}/git/commits`, {
    method: 'POST',
    body: JSON.stringify({
      message,
      tree: newTree.sha,
      parents: [currentCommitSha],
    }),
  });
  await githubJson(token, `${base}/git/refs/heads/${encodeURIComponent(branch)}`, {
    method: 'PATCH',
    body: JSON.stringify({ sha: newCommit.sha, force: false }),
  });
  return newCommit;
}

export function findCommitConflicts(files, treeItems) {
  const currentByPath = new Map((treeItems || []).map(item => [item.path, item]));
  return files
    .filter(file => {
      const current = currentByPath.get(file.path);
      const currentSha = current?.sha || '';

      if (file.expectedSha) {
        return currentSha !== file.expectedSha;
      }

      return Boolean(currentSha);
    })
    .map(file => file.path);
}

export async function githubJson(token, url, options = {}) {
  const res = await fetch(url, {
    ...options,
    headers: {
      Authorization: `Bearer ${token}`,
      Accept: 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
      ...(options.body ? { 'Content-Type': 'application/json' } : {}),
      ...(options.headers || {}),
    },
  });
  const json = await res.json().catch(() => ({}));
  if (!res.ok) {
    throw new Error(json.message || `GitHub API ${res.status}`);
  }
  return json;
}
