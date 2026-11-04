import assert from 'node:assert/strict';
import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import test from 'node:test';
import { artifactHashes, environmentConfig, prepareMetadata, root, settings, verifyRelease } from '../web_release.mjs';

const source = await readFile(path.join(root, 'web/index.html'), 'utf8');

test('dev is excluded from indexing and does not advertise the production site', () => {
  const html = prepareMetadata(source, 'dev');
  assert.match(html, /noindex, nofollow, noarchive/);
  assert.doesNotMatch(html, /rel="canonical"|rel="sitemap"|application\/ld\+json|google-site-verification/);
  assert.ok(!html.includes(settings.canonicalOrigin));
  assert.ok(html.includes(settings.environments.dev.publicOrigin));
  const prod = prepareMetadata(source, 'prod');
  assert.ok(prod.includes(`rel="canonical" href="${settings.canonicalOrigin}/"`));
  assert.doesNotMatch(prod, /noindex/);
});

test('reject invalid environments before starting a build or deployment', () => {
  for (const value of [undefined, '', 'production', '../../prod', 'toString']) {
    assert.throws(() => environmentConfig(value), /Choose dev or prod/);
  }
});

test('production discovery files use the confirmed canonical domain', async () => {
  for (const file of ['robots.txt', 'sitemap.xml']) {
    const content = await readFile(path.join(root, 'web', file), 'utf8');
    assert.ok(content.includes(settings.canonicalOrigin));
    assert.ok(!content.includes('bramwells-precision-test-kit.web.app'));
    assert.ok(!content.includes(settings.environments.dev.publicOrigin));
  }
});

test('wrong-environment and modified artifacts cannot pass deployment validation', async () => {
  const directory = await mkdtemp(path.join(tmpdir(), 'web-release-test-'));
  try {
    await writeFile(path.join(directory, 'index.html'), prepareMetadata(source, 'dev'));
    await writeFile(path.join(directory, 'robots.txt'), 'User-agent: *\nDisallow: /\n');
    await writeFile(path.join(directory, 'main.dart.js'), 'compiled dev application');
    await writeFile(path.join(directory, '.last_build_id'), 'Flutter build marker, not a public asset');
    const release = { ...environmentConfig('dev'), canonicalOrigin: settings.canonicalOrigin,
      files: await artifactHashes(directory) };
    await writeFile(path.join(directory, 'release.json'), JSON.stringify(release));
    assert.equal((await verifyRelease('dev', directory)).environment, 'dev');
    // CI drops hidden files while packaging; the public artifact must still pass.
    await rm(path.join(directory, '.last_build_id'));
    assert.equal((await verifyRelease('dev', directory)).environment, 'dev');
    await assert.rejects(verifyRelease('prod', directory), /Release environment does not match/);
    await writeFile(path.join(directory, 'main.dart.js'), 'accidentally replaced by another build');
    await assert.rejects(verifyRelease('dev', directory), /contents changed/);
    await writeFile(path.join(directory, 'main.dart.js'), 'compiled dev application');
    release.projectId = settings.environments.prod.projectId;
    await writeFile(path.join(directory, 'release.json'), JSON.stringify(release));
    await assert.rejects(verifyRelease('dev', directory), /Release projectId does not match/);
    await writeFile(path.join(directory, 'installer.apk'), 'not a web asset');
    await assert.rejects(verifyRelease('dev', directory), /Release projectId does not match/);
    await assert.rejects(artifactHashes(directory), /outside Hosting/);
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
});

test('Hosting keeps SPA routing, revalidates stable filenames, and isolates sites', async () => {
  for (const environment of ['dev', 'prod']) {
    const { hosting, ...other } = JSON.parse(await readFile(path.join(root, `firebase.${environment}.json`)));
    assert.deepEqual(other, {});
    assert.equal(hosting.site, environmentConfig(environment).siteId);
    assert.equal(hosting.public, `build/web-${environment}`);
    assert.deepEqual(hosting.rewrites, [{ source: '**', destination: '/index.html' }]);
    const headers = Object.fromEntries(hosting.headers.find((entry) => entry.source === '**')
      .headers.map(({ key, value }) => [key, value]));
    assert.equal(headers['Cache-Control'], environment === 'dev' ? 'no-store' : 'public, max-age=0, must-revalidate');
    assert.equal(headers['X-Robots-Tag'], environment === 'dev' ? 'noindex, nofollow, noarchive' : undefined);
  }
});


test('contact verification stays optional and cannot cross environments', () => {
  const dev = settings.environments.dev;
  const previous = dev.contactVerificationUrl;
  try {
    delete dev.contactVerificationUrl;
    assert.equal(environmentConfig('dev').contactVerificationUrl, undefined);
    dev.contactVerificationUrl = `${dev.publicOrigin}/contact-verification/`;
    assert.equal(environmentConfig('dev').contactVerificationUrl, dev.contactVerificationUrl);
    for (const url of [settings.canonicalOrigin + '/contact-verification/',
      dev.publicOrigin + '/contact-verification/?email=anything', dev.publicOrigin + '/other']) {
      dev.contactVerificationUrl = url;
      assert.throws(() => environmentConfig('dev'), /Contact verification must use/);
    }
  } finally {
    if (previous === undefined) delete dev.contactVerificationUrl;
    else dev.contactVerificationUrl = previous;
  }
});
