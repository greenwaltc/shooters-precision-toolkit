# Application architecture and lifetimes

See [ADR 0001](decisions/0001_application_boundaries.md) for the boundary and state
management decisions. `lib/main.dart` starts Flutter; `lib/app/application.dart`
composes adapters, the auth gate, routes and session-owned state. The code is
organized by capability:

- **Auth**: pure account/operation contracts, Firebase Auth adapter, and sign-in,
  verification, session gate and sign-out presentation.
- **Experiments**: app-owned project snapshots, bounded pages and cursors, pure
  test-design rules, calibration and ANOMR arithmetic, Firestore/session adapters,
  and projects, design, matrix and results presentation.
- **Contact**: public placeholder and navigation. No contact address or contact
  submission service is shipped.
- **Shared**: small pure contracts, generated localization, visual components,
  and explicit platform adapters for clipboard events, preferences, links and
  file saving. Shared code does not import features or the composition root.

Run `node scripts/check_architecture.mjs` to check import direction, purity and
feature cycles. Presentation widgets use Provider for distribution; domain and
data code receive typed constructors. Adapters translate vendor failures to
`AppFailure`; no Firebase exceptions are required in views.

| Capability | State, concurrency and lifetime |
| --- | --- |
| Authentication | Startup waits for the auth stream; signed-out, unverified and verified states are distinct. One form operation runs at a time. Verified profile and token claims are both required. The gate keys verification and workspace by project and account, so old futures cannot publish a new account's UI. The SDK owns credentials; UI owns form controllers only. |
| Projects and sync | A session store subscribes to one bounded recent page plus the selected project. Load/pagination requests deduplicate, pagination generations reject stale cursors, and writes serialize. Initial server availability is bounded to 15 seconds with a retry state. Cache metadata is distinct from server authority, and a cached miss cannot delete an editable project. Acknowledged revisions and pending writes are distinct. |
| Test Design | One editable notifier per project holds active and inactive factor slots. Validation precedes matrix navigation. Cloud snapshots remain immutable; the store creates an editable model only at the presentation boundary. |
| Matrix | Route owns grid controllers, focus, selection, clipboard listeners and undo history. Stable storage indices preserve entered values through reordering and responsive rebuilds. Focus and selection do not survive restart; saved values and row order do. |
| Results and exports | Domain receives typed numeric observations; it has no knowledge of grid, chart, colors or navigation. Presentation maps results into labels/geometry and owns export busy state. File selection is a platform capability with explicit cancellation. No export data is uploaded. |
| Contact and shared chrome | Static localized content, a bounded menu and injected navigation callbacks. There is no background work or private state. |

Each repository write freezes its `ProjectDocument` synchronously to a
`ProjectSnapshot` before awaiting external work. Read snapshots own their
collections and carry revision/authority separately from the editable content.
Firestore pagination uses a private adapter cursor, never a vendor object in the
app API. Version 1 field names, enum identifiers, UTC instants and measurement
values retain the existing persistence representation. The app edits in the
user's chosen unit without unit conversion; computation uses finite doubles and
display rounding does not change persisted values. No legacy import or disk draft
recovery is required by the product scope.

On a write conflict, keep the unsaved session draft and offer retry/review,
discard against an authoritative version, or save a copy under a new ID.
An older acknowledgement never clears a newer draft. Save retries are bounded
by user actions and the SDK's transaction policy. The store cancels subscriptions
and timers on disposal and uses generation checks for operations that cannot
actually be cancelled. Sign-out flushes pending writes first and removes private
routes and session state. The server still enforces ownership and verified email.

Named routes are drawn from an allowlist; private pages require the verified
workspace and a usable selected project. Route visibility is not authorization.
See [configuration](app_configuration.md), [test evidence](testing_evidence.md),
and [UI acceptance](ui_acceptance.md) for adjacent contracts and verification.
