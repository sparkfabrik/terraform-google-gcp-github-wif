resource "random_id" "suffix" {
  byte_length = 4
}

# Google resources for Workload Identity Federation
data "google_project" "project" {
  project_id = var.gcp_project_id
}

resource "google_iam_workload_identity_pool" "this" {
  project                   = var.gcp_project_id
  workload_identity_pool_id = "pool-${substr(local.resource_name_suffix, 0, 32 - length("pool-"))}"
  display_name              = local.pool_display_name
  description               = "Identity pool for ${var.name}"

  lifecycle {
    # Prevent creation of resources if the module is not configured correctly
    precondition {
      condition     = var.github_organization_id != null || length(var.github_repository_names) > 0
      error_message = "At least one of github_organization_id or github_repository_names must be provided."
    }
  }
}

resource "google_iam_workload_identity_pool_provider" "this" {
  project                            = var.gcp_project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.this.workload_identity_pool_id
  workload_identity_pool_provider_id = "provider-${substr(local.resource_name_suffix, 0, 32 - length("provider-"))}"
  display_name                       = local.provider_display_name
  description                        = "OIDC identity pool provider for ${var.name}"
  attribute_condition                = local.attribute_condition
  attribute_mapping                  = var.gcp_workload_identity_pool_provider_attribute_mapping

  oidc {
    issuer_uri = local.github_issuer_url
  }
}

resource "google_service_account" "this" {
  count = var.gcp_existing_service_account_account_id == null ? 1 : 0

  project      = var.gcp_project_id
  account_id   = local.account_id
  display_name = "Service Account for ${var.name}"
}

data "google_service_account" "this" {
  count = var.gcp_existing_service_account_account_id != null ? 1 : 0

  account_id = var.gcp_existing_service_account_account_id
  project    = var.gcp_project_id
}

resource "google_service_account_iam_member" "this" {
  for_each = local.principal_sets

  service_account_id = local.sa_name
  role               = "roles/iam.workloadIdentityUser"
  member             = each.value
}
