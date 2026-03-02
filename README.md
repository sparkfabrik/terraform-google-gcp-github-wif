# Terraform Google GCP GitHub Workload Identity Federation Module

This Terraform module sets up **Google Cloud Platform (GCP) Workload Identity Federation (WIF)** to allow GitHub Actions workflows to authenticate with GCP without using static service account keys.

## Features

- Creates a Workload Identity Pool and OIDC Provider for GitHub Actions
- Supports repository-level and organization-level access control
- Optionally creates a dedicated service account (or uses an existing one)
- Automatically creates GitHub Actions variables with WIF configuration
- Supports Secret Manager integration for managing secrets
- Flexible attribute conditions for fine-grained access control

## Usage

### Basic Usage - Repository Level Access

```hcl
module "github_wif" {
  source = "github.com/sparkfabrik/terraform-google-gcp-github-wif"

  name           = "my-github-wif"
  gcp_project_id = "my-gcp-project-id"

  github_repository_names = ["my-org/my-repo"]
}
```

### Organization Level Access

```hcl
module "github_wif" {
  source = "github.com/sparkfabrik/terraform-google-gcp-github-wif"

  name           = "org-github-wif"
  gcp_project_id = "my-gcp-project-id"

  github_organization_id = 12345678
}
```

### Enterprise Level Access (GitHub Enterprise Cloud)

> **Note:** GitHub Enterprise Cloud provides additional OIDC claims (`enterprise` and `enterprise_id`).
> While this module supports enterprise-level WIF attribute conditions, the GitHub Terraform provider
> does not currently support enterprise-level Actions variables. You'll need to configure
> variables at the organization or repository level.

```hcl
module "github_wif" {
  source = "github.com/sparkfabrik/terraform-google-gcp-github-wif"

  name           = "enterprise-github-wif"
  gcp_project_id = "my-gcp-project-id"

  # Enterprise-level WIF access (GitHub Enterprise Cloud only)
  github_enterprise_id = "123456"

  # Variables must still be set at org or repo level
  github_organization_id = 12345678
}
```

### Organization Level Access with Selected Repositories

```hcl
module "github_wif" {
  source = "github.com/sparkfabrik/terraform-google-gcp-github-wif"

  name           = "org-github-wif"
  gcp_project_id = "my-gcp-project-id"

  github_organization_id = 12345678

  # Only allow specific repositories to access the variables
  github_organization_variables_visibility              = "selected"
  github_organization_variables_selected_repository_ids = [123456789, 987654321]
}
```

### With Additional Security Conditions

```hcl
module "github_wif" {
  source = "github.com/sparkfabrik/terraform-google-gcp-github-wif"

  name           = "prod-deploy"
  gcp_project_id = "my-gcp-project-id"

  github_repository_names = ["my-org/my-repo"]
  
  # Only allow from main branch and production environment
  github_attribute_condition_additional = "attribute.ref==\"refs/heads/main\" && attribute.environment==\"production\""
}
```

### With Secret Manager Integration

```hcl
module "github_wif" {
  source = "github.com/sparkfabrik/terraform-google-gcp-github-wif"

  name           = "my-github-wif"
  gcp_project_id = "my-gcp-project-id"

  github_repository_names = ["my-org/my-repo"]
  
  secret_names = ["api-key", "database-password"]
}
```

## GitHub Actions Workflow

After applying this module, use the following workflow configuration:

```yaml
name: Deploy to GCP

on:
  push:
    branches: [main]

permissions:
  contents: read
  id-token: write  # Required for OIDC authentication

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - id: auth
        name: Authenticate to Google Cloud
        uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: ${{ vars.GCP_WORKLOAD_IDENTITY_PROVIDER }}
          service_account: ${{ vars.GCP_WIF_SERVICE_ACCOUNT_EMAIL }}

      - name: Set up Cloud SDK
        uses: google-github-actions/setup-gcloud@v2

      - name: Use gcloud CLI
        run: gcloud services list
```

