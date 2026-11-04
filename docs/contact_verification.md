# Contact verification setup

The Contact menu item is available on sign-in, Projects, Setup, Matrix, and Results. Without configuration, the Contact page offers a direct email reveal and mail link. This fallback does not provide Turnstile protection. Configuring the verification URL switches the page to the protected service. A Cloudflare Worker reveals it only after server-side Turnstile verification, including checks on the token’s hostname and action. No email is sent by this endpoint. Once a person sees an address, they can share it; this protects against automated harvesting, not all future spam.

This uses Cloudflare Workers and Turnstile without adding Firebase Functions or a Firebase billing requirement. Select the Workers Free plan; its request/CPU limits still apply. Each deployment has its own widget, Worker, and secrets. Requests fail closed if verification or configuration is missing.

## Activate dev

1. In Cloudflare’s Turnstile dashboard, create a **Managed** widget allowing only `dev.bramwelltest.com`. Leave pre-clearance disabled. Copy its **public site key** into `env.dev.vars.TURNSTILE_SITE_KEY` in `infra/contact-worker/wrangler.jsonc`.
2. From the project root, authenticate and create the dev Worker. The initial deployment intentionally returns an unavailable message until secrets are set:

   ```sh
   npx wrangler@latest login
   task contact:test
   task contact:deploy ENV=dev
   npx wrangler@latest secret put TURNSTILE_SECRET_KEY --config infra/contact-worker/wrangler.jsonc --env dev
   npx wrangler@latest secret put CONTACT_EMAIL --config infra/contact-worker/wrangler.jsonc --env dev
   ```

   At the first secret prompt, enter the widget’s private Turnstile secret. At the second, enter Denton’s email address supplied in the request. Do not put either value in Git, Dart defines, public CI logs, or the app’s assets.
3. Keep the hostname proxied through Cloudflare. The checked-in Worker route handles only `dev.bramwelltest.com/contact-verification/*`; Firebase continues serving the app. Add a **Bypass cache** rule for this path (after broader cache rules), respect origin browser TTL, and purge any previously cached path responses. The Worker sends `no-store` headers on every response, including the revealed address.
4. Open `https://dev.bramwelltest.com/contact-verification/`. Verify that an invalid/expired challenge does not reveal the address and a valid challenge reveals the intended address. Also test retry, browser privacy extensions, and a narrow mobile screen. A real challenge must be completed by a human.
5. After the Worker works, add this property to the **dev** entry in `config/web_environments.json`:

   ```json
   "contactVerificationUrl": "https://dev.bramwelltest.com/contact-verification/"
   ```

   Push dev with an open dev-to-main PR, or run `task web:deploy ENV=dev`. The build script injects the environment-specific URL. Until it is configured, the rest of the app works normally and Contact uses the unprotected direct email fallback. A configured service failure does not fall back to the unprotected address.

## Activate production

Repeat with a separate Managed widget allowing only `bramwelltest.com`, the `env.prod` public key, `ENV=prod`, and `--env prod` for both secrets. Set production’s `contactVerificationUrl` to `https://bramwelltest.com/contact-verification/` only after testing that Worker. Publish the Flutter app through the existing production release workflow.

## Local checks

`task contact:test` tests valid/invalid/expired verification responses, hostname/action mismatches, missing configuration, request bounds, origin checks, and upstream failures using a mock Siteverify response. It never solves a real challenge or calls Cloudflare. `task check` tests chart layout and Contact navigation. The same Node tests run in web release CI.

For local Flutter UI testing after dev activation, supply `--dart-define=CONTACT_VERIFICATION_URL=https://dev.bramwelltest.com/contact-verification/` with your Flutter run command. Use **Open verification in a new tab** when running on localhost or the Firebase web.app hostname: the Worker deliberately permits embedding only from its own custom domain. Do not relax the frame policy. Native builds can pass the same Dart define and open the verification page in the browser.

[Turnstile server-side validation](https://developers.cloudflare.com/turnstile/get-started/server-side-validation/), [Worker routes](https://developers.cloudflare.com/workers/configuration/routing/routes/), [Worker secrets](https://developers.cloudflare.com/workers/configuration/secrets/), [Workers Free limits](https://developers.cloudflare.com/workers/platform/limits/).
