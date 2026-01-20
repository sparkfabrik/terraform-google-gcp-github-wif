# GitHub WIF Module Specification

## Purpose

This Terraform module sets up Google Cloud Workload Identity Federation (WIF) to allow GitHub Actions workflows to authenticate with GCP without static service account keys.

## Core Concepts

### Access Levels
- **Repository**: Limit access to specific GitHub repositories
- **Organization**: Allow any repository in a GitHub organization  
- **Enterprise**: Allow any repository in a GitHub Enterprise (Enterprise Cloud only)

### How It Works
1. Creates a GCP Workload Identity Pool and OIDC Provider
2. Configures attribute conditions based on GitHub OIDC token claims
3. Creates/uses a GCP service account for GitHub Actions to impersonate
4. Optionally creates GitHub Actions variables with WIF configuration
5. Optionally creates GCP Secret Manager secrets with appropriate IAM bindings

## Key Design Decisions

### Variables Only, No Secrets
The module creates GitHub Actions **variables** (non-sensitive), not secrets. WIF configuration values (project IDs, pool names, service account emails) are public identifiers - security comes from OIDC token validation, not hiding these values.

### Enterprise Support Limitation
GitHub Enterprise Cloud provides `enterprise` and `enterprise_id` OIDC claims. The module supports these for WIF attribute conditions on the GCP side, but the GitHub Terraform provider doesn't support enterprise-level variables/secrets. Users must configure variables at org/repo level.

### Organization Variable Visibility
Organization-level variables support three visibility modes matching GitHub's options:
- `all` - All repositories can access
- `private` - Only private repositories can access  
- `selected` - Only specified repositories can access

### Attribute Mapping Strategy
The module maps all standard GitHub OIDC claims to GCP attributes by default, including Enterprise Cloud claims. The `google.subject` field uses `repository + run_id + run_attempt` to ensure uniqueness per token.

### Secret Manager Integration
The module creates empty Secret Manager secrets and grants the WIF service account `secretAccessor` role. Users add secret values manually to keep sensitive data out of Terraform state.

## Module Behavior

### Attribute Conditions
The module builds CEL expressions to restrict which GitHub workflows can authenticate:
- Combines access levels with OR logic (repo OR org OR enterprise)
- Users can add custom conditions with AND logic (e.g., branch restrictions)
- Conditions are evaluated during OIDC token exchange

### GitHub Actions Variables
When enabled, the module creates these variables in GitHub:
- `GCP_WIF_PROJECT_NUMBER` - For internal WIF use
- `GCP_WIF_POOL` - Pool identifier
- `GCP_WIF_PROVIDER` - Provider identifier  
- `GCP_WIF_SERVICE_ACCOUNT_EMAIL` - Service account to impersonate
- `GCP_WORKLOAD_IDENTITY_PROVIDER` - Full path for google-github-actions/auth action

Variables are created at repository or organization level based on configuration.

### Service Account Management
The module either creates a new service account or uses an existing one. The service account:
- Gets workloadIdentityUser role on itself for token exchange
- Gets secretAccessor role on created Secret Manager secrets
- Can be granted additional roles externally for workload permissions

## Security Patterns

### Principle of Least Privilege
Use repository-level access over organization/enterprise when possible. Limit access to specific repositories that need GCP authentication.

### Branch and Environment Protection
Add attribute conditions to restrict access:
- Specific branches (e.g., `main` only)
- Specific environments (e.g., `production` only)
- Specific event types (e.g., `push` events only)
- GitHub-hosted runners only

### Secret Management
- Store sensitive values in GCP Secret Manager, not GitHub secrets
- WIF service account reads secrets during workflow execution
- Secrets stay in GCP and don't appear in GitHub logs or artifacts

## Comparison with GitLab Module

The GitHub module follows the same patterns as the GitLab WIF module but adapted for GitHub's different architecture:
- Access levels map to GitHub's structure (repo/org/enterprise vs project/group)
- GitHub Actions variables lack description/protected/masked fields that GitLab has
- Both modules use the same Secret Manager integration approach

## References

- [GitHub OIDC Documentation](https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
- [GCP Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation)
- [google-github-actions/auth Action](https://github.com/google-github-actions/auth)
