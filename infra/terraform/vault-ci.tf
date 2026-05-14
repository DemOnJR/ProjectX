# Writes GitHub Actions CI material to Vault KV v2 so workflows authenticate with
# GitHub OIDC → Vault JWT (see infra/terraform-vault/github-jwt.tf) and read this path.
#
# Requires: export VAULT_TOKEN=... before terraform apply when github_repo is set.

locals {
  vault_ci_kv_enabled = var.write_ci_secrets_to_vault && var.github_repo != ""
}

resource "vault_kv_secret_v2" "github_actions_ci" {
  count = local.vault_ci_kv_enabled ? 1 : 0

  mount = var.vault_ci_kv_mount
  name  = var.vault_ci_secret_name

  data_json = jsonencode({
    wif_provider        = google_iam_workload_identity_pool_provider.github[0].name
    gcp_service_account = google_service_account.ci[0].email
    gcp_project_id      = var.gcp_project_id
    registry            = "${var.gcp_region}-docker.pkg.dev"
    gitops_pat          = var.github_gitops_pat
    app_url             = var.app_url
    gcp_cluster_name    = module.gke.name
    gcp_region          = var.gcp_region
  })

  depends_on = [
    module.gke,
    google_iam_workload_identity_pool_provider.github,
    google_service_account.ci,
  ]
}
