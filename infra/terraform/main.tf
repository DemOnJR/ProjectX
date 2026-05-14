data "google_client_config" "default" {}

data "http" "terraform_client_ip" {
  count = var.gke_master_authorized_include_current_ip ? 1 : 0

  url                = "https://checkip.amazonaws.com"
  request_timeout_ms = 20000
}

locals {
  terraform_client_cidr = var.gke_master_authorized_include_current_ip ? "${chomp(data.http.terraform_client_ip[0].response_body)}/32" : ""
  use_private_gitops    = var.gitops_repo_username != "" && var.gitops_repo_password != ""
  ar_repo_url           = "${var.gcp_region}-docker.pkg.dev/${var.gcp_project_id}/${var.artifact_registry_repository_id}"
}

resource "google_project_service" "services" {
  for_each = var.manage_project_services ? toset([
    "artifactregistry.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com"
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

# Deletes all images before terraform destroy so the repository can be removed cleanly.
resource "terraform_data" "artifact_registry_cleanup" {
  triggers_replace = local.ar_repo_url

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      REPO="${self.triggers_replace}"
      DIGESTS=$(gcloud artifacts docker images list "$REPO" \
        --format="value(DIGEST)" 2>/dev/null | sort -u)
      for digest in $DIGESTS; do
        [ -n "$digest" ] && \
          gcloud artifacts docker images delete "$REPO@$digest" \
            --delete-tags --quiet 2>/dev/null || true
      done
    EOT
  }

  depends_on = [google_artifact_registry_repository.docker]
}
