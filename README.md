# Bramwell's Precision Test Kit

A statistical analysis app for testing firearm shot consistency, by Denton M. Bramwell.

Built with Flutter for **web, Android, iOS, and macOS**, the app walks a shooter through designing a precision experiment, collecting two-shot group data, and reading statistically sound conclusions from an ANOMR (Analysis of Means for Ranges) chart — no statistics background required. Windows has a runner scaffold but no configured Firebase environment.

## What it does

Measures of dispersion are hard to test: they need large samples and careful experiment design. This app packages that rigor into a simple workflow:

1. **Design the experiment** — Name a project, choose 1–4 factors (e.g. cartridge design, shooting stance, bullet type), and name the two states of each factor. Testing four factors at once requires *no more samples* than testing one.
2. **Choose risk and sample size** — Pick an α (alpha) risk level (5%, 10%, ...) and a sample size that gives the detectable-difference resolution you want. The app shows exactly what difference each option can detect.
3. **Enter group size data** — The app generates a data matrix pairing every factor-state combination. Shoot the prescribed two-shot groups and enter each group's size in the **Group Size** column. Run order can be randomized to guard against drift. Copy/paste, undo/redo, and fraction input (`1/4` → `0.25`) are supported.
4. **Read the results** — One click renders an ANOMR chart with a grand-mean centerline and upper/lower decision limits. Any factor state whose mean falls outside the limits is significantly different at your chosen risk level. Conclusions are also spelled out in plain language, and everything can be exported (including PDF).

Full usage instructions live in the app under the **Instructions** button (source: `assets/help_instructions.md`).

## Feature highlights

- **Multi-project workspace** — create, switch, and delete saved projects; state persists locally between sessions.
- **Spreadsheet-style data entry** — Enter/Tab advance through the Group Size column, values commit on every keystroke, grid-level undo/redo (Cmd/Ctrl+Z), and clipboard support.
- **Randomized run order** — optional shuffle with values that stay bound to their sample rows.
- **Results export** — chart and conclusions exportable, including PDF output.
- **Light & dark mode** — toggle on the home page; follows the system preference by default and persists your choice.
- **Fully responsive** — adapts across phone, tablet, desktop, and browser-zoom/text-magnification levels.

## Getting started (development)

