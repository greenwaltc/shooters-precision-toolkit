# Bramwell's Precision Test Kit

A statistical analysis app for testing firearm shot consistency, by Denton M. Bramwell.

Built with Flutter and running on **web, Android, iOS, macOS, and Windows**, the app walks a shooter through designing a precision experiment, collecting two-shot group data, and reading statistically sound conclusions from an ANOMR (Analysis of Means for Ranges) chart — no statistics background required.

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

Prerequisites: a recent [Flutter](https://docs.flutter.dev/get-started/install) stable release (Dart SDK ≥ 3.11, per `pubspec.yaml`).

```bash
flutter pub get
flutter run -d chrome     # web
flutter run -d macos      # macOS desktop
flutter run               # any connected device/emulator
```

Run the checks:

```bash
flutter analyze
flutter test
```

Release builds:

```bash
flutter build web --release
flutter build apk --release        # Android
flutter build ios --release        # iOS (requires Xcode + signing)
flutter build macos --release
flutter build windows --release    # requires a Windows host
```

## Project structure

```
lib/
├── main.dart                  # App bootstrap, routing, theme wiring
├── config/                    # Feature flags and build configuration
├── help/                      # In-app instructions sheet
├── model/                     # ProjectStore, form model, theme controller
├── navigation/                # Route names
├── sample_size_catalog.dart   # Sample-size options per factor count / risk
├── storage/                   # SharedPreferences persistence boundary
├── styles/
│   ├── app_design.dart        # ← Central design config: every visual "knob"
│   ├── app_theme.dart         # Material 3 theme built from AppDesign
│   ├── tokens/                # Spacing, radius, color, border, opacity facets
│   ├── components/            # Reusable styled widgets (cards, pills, panels)
│   ├── layout/                # Responsive breakpoints and viewport helpers
│   └── chart/                 # Chart scaling and layout rules
└── widgets/
    ├── project_home_page.dart # Project list + create
    ├── project_form.dart      # Experiment setup form
    ├── anomr_matrix.dart      # Data-entry grid (PlutoGrid)
    └── anomr_results/         # ANOMR calculation, chart, export
```

### Theming and design knobs

All visual configuration — brand color, spacing scale, radii, typography, button geometry, motion — lives in **`lib/styles/app_design.dart`** as documented constants. Change a value there and it propagates through the theme and every token. Light and dark themes are generated from the same knobs, so they stay consistent automatically.

## Testing

Tests live in `test/` and cover the form model (factor persistence across structure changes), range-value parsing, grid undo/redo history, theme controller persistence, text-scale clamping, and end-to-end widget flows (project creation → setup → matrix → results).

```bash
flutter test
```

## App icons

Source artwork lives at `assets/icon/app_icon.png` (1024×1024 PNG). After replacing it, regenerate every platform size with:

```bash
dart run flutter_launcher_icons
```

Configuration is in `pubspec.yaml` under `flutter_launcher_icons` (Android adaptive icons, iOS, macOS, Windows, and web PWA/favicon).

## Deployment (web)

The web app deploys to Firebase Hosting (project `bramwells-precision-test-kit`), serving `build/web` as a single-page app (`firebase.json`).

- **CI/CD** — GitHub Actions build and deploy automatically: pull requests get preview channels, merges to `main` deploy to the live channel (`.github/workflows/firebase-hosting-*.yml`). Requires the `FIREBASE_SERVICE_ACCOUNT_BRAMWELLS_PRECISION_TEST_KIT` repository secret.
- **Manual deploy:**

```bash
flutter build web --release
npx -y firebase-tools@latest deploy --only hosting --project bramwells-precision-test-kit
```

> If you rename the Dart package in `pubspec.yaml`, run `flutter clean` before the next build — stale build artifacts reference the old package name.

## License

Copyright © 2026 Denton M. Bramwell. All rights reserved.

This is **proprietary software** — see [LICENSE](LICENSE). No part of the software may be reproduced, modified, or distributed without the prior express written consent of the owner.
