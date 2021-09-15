variable "GCP_REGION" {
  description = "GKE cluster region"
}

variable "GCP_PROJECT_ID" {
  description = "Name of google project id. Example: gke-cluster-test-123456"
}

variable "gke_username" {
  default     = ""
  description = "GKE username"
}

variable "gke_password" {
  default     = ""
  description = "GKE password"
}

variable "gke_node_count" {
  default     = 2
  description = "number of GKE nodes in the cluster"
}

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.52.0"
    }
  }

  required_version = "> 0.14"
}
provider "google" {
  project = var.GCP_PROJECT_ID
  region  = var.GCP_REGION
}

# GKE cluster
resource "google_container_cluster" "primary" {
  name     = "${var.GCP_PROJECT_ID}-gke"
  location = var.GCP_REGION

  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "${google_container_cluster.primary.name}-node-pool"
  location   = var.GCP_REGION
  cluster    = google_container_cluster.primary.name
  node_count = var.gke_node_count

  node_config {
    image_type = "ubuntu"

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    labels = {
      env = var.GCP_PROJECT_ID
    }

    # preemptible  = true
    machine_type = "n1-standard-1"
    tags         = ["gke-node", "${var.GCP_PROJECT_ID}-gke"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}

resource "google_compute_network" "vpc" {
  name                    = "${var.GCP_PROJECT_ID}-vpc"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${var.GCP_PROJECT_ID}-subnet"
  region        = var.GCP_REGION
  network       = google_compute_network.vpc.name
  ip_cidr_range = "10.10.0.0/24"
}
