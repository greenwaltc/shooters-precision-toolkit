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
