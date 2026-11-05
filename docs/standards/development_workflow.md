# Development, review, and delivery conventions

Status and requirement language: [engineering standards](../README.md).

This document defines the target workflow. It does not claim that CI, coverage
gates, release automation, or a migration plan have already been implemented.
See [current adoption](../verification/standards_adoption.md) and [test commands](../verification/testing_evidence.md)
for the gates in use and the manual checks still required.

## Toolchain and dependencies

Pin an exact supported stable Flutter SDK for local development and CI, and use
its bundled Dart SDK. Record supported platform versions and the build tools
required for each target. Upgrade through a reviewed change that includes analyzer,
test, golden, and representative release-build verification.

For the application, commit `pubspec.lock` and resolve the locked graph in CI.
Use `flutter pub get --enforce-lockfile` to detect lockfile/content-hash mismatch
rather than silently accepting a different dependency set. See
[Dart pub get](https://dart.dev/tools/pub/cmd/pub-get).

Declare direct dependencies explicitly, put test/generation tools under
`dev_dependencies`, and choose version constraints deliberately. Do not use `any`
for convenience. A dependency override MUST have a reason, owner, and removal
condition; it must not conceal incompatible packages indefinitely. Review updates
and test the resulting graph. See
[Dart package dependencies](https://dart.dev/tools/pub/dependencies).

Before adding a package, record the capability it supplies, supported platforms,
maintenance health, license, security implications, and lifecycle/disposal model.
Prefer an existing platform/framework capability when adequate. Do not add a large
framework solely to avoid a few straightforward constructors.

Contact submission declares the already locked Dart-team `http` package as a
direct dependency. The BSD-3-Clause package uses the browser HTTP stack on web
and Dart I/O on native platforms. The application owns and closes the client,
and the adapter limits the lifetime and size of each response. This change keeps
the resolved dependency version and adds no platform permissions.

## Code generation and repository hygiene

Generated outputs MUST NOT be hand edited. Pin generator versions and document
the exact generation command. Choose a repository-wide policy per generator:
commit outputs and verify regeneration produces no diff, or regenerate before
analysis/build in CI. Never rely on uncommitted local outputs for a successful
build.

Keep generated-code exclusions narrow and tool-specific. Generated files must
still compile and integrate; excluding a file from coverage does not exclude it
from correctness checks. Generator-supplied lint suppressions are preferable to
excluding all generated code from analysis without a demonstrated need.

Keep build products, local credentials, machine-specific paths, caches, and editor
temporary files out of source control. Commit intentional public configuration
templates with instructions. Remove dead code, obsolete flags, and unused
dependencies as part of the relevant change.

For this repository, run `flutter gen-l10n` with the pinned SDK after changing
the ARB resources and commit the generated Dart files. CI regenerates the files
from the checked-out ARB before analysis, tests, and builds. Hosting deployments
use the resulting verified artifact. `task native:config` refreshes public FlutterFire native
snapshots using the existing Terraform app IDs and operator credentials; review
and commit the generated snapshots. `task native:check` verifies their environment
mapping without fetching cloud configuration. See [release tooling](../guides/web_releases.md)
for artifact and private symbol retention.

## Change design and review

Keep a change focused on one understandable outcome. Separate broad formatting,
dependency upgrades, and structural moves from behavior changes when practical.
Use descriptive imperative commit subjects; a particular commit-prefix framework
is optional unless release automation adopts one.

A pull request MUST describe the problem, resulting behavior, significant design
choices, validation, and known limitations. Include screenshots or short recordings
for material UI changes and migration/rollback notes for persistent data or release
behavior. Do not describe tests as passed unless they were run successfully.

Record consequential choices with [an ADR](../decisions/adr_template.md), including changes to
state management, module boundaries, configuration sources, persistence, error
contracts, and security-sensitive integrations. Small implementation choices need
only a review explanation.

Review checklist:

- Responsibilities and dependencies follow [architecture](architecture_standards.md).
- Async work, input validation, lifecycle, and types follow
  [coding standards](dart_flutter_coding_standards.md).
- Tests protect changed behavior and include the relevant failure paths.
- Configuration changes include schema/default documentation and environment checks.
- UI changes include applicable accessibility, localization, and performance evidence.
- Sensitive data, logging, permissions, and dependencies receive appropriate review.
- Public contracts, operational instructions, and generated artifacts stay current.

## CI quality gates

After adoption, every pull request MUST pass the following gates. Tool commands
are examples for a single Flutter package; run equivalent checks in every affected
package. Do not pass nonexistent directories to a command.

| Gate | Required behavior |
| --- | --- |
| Reproducibility | Install pinned SDK, resolve enforced lockfile, reproduce generated outputs |
| Format | Fail if maintained Dart source differs from the formatter |
| Analysis | Fail on errors, warnings, or informational diagnostics |
| Behavior | Run deterministic unit/widget tests and affected contract/integration tests |
| Coverage | Enforce the separately implemented policy in the testing guide |
| Documentation | Check relative links, examples, and changed contracts |
| Security | Scan committed material for secrets and review relevant dependency advisories |
| Build | Compile affected targets/configurations; smoke-test assembled startup |

Example core commands after prerequisites are in place:

```sh
flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed lib test
flutter analyze --fatal-infos --fatal-warnings
flutter test --coverage
```

Include existing `integration_test`, tool, and package source directories in the
format check. Run generation before checks when outputs are not committed. Check
goldens in their pinned environment. Never run `pub upgrade`, rewrite lockfiles,
or auto-approve golden changes as part of ordinary CI validation.

Tests and formatters are only part of enforcement: architecture boundaries,
accessibility, configuration mismatch checks, and coverage denominators need
explicit checks or review evidence. See [testing standards](testing_standards.md).

## Release and compatibility

Every release MUST identify its source revision, app version/build number, SDK,
dependency lockfile, build target, environment manifest, and artifact checksum.
Protect signing credentials in the release system. Verify the environment/native
resource mapping described in
[configuration standards](configuration_and_dependency_injection.md).

Build once per target/environment configuration and promote the tested artifact
through that configuration's delivery stages. A changed build-time configuration
creates a new artifact that needs verification. Smoke-test each supported release
target in release conditions, and retain the corresponding symbols and evidence.

Persistent schema and backend-contract changes MUST account for older clients,
interrupted upgrades, and rollback. Prefer backward-compatible staged changes.
Document whether rolling back the app is safe after a data migration; a backup or
tested forward repair may be required instead. Do not assume app-store updates
reach every user simultaneously.

Before release, name an owner, verify critical journeys, define actionable health
signals, and record a rollback/recovery procedure. After release, assess those
signals and track regressions. Keep user-facing release notes focused on behavior.

## Documentation maintenance

Update standards when an accepted decision changes them. Keep examples minimal
and distinguish executable snippets from sketches requiring application types.
Maintain a short setup path, configuration field contract, test commands, release
runbook, and ADR index as those capabilities are implemented. Do not leave a
document claiming a quality gate exists when it is only planned.
