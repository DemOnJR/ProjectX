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
