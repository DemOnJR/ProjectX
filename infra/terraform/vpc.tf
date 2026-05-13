module "network" {
  source  = "terraform-google-modules/network/google"
  version = "18.1.0"

  project_id   = var.gcp_project_id
  network_name = var.network_name
  routing_mode = "REGIONAL"

  subnets = [
    {
      subnet_name           = var.subnet_name
      subnet_ip             = var.subnet_cidr
      subnet_region         = var.gcp_region
      subnet_private_access = true
    }
  ]

  secondary_ranges = {
    (var.subnet_name) = [
      {
        range_name    = "${var.subnet_name}-pods"
        ip_cidr_range = var.pods_cidr
      },
      {
        range_name    = "${var.subnet_name}-services"
        ip_cidr_range = var.services_cidr
      }
    ]
  }

  depends_on = [google_project_service.services]
}
