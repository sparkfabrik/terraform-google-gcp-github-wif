# Upgrading

## 0.2.x to 1.0.0

### What changes

The workload identity pool and provider IDs now place the random hex before `var.name` instead of after it. This fixes potential ID collisions when `var.name` is long enough to cause the random suffix to be truncated.

| Resource | Old ID format           | New ID format           |
| -------- | ----------------------- | ----------------------- |
| Pool     | `pool-{name}-{hex}`     | `pool-{hex}-{name}`     |
| Provider | `provider-{name}-{hex}` | `provider-{hex}-{name}` |

### What happens on `terraform apply`

Terraform will **destroy and recreate** the following resources per module instance:

- `google_iam_workload_identity_pool` (new pool ID)
- `google_iam_workload_identity_pool_provider` (new provider ID)
- `google_service_account_iam_member` (references the pool name in its `member` attribute)
- GitHub Actions variables whose values embed pool/provider IDs (e.g., `GCP_WORKLOAD_IDENTITY_PROVIDER`)

All of these are configuration-only resources (no data is stored in them).

**Not affected:** service account, its email address, and any IAM roles granted to the service account on other GCP resources.

### Steps

1. Run `terraform plan` and verify that only the resources listed above are being replaced. The service account itself must **not** appear in the plan.
2. Schedule a short maintenance window. GitHub Actions workflows using WIF authentication will fail between the destroy and recreate (typically seconds).
3. Run `terraform apply`.
