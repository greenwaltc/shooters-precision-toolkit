import assert from 'node:assert/strict';
import { environmentConfig } from '../web_release.mjs';

const { environment } = environmentConfig(process.argv[2]);
const hub = process.env.FIREBASE_EMULATOR_HUB;
assert.ok(hub, 'Run this script through Firebase emulators:exec.');
const services = await (await fetch(`http://${hub}/emulators`)).json();
assert.ok(services.hosting?.port, 'The Hosting emulator must be running.');
const origin = `http://127.0.0.1:${services.hosting.port}`;
for (const route of ['/', '/projects/example/deep-link']) {
  const response = await fetch(`${origin}${route}`);
  assert.equal(response.status, 200);
  assert.match(response.headers.get('content-type'), /text\/html/);
  assert.equal(response.headers.get('x-robots-tag'), environment === 'dev' ? 'noindex, nofollow, noarchive' : null);
  assert.equal(response.headers.get('cache-control'), environment === 'dev' ? 'no-store' : 'public, max-age=0, must-revalidate');
  assert.ok((await response.text()).includes(`name="app-environment" content="${environment}"`));
}
const robots = await (await fetch(`${origin}/robots.txt`)).text();
assert.ok(robots.includes(environment === 'dev' ? 'Disallow: /' : 'Allow: /'));
const release = await (await fetch(`${origin}/release.json`)).json();
assert.equal(release.environment, environment);
const script = await fetch(`${origin}/main.dart.js`);
assert.match(script.headers.get('content-type'), /javascript/);
assert.equal(script.headers.get('x-content-type-options'), 'nosniff');
console.log(`${environment}: Hosting SPA routes, metadata, and headers passed.`);
