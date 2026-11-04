const verifyEndpoint = 'https://challenges.cloudflare.com/turnstile/v0/siteverify';
const escape = (value) => String(value).replace(/[&<>"']/g,
  (char) => ({'&':'&amp;', '<':'&lt;', '>':'&gt;', '"':'&quot;', "'":'&#39;'}[char]));

function page(content, status = 200) {
  return new Response(`<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Contact verification</title>
<style>body{font:16px system-ui,sans-serif;margin:0;padding:12px;color:#231f26;background:#fff}
button,a{display:inline-block;margin-top:12px}button{font:inherit;padding:12px 18px;background:#67508d;color:white;border:0;border-radius:8px;cursor:pointer}
a{overflow-wrap:anywhere}p{line-height:1.5}.cf-turnstile{margin-top:12px}</style>
<script src="https://challenges.cloudflare.com/turnstile/v0/api.js" async defer></script>
</head><body>${content}</body></html>`, {status, headers: {
    'Content-Type': 'text/html; charset=utf-8',
    'Cache-Control': 'no-store',
    'Cloudflare-CDN-Cache-Control': 'no-store',
    'X-Robots-Tag': 'noindex, nofollow, noarchive',
    'X-Content-Type-Options': 'nosniff',
    'Referrer-Policy': 'no-referrer',
    'Content-Security-Policy': "default-src 'none'; script-src https://challenges.cloudflare.com; frame-src https://challenges.cloudflare.com; connect-src https://challenges.cloudflare.com; style-src 'unsafe-inline'; form-action 'self'; base-uri 'none'; frame-ancestors 'self'",
  }});
}

export async function handleRequest(request, env, verifyFetch = fetch) {
  const url = new URL(request.url);
  if (url.hostname !== env.CONTACT_HOSTNAME || !['/contact-verification/', '/contact-verification/reveal'].includes(url.pathname)) {
    return page('<p>Not found.</p>', 404);
  }
  if (!env.TURNSTILE_SITE_KEY || !env.TURNSTILE_SECRET_KEY || !env.CONTACT_EMAIL) {
    return page('<p>Contact verification is temporarily unavailable. Please try again later.</p>', 503);
  }
  const retry = '<p><a href="/contact-verification/">Try verification again</a></p>';
  if (request.method === 'GET' && url.pathname === '/contact-verification/') {
    return page(`<p>Verify that you are human to reveal Denton Bramwell’s email address.</p>
<form method="POST" action="/contact-verification/reveal">
<div class="cf-turnstile" data-sitekey="${escape(env.TURNSTILE_SITE_KEY)}" data-action="contact" data-size="flexible"></div>
<button type="submit">Reveal email address</button></form>`);
  }
  if (request.method !== 'POST' || url.pathname !== '/contact-verification/reveal') {
    return page('<p>Method not allowed.</p>', 405);
  }
  if (request.headers.get('Origin') !== url.origin) return page('<p>Invalid request origin.</p>', 403);
  if (!request.headers.get('Content-Type')?.startsWith('application/x-www-form-urlencoded')) {
    return page('<p>Invalid form.</p>', 415);
  }
  // Bound streamed bodies too; Content-Length alone can be absent or forged.
  const reader = request.body?.getReader();
  if (!reader) return page('<p>Verification required.</p>' + retry, 400);
  let bytes = 0;
  let body = '';
  const decoder = new TextDecoder();
  while (true) {
    const {done, value} = await reader.read();
    if (done) break;
    bytes += value.byteLength;
    if (bytes > 8192) { await reader.cancel(); return page('<p>Request too large.</p>', 413); }
    body += decoder.decode(value, {stream: true});
  }
  body += decoder.decode();
  const token = new URLSearchParams(body).get('cf-turnstile-response');
  if (!token || token.length > 2048) return page('<p>Complete verification first.</p>' + retry, 400);
  try {
    const response = await verifyFetch(verifyEndpoint, {
      method: 'POST',
      body: new URLSearchParams({secret: env.TURNSTILE_SECRET_KEY, response: token}),
      signal: AbortSignal.timeout(10000),
    });
    if (!response.ok) throw new Error('Verification unavailable');
    const result = await response.json();
    if (result.success !== true || result.hostname !== env.CONTACT_HOSTNAME || result.action !== 'contact') {
      return page('<p>Verification failed or expired.</p>' + retry, 403);
    }
    // No client-provided destination and no endpoint that sends mail.
    const email = escape(env.CONTACT_EMAIL);
    return page(`<p>Contact Denton Bramwell:</p><p><a href="mailto:${email}" target="_blank" rel="noopener">${email}</a></p>`);
  } catch {
    return page('<p>Verification is temporarily unavailable.</p>' + retry, 503);
  }
}

export default {fetch(request, env) { return handleRequest(request, env); }};
