# Terraform Google GCP GitHub WIF Module

## Project Overview

Terraform module that configures Google Cloud Workload Identity Federation (WIF) for GitHub Actions, enabling keyless authentication from GitHub workflows to GCP. Supports repository-level, organization-level, and enterprise-level access with CEL-based attribute conditions.

**Tech stack:** Terraform (HCL), GCP (Workload Identity, IAM, Secret Manager), GitHub provider. No application code — pure infrastructure module.

## Project Context

Read [`spec/SPEC.md`](spec/SPEC.md) for module design decisions, architecture rationale, access levels, and security patterns. Use the spec as reference when making design-level changes. Update `spec/SPEC.md` when introducing new behavior or configuration that affects the module's design.

## Setup

This is a Terraform module — it is not deployed standalone. Development tasks (linting, docs generation, security scanning) run via Docker through `make` targets. No local Terraform, tflint, or tfsec installation required.

```bash
make lint           # Run tflint via Docker
make tfsec          # Run tfsec security scan via Docker
make generate-docs  # Lint + regenerate README.md via terraform-docs
```

Running `make` without a target defaults to `lint`.

## Key Conventions

- All tooling runs in Docker — never install tflint, tfsec, or terraform-docs locally.
- The `examples/` directory contains usage examples and `test.tfvars` used by the linter.
- The `examples/test.tfvars` file must be kept in sync with `variables.tf` — if you add or remove a variable, update `test.tfvars` accordingly.
- README.md contains auto-generated sections between `<!-- BEGIN_TF_DOCS -->` and `<!-- END_TF_DOCS -->` markers. Never edit content inside these markers manually.

## Code Style

- **Terraform (HCL):** TFLint with 9 rules enabled (`.tflint.hcl`):
  - `terraform_naming_convention` — snake_case for all names
  - `terraform_unused_declarations` — no unused variables/locals
  - `terraform_typed_variables` — all variables must have types
  - `terraform_standard_module_structure` — standard file layout (`main.tf`, `variables.tf`, `outputs.tf`)
  - `terraform_comment_syntax` — use `#` comments, not `//`
  - `terraform_deprecated_index` — no legacy index syntax
  - `terraform_deprecated_interpolation` — no legacy interpolation syntax
  - `terraform_module_pinned_source` — pin module sources
  - `terraform_unused_required_providers` — no unused provider declarations
- Run `make lint` before committing.

## Changelog

This project uses [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format with [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

**On every change**, update `CHANGELOG.md`:

- Add entries under the `## [Unreleased]` section.
- Use imperative mood (e.g., "Add support for...", "Fix validation of...").
- Group entries by type when multiple changes are present: `Added`, `Changed`, `Fixed`, `Removed`.
- Only create a new version section when the user explicitly asks to cut a release.

## Documentation

After any change to `.tf` files, run:

```bash
make generate-docs
```

This regenerates the auto-generated sections of `README.md` (providers, requirements, inputs, outputs, resources). The target depends on `lint`, so linting runs first.

Always format Markdown files after creating or modifying them.

## Git Workflow

### Commits

Follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/):

```text
<type>(<scope>): <description>
```

**Types:** `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `ci`, `perf`, `build`.
**Scope** is optional — use the affected component (e.g., `wif`, `secrets`, `github`).

Keep the description lowercase, imperative, no period.

### Branching

- Branch naming: `feat/`, `fix/`, `chore/`, `test/`, `docs/` prefix + kebab-case description (e.g., `feat/add-custom-audiences`, `fix/org-id-validation`).
- Never push directly to `main`. Always create a feature branch and open a pull request.

### Rebasing

- Always rebase onto `main` before pushing. No merge commits.
- Use `--force-with-lease` (never `--force`) after rebasing.

## CI/CD

The project uses GitHub Actions with a single workflow (`.github/workflows/tflint.yml`):

- **Triggers:** push to `main`, pull requests (opened/synchronize)
- **Job:** `tflint` — runs TFLint on `ubuntu-latest` with plugin caching

## Command Safety

### Safe (run autonomously)

- `make lint` — runs tflint, read-only analysis
- `make tfsec` — runs tfsec, read-only security scan
- `make generate-docs` — regenerates README.md (file change, but safe and expected)
- `git status`, `git log`, `git diff`

### Dangerous (ask user first)

- `git push`
- Any change to `versions.tf` provider constraints
- Any change to `.github/workflows/`

### Destructive (never run)

- `rm -rf`
- `git push --force`
- `terraform destroy`
- `terraform apply`

## Important Rules

- Never install tflint, tfsec, or terraform-docs locally — all tooling runs in Docker via `make`.
- Run `make lint` before committing.
- Run `make generate-docs` after any `.tf` file change to keep README.md in sync.
- Always format Markdown files after creating or modifying them.
- Update `CHANGELOG.md` under `## [Unreleased]` on every change.
- Never edit content between `<!-- BEGIN_TF_DOCS -->` and `<!-- END_TF_DOCS -->` in README.md.
- Keep `examples/test.tfvars` in sync with `variables.tf`.
- Follow conventional commits.
- Never push directly to `main`.
- Read `spec/SPEC.md` before making design-level changes.
- Update `spec/SPEC.md` when introducing new behavior or configuration.
