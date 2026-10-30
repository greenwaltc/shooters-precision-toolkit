# Optional infrastructure bootstrap

The environment roots operate on existing Firebase projects using local Terraform state. This directory reserves the bootstrap area from the migration guide for initial operator/deployment IAM setup.

Use an authorized local identity for the first setup:

```bash
gcloud auth application-default login
```

The base module handles API enablement through a provider with `user_project_override = false`, then manages Firebase resources with quota checks enabled. Project IDs and numbers are checked by each environment root before it manages resources.

For later CI deployment, follow step 15 of [the migration guide](../../docs/firebase_migration_guide.md) to create environment-specific service accounts and Workload Identity Federation. Review the repository IDs, GitHub environment, and IAM grants before introducing that optional configuration. Pin both Google provider variants to `8.9.0` in any future bootstrap root and give it its own private local state.

No bucket, billing account, project creation, or privileged IAM grants are part of this scaffold.
