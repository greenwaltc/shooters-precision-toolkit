import { spawnSync } from 'node:child_process';
import { validateBuildArguments } from './app_config.mjs';
import { withBuildManifest } from './build_identity.mjs';

try {
  const [profile, ...arguments_] = process.argv.slice(2);
  validateBuildArguments(arguments_, profile === 'prod' ? 'prod' : 'dev');
  await withBuildManifest(profile, ({ file }) => {
    const result = spawnSync('flutter', [...arguments_, `--dart-define-from-file=${file}`], { stdio: 'inherit' });
    if (result.error) throw result.error;
    process.exitCode = result.status ?? 1;
  });
} catch (error) {
  console.error(error.message);
  process.exitCode = 1;
}
