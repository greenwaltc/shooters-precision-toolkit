# Class and function documentation standards

Status and requirement language follow the [project documentation index](../README.md).
These standards apply to Dart classes, interfaces, constructors, functions, and
methods. Effective Dart defines the language conventions. The requirements below
set the project baseline for which contracts to document.
[Effective Dart documentation](https://dart.dev/effective-dart/documentation)

## What to document

- Public classes and interfaces MUST describe their purpose. Public constructors,
  functions, and methods MUST document their behavior when they introduce a contract.
  An override MAY rely on the inherited documentation when that contract applies
  unchanged. Document observable behavior specific to an implementation, such as
  stricter supported limits, while preserving the interface contract.
- Private declarations SHOULD be documented when they carry a subtle invariant,
  precondition, ownership rule, or reason for a surprising choice. A clear name
  and signature are sufficient for straightforward private helpers.
- When a change affects caller expectations, update the declaration's documentation
  and any affected examples in the same change. Describe stable guarantees and
  point to a design document for broader rationale.

## Writing doc comments

Use `///` immediately above the declaration and before annotations such as
`@override` or `@Deprecated`. Give the declaration a short opening sentence on its
own, followed by a blank documentation line if more detail is needed. Start a
class summary with a phrase that names what the class represents. Use verbs such
as “Writes” or “Closes” for operations whose main purpose is a side effect.

Explain parameters, results, and exceptions in prose where their meaning matters.
Use Dartdoc links such as `[RetryBudget]` and `[RetryBudget.tryConsume]` for
resolvable declarations, and backticks for literals such as `null`. Use fenced
`dart` blocks for code samples. A sample SHOULD demonstrate a common use or a
subtle contract with realistic inputs and an observable result. Label partial
snippets when they depend on context outside the example.
[Effective Dart doc comments and Markdown](https://dart.dev/effective-dart/documentation#doc-comments)

## Classes and constructors

A class comment MUST state the abstraction's responsibility and any invariants
the caller or implementer must preserve. Include the applicable details below.

- What state instances own and whether that state can change.
- Whether construction copies, borrows, or takes ownership of inputs and resources.
- Who closes or disposes an instance, when it is safe to do so, and whether the
  instance can be reused afterward.
- Limits on sharing, concurrent calls, and required call order.

Put construction-specific constraints, defaults, and failures on the constructor.
Put guarantees shared by all implementations on the interface.

```dart
/// A finite allowance of retry attempts for one operation.
///
/// Attempts are consumed by [tryConsume]. Create a separate budget for each
/// operation that needs its own allowance.
final class RetryBudget {
  /// Creates a budget with [limit] attempts.
  ///
  /// Throws [RangeError] if [limit] is negative. A limit of zero allows
  /// no retries.
  RetryBudget(int limit) : _remaining = RangeError.checkNotNegative(limit);

  int _remaining;

  /// Consumes one attempt if available and returns whether it did so.
  ///
  /// Returns false when the budget is exhausted and leaves it unchanged.
  bool tryConsume() {
    if (_remaining == 0) return false;
    _remaining--;
    return true;
  }
}
```

## Functions and methods

Document what a caller needs to invoke the operation correctly and interpret
the result. Cover each applicable part of the contract.

- **Inputs.** State units, ranges, defaults, and the meaning of omitted or null
  values when the signature leaves room for interpretation.
- **Results.** Define what completion means and what an empty result, `null`, or
  a sentinel represents. State any promised ordering, mutability, or ownership.
- **Failures and effects.** Name expected exception types and what triggers them.
  Describe observable mutations, I/O, and any effects that can remain after a
  failure. Explain when repeating an operation is safe if callers may retry it.
- **Asynchronous behavior.** Distinguish synchronous throws from errors delivered
  through a future or stream where callers need that distinction. Describe
  cancellation, timeouts, subscription ownership, or overlapping calls when
  they affect observable behavior.

```dart
/// Returns the first index whose reading meets or exceeds [threshold].
///
/// Both [readings] and [threshold] use degrees Celsius. Returns null if
/// no reading meets or exceeds the threshold.
int? firstThresholdCrossing(List<double> readings, double threshold) {
  for (var index = 0; index < readings.length; index++) {
    if (readings[index] >= threshold) return index;
  }
  return null;
}
```

## Review

Compare the comments with the signature and observable behavior. Check that any
documented edge cases, examples, and links still hold. Use `dart doc --dry-run .`
when checking Dartdoc rendering inputs and references without generating files.
[The Dart documentation command](https://dart.dev/tools/dart-doc)