## GitHub OIDC Token Claims

This module maps the following GitHub OIDC token claims to GCP attributes:

| GitHub Claim | GCP Attribute | Description |
|-------------|---------------|-------------|
| `repository` | `attribute.repository` | Full repository name (owner/repo) |
| `repository_id` | `attribute.repository_id` | Numeric repository ID |
| `repository_owner` | `attribute.repository_owner` | Organization or user name |
| `repository_owner_id` | `attribute.repository_owner_id` | Numeric owner ID |
| `repository_visibility` | `attribute.repository_visibility` | public, private, or internal |
| `actor` | `attribute.actor` | User who triggered the workflow |
| `actor_id` | `attribute.actor_id` | Numeric user ID |
| `ref` | `attribute.ref` | Git ref (e.g., refs/heads/main) |
| `ref_type` | `attribute.ref_type` | branch or tag |
| `event_name` | `attribute.event_name` | Trigger event (push, pull_request, etc.) |
| `workflow` | `attribute.workflow` | Workflow name |
| `workflow_ref` | `attribute.workflow_ref` | Full workflow path with ref |
| `job_workflow_ref` | `attribute.job_workflow_ref` | Reusable workflow reference |
| `environment` | `attribute.environment` | Deployment environment name |
| `runner_environment` | `attribute.runner_environment` | github-hosted or self-hosted |
| `enterprise` | `attribute.enterprise` | Enterprise name (Enterprise Cloud only) |
| `enterprise_id` | `attribute.enterprise_id` | Enterprise ID (Enterprise Cloud only) |

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5 |
| google | >= 3.53 |
| random | >= 3.0 |
| github | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| google | >= 3.53 |
| random | >= 3.0 |
| github | >= 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | The name to use for all resources created by this module | `string` | n/a | yes |
| gcp_project_id | The ID of the project in which to provision resources | `string` | n/a | yes |
| gcp_existing_service_account_account_id | The account_id of an existing service account to use | `string` | `null` | no |
| gcp_workload_identity_pool_provider_attribute_mapping | Custom attribute mappings for the OIDC provider | `map(string)` | See variables.tf | no |
| github_organization_id | GitHub organization ID for org-level access | `number` | `null` | no |
| github_enterprise_id | GitHub Enterprise ID (Enterprise Cloud only) | `string` | `null` | no |
| github_repository_ids | GitHub repository IDs for repo-level access | `list(number)` | `[]` | no |
| github_repository_names | GitHub repository names (owner/repo format) | `list(string)` | `[]` | no |
| github_token_issuer_url | GitHub OIDC token issuer URL | `string` | `"https://token.actions.githubusercontent.com"` | no |
| github_create_oidc_variables | Whether to create GitHub Actions variables | `bool` | `true` | no |
| github_organization_variables_visibility | Visibility for org-level variables (all, private, selected) | `string` | `"all"` | no |
| github_organization_variables_selected_repository_ids | Repository IDs for selected visibility | `list(number)` | `[]` | no |
| github_attribute_condition_additional | Additional CEL expression for attribute conditions | `string` | `null` | no |
| github_variables_additional | Additional GitHub Actions variables to create | `map(string)` | `{}` | no |
| secret_gcp_project_id | GCP project ID for Secret Manager | `string` | `null` | no |
| secret_names | List of secret names to create | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| workload_identity_pool_name | Full name of the Workload Identity Pool |
| workload_identity_pool_id | ID of the Workload Identity Pool |
| workload_identity_pool_provider_id | ID of the Workload Identity Provider |
| workload_identity_provider | Full resource path for google-github-actions/auth |
| service_account_email | Email of the Service Account |
| principal_set | Principal sets for IAM bindings |
| attribute_condition | The attribute condition used |
| github_actions_variables | Map of GitHub Actions variables created |
| secret_names | Map of secret names to formatted names |
| secret_project_id | GCP project ID where secrets are stored |
| secret_created | Names and IDs of created secrets |
| secret_ids | Map of secret names to Secret Manager IDs |

