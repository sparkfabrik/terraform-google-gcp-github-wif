# Example: GitHub Actions Workload Identity Federation with GCP

# Configure the GitHub provider
provider "github" {
  owner = var.github_organization
  # token = var.github_token  # Or use GITHUB_TOKEN environment variable
}

# Configure the Google provider
provider "google" {
  project = var.gcp_project_id
}

module "github_wif" {
  source = "../"

  name           = "my-github-wif"
  gcp_project_id = var.gcp_project_id

  # Option 1: Repository-level access (recommended for most use cases)
  github_repository_names = var.github_repositories

  # Option 2: Organization-level access (use with caution - allows all repos in org)
  # github_organization_id = var.github_organization_id

  # Optional: Add additional conditions for security
  # github_attribute_condition_additional = "attribute.ref==\"refs/heads/main\""

  # Optional: Secret Manager integration
  secret_names = var.secret_names
}

# Output the workload identity provider path for use in GitHub Actions
output "workload_identity_provider" {
  description = "Use this value in the 'workload_identity_provider' input of google-github-actions/auth"
  value       = module.github_wif.workload_identity_provider
}

output "service_account_email" {
  description = "Use this value in the 'service_account' input of google-github-actions/auth"
  value       = module.github_wif.service_account_email
}

output "github_actions_variables" {
  description = "Variables automatically created in GitHub Actions"
  value       = module.github_wif.github_actions_variables
}
