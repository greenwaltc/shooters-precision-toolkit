# CI execution and caches

Both Hosting entry workflows call `.github/workflows/web-ci.yml`. Independent
jobs start together: repository/tooling checks, Flutter analysis/tests/coverage,
three browser suites (clipboard, desktop, mobile), Firestore rules/audit, Firebase
SDK contracts, and the web release build/Hosting/traffic checks. No existing
assertions, tests, coverage threshold, or artifact checks are removed.

The caller's `validate` job remains the stable branch-protection check. It accepts
only success from the reusable workflow; failure, cancellation, skipped work, or
missing results prevent deployment. The web artifact can build while tests run,
but deployment downloads that exact verified artifact only after validation.
Dev live versus PR preview selection, fork restrictions, credential project
checks, production environment approval, and main-only production deployment
remain in the entry workflows.

## Parallelism and reuse

- iOS and macOS build independently for dev and prod (four Apple jobs).
- Android keeps both flavors together because the second build reuses the
  first build's native compilation. Gradle's action caches dependencies and build
  state and verifies Gradle wrapper checksums.
- The shared Flutter action reads pinned SDK/Node versions from
  `config/toolchain.json`, caches Flutter and locked pub packages, and still runs
  enforced dependency resolution and localization generation on each runner.
- Firebase/npm jobs cache npm downloads and emulator binaries. Firebase continues
  selecting and verifying its requested emulator version on every run; caches
  never determine which version to execute.
- Apple caches include CocoaPods downloads, the selected platform's Pods, and
  incremental native build outputs. Keys isolate OS/architecture, platform,
  flavor, full Xcode version, Flutter/toolchain and dependency lockfiles. An exact
  commit match is preferred, with restoration from the same dependency/toolchain
  prefix for subsequent commits. Builds always execute, including on cache hits.
- GitHub scopes PR caches to the PR ref, preventing fork PRs from replacing
  default-branch caches. All validation jobs have read-only repository access.
- Artifact names are distinct across parallel jobs. Coverage and browser logs are
  retained for seven days; release bundles remain separate from private symbols.

Parallel jobs use more simultaneous runners and repeat some setup, reducing
elapsed time rather than promising fewer billable minutes. Cache eviction and
runner availability can increase elapsed time; correctness never depends on hits.
The new official Actions releases use Node 24 rather than deprecated runtimes.

## Validation

The repository job runs checksum-pinned actionlint and Node tooling checks. Every
web validation includes the existing full Flutter and integration suites. The
native workflow still compiles Android dev/prod, unsigned iOS simulator dev/prod,
and unsigned macOS dev/prod, with `fail-fast: false` for the Apple matrix.

To exercise production checks on `dev` without deploying production:

```sh
gh workflow run firebase-hosting-merge.yml --ref dev -f validate_only=true
```

Normal production release remains a manual dispatch on `main` with
`validate_only=false` (the default), followed by the production environment's
approval rules. Do not use a real production deployment as a CI smoke test.

Previous successful runs provide comparison baselines:
[web](https://github.com/greenwaltc/shooters-precision-toolkit/actions/runs/42904465481)
took 9 minutes 8 seconds for validation plus 29 seconds to deploy;
[Apple](https://github.com/greenwaltc/shooters-precision-toolkit/actions/runs/42904465493)
took about 16 minutes 36 seconds for the slower flavor. Compare job elapsed times
and queue delays separately, distinguishing cache-fill runs from warm runs.
Validation-only production runs do not establish deployment credentials or
production environment approval behavior.
