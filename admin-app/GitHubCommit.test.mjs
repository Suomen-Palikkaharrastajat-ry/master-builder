import assert from 'node:assert/strict';
import test from 'node:test';

import { findCommitConflicts } from './GitHubCommit.mjs';

const remoteTree = [
  { path: 'content/existing.md', sha: 'sha-current' },
  { path: 'content/other.md', sha: 'sha-other' },
];

test('existing file with changed sha reports conflict', () => {
  const conflicts = findCommitConflicts(
    [{ path: 'content/existing.md', content: 'local', expectedSha: 'sha-old' }],
    remoteTree
  );

  assert.deepEqual(conflicts, ['content/existing.md']);
});

test('new file with no remote blob does not report conflict', () => {
  const conflicts = findCommitConflicts(
    [{ path: 'content/new.md', content: 'local', expectedSha: '' }],
    remoteTree
  );

  assert.deepEqual(conflicts, []);
});

test('new file with existing remote blob reports conflict', () => {
  const conflicts = findCommitConflicts(
    [{ path: 'content/existing.md', content: 'local', expectedSha: '' }],
    remoteTree
  );

  assert.deepEqual(conflicts, ['content/existing.md']);
});

test('existing file with matching sha does not report conflict', () => {
  const conflicts = findCommitConflicts(
    [{ path: 'content/existing.md', content: 'local', expectedSha: 'sha-current' }],
    remoteTree
  );

  assert.deepEqual(conflicts, []);
});
