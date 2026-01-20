# GitHub Actions variables for Workload Identity Federation
# Repository-level variables for each specified repository

# Create WIF variables at repository level
resource "github_actions_variable" "gcp_wif_project_number" {
  for_each = var.github_create_oidc_variables ? toset(var.github_repository_names) : []

  repository    = local.parsed_repositories[each.value].name
  variable_name = var.github_gcp_wif_project_id_variable_name
  value         = data.google_project.project.number
}

resource "github_actions_variable" "gcp_wif_pool" {
  for_each = var.github_create_oidc_variables ? toset(var.github_repository_names) : []

  repository    = local.parsed_repositories[each.value].name
  variable_name = var.github_gcp_wif_pool_variable_name
  value         = google_iam_workload_identity_pool.this.workload_identity_pool_id
}

resource "github_actions_variable" "gcp_wif_provider" {
  for_each = var.github_create_oidc_variables ? toset(var.github_repository_names) : []

  repository    = local.parsed_repositories[each.value].name
  variable_name = var.github_gcp_wif_provider_variable_name
  value         = google_iam_workload_identity_pool_provider.this.workload_identity_pool_provider_id
}

resource "github_actions_variable" "gcp_wif_service_account_email" {
  for_each = var.github_create_oidc_variables ? toset(var.github_repository_names) : []

  repository    = local.parsed_repositories[each.value].name
  variable_name = var.github_gcp_wif_service_account_email_variable_name
  value         = local.sa_email
}

resource "github_actions_variable" "gcp_workload_identity_provider" {
  for_each = var.github_create_oidc_variables ? toset(var.github_repository_names) : []

  repository    = local.parsed_repositories[each.value].name
  variable_name = var.github_gcp_wif_workload_identity_provider_variable_name
  value         = local.workload_identity_provider
}

# Additional variables
resource "github_actions_variable" "additional" {
  for_each = var.github_create_oidc_variables ? {
    for item in flatten([
      for repo in var.github_repository_names : [
        for key, value in var.github_variables_additional : {
          key   = "${local.parsed_repositories[repo].name}--${key}"
          repo  = local.parsed_repositories[repo].name
          name  = key
          value = value
        }
      ]
    ]) : item.key => item
  } : {}

  repository    = each.value.repo
  variable_name = each.value.name
  value         = each.value.value
}

# Organization-level variables (when github_organization_name is provided)
resource "github_actions_organization_variable" "gcp_wif_project_number" {
  count = var.github_create_oidc_variables && var.github_organization_name != null && length(var.github_repository_names) == 0 ? 1 : 0

  variable_name           = var.github_gcp_wif_project_id_variable_name
  visibility              = var.github_organization_variables_visibility
  value                   = data.google_project.project.number
  selected_repository_ids = var.github_organization_variables_visibility == "selected" ? var.github_organization_variables_selected_repository_ids : null
}

resource "github_actions_organization_variable" "gcp_wif_pool" {
  count = var.github_create_oidc_variables && var.github_organization_name != null && length(var.github_repository_names) == 0 ? 1 : 0

  variable_name           = var.github_gcp_wif_pool_variable_name
  visibility              = var.github_organization_variables_visibility
  value                   = google_iam_workload_identity_pool.this.workload_identity_pool_id
  selected_repository_ids = var.github_organization_variables_visibility == "selected" ? var.github_organization_variables_selected_repository_ids : null
}

resource "github_actions_organization_variable" "gcp_wif_provider" {
  count = var.github_create_oidc_variables && var.github_organization_name != null && length(var.github_repository_names) == 0 ? 1 : 0

  variable_name           = var.github_gcp_wif_provider_variable_name
  visibility              = var.github_organization_variables_visibility
  value                   = google_iam_workload_identity_pool_provider.this.workload_identity_pool_provider_id
  selected_repository_ids = var.github_organization_variables_visibility == "selected" ? var.github_organization_variables_selected_repository_ids : null
}

resource "github_actions_organization_variable" "gcp_wif_service_account_email" {
  count = var.github_create_oidc_variables && var.github_organization_name != null && length(var.github_repository_names) == 0 ? 1 : 0

  variable_name           = var.github_gcp_wif_service_account_email_variable_name
  visibility              = var.github_organization_variables_visibility
  value                   = local.sa_email
  selected_repository_ids = var.github_organization_variables_visibility == "selected" ? var.github_organization_variables_selected_repository_ids : null
}

resource "github_actions_organization_variable" "gcp_workload_identity_provider" {
  count = var.github_create_oidc_variables && var.github_organization_name != null && length(var.github_repository_names) == 0 ? 1 : 0

  variable_name           = var.github_gcp_wif_workload_identity_provider_variable_name
  visibility              = var.github_organization_variables_visibility
  value                   = local.workload_identity_provider
  selected_repository_ids = var.github_organization_variables_visibility == "selected" ? var.github_organization_variables_selected_repository_ids : null
}

# Organization-level additional variables
resource "github_actions_organization_variable" "additional" {
  for_each = var.github_create_oidc_variables && var.github_organization_name != null && length(var.github_repository_names) == 0 ? var.github_variables_additional : {}

  variable_name           = each.key
  visibility              = var.github_organization_variables_visibility
  value                   = each.value
  selected_repository_ids = var.github_organization_variables_visibility == "selected" ? var.github_organization_variables_selected_repository_ids : null
}
