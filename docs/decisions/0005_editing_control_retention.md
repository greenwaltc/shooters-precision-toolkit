# ADR 0005: Transfer editing control on intentional project open

- Status: Accepted
- Date: 2026-11-11
- Owner: Application maintainers
- Related standard: [Architecture](../standards/architecture_standards.md)
- Supersedes: Opening/retention policy in [ADR 0003](0003_project_editing_handoff.md)

## Context

An editor ID can outlive its browser tab, application process, or active use.
Previously a new device opening an already claimed project started read-only,
even when the previous device was closed. The stored ID cannot tell whether
that device is still active. Revision checks already protect against stale saves.

## Decision

Editing control is retained until another session intentionally opens the
project or requests editing in an already open editor. Selecting a project in
Projects now requests a takeover and loads the acknowledged server snapshot
before navigation. Reload restoration continues to use the same policy.

An idle/background session never reacquires control merely because it receives
a snapshot or becomes visible. After displacement it remains read-only until
the user deliberately opens the project again or selects an editable field.
Closing a tab does not reserve the project against the next device's open.

The existing store refuses handoff over a local dirty or saving draft. Failed
claims show localized connection feedback and leave the project available for
viewing and explicit retry. A displaced editor keeps unsaved input in the
existing draft recovery flow. Handoff does not change project content or its
last-modified timestamp. Firebase account ownership remains the authorization
boundary; this policy coordinates sessions of that account.

## Alternatives and tradeoffs

A time lease would delay new-device access until expiry and require heartbeat
writes, timestamp metadata, compatible rule deployment, and background lifecycle
handling. Browser unload callbacks are unreliable on process termination and
mobile. Intentional opening makes the new device usable immediately without
timers or additional backend writes while idle. Opening a project elsewhere can
displace an active editor; its unsaved draft is preserved for recovery.

## Adoption and validation

There is no schema or Firestore rule change. Existing persisted editor IDs and
older clients remain compatible. Rolling back restores the earlier explicit
field-tap handoff policy without a data migration. Widget regressions cover
opening, claim failure, displacement without automatic reacquisition, and draft
preservation. Existing emulator contracts verify revision conflicts and handoff
in both directions. Desktop Enter entry is separately tested across a delayed
autosave acknowledgement.

## Revisit conditions

Revisit when simultaneous editing is required, opening must support a separate
view-only intent, or device-specific authorization becomes necessary.
