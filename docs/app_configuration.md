# Running and configuring the application

Use `task local` for isolated emulators, `task web:run ENV=dev` for the dev cloud,
and `task web:build ENV=dev` for a verified release. Production is always explicit:
`ENV=prod`. For an Android emulator use `task native:local DEVICE=<id>
LOCAL_PROFILE=local-android`; its loopback alias is `10.0.2.2`.

The reviewed, non-secret manifests are `config/dev.json`, `prod.json`, `local.json`
and `local-android.json`. `scripts/flutter.mjs` validates the entire flat manifest
and rejects additional `--dart-define`/`--dart-define-from-file` options. For example:

```sh
node scripts/flutter.mjs local run -d chrome --web-port=7357
node scripts/flutter.mjs dev build apk --flavor dev --debug
```

`AppConfig.fromValues` repeats validation before constructing clients. Only
`loadBuildConfig` reads compilation declarations. Environment, Firebase project,
native flavor and return origin must agree; generated native resources have their
own `task native:check` validation. Release metadata includes the manifest SHA-256;
changing a manifest invalidates an existing release. Restart after changing inputs.

The wrapper also derives `BUILD_ID`, `BUILD_VERSION`, `BUILD_REVISION`, and
`BUILD_FLUTTER_SDK` from Git, pubspec, and the pinned toolchain. These public values
are written to the temporary build input, never to the reviewed manifests. An
unwrapped test reports unknown build identity; release commands require the real
metadata. Debug symbols and source maps do not go into public release folders.

## Field contract

All fields below are public strings at the JSON boundary, immutable after parsing,
owned by the application maintainer, and take effect on a new build/restart. They
must never contain credentials. No runtime remote overrides are implemented.

| Field | Typed value / allowed values | Default |
| --- | --- | --- |
| CONFIG_SCHEMA_VERSION | exact schema `1` | Required |
| APP_ENV | `dev` or `prod` | Required; no production fallback |
| USE_FIREBASE_EMULATORS | bool, exact `true`/`false`; forbidden in prod | false |
| FIREBASE_EMULATOR_HOST | local allowlist: 127.0.0.1, localhost, 10.0.2.2 | 127.0.0.1 |
| AUTH_EMULATOR_PORT | integer, 1024–65535 | 9099 |
| FIRESTORE_EMULATOR_PORT | integer, 1024–65535 | 8080 |
| SAVE_DEBOUNCE_MILLISECONDS | Duration, 100–10000 ms | 2000 |
| EMAIL_COOLDOWN_SECONDS | Duration, 30–300 s | 60 |
| IMPUTE_MISSING_DATA | bool, exact true/false | false |
| THEME_MODE_TOGGLE | bool, exact true/false | false |

Both experimental flags belong to the application maintainer; review for removal
or permanent adoption by **2026-12-31**. Both states are tested. They expose UI
capabilities and cannot grant authorization. A persisted preference cannot enable
a disabled capability.

Brand artwork/content are named resources in `BrandConfiguration`; UI text belongs
to localization resources and visual dimensions/colors/motion to design tokens.
`BehaviorPolicy` contains reviewed defaults for timing, precision, bounded history,
export quality, paging and the donation destination. Algorithm identities, schema
keys/versions, units and calibration data are code/data contracts, not arbitrary
deployment switches. Keep them versioned with their tests rather than turning
every literal (such as zero, field names or a formula exponent) into a build input.

## Ownership and injection

Bootstrap owns configuration and Firebase clients. One authenticated workspace owns
its repository, editable models, timers and subscriptions; sign-out invalidates
that workspace. Routes own text/focus/grid controllers. Preferences loaders, time,
and random sources are supplied explicitly; tests supply isolated preferences,
fixed/controlled clocks and seeded randomness. The composition root alone chooses
real adapters. The volatile repository is test/preview tooling and is never a
cloud fallback. In-memory drafts remain limited to one session.
