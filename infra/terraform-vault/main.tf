# Reads the live GKE cluster to extract its API endpoint and CA certificate.
# After the cluster is deleted, set skip_live_gke_cluster_lookup = true so refresh/destroy does not call Google.
data "google_container_cluster" "gke" {
  count = var.skip_live_gke_cluster_lookup ? 0 : 1

  name     = var.cluster_name
  location = var.gcp_region
  project  = var.gcp_project_id
}

locals {
  k8s_host = var.skip_live_gke_cluster_lookup ? "https://127.0.0.1" : "https://${data.google_container_cluster.gke[0].endpoint}"
}

# ── Vault: Kubernetes auth backend ────────────────────────────────────────────

resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
  path = var.vault_kubernetes_auth_path
}

resource "vault_kubernetes_auth_backend_config" "gke" {
  backend            = vault_auth_backend.kubernetes.path
  kubernetes_host    = local.k8s_host
  kubernetes_ca_cert = var.skip_live_gke_cluster_lookup ? null : base64decode(data.google_container_cluster.gke[0].master_auth[0].cluster_ca_certificate)
}

# ── Vault: policy + role for the ProjectX app ─────────────────────────────────

resource "vault_policy" "projectx_api" {
  name = "projectx-api"

  policy = <<-EOT
    path "${var.vault_kv_mount}/data/${var.vault_kv_projectx_path}" {
      capabilities = ["read"]
    }
  EOT
}

resource "vault_kubernetes_auth_backend_role" "projectx_api" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "projectx-api"
  bound_service_account_names      = ["projectx-vault-auth"]
  bound_service_account_namespaces = ["projectx"]
  token_policies                   = [vault_policy.projectx_api.name]
  token_ttl                        = 3600

  depends_on = [vault_kubernetes_auth_backend_config.gke]
}

# ── Vault: secrets ─────────────────────────────────────────────────────────────
# Both Cloudflare tunnel tokens are written here.
# Leave the variable empty to skip writing (if you manage it manually in Vault).

resource "vault_kv_secret_v2" "projectx_cloudflared" {
  count = var.cloudflare_projectx_token != "" ? 1 : 0

  mount = var.vault_kv_mount
  name  = var.vault_kv_projectx_path

  data_json = jsonencode({
    token = var.cloudflare_projectx_token
  })
}

resource "vault_kv_secret_v2" "argocd_cloudflared" {
  count = var.cloudflare_argocd_token != "" ? 1 : 0

  mount = var.vault_kv_mount
  name  = var.vault_kv_argocd_path

  data_json = jsonencode({
    token = var.cloudflare_argocd_token
  })
}
