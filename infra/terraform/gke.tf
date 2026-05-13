module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google"
  version = "44.1.0"

  project_id = var.gcp_project_id
  name       = var.cluster_name
  region     = var.gcp_region
  zones      = var.gcp_zones

  network    = module.network.network_name
  subnetwork = module.network.subnets_names[0]

  ip_range_pods     = "${var.subnet_name}-pods"
  ip_range_services = "${var.subnet_name}-services"

  deletion_protection = false

  http_load_balancing        = true
  horizontal_pod_autoscaling = true
  network_policy             = true
  remove_default_node_pool   = true

  master_authorized_networks = [
    {
      cidr_block   = local.terraform_client_cidr
      display_name = "terraform-client"
    }
  ]

  node_pools = [
    {
      name               = var.node_pool_name
      machine_type       = var.node_machine_type
      node_locations     = join(",", var.gcp_zones)
      initial_node_count = var.node_min_count
      min_count          = var.node_min_count
      max_count          = var.node_max_count
      disk_size_gb       = 50
      disk_type          = "pd-balanced"
      auto_repair        = true
      auto_upgrade       = true
      preemptible        = false
      spot               = false
    }
  ]

  depends_on = [
    google_project_service.services,
    module.network
  ]
}
