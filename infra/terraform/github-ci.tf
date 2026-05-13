# Automatically wires the GitHub Actions CI workflow on github_repo so it can:
#   1. Authenticate to GCP keylessly via Workload Identity Federation (WIF)
#   2. Push image-tag commits to the GitOps repo via GITOPS_PAT
#
# All values are computed directly from other resources in this module —
# no copy-paste from terraform output is ever needed.
#
# Skip entirely when github_repo or github_token is not provided.

locals {
  github_ci_repo    = var.github_repo != "" ? split("/", var.github_repo)[1] : ""
  github_ci_enabled = var.github_repo != "" && var.github_token != ""
}

provider "github" {
  token = var.github_token
  owner = var.github_repo != "" ? split("/", var.github_repo)[0] : ""
}

# ── Actions Variables (non-sensitive, visible in workflow logs) ───────────────

resource "github_actions_variable" "wif_provider" {
  count = local.github_ci_enabled && var.github_repo != "" ? 1 : 0

  repository    = local.github_ci_repo
  variable_name = "WIF_PROVIDER"
  value         = google_iam_workload_identity_pool_provider.github[0].name
}

resource "github_actions_variable" "gcp_service_account" {
  count = local.github_ci_enabled && var.github_repo != "" ? 1 : 0

  repository    = local.github_ci_repo
  variable_name = "GCP_SERVICE_ACCOUNT"
  value         = google_service_account.ci[0].email
}

resource "github_actions_variable" "gcp_project_id" {
  count = local.github_ci_enabled ? 1 : 0

  repository    = local.github_ci_repo
  variable_name = "GCP_PROJECT_ID"
  value         = var.gcp_project_id
}

# ── Actions Secret (sensitive — injected as ${{ secrets.GITOPS_PAT }}) ────────

resource "github_actions_secret" "gitops_pat" {
  count = local.github_ci_enabled && var.github_gitops_pat != "" ? 1 : 0

  repository      = local.github_ci_repo
  secret_name     = "GITOPS_PAT"
  plaintext_value = var.github_gitops_pat
}
