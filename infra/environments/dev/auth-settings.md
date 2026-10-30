# Dev authentication settings

Project: `bramwellsprecisiontestkitdev` (`723783645502`). Record verified Console settings here; these unchecked items are intended configuration, not proof of live configuration.

- [x] Cloud Billing disabled, verified October 29, 2026 (Spark billing boundary).
- [x] Email/Password enabled with password required; subtype verified as `FIREBASE_AUTH` on October 29, 2026.
- [x] Email-link, anonymous, phone/SMS, and unused providers disabled.
- [x] Authorized domains include `localhost`, `bramwellsprecisiontestkitdev.firebaseapp.com`, and `bramwellsprecisiontestkitdev.web.app`.
- [x] Password policy and verification/reset templates reviewed.
- [ ] Action links resolve to the dev application.
- [ ] Verification/reset email cooldowns and quota handling tested.

Provider deployment and manual settings are described in step 5 of [the migration guide](../../../docs/firebase_migration_guide.md). Auth configuration is kept outside Terraform to preserve the Spark setup.

App return URL: https://bramwellsprecisiontestkitdev.web.app