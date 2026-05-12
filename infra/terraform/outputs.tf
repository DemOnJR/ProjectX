output "cluster_name" {
  description = "GKE cluster name."
  value       = module.gke.name
}

output "cluster_region" {
  description = "GKE cluster region."
  value       = var.gcp_region
}

output "artifact_registry_repository" {
  description = "Artifact Registry Docker repository."
  value       = "${var.gcp_region}-docker.pkg.dev/${var.gcp_project_id}/${google_artifact_registry_repository.docker.repository_id}"
}

output "get_credentials_command" {
  description = "Command to configure kubectl for this cluster."
  value       = "gcloud container clusters get-credentials ${module.gke.name} --region ${var.gcp_region} --project ${var.gcp_project_id}"
}

output "argocd_port_forward_command" {
  description = "Command to access Argo CD locally."
  value       = "kubectl -n argocd port-forward svc/argocd-server 8080:80"
}
