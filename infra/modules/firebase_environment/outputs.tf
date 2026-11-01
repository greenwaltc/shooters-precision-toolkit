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
