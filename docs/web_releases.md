# Web releases (migration step 14)

Use Node 22+, Flutter 3.47.9, Task, and Google Chrome. Run commands from the repository root. Set `CHROME_EXECUTABLE` if Chrome is installed somewhere other than its normal macOS location or `google-chrome` on Linux.

## Build and test

```sh
task web:test
task web:build
task web:check
task web:measure
task web:hosting:test
```

These default to dev. Repeat with `ENV=prod` to validate production locally. The Hosting emulator uses a demo project and stops automatically; the test discovers its assigned port from the Emulator Hub. It tests response headers and deep-link SPA rewrites without publishing. The compiled release still selects its cloud backend; use `task local` for an application connected to emulated Auth/Firestore.

The build hook compiles the chosen `APP_ENV`, keeps renderer resources on the same Hosting site, prepares search metadata, drops debug symbol/map files, and writes a hash manifest to `build/web-ENV/release.json`. The deployment hook refuses missing, altered, or mismatched releases. Use these hooks instead of raw `flutter build web` for publishable bundles. Hosting content deployments do not publish Auth, rules, or indexes.

`firebase.dev.json` explicitly selects `bramwellsprecisiontestkitdev` and `build/web-dev`. Dev responses carry `X-Robots-Tag: noindex, nofollow, noarchive` and `Cache-Control: no-store`; HTML has matching robot metadata, dev social URLs, no production structured data/canonical/sitemap, and a disallow-all robots file. The dev installable web manifest is labelled Dev.

`firebase.prod.json` explicitly selects `bramwells-precision-test-kit` and `build/web-prod`. Production uses the confirmed canonical origin `https://bramwelltest.com`, including the sitemap, social metadata, and `BrandConfiguration.publicSiteUrl`. Runtime Auth return URLs retain `https://dev.bramwelltest.com` / `https://bramwelltest.com`; emulators use localhost. The origin values in `config/web_environments.json` and Dart are checked together by a Flutter test. A future canonical-domain change should update all of these sources together.

Both sites retain SPA rewrites. Stable filenames revalidate in production (`max-age=0, must-revalidate`); no stable filename receives immutable caching. The existing Flutter service worker manages its versioned code cache. Its caching is independent of Auth/Firestore document persistence, which remains disabled. The small UI icon reuses the existing 192px launcher image; the full-resolution source remains available for native icon generation.

## Spark traffic planning

`task web:measure` opens a fresh headless Chrome profile with browser caching disabled. It serves the local bundle with gzip, waits for Flutter and network idle, and records observed compressed bytes, including local requests from service workers. Reports go to `build/web-transfer-dev.json` and `build/web-transfer-prod.json` and are uploaded by CI. This is a local approximation, not Firebase billing telemetry. It measures the signed-out landing screen; a per-session reserve covers additional workspace assets. Recheck an actual deployed cold load in Chrome DevTools > Network with cache disabled and a fresh profile, including worker traffic, before increasing the audience. Different browsers, later screens, repeat traffic, and previews also consume quota.

The checked-in planning settings are **250 MB/day**, **8 GB/month**, **40 cold sessions/day**, **31 days/month**, plus **1 MB/session** for additional assets/traffic. The command fails when the projection exceeds either planning limit. These are release checks, not server-enforced spending/traffic caps. They leave headroom against Firebase's documented 360 MB/day pricing figure and 10 GB/month usage figure. Confirm the actual quota and current usage displayed for each project. External Firebase SDK downloads are reported separately; Firestore traffic has its own quota. [Pricing](https://firebase.google.com/pricing), [Hosting usage and monitoring](https://firebase.google.com/docs/hosting/usage-quotas-pricing)

Before a large release, check Firebase Console > Hosting > Usage for storage and transfer. Live content, previews, and retained versions share each project's quota. Keep installers and generated exports outside the web build; the release checker rejects native installers and PDFs. Exported user PDFs/JSON remain local downloads.

## Release retention (Terraform)

The module adopts each existing live channel and retains **2 previous dev releases** and **5 previous production releases**. Import blocks are checked in; the channel has destruction protection. This changes the retention setting only after a reviewed Terraform apply. Lowering retention schedules older versions for deletion, so keep any required rollback version before applying. [Release retention and expiration](https://firebase.google.com/docs/hosting/manage-hosting-resources)

```sh
task infra:plan
task infra:show
task infra:apply
```

Repeat with `ENV=prod` after independent review. The current production plan also contains the previously pending Firestore ruleset/release replacement from step 9; review that separately before applying. Saved plans and state are private and ignored by Git. Do not apply only a targeted subset as a routine release process.

## Publish a dev preview or live release

```sh
task login:firebase                  # If not already signed in
task web:preview CHANNEL=my-change   # Expires two days after the last deploy
task web:channels                   # List channel URLs and expiry dates
task web:deploy                     # Deliberately publish dev live
```

Previews isolate Hosting files, while all dev previews connect to dev Auth/Firestore. Email action links return to the stable dev custom domain. Live deploys do not expire. A local production publish is an explicit operator action: `task web:deploy ENV=prod`; normal production releases should use the reviewed GitHub workflow below.

## Configure GitHub once

1. In the [repository environment settings](https://github.com/greenwaltc/shooters-precision-toolkit/settings/environments), create **production**. Add a required reviewer and restrict deployment branches to **main**. A workflow environment name alone does not create protection rules. Configure a second reviewer if you enable Prevent self-review; otherwise a solo maintainer cannot approve their own release.
2. Protect `main` with a ruleset/branch rule requiring PRs and the **Firebase dev Hosting / validate** check (select the actual check after its first run). Require review as appropriate for your team. If a required check refers to the former workflow name, update it to the current check.
3. Keep the existing dev-only GitHub secret `FIREBASE_SERVICE_ACCOUNT_BRAMWELLSPRECISIONTESTKITDEV` for dev live and previews. Put the production key in the production environment as `FIREBASE_SERVICE_ACCOUNT_BRAMWELLS_PRECISION_TEST_KIT` and remove its repository-level copy after verifying the environment secret. Do not commit keys. Short-lived credentials are the separate step 15.
4. Open a PR. Every PR runs Flutter analysis/tests and the dev build/traffic checks. A same-repository PR from **dev** into **main** builds the dev head commit and publishes that verified artifact to the dev **live** channel at `https://dev.bramwelltest.com`. Each subsequent push to dev triggers the PR's `synchronize` event and updates that live site; opening or reopening the PR also deploys it. Pushes to dev without an open PR do not trigger this workflow. Other same-repository PRs validate the merge ref and publish `pr-NUMBER` to the dev project with a **2d** expiry. Fork PRs run validation without receiving deployment credentials. Live deployments share one concurrency group so newer dev releases cancel older runs.
5. After merging to `main`, open **Actions > Release Firebase production > Run workflow**, choosing **main**. The workflow builds/tests/measures prod, then waits for the production environment's configured approval before uploading that exact verified artifact to prod live. Other branches do not run the production build/deploy jobs. Merging alone no longer publishes production.

The workflow files implement the build/deploy gates; repository administrator settings and secrets must be configured on GitHub. Local validation cannot establish that these remote settings exist. [GitHub environments and protection rules](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/manage-environments), [Firebase preview action](https://github.com/FirebaseExtended/action-hosting-deploy)
