# Bramwell's Precision Test Kit

A Flutter app by Denton M. Bramwell for measuring firearm shot consistency with
two-shot groups. It guides users through test design, measurement entry, and
ANOMR (Analysis of Means for Ranges) results on web, Android, iOS, and macOS.

## How the app works

1. **Projects.** Create an account and verify your email to open your workspace.
   Create, open, clone, delete, or import projects. Firebase Auth identifies
   the account, and Cloud Firestore stores its projects.
2. **Test Design.** Name the project, define one to four factors with two states
   each, and choose a risk level and sample size. The form shows the detectable
   difference for each sample-size option.
3. **Data Matrix.** Enter measurements in **Group Size**. For multi-factor
   designs, columns follow Test Design order and the first factor changes fastest
   within each replicate. You can randomize run order, enter fractions, use
   undo/redo, copy selections with their headers, and paste a single column of
   measurements into Group Size.
4. **Results.** Compare each factor state's average group size with the grand mean
   and decision limits. Export results as PNG, JPEG, or PDF.

The **Instructions** menu opens the [in-app usage guide](assets/help_instructions.md).
**Contact** sends messages through Web3Forms in dev and production. **Donate**
opens the project's PayPal page.

Project edits save automatically. The Test Design and Data Matrix banners show
save status. Unsaved drafts live in the current session, so wait for **Saved**
before refreshing or closing the app. The shipped profiles use the light theme.
The theme toggle and missing-data imputation are controlled by
[build configuration](docs/guides/app_configuration.md).

### Portable project files

Select **Export** in the Data Matrix to save the test design, measurements, and
randomized run order to a JSON file. Select **Import** on Projects to validate a
file and save it as a separate project under your account. Project files use a
versioned format with a 256 KiB limit. When the file contract
changes, run `task project-schema:update` and commit the generated version
stamp. CI verifies it. [Portable project files](docs/guides/project_files.md)

## Local development

Use Flutter **3.47.9** with its bundled Dart **3.13.7**, Node.js **22+**, Task,
Google Chrome, and Java **21+** for the Firebase emulators. The repository pins
the toolchain in [config/toolchain.json](config/toolchain.json). Install the
missing tools with the [Flutter setup guide](https://docs.flutter.dev/get-started/install)
and the [Task installation guide](https://taskfile.dev/docs/installation).

Run these commands from the repository root.

```sh
task deps
flutter gen-l10n
task local
```

Open the [local app](http://127.0.0.1:7357/) or the
[Firebase Emulator UI](http://127.0.0.1:4000/). The local app connects to Auth
and Standard Firestore emulators under the demo project
`demo-bramwellsprecisiontestkit`. Local accounts and projects last for the
emulator session. Use `r` for hot reload, `R` for hot restart, and `q` or
Ctrl+C to end the session.

Use `task emulators:start` and `task local:run` in separate terminals to keep
the emulators running between app restarts. Use `task web:run ENV=dev` when you
want to connect to cloud dev. Run `task` to list the available commands.
[Application configuration](docs/guides/app_configuration.md)

## Web builds and releases

| Environment | Firebase project | Verified bundle | Site |
| --- | --- | --- | --- |
| Dev | `bramwellsprecisiontestkitdev` | `build/web-dev/` | [dev.bramwelltest.com](https://dev.bramwelltest.com) |
| Production | `bramwells-precision-test-kit` | `build/web-prod/` | [bramwelltest.com](https://bramwelltest.com) |

Run the production build locally.

```sh
task deps
flutter gen-l10n
task web:build ENV=prod
```

Use `task web:build ENV=dev` for dev. The build applies the selected environment's
configuration and search metadata and writes a verified `release.json` manifest
into the bundle. Run `task web:hosting:test ENV=prod` to check routes and headers
using the Hosting emulator.

- An open same-repository **dev → main** PR publishes each validated dev push to
  the dev live channel. Other same-repository PRs publish two-day dev previews.
  Fork PRs run validation.
- For production, run **Release Firebase production** from **main** in GitHub
  Actions. The workflow validates the production artifact and publishes it
  through the GitHub **production** environment.

The release guide covers preview commands, deployment credentials, environment
protections, and Spark traffic checks. [Web releases](docs/guides/web_releases.md)

## Native apps

Android, iOS, and macOS use separate `dev` and `prod` flavors. Dev uses
`.dev` application IDs. The commands below use dev by default. Add `ENV=prod`
to select the production Firebase configuration.

```sh
task native:check
task android:build                 # Debug APK
task ios:build                     # Unsigned iOS simulator build
task macos:build                   # Unsigned macOS debug build
task native:run DEVICE=macos       # Requires Apple development signing
```

For native development with Firebase emulators, start `task emulators:start`
first, then run `task native:local DEVICE=macos`. Android emulators use
`LOCAL_PROFILE=local-android` with the device ID from `flutter devices`.
Run `task native:config` to refresh native Firebase files after the Terraform
app registrations change. [Application configuration](docs/guides/app_configuration.md)

## Firebase infrastructure

Terraform manages the dev and production Firebase resources, including
Firestore and its rules, app registrations, and Hosting configuration. Install
Terraform **1.5 or later, below 2.0**, and the Google Cloud CLI. The Google and
Google Beta providers are pinned to **8.9.0**.

```sh
task login:terraform
task infra:plan ENV=dev
task infra:show ENV=dev
```

After reviewing the saved plan, use `task infra:apply ENV=dev` to apply it.
Hosting content is released separately through the web workflows. Follow the
environment checklists for Firebase Auth settings. [Infrastructure guide](infra/README.md)

## Checks and source layout

```sh
task check            # Format, analysis, Flutter/Node tests, coverage, and schema checks
task test:browser     # Chrome clipboard tests
task emulators:test   # Auth/Firestore SDK tests with fresh emulators
task local:test       # Auth/Firestore SDK tests against running local emulators
```

Use `task local:test` during an interactive emulator session. The fresh-emulator
task uses the same ports. `task verify` also runs native configuration and
Firestore rules checks. [Testing commands and evidence](docs/verification/testing_evidence.md)

- `lib/app/` owns startup, environment configuration, and routing.
- `lib/features/` contains Auth, Contact, and the experiment workspace.
- `lib/shared/` contains platform adapters, UI, theme tokens, and localization.
- `test/` and `integration_test/` cover isolated behavior and assembled journeys.
- `config/`, `infra/`, and `.github/workflows/` define build profiles,
  infrastructure, and CI/CD.

Edit user-facing copy in `lib/shared/l10n/app_en.arb` and regenerate it with
`flutter gen-l10n`. To update launcher icons, replace `assets/icon/app_icon.png`
and run `dart run flutter_launcher_icons`.
[Architecture map](docs/reference/architecture_map.md) · [Engineering standards](docs/README.md)

## License

Copyright © 2026 Denton M. Bramwell. All rights reserved. Engineered by Cameron Greenwalt.

This is proprietary software. See [LICENSE](LICENSE) for the terms.
