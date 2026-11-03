environment             = "dev"
project_id              = "bramwellsprecisiontestkitdev"
expected_project_number = "723783645502"
database_id             = "(default)"

# Preserve the original registrations while adding separate .dev flavors.
android_package_name = "com.bramwell.bramwells_precision_test_kit"
apple_bundle_ids = [
  "com.bramwell.bramwellsPrecisionTestKit",
  "com.bramwell.bramwellsPrecisionTestKit.dev",
]

# Confirm the actual region and supply reviewed rules before planning.
location   = "us-central1"
rules_file = "../../../firestore.rules"
