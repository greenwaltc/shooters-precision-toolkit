# Software architecture standards

Status and requirement language: [engineering standards](../README.md).

## Principles and baseline

Choose the smallest structure that makes responsibilities, state ownership, and
dependencies clear. Optimize for safe change and testability before introducing
frameworks or abstractions. Prefer composition to inheritance, high cohesion
within a component, and narrow contracts between components. Do not generalize
until there is a real variation to support.

The baseline has a presentation layer and a data layer, with an optional pure-Dart
domain layer for substantial or shared business rules. This adopts Flutter's
separation of views, presentation logic, repositories, and external services.
See [Flutter's architecture guide](https://docs.flutter.dev/app-architecture/guide).

| Component | Owns | Must not own |
| --- | --- | --- |
| View/widget | Rendering, semantics, local interaction, forwarding user intent | Network/storage calls or business calculations |
| View model/controller | Presentation state, coordinating an operation, translating results for display | Vendor SDK details or persistent source-of-truth data |
| Domain model/use case, when justified | Invariants, calculations, cross-repository workflows | Flutter imports, navigation, transport formats |
| Repository contract and implementation | Application data, cache/sync policy, mapping external data and failures | Widget state or navigation |
| Service/adapter | One external system or platform capability | Cross-feature business decisions or UI state |
| Composition root | Construction, configuration, scopes, startup, shutdown | Feature behavior |

“View model” describes a role. A controller, notifier, or BLoC MAY fill it. Choose
one principal presentation-state convention for the application and document the
choice in an ADR. Do not mix competing approaches within a feature without a
specific reason. A package name does not determine an architecture.

## Dependency direction

Application behavior MUST depend on contracts rather than constructing vendor
clients. Constructors expose dependencies. Widgets access composition through the
UI boundary; domain and data code MUST NOT look up global containers.

```text
View -> presentation logic -> repository contract
                         \-> optional use case -> repository contract
Repository implementation -> service/adapter -> external system
Composition root -> concrete implementations and their wiring
```

Arrows represent allowed dependencies, not the direction of notifications.
Repository contracts and app models belong in a framework-independent API owned
by the feature. Implementations depend on that API. The composition root is the
place permitted to import concrete implementations from multiple features.

These boundaries apply the single-responsibility and dependency-inversion
principles. Interfaces SHOULD describe what consumers need; do not copy every
vendor method into an oversized abstraction. Implementations MUST honor the same
semantics for absence, failures, ownership, and ordering, including test fakes.
Extend behavior through a new implementation when variation exists; do not create
an interface for every immutable value or private helper.

Use cases SHOULD be introduced for meaningful shared rules, complicated operations,
or coordination across repositories. A simple screen MAY call a repository contract
directly. Avoid mandatory pass-through layers. Flutter likewise treats domain/use
case layers as conditional in its
[architecture recommendations](https://docs.flutter.dev/app-architecture/recommendations).

## Feature organization

Project choice: organize by capability first, then responsibility. A possible
starting structure is:

```text
lib/
  main.dart
  app/
    bootstrap.dart
    config/
    routing/
    theme/
  features/
    catalog/
      api/                   # Public models and repository contracts
      data/                  # Implementations, adapters, transport mapping
      domain/                # Optional calculations and use cases
      presentation/          # Screens, state, view models, local widgets
  shared/
    ui/                      # Reusable visual components
    foundation/              # Small framework-independent contracts
test/                        # Mirrors lib's feature/responsibility paths
integration_test/            # User journeys crossing real boundaries
```

Create directories only when needed. This tree is a proposal, not a description
of the current repository. Prefer a feature's public API over imports into its
internal data or presentation files. Cross-feature dependencies MUST be acyclic.
Move genuinely shared concepts to a clearly owned module or coordinate them in
an application use case. Do not turn `shared` into a miscellaneous dumping ground.

Extract a separate Dart package only when independent reuse, ownership, dependency
enforcement, or build isolation justifies it. Directory names alone do not enforce
boundaries; review imports and add automated checks as the module graph grows.

## State and event flow

Repositories own shared application data; presentation objects derive screen
state. User intent flows into operations, and observable results flow back to the
view. Prefer immutable snapshots. Never maintain independently writable copies of
the same shared entity in several view models. This follows Flutter's
[unidirectional data-flow guidance](https://docs.flutter.dev/app-architecture/concepts).

Each feature MUST define:

- Its initial, loading, success, empty, and recoverable failure behavior, as
  applicable. Preserve useful existing data during refresh when appropriate.
- Whether repeat operations are disabled, deduplicated, queued, or concurrent.
- How stale responses are rejected, and what cancellation actually stops.
- State lifetime: widget, route, authenticated session, or application.
- Whether state survives process restart, and how persisted state is migrated.

Do not put transient focus, expansion, or animation state into a global store.
Navigation remains a presentation/application concern. Deep links MUST be parsed
as untrusted input, handle missing resources, and support applicable back/forward
behavior. Route visibility is not an authorization boundary.

## Data and failure contracts

At each external boundary, validate payloads and translate them into app-owned
types. Separate transport and domain models when schemas, semantics, or lifetimes
diverge; avoid mechanically duplicating identical types. Document identifiers,
nullability, time zones, units, precision, and schema evolution.

Store instants consistently, normally in UTC; represent calendar dates and local
appointments explicitly when they are not instants. Keep calculations in canonical
units and convert at presentation boundaries. Define rounding and numeric error
tolerances before writing tests. Do not use floating-point equality for values
whose computation permits rounding error.

Project default: represent expected recoverable failures with typed result/failure
values at repository APIs. Name meaningful cases such as unavailable, denied,
invalid input, or conflict. Do not use nullable success data as an error channel.
Unexpected defects propagate to the diagnostic boundary. Low-level SDK exceptions
MUST NOT escape into widgets. A different consistent error contract needs an ADR.

Caching, retries, and synchronization belong to an explicit owner. Specify cache
freshness, invalidation, identity isolation, conflict resolution, and whether a
write is pending or durable. Retry only eligible transient failures with bounds
and backoff; retries of writes require idempotency or equivalent deduplication.
Do not silently treat stale data as current or optimistic writes as committed.

## Review and verification

Before accepting a boundary change, check that:

- A consumer can be tested using explicit dependencies and no live backend.
- A dependency can be replaced without changing business rules or widgets.
- State, resource lifetimes, failures, and concurrency have named owners.
- Persistence or API changes have compatibility and migration tests.
- Complexity has a concrete benefit and consequential decisions have an
  [ADR](../decisions/adr_template.md).

Use [configuration and injection](configuration_and_dependency_injection.md) for
wiring and [testing standards](testing_standards.md) for evidence. No architecture
diagram substitutes for testing the assembled application.
