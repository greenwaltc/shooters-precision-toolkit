import { spawnSync } from 'node:child_process';
import { root, settings, verifyRelease } from './web_release.mjs';

try {
  const environment = process.argv[2];
  const channel = process.argv[3] ?? process.env.PREVIEW_CHANNEL;
  const config = await verifyRelease(environment);
  if (channel !== undefined && (environment !== 'dev' || channel === 'live' || !/^[a-z0-9][a-z0-9-]{0,39}$/.test(channel))) {
    throw new Error('Preview channels require dev and a lowercase channel name other than live.');
  }
  const args = channel === undefined
    ? ['deploy', '--only', 'hosting']
    : ['hosting:channel:deploy', channel, '--expires', settings.previewExpires];
  args.push('--config', `firebase.${environment}.json`, '--project', config.projectId);
  console.log(`Deploying verified ${environment} bundle to ${config.siteId}:${channel ?? 'live'}.`);
  const result = spawnSync('npx', ['-y', 'firebase-tools@latest', ...args], { cwd: root, stdio: 'inherit' });
  if (result.error) throw result.error;
  process.exitCode = result.status ?? 1;
} catch (error) {
  console.error(error.message);
  process.exitCode = 1;
}
