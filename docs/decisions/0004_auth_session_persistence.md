# ADR 0004: Firebase-managed sign-in persistence

- Status: Proposed
- Date: 2026-11-10
- Owner: Application maintainers
- Related standards: [Security and privacy](../standards/security_privacy_and_observability.md), [Architecture](../standards/architecture_standards.md)

## Context

Users need password-manager support and a lightweight choice to remain signed in
between visits. Passwords and refresh tokens must not be copied into application
preferences. Firebase already owns authentication, token refresh and revocation.

## Decision

The login and registration forms offer **Stay logged in**, initially checked.
`AuthRepository` accepts this choice; the injected `AuthSessionPolicy` applies it
before authentication can expose an account. Policy failures stop the attempt.

On web, the Firebase adapter selects `LOCAL` when checked and `SESSION` when
unchecked. A session survives reloads in the same tab; Firebase's session storage
normally ends when the tab/window closes. Browser restoration settings can extend
that lifetime. Local persistence survives browser restarts until sign-out or
server-side invalidation. Browser storage is script-accessible and is subject to
browser restrictions and clearing. This choice does not change Firestore caching.

On native targets, Firebase retains credentials using its supported native SDK
storage. The app stores only a boolean under
`auth_stay_signed_in_v1/<project-id>/<app-name>`. Bootstrap clears a restored account
before exposing it if the previous choice was false. Missing values preserve the
existing persistent default; malformed values clear the account. Backgrounding
does not end a session; a new process does when opted out. The preference is scoped
to the backend and Firebase app and updated on the next login/registration.

Autofill hints identify the username and current/new password. A successful
authentication explicitly commits the autofill context; failures do not. Saving
and filling remain controlled by the user's browser, operating system and password
manager. No password, email, or token is stored in the new preference.

Explicit sign-out still clears the Firebase session and destroys the private
workspace. Verification, expiration and revoked-session handling remain enforced.
The demo emulator bootstrap retains its existing ephemeral web startup policy.

## Alternatives and tradeoffs

Always keeping Firebase's default offers no shared-device opt-out. A custom token
store or cookie backend adds security and maintenance costs without improving this
client-side requirement. Native SDKs do not offer web's per-tab session mode, so a
single opt-out preference with startup cleanup is the smallest supported approach.

## Adoption and validation

No credential migration or dependency change is required. Unit tests cover web
persistence selection, native restart/default/malformed preference behavior, and
policy failures. Widget tests cover successful/failed autofill completion, the
checkbox and existing sign-out/account-switch behavior. Native password-manager
prompts and actual process restarts require device acceptance testing.

Rolling back ignores the native opt-out flag; sign out before rollback on shared
devices. Revisit if session expiry requirements change, new platforms are added,
or a server-managed browser session replaces Firebase client authentication.
