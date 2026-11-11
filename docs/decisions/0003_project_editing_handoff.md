# ADR 0003: One editing session per project

- Status: Accepted
- Date: 2026-11-05
- Owner: Application maintainers
- Related standard: [Architecture](../standards/architecture_standards.md)
- Opening/retention policy superseded by [ADR 0005](0005_editing_control_retention.md).

## Context

Two sessions of the same account can open the same project. Each save replaces a
whole snapshot, so a stale session can hit a revision conflict even if the users
edited different cells. Switching devices should load the latest saved project
and let the new session edit it.

## Decision

The Firestore adapter assigns an opaque ID to each workspace instance. A project
document can store that ID in the optional `editorSession` field. Opening an
editor can claim an unowned project. Tapping a Group Size cell in a read-only
matrix or activating a field or option in read-only Test Design transfers
control. The new editor receives the server snapshot from the claim transaction.
For a Test Design option, choose it again after the handoff to apply it to the
current design.

A browser reload also transfers control of the selected project. Tab-scoped
session storage remembers the project ID and page for that account. Results
reopen in the Data Matrix. Reloading the Projects list transfers control of the
last selected project and keeps the list open. A reload without a remembered
project has no editing target.

A claim advances the same revision used by conditional saves. It leaves the
project data and its last-modified timestamp intact. A save checks the current
editor and expected revision in the same transaction. The store follows the
project stream and makes the losing session read-only. If that session has an
unsaved draft, the existing conflict controls let it save a copy or reload the
cloud version. The draft lives in that workspace's memory until resolved or the
workspace closes.

## Tradeoffs and deployment

This coordinates cooperating app sessions of one Firebase account. The Firebase
account remains the authorization boundary. The rules validate that a claim
only changes the editor and revision and that normal saves preserve the editor.
They continue to enforce verified ownership and project validation.

The design uses a write on acquisition or takeover, with no polling or
heartbeat. Taking over is available even when the previous device is gone. A
takeover uses the latest saved data. Unsaved input from the previous session
stays available there for recovery.

Existing projects are claimed on demand. The editing field is persistence
metadata and stays outside the portable JSON schema. Publish the Firestore rules
via Terraform before publishing a client with handoff support. Once a project
has been claimed, a client built before this change must refresh to edit it.

## Validation

The emulator contract covers both directions of handoff, rejection of a write
from the displaced editor, and recovery of unsaved data. Rules tests cover
unauthorized claims, malformed metadata, and attempts to mix claims with data
changes or remove a claim. Revisit the design if the app needs simultaneous
editing or server-side authorization of individual devices.
