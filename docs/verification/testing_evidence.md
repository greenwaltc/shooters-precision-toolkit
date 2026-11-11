# Test execution and coverage

The toolchain is Flutter **3.47.9** with its bundled Dart SDK, Node **22+**, and
Google Chrome for browser checks. `pubspec.lock` is committed. Tests mirror source
responsibilities; shared fakes/builders live in `test/support`, and the assembled
application journey uses the SDK's `integration_test` runner.

## Automated gates

`task check` verifies generated localization, architecture boundaries, repository
hygiene, formatting, strict analysis, seed **4729** randomized unit/widget tests,
source-inclusive coverage, and release-tool tests. `task test:browser` exercises native browser
copy/paste events and desktop Enter entry across a delayed autosave. `task local:test` exercises real Auth/Firestore SDK contracts
against running **demo** emulators and never clears interactive emulator data.
`task rules:test` installs its own locked npm dependencies and runs a disposable
Firestore emulator on distinct loopback ports. `task web:hosting:test` checks the
built artifact in a disposable Hosting emulator for the selected environment.

The shared repository cases run against the fake, the volatile adapter, and real
Firestore emulators. Time, IDs, storage, and asynchronous completions are controlled
for deterministic tests. The anonymous volatile adapter is used only by the
integration journey/preview tooling; production remains cloud-only.

## Assembled browser journey

Install a matching ChromeDriver from Google's Chrome for Testing distribution.
The pinned downloader is development tooling, not a runtime dependency:

```sh
npx --yes @puppeteer/browsers@3.2.6 install chromedriver@<your-Chrome-version> --path build/browser
CHROMEDRIVER=/absolute/path/printed/by/the/installer/chromedriver task test:integration:web
```

The command bundles Flutter web resources to avoid a runtime CDN dependency,
selects an unused local driver port, launches a fresh headless browser,
runs the real Flutter application with isolated volatile data, and stops its
driver. Logs are under `build/test-results`. This proves assembled UI/wiring; the
separate emulator suite proves actual backend compatibility. Neither uses a cloud
Firebase project. Native integration can run the same target using
`flutter test integration_test/project_journey_test.dart -d <device>`.

Repository streams are eventually consistent: an initial SDK cache snapshot may
precede the current server value. Shared contracts await the expected revision or
deletion with a bounded timeout; they do not mistake the first cache event for a
new authoritative read.

## Coverage denominator

The required floor is **80%**. `scripts/check_coverage.mjs` enumerates every Dart
source under `lib`; it does not infer the denominator solely from loaded libraries.
The two generated Firebase option files are explicitly excluded by
`config/coverage.json`. Every other file is included. For an uninstrumented file,
the conservative denominator is all nonblank/non-comment source lines at zero
hits, including platform implementations unavailable to VM tests. This can only
lower coverage. A Node regression test proves newly unexecuted source lowers the
result. CI archives LCOV, the expanded JSON report, and browser logs.

Goldens are not selected as a substitute for interaction/semantic layout tests.
Physical screen-reader and native-device acceptance must be recorded separately;
browser/widget success must not be presented as those manual checks.

## Native and release checks

`task native:check` checks Android and Apple profile mappings, Apple plist
selection, and production transport policy. `task android:build`,
`task ios:build`, and `task macos:build` compile debug smoke artifacts; use
`ENV=prod` for the second configuration. The **Native validation** workflow
runs unsigned builds on PRs affecting native or shared application code.
These builds are separate from signed distribution and physical-device acceptance.

The current targets are Android API 24+ (Android SDK 36 and NDK 28.2.13676358
for this Flutter SDK), iOS 15+, and macOS 13+. Apple builds need Xcode with
the matching platform and simulator components; local checks used Xcode 26.5.
Windows is a runner scaffold without configured Firebase options.

## Adoption verification (2026-11-04)

| Check | Local result |
| --- | --- |
| Formatter, generated code, repository and architecture checks, strict analysis | Passed |
| Randomized unit and widget suite | 289 passed; 82.41% maintained Dart coverage (5,042/6,118 lines, minimum 80%) |
| Node tooling and rules-harness audit | 12 tooling tests passed; npm audit reported zero findings in the locked rules-test graph |
| Firebase emulators | 8 real SDK contract tests and 14 isolated Firestore rule tests passed |
| Chrome | Native clipboard test and full desktop and compact viewport journeys passed |
| Web release, dev and prod | Both built, passed artifact/Hosting checks, and fit the Spark planning budget at about 4.58 MB of cold Hosting transfer per session |
| Native builds, dev and prod | Android debug and unsigned macOS debug built; both iOS simulator attempts blocked by Xcode's missing iOS 26.5 platform component |

The native workflow was checked with actionlint; remote Actions execution, signed
release builds, live cloud settings, and physical-device checks were not run.
See [UI acceptance](ui_acceptance.md) for the device and performance review.
