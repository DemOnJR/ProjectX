# GitHub Actions → Vault JWT/OIDC (no long-lived GitHub PAT for Vault).
# Workflows use hashicorp/vault-action with method=jwt; configure repo Actions **secrets**
#   VAULT_ADDR, VAULT_JWT_PATH, VAULT_JWT_ROLE, VAULT_CI_SECRET_PATH
# (see ProjectX .github/workflows).

resource "vault_jwt_auth_backend" "github_actions" {
  path               = var.vault_github_jwt_mount_path
  oidc_discovery_url = "https://token.actions.githubusercontent.com"
  bound_issuer       = "https://token.actions.githubusercontent.com"
}

resource "vault_policy" "github_actions_ci_read" {
  name = "github-actions-ci-projectx-read"

  policy = <<-EOT
    path "${var.vault_kv_mount}/data/${var.vault_ci_secret_kv_path}" {
      capabilities = ["read"]
    }
  EOT
}

resource "vault_jwt_auth_backend_role" "github_actions_ci" {
  backend        = vault_jwt_auth_backend.github_actions.path
  role_name      = var.vault_github_jwt_role_name
  role_type      = "jwt"
  user_claim     = "repository"
  token_policies = [vault_policy.github_actions_ci_read.name]
  token_ttl      = 600

  bound_claims = {
    repository = var.github_repository_full
  }
}
