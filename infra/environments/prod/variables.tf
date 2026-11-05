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
