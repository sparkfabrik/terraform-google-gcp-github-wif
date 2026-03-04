variable "name" {
  description = "The name to use for all resources created by this module."
  type        = string
}

# Google Cloud Platform (GCP) variables
variable "gcp_project_id" {
  description = "The ID of the project in which to provision resources."
  type        = string
}

variable "gcp_existing_service_account_account_id" {
  description = "The account_id of an existing service account to use for GitHub WIF. If not provided, a new service account will be created."
  type        = string
  default     = null
}

variable "gcp_workload_identity_pool_provider_attribute_mapping" {
  description = "A map of attribute mappings for the GCP Workload Identity Federation provider. This allows you to customize how attributes are mapped from GitHub to GCP."
  type        = map(string)
  default = {
    # google.subject must be unique per token - using actor + run_id + run_attempt
    "google.subject"                  = "assertion.actor+\"::run:\"+assertion.run_id+\"::attempt:\"+assertion.run_attempt"
    "attribute.actor"                 = "assertion.actor"
    "attribute.actor_id"              = "assertion.actor_id"
    "attribute.repository"            = "assertion.repository"
    "attribute.repository_id"         = "assertion.repository_id"
    "attribute.repository_owner"      = "assertion.repository_owner"
    "attribute.repository_owner_id"   = "assertion.repository_owner_id"
    "attribute.repository_visibility" = "assertion.repository_visibility"
    "attribute.ref"                   = "assertion.ref"
    "attribute.ref_type"              = "assertion.ref_type"
    "attribute.event_name"            = "assertion.event_name"
    "attribute.workflow"              = "assertion.workflow"
    "attribute.workflow_ref"          = "assertion.workflow_ref"
    "attribute.job_workflow_ref"      = "assertion.job_workflow_ref"
    "attribute.environment"           = "assertion.environment"
    "attribute.runner_environment"    = "assertion.runner_environment"
    # GitHub Enterprise Cloud claims
    "attribute.enterprise"    = "assertion.enterprise"
    "attribute.enterprise_id" = "assertion.enterprise_id"
  }

  validation {
    condition     = length(var.gcp_workload_identity_pool_provider_attribute_mapping) > 0 && contains(keys(var.gcp_workload_identity_pool_provider_attribute_mapping), "google.subject") && length(var.gcp_workload_identity_pool_provider_attribute_mapping["google.subject"]) > 0
    error_message = "gcp_workload_identity_pool_provider_attribute_mapping must contain a non-empty 'google.subject' mapping."
  }
}

# GitHub variables
variable "github_organization_id" {
  description = "The GitHub organization ID to allow access from. Use this for organization-level access."
  type        = number
  default     = null

  validation {
    condition     = var.github_organization_id == null ? true : var.github_organization_id > 0
    error_message = "github_organization_id must be a valid positive GitHub organization ID or null."
  }
}

variable "github_enterprise_id" {
  description = "The GitHub Enterprise ID to allow access from. Only available with GitHub Enterprise Cloud."
  type        = string
  default     = null
}

variable "github_repository_ids" {
  description = "The GitHub repository IDs to allow access from. Use this for repository-level access."
  type        = list(number)
  default     = []

  validation {
    condition     = length(var.github_repository_ids) == 0 || alltrue([for id in var.github_repository_ids : id > 0])
    error_message = "github_repository_ids must be a valid list of GitHub repository IDs or an empty list."
  }
}

variable "github_repository_names" {
  description = "The GitHub repository names (in format 'owner/repo') to allow access from. Use this for repository-level access when you prefer to use repository names instead of IDs."
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.github_repository_names) == 0 || alltrue([for name in var.github_repository_names : can(regex("^[^/]+/[^/]+$", name))])
    error_message = "github_repository_names must be in the format 'owner/repo'."
  }
}

variable "github_token_issuer_url" {
  description = "The URL of the GitHub OIDC token issuer."
  type        = string
  default     = "https://token.actions.githubusercontent.com"
}

variable "github_gcp_wif_project_id_variable_name" {
  description = "The name of the GitHub Actions variable to store the GCP project ID for WIF."
  type        = string
  default     = "GCP_WIF_PROJECT_ID"
}

variable "github_gcp_wif_service_account_email_variable_name" {
  description = "The name of the GitHub Actions variable to store the GCP WIF service account email."
  type        = string
  default     = "GCP_WIF_SERVICE_ACCOUNT_EMAIL"
}

variable "github_gcp_wif_workload_identity_provider_variable_name" {
  description = "The name of the GitHub Actions variable to store the full workload identity provider path (used by google-github-actions/auth)."
  type        = string
  default     = "GCP_WORKLOAD_IDENTITY_PROVIDER"
}

variable "github_create_oidc_variables" {
  description = "Whether to create GitHub Actions variables for the WIF configuration. Set to false if you want to manage variables manually."
  type        = bool
  default     = true
}

variable "github_organization_variables_visibility" {
  description = "Visibility level for organization-level variables. Valid values: all, private, selected."
  type        = string
  default     = "all"

  validation {
    condition     = contains(["all", "private", "selected"], var.github_organization_variables_visibility)
    error_message = "github_organization_variables_visibility must be one of: all, private, selected."
  }
}

variable "github_organization_variables_selected_repository_ids" {
  description = "List of repository IDs that can access organization-level variables. Only used when github_organization_variables_visibility is 'selected'."
  type        = list(number)
  default     = []
}

variable "github_variables_additional" {
  description = "Additional GitHub Actions variables to create. This should be a map where the key is the variable name and the value is the variable value."
  type        = map(string)
  default     = {}
}

# Attribute condition customization
variable "github_attribute_condition_additional" {
  description = "Additional CEL expression to AND with the generated attribute condition. Use this to add extra restrictions like branch filters, environment filters, etc."
  type        = string
  default     = null
}

# Secret Manager variables
variable "secret_gcp_project_id" {
  description = "The GCP project ID where secrets will be created. If not provided, defaults to `var.gcp_project_id`."
  type        = string
  default     = null
}

variable "secret_names" {
  description = "List of secret names to create and grant access to."
  type        = list(string)
  default     = []
}
