provider "google" {
  project = "deft-epoch-361312"
  region  = "europe-west3"
  zone    = "europe-west3-a"
}

resource "google_compute_network" "vpc_network" {
  name = "project-network"
  auto_create_subnetworks = "true"
}

resource "google_container_cluster" "bootcampodev" {
  name = "project-gke"
  
  remove_default_node_pool = true
  initial_node_count       = 1
  
  network    = google_compute_network.vpc_network.name
}

resource "google_service_account" "nodepool" {
  account_id   = "project-serviceaccount"
  display_name = "Project Service Account"
}

resource "google_container_node_pool" "primary_preemptible_nodes" {
  name       = "project-node-pool"
  cluster    = google_container_cluster.bootcampodev.name
  node_count = 1
  
  node_config {
    preemptible  = true
	machine_type = "e2-medium"
	
	service_account = google_service_account.nodepool.email
	oauth_scopes    = [
	  "https://www.googleapis.com/auth/cloud-platform"
	]
  }
}
