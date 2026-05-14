# Automatically wires the GitHub Actions CI workflow on github_repo so it can:
#   1. Authenticate to GCP keylessly via Workload Identity Federation (WIF)
#   2. Push image-tag commits to the GitOps repo via GITOPS_PAT
#
# All values are computed directly from other resources in this module —
# no copy-paste from terraform output is ever needed.
#
# WIF_PROVIDER, GCP_SERVICE_ACCOUNT and GCP_PROJECT_ID are stored as SECRETS
# (not variables) so GitHub masks them as *** in all public workflow logs,
# preventing project ID, project number, and service account leakage.
#
# Skip entirely when github_repo or github_token is not provided.

locals {
  github_ci_repo    = var.github_repo != "" ? split("/", var.github_repo)[1] : ""
  github_ci_enabled = var.github_repo != "" && var.github_token != ""
}

provider "github" {
  owner = var.github_repo != "" ? split("/", var.github_repo)[0] : ""
  # When github_token is unset in tfvars, omit this field so the provider can use
  # the GITHUB_TOKEN environment variable (same PAT) for destroy/apply without
  # duplicating secrets in a file.
  token = var.github_token != "" ? var.github_token : null
}

# ── Actions Secrets — all GCP references stored as secrets so they are
#    masked in public logs (${{ secrets.NAME }} syntax in the workflow) ─────────

resource "github_actions_secret" "wif_provider" {
  count = local.github_ci_enabled && var.github_repo != "" ? 1 : 0

  repository      = local.github_ci_repo
  secret_name     = "WIF_PROVIDER"
  plaintext_value = google_iam_workload_identity_pool_provider.github[0].name
}

resource "github_actions_secret" "gcp_service_account" {
  count = local.github_ci_enabled && var.github_repo != "" ? 1 : 0

  repository      = local.github_ci_repo
  secret_name     = "GCP_SERVICE_ACCOUNT"
  plaintext_value = google_service_account.ci[0].email
}

resource "github_actions_secret" "gcp_project_id" {
  count = local.github_ci_enabled ? 1 : 0

  repository      = local.github_ci_repo
  secret_name     = "GCP_PROJECT_ID"
  plaintext_value = var.gcp_project_id
}

resource "github_actions_secret" "registry" {
  count = local.github_ci_enabled ? 1 : 0

  repository      = local.github_ci_repo
  secret_name     = "REGISTRY"
  plaintext_value = "${var.gcp_region}-docker.pkg.dev"
}

resource "github_actions_secret" "app_url" {
  count = local.github_ci_enabled && var.app_url != "" ? 1 : 0

  repository      = local.github_ci_repo
  secret_name     = "APP_URL"
  plaintext_value = var.app_url
}

resource "github_actions_secret" "gitops_pat" {
  count = local.github_ci_enabled && var.github_gitops_pat != "" ? 1 : 0

  repository      = local.github_ci_repo
  secret_name     = "GITOPS_PAT"
  plaintext_value = var.github_gitops_pat
}

resource "github_actions_secret" "gcp_cluster_name" {
  count = local.github_ci_enabled ? 1 : 0

  repository      = local.github_ci_repo
  secret_name     = "GCP_CLUSTER_NAME"
  plaintext_value = module.gke.name
}

resource "github_actions_secret" "gcp_region" {
  count = local.github_ci_enabled ? 1 : 0

  repository      = local.github_ci_repo
  secret_name     = "GCP_REGION"
  plaintext_value = var.gcp_region
}
