# Security and diagnostic operations

The application maintainer owns release review, access, and incident response.
Production and development use separate Firebase projects; use the disposable
emulator commands for security tests. A verified Firebase account and
owner-scoped Firestore rules protect project reads and writes. The rules suite
checks signed-out/unverified callers, cross-account access, bounds, revisions,
tombstones, and recent authentication for deletion requests. The client also
refuses to open a workspace if a restored account cannot obtain a verified
token. An expired session offers sign-out and a fresh sign-in. Emulator tests
cannot prove the deployed project's IAM settings or live token revocation.

| Data | Access and retention |
| --- | --- |
| Account email and credentials | Firebase Auth handles credentials. Forms retain input only while mounted. On web the SDK's persisted session is accessible to scripts on the app origin; the local emulator uses in-memory Auth persistence. Native sessions use the platform storage provided by Firebase Auth, not app preferences. Sign-out tears down private routes and listeners. |
| Projects, design and measurements | Firestore is the durable record. There is no disk project cache or offline draft store in the app. Pending edits live in the active workspace and expire with it. Owners can delete projects; existing soft-delete/deletion request handling is distinct from an operator's permanent purge. |
| UI preferences | Shared preferences store ordinary settings, not credentials or measurement data. |
| Exports and clipboard | User-initiated file and clipboard actions can contain measurements and names. They are not uploaded by the app. Files and copied text can outlive a session; the person initiating export controls their distribution and deletion. Browser screenshots used for tests contain only synthetic data. |
| Diagnostics | App-generated records stay in the local browser console or native log. There is no collection endpoint, analytics integration, or offline telemetry queue. Share only relevant sanitized events in a private issue and remove the attachment when the incident is resolved. |

External link navigation permits only reviewed HTTPS destinations and uses
normal certificate validation. Help cannot fetch third-party images. The app
does not request camera, contacts, location, or storage-wide permissions; file
export uses the platform picker/download. Dev-only native configurations permit
the emulator transport; the native validator rejects production exceptions.
Do not add private SDK keys or signing credentials to client manifests.

Diagnostic events carry component, severity, outcome, environment, configuration
schema and build identity, plus timing when measured. Framework and uncaught
async hooks feed the same boundary. It keeps only bounded app code locations and
stable failure categories. It does not record account IDs, emails, passwords,
tokens, URL queries, document values, or arbitrary exception messages. Startup
and the signed-in workspace show safe recovery text when a service fails.

| Signal | Response |
| --- | --- |
| Startup errors or slow `startupReady` events | Confirm the served build ID, environment, and origin. Reproduce with a fresh browser and compare the previous release. Verify SDK project mapping and emulator reachability for local builds. |
| Repeated `authFailed`, load or save failures | Reproduce with a designated test account. Distinguish expired/denied, unavailable, and conflict outcomes. Check Firebase console usage and service status; retry only once connectivity and ownership are confirmed. Do not ask for a token or private payload. |
| A repeated framework error or export failure | Preserve the sanitized event and matching private symbols, record viewport/browser/OS and steps, and revert the live Hosting release if a critical flow is affected. |

**Operational exception:** There is no automated crash-rate or latency alert.
This keeps the current Spark deployment free of another data collector and avoids
retaining session data. CI startup and browser journeys, post-release smoke checks,
Firebase console usage and manual reports are compensating checks. The application
maintainer reviews this decision by **2027-02-01** or before expanding the release
audience. See [ADR 0002](decisions/0002_local_diagnostics.md) and
[web releases](web_releases.md).

**Dependency exception:** The isolated Node rules harness pins
`@grpc/grpc-js` **1.13.7** under Firestore's transitive dependency to address
[the certificate advisory](https://github.com/grpc/grpc-node/security/advisories/GHSA-m9gg-hp2v-232j)
and [error-message advisory](https://github.com/grpc/grpc-node/security/advisories/GHSA-f596-whhp-79r4).
It is not in the Flutter web or native artifact. The test tooling owner removes
the override when Firebase's locked dependency resolves to a patched version
without it, then reruns the rules suite and npm audit. Review by **2027-02-01**.
