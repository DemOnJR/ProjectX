terraform {
  required_version = ">= 1.5.0"

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
  }
}

# Auth via VAULT_TOKEN environment variable — run: export VAULT_TOKEN=$(vault print token)
provider "vault" {
  address = var.vault_address
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}
