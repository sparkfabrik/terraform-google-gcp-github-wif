# Example GitHub Actions Workflow using WIF

This example shows how to use Workload Identity Federation in your GitHub Actions workflow after applying this Terraform module.

## Workflow Example

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

## Environment-Specific Access

If you want to restrict access to specific environments, you can add an attribute condition:

```hcl
module "github_wif" {
  source = "github.com/sparkfabrik/terraform-google-gcp-github-wif"

  name           = "prod-deploy"
  gcp_project_id = "my-project"

  github_repository_names = ["my-org/my-repo"]
  
  # Only allow from production environment
  github_attribute_condition_additional = "attribute.environment==\"production\""
}
```

Then in your workflow:

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production  # This sets the environment claim in the OIDC token
    steps:
      - uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: ${{ vars.GCP_WORKLOAD_IDENTITY_PROVIDER }}
          service_account: ${{ vars.GCP_WIF_SERVICE_ACCOUNT_EMAIL }}
```

## Branch-Specific Access

To restrict access to specific branches:

```hcl
module "github_wif" {
  source = "github.com/sparkfabrik/terraform-google-gcp-github-wif"

  name           = "main-branch-deploy"
  gcp_project_id = "my-project"

  github_repository_names = ["my-org/my-repo"]
  
  # Only allow from main branch
  github_attribute_condition_additional = "attribute.ref==\"refs/heads/main\""
}
```
