# Secret manager resources
resource "google_secret_manager_secret" "secrets" {
  for_each = local.formatted_secret_names

  project   = local.secret_gcp_project_id
  secret_id = each.value

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_iam_member" "secrets" {
  for_each = toset(var.secret_names)

  project   = local.secret_gcp_project_id
  secret_id = google_secret_manager_secret.secrets[each.key].secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = local.sa_member
}
