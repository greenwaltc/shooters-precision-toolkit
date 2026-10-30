# Firebase infrastructure

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
    imports.tf.example
    auth-settings.md
```

The module manages required APIs, Firebase enablement, one web registration, one Android registration, unique Apple registrations, a protected default Standard Firestore database, payload index exemptions, a Hosting site, and a Firestore ruleset/release. It does not manage billing, Storage buckets, deployed functions, Identity Platform, user accounts, or application data. Hosting content and basic Auth provisioning remain separate from Terraform.

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

The dev root already includes declarative imports for Firebase enablement and the web/Android/Apple IDs found in `firebase.json`. Those IDs are local configuration evidence; verify the current remote registrations before applying. The Windows-specific web registration remains outside this module. The existing iOS/macOS IDs match, so one Apple registration serves both.

The dev variable file uses the **current unsuffixed native application IDs** so the known registrations can be adopted. When implementing the guide's `.dev` native flavors, plan separate dev registrations and update native service files/import declarations together. Changing an imported registration's package/bundle ID can require replacement; destruction protection will stop that operation.

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

Review the imports, proposed creates/updates, and destination project in the saved plan. An existing database or Hosting site needs its own import. For example:

```bash
terraform -chdir=infra/environments/dev import -var-file=dev.tfvars module.firebase.google_firestore_database.projects 'projects/bramwellsprecisiontestkitdev/databases/(default)'
terraform -chdir=infra/environments/dev import -var-file=dev.tfvars module.firebase.google_firebase_hosting_site.web projects/bramwellsprecisiontestkitdev/sites/bramwellsprecisiontestkitdev
terraform -chdir=infra/environments/dev import -var-file=dev.tfvars module.firebase.google_firebaserules_release.firestore projects/bramwellsprecisiontestkitdev/releases/cloud.firestore
```

Run only imports for confirmed existing resources; inspect existing field overrides before adopting or replacing them. The production import template includes the known project and Hosting resource addresses, and directions for app/database/rules imports. Fill/verify that template before making it an active `.tf` file.

Only after reviewing the plan, apply that exact saved plan:

```bash
terraform -chdir=infra/environments/dev apply dev.tfplan
```

Repeat in the production root with `prod.tfvars` and an independently reviewed production plan. A root rejects another environment's project ID/variable file and checks the numeric project identifier. No automatic apply is configured.

**State and ongoing ownership**

Each root stores private state in its own `terraform.tfstate`, created by Terraform rather than checked in as an empty placeholder. Keep encrypted, recoverable backups and one operator for local applies. Local locks do not coordinate separate machines. Do not initialize fresh state on an ephemeral CI runner and apply it to resources already managed here.

Terraform owns the rules release and index overrides once applied. Avoid deploying the same policy/index resources independently through the Firebase CLI. Keep basic Auth settings in the environment checklists and use the separate provider-provisioning instructions in the guide; adding a Terraform Identity Platform resource would violate this scaffold's Spark boundary.

Full implementation instructions: [Firebase migration guide](../docs/firebase_migration_guide.md). Provider documentation: [Google 8.9.0](https://registry.terraform.io/providers/hashicorp/google/8.9.0/docs), [Google Beta 8.9.0](https://registry.terraform.io/providers/hashicorp/google-beta/8.9.0/docs).
