# Production authentication settings

Project: `bramwells-precision-test-kit`. Record its confirmed project number in `prod.tfvars`. These unchecked items are intended configuration, not proof of live configuration.

- [x] Cloud Billing disabled, verified October 29, 2026 (Spark billing boundary).
- [x] Email/Password enabled with password required; subtype verified as `IDENTITY_PLATFORM` on October 29, 2026.
- [ ] Email-link, anonymous, phone/SMS, and unused providers disabled.
- [x] Authorized domains include the required `bramwells-precision-test-kit.firebaseapp.com` / `bramwells-precision-test-kit.web.app` hosts; no custom domains configured.
- [x] Dev domains and `localhost` omitted unless production explicitly needs them.
- [x] Password policy and verification/reset templates reviewed.
- [ ] Action links resolve to the production application.
- [ ] Verification/reset email cooldowns and quota handling tested.

Provider deployment and manual settings are described in step 5 of [the migration guide](../../../docs/firebase_migration_guide.md). Auth configuration is kept outside Terraform to preserve the Spark setup.

Production Auth was initialized using the CLI and reports Identity Platform. Billing remains disabled. Apply Spark Identity Platform quotas rather than basic-Auth capacity assumptions. No downgrade was attempted.

Spark Identity Platform permits 3,000 Tier-1 daily active users (email/password is Tier 1). See [Auth limits](https://firebase.google.com/docs/auth/limits).

App return URL: https://bramwells-precision-test-kit.web.app
