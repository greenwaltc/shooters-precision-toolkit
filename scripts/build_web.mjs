import { spawnSync } from 'node:child_process';
import { readFile, rm, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { artifactHashes, environmentConfig, filesIn, prepareMetadata, root, settings, verifyRelease } from './web_release.mjs';

try {
  const environment = process.argv[2];
  const config = environmentConfig(environment);
  const directory = path.join(root, `build/web-${environment}`);
  // Never leave an older deployable release behind after a failed build.
  await rm(directory, { recursive: true, force: true });
  const result = spawnSync('flutter', [
    'build', 'web', '--release', `--dart-define=APP_ENV=${environment}`,
    `--dart-define=CONTACT_VERIFICATION_URL=${config.contactVerificationUrl ?? ''}`,
    '--no-web-resources-cdn', `--output=build/web-${environment}`,
  ], { cwd: root, stdio: 'inherit' });
  if (result.error) throw result.error;
  if (result.status !== 0) process.exit(result.status ?? 1);

  const htmlPath = path.join(directory, 'index.html');
  await writeFile(htmlPath, prepareMetadata(await readFile(htmlPath, 'utf8'), environment));
  if (environment === 'dev') {
    await writeFile(path.join(directory, 'robots.txt'), 'User-agent: *\nDisallow: /\n');
    await rm(path.join(directory, 'sitemap.xml'), { force: true });
    const manifestPath = path.join(directory, 'manifest.json');
    const manifest = JSON.parse(await readFile(manifestPath));
    manifest.name += ' (Dev)';
    manifest.short_name += ' Dev';
    await writeFile(manifestPath, JSON.stringify(manifest, null, 2) + '\n');
  }
  // Debug symbol tables are not needed to run a release in the browser.
  for (const file of await filesIn(directory)) {
    if (file.endsWith('.symbols') || file.endsWith('.map')) await rm(file);
  }
  await writeFile(path.join(directory, 'release.json'), JSON.stringify({
    ...config,
    canonicalOrigin: settings.canonicalOrigin,
    builtAt: new Date().toISOString(),
    files: await artifactHashes(directory),
  }, null, 2) + '\n');
  await verifyRelease(environment);
  console.log(`Verified ${environment} release for ${config.projectId}.`);
} catch (error) {
  console.error(error.message);
  process.exitCode = 1;
}
