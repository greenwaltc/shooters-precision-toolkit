import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { loadManifest } from './app_config.mjs';

const root = fileURLToPath(new URL('../', import.meta.url));
export const toolchain = JSON.parse(await readFile(path.join(root, 'config/toolchain.json')));

function command(program, args) {
  const result = spawnSync(program, args, {
    cwd: root, encoding: 'utf8', env: { ...process.env, GIT_OPTIONAL_LOCKS: '0' },
  });
  if (result.error || result.status !== 0) throw new Error(`${program} is required to identify the build.`);
  return result.stdout.trim();
}

export async function releaseIdentity() {
  const revision = command('git', ['rev-parse', '--verify', 'HEAD']);
  if (!/^[a-f0-9]{40}(?:[a-f0-9]{24})?$/.test(revision)) throw new Error('Invalid source revision.');
  const pubspec = await readFile(path.join(root, 'pubspec.yaml'), 'utf8');
  const version = pubspec.match(/^version:\s*([0-9]+\.[0-9]+\.[0-9]+\+[0-9]+)\s*$/m)?.[1];
  if (!version) throw new Error('pubspec must declare an app version and build number.');
  return {
    sourceRevision: revision,
    appVersion: version,
    flutterVersion: toolchain.flutter,
    dartVersion: toolchain.dart,
    lockfileChecksum: createHash('sha256').update(await readFile(path.join(root, 'pubspec.lock'))).digest('hex'),
  };
}

export async function withBuildManifest(profile, action) {
  const reviewed = await loadManifest(profile);
  const actual = JSON.parse(command('flutter', ['--version', '--machine']));
  if (actual.frameworkVersion !== toolchain.flutter || actual.dartSdkVersion !== toolchain.dart) {
    throw new Error(`Use Flutter ${toolchain.flutter} with its bundled Dart ${toolchain.dart}.`);
  }
  const identity = await releaseIdentity();
  const buildId = `${identity.sourceRevision.slice(0, 12)}-${Date.now().toString(36)}`;
  const sourceDirty = command('git', ['status', '--porcelain=v1']).length !== 0;
  const values = {
    ...reviewed.values,
    BUILD_ID: buildId,
    BUILD_VERSION: identity.appVersion,
    BUILD_REVISION: identity.sourceRevision,
    BUILD_FLUTTER_SDK: identity.flutterVersion,
  };
  const directory = await mkdtemp(path.join(tmpdir(), 'precision-build-config-'));
  try {
    const file = path.join(directory, 'config.json');
    await writeFile(file, JSON.stringify(values), { mode: 0o600 });
    return await action({ ...reviewed, file, identity: { ...identity, buildId, sourceDirty } });
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
}
