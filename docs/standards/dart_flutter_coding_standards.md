# Dart and Flutter coding standards

Status and requirement language: [engineering standards](../README.md).

## Formatting, names, and imports

Code MUST use `dart format` from the pinned SDK. Use the default 80-column page
width; let the formatter control wrapping and trailing commas. Do not manually
align code or add formatting exceptions for personal preference. This makes
formatting reproducible in editors and CI. See [dart format](https://dart.dev/tools/dart-format).

Use `UpperCamelCase` for types and extensions, `lowerCamelCase` for members,
variables, parameters, and constants, and `lowercase_with_underscores` for files,
directories, packages, and import prefixes. Spell multi-letter acronyms as words
(`HttpClient`, `apiUrl`). Order imports in separate groups: `dart:`, `package:`,
then relative imports; sort each group. Put exports after imports. Use braces for
control flow. These conventions follow
[Effective Dart: Style](https://dart.dev/effective-dart/style).

Project choices:

- Use relative imports within `lib`; use `package:` imports from tests or other
  directories into `lib`. Never traverse across the `lib` boundary with `../`.
- Keep one primary responsibility per file. Closely related private helpers or
  sealed variants MAY share a file. There is no arbitrary file-length limit.
- Prefer names that expose meaning and units: `timeout`, `distanceMeters`,
  `isLoading`. Avoid `Helper`, `Manager`, or `Utils` when a precise responsibility
  can be named.
- Use single-quoted strings unless another form reduces escaping. Avoid broad
  barrel exports; export only the intentional public surface of a feature.

## Types, values, and public APIs

Public APIs MUST declare parameter and return types. Use inference for obvious
local variables, `final` for values assigned once, and `const` when supported.
Prefer required named parameters for dependencies and ambiguous arguments. Use
enums or sealed types for closed sets. Keep declarations private unless another
library needs them. These defaults build on
[Effective Dart: Design](https://dart.dev/effective-dart/design).

- Use `Object?` for an unknown value requiring validation. `dynamic` MUST be
  confined to a documented interop or deserialization boundary.
- Do not use `!`, unchecked casts, or `late` to silence modeling problems. A use
  MUST have an explainable invariant; test externally influenced invariants.
- Model absence deliberately. Distinguish missing data, an empty result, a loading
  operation, and a failure; do not overload `null` with all four meanings.
- Prefer immutable data exposed across boundaries. A `final List<T>` is still
  mutable: copy and expose unmodifiable collections where callers must not mutate.
- Validate external input in executable code. Assertions are for developer
  invariants and MUST NOT implement required release-mode validation.
- Avoid flags that create unrelated modes in one method. Split distinct operations
  or introduce a meaningful options type when the use case needs it.

For example, an injected collaborator and a typed value make a dependency visible:

```dart
abstract interface class ReadingRepository {
  Future<double?> latestValue();
}

final class ReadLatestValue {
  const ReadLatestValue({required ReadingRepository repository})
    : _repository = repository;

  final ReadingRepository _repository;

  Future<double?> call() => _repository.latestValue();
}
```

This small example demonstrates syntax, not a requirement to wrap every repository
method in a use case. See [architecture standards](architecture_standards.md).

## Async work, failures, and resources

Prefer `async`/`await` when it improves control flow, and return `Future<void>` for
async operations without a result. Catch errors at a boundary that can translate,
recover, or report them. Catch specific expected exceptions; preserve stack traces
with `rethrow` when propagating the same failure. Do not convert programmer errors
into a successful empty result. See
[Effective Dart: Usage](https://dart.dev/effective-dart/usage).

Every future MUST be awaited, returned, or deliberately detached with a documented
error and lifetime policy. `unawaited()` only expresses intent; it does not catch
errors or cancel work. Detached work must handle failure itself or have an explicit
owner that observes it. See [unawaited](https://api.dart.dev/dart-async/unawaited.html).

The creator owns disposal unless ownership is explicitly transferred. Cancel
subscriptions and timers; dispose controllers, notifiers, and owned clients. Avoid
closing shared dependencies from a short-lived consumer. Define how operations
behave when disposed, canceled, repeated, or completed out of order. A timeout does
not automatically cancel the underlying request.

Use bounded concurrency for batches. Retry policy belongs at a designated data
boundary, not independently in every caller. Never add fixed delays to make races
appear to disappear.

## Flutter-specific rules

- Keep `build` synchronous and free of network calls, persistence, registration,
  analytics emission, and state mutation. Trigger work through lifecycle-aware
  initialization or explicit user actions.
- Prefer small widgets with `const` constructors where possible. Extract widgets
  when they have their own layout, semantics, lifecycle, or reuse boundary.
- Keep local visual state near its widget. Put reusable application behavior in
  the presentation or domain layer; see [architecture](architecture_standards.md).
- After an async gap, check the relevant `context.mounted` before using that
  context. Check `State.mounted` before `setState`; neither check prevents stale
  results from overwriting newer state. See
  [BuildContext.mounted](https://api.flutter.dev/flutter/widgets/BuildContext/mounted.html).
- Use stable keys when identity matters in reordered collections. Do not generate
  a new `UniqueKey` on every build. Use `GlobalKey` only for a specific need.
- Do not retain `BuildContext` in repositories, services, or domain objects.
- User-visible strings, layout, accessibility, and performance follow
  [UI quality standards](ui_quality_standards.md).

## Analyzer baseline

Flutter packages MUST start with `flutter_lints`; standalone Dart packages use
`lints/recommended.yaml`. Pin compatible dependency constraints and the SDK as
described in [development workflow](development_workflow.md). The following is the
target `analysis_options.yaml` for a Flutter package, not an edit to today's file:

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true

linter:
  rules:
    always_use_package_imports: false
    prefer_relative_imports: true
    directives_ordering: true
    unawaited_futures: true
    discarded_futures: true
    avoid_void_async: true
    cancel_subscriptions: true
    close_sinks: true
    use_build_context_synchronously: true
    avoid_print: true
```

Require a clean analyzer result, including informational diagnostics, for compliant
code. The baseline combines strict type checks with additional project rules;
analyzer configuration is described in
[Customizing static analysis](https://dart.dev/tools/analysis).

Use the narrowest justified suppression, naming the rule and reason. Do not
disable a rule globally to accommodate one call site. Do not blanket-exclude
handwritten code or tests. Generated-code handling belongs in
[development workflow](development_workflow.md).

## Comments and documentation

Use `///` for public contracts with non-obvious behavior. Document units, failure
semantics, ownership, side effects, and ordering guarantees where relevant.
Comments should explain a constraint or decision, not narrate syntax. A TODO MUST
identify the missing outcome and a tracking reference. Remove dead code rather
than commenting it out.

Reviewers MUST check behavior and ownership as well as lint compliance; static
analysis cannot prove that an architectural or concurrency contract is correct.
