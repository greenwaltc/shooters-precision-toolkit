import assert from 'node:assert/strict';
import test from 'node:test';
import { loadManifest, parseManifest, validateBuildArguments, validateManifest } from '../app_config.mjs';

test('reviewed manifests and artifact hashes cover all environments', async () => {
  for (const profile of ['dev', 'prod', 'local', 'local-android']) {
    const { values, checksum } = await loadManifest(profile);
    assert.equal(values.APP_ENV, profile === 'prod' ? 'prod' : 'dev');
    assert.match(checksum, /^[a-f0-9]{64}$/);
  }
});
test('unknown, duplicate and malformed configuration fails before Flutter', () => {
  const base = { CONFIG_SCHEMA_VERSION: '1', APP_ENV: 'dev' };
  for (const invalid of [{}, {...base, TYPO: 'true'}, {...base, APP_ENV: 'other'},
    {...base, USE_FIREBASE_EMULATORS: 'yes'}, {...base, AUTH_EMULATOR_PORT: '0'},
    {...base, APP_ENV: 'prod', USE_FIREBASE_EMULATORS: 'true'},
    {...base, FIREBASE_EMULATOR_HOST: 'example.test'}, {...base, EMAIL_COOLDOWN_SECONDS: 'NaN'}]) {
    assert.throws(() => validateManifest(invalid));
  }
  assert.throws(() => parseManifest('{"APP_ENV":"dev","APP_ENV":"prod"}'), /Duplicate/);
  assert.throws(() => parseManifest('{"APP_ENV":true}'), /strings/);
  assert.throws(() => validateBuildArguments(['run', '--dart-define=APP_ENV=prod']));
  assert.throws(() => validateBuildArguments(['run', '--dart-define-from-file=other.json']));
  validateBuildArguments(['run', '-d', 'chrome']);
});
