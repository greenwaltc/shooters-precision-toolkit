# Firebase Spark migration and environment implementation guide

Prepared for Bramwell's Precision Test Kit on October 11, 2026; revised for the no-cost Firebase Spark plan. The infrastructure scaffold and provider pins were updated on October 29, 2026. Dev and production infrastructure are applied; both live Terraform plans reported no changes on October 29, 2026. Application migration beyond the step-6 service scope remains in progress.

The deployment target is Spark in both dev and prod, without linking a Cloud Billing account. A Blaze project operating below a no-cost allowance is a different arrangement and is outside this guide's cost constraint. Linking billing automatically upgrades a Firebase project to Blaze. [Firebase pricing plans](https://firebase.google.com/docs/projects/billing/firebase-pricing-plans)

**Spark capacity and service boundaries**

| Service | Limit or choice used by this guide |
| --- | --- |
| Firestore Standard | One free-quota database per Firebase project; use `(default)` for a fresh environment |
| Firestore storage | 1 GiB, including applicable document/index storage |
| Firestore daily operations | 50,000 document reads; 20,000 document writes; 20,000 document deletes |
| Firestore network | 10 GiB outbound per month |
| Classic Firebase Hosting | 10 GB stored; plan conservatively for at most 360 MB/day and 10 GB/month transfer |
| Basic Firebase Authentication | Email/password; verification emails up to 1,000/day and password-reset emails up to 150/day |
| Excluded services/features | Phone/SMS auth, deployed Cloud Functions, App Hosting, Cloud Storage buckets, TTL deletes, managed backups/PITR/restore/clone operations |