## Security Considerations

1. **Principle of Least Privilege**: Use repository-level access instead of organization-level when possible
2. **Branch Protection**: Add branch conditions to limit access to protected branches
3. **Environment Protection**: Use GitHub environments with protection rules
4. **Attribute Conditions**: Use `github_attribute_condition_additional` to add extra restrictions

## Example Attribute Conditions

```hcl
# Only main branch
github_attribute_condition_additional = "attribute.ref==\"refs/heads/main\""

# Only production environment
github_attribute_condition_additional = "attribute.environment==\"production\""

# Only github-hosted runners
github_attribute_condition_additional = "attribute.runner_environment==\"github-hosted\""

# Combined conditions
github_attribute_condition_additional = "attribute.ref==\"refs/heads/main\" && attribute.environment==\"production\""
```

## License

Apache 2.0 - See LICENSE for more information.

<!-- BEGIN_TF_DOCS -->
## Providers

| Name | Version |
|------|---------|
| <a name="provider_github"></a> [github](#provider\_github) | >= 5.0 |
| <a name="provider_google"></a> [google](#provider\_google) | >= 3.53 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.0 |

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5 |
| <a name="requirement_github"></a> [github](#requirement\_github) | >= 5.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 3.53 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_gcp_existing_service_account_account_id"></a> [gcp\_existing\_service\_account\_account\_id](#input\_gcp\_existing\_service\_account\_account\_id) | The account\_id of an existing service account to use for GitHub WIF. If not provided, a new service account will be created. | `string` | `null` | no |
| <a name="input_gcp_project_id"></a> [gcp\_project\_id](#input\_gcp\_project\_id) | The ID of the project in which to provision resources. | `string` | n/a | yes |
| <a name="input_gcp_workload_identity_pool_provider_attribute_mapping"></a> [gcp\_workload\_identity\_pool\_provider\_attribute\_mapping](#input\_gcp\_workload\_identity\_pool\_provider\_attribute\_mapping) | A map of attribute mappings for the GCP Workload Identity Federation provider. This allows you to customize how attributes are mapped from GitHub to GCP. | `map(string)` | <pre>{<br/>  "attribute.actor": "assertion.actor",<br/>  "attribute.actor_id": "assertion.actor_id",<br/>  "attribute.enterprise": "assertion.enterprise",<br/>  "attribute.enterprise_id": "assertion.enterprise_id",<br/>  "attribute.environment": "assertion.environment",<br/>  "attribute.event_name": "assertion.event_name",<br/>  "attribute.job_workflow_ref": "assertion.job_workflow_ref",<br/>  "attribute.ref": "assertion.ref",<br/>  "attribute.ref_type": "assertion.ref_type",<br/>  "attribute.repository": "assertion.repository",<br/>  "attribute.repository_id": "assertion.repository_id",<br/>  "attribute.repository_owner": "assertion.repository_owner",<br/>  "attribute.repository_owner_id": "assertion.repository_owner_id",<br/>  "attribute.repository_visibility": "assertion.repository_visibility",<br/>  "attribute.runner_environment": "assertion.runner_environment",<br/>  "attribute.workflow": "assertion.workflow",<br/>  "attribute.workflow_ref": "assertion.workflow_ref",<br/>  "google.subject": "assertion.actor+\"::run:\"+assertion.run_id+\"::attempt:\"+assertion.run_attempt"<br/>}</pre> | no |
| <a name="input_github_attribute_condition_additional"></a> [github\_attribute\_condition\_additional](#input\_github\_attribute\_condition\_additional) | Additional CEL expression to AND with the generated attribute condition. Use this to add extra restrictions like branch filters, environment filters, etc. | `string` | `null` | no |
| <a name="input_github_create_oidc_variables"></a> [github\_create\_oidc\_variables](#input\_github\_create\_oidc\_variables) | Whether to create GitHub Actions variables for the WIF configuration. Set to false if you want to manage variables manually. | `bool` | `true` | no |
| <a name="input_github_enterprise_id"></a> [github\_enterprise\_id](#input\_github\_enterprise\_id) | The GitHub Enterprise ID to allow access from. Only available with GitHub Enterprise Cloud. | `string` | `null` | no |
| <a name="input_github_gcp_wif_pool_variable_name"></a> [github\_gcp\_wif\_pool\_variable\_name](#input\_github\_gcp\_wif\_pool\_variable\_name) | The name of the GitHub Actions variable to store the GCP WIF pool name. | `string` | `"GCP_WIF_POOL"` | no |
| <a name="input_github_gcp_wif_project_id_variable_name"></a> [github\_gcp\_wif\_project\_id\_variable\_name](#input\_github\_gcp\_wif\_project\_id\_variable\_name) | The name of the GitHub Actions variable to store the GCP project ID for WIF. | `string` | `"GCP_WIF_PROJECT_ID"` | no |
| <a name="input_github_gcp_wif_provider_variable_name"></a> [github\_gcp\_wif\_provider\_variable\_name](#input\_github\_gcp\_wif\_provider\_variable\_name) | The name of the GitHub Actions variable to store the GCP WIF provider name. | `string` | `"GCP_WIF_PROVIDER"` | no |
| <a name="input_github_gcp_wif_service_account_email_variable_name"></a> [github\_gcp\_wif\_service\_account\_email\_variable\_name](#input\_github\_gcp\_wif\_service\_account\_email\_variable\_name) | The name of the GitHub Actions variable to store the GCP WIF service account email. | `string` | `"GCP_WIF_SERVICE_ACCOUNT_EMAIL"` | no |
| <a name="input_github_gcp_wif_workload_identity_provider_variable_name"></a> [github\_gcp\_wif\_workload\_identity\_provider\_variable\_name](#input\_github\_gcp\_wif\_workload\_identity\_provider\_variable\_name) | The name of the GitHub Actions variable to store the full workload identity provider path (used by google-github-actions/auth). | `string` | `"GCP_WORKLOAD_IDENTITY_PROVIDER"` | no |
| <a name="input_github_organization_id"></a> [github\_organization\_id](#input\_github\_organization\_id) | The GitHub organization ID to allow access from. Use this for organization-level access. | `number` | `null` | no |
| <a name="input_github_organization_variables_selected_repository_ids"></a> [github\_organization\_variables\_selected\_repository\_ids](#input\_github\_organization\_variables\_selected\_repository\_ids) | List of repository IDs that can access organization-level variables. Only used when github\_organization\_variables\_visibility is 'selected'. | `list(number)` | `[]` | no |
| <a name="input_github_organization_variables_visibility"></a> [github\_organization\_variables\_visibility](#input\_github\_organization\_variables\_visibility) | Visibility level for organization-level variables. Valid values: all, private, selected. | `string` | `"all"` | no |
| <a name="input_github_repository_ids"></a> [github\_repository\_ids](#input\_github\_repository\_ids) | The GitHub repository IDs to allow access from. Use this for repository-level access. | `list(number)` | `[]` | no |
| <a name="input_github_repository_names"></a> [github\_repository\_names](#input\_github\_repository\_names) | The GitHub repository names (in format 'owner/repo') to allow access from. Use this for repository-level access when you prefer to use repository names instead of IDs. | `list(string)` | `[]` | no |
| <a name="input_github_token_issuer_url"></a> [github\_token\_issuer\_url](#input\_github\_token\_issuer\_url) | The URL of the GitHub OIDC token issuer. | `string` | `"https://token.actions.githubusercontent.com"` | no |
| <a name="input_github_variables_additional"></a> [github\_variables\_additional](#input\_github\_variables\_additional) | Additional GitHub Actions variables to create. This should be a map where the key is the variable name and the value is the variable value. | `map(string)` | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | The name to use for all resources created by this module. | `string` | n/a | yes |
| <a name="input_secret_gcp_project_id"></a> [secret\_gcp\_project\_id](#input\_secret\_gcp\_project\_id) | The GCP project ID where secrets will be created. If not provided, defaults to `var.gcp_project_id`. | `string` | `null` | no |
| <a name="input_secret_names"></a> [secret\_names](#input\_secret\_names) | List of secret names to create and grant access to. | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_attribute_condition"></a> [attribute\_condition](#output\_attribute\_condition) | The attribute condition used for the Workload Identity Provider. |
| <a name="output_github_actions_variables"></a> [github\_actions\_variables](#output\_github\_actions\_variables) | The GitHub Actions variables created by this module. |
| <a name="output_principal_set"></a> [principal\_set](#output\_principal\_set) | The principal sets string used for IAM bindings. |
| <a name="output_secret_created"></a> [secret\_created](#output\_secret\_created) | The names and IDs of the secrets created by this module. |
| <a name="output_secret_gcp_project_id"></a> [secret\_gcp\_project\_id](#output\_secret\_gcp\_project\_id) | The GCP project ID where secrets are stored. |
| <a name="output_secret_ids"></a> [secret\_ids](#output\_secret\_ids) | Map of original secret names to their Secret Manager secret IDs. |
| <a name="output_secret_names"></a> [secret\_names](#output\_secret\_names) | Map of original secret names to their formatted names. |
| <a name="output_service_account_email"></a> [service\_account\_email](#output\_service\_account\_email) | The email of the Service Account used. |
| <a name="output_workload_identity_pool_id"></a> [workload\_identity\_pool\_id](#output\_workload\_identity\_pool\_id) | The ID of the Workload Identity Pool. |
| <a name="output_workload_identity_pool_name"></a> [workload\_identity\_pool\_name](#output\_workload\_identity\_pool\_name) | The full name of the Workload Identity Pool. |
| <a name="output_workload_identity_pool_provider_id"></a> [workload\_identity\_pool\_provider\_id](#output\_workload\_identity\_pool\_provider\_id) | The ID of the Workload Identity Provider. |
| <a name="output_workload_identity_provider"></a> [workload\_identity\_provider](#output\_workload\_identity\_provider) | The full resource path of the Workload Identity Provider (for use with google-github-actions/auth). |

## Resources

| Name | Type |
|------|------|
| [github_actions_organization_variable.additional](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_organization_variable) | resource |
| [github_actions_organization_variable.gcp_wif_pool](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_organization_variable) | resource |
| [github_actions_organization_variable.gcp_wif_project_number](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_organization_variable) | resource |
| [github_actions_organization_variable.gcp_wif_provider](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_organization_variable) | resource |
| [github_actions_organization_variable.gcp_wif_service_account_email](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_organization_variable) | resource |
| [github_actions_organization_variable.gcp_workload_identity_provider](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_organization_variable) | resource |
| [github_actions_variable.additional](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_variable) | resource |
| [github_actions_variable.gcp_wif_pool](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_variable) | resource |
| [github_actions_variable.gcp_wif_project_number](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_variable) | resource |
| [github_actions_variable.gcp_wif_provider](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_variable) | resource |
| [github_actions_variable.gcp_wif_service_account_email](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_variable) | resource |
| [github_actions_variable.gcp_workload_identity_provider](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_variable) | resource |
| [google_iam_workload_identity_pool.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iam_workload_identity_pool) | resource |
| [google_iam_workload_identity_pool_provider.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iam_workload_identity_pool_provider) | resource |
| [google_secret_manager_secret.secrets](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret) | resource |
| [google_secret_manager_secret_iam_member.secrets](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_iam_member) | resource |
| [google_service_account.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_service_account_iam_member.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account_iam_member) | resource |
| [random_id.suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [google_project.project](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/project) | data source |
| [google_service_account.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/service_account) | data source |

## Modules

No modules.

<!-- END_TF_DOCS -->
