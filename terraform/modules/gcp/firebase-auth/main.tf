resource "google_firebase_project" "main" {
  provider = google-beta
  project  = var.gcp_project_id
}

resource "google_identity_platform_config" "main" {
  provider = google-beta
  project  = var.gcp_project_id

  sign_in {
    allow_duplicate_emails = false

    email {
      enabled           = true
      password_required = true
    }

    anonymous {
      enabled = false
    }
  }

  authorized_domains = [
    "${var.project_name}.web.app",
    "${var.project_name}.firebaseapp.com",
    "localhost",
  ]

  depends_on = [google_firebase_project.main]
}

resource "google_identity_platform_default_supported_idp_config" "google" {
  provider      = google-beta
  project       = var.gcp_project_id
  idp_id        = "google.com"
  client_id     = var.google_oauth_client_id
  client_secret = var.google_oauth_client_secret
  enabled       = true

  depends_on = [google_identity_platform_config.main]
}

resource "google_service_account" "firebase_admin" {
  account_id   = "${var.project_name}-admin"
  display_name = "${var.project_name} Firebase Admin SDK"
  project      = var.gcp_project_id
}

resource "google_project_iam_member" "firebase_admin" {
  project = var.gcp_project_id
  role    = "roles/firebaseauth.admin"
  member  = "serviceAccount:${google_service_account.firebase_admin.email}"
}

resource "google_firebase_web_app" "main" {
  provider     = google-beta
  display_name = "${var.project_name}-${var.environment}"
  project      = var.gcp_project_id

  depends_on = [google_firebase_project.main]
}
