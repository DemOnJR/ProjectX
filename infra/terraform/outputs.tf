output "cluster_name" {
  description = "GKE cluster name."
  value       = module.gke.name
}

output "artifact_registry_repository" {
  description = "Artifact Registry Docker repository URL."
  value       = local.ar_repo_url
}

output "get_credentials_command" {
  description = "Command to configure kubectl for this cluster."
  value       = "gcloud container clusters get-credentials ${module.gke.name} --region ${var.gcp_region} --project ${var.gcp_project_id}"
}

output "argocd_port_forward_command" {
  description = "Command to access Argo CD locally."
  value       = "kubectl -n argocd port-forward svc/argocd-server 8080:80"
}

output "argocd_initial_password_command" {
  description = "Command to retrieve the initial Argo CD admin password."
  value       = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d && echo"
}

output "ci_wif_provider" {
  description = "Workload Identity Federation provider resource name (also written to Vault KV when write_ci_secrets_to_vault is true)."
  value       = var.github_repo != "" ? google_iam_workload_identity_pool_provider.github[0].name : "github_repo variable not set"
}

output "ci_service_account" {
  description = "CI service account email (also written to Vault KV when write_ci_secrets_to_vault is true)."
  value       = var.github_repo != "" ? google_service_account.ci[0].email : "github_repo variable not set"
}

output "docker_push_example" {
  description = "Example commands to build and push the app image."
  value       = <<-EOT
    gcloud auth configure-docker ${var.gcp_region}-docker.pkg.dev
    docker build -t ${local.ar_repo_url}/projectx-api:0.1.0 ./app
    docker push ${local.ar_repo_url}/projectx-api:0.1.0
  EOT
}
