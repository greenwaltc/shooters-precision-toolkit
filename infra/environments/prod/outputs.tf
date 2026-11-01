output "project_id" {
  value = module.firebase.project_id
}

output "project_number" {
  value = data.google_project.existing.number
}

output "web_app_id" {
  value = module.firebase.web_app_id
}

output "android_app_id" {
  value = module.firebase.android_app_id
}

output "apple_app_ids" {
  value = module.firebase.apple_app_ids
}

output "database_id" {
  value = module.firebase.database_id
}

output "hosting_url" {
  value = module.firebase.hosting_url
}
