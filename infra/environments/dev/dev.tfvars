environment             = "dev"
project_id              = "bramwellsprecisiontestkitdev"
expected_project_number = "723783645502"
database_id             = "(default)"

# Match the registrations already referenced by firebase.json and the current
# native builds. Introduce .dev registrations with the native flavors later.
android_package_name = "com.bramwell.bramwells_precision_test_kit"
apple_bundle_ids     = ["com.bramwell.bramwellsPrecisionTestKit"]

# Confirm the actual region and supply reviewed rules before planning.
location   = "us-central1"
rules_file = "../../../firestore.rules"
