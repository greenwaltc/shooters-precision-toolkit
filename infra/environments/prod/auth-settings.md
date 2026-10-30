# Production authentication settings

Project: `bramwells-precision-test-kit`. Record its confirmed project number in `prod.tfvars`. These unchecked items are intended configuration, not proof of live configuration.

- [ ] Spark plan confirmed; Cloud Billing unlinked.
- [ ] Basic Email/Password enabled; Auth upgrade state recorded.
- [ ] Email-link, anonymous, phone/SMS, and unused providers disabled.
- [ ] Authorized domains include the required `bramwells-precision-test-kit.firebaseapp.com` / `bramwells-precision-test-kit.web.app` hosts and any verified custom domains.
- [ ] Dev domains and `localhost` omitted unless production explicitly needs them.
- [ ] Password policy and verification/reset templates reviewed.
- [ ] Action links resolve to the production application.
- [ ] Verification/reset email cooldowns and quota handling tested.

Provider deployment and manual settings are described in step 5 of [the migration guide](../../../docs/firebase_migration_guide.md). Auth configuration is kept outside Terraform to preserve the Spark setup.
