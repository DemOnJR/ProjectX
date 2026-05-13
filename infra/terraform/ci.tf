# Keyless authentication for GitHub Actions via Workload Identity Federation.
# No service account keys are ever created or stored.

resource "google_iam_workload_identity_pool" "github" {
  count                     = var.github_repo != "" ? 1 : 0
  workload_identity_pool_id = "github-actions"
  display_name              = "GitHub Actions"
  description               = "WIF pool for ProjectX CI"

  depends_on = [google_project_service.services]
}

resource "google_iam_workload_identity_pool_provider" "github" {
  count = var.github_repo != "" ? 1 : 0

  workload_identity_pool_id          = google_iam_workload_identity_pool.github[0].workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub OIDC"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }

  # Only tokens from this specific repo are accepted.
  attribute_condition = "assertion.repository == '${var.github_repo}'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account" "ci" {
  count        = var.github_repo != "" ? 1 : 0
  account_id   = "projectx-ci"
  display_name = "ProjectX CI"
  description  = "Used by GitHub Actions to push Docker images to Artifact Registry"
}

resource "google_project_iam_member" "ci_ar_writer" {
  count   = var.github_repo != "" ? 1 : 0
  project = var.gcp_project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.ci[0].email}"
}

# Allows the GitHub Actions OIDC token (scoped to the repo) to impersonate the CI SA.
resource "google_service_account_iam_member" "ci_wif_binding" {
  count              = var.github_repo != "" ? 1 : 0
  service_account_id = google_service_account.ci[0].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github[0].name}/attribute.repository/${var.github_repo}"
}
