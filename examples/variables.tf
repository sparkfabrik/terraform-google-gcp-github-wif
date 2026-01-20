variable "gcp_project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "github_organization" {
  description = "The GitHub organization name"
  type        = string
}

variable "github_organization_id" {
  description = "The GitHub organization ID (optional)"
  type        = number
  default     = null
}

variable "github_repositories" {
  description = "List of GitHub repositories in 'owner/repo' format"
  type        = list(string)
  default     = []
}

variable "secret_names" {
  description = "List of secret names to create in Secret Manager"
  type        = list(string)
  default     = []
}
