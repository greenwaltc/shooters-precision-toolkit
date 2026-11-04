import { createHash } from 'node:crypto';
import { readFile, readdir } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

export const root = fileURLToPath(new URL('../', import.meta.url));
export const settings = JSON.parse(await readFile(path.join(root, 'config/web_environments.json')));

export function environmentConfig(environment) {
  if (!Object.hasOwn(settings.environments, environment)) {
    throw new Error('Choose dev or prod.');
  }
  const config = { environment, ...settings.environments[environment] };
  if (config.contactVerificationUrl) {
    const url = new URL(config.contactVerificationUrl);
    if (url.origin !== config.publicOrigin || url.pathname !== '/contact-verification/' || url.search || url.hash) {
      throw new Error('Contact verification must use this environment’s public origin and /contact-verification/.');
    }
  }
  return config;
}

export async function filesIn(directory) {
  const entries = await readdir(directory, { withFileTypes: true });
  const nested = await Promise.all(entries.map(async (entry) => {
    const name = path.join(directory, entry.name);
    if (entry.isSymbolicLink()) throw new Error(`Symlinks cannot be deployed: ${name}`);
    return entry.isDirectory() ? filesIn(name) : [name];
  }));
  return nested.flat().sort();
}

export async function artifactHashes(directory) {
  const hashes = {};
  for (const file of await filesIn(directory)) {
    const name = path.relative(directory, file).split(path.sep).join('/');
    // Match Hosting's **/.* ignore and upload-artifact's hidden-file exclusion.
    if (name === 'release.json' || name.split('/').some((part) => part.startsWith('.'))) continue;
    if (/\.(apk|aab|exe|msi|msix|dmg|ipa|pdf)$/i.test(name)) {
      throw new Error(`Keep installers and PDF exports outside Hosting: ${name}`);
    }
    hashes[name] = createHash('sha256').update(await readFile(file)).digest('hex');
  }
  return hashes;
}

export function prepareMetadata(html, environment) {
  const config = environmentConfig(environment);
  if (!html.includes(settings.canonicalOrigin)) {
    throw new Error('The web template and canonicalOrigin disagree.');
  }
  if (environment === 'dev') {
    html = html.replaceAll(settings.canonicalOrigin, config.publicOrigin)
      .replace(/\s*<link rel="canonical"[^>]*>/g, '')
      .replace(/\s*<link rel="sitemap"[^>]*>/g, '')
      .replace(/\s*<meta name="google-site-verification"[^>]*>/g, '')
      .replace(/\s*<script type="application\/ld\+json">[\s\S]*?<\/script>/g, '')
      .replace('<head>', '<head>\n  <meta name="robots" content="noindex, nofollow, noarchive">');
  }
  return html.replace('<head>', `<head>\n  <meta name="app-environment" content="${environment}">`);
}

export async function verifyRelease(environment, directory = path.join(root, `build/web-${environment}`)) {
  const config = environmentConfig(environment);
  const hosting = JSON.parse(await readFile(path.join(root, `firebase.${environment}.json`))).hosting;
  if (hosting.site !== config.siteId || hosting.public !== `build/web-${environment}`) {
    throw new Error('Hosting configuration selects the wrong site or build directory.');
  }
  const manifest = JSON.parse(await readFile(path.join(directory, 'release.json')));
  for (const key of ['environment', 'projectId', 'siteId', 'publicOrigin']) {
    if (manifest[key] !== config[key]) throw new Error(`Release ${key} does not match ${environment}. Rebuild it.`);
  }
  if ((manifest.contactVerificationUrl ?? '') !== (config.contactVerificationUrl ?? '')) {
    throw new Error('Rebuild after changing contactVerificationUrl.');
  }
  if (manifest.canonicalOrigin !== settings.canonicalOrigin) throw new Error('Rebuild after changing canonicalOrigin.');
  const hashes = await artifactHashes(directory);
  if (JSON.stringify(hashes) !== JSON.stringify(manifest.files)) {
    throw new Error('Release contents changed after building. Rebuild before deploying.');
  }
  const html = await readFile(path.join(directory, 'index.html'), 'utf8');
  const robots = await readFile(path.join(directory, 'robots.txt'), 'utf8');
  if (environment === 'dev') {
    if (!html.includes('noindex, nofollow, noarchive') || !robots.includes('Disallow: /')) {
      throw new Error('Dev indexing protection is missing.');
    }
    if (!hosting.headers?.some((rule) => rule.source === '**' && rule.headers.some(
      (header) => header.key === 'X-Robots-Tag' && header.value.includes('noindex'),
    ))) throw new Error('Dev Hosting noindex header is missing.');
  } else if (!html.includes(`rel="canonical" href="${settings.canonicalOrigin}/"`) || html.includes('noindex')) {
    throw new Error('Production canonical/indexing metadata is incorrect.');
  }
  return config;
}
