# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres
to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2026-05-20

[Compare with previous version](https://github.com/sparkfabrik/terraform-google-gcp-github-wif/compare/0.2.0...1.0.0)

### :warning: Breaking change

The workload identity pool and provider IDs now place the random hex suffix at the **beginning** of the identifier (e.g., `pool-a1b2c3d4-myname` instead of `pool-myname-a1b2c3d4`). This prevents the random part from being truncated when `var.name` is long, which could cause ID collisions.

**Upgrading will destroy and recreate the pool and provider resources.** These are pure configuration resources (identity federation settings), no data loss is involved. The service account itself is **not affected**, though its WIF IAM binding (`google_service_account_iam_member`) is recreated because it references the pool name.

See [UPGRADING.md](UPGRADING.md) for details.

### Changed

- Move random hex prefix before `var.name` in pool and provider IDs to avoid collisions caused by truncation.

## [0.2.0] - 2026-03-04

[Compare with previous version](https://github.com/sparkfabrik/terraform-google-gcp-github-wif/compare/0.1.1...0.2.0)

- Remove `github_repository_ids` variable and all related logic.
- Fetch repository IDs dynamically using the GitHub provider based on the provided `github_repository_names`.
- Update the logic used in federation using repository names to reference the dynamically fetched repository IDs instead of relying on names directly.

## [0.1.1] - 2026-03-04

[Compare with previous version](https://github.com/sparkfabrik/terraform-google-gcp-github-wif/compare/0.1.0...0.1.1)

- Fix a bug in the validation logic for `github_organization_id`. The issue was with how Terraform evaluates the `>` operator when the value is `null`, because in Terraform `null > 0` does not return `false`.

## [0.1.0] - 2026-03-02

- First release.
