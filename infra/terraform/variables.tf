variable "gcp_project_id" {
  description = "Google Cloud project ID."
  type        = string
}

variable "gcp_region" {
  description = "Google Cloud region for the GKE cluster."
  type        = string
  default     = "europe-west3"
}

variable "manage_project_services" {
  description = "Whether Terraform should enable required Google Cloud APIs. Set to false if your account cannot manage Service Usage APIs."
  type        = bool
  default     = true
}

variable "gcp_zones" {
  description = "Zones used by the node pool."
  type        = list(string)
  default     = ["europe-west3-a", "europe-west3-b"]
}

variable "network_name" {
  description = "VPC network name."
  type        = string
  default     = "projectx-vpc"
}

variable "subnet_name" {
  description = "GKE subnet name."
  type        = string
  default     = "projectx-gke-subnet"
}

variable "subnet_cidr" {
  description = "Primary subnet CIDR."
  type        = string
  default     = "10.10.0.0/20"
}

variable "pods_cidr" {
  description = "Secondary CIDR for GKE pods."
  type        = string
  default     = "10.20.0.0/16"
}

variable "services_cidr" {
  description = "Secondary CIDR for GKE services."
  type        = string
  default     = "10.30.0.0/20"
}

variable "cluster_name" {
  description = "GKE cluster name."
  type        = string
  default     = "projectx-gke"
}

variable "node_pool_name" {
  description = "GKE node pool name."
  type        = string
  default     = "projectx-pool"
}

variable "node_machine_type" {
  description = "Machine type for GKE worker nodes."
  type        = string
  default     = "e2-medium"
}

variable "node_min_count" {
  description = "Minimum nodes per zone."
  type        = number
  default     = 1
}

variable "node_max_count" {
  description = "Maximum nodes per zone."
  type        = number
  default     = 4
}

variable "extra_gke_master_authorized_networks" {
  description = "Extra CIDRs allowed to reach the GKE control plane (in addition to the Terraform client IP from data.http). Use stable /32s (office, VPN) so plan/destroy still works if your home IP changes and master_authorized_networks would otherwise lock you out (Kubernetes API Unauthorized)."
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []
}

variable "artifact_registry_repository_id" {
  description = "Artifact Registry Docker repository ID."
  type        = string
  default     = "projectx"
}

variable "argocd_chart_version" {
  description = "Argo CD Helm chart version."
  type        = string
  default     = "7.7.15"
}

variable "install_vault_secrets_operator" {
  description = "Whether Terraform should install HashiCorp Vault Secrets Operator into the cluster."
  type        = bool
  default     = true
}

variable "vault_secrets_operator_chart_version" {
  description = "HashiCorp Vault Secrets Operator Helm chart version."
  type        = string
  default     = "0.9.1"
}

variable "gitops_repo_url" {
  description = "GitOps repository URL used by Argo CD."
  type        = string
}

variable "gitops_repo_username" {
  description = "Optional Git username for private GitOps repositories."
  type        = string
  default     = ""
}

variable "gitops_repo_password" {
  description = "Optional Git password or token for private GitOps repositories."
  type        = string
  sensitive   = true
  default     = ""
}

variable "gitops_target_revision" {
  description = "Git branch, tag, or commit Argo CD should track."
  type        = string
  default     = "main"
}

variable "gitops_app_path" {
  description = "Path inside the GitOps repo containing the ProjectX app chart."
  type        = string
  default     = "apps/projectx-api"
}

variable "github_repo" {
  description = "GitHub repository in owner/repo format (e.g. DemOnJR/ProjectX). Used for Workload Identity Federation binding for CI. When set with write_ci_secrets_to_vault, CI material is written to Vault KV for GitHub Actions (JWT auth). Leave empty to skip."
  type        = string
  default     = ""

  validation {
    condition     = var.github_repo == "" || var.write_ci_secrets_to_vault
    error_message = "When github_repo is set, write_ci_secrets_to_vault must be true so CI can read secrets from Vault (or clear github_repo to skip WIF CI)."
  }
}

variable "github_wif_pool_id" {
  description = "Workload Identity Pool ID for GitHub Actions (final segment of the pool resource name). Must match an existing pool when github_wif_use_existing_pool is true."
  type        = string
  default     = "github-actions"
}

variable "github_wif_use_existing_pool" {
  description = "When true, Terraform does not create google_iam_workload_identity_pool.github and instead reads the pool github_wif_pool_id from GCP. Use when apply fails with 409 (pool already exists in the project but is absent from state). Do not turn this on if that pool is already in Terraform state with github_wif_use_existing_pool false, or the next plan can destroy the managed pool; in that case use terraform import instead."
  type        = bool
  default     = false
}

variable "vault_address" {
  description = "Vault URL for the root module provider (e.g. https://vault.pbcv.dev). Token: export VAULT_TOKEN before terraform apply when write_ci_secrets_to_vault is true."
  type        = string
  default     = "https://vault.pbcv.dev"
}

variable "write_ci_secrets_to_vault" {
  description = "When true and github_repo is set, write CI key material to Vault KV (path vault_ci_secret_name on vault_ci_kv_mount). Requires VAULT_TOKEN in the environment during apply."
  type        = bool
  default     = true
}

variable "vault_ci_kv_mount" {
  description = "KV v2 mount for CI secrets written by this module."
  type        = string
  default     = "kv"
}

variable "vault_ci_secret_name" {
  description = "KV v2 secret name (path without mount), e.g. ci/projectx."
  type        = string
  default     = "ci/projectx"
}

variable "app_url" {
  description = "Public URL of the deployed app (e.g. https://projectx.pbcv.dev). Stored in Vault KV for the CI verify step."
  type        = string
  default     = ""
}

variable "github_gitops_pat" {
  description = "GitHub PAT (repo scope on ProjectX-ArgoCD) for CI to push image tags. Stored in Vault KV (not GitHub Actions secrets). Leave empty to skip writing gitops_pat."
  type        = string
  sensitive   = true
  default     = ""
}

variable "argocd_tunnel_token" {
  description = "Cloudflare tunnel token to expose Argo CD publicly. Leave empty to skip."
  type        = string
  sensitive   = true
  default     = ""
}

variable "projectx_tunnel_token" {
  description = "Cloudflare tunnel token to expose the ProjectX API publicly. Leave empty to skip. Also set cloudflareTunnel.enabled=true in values.yaml."
  type        = string
  sensitive   = true
  default     = ""
}