Prerequisites: [Flutter](https://docs.flutter.dev/get-started/install) **3.47.9** (bundled Dart **3.13.7**), Node.js **22+**, and [Task](https://taskfile.dev/docs/installation). The SDK pin is recorded in `.fvmrc` and `config/toolchain.json`. On macOS, install Task with `brew install go-task`. Infrastructure commands also use Terraform and the Google Cloud CLI.

```bash
task deps
task local                # Local emulators + Flutter in Chrome
task                      # List all available commands
```

### Local services

`task local` starts the Auth and Standard Firestore emulators, waits for them, and launches Flutter in Chrome at `http://127.0.0.1:7357`. Use Flutter's `r`/`R` commands to reload/restart after changes, and `q` to quit. Ctrl+C also shuts down the session. The Emulator UI is at [127.0.0.1:4000](http://127.0.0.1:4000).

The first start downloads the Firebase CLI and emulator binaries, so it needs internet access. Install Java 21 or newer; the launcher can use Android Studio's bundled Java when the default Java is older. No Firebase login, cloud deployment, or Terraform apply is needed. Local services use `demo-bramwellsprecisiontestkit`, with separate dummy SDK configuration. All emulator listeners are restricted to this computer.

For separate terminals:

```bash
task emulators:start      # Terminal 1: leave running
task local:run            # Terminal 2: Flutter with local services
```

Test the full local connection:

```bash
task emulators:test       # Starts fresh services, tests in headless Chrome, stops services
task local:test           # Same tests when emulators are already running
```

Stop an existing emulator session before `emulators:test` because both use the same ports. `task emulators:check` checks the running services. Emulator Auth accounts and database data reset when the services stop. Browser Auth and Firestore persistence are disabled in local mode to avoid stale sessions/cache after a reset.

The local app supports registration, email verification, sign-in, and cloud project storage against demo Auth/Firestore services. The smoke tests check account flows and database access rules. Use `task web:run` when you deliberately want local Flutter connected to **cloud dev** instead. Production emulator builds are rejected.

See [Firebase's emulator connection guide](https://firebase.google.com/docs/emulator-suite/connect_firestore) for demo-project isolation and [Emulator Suite setup](https://firebase.google.com/docs/emulator-suite/install_and_configure) for emulator options.

Run the checks:

```bash
task check
```

Build and publish web releases:

```bash
task web:build            # build/web-dev
task web:build ENV=prod   # build/web-prod
task web:check            # Verify the built bundle and destination
task web:measure          # Fresh Chrome load and Spark traffic planning check
task web:hosting:test     # Test built routes/headers with the Hosting emulator
task web:preview CHANNEL=my-change # Publish a two-day dev preview
task web:deploy           # Check, rebuild, and publish to dev Hosting
task web:deploy ENV=prod  # Check, rebuild, and publish to production Hosting
```

Environment commands default to `dev` and accept only `dev` or `prod`. Deploy/preview commands run checks, rebuild, measure transfer, and verify file hashes and the Hosting destination before uploading. Dev builds have indexing disabled. Use `task --dry web:deploy ENV=prod` to inspect commands without executing them. Run environments sequentially in one checkout because Flutter shares build intermediates. Node 22+ and Google Chrome are required for web release checks; set `CHROME_EXECUTABLE` if Chrome is installed elsewhere.

An open `dev` → `main` PR deploys each pushed dev commit to the dev live site at `https://dev.bramwelltest.com`. Other same-repository PRs deploy dev previews. Production uses a manual workflow from `main` and the GitHub `production` environment. Configure its reviewer/branch protections before the first production run. See [web release instructions](docs/web_releases.md) for setup, retention, and Spark traffic limits.

### Native dev and production apps

Android, iOS, and macOS support `dev` and `prod` flavors. Dev app IDs end in `.dev` and the app is named Precision Test Kit Dev. Production retains its original IDs. Firebase service files and Dart options select the same environment; Apple builds validate the selected plist before bundling it.

```bash
task native:check
task native:run DEVICE=macos                 # requires Apple development signing
task native:run DEVICE=macos ENV=prod
task android:build                          # dev debug APK
task android:build ENV=prod                  # production backend, debug APK
task ios:build                              # unsigned dev simulator app
task ios:build ENV=prod
task macos:build                            # unsigned dev macOS app
task macos:build ENV=prod
```

For a native dev app with local Firebase, start `task emulators:start` in one terminal and run `task native:local DEVICE=macos` in another. Use `flutter devices` for other device IDs. Android emulators use `task native:local DEVICE=YOUR_DEVICE_ID LOCAL_PROFILE=local-android`. Apple signed runs require a development certificate/team configured in Xcode; unsigned builds do not need one. Android production release signing uses the private `android/key.properties` file; see its checked-in example. Production releases fail if that file is absent.

If Xcode reports “Found no destinations” or “iOS 26.5 is not installed,” install the matching iOS platform in Xcode > Settings > Components, then rerun `task ios:build`. A simulator runtime is also needed to run the app in a simulator.

`task native:config` retrieves SDK config using Terraform output app IDs and regenerates native Dart options while preserving web options. It never creates Firebase apps. `task native:check` checks environment identity and transport policy. `task verify` runs regular Flutter, native config, rules, and browser emulator checks sequentially on macOS; stop interactive emulators first or run `task local:test` against the running instance. See the [engineering standards](docs/README.md) and [verification commands](docs/testing_evidence.md).

The application is cloud-native. Its signed-in workspace retains only session drafts, and persistent Firestore caching is disabled. Legacy import and durable offline replay are outside scope; unsaved changes do not survive a refresh/restart. Existing cloud revision guards remain in place. Steps 10–11 are marked skipped in the [migration guide](docs/firebase_migration_guide.md).

For first-time authentication, run `task login:firebase` for Firebase CLI deployments, `task login:terraform` for Terraform, and `task login:gcloud` for billing inspection. These maintain separate credentials.

To change infrastructure:

```bash
task infra:plan           # Initialize, validate, and save the dev plan
task infra:show           # Review the saved changes
task infra:apply          # Apply that exact plan
task infra:output         # Show app IDs and Hosting URL
task billing:check        # Expect False for Spark
```

Add `ENV=prod` to each command for production. `infra:apply` changes cloud resources and applies the saved plan without an additional confirmation prompt. Plans and local state stay out of Git; back up state privately after applies and use one infrastructure operator. Do not run competing applies or builds in the same checkout.

Auth settings are separate: `task auth:deploy` deploys only the selected provider configuration. It does not complete the Console checklist, disable omitted providers, or downgrade Identity Platform. Email/password is already enabled in both projects, so this task is only needed for deliberate configuration changes. See [infra/README.md](infra/README.md) and each environment's Auth checklist before changing it. Terraform continues to own Firestore rules; web deployment uploads Hosting content only.

## Project structure

```
lib/
├── main.dart       # Entry point
├── app/            # Validated configuration, startup, routing, composition
├── features/
│   ├── auth/       # Account lifecycle and Firebase Auth adapter
│   ├── contact/    # Contact page
│   └── experiments/ # Projects, Test Design, matrix, results, and persistence
└── shared/         # Contracts, platform adapters, localization, and UI
```

See the [architecture map](docs/architecture_map.md) for dependencies and state
lifetimes.

### Theming and design knobs

Common visual settings live in `lib/shared/ui/theme/app_design.dart` and its
theme tokens. Responsive layout adapts those values to the viewport. User-facing
copy lives in `lib/shared/l10n/app_en.arb`.

## Testing

Tests mirror the app under `test/`. They cover form validation, numeric parsing,
matrix selection and history, accessible layouts, and account isolation. The
assembled browser journey covers project creation → Test Design → matrix → results.
See [test commands and evidence](docs/testing_evidence.md).

```bash
task check               # Locked dependencies, analysis, tests and coverage
task emulators:test      # Fresh emulators and browser Auth/Firestore tests
task local:test          # Browser tests against already-running emulators
```

The browser suite applies a real emulator verification code and signs out from a private workspace route. It creates uniquely named test accounts and deletes only those accounts; it does not clear existing emulator users. Stop other emulator sessions before running `emulators:test`.

## App icons

Source artwork lives at `assets/icon/app_icon.png` (1024×1024 PNG). After replacing it, regenerate every platform size with:

```bash
dart run flutter_launcher_icons
```

Configuration is in `pubspec.yaml` under `flutter_launcher_icons` (Android adaptive icons, iOS, macOS, Windows, and web PWA/favicon).

## Deployment (web)

The web app deploys to Firebase Hosting (project `bramwells-precision-test-kit`), serving `build/web` as a single-page app (`firebase.json`).

- **CI/CD** — GitHub Actions validate every PR. Same-repository `dev` → `main` PRs publish to dev live; other same-repository PRs get preview channels. Production uses a manual release from `main` (`.github/workflows/firebase-hosting-*.yml`). Requires separate dev and production Firebase service-account secrets; see [web release setup](docs/web_releases.md#configure-github-once).
- **Manual deploy:**

```bash
flutter build web --release
npx -y firebase-tools@latest deploy --only hosting --project bramwells-precision-test-kit
```

> If you rename the Dart package in `pubspec.yaml`, run `flutter clean` before the next build — stale build artifacts reference the old package name.

## License

Copyright © 2026 Denton M. Bramwell. All rights reserved.

This is **proprietary software** — see [LICENSE](LICENSE). No part of the software may be reproduced, modified, or distributed without the prior express written consent of the owner.


### Contact page

The Contact page is a placeholder until a private contact form is implemented. It does not reveal an email address or send messages.
