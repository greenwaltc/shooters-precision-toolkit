import { withBuildManifest } from './build_identity.mjs';
import { spawnSync } from 'node:child_process';
import { chmod, copyFile, mkdir, readFile, rm, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { artifactHashes, environmentConfig, filesIn, prepareMetadata, root, settings, stripSourceMapDirectives, verifyRelease } from './web_release.mjs';

try {
  const environment = process.argv[2];
  const config = environmentConfig(environment);
  const directory = path.join(root, `build/web-${environment}`);
  // Never leave an older deployable release behind after a failed build.
  await rm(directory, { recursive: true, force: true });
  const manifest = await withBuildManifest(environment, (resolved) => {
    const result = spawnSync('flutter', [
      'build', 'web', '--release', '--no-pub', `--dart-define-from-file=${resolved.file}`,
      '--no-web-resources-cdn', '--source-maps', `--output=build/web-${environment}`,
    ], { cwd: root, stdio: 'inherit' });
    if (result.error) throw result.error;
    if (result.status !== 0) throw new Error(`Flutter web build failed (${result.status ?? 'signal'}).`);
    return resolved;
  });

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
  // Keep private debugging evidence outside the Hosting artifact.
  const privateRoot = path.join(root, 'build/private-symbols', environment, manifest.identity.buildId);
  const privateFiles = {};
  for (const file of await filesIn(directory)) {
    if (/\.(symbols|map)$/i.test(file)) {
      const relative = path.relative(directory, file);
      const destination = path.join(privateRoot, relative);
      await mkdir(path.dirname(destination), { recursive: true, mode: 0o700 });
      await copyFile(file, destination);
      await chmod(destination, 0o600);
      privateFiles[relative] = true;
      await rm(file);
    } else if (file.endsWith('.js')) {
      const code = await readFile(file, 'utf8');
      const cleaned = stripSourceMapDirectives(code);
      if (cleaned !== code) await writeFile(file, cleaned);
    }
  }
  if (!Object.keys(privateFiles).length) throw new Error('Build produced no private debugging symbols.');
  await writeFile(path.join(privateRoot, 'identity.json'), JSON.stringify({
    ...manifest.identity, environment, configChecksum: manifest.checksum,
  }, null, 2) + '\n', { mode: 0o600 });
  await writeFile(path.join(directory, 'release.json'), JSON.stringify({
    ...config,
    ...manifest.identity,
    target: 'web',
    configChecksum: manifest.checksum,
    configurationSchema: manifest.values.CONFIG_SCHEMA_VERSION,
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
