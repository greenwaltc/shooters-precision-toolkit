import assert from 'node:assert/strict';
import test from 'node:test';
import { secretMatches } from '../check_repository.mjs';

test('secret checks return locations and types without the credential', () => {
  const privateKeyHeader = ['-----BEGIN', 'PRIVATE KEY-----'].join(' ');
  const token = ['ghp', 'a'.repeat(36)].join('_');
  assert.deepEqual(secretMatches(['public config', privateKeyHeader, token].join('\n')), [
    { kind: 'privateKey', line: 2 },
    { kind: 'githubCredential', line: 3 },
  ]);
  assert.deepEqual(secretMatches('public Firebase client identifier; no credential'), []);
});
