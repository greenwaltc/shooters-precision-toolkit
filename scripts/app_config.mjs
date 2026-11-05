import { createHash } from 'node:crypto';
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('../', import.meta.url));
const defaults = {
  USE_FIREBASE_EMULATORS: 'false', FIREBASE_EMULATOR_HOST: '127.0.0.1',
  AUTH_EMULATOR_PORT: '9099', FIRESTORE_EMULATOR_PORT: '8080',
  SAVE_DEBOUNCE_MILLISECONDS: '2000', EMAIL_COOLDOWN_SECONDS: '60',
  IMPUTE_MISSING_DATA: 'false', THEME_MODE_TOGGLE: 'false',
  WEB3FORMS_ACCESS_KEY: '',
};

export function parseManifest(text) {
  // Flat string-only JSON: preserve keys during tokenization to detect duplicates.
  const tokens = text.match(/"(?:[^"\\]|\\.)*"|[{}:,]|[^\s{}:,]+/g) ?? [];
  const seen = new Set();
  let index = 0;
  if (tokens[index++] !== '{') throw new Error('Manifest must be an object.');
  while (tokens[index] !== '}') {
    const key = JSON.parse(tokens[index++]);
    if (typeof key !== 'string' || seen.has(key)) throw new Error('Duplicate configuration key.');
    seen.add(key);
    if (tokens[index++] !== ':') throw new Error('Invalid manifest.');
    if (typeof JSON.parse(tokens[index++]) !== 'string') throw new Error('Manifest values must be strings.');
    if (tokens[index] === '}') break;
    if (tokens[index++] !== ',') throw new Error('Invalid manifest.');
  }
  if (tokens[index++] !== '}' || index !== tokens.length) throw new Error('Invalid manifest.');
  return validateManifest(JSON.parse(text));
}

export function validateManifest(values) {
  const allowed = new Set(['CONFIG_SCHEMA_VERSION', 'APP_ENV', ...Object.keys(defaults)]);
  if (Object.keys(values).some((key) => !allowed.has(key))) throw new Error('Unknown configuration key.');
  if (Object.values(values).some((value) => typeof value !== 'string')) throw new Error('Manifest values must be strings.');
  if (values.CONFIG_SCHEMA_VERSION !== '1') throw new Error('Unsupported configuration schema.');
  if (!['dev', 'prod'].includes(values.APP_ENV)) throw new Error('Invalid APP_ENV.');
  const config = { ...defaults, ...values };
  if (config.WEB3FORMS_ACCESS_KEY !== '' &&
      !/^[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}$/i.test(config.WEB3FORMS_ACCESS_KEY)) {
    throw new Error('WEB3FORMS_ACCESS_KEY must be a UUID.');
  }
  for (const key of ['USE_FIREBASE_EMULATORS', 'IMPUTE_MISSING_DATA', 'THEME_MODE_TOGGLE']) {
    if (!['true', 'false'].includes(config[key])) throw new Error(`Invalid ${key}.`);
  }
  if (config.APP_ENV === 'prod' && config.USE_FIREBASE_EMULATORS === 'true') throw new Error('Production cannot select emulators.');
  if (!['127.0.0.1', 'localhost', '10.0.2.2'].includes(config.FIREBASE_EMULATOR_HOST)) throw new Error('Invalid emulator host.');
  for (const [key, minimum, maximum] of [
    ['AUTH_EMULATOR_PORT', 1024, 65535], ['FIRESTORE_EMULATOR_PORT', 1024, 65535],
    ['SAVE_DEBOUNCE_MILLISECONDS', 100, 10000], ['EMAIL_COOLDOWN_SECONDS', 30, 300],
  ]) {
    if (!/^\d+$/.test(config[key]) || Number(config[key]) < minimum || Number(config[key]) > maximum) throw new Error(`Invalid ${key}.`);
  }
  return Object.freeze(config);
}

export async function loadManifest(profile) {
  if (!['dev', 'prod', 'local', 'local-android'].includes(profile)) throw new Error('Choose a reviewed configuration profile.');
  const file = path.join(root, `config/${profile}.json`);
  const bytes = await readFile(file, 'utf8');
  const values = parseManifest(bytes);
  if (values.APP_ENV !== (profile === 'prod' ? 'prod' : 'dev') ||
      values.USE_FIREBASE_EMULATORS !== String(profile.startsWith('local'))) {
    throw new Error('Manifest identity does not match its selected profile.');
  }
  return { values, file, checksum: createHash('sha256').update(bytes).digest('hex') };
}

export function validateBuildArguments(arguments_, environment) {
  if (arguments_.some((value) => value.startsWith('--dart-define'))) {
    throw new Error('Use one reviewed manifest; duplicate or individual declarations are not accepted.');
  }
  const flavors = arguments_.flatMap((value, index) => value === '--flavor'
    ? [arguments_[index + 1]] : value.startsWith('--flavor=') ? [value.slice(9)] : []);
  if (flavors.length > 1 || (flavors.length && environment && flavors[0] !== environment)) {
    throw new Error('Native flavor and build profile disagree.');
  }
}
