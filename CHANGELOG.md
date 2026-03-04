# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres
to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
