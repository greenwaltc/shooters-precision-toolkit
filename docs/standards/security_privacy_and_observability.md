# Security, privacy, and observability standards

Status and requirement language: [engineering standards](../README.md).

## Trust boundaries and access

Treat clients, deep links, imports, remote configuration, and network payloads as
untrusted. Validate types, lengths, ranges, schemes, and allowed operations at each
boundary. Each new external integration MUST identify the data exchanged, who can
access it, likely misuse, and how failures are contained. Use the
[OWASP Mobile Application Security Verification Standard](https://mas.owasp.org/MASVS/)
as a review framework for mobile capabilities; it is not a claim of certification.

Authorization MUST be enforced by the trusted service for every protected operation
and resource. Hiding a button or checking a role in Flutter only controls the UI.
Prefer least privilege and deny by default. Include tests for attempts to access
another user's resources and for expired/revoked sessions. See
[OWASP authorization guidance](https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html).

Request device permissions only when needed, explain the feature purpose, and
handle denial or revocation. Validate external navigation destinations; never
launch arbitrary schemes from untrusted strings. Define account-switch behavior
so data from the previous identity cannot remain visible.

## Storage, transport, and dependencies

Classify collected data and minimize what is stored. Sensitive session material
MUST use an appropriate platform-backed storage mechanism on native targets.
Ordinary preferences are not a credential store. Review temporary files, backups,
exports, screenshots, and clipboard use as additional exposure paths. See
[OWASP secure storage](https://mas.owasp.org/MASVS/controls/MASVS-STORAGE-1/).

Web requires a separate session/storage design: native secure-storage guarantees
do not carry over to browser storage. Document script-access, persistence, and
sign-out behavior. Sensitive user caches MUST be cleared or made inaccessible on
sign-out/account change. Define retention, deletion, and export behavior before
collecting new categories of personal data.

Use authenticated TLS with normal certificate validation for remote services.
MUST NOT ship trust-all certificate callbacks or production cleartext exceptions.
A local-development transport exception requires explicit environment scoping
and release checks. See
[OWASP network communication](https://mas.owasp.org/MASVS/controls/MASVS-NETWORK-1/).

Keep private keys and server credentials outside the client, following
[configuration standards](configuration_and_dependency_injection.md). Use supported
cryptographic/authentication libraries; do not invent security protocols. Review
new plugins for platform permissions, data collection, maintenance, licensing, and
transitive dependencies. Address known relevant vulnerabilities with a tracked
owner and priority.

## Logs and telemetry

Production diagnostics MUST use a structured reporting boundary rather than
scattered `print` calls. Include a stable event name, severity, component, outcome,
duration, and non-sensitive correlation identifier when useful. Sanitize untrusted
text, bound event size, and redact before data leaves the device. See
[OWASP logging guidance](https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html).

Never log passwords, access/refresh tokens, authorization headers, raw private
payloads, or full URLs containing sensitive query parameters. Avoid raw user IDs,
precise location, and free-form user text unless an explicitly justified, protected
diagnostic requirement exists. Do not assume exception messages are safe.

Project conventions:

| Severity | Purpose |
| --- | --- |
| Debug | Local diagnosis; disabled or tightly controlled in production |
| Info | Significant lifecycle/business operation outcomes without personal payloads |
| Warning | Recovered degradation that needs operational visibility |
| Error | Failed operation or defect requiring investigation |

Specify collection purpose, retention, access, sampling, and applicable consent.
Separate analytics from crash/error reporting so their policies can differ. Bound
offline buffers. Reporting failures MUST NOT recursively report themselves or
block the primary user operation indefinitely.

## Error reporting and operational readiness

At bootstrap, install appropriate Flutter framework and uncaught async error
handlers. `FlutterError.onError` and `PlatformDispatcher.instance.onError` cover
different paths; neither replaces local error recovery. Worker isolates need their
own error forwarding when used. Retain useful stack traces and avoid duplicate
reports. See [Flutter error handling](https://docs.flutter.dev/testing/errors).

User-facing errors MUST be safe, localized, and actionable. Keep internal stack
traces and backend details out of the UI. When an operation cannot safely continue,
show a controlled failure state instead of reporting success. Preserve developer
diagnostics during local development.

Record app version, build identifier, environment, and configuration schema with
diagnostic events. Keep symbol/source-map artifacts accessible to authorized
debugging systems with the matching build. Define ownership and response for
signals such as startup failures, crash rates, request failures, and slow critical
flows. Alert on actionable changes, with a runbook and sufficient context to
reproduce them.

Verification MUST cover redaction, configuration isolation, denied access, session
cleanup, and error reporting behavior for the applicable feature. Release evidence
and dependency review follow [development workflow](development_workflow.md).
