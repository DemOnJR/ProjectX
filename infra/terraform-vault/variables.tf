variable "gcp_project_id" {
  description = "Google Cloud project ID."
  type        = string
}

variable "gcp_region" {
  description = "Region where the GKE cluster lives."
  type        = string
  default     = "europe-west3"
}

variable "cluster_name" {
  description = "GKE cluster name."
  type        = string
  default     = "projectx-gke"
}

variable "skip_live_gke_cluster_lookup" {
  description = "When true, Terraform does not call data.google_container_cluster (use after the cluster is deleted but Vault resources still exist in state). Required for terraform destroy/plan when the cluster no longer exists. Uses a placeholder kubernetes_host and omits CA cert for the Vault Kubernetes auth config resource so refresh can succeed."
  type        = bool
  default     = false
}

variable "vault_address" {
  description = "Vault server URL."
  type        = string
  default     = "https://vault.pbcv.dev"
}

variable "vault_kubernetes_auth_path" {
  description = "Mount path for the Vault Kubernetes auth method."
  type        = string
  default     = "kubernetes"
}

variable "vault_kv_mount" {
  description = "KV v2 secrets engine mount name in Vault."
  type        = string
  default     = "kv"
}

variable "vault_kv_projectx_path" {
  description = "KV path for the ProjectX app secrets (Cloudflare tunnel token)."
  type        = string
  default     = "projectx"
}

variable "vault_kv_argocd_path" {
  description = "KV path for the Argo CD secrets (Cloudflare tunnel token)."
  type        = string
  default     = "argocd"
}

variable "github_repository_full" {
  description = "GitHub repo allowed to use Vault JWT auth for CI (owner/repo). Must match the Actions workflow repository."
  type        = string
  default     = "DemOnJR/ProjectX"
}

variable "vault_github_jwt_mount_path" {
  description = "Mount path for the Vault JWT auth method used by GitHub Actions."
  type        = string
  default     = "jwt-github"
}

variable "vault_github_jwt_role_name" {
  description = "Vault JWT role name passed to vault-action as role=."
  type        = string
  default     = "github-ci-projectx"
}

variable "vault_ci_secret_kv_path" {
  description = "KV v2 secret path without mount; must match main Terraform vault_ci_secret_name (e.g. ci/projectx)."
  type        = string
  default     = "ci/projectx"
}

variable "cloudflare_projectx_token" {
  description = "Cloudflare tunnel token for the ProjectX API (projectx.pbcv.dev). Written to Vault at kv/projectx."
  type        = string
  sensitive   = true
  default     = ""
}

variable "cloudflare_argocd_token" {
  description = "Cloudflare tunnel token for Argo CD (argocd.pbcv.dev). Written to Vault at kv/argocd."
  type        = string
  sensitive   = true
  default     = ""
}
