locals {
  resource_name_suffix = "${var.name}-${random_id.suffix.hex}"

  repository_resource_suffix   = "repository"
  organization_resource_suffix = "organization"
  enterprise_resource_suffix   = "enterprise"

  # GitHub OIDC issuer URL
  github_issuer_url = var.github_token_issuer_url

  # Build attribute condition for repository access
  # GitHub uses "repository" claim in format "owner/repo"
  repositories_attribute_condition = length(var.github_repository_names) > 0 ? "(${join(" || ", [for repo in var.github_repository_names : "attribute.repository==\"${repo}\""])})" : null

  # Build attribute condition for repository ID access
  repository_ids_attribute_condition = length(var.github_repository_ids) > 0 ? "(${join(" || ", [for id in var.github_repository_ids : "attribute.repository_id==\"${id}\""])})" : null

  # Build attribute condition for organization access
  # GitHub uses "repository_owner_id" claim for organization ID
  organization_attribute_condition = var.github_organization_id != null ? "(attribute.repository_owner_id==\"${var.github_organization_id}\")" : null

  # Build attribute condition for enterprise access (GitHub Enterprise Cloud only)
  enterprise_attribute_condition = var.github_enterprise_id != null ? "(attribute.enterprise_id==\"${var.github_enterprise_id}\")" : null

  # Combine all conditions
  base_attribute_condition = join(" || ", compact([
    local.repositories_attribute_condition,
    local.repository_ids_attribute_condition,
    local.organization_attribute_condition,
    local.enterprise_attribute_condition,
  ]))

  # Add additional condition if provided
  attribute_condition = var.github_attribute_condition_additional != null ? "(${local.base_attribute_condition}) && (${var.github_attribute_condition_additional})" : local.base_attribute_condition

  # Principal subjects for IAM bindings
  # For repositories, we bind to the repository attribute
  # For organization, we bind to the repository_owner_id attribute
  # For enterprise, we bind to the enterprise_id attribute
  principal_subjects = merge(
    { for repo in var.github_repository_names : "${local.repository_resource_suffix}-${replace(repo, "/", "-")}" => "attribute.repository/${repo}" },
    { for id in var.github_repository_ids : "${local.repository_resource_suffix}-id-${id}" => "attribute.repository_id/${id}" },
    var.github_organization_id != null ? { (local.organization_resource_suffix) = "attribute.repository_owner_id/${var.github_organization_id}" } : {},
    var.github_enterprise_id != null ? { (local.enterprise_resource_suffix) = "attribute.enterprise_id/${var.github_enterprise_id}" } : {},
  )

  principal_sets = {
    for key, subject in local.principal_subjects : key => "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.this.name}/${subject}"
  }

  # Ensure the account_id is always 28 characters or less
  sa_name_prefix    = "gwif-sa-"
  sa_name_max_len   = 28 - length(local.sa_name_prefix)
  sa_name_truncated = substr(local.resource_name_suffix, 0, local.sa_name_max_len)
  account_id        = "${local.sa_name_prefix}${local.sa_name_truncated}"

  # Manage conditionally creation of the service account
  sa_must_be_created = var.gcp_existing_service_account_account_id == null
  sa_name            = local.sa_must_be_created ? resource.google_service_account.this[0].name : data.google_service_account.this[0].name
  sa_email           = local.sa_must_be_created ? resource.google_service_account.this[0].email : data.google_service_account.this[0].email
  sa_member          = local.sa_must_be_created ? resource.google_service_account.this[0].member : data.google_service_account.this[0].member

  # Ensure the display_name is always 32 characters or less
  pool_display_name_suffix    = " Pool"
  pool_display_name_max_len   = 32 - length(local.pool_display_name_suffix)
  pool_display_name_truncated = substr(var.name, 0, local.pool_display_name_max_len)
  pool_display_name           = "${local.pool_display_name_truncated}${local.pool_display_name_suffix}"

  # Ensure the provider display_name is always 32 characters or less
  provider_display_name_suffix    = " Provider"
  provider_display_name_max_len   = 32 - length(local.provider_display_name_suffix)
  provider_display_name_truncated = substr(var.name, 0, local.provider_display_name_max_len)
  provider_display_name           = "${local.provider_display_name_truncated}${local.provider_display_name_suffix}"

  # Full workload identity provider path for google-github-actions/auth
  workload_identity_provider = "projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.this.workload_identity_pool_id}/providers/${google_iam_workload_identity_pool_provider.this.workload_identity_pool_provider_id}"

  # Create a prefix for secrets and ensure the final name is valid and under 255 characters
  secret_prefix          = "${var.name}-"
  max_secret_name_length = 255 - length(local.secret_prefix)

  # Clean and format each secret name
  formatted_secret_names = {
    for name in var.secret_names :
    name => substr("${local.secret_prefix}${lower(replace(replace(name, "_", "-"), "/[^a-z0-9-]/", ""))}", 0, 255)
  }

  secret_gcp_project_id = var.secret_gcp_project_id != null ? var.secret_gcp_project_id : var.gcp_project_id

  # Parse repository names into owner and repo
  parsed_repositories = {
    for repo in var.github_repository_names :
    repo => {
      owner = split("/", repo)[0]
      name  = split("/", repo)[1]
    }
  }
}
