import assert from 'node:assert/strict';
import test from 'node:test';
import {handleRequest} from '../worker.mjs';

const env = {CONTACT_HOSTNAME: 'dev.example.test', TURNSTILE_SITE_KEY: 'public-key',
  TURNSTILE_SECRET_KEY: 'private-key', CONTACT_EMAIL: 'protected@example.test'};
const origin = 'https://dev.example.test';
const post = (token = 'test-token', headers = {}) => new Request(origin + '/contact-verification/reveal', {
  method: 'POST', headers: {'Origin': origin, 'Content-Type': 'application/x-www-form-urlencoded', ...headers},
  body: new URLSearchParams({'cf-turnstile-response': token}),
});
const verify = (value) => async () => Response.json(value);
const valid = {success: true, hostname: env.CONTACT_HOSTNAME, action: 'contact'};

test('initial page contains the challenge and never the address or secret', async () => {
  const response = await handleRequest(new Request(origin + '/contact-verification/'), env);
  const html = await response.text();
  assert.ok(html.includes('public-key'));
  assert.ok(!html.includes(env.CONTACT_EMAIL));
  assert.ok(!html.includes(env.TURNSTILE_SECRET_KEY));
  assert.equal(response.headers.get('Cache-Control'), 'no-store');
  assert.equal(response.headers.get('Cloudflare-CDN-Cache-Control'), 'no-store');
});

test('only successful server verification with correct hostname and action reveals email', async () => {
  let calls = 0;
  const response = await handleRequest(post(), env, async (url, options) => {
    calls++;
    assert.equal(url, 'https://challenges.cloudflare.com/turnstile/v0/siteverify');
    assert.equal(options.body.get('secret'), env.TURNSTILE_SECRET_KEY);
    assert.equal(options.body.get('response'), 'test-token');
    return Response.json(valid);
  });
  assert.equal(calls, 1);
  assert.equal(response.status, 200);
  assert.ok((await response.text()).includes('mailto:' + env.CONTACT_EMAIL));
  assert.equal(response.headers.get('Cache-Control'), 'no-store');
});

for (const result of [
  {success: false, 'error-codes': ['timeout-or-duplicate']},
  {...valid, hostname: 'other.example.test'}, {...valid, action: 'login'},
  {success: true},
]) {
  test(`reject invalid verification ${JSON.stringify(result)}`, async () => {
    const response = await handleRequest(post(), env, verify(result));
    assert.equal(response.status, 403);
    assert.ok(!(await response.text()).includes(env.CONTACT_EMAIL));
  });
}

test('missing token, foreign origin, wrong host and direct GET cannot reveal email', async () => {
  for (const request of [post(''), post('test', {Origin: 'https://evil.test'}),
    new Request(origin + '/contact-verification/reveal'),
    new Request('https://other.example.test/contact-verification/'),
    post('x'.repeat(9000))]) {
    const response = await handleRequest(request, env, () => {throw new Error('Must not call Siteverify');});
    assert.ok(response.status >= 400);
    assert.ok(!(await response.text()).includes(env.CONTACT_EMAIL));
  }
});

test('missing configuration and verification outages fail closed', async () => {
  for (const key of ['TURNSTILE_SITE_KEY', 'TURNSTILE_SECRET_KEY', 'CONTACT_EMAIL']) {
    const response = await handleRequest(post(), {...env, [key]: ''});
    assert.equal(response.status, 503);
    assert.ok(!(await response.text()).includes(env.CONTACT_EMAIL));
  }
  const response = await handleRequest(post(), env, () => {throw new Error('Network failure');});
  assert.equal(response.status, 503);
  assert.ok(!(await response.text()).includes(env.CONTACT_EMAIL));
});
