variable "GCP_REGION" {
  description = "GCP region"
}

variable "GCP_PROJECT_ID" {
  description = "Name of google project id. Example: test-123456"
}

variable "VOTE_URL" {
  description = "Vote app url"
}

variable "RESULT_URL" {
  description = "Result app url"
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

resource "google_compute_instance" "default" {
  name         = "test"
  machine_type = "e2-small"
  zone         = "${var.GCP_REGION}-b"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral public IP
    }
  }

  metadata_startup_script = "${templatefile(
                  "../../scripts/loadgen-vm-setup-script.sh",
                  {
                    "VOTE_URL"=var.VOTE_URL,
                    "RESULT_URL"=var.RESULT_URL
                  }
                 )}"
}