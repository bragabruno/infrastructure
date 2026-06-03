output "firebase_config" {
  value = {
    api_key             = google_apikeys_key.firebase.key_string
    auth_domain         = "${var.gcp_project_id}.firebaseapp.com"
    project_id          = var.gcp_project_id
    storage_bucket      = "${var.gcp_project_id}.firebasestorage.app"
    messaging_sender_id = google_firebase_project.main.project_number
    app_id              = google_firebase_web_app.main.app_id
  }
  sensitive = true
}

output "firebase_project_id" {
  value = var.gcp_project_id
}

output "service_account_email" {
  value = google_service_account.firebase_admin.email
}
