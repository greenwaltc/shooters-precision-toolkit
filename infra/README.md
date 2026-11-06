# Firebase infrastructure

Step 14 adds management of the existing Hosting `live` channel, with imports in each root's `hosting_imports.tf`. A reviewed apply sets retention to 2 previous releases in dev and 5 in production. Reducing retention schedules older versions for deletion. Hosting content and two-day preview expiration remain outside Terraform. See [web releases](../docs/guides/web_releases.md) for commands and GitHub setup.

Native flavors: the dev root now manages additional `.dev` Android and Apple registrations. The original imported dev registrations are preserved. `android_app_id` returns the installable flavor's app ID; `apple_app_ids` is keyed by bundle ID. Use `task native:config` after apply to retrieve the corresponding SDK files and update Dart options. Production uses its existing registrations. Native generation never creates registrations outside Terraform.

With Google provider 8.9.0, changing a ruleset also replaces its rules release
(`ruleset_name` is ForceNew). The release intentionally has no `prevent_destroy`
guard; that guard would block policy updates. The immutable ruleset uses
`create_before_destroy`, while the fixed-name release is destroyed and recreated.
Allow for a possible brief interruption to Firestore client access during that
replacement. This does not delete the database or its documents. Database,
project, and app destruction protections remain in place.

Terraform configuration for the existing dev and production Firebase projects, following the Spark migration guide. `hashicorp/google` and `hashicorp/google-beta` are both pinned to **8.9.0**. The stable provider manages APIs, Firestore, and rules; the beta provider handles Firebase project/app/Hosting resources.

```text
infra/
  bootstrap/README.md
  modules/firebase_environment/
    main.tf
    variables.tf
    outputs.tf
  environments/dev/
    main.tf
    variables.tf
    outputs.tf
    dev.tfvars
    imports.tf
    auth-settings.md
  environments/prod/
    main.tf
    variables.tf
    outputs.tf
    prod.tfvars
    imports.tf
    auth-settings.md
```

The module manages required APIs, Firebase enablement, web and native app registrations, a protected default Standard Firestore database, payload index exemptions, a Hosting site, and a Firestore ruleset/release. It does not manage billing, Storage buckets, deployed functions, Identity Platform, user accounts, or application data. Hosting content and basic Auth provisioning remain separate from Terraform.

**Inputs to complete before planning**

1. Confirm each project's Spark plan and database inventory. If a default database already exists, use its actual location and import it. Do not replace an existing named/Enterprise database to fit this scaffold.
2. Set `location` and `rules_file` in each environment's variable file. A location is deliberately not chosen for you. Relative rules paths resolve from the environment directory; `../../../firestore.rules` refers to the repository root. Supply the reviewed policy from step 9 of the migration guide before planning. This scaffold does not create or deploy an application security policy.
3. Set `expected_project_number` in `prod.tfvars` from the existing production project. The known dev number is prefilled.
4. Inspect the existing Firebase apps and Hosting sites, and add imports for every declared resource that already exists.

Read-only inventory commands:

```bash
npx -y firebase-tools@latest apps:list --project bramwellsprecisiontestkitdev
npx -y firebase-tools@latest firestore:databases:list --project bramwellsprecisiontestkitdev
npx -y firebase-tools@latest firestore:databases:get '(default)' --project bramwellsprecisiontestkitdev
gcloud projects describe bramwells-precision-test-kit
```

The dev root includes declarative imports for the Firebase project, web and native registrations, Hosting site and live channel, default database, index exemptions, and Firestore rules release. Both the original native registrations and the separate `.dev` flavors are included. The Windows-specific web registration remains outside the module. iOS and macOS share the Apple registration for each bundle ID.

**Local initialization and validation**

Install Terraform 1.5 or later (below 2.0). Then run from the repository root:

```bash
terraform fmt -check -recursive infra
terraform -chdir=infra/environments/dev init -backend=false
terraform -chdir=infra/environments/dev validate
terraform -chdir=infra/environments/prod init -backend=false
terraform -chdir=infra/environments/prod validate
```

These commands download providers and validate configuration without provisioning Firebase. Required deployment inputs can remain unset during `validate`. Keep generated `.terraform.lock.hcl` files in Git; local state, plan files, `.terraform/`, and local credentials are ignored.

Validation on October 29, 2026: both environment roots passed `terraform validate` with the signed Google/Google Beta 8.9.0 providers, and recursive formatting passed. Their provider lock files are included. No plan, import, apply, or Firebase deployment was executed during scaffolding.

**Adopt and plan an environment**

Complete the inputs first and authenticate using an identity authorized for the selected project:

```bash
gcloud auth application-default login
terraform -chdir=infra/environments/dev init
terraform -chdir=infra/environments/dev plan -var-file=dev.tfvars -out=dev.tfplan
```

Review the imports, proposed changes, and destination project in the saved plan. After a partial apply, check the local state and generate a fresh plan. Terraform retains successful operations from the failed apply, and the import blocks adopt the existing resources still missing from state. An HTTP 409 on a planned create means the existing resource needs to be identified and adopted before retrying.

The production root declares imports for Firebase enablement, the Hosting site and live channel, the app registrations used by the production build, the default database, and the Firestore rules release. Review the import IDs and check the local state before applying a plan from another checkout.

Only after reviewing the plan, apply that exact saved plan:

```bash
terraform -chdir=infra/environments/dev apply dev.tfplan
```

Repeat in the production root with `prod.tfvars` and an independently reviewed production plan. A root rejects another environment's project ID/variable file and checks the numeric project identifier. No automatic apply is configured.

**State and ongoing ownership**

Each root stores private state in its own `terraform.tfstate`, created by Terraform rather than checked in as an empty placeholder. Keep encrypted, recoverable backups and one operator for local applies. Local locks do not coordinate separate machines. Do not initialize fresh state on an ephemeral CI runner and apply it to resources already managed here.

Terraform owns the rules release and index overrides once applied. Avoid deploying the same policy/index resources independently through the Firebase CLI. Keep basic Auth settings in the environment checklists and use the separate provider-provisioning instructions in the guide; adding a Terraform Identity Platform resource would violate this scaffold's Spark boundary.

Full implementation instructions: [Firebase migration guide](../docs/guides/firebase_migration_guide.md). Provider documentation: [Google 8.9.0](https://registry.terraform.io/providers/hashicorp/google/8.9.0/docs), [Google Beta 8.9.0](https://registry.terraform.io/providers/hashicorp/google-beta/8.9.0/docs).

Both environments reported no changes on October 29, 2026. On November 6, the dev app registrations, database location and edition, index exemptions, and rules release were verified against the live project during recovery of a partial apply. See the environment Auth checklists for verified settings and remaining manual checks.
