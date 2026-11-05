# ADR 0001: Application boundaries and presentation state

- Status: Accepted
- Date: 2026-11-04
- Owner: Application maintainer
- Related standards: architecture, configuration, testing, coding

## Context

The application edits one experiment through a project list, design, matrix and
results. Those screens share one editing model, revision and save lifecycle.
Splitting them into independent features would introduce circular dependencies
and duplicate ownership. Authentication and public contact content have separate
lifetimes and responsibilities. Existing widgets use ChangeNotifier and Provider.

## Decision

Use feature-first organization: authentication, experiments and contact. Within
experiments, organize presentation by projects, Test Design, matrix and results.
Keep repository contracts, immutable persistence snapshots and substantial numeric
rules independent of Flutter, Firebase and grid/chart packages. Adapters depend on
these contracts. The application composition root constructs concrete adapters and
session state. Shared UI receives callbacks/projections rather than importing a
feature's state or creating platform clients.

ChangeNotifier is the principal presentation-state convention; Provider distributes
owned dependencies through the widget boundary. Local focus, expansion and
animation state stays local. The workspace owns editable models and in-flight
saves for one account; repositories own durable cloud data. No second writable
project source is introduced. Domain snapshots and pagination cursors cross
repository boundaries; Firebase snapshots remain adapter details.

Expected recoverable failures use a consistent **typed exception** contract, an
explicit alternative to the architecture guide's default result values. Existing
async store operations and Future/Stream consumers already preserve pending/failed
state with exceptions. App-owned failure categories preserve that flow without
wrapping every stream event in a result. Vendor exceptions are translated at the
adapter boundary; unexpected defects retain their stack for diagnostics. Widgets
show safe localized messages. Conditional revisions retain conflict semantics.

## Alternatives and tradeoffs

Separate features for every screen would create cycles and pass-through layers.
A new state framework or a full result-envelope rewrite would expand regression
risk without addressing a current variation. Keeping layer-first global folders
would hide ownership. The chosen structure retains familiar state behavior while
making SDK replacement and pure calculation testing possible.

## Consequences and verification

Imports are checked automatically, including transitive purity of API/domain
libraries and cross-feature cycles. Tests mirror final feature responsibilities.
Shared repository cases run against fake, volatile and emulator implementations;
assembled browser journeys protect design, entry, results and persistence.
The Firestore document schema and revision protocol remain compatible with older
valid documents. Structural changes require an ordinary app rollback; no backend
data migration is introduced. Manual native/accessibility/performance release
evidence remains governed by [UI acceptance](../verification/ui_acceptance.md)
and the [release runbook](../guides/web_releases.md).

Revisit when another independent capability needs reuse, a second persistence
adapter changes semantics, or the state convention becomes a measured obstacle.
