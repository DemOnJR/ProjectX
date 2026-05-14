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
  description = "GitHub repository in owner/repo format (e.g. DemOnJR/ProjectX). Used to create the Workload Identity Federation binding for CI. Leave empty to skip."
  type        = string
  default     = ""
}

variable "github_token" {
  description = <<-EOT
    GitHub token used by Terraform to create and delete Actions secrets on github_repo.
    Classic PAT: repo scope. Fine-grained: access to github_repo with "Secrets" read and write.
    terraform destroy loads the same tfvars / -var-file / TF_VAR_github_token as apply, and uses this token to remove github_actions_secret resources before dependent GCP resources are torn down — keep a valid token until destroy finishes, or export GITHUB_TOKEN with the same PAT and leave this empty (see github provider in github-ci.tf).
    401 errors on plan/apply/destroy mean the token is expired, revoked, or lacks those permissions — create a new PAT and update this value.
    Until the token is fixed, you can run terraform plan/apply with -refresh=false to change GCP resources without the provider calling the GitHub API (use sparingly; refresh drift is possible).
    Leave empty to skip creating github_actions_secret resources (github_repo must still be set for WIF in ci.tf).
  EOT
  type        = string
  sensitive   = true
  default     = ""
}

variable "app_url" {
  description = "Public URL of the deployed app (e.g. https://projectx.pbcv.dev). Used as APP_URL Actions secret for post-deploy health checks."
  type        = string
  default     = ""
}

variable "github_gitops_pat" {
  description = "GitHub PAT (repo scope on ProjectX-ArgoCD) injected as the GITOPS_PAT Actions secret so CI can push image tags. Also written to Vault for central secret management. Leave empty to skip."
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