Firestore operation allowances reset around midnight Pacific time and are shared by all apps/users in a project. The separate dev project has its own allocation. [Firestore quotas](https://firebase.google.com/docs/firestore/quotas)

Hosting's pricing page currently lists 360 MB/day while its usage guide describes 10 GB/month. Respect both figures for planning and verify the quota displayed for your project. Live sites, previews, and retained releases share project-level usage; CDN cache hits still count as transfer. Reaching transfer limits can disable the sites until the next monthly cycle; storage limits can prevent deployments. [Firebase pricing](https://firebase.google.com/pricing), [Hosting usage](https://firebase.google.com/docs/hosting/usage-quotas-pricing)

Spark does not make paid services available just because a related Google Cloud product advertises an always-free allowance. Cloud Storage for Firebase now requires Blaze. Keep generated PDFs, JSON backups, and exports on the user's device. [Storage billing requirements](https://firebase.google.com/docs/storage/faqs-storage-changes-announced-sept-2024)

**1. Establish the environment contract**

Use separate Spark Firebase projects for development and production. Authentication users, databases, app registrations, Hosting sites, IAM, and usage quotas belong to their respective projects. Promote application code and infrastructure configuration between environments; keep customer accounts and data in production. Firebase recommends separate projects for separate environments. [Environment best practices](https://firebase.google.com/docs/projects/dev-workflows/general-best-practices)

| Environment | Firebase project | Purpose |
| --- | --- | --- |
| Local | Emulators, normally using a `demo-` project ID | Automated rules tests and development without live data |
| Dev | `bramwellsprecisiontestkitdev` | Integration tests, sample accounts, internal testing, PR previews |
| Prod | `bramwells-precision-test-kit` | Existing public application and real accounts; inferred from the current Hosting configuration |

Dev display name: `BramwellsPrecisionTestKitDev`. Dev project number: `723783645502`. Use the project ID in CLI commands; use the project number when a service requires a numeric resource identifier. An app ID such as `1:723783645502:web:...` is a separate identifier generated for an app registration.

Make the environment an explicit build input. `--release` controls compiler/build behavior; it does not select a Firebase project. A Hosting destination also does not change the Firebase configuration already compiled into a web bundle.

Update `.firebaserc`:

```json
{
  "projects": {
    "default": "bramwellsprecisiontestkitdev",
    "dev": "bramwellsprecisiontestkitdev",
    "prod": "bramwells-precision-test-kit"
  }
}
```

Use explicit project IDs in deployment scripts even with aliases. Keep separate build directories when preparing both environments, so a later build cannot replace a bundle awaiting deployment.

**2. Inventory existing resources before creating anything**

The repository currently has:

- Firebase Hosting configuration and two GitHub workflows pointing to `bramwells-precision-test-kit`.
- `firebase_core`, `firebase_auth`, and `cloud_firestore` already added to `pubspec.yaml`.
- Startup initializes Flutter bindings, awaits Firebase through `FirebaseStartup`, and displays loading/error UI. `FirebaseApplication` provides Firebase services to the existing local-data `MyApp`.
- Canonical web options exist at `lib/firebase/firebase_options_dev.dart` and `lib/firebase/firebase_options_prod.dart`. Native registrations exist, but native environment options/flavors remain step 12; these web-only options deliberately reject native startup.
- Local project JSON under `anomr_projects_v1`; theme under `anomr_theme_mode_v1`.
- A whole-workspace `ProjectStorage` interface, and a `ProjectStore` that loads once and rewrites all projects.
- Android application ID `com.bramwell.bramwells_precision_test_kit`.
- iOS and macOS bundle ID `com.bramwell.bramwellsPrecisionTestKit`.
- iOS deployment targets are now set to 15.0, matching the minimum in the current Firebase Flutter setup guide; keep Podfile, Xcode targets, and dependencies aligned. It also lists Android API 24 or later and macOS 11 or later. [Flutter prerequisites](https://firebase.google.com/docs/flutter/setup)

Both projects have been inspected and provisioned. Billing is disabled in both. Re-run discovery before future infrastructure changes:

```bash
npx -y firebase-tools@latest --version
npx -y firebase-tools@latest login
npx -y firebase-tools@latest projects:list
npx -y firebase-tools@latest apps:list --project bramwellsprecisiontestkitdev
npx -y firebase-tools@latest firestore:databases:list --project bramwellsprecisiontestkitdev
npx -y firebase-tools@latest firestore:databases:list --project bramwells-precision-test-kit
```

For every existing database, inspect its ID, edition, type, location, and realtime settings:

```bash
npx -y firebase-tools@latest firestore:databases:get DATABASE_ID --project bramwellsprecisiontestkitdev
gcloud projects describe bramwellsprecisiontestkitdev
gcloud projects describe bramwells-precision-test-kit
```

For a fresh environment, the examples declare one Standard-edition Firestore Native database named `(default)`. Standard's per-document quotas and automatic single-field indexing fit this app's simple CRUD queries. Choose the location based on your users; `us-central1` below is an example. Enterprise also has published no-cost allowances, but its unit-based model is not the model used here. [Firestore setup](https://firebase.google.com/docs/firestore/quickstart), [edition allowances](https://firebase.google.com/pricing)

Before provisioning, confirm in the Firebase Console that both projects remain on Spark and that the intended database is the one receiving free quota. Exactly one database per project receives free quota; creating another does not add a second allocation. If you already applied the older named `precision` example, preserve its data and state and inspect its free-quota eligibility. Do not rename/replace it with `(default)` or change its edition through Terraform. Either adapt the guide to the existing eligible database or plan an explicit export/migration first; do not create an additional database as a shortcut.

Your app also has a Windows release configuration. Firebase's Flutter documentation currently says Windows support is for local development workflows, not production. For production Windows users, the web app is the simplest Firebase route. A native Windows release requires a separately validated supported authentication/backend approach. [Platform support](https://firebase.google.com/docs/flutter/setup)

**3. Define what infrastructure code owns**

Use Terraform for Firebase enablement, APIs, app registrations, the Standard database, Hosting site creation, rules, and IAM. Use the Firebase CLI's checked-in Auth provider configuration for basic email/password provisioning, and the CLI for uploading compiled Hosting files. Record domain/template settings in a reviewed checklist. Application documents and end-user accounts are runtime data and should not be Terraform resources.

| Resource | Owner |
| --- | --- |
| Existing Google Cloud projects | Existing project administration; optionally import into a separate bootstrap Terraform state |
| Firebase enablement, API configuration, app registrations, database | Terraform |
| Basic email/password provider | Version-controlled Firebase CLI Auth configuration; Console fallback |
| Authorized domains, password policy, email templates | Reviewed environment-specific Console checklist |
| Firestore security rules | Terraform ruleset/release resources using the checked-in `firestore.rules` source |
| Firestore indexes | Standard automatic indexes; Terraform exemptions for unqueried matrix/form fields |
| Hosting site | Terraform |
| Hosting content and preview channels | Explicit Firebase CLI deployment from CI |
| User data and Auth users | Application/Firebase runtime |

Avoid managing the same rules release or index with both Terraform and CLI deployments. Manual Console changes should be reconciled into code before the next apply.

**Spark boundary:** Do not use `google_identity_platform_config` or configure a `billing_account`. Firebase's documented Terraform Auth path requires billing. Basic Email/Password authentication is sufficient here. Identity Platform itself can also exist on Spark with different limits, but upgrading Auth is unnecessary for this migration and is not part of these examples. [Terraform Auth requirements](https://firebase.google.com/docs/projects/terraform/get-started#firebase-authentication), [basic and upgraded Auth limits](https://firebase.google.com/docs/auth)

The checked-in scaffold pins both `hashicorp/google` and `hashicorp/google-beta` to **8.9.0**. The stable provider manages APIs, Firestore, and rules; the beta provider handles Firebase project/app/Hosting resources. Review provider changes and validate dev before production. [Google release](https://github.com/hashicorp/terraform-provider-google/releases/tag/v8.9.0), [Google Beta release](https://github.com/hashicorp/terraform-provider-google-beta/releases/tag/v8.9.0)

Suggested layout:

```text
infra/
  README.md
  bootstrap/README.md         # Optional initial IAM; no bucket/billing resources
  modules/firebase_environment/
    main.tf
    variables.tf
    outputs.tf
  environments/dev/
    main.tf
    variables.tf
    outputs.tf
    dev.tfvars
    imports.tf               # Known dev registrations from FlutterFire metadata
    auth-settings.md
    .terraform.lock.hcl
  environments/prod/
    main.tf
    variables.tf
    outputs.tf
    prod.tfvars
    imports.tf               # Existing production apps, database, and rules release
    auth-settings.md
    .terraform.lock.hcl
lib/
  firebase/firebase_options_dev.dart
  firebase/firebase_options_prod.dart
  firebase/firebase_bootstrap.dart
  auth/auth_service.dart
  auth/auth_gate.dart
  storage/firestore_project_repository.dart
  storage/legacy_project_importer.dart
firestore.rules
firebase.auth.dev.json
firebase.auth.prod.json
firebase.json
firebase.emulators.json
docs/guides/firebase_migration_guide.md
```

The infra portion of this layout is now implemented. See [infra/README.md](../../infra/README.md) for current inputs and adoption instructions. Both roots passed `terraform validate` with Google/Google Beta 8.9.0 on October 29, 2026, and provider lock files are included. State files are generated privately by Terraform, not created as placeholders. The app/auth/root policy files shown here are later migration steps.

**4. Keep separate local Terraform states and adopt the existing projects**

Use Terraform's local backend, with an independent state file in each environment root. This avoids adding Cloud Storage or a billing account for infrastructure state. Store state/plan files on an encrypted, access-controlled machine and keep a recoverable private backup outside Git. The local backend locks on the local machine; it does not coordinate independent copies on different machines. Designate one infrastructure operator and serialize applies. [Terraform local backend](https://developer.hashicorp.com/terraform/language/backend/local)

For team-based automated infrastructure applies, first choose a secure shared-state service whose separate pricing and access rules meet your cost constraint. Do not run Terraform apply on a disposable CI runner with a fresh/empty state, and do not put state in public Git or publicly accessible Hosting. Hosting content deployments can still run in CI using the workflow in step 15.

If you already used the previous GCS backend, back up its state and plan a controlled `terraform init -migrate-state` transition while the bucket is still accessible. Changing backend configuration alone does not import the existing resources or copy their state. Review existing paid resources and the downgrade consequences before any Console plan change; this guide does not downgrade or destroy resources for you.

If the earlier Terraform Auth resource was already applied, export/review its current settings and preserve all accounts before removing it from management. Merely removing the HCL can propose an unwanted live change, and it does not undo an Auth upgrade. After backing up the correct environment's state, inspect `terraform state list`; if applicable, deliberately detach only `module.firebase.google_identity_platform_config.auth` with `terraform state rm` and manage its settings through the reviewed Auth checklist. This state operation does not delete Auth users or downgrade the live project. Recheck the Console plan/upgrade state and its limits, and review the full resulting plan before applying any replacement configuration.

The following is the checked-in dev root `main.tf`. The production root has its own fixed `expected_environment` and `expected_project_id`; use the existing production file instead of blindly copying the dev root. Each root has separate local state and variables. The guards reject another environment's project or variable file.

```hcl
terraform {
  required_version = ">= 1.5, < 2.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "= 8.9.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "= 8.9.0"
    }
  }

  backend "local" {
    path = "terraform.tfstate"
  }
}

locals {
  expected_environment = "dev"
  expected_project_id  = "bramwellsprecisiontestkitdev"
}

provider "google" {
  project               = var.project_id
  user_project_override = true
}

provider "google" {
  alias                 = "bootstrap"
  project               = var.project_id
  user_project_override = false
}

provider "google-beta" {
  project               = var.project_id
  user_project_override = true
}

data "google_project" "existing" {
  provider   = google.bootstrap
  project_id = var.project_id

  lifecycle {
    precondition {
      condition = (
        var.environment == local.expected_environment &&
        var.project_id == local.expected_project_id
      )
      error_message = "This root accepts only the dev project and its dev variable file."
    }
    postcondition {
      condition     = tostring(self.number) == var.expected_project_number
      error_message = "The dev project number does not match the verified configuration."
    }
  }
}

module "firebase" {
  source = "../../modules/firebase_environment"

  providers = {
    google           = google
    google.bootstrap = google.bootstrap
    google-beta      = google-beta
  }

  project_id           = data.google_project.existing.project_id
  environment          = var.environment
  database_id          = var.database_id
  location             = var.location
  android_package_name = var.android_package_name
  apple_bundle_ids     = var.apple_bundle_ids
  rules_file           = abspath(var.rules_file)
}
```

Root `variables.tf`:

```hcl
variable "environment" {
  description = "Must match this root's fixed environment."
  type        = string
  nullable    = false
}

variable "project_id" {
  description = "Must match this root's fixed Firebase project ID."
  type        = string
  nullable    = false
}

variable "expected_project_number" {
  description = "Verified numeric Google Cloud project identifier."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[0-9]+$", var.expected_project_number))
    error_message = "Provide the verified numeric project number."
  }
}

variable "database_id" {
  description = "Single default Standard database for this Spark environment."
  type        = string
  default     = "(default)"
  nullable    = false

  validation {
    condition     = var.database_id == "(default)"
    error_message = "This Spark configuration manages only the (default) database."
  }
}

variable "location" {
  description = "Required: confirmed Firestore region or multi-region. No location is guessed."
  type        = string
  nullable    = false
}

variable "android_package_name" {
  description = "Existing Android application ID; coordinate future flavor changes with app imports."
  type        = string
  nullable    = false
}

variable "apple_bundle_ids" {
  description = "Unique Apple bundle IDs to manage."
  type        = set(string)
  nullable    = false
}

variable "rules_file" {
  description = "Required: path to reviewed Firestore rules, absolute or relative to this environment directory."
  type        = string
  nullable    = false
}
```

Module `variables.tf` declares the same input types for `project_id`, `environment`, `database_id`, `location`, `android_package_name`, and `apple_bundle_ids`, plus `variable "rules_file" { type = string }`. It does not need `expected_project_number`, which the root checks. The database edition is fixed to Standard in this Spark example.

Module `main.tf`:

```hcl
terraform {
  required_version = ">= 1.5, < 2.0"

  required_providers {
    google = {
      source                = "hashicorp/google"
      version               = "= 8.9.0"
      configuration_aliases = [google.bootstrap]
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "= 8.9.0"
    }
  }
}

resource "google_project_service" "api" {
  provider = google.bootstrap
  for_each = toset([
    "serviceusage.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "firebase.googleapis.com",
    "apikeys.googleapis.com",
    "firestore.googleapis.com",
    "identitytoolkit.googleapis.com",
    "firebaserules.googleapis.com",
    "firebasehosting.googleapis.com",
  ])

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_firebase_project" "this" {
  provider = google-beta
  project  = var.project_id

  depends_on = [google_project_service.api]

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_firebase_web_app" "web" {
  provider     = google-beta
  project      = google_firebase_project.this.project
  display_name = "Precision Test Kit ${var.environment} Web"

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_firebase_android_app" "android" {
  provider     = google-beta
  project      = google_firebase_project.this.project
  display_name = "Precision Test Kit ${var.environment} Android"
  package_name = var.android_package_name

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_firebase_apple_app" "apple" {
  provider     = google-beta
  for_each     = var.apple_bundle_ids
  project      = google_firebase_project.this.project
  display_name = "Precision Test Kit ${var.environment} Apple"
  bundle_id    = each.value

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_firestore_database" "projects" {
  project                 = google_firebase_project.this.project
  name                    = var.database_id
  location_id             = var.location
  type                    = "FIRESTORE_NATIVE"
  database_edition        = "STANDARD"
  delete_protection_state = "DELETE_PROTECTION_ENABLED"
  deletion_policy         = "PREVENT"

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_firestore_field" "unqueried_payload" {
  for_each   = toset(["matrixState", "randomizeSequence", "formModel"])
  project    = var.project_id
  database   = google_firestore_database.projects.name
  collection = "projects"
  field      = each.value

  # Preserve automatic indexing for updatedAt, which the project list queries.
  index_config {}
}

resource "google_firebase_hosting_site" "web" {
  provider = google-beta
  project  = google_firebase_project.this.project
  site_id  = var.project_id

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_firebaserules_ruleset" "firestore" {
  project = var.project_id

  source {
    files {
      name    = "firestore.rules"
      content = file(var.rules_file)
    }
  }

  depends_on = [google_firestore_database.projects]

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_firebaserules_release" "firestore" {
  # Google 8.9.0 marks ruleset_name ForceNew. Replacing this release publishes
  # new rules; prevent_destroy here would block every policy update.
  project      = var.project_id
  name         = "cloud.firestore"
  ruleset_name = google_firebaserules_ruleset.firestore.id
}
```

The root provider version bounds apply to the module too. Use the provider's fully-qualified ruleset ID for the release. A ruleset takes effect only when a release points to it. [Database resource](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/firestore_database), [ruleset](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/firebaserules_ruleset), [rules release](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/firebaserules_release)

The recent-project query uses Standard's automatic `updatedAt` single-field index. Exempting the matrix, randomized list, and form map reduces index storage because those payloads are not queried. Keep `updatedAt` indexed; add a suitable index in Terraform if later adding title/form-field search. These exemptions do not alter stored data or owner rules. [Index exemptions](https://firebase.google.com/docs/firestore/query-data/index-overview), [field resource](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/firestore_field)

Module `outputs.tf`:

```hcl
output "project_id" {
  description = "Firebase project managed by this module."
  value       = google_firebase_project.this.project
}

output "web_app_id" {
  description = "Web registration ID to pass to FlutterFire configure."
  value       = google_firebase_web_app.web.app_id
}

output "android_app_id" {
  description = "Android registration ID."
  value       = google_firebase_android_app.android.app_id
}

output "apple_app_ids" {
  description = "Apple registration IDs keyed by bundle ID."
  value = {
    for bundle_id, app in google_firebase_apple_app.apple : bundle_id => app.app_id
  }
}

output "database_id" {
  description = "Default Firestore database ID."
  value       = google_firestore_database.projects.name
}

output "hosting_url" {
  description = "Default URL of the Hosting site."
  value       = google_firebase_hosting_site.web.default_url
}
```

Dev `dev.tfvars`:

```hcl
environment             = "dev"
project_id              = "bramwellsprecisiontestkitdev"
expected_project_number = "723783645502"
database_id             = "(default)"

# Match the registrations already referenced by firebase.json and the current
# native builds. Introduce .dev registrations with the native flavors later.
android_package_name = "com.bramwell.bramwells_precision_test_kit"
apple_bundle_ids     = ["com.bramwell.bramwellsPrecisionTestKit"]

# Confirm the actual region and supply reviewed rules before planning.
# location   = "us-central1"
# rules_file = "../../../firestore.rules"
```

Prod `prod.tfvars` already declares its environment, project ID, and current native app IDs. Supply the confirmed production project number, database location, and rules-file path before planning. The dev scaffold adopts the existing unsuffixed native registrations to avoid replacements; implement separate `.dev` registrations together with the native flavor work in step 12. Configure authorized domains separately in step 5.

Your iOS and macOS bundle IDs currently match. Register that unique Apple bundle ID once in each Firebase project if keeping the shared ID; both native platforms can reference that registration. If you introduce distinct platform bundle IDs, declare both and regenerate the corresponding options.

Before plan/import commands, supply the required `location` and `rules_file` values and a reviewed policy from step 9; do not replace a live policy with an unreviewed sample. `init -backend=false` and `validate` can run before these deployment inputs are set. Declarative dev imports already adopt the known Firebase enablement and app IDs when plan/apply runs. The following manual import is an alternative when the resource is not yet in state:

```bash
gcloud auth application-default login
terraform -chdir=infra/environments/dev init
terraform -chdir=infra/environments/dev import -var-file=dev.tfvars module.firebase.google_firebase_project.this projects/bramwellsprecisiontestkitdev
```

Import every other declared resource that already exists. Examples:

```bash
terraform -chdir=infra/environments/dev import -var-file=dev.tfvars module.firebase.google_firestore_database.projects 'projects/bramwellsprecisiontestkitdev/databases/(default)'
terraform -chdir=infra/environments/dev import -var-file=dev.tfvars module.firebase.google_firebase_hosting_site.web projects/bramwellsprecisiontestkitdev/sites/bramwellsprecisiontestkitdev
```

Run only applicable imports; a resource that does not exist should be created by the plan. Firebase app imports use their actual app IDs. The default database rules release is imported using `projects/PROJECT_ID/releases/cloud.firestore`. Consult the resource import documentation for the pinned provider, then inspect the result.

Before the initial dev apply, create the prototype `firestore.rules` from step 9 or start with deny-all rules. Keep both projects on Spark and leave Cloud Billing unlinked. The roots read the existing Google Cloud projects and do not configure billing, storage buckets, or an Identity Platform resource. [Existing Firebase adoption](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/firebase_project)

Then:

```bash
terraform -chdir=infra/environments/dev fmt
terraform -chdir=infra/environments/dev validate
terraform -chdir=infra/environments/dev plan -var-file=dev.tfvars -out=dev.tfplan
terraform -chdir=infra/environments/dev apply dev.tfplan
```

Examine creates, updates, and replacements. Investigate any database/app/project replacement before applying. After dev validation, initialize and import prod in its separate local root, review the prod plan, and let the designated operator apply that saved plan. Back up both state files after each successful apply. Commit `.terraform.lock.hcl` for each root and `pubspec.lock` for the app. Ignore `.terraform/`, `*.tfstate*`, `*.tfplan`, credentials, and generated local emulator exports containing account data.

**5. Generate separate FlutterFire configurations**

After Terraform creates/adopts the web app, provision basic Email/Password authentication using a small checked-in `firebase.auth.dev.json` file:

```json
{
  "auth": {
    "providers": { "emailPassword": true }
  }
}
```

Use the same provider declaration in `firebase.auth.prod.json`. The current Firebase CLI supports this configuration, but may initialize Identity Platform rather than legacy basic Auth. In this deployment, dev remains `FIREBASE_AUTH`; production reports `IDENTITY_PLATFORM` after provider provisioning. Billing remains disabled in both. Production must use the Spark Identity Platform limits (including its daily active-user allowance), not the basic-Auth assumptions elsewhere. Do not rerun provisioning to attempt a downgrade. Verify command support and the resulting subtype:

```bash
npx -y firebase-tools@latest deploy --help
npx -y firebase-tools@latest deploy --only auth --config firebase.auth.dev.json --project bramwellsprecisiontestkitdev
```

Then deploy the corresponding reviewed production config with the explicit prod project ID. Confirm after provisioning that the project remains on Spark and uses the intended basic Email/Password provider. If your CLI version or project requires an upgrade for this provisioning path, use Authentication > Sign-in method in the Firebase Console to enable Email/Password instead; do not accept a billing upgrade. The CLI source enables declared providers, so omitted/false declarations are not a reliable mechanism for disabling providers that were already enabled. [CLI Auth configuration](https://github.com/firebase/firebase-tools/blob/master/src/deploy/auth/index.ts), [CLI provider deployment](https://github.com/firebase/firebase-tools/blob/master/src/deploy/auth/deploy.ts)

Record these settings in `infra/environments/dev/auth-settings.md` and the prod equivalent:

- Email/Password enabled; email-link, phone/SMS, anonymous, and unused providers disabled in the Console.
- Dev authorized domains include `localhost`, `bramwellsprecisiontestkitdev.firebaseapp.com`, and `bramwellsprecisiontestkitdev.web.app`.
- Prod authorized domains include its Hosting/auth/custom domains; omit dev domains and `localhost` unless explicitly needed.
- Password policy, verification/reset templates, and action-link destinations reviewed separately for each environment.
- Spark plan confirmed; no billing account attached; Auth upgrade state recorded.

These Console settings are the documented manual boundary of the Spark infrastructure workflow. Do not substitute the billing-dependent Terraform Auth resource to automate them. If Authentication was previously upgraded to Identity Platform, inspect its limits separately; the basic-auth capacity assumptions here do not apply unchanged. [Authentication comparison](https://firebase.google.com/docs/auth)

Generate configurations after Terraform creates or adopts the app registrations. This preserves Terraform's ownership of registrations and prevents accidental duplicate web apps. Firebase SDK configuration is public application metadata; administrative keys and OAuth client secrets are different and must stay out of the Flutter bundle. [FlutterFire configuration](https://firebase.google.com/docs/flutter/setup)

Start with web to prove the migration, then add native flavors. Read the app IDs from Terraform:

```bash
terraform -chdir=infra/environments/dev output -raw web_app_id
terraform -chdir=infra/environments/prod output -raw web_app_id
dart pub global activate flutterfire_cli
```

Use the resulting IDs in place of `DEV_WEB_APP_ID` and `PROD_WEB_APP_ID`:

```bash
npx -y --package=firebase-tools@latest -c 'flutterfire configure --yes --project=bramwellsprecisiontestkitdev --platforms=web --web-app-id=DEV_WEB_APP_ID --out=lib/firebase/firebase_options_dev.dart'
npx -y --package=firebase-tools@latest -c 'flutterfire configure --yes --project=bramwells-precision-test-kit --platforms=web --web-app-id=PROD_WEB_APP_ID --out=lib/firebase/firebase_options_prod.dart'
```

The npm wrapper supplies the Firebase CLI executable that FlutterFire invokes internally. Alternatively install that dependency according to the FlutterFire setup instructions. Keep the two generated files; do not overwrite one with the other. Review changes FlutterFire makes to `firebase.json` and native build files. [FlutterFire CLI flags and flavor configuration](https://github.com/invertase/flutterfire_cli#multi-build-configuration-setup)

**6. Select Firebase safely during startup**

Create `lib/firebase/firebase_bootstrap.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show appFlavor;

import 'firebase_options_dev.dart' as dev;
import 'firebase_options_prod.dart' as prod;

class FirebaseServices {
  FirebaseServices({required this.app, required this.auth, required this.db});
  final FirebaseApp app;
  final FirebaseAuth auth;
  final FirebaseFirestore db;
}

const localFirebaseProjectId = 'demo-bramwellsprecisiontestkit';

/// Resolve the project before initializing any SDK or accessing a service.
String firebaseProjectFor({
  required String environment,
  required bool useEmulators,
  String? nativeFlavor,
}) {
  final cloudProject = switch (environment) {
    'dev' => 'bramwellsprecisiontestkitdev',
    'prod' => 'bramwells-precision-test-kit',
    _ => throw StateError('Build with APP_ENV=dev or APP_ENV=prod.'),
  };
  if (nativeFlavor != null && nativeFlavor != environment) {
    throw StateError('Native flavor and APP_ENV disagree.');
  }
  if (useEmulators && environment == 'prod') {
    throw StateError('A production build cannot select emulators.');
  }
  return useEmulators ? localFirebaseProjectId : cloudProject;
}

Future<FirebaseServices> bootstrapFirebase() async {
  const environment = String.fromEnvironment('APP_ENV');
  const useEmulators = bool.fromEnvironment('USE_FIREBASE_EMULATORS');
  const emulatorHost = String.fromEnvironment(
    'FIREBASE_EMULATOR_HOST',
    defaultValue: '127.0.0.1',
  );

  final expectedProject = firebaseProjectFor(
    environment: environment,
    useEmulators: useEmulators,
    nativeFlavor: appFlavor,
  );

  late final FirebaseApp app;
  if (useEmulators) {
    // No real project configuration or credentials are used for local services.
    app = await Firebase.initializeApp(demoProjectId: localFirebaseProjectId);
  } else {
    final options = environment == 'dev'
        ? dev.DefaultFirebaseOptions.currentPlatform
        : prod.DefaultFirebaseOptions.currentPlatform;
    if (options.projectId != expectedProject) {
      throw StateError('Generated Firebase options select the wrong project.');
    }
    app = await Firebase.initializeApp(options: options);
  }
  if (app.options.projectId != expectedProject) {
    throw StateError('Initialized Firebase app selects the wrong project.');
  }
  final auth = FirebaseAuth.instanceFor(app: app);
  // Spark examples use the same Standard default database ID everywhere.
  final db = FirebaseFirestore.instanceFor(app: app);
  if (useEmulators) {
    await auth.useAuthEmulator(emulatorHost, 9099);
    if (kIsWeb) await auth.setPersistence(Persistence.NONE);
    db.settings = const Settings(persistenceEnabled: false);
    db.useFirestoreEmulator(emulatorHost, 8080);
  }
  return FirebaseServices(app: app, auth: auth, db: db);
}
```

The checked-in `main.dart` initializes Flutter bindings and mounts `FirebaseStartup`, which awaits `bootstrapFirebase`, shows a loading indicator, and handles initialization failures with a user-facing error screen. On success it mounts `FirebaseApplication`, which provides `FirebaseServices` and `AuthService` above the existing `MyApp`.

This is the runnable step-6 checkpoint: projects still use local SharedPreferences. Do not put the existing shared local store behind an account gate and assume it is account-isolated. Implement the account scope and cloud repository together in steps 7–8. Existing injected-store widget tests remain independent of Firebase.

Build and deployment are two separate decisions:

```bash
flutter run -d chrome --dart-define=APP_ENV=dev
flutter build web --release --dart-define=APP_ENV=dev --output=build/web-dev
flutter build web --release --dart-define=APP_ENV=prod --output=build/web-prod
```

For native platforms with flavors, supply both `--flavor dev` and `--dart-define=APP_ENV=dev`, or both prod equivalents. Web uses the Dart definition; it has no Android/iOS product flavor.

**7. Implement Authentication and scope the workspace to the account**

Create `lib/auth/auth_service.dart`:

```dart
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService(this.auth);
  final FirebaseAuth auth;

  Future<void> register(String email, String password) async {
    final credential = await auth.createUserWithEmailAndPassword(
      email: email.trim(), password: password,
    );
    await credential.user!.sendEmailVerification();
  }

  Future<void> signIn(String email, String password) async {
    await auth.signInWithEmailAndPassword(
      email: email.trim(), password: password,
    );
  }

  Future<void> resetPassword(String email) =>
      auth.sendPasswordResetEmail(email: email.trim());

  Future<void> refreshVerification() async {
    await auth.currentUser?.reload();
    await auth.currentUser?.getIdToken(true);
  }

  Future<void> signOut() => auth.signOut();
}
```

Build sign-in, registration, password-reset, and verify-email pages with loading/error states. Apply the same password policy in Firebase and client feedback. Show a generic reset confirmation so the UI does not reveal whether an address has an account. Configure verification/reset templates and their links separately for dev and prod. Firebase manages passwords and tokens. [Password authentication](https://firebase.google.com/docs/auth/flutter/password-auth), [user management and email verification](https://firebase.google.com/docs/auth/flutter/manage-users)

Use email/password rather than email-link sign-in, which has a Spark sending allowance of only five sign-in emails/day. Add resend/reset cooldowns and clear handling of `too-many-requests`/quota failures; do not resend verification automatically on every app launch. Stage onboarding within the 1,000 verification-email/day allowance and account-creation abuse limits; password-reset sending is limited to 150/day. Check Auth Console usage rather than assuming registration is unlimited. [Auth limits](https://firebase.google.com/docs/auth/limits)

A reusable `lib/auth/auth_gate.dart`:

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.auth,
    required this.signedOutBuilder, required this.verifyEmailBuilder,
    required this.signedInBuilder});

  final FirebaseAuth auth;
  final WidgetBuilder signedOutBuilder;
  final WidgetBuilder verifyEmailBuilder;
  final Widget Function(BuildContext, User) signedInBuilder;

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: auth.userChanges(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const Center(child: Text('Unable to restore your session.'));
      }
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      final user = snapshot.data;
      if (user == null) return signedOutBuilder(context);
      if (!user.emailVerified) return verifyEmailBuilder(context);
      return KeyedSubtree(
        key: ValueKey('${auth.app.options.projectId}/${user.uid}'),
        child: signedInBuilder(context, user),
      );
    },
  );
}
```

Wrap this in your application's Material/navigation shell. The signed-in builder creates a stateful account scope which owns a repository and cloud-aware `ProjectStore` for that UID. The key forces disposal when accounts change. `userChanges()` plus `reload()` handles refreshed email verification; `authStateChanges()` alone is insufficient for every profile/verification change. [Authentication streams](https://firebase.google.com/docs/auth/flutter/start)

Bind each repository to an immutable UID. On sign-out cancel project streams and debounce timers, clear the visible workspace and navigation history, and suspend that user's outbox. Preserve pending drafts under their original environment and UID; never send them through the next signed-in user's repository. Signing out does not itself erase a persistent Firestore cache. Decide the trusted/shared-device cache policy before enabling persistent web caching.

The sample rules require verified email for cloud access. The verify-email page must provide resend and refresh actions before loading/importing projects. Dev and prod accounts are separate even when the email address is identical.

**8. Replace workspace JSON saves with a project repository**

Use one document per experiment. UID ownership comes from the document path:

```text
users/{uid}/projects/{projectId}
users/{uid}/imports/{migrationKey}
```

Keep `ThemeController` local initially. Keep the existing local `ProjectStorage` for legacy import and compatibility testing. Reuse `SavedProject.toJson()`/`fromJson()` at the conversion boundary, while Firestore timestamps and revisions stay outside the local JSON format.

Create `lib/storage/firestore_project_repository.dart`:

```dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/saved_project.dart';

class ProjectConflict implements Exception {
  ProjectConflict(this.projectId);
  final String projectId;
}

class CloudProject {
  CloudProject(this.project, this.revision, this.hasPendingWrites,
      {required this.snapshot});
  final SavedProject project;
  final int revision;
  final bool hasPendingWrites;
  final DocumentSnapshot<Map<String, dynamic>> snapshot;
}

class FirestoreProjectRepository {
  FirestoreProjectRepository({required this.db, required this.uid});
  final FirebaseFirestore db;
  final String uid;

  CollectionReference<Map<String, dynamic>> get _projects =>
      db.collection('users').doc(uid).collection('projects');

  String newProjectId() => _projects.doc().id;

  static const pageSize = 25;

  Query<Map<String, dynamic>> get _recentQuery =>
      _projects.orderBy('updatedAt', descending: true);

  Stream<List<CloudProject>> watchProjects() => _recentQuery
      .limit(pageSize)
      .snapshots(includeMetadataChanges: true)
      .map((query) => query.docs.map(_decode).toList());

  Future<List<CloudProject>> fetchOlderProjects({
    required DocumentSnapshot<Map<String, dynamic>> after,
  }) async {
    final page = await _recentQuery.startAfterDocument(after)
        .limit(pageSize).get();
    return page.docs.map(_decode).toList();
  }

  Stream<CloudProject?> watchProject(String id) => _projects.doc(id)
      .snapshots(includeMetadataChanges: true)
      .map((doc) => doc.exists ? _decode(doc) : null);

  CloudProject _decode(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null || data['schemaVersion'] != 1 ||
        data['revision'] is! int || data['createdAt'] is! Timestamp) {
      throw FormatException('Unsupported project ${doc.id}');
    }
    final created = (data['createdAt'] as Timestamp).toDate().toUtc();
    final updated = (data['updatedAt'] as Timestamp?)?.toDate().toUtc()
        ?? created; // Pending server timestamps can be null.
    final json = Map<String, dynamic>.from(data)
      ..remove('schemaVersion')
      ..remove('revision')
      ..['id'] = doc.id
      ..['createdAt'] = created.toIso8601String()
      ..['updatedAt'] = updated.toIso8601String();
    return CloudProject(SavedProject.fromJson(json),
        data['revision'] as int, doc.metadata.hasPendingWrites, snapshot: doc);
  }

  Map<String, dynamic> _encode(Map<String, dynamic> snapshot, int revision) {
    final data = Map<String, dynamic>.from(snapshot)
      ..remove('id')
      ..['createdAt'] = Timestamp.fromDate(
          DateTime.parse(snapshot['createdAt'] as String))
      ..['updatedAt'] = FieldValue.serverTimestamp()
      ..['schemaVersion'] = 1
      ..['revision'] = revision;
    return data;
  }

  Future<int> saveProject(SavedProject project,
      {required int expectedRevision}) async {
    // Freeze mutable form/matrix data before an async transaction can retry.
    final snapshot = Map<String, dynamic>.from(
        jsonDecode(jsonEncode(project.toJson())) as Map);
    final ref = _projects.doc(project.id);
    return db.runTransaction<int>((transaction) async {
      final current = await transaction.get(ref);
      final actualRevision = current.exists
          ? current.data()!['revision'] as int : 0;
      if (actualRevision != expectedRevision) {
        throw ProjectConflict(project.id);
      }
      final data = _encode(snapshot, actualRevision + 1);
      if (current.exists) {
        data['createdAt'] = current.data()!['createdAt'];
      }
      transaction.set(ref, data);
      return actualRevision + 1;
    });
  }

  Future<void> deleteProject(String id,
      {required int expectedRevision}) => db.runTransaction<void>((tx) async {
    final ref = _projects.doc(id);
    final current = await tx.get(ref);
    if (!current.exists) return;
    if (current.data()!['revision'] != expectedRevision) {
      throw ProjectConflict(id);
    }
    tx.delete(ref);
  });

  Future<bool> importLegacyProject(SavedProject project,
      String migrationKey) async {
    final targetId = 'legacy_$migrationKey';
    final marker = db.collection('users').doc(uid)
        .collection('imports').doc(migrationKey);
    final target = _projects.doc(targetId);
    final snapshot = Map<String, dynamic>.from(
        jsonDecode(jsonEncode(project.toJson())) as Map);
    return db.runTransaction<bool>((tx) async {
      final imported = await tx.get(marker);
      if (imported.exists) return false;
      final existing = await tx.get(target);
      if (existing.exists) {
        throw StateError('Migration target already exists without its receipt.');
      }
      tx.set(target, _encode(snapshot, 1));
      tx.set(marker, {
        'schemaVersion': 1,
        'projectId': targetId,
        'completedAt': FieldValue.serverTimestamp(),
      });
      return true;
    });
  }
}
```

`expectedRevision: 0` creates a new document using an ID from `newProjectId()`. Existing updates use the revision loaded with the project. A competing edit triggers `ProjectConflict`; keep the user's draft and offer reload, comparison, or saving a separate copy. Do not retry with the latest revision automatically, which would overwrite another device's work. The transaction callback must not mutate UI state, since Firebase can retry it. [Transactions](https://firebase.google.com/docs/firestore/manage-data/transactions)

The list watches only the most recent 25 projects. Load older projects using the last displayed `CloudProject.snapshot` as the pagination cursor; avoid offsets. Watch the selected project separately when it falls outside the live page, and cancel that listener when selection changes. Standard supplies an implicit document-name tie breaker for the timestamp ordering, so no extra explicit document-ID ordering or composite index is needed here. Avoid querying the exempted payload fields. [Cursor pagination](https://firebase.google.com/docs/firestore/query-data/query-cursors), [index ordering](https://firebase.google.com/docs/firestore/query-data/index-overview)

This repository intentionally uses online transactions for conflict detection. Transactions fail offline. Add the local draft/outbox layer in step 11 before claiming that offline edits are safely supported. Server acknowledgement and local draft persistence must be separate UI states.

Specific `ProjectStore` changes:

- Replace `readProjectsJson()`/`writeProjectsJson()` as its active cloud persistence interface with the repository above.
- Replace the one-time `_isLoaded` loading behavior with a subscription and distinct loading/error/sync states.
- Treat the live 25-project query as one page, not the complete workspace. A project leaving that result window may still exist. Keep loaded pages separate, deduplicate by document ID, and use the selected-document listener or an explicit delete result to detect deletion. Refresh older-page cursors when timestamp ordering changes.
- Generate new IDs with `newProjectId()` rather than device timestamps.
- Track each project's cloud revision and local dirty state.
- Save local drafts immediately; coalesce the current 400 ms form debounce and immediate matrix calls into approximately 1–2 seconds of idle time or an explicit cloud-save action. Save only the latest changed project snapshot and cap concurrent/retrying saves. Do not upload on every keystroke or on a fixed timer when nothing changed.
- Detach model listeners while applying clean remote state, then reattach them; avoid a snapshot/write feedback loop.
- Keep dirty local projects visible when remote snapshots arrive. Resolve conflicts instead of replacing an edited form/grid wholesale.
- Make project deletion an explicit operation. A cloud loading error must never be converted to an empty workspace and persisted.
- Preserve selection locally, scoped by environment/UID, and cancel subscriptions/timers in `dispose()`.

This is a change to the persistence contract, not a drop-in replacement of the existing whole-JSON storage class. Keep the app's statistical calculation and grid/history code independent of Firebase.

**9. Add prototype owner-only Security Rules**

Create `firestore.rules` as a starting point:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Assumed model: private user project documents; schema/revision ints;
    // timestamps; setup/randomize booleans; nullable randomized index list;
    // a form map and matrix map. createdAt is immutable after creation.
    // Imports: immutable receipts with schemaVersion, projectId, completedAt.
    function owns(uid) {
      return request.auth != null && request.auth.uid == uid &&
          request.auth.token.email_verified == true;
    }
    function activeOwner(uid) {
      return owns(uid) &&
          !exists(/databases/$(database)/documents/accountDeletionRequests/$(uid));
    }
    function recentSignIn() {
      return request.auth.token.auth_time is int &&
          request.time.toMillis() - request.auth.token.auth_time * 1000 <= 300000;
    }
    function shortText(value, maximum) {
      return value is string && value.size() <= maximum;
    }
    function validFactor(f) {
      return f is map &&
          f.keys().hasAll(['name', 'firstState', 'secondState']) &&
          f.keys().hasOnly(['name', 'firstState', 'secondState']) &&
          shortText(f.name, 120) && shortText(f.firstState, 120) &&
          shortText(f.secondState, 120);
    }
    function validSample(s) {
      return s is map &&
          s.keys().hasAll(['numFactors', 'numSets', 'setSize', 'family']) &&
          s.keys().hasOnly(['numFactors', 'numSets', 'setSize', 'family']) &&
          s.numFactors is int && s.numFactors >= 1 && s.numFactors <= 4 &&
          s.numSets is number && s.numSets > 0 && s.numSets <= 4096 &&
          s.setSize is int && s.setSize >= 1 && s.setSize <= 16 &&
          s.family in ['simpleComparison', 'factorial'];
    }
    function validForm(f) {
      return f is map && f.keys().hasAll([
          'projectTitle', 'experimentStructure', 'riskLevel',
          'sampleSizeOption', 'factorDefinitions', 'imputeMissingData']) &&
          f.keys().hasOnly([
          'projectTitle', 'experimentStructure', 'riskLevel',
          'sampleSizeOption', 'factorDefinitions', 'imputeMissingData']) &&
          shortText(f.projectTitle, 200) &&
          f.experimentStructure in ['simpleABComparison', 'twoFactors',
              'threeFactors', 'fourFactors'] &&
          f.riskLevel in ['tenPercent', 'fivePercent', 'onePercent'] &&
          validSample(f.sampleSizeOption) && f.imputeMissingData is bool &&
          f.factorDefinitions is list && f.factorDefinitions.size() == 4 &&
          validFactor(f.factorDefinitions[0]) &&
          validFactor(f.factorDefinitions[1]) &&
          validFactor(f.factorDefinitions[2]) &&
          validFactor(f.factorDefinitions[3]);
    }
    function validProject(d) {
      return d.keys().hasAll(['schemaVersion', 'revision', 'createdAt',
          'updatedAt', 'setupComplete', 'randomizeOrder',
          'randomizeSequence', 'formModel', 'matrixState']) &&
          d.keys().hasOnly(['schemaVersion', 'revision', 'createdAt',
          'updatedAt', 'setupComplete', 'randomizeOrder',
          'randomizeSequence', 'formModel', 'matrixState']) &&
          d.schemaVersion == 1 && d.revision is int && d.revision >= 1 &&
          d.createdAt is timestamp && d.updatedAt == request.time &&
          d.setupComplete is bool && d.randomizeOrder is bool &&
          (d.randomizeSequence == null ||
              (d.randomizeSequence is list && d.randomizeSequence.size() <= 4096)) &&
          validForm(d.formModel) && d.matrixState is map &&
          d.matrixState.size() <= 4096;
    }
    function validImport(d, migrationKey) {
      return d.keys().hasAll(['schemaVersion', 'projectId', 'completedAt']) &&
          d.keys().hasOnly(['schemaVersion', 'projectId', 'completedAt']) &&
          d.schemaVersion == 1 && migrationKey.matches('^[a-f0-9]{64}$') &&
          d.projectId == 'legacy_' + migrationKey &&
          d.completedAt == request.time;
    }
    function validDeletionRequest(d) {
      return d.keys().hasAll(['schemaVersion', 'status', 'requestedAt']) &&
          d.keys().hasOnly(['schemaVersion', 'status', 'requestedAt']) &&
          d.schemaVersion == 1 && d.status == 'pending' &&
          d.requestedAt == request.time;
    }

    match /users/{uid}/projects/{projectId} {
      allow get: if owns(uid);
      allow list: if owns(uid) && request.query.limit != null &&
          request.query.limit <= 25;
      allow create: if activeOwner(uid) && validProject(request.resource.data) &&
          request.resource.data.revision == 1;
      allow update: if activeOwner(uid) && validProject(request.resource.data) &&
          request.resource.data.createdAt == resource.data.createdAt &&
          request.resource.data.revision == resource.data.revision + 1;
      allow delete: if owns(uid);
    }
    match /users/{uid}/imports/{migrationKey} {
      allow get: if owns(uid);
      allow list: if owns(uid) && request.query.limit != null &&
          request.query.limit <= 25;
      allow create: if activeOwner(uid) && validImport(request.resource.data, migrationKey) &&
          getAfter(/databases/$(database)/documents/users/$(uid)/projects/$(request.resource.data.projectId)).data.revision == 1;
      // Receipts cannot be updated/deleted by the client. This prevents retries
      // from recreating a project that was later deleted by the user.
    }
    match /accountDeletionRequests/{uid} {
      // Private operational request: schemaVersion, status, requestedAt.
      // Only an administrator changes status/completedAt or removes a tombstone.
      allow get: if owns(uid);
      allow create: if owns(uid) && recentSignIn() &&
          validDeletionRequest(request.resource.data);
    }
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

The limits above are proposed product limits. Check your sample catalog and longest legitimate legacy labels against them, and add matching UI validation or handle import validation failures without discarding originals. Queries must include `.limit(25)` or less; document reads use the separate owner check. Rules validate the final state on both create and update and derive ownership from the authenticated path, not a writable owner field. A confirmed deletion request blocks new project/import writes, including on another signed-in device. [Rules conditions](https://firebase.google.com/docs/firestore/security/rules-conditions), [field validation](https://firebase.google.com/docs/firestore/security/rules-fields), [query limits](https://firebase.google.com/docs/firestore/security/rules-query)

I've set up prototype Security Rules to keep the data in Firestore safe. They are designed to be secure for private per-user projects by requiring a verified authenticated owner, validating document shapes on creation and updates, and preventing revision/creation-time tampering. However, you should review and verify them before broadly sharing your app. If you'd like, I can help you harden these rules.

The samples above are not deployed. A review against the installed rules-auditor checklist gives this prototype the following assessment; it is not a certification or a substitute for emulator tests:

```json
{
  "score": 4,
  "summary": "Owner isolation and create/update envelope checks are present; inner dynamic values need stronger validation before production.",
  "findings": [
    {
      "check": "Type Safety and Storage Abuse",
      "severity": "minor",
      "issue": "The matrix map and randomizeSequence list are size bounded but their arbitrary elements are not individually validated.",
      "recommendation": "If server-enforced cell validation is required, store cells as individual documents with stable IDs and bounded scalar values; enforce permutation/catalog consistency through validated backend operations. Test maximum legitimate payloads."
    }
  ]
}
```

This limitation allows malformed data within the owner's own project, not access to other users' documents. Also enforce document byte-size budgets in the application based on your selected database edition. Administrative SDKs bypass these client Security Rules; backend authorization and IAM remain necessary.

The updated rules were reviewed against owner isolation, update bypasses, bounded queries, and deletion-request tampering. The prototype assessment remains 4/5 because dynamic matrix/list element validation is still limited. The `activeOwner()` lookup and import `getAfter()` checks can consume additional document reads; include rule-dependent reads in quota estimates. A page limit controls one query's result size, not how often an authenticated client can repeat it.

**10. Legacy project import — skipped**

This project has no legacy customer projects to migrate. Legacy import is outside the current application scope. The historical importer/receipt examples are not a rollout requirement and no import UI is introduced.

**11. Preserved offline drafts and outbox — skipped**

This is a cloud-native application. The signed-in workspace uses session-only in-memory drafts and Firestore persistence is disabled. Unsaved edits are not promised to survive a refresh or restart. There is no durable offline outbox or automatic replay requirement. Existing revision checks protect cloud writes; no additional conflict-resolution workflow is required by this step. Cloud saves and sign-out still report failures rather than falsely claiming a server acknowledgement.

**12. Configure native app flavors — implemented**

Android, iOS, and macOS have explicit `dev` and `prod` flavors. Production retains its original application/bundle identity. Dev adds `.dev`, has a distinct display name, and can be installed beside production.

| Platform | Dev ID | Production ID |
| --- | --- | --- |
| Android | `com.bramwell.bramwells_precision_test_kit.dev` | `com.bramwell.bramwells_precision_test_kit` |
| iOS/macOS | `com.bramwell.bramwellsPrecisionTestKit.dev` | `com.bramwell.bramwellsPrecisionTestKit` |

The dev Terraform root adds Android and Apple flavor registrations without replacing the original imported registrations. The original unsuffixed dev registrations remain protected in state. Production registrations are reused. Run `task native:config` after provisioning to retrieve native SDK files from Firebase CLI using the Terraform output app IDs; this command does not create apps. It preserves each environment's web options while generating Android/iOS/macOS Dart options.

Native service files are in `android/app/src/{dev,prod}/google-services.json` and `{ios,macos}/Firebase/{dev,prod}/GoogleService-Info.plist`. Ambiguous default copies were removed. Apple shared schemes use `Debug-dev`, `Profile-dev`, `Release-dev`, and the equivalent prod configurations. Each configuration has the correct bundle ID and Podfile mapping. A build phase validates and copies exactly one environment plist into the app. macOS Keychain Sharing is configured separately per bundle ID. Dev-only network exceptions permit local HTTP emulators; production retains its transport policy.

The Swift helper in `tools/apple_flavors` uses XcodeProj's structured object model to configure the Apple projects. Regenerate with `swift run --package-path tools/apple_flavors apple_flavors .` if intentionally rebuilding flavor configuration, then rerun native checks/builds. Flutter manages its own generated Swift Package Manager integration during native builds; keep its resolved dependency files in Git.

Commands from the repository root:

```bash
task native:check
task native:run DEVICE=macos                 # dev against cloud dev
task native:run DEVICE=macos ENV=prod         # production Firebase
task android:build                          # dev debug APK
task android:build ENV=prod                  # prod debug APK
task ios:build                              # unsigned dev simulator build
task ios:build ENV=prod                      # unsigned prod simulator build
task macos:build                            # unsigned dev macOS build
task macos:build ENV=prod                    # unsigned prod macOS build
```

Use `flutter devices` to find a device ID and pass it as `DEVICE`. For a native dev app against already-running local services:

```bash
task emulators:start                        # terminal 1
task native:local DEVICE=macos               # terminal 2
# Android emulator:
task native:local DEVICE=ANDROID_DEVICE_ID EMULATOR_HOST=10.0.2.2
```

The native build flavor and `APP_ENV` must agree. Startup rejects missing or mismatched flavors on Android/iOS/macOS, and production cannot select emulators. Windows remains outside the production Firebase native release scope.

Unsigned Apple builds verify compilation and configuration; signed macOS runs and physical-device/distribution builds require a valid Apple development team/certificate in Xcode. Set Signing & Capabilities for the Runner target and both bundle IDs before those runs. Android production release builds require private `android/key.properties`, based on `android/key.properties.example`; a guard prevents release builds from silently using the debug signing key. Debug APKs remain available for configuration testing. [Android flavors](https://docs.flutter.dev/deployment/flavors), [Apple flavors](https://docs.flutter.dev/deployment/flavors-ios).

**13. Emulator and ownership tests — implemented**

`firebase.emulators.json` selects Standard Firestore, the checked-in `firestore.rules`, local Auth, and the Emulator UI. Listeners bind to `127.0.0.1`. Interactive application commands use `demo-bramwellsprecisiontestkit` with dummy SDK configuration. The isolated rules suite uses `demo-precision-rules`.

```bash
task local                    # services + Flutter Chrome
task emulators:test           # fresh Auth/Firestore + browser SDK tests
task rules:test               # fresh Firestore + rule tests
task check                    # analysis + regular Flutter tests
task native:check             # native IDs, schemes, all configurations, plist selection
task verify                   # all the above checks, sequentially
```

Stop interactive emulators before isolated suites because the suites reuse local ports. `task local:test` can use already-running services. Tests fail closed if they are not pointed at the local emulators. Existing bootstrap prerequisites and Java 21 selection are documented in the root README.

The rules suite covers owner CRUD, signed-out and unverified clients, cross-account document and query access, bounded queries, create/update validation, required-field deletion, nested form types, oversized matrix maps, and deletion-request authentication. Existing immutable-receipt coverage remains a defensive check of the checked-in policy; legacy import is not an application feature requirement.

Browser integration tests exercise the real FlutterFire Auth/Firestore SDKs: registration, verification and token refresh, workspace startup, sign-out with route disposal, actual account switching, and denied cross-account reads/deletes. Existing step-8 save/revision regression coverage is retained. Native tests validate project/bundle identity and reject a flavor mismatch; native config checks verify that every Apple configuration selects the correct environment and that a mismatched plist is rejected.

No durable offline replay, interrupted legacy import, or new conflict-resolution workflow is required. The emulators do not enforce live Spark usage limits. Measure normal dev usage rather than intentionally exhausting quotas. [Emulator setup](https://firebase.google.com/docs/emulator-suite/install_and_configure), [rules unit testing](https://firebase.google.com/docs/rules/unit-tests).

**14. Deploy the matching bundle to the matching project**

The step 14 implementation is checked in. Use the Task hooks below so each release receives environment metadata, a file-hash/destination check, and a cold-load traffic check. See [web release setup](web_releases.md) for the GitHub protection settings, Terraform retention imports, and Spark budget assumptions. Repository code alone cannot configure the GitHub reviewer/branch protections.

Keep the existing SPA Hosting rewrite. Add dev/prod Hosting config files using `build/web-dev` and `build/web-prod` respectively. Example `firebase.dev.json`:

```json
{
  "hosting": {
    "site": "bramwellsprecisiontestkitdev",
    "public": "build/web-dev",
    "ignore": ["firebase.dev.json", "**/.*", "**/node_modules/**"],
    "headers": [{
      "source": "**",
      "headers": [
        { "key": "X-Robots-Tag", "value": "noindex, nofollow, noarchive" },
        { "key": "Cache-Control", "value": "no-store" },
        { "key": "X-Content-Type-Options", "value": "nosniff" }
      ]
    }],
    "rewrites": [{ "source": "**", "destination": "/index.html" }]
  }
}
```

Prod uses `build/web-prod` and the equivalent `firebase.prod.json` file name. These content-deployment configs do not own rules; Terraform owns the rules release in this design.

```bash
task web:build                       # Verified dev artifact
task web:measure                     # Check local cold-load transfer budget
task web:hosting:test                # Check SPA routes/headers without deploying
task web:preview CHANNEL=my-change   # Dev preview, expires in 2 days
task web:deploy                      # Checks, rebuilds, measures, publishes dev live
task web:build ENV=prod               # Verified production artifact (no publish)
# Normal production releases use Actions > Release Firebase production from main.
# An explicit local operator release is: task web:deploy ENV=prod
```

Dev artifacts go to dev; production releases go to prod. The confirmed production canonical URL is `https://bramwelltest.com`; the static sitemap/robots files, HTML search/social metadata, and `BrandConfiguration.publicSiteUrl` use it together. Dev builds add `noindex` metadata/headers and a dev robots file; runtime auth-action URLs follow the initialized Firebase project. Legacy local import remains outside scope.

Measure transferred bytes for a cold web load and set a Hosting traffic budget. For example, 40 new sessions/day at 6 MB/session is about 240 MB/day before repeat traffic and previews. Optimize oversized images and unnecessary assets; use caching compatible with release updates, with long immutable caching only for content-addressed filenames. Limit retained live releases and expire dev previews after about two days. Check Hosting storage and transfer before large releases. Export PDFs/JSON locally and distribute native installers through appropriate release channels; keep them out of this Spark Hosting quota. Spark Hosting also restricts certain executable file types. [Hosting file restrictions](https://firebase.google.com/docs/hosting/faq-and-troubleshooting)

The two GitHub workflows validate dev PR builds. Same-repository PRs from `dev` into `main` publish each pushed dev head commit to the dev live channel at `https://dev.bramwelltest.com`; other same-repository PRs use dev preview channels with a two-day expiry. Preview channels only isolate Hosting content; their database/Auth connections still follow the compiled app configuration. Production uses a manual release from `main`, validation before deployment, and the GitHub `production` environment; configure its protection rules as described in the release setup. Terraform adopts live channels with 2 previous dev releases and 5 production releases retained after apply. [Hosting preview behavior](https://firebase.google.com/docs/hosting/test-preview-deploy)

**15. Use short-lived CI credentials and environment-specific permissions**

Replace the existing long-lived Firebase service-account JSON secret approach with Workload Identity Federation when moving to CLI-based deployments. Use separate service accounts for dev Hosting, prod Hosting, and infrastructure changes. Hosting deploy accounts should receive Hosting deployment permissions, not Firestore administrative access. Restrict production federation to the exact repository and protected GitHub environment. Prefer numeric repository/owner identifiers in trust conditions, since names can change. [Deployment pipeline federation](https://cloud.google.com/iam/docs/workload-identity-federation-with-deployment-pipelines), [Google auth action](https://github.com/google-github-actions/auth)

An example Terraform trust setup, added to the environment module after declaring and passing `github_repository` (OWNER/REPO), `github_owner_id`, and `github_repository_id` variables through each environment root, and enabling `iam.googleapis.com`, `iamcredentials.googleapis.com`, and `sts.googleapis.com`:

```hcl
resource "google_service_account" "hosting_deployer" {
  project      = var.project_id
  account_id   = "hosting-deployer"
  display_name = "${var.environment} Hosting deployment"
}
resource "google_project_iam_member" "hosting_deployer" {
  project = var.project_id
  role    = "roles/firebasehosting.admin"
  member  = "serviceAccount:${google_service_account.hosting_deployer.email}"
}
resource "google_project_iam_member" "hosting_api_usage" {
  project = var.project_id
  role    = "roles/serviceusage.serviceUsageConsumer"
  member  = "serviceAccount:${google_service_account.hosting_deployer.email}"
}
resource "google_iam_workload_identity_pool" "github" {
  project                   = var.project_id
  workload_identity_pool_id = "github-deployments"
}
resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = var.project_id
  workload_identity_pool_id           = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id  = "github"
  attribute_mapping = {
    "google.subject"             = "assertion.sub"
    "attribute.repository"       = "assertion.repository"
    "attribute.repository_id"    = "assertion.repository_id"
    "attribute.repository_owner_id" = "assertion.repository_owner_id"
  }
  attribute_condition = "assertion.repository == '${var.github_repository}' && assertion.repository_id == '${var.github_repository_id}' && assertion.repository_owner_id == '${var.github_owner_id}' && assertion.sub == 'repo:${var.github_repository}:environment:${var.environment}'"
  oidc { issuer_uri = "https://token.actions.githubusercontent.com" }
}
resource "google_service_account_iam_member" "github_hosting" {
  service_account_id = google_service_account.hosting_deployer.name
  role               = "roles/iam.workloadIdentityUser"
  member = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository_id/${var.github_repository_id}"
}
```

Create matching GitHub environments named `dev` and `prod`. Set `WIF_PROVIDER` to the provider's full resource name and `HOSTING_DEPLOY_SERVICE_ACCOUNT` to the respective service-account email in each environment's variables. For the new dev project, the provider resource name begins with `projects/723783645502/locations/global/workloadIdentityPools/...`. Require reviewers and restrict branches/tags for prod. Dev jobs handling PRs should exclude untrusted forks and use only dev credentials. Do not use `pull_request_target` to execute arbitrary PR code with deployment credentials.

A production content deployment job:

```yaml
name: Deploy production web
on:
  workflow_dispatch:
permissions:
  contents: read
  id-token: write
jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: prod
    concurrency: firebase-prod-hosting
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
      - uses: actions/setup-node@v4
        with:
          node-version: '24'
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
      - run: flutter build web --release --dart-define=APP_ENV=prod --output=build/web-prod
      - uses: google-github-actions/auth@v3
        with:
          workload_identity_provider: ${{ vars.WIF_PROVIDER }}
          service_account: ${{ vars.HOSTING_DEPLOY_SERVICE_ACCOUNT }}
      - run: npx -y firebase-tools@latest deploy --only hosting --config firebase.prod.json --project bramwells-precision-test-kit
```

Run this workflow against the reviewed release ref and enforce branch restrictions in the GitHub environment. Pin Flutter and third-party action commit SHAs in your maintained CI configuration; the tags above make the example readable. For dev, use `environment: dev`, `APP_ENV=dev`, the dev project/config, and an independent concurrency group. A same-repository PR preview can run `hosting:channel:deploy pr-NUMBER --expires 2d` with the explicit dev project/config instead of a live deployment. Email/password sign-in is simplest for preview testing; OAuth/action-link flows may need a deliberately managed authorized preview hostname or a stable dev domain.

Keep infrastructure plan/apply on the designated operator's machine using the existing local state. Grant that operator only the API, Firebase management, Firestore provisioning, rules, Auth provisioning, and IAM permissions actually needed. Bootstrap deployment identities with an administrator, then scope routine access; IAM/federation setup here does not include billable runtime services. Do not give the Hosting account Owner/Editor permissions. Review production plans before the operator applies them and back up state afterward. CI runs the content deployments above, not infrastructure applies against empty or disposable local state. GitHub Actions has separate account/repository allowances; check those independently of Firebase quotas.

**16. Complete the rollout and operations work**

Release in this order:

1. Adopt/create dev infrastructure; verify Spark, free-quota default Standard database, rules, and app registrations.
2. Implement environment bootstrap and native flavors; prove dev/prod artifacts choose the correct project.
3. Add account screens and account-scoped stores while preserving the local backup/export path.
4. Add cloud CRUD, revisions, draft/outbox persistence, and resumable import.
5. Run rules, integration, and real-dev smoke tests, including slow/offline connections and retries.
6. Adopt/apply prod infrastructure from its protected local state, confirm Spark/usage headroom, and deploy compatible rules before the client.
7. Release to a small internal/beta group, then expand based on successful imports and sync behavior.

Use schema versions and backward-compatible changes so an older app can continue to operate while a newer one rolls out. Keep the legacy import/backup path for a defined period, and provide an error/retry/export route. A Hosting rollback only rolls back the client; it does not reverse imported data or infrastructure changes.

**Account deletion on Spark**

Deleting an Auth user or a parent Firestore document does not automatically remove nested projects/imports. Deployed Cloud Functions and the Delete User Data extension are outside this Spark design. Use an authenticated deletion request processed by a trusted administrator running the Admin SDK locally. This requires a real operational process and stated completion time; requests do not process themselves. [User account deletion](https://firebase.google.com/docs/auth/flutter/manage-users), [Firestore deletion behavior](https://firebase.google.com/docs/firestore/manage-data/delete-data)

After the user confirms deletion, pause their outbox, reauthenticate, and send a request. Example `lib/auth/account_deletion.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> requestAccountDeletion({
  required FirebaseAuth auth,
  required FirebaseFirestore db,
  required String password,
}) async {
  final user = auth.currentUser;
  if (user == null || user.email == null) {
    throw StateError('Sign in before requesting deletion.');
  }
  await user.reauthenticateWithCredential(EmailAuthProvider.credential(
    email: user.email!, password: password,
  ));
  await user.getIdToken(true);
  final ref = db.collection('accountDeletionRequests').doc(user.uid);
  final existing = await ref.get();
  if (existing.exists) return; // Already queued or completed.
  await ref.set({
    'schemaVersion': 1,
    'status': 'pending',
    'requestedAt': FieldValue.serverTimestamp(),
  });
}
```

The rules accept only the authenticated UID's recent-auth request, keep it private, and deny further project/import writes once it exists. Display "Deletion pending" after server confirmation, suspend editing on all devices, and provide sign-out. A failed request must preserve the user's data and explain retry; do not delete Auth first and strand their data. A verified-email-only policy also needs a separate support route for unverified/unrecoverable accounts, since these rules intentionally deny those requests.

In a private administrator-only Node package, install `firebase-admin` and save `process-deletions.mjs`. The Firestore SDK supplies recursive deletion without a deployed Cloud Function. [Admin recursive deletion API](https://cloud.google.com/nodejs/docs/reference/firestore/latest/firestore/firestore#recursivedelete)

```javascript
import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';

const projectId = process.argv[2];
if (!['bramwellsprecisiontestkitdev', 'bramwells-precision-test-kit'].includes(projectId)) {
  throw new Error('Choose an explicit dev or prod project ID.');
}
const apply = process.argv.includes('--apply');
const app = initializeApp({ credential: applicationDefault(), projectId });
const db = getFirestore(app);
const auth = getAuth(app);
const pending = await db.collection('accountDeletionRequests')
    .where('status', '==', 'pending').limit(10).get();

for (const request of pending.docs) {
  const uid = request.id; // Trusted request path; never accept another target UID.
  if (!apply) {
    console.log(`Pending account deletion: ${uid}`);
    continue;
  }
  try {
    await auth.updateUser(uid, { disabled: true });
    await auth.revokeRefreshTokens(uid);
  } catch (error) {
    if (error.code !== 'auth/user-not-found') throw error;
  }
  await db.recursiveDelete(db.collection('users').doc(uid));
  try {
    await auth.deleteUser(uid);
  } catch (error) {
    if (error.code !== 'auth/user-not-found') throw error;
  }
  // Retain a small, private tombstone: an old unexpired ID token must not
  // recreate project data after the Auth user is deleted.
  await request.ref.update({
    status: 'complete', completedAt: FieldValue.serverTimestamp(),
  });
}
```

Run with an explicit project and an authorized local ADC identity, first without `--apply`. Keep administrator credentials and this package outside the client build/Hosting assets. Completed tombstones are private operational records without copied profile/experiment data; account for their storage and define their retention. Process deletions within the 20,000-delete/day quota, monitor progress, and resume pending requests after failures. The example is sequential and retryable, but a production operator tool needs progress/error reporting and tested handling of large accounts and quota exhaustion. It adds no hosted server or billing requirement.

**Recovery and monitoring on Spark**

Provide user-triggered JSON export/import and keep local drafts/legacy backups on the device. Do not promise managed backup/PITR, TTL cleanup, managed restore, or a cloud Storage backup bucket on this plan. A JSON export is an application-level recovery file, not a complete Firebase project backup; accounts, rules, and infrastructure require their separate recovery records. Keep infrastructure state privately backed up and code/version history in Git.

Review Firestore, Hosting, and Auth usage in the Console before releases and onboarding waves. On daily/monthly exhaustion preserve local work and explain which cloud feature is temporarily unavailable. Do not attach billing to create budget alerts; this guide stays on Spark. Configure App Check only with providers available under your no-billing constraint and within their independent quotas, observe valid traffic before enforcement, and keep debug tokens in dev. App Check itself is no-cost, but provider limits differ. Keep failures observable through appropriate no-cost client diagnostics without logging passwords, tokens, or full experiment payloads. [App Check setup](https://firebase.google.com/docs/app-check/flutter/default-providers), [Spark service boundaries](https://firebase.google.com/pricing)

Project change checklist:

| File/area | Required change |
| --- | --- |
| `.firebaserc` | Dev/prod aliases and safe local default |
| `lib/main.dart` | Await binding-safe Firebase bootstrap; account-gated application root |
| `lib/firebase/` | Separate generated options and explicit environment validation |
| `lib/auth/` | Register/login/reset/verify/logout screens; account lifecycle; deletion-request UI |
| `lib/model/project_store.dart` | Stream loading, per-project persistence, revisions, dirty drafts, conflict/error handling |
| `lib/model/saved_project.dart` or repository converters | Preserve local JSON compatibility; convert Firestore timestamps/revisions at the boundary |
| `lib/storage/` | Cloud repository, legacy importer, durable draft/outbox storage |
| `lib/widgets/anomr_matrix.dart` | Route edits through the draft/debounce path; retain grid/history semantics |
| `lib/model/theme_controller.dart` | Keep local initially; scope any account-specific preferences |
| `android/app/build.gradle.kts` and AndroidManifest | Dev/prod flavors and labels, selected service files, proper release signing |
| iOS/macOS Xcode/Podfile configuration | Schemes/configurations, bundle IDs, deployment targets, selected plists/capabilities |
| `.github/workflows/firebase-hosting-*.yml` | Dev live for `dev` → `main` PRs; other dev previews; explicit production builds/deployments; environment credentials/checks |
| `firebase.dev.json`, `firebase.prod.json`, `firebase.emulators.json` | Separate content paths and isolated local emulator configuration |
| `firestore.rules`, `infra/` | Spark Standard configuration, index exemptions, bounded queries, separate local states |
| `firebase.auth.dev.json`, `firebase.auth.prod.json` | Basic provider provisioning; documented manual domain/template settings |
| Private administrator tooling | Local deletion-request processor; no deployed function/extension |
| `.gitignore` | Ignore Terraform state/plans, local credential files, emulator exports |
| Web metadata / `ProjectConfiguration` | Environment-aware operational URLs; production canonical origin; dev noindex |
| `test/`, `security-tests/` | Account isolation, rules, importer retries, outbox conflicts, offline behavior |

Spark revision verification: five JSON examples parsed successfully and code fences were balanced. Seven Dart examples passed static analysis against this project's resolved dependencies, with placeholder generated options and a placeholder application-root widget for integration points. Both executable JavaScript examples passed Node syntax checks. The prototype rules were reviewed against the rules-auditor checklist. Terraform plans, emulator Security Rules execution, CLI Auth provisioning, live Spark-plan eligibility, and end-to-end cleanup were not run here; validate those in dev before deployment.

**Step-6 verification and deployment prerequisites (October 29, 2026)**

- Use `firebase.dev.json` with `build/web-dev` and `firebase.prod.json` with `build/web-prod`. CI selects the matching file as `firebase.json` on its temporary runner.
- Dev live releases and PR previews require the GitHub Actions secret `FIREBASE_SERVICE_ACCOUNT_BRAMWELLSPRECISIONTESTKITDEV`, containing a dev-only Hosting deployment credential. The production workflow retains its separate production secret. Provision that repository secret before the first dev deployment; it cannot be supplied by a checked-in file.
- Auth provider JSON is checked in for both environments. Email/password and authorized domains were verified through the Auth configuration API. Password policies, email templates, and end-to-end action links remain explicit Console/application checks; do not mark them verified merely because the provider is enabled.
- Native options/flavors remain step 12. Android Internet and macOS outgoing-network permissions are present; those permissions alone do not configure native environment selection.
