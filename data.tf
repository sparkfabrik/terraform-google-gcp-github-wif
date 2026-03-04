data "github_repository" "repositories" {
  for_each = toset(var.github_repository_names)

  full_name = each.value
}
