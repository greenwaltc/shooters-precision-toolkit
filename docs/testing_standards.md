# Flutter and Dart testing standards

Status and requirement language: [engineering standards](README.md).

## Strategy and ownership

Tests MUST demonstrate observable behavior and protect meaningful contracts.
Choose the smallest test that can catch the failure. Most checks should be unit
and widget tests, with integration tests for critical assembled flows. There is
no mandated numerical ratio. See [Flutter testing overview](https://docs.flutter.dev/testing/overview).

| Level | Required evidence when the behavior exists | Boundary setup |
| --- | --- | --- |
| Unit | Rules, calculations, parsing, state transitions, repositories, failure mapping | Explicit dependencies; no live services |
| Widget | Visible states, interactions, validation, semantics, navigation entry points | Real widget tree with fake application dependencies |
| Contract | Each adapter/fake preserves the consumer-facing contract; external schema assumptions | Shared contract cases and controlled fixtures; sandbox checks where needed |
| Integration | Startup/wiring, critical user journeys, persistence, platform interactions | Real app on representative targets with isolated test services/data |
| Golden | Deliberately selected visual contracts | Pinned rendering environment and reviewed reference images |

Every bug fix SHOULD include a regression test that fails for the original
behavior. New nontrivial behavior MUST include success, relevant failure, and
boundary cases. Test a simple declarative UI change at the level where its risk
exists; do not add tests merely to repeat a getter or constructor implementation.

## Layout and naming

Mirror source responsibilities under `test/`, using `*_test.dart`. Put complete
journeys under `integration_test/`, fixtures under `test/fixtures/`, and reusable
fakes/builders under `test/support/`. Store golden images beside the relevant test
or in its `goldens/` directory. Avoid a shared mutable “test app” singleton.

Name groups for the subject and tests for the condition and expected outcome:
`rejects a production configuration with a staging endpoint`. Use Arrange–Act–Assert
ordering. A test should have one coherent behavior; multiple assertions are
appropriate when they describe the same result.

Use `package:test` in standalone Dart packages, and `flutter_test` for Flutter
package/widget tests. `test`, `group`, setup, and teardown provide the basic
structure; see [Flutter's unit-testing introduction](https://docs.flutter.dev/cookbook/testing/unit/introduction).

The following example assumes the configuration class from
[configuration standards](configuration_and_dependency_injection.md) has been
adopted and `example_app` has been replaced with the actual package name:

```dart
import 'package:example_app/app/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfig', () {
    test('rejects a production configuration with a staging endpoint', () {
      final values = <String, String>{
        'CONFIG_SCHEMA_VERSION': '1',
        'APP_ENV': 'production',
        'API_BASE_URL': 'https://api.staging.example.com/v1/',
      };

      expect(() => AppConfig.fromValues(values), throwsArgumentError);
    });

    test('uses a 15-second timeout when no override is supplied', () {
      final values = <String, String>{
        'CONFIG_SCHEMA_VERSION': '1',
        'APP_ENV': 'production',
        'API_BASE_URL': 'https://api.example.com/v1/',
      };

      final config = AppConfig.fromValues(values);

      expect(config.requestTimeout, const Duration(seconds: 15));
    });
  });
}
```

## Isolation, fakes, and async determinism

- Inject time, randomness, IDs, external clients, and filesystem locations when
  they affect outcomes. Fix random seeds and report them on failure.
- Unit and widget tests MUST work without internet access, real credentials,
  production data, or developer-machine state.
- Prefer small behaviorally accurate fakes. Use mocks for interactions that are
  themselves a requirement, such as sending a write once; avoid asserting private
  method order or incidental call counts.
- Keep fixtures minimal and anonymous. Name fixture builders after the meaningful
  variation; do not hide invalid combinations behind broad defaults.
- Register cleanup when allocating resources. Close subscriptions and temporary
  files; restore modified globals, viewport settings, and error hooks.
- Await futures and async expectations. Use controlled completion or fake clocks
  instead of wall-clock sleeps. Test cancellation, timeout, late completion,
  duplicate submissions, and disposal where those states are possible.
- Each test MUST pass alone and in any order. Shared external test runs require
  unique namespaces and cleanup that cannot delete another run's data.

For numeric behavior, derive tolerances from the specification and units. Test
limits, invalid/non-finite values, rounding, and useful invariants. Do not loosen a
tolerance merely to make a failing assertion pass.

## Widget and visual tests

Use `testWidgets` to build the smallest realistic tree with the theme,
localizations, routing, and injected state the component actually needs. Exercise
the public UI using text, semantics, or stable keys. Avoid selectors coupled to
incidental nesting. See [Flutter widget testing](https://docs.flutter.dev/cookbook/testing/widget/introduction).

Use explicit `pump` calls for known state transitions and animation intervals.
`pumpAndSettle` is appropriate only when all scheduled animations are expected to
finish; it can time out on an indeterminate loading indicator and can conceal
extra frames. Set a bounded timeout when using it. See
[WidgetTester.pumpAndSettle](https://api.flutter.dev/flutter/flutter_test/WidgetTester/pumpAndSettle.html).

Cover loading, empty, success, validation, and recoverable error states as
applicable. Include narrow/wide layouts, large text, relevant locales/directions,
and keyboard/focus behavior when supported. Verify semantic labels and interaction
availability; a screenshot alone cannot establish accessibility.

Golden tests are selective regression evidence, not the main behavior suite.
Pin Flutter version, OS/rendering environment, fonts, viewport, device pixel ratio,
locale, theme, and text scaling. Eliminate network images and timestamps. Review
image diffs when changing baselines; never automatically approve them in CI.
Await `expectLater` with `matchesGoldenFile`. See
[Flutter golden-file API](https://api.flutter.dev/flutter/flutter_test/matchesGoldenFile.html).

## Integration and platform coverage

Use Flutter's `integration_test` tooling for journeys through the assembled app.
Run on supported platform targets, choosing devices or emulators that exercise
the relevant plugins, permissions, navigation, and persistence behavior. A Flutter
widget integration test cannot necessarily operate native permission dialogs;
use an appropriate platform harness or an explicit manual check. See
[Flutter integration testing](https://docs.flutter.dev/testing/integration-tests).

Keep two purposes distinct: deterministic journeys with isolated/fake services,
and a smaller set of sandbox tests proving actual adapter/backend compatibility.
Do not claim a fake-backed test validates the live service. Never point automated
tests at production. Exercise upgrades and persisted-data migrations, not only
fresh installs. Include account changes, offline recovery, and interrupted writes
when those capabilities exist.

## Coverage, CI, and flaky tests

Project target: at least **80% line coverage of maintained handwritten Dart code**
once a coverage gate is adopted. This is a review signal, not proof of correctness
or an upstream Flutter requirement. Also review changed critical behavior directly;
a high aggregate percentage must not hide an untested new subsystem.

CI MUST report how unexecuted source files enter the denominator. Plain coverage
collection may omit never-loaded libraries; use explicit source inclusion or a
generated import harness and verify a newly untested file lowers the result.
Exclude generated/vendor code by reviewed patterns. Do not exclude whole feature
directories to meet the target. Document exceptions and ratchet a lower legacy
baseline separately during adoption. Critical rules need branch/edge-case review
regardless of line percentage.

Reference commands, after creating the relevant directories and dependencies:

```sh
flutter test --coverage
flutter test --test-randomize-ordering-seed=4729
flutter test integration_test -d <device-id>
```

Add validated build inputs to an integration invocation when it boots the real
app, and `--flavor` only on configured targets. The device command above is for
supported native device runs; web integration needs its documented browser/driver
setup. A future CI job must actually enforce coverage; `--coverage` only collects it.

Every pull request runs deterministic unit/widget tests and relevant contract
checks. Run affected integration journeys before merge; the release suite must
cover every supported platform's critical paths. Keep durations and failure
artifacts visible. See [development workflow](development_workflow.md).

Do not hide flakes with unlimited retries. Preserve the first failure, fix the
source, or quarantine with an owner, issue, expiry, and equivalent coverage for a
critical path. Unexplained skipped tests and silent golden updates fail review.
