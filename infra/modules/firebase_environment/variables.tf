variable "project_id" {
  description = "ID of an existing Firebase project; the module does not create or bill a Google Cloud project."
  type        = string
  nullable    = false
}

variable "environment" {
  description = "Environment used in resource display names."
  type        = string
  nullable    = false

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Choose dev or prod."
  }
}

variable "database_id" {
  description = "The single default database used by this Spark configuration."
  type        = string
  default     = "(default)"
  nullable    = false

  validation {
    condition     = var.database_id == "(default)"
    error_message = "This Spark module manages only the (default) database."
  }
}

variable "location" {
  description = "Confirmed Firestore location, matching any existing database."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.location)) > 0
    error_message = "Provide the confirmed Firestore location."
  }
}

variable "android_package_name" {
  description = "Android application ID of the registration to create or adopt."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.android_package_name)) > 0
    error_message = "Provide the Android application ID."
  }
}

variable "apple_bundle_ids" {
  description = "Unique Apple bundle IDs. iOS and macOS currently share one registration."
  type        = set(string)
  nullable    = false

  validation {
    condition = length(var.apple_bundle_ids) > 0 && alltrue([
      for bundle_id in var.apple_bundle_ids : length(trimspace(bundle_id)) > 0
    ])
    error_message = "Provide at least one nonempty Apple bundle ID."
  }
}

variable "rules_file" {
  description = "Absolute path to reviewed Firestore Security Rules; supplying the policy is an explicit deployment input."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.rules_file)) > 0
    error_message = "Provide a reviewed Firestore Security Rules file."
  }
}
