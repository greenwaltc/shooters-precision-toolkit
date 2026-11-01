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
