data "google_client_config" "default" {}

data "http" "terraform_client_ip" {
  url = "https://checkip.amazonaws.com"
}

locals {
  terraform_client_cidr = "${chomp(data.http.terraform_client_ip.response_body)}/32"
  use_private_gitops    = var.gitops_repo_username != "" && var.gitops_repo_password != ""
}

resource "google_project_service" "services" {
  for_each = var.manage_project_services ? toset([
    "artifactregistry.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "iam.googleapis.com"
  ]) : toset([])

  project            = var.gcp_project_id
  service            = each.key
  disable_on_destroy = false
}

resource "google_artifact_registry_repository" "docker" {
  location      = var.gcp_region
  repository_id = var.artifact_registry_repository_id
  description   = "Docker images for ProjectX"
  format        = "DOCKER"

  depends_on = [google_project_service.services]
}
