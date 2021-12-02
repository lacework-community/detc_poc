terraform {
  required_providers {
    ssh = {
      source  = "loafoe/ssh"
      version = "1.0.1"
    }
  }
}

variable "GCP_PROJECT_ID" {
  description = "Name of google project id. Example: gke-cluster-test-123456"
}

resource "tls_private_key" "keypair" {
  algorithm = "RSA"
}

# Virtual Private Network
resource "google_compute_network" "activity-network" {
  name    = "activity-network"
  project = var.GCP_PROJECT_ID
}

# Enable ssh
resource "google_compute_firewall" "ssh_rule" {
  name    = "activity-network-ssh"
  project = var.GCP_PROJECT_ID
  network = google_compute_network.activity-network.name
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  target_tags   = ["activity-vm-instance"]
  source_ranges = ["0.0.0.0/0"]
}


# VM Instance
resource "google_compute_instance" "activity-vm-instance" {
  project      = var.GCP_PROJECT_ID
  zone         = "us-central1-a"
  depends_on   = [google_compute_network.activity-network, google_compute_firewall.ssh_rule]
  name         = "activity-vm-instance"
  machine_type = "f1-micro"
  tags         = ["activity-vm-instance"]
  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }
  metadata = {
    ssh-keys = "root:${tls_private_key.keypair.public_key_openssh}"
  }
  network_interface {
    network = google_compute_network.activity-network.name
    access_config {
    }
  }
}

# Setup SAs for making noise
resource "google_service_account" "service_account" {
  for_each     = toset(["leia", "luke", "han"])
  project      = var.GCP_PROJECT_ID
  account_id   = "${each.value}-sa"
  display_name = each.value
}

resource "google_service_account_key" "service_account_key" {
  for_each           = google_service_account.service_account
  service_account_id = each.value.name
}

resource "google_project_iam_member" "service-account-iam" {
  for_each = google_service_account.service_account
  project  = var.GCP_PROJECT_ID
  role     = "roles/editor"
  member   = "serviceAccount:${each.value.email}"
}

resource "ssh_resource" "root_tf_dir" {
  host        = google_compute_instance.activity-vm-instance.network_interface.0.access_config.0.nat_ip
  depends_on  = [google_compute_instance.activity-vm-instance]
  user        = "root"
  host_user   = "root"
  private_key = tls_private_key.keypair.private_key_pem
  commands    = ["test -d /root/tf || mkdir -p /root/tf"]
}

resource "ssh_resource" "auth_files" {
  for_each    = google_service_account_key.service_account_key
  host        = google_compute_instance.activity-vm-instance.network_interface.0.access_config.0.nat_ip
  host_user   = "root"
  private_key = tls_private_key.keypair.private_key_pem
  depends_on  = [ssh_resource.root_tf_dir]

  file {
    destination = "/root/tf/gcp_auth_${each.key}.json"
    content     = base64decode(each.value.private_key)
  }
}

resource "ssh_resource" "run_file" {
  host        = google_compute_instance.activity-vm-instance.network_interface.0.access_config.0.nat_ip
  host_user   = "root"
  user        = "root"
  private_key = tls_private_key.keypair.private_key_pem

  file {
    destination = "/root/tf/main.tf"
    content     = file("${path.module}/files/main.tf.source")
    permissions = "0660"

  }

  file {
    destination = "/root/tf/gcp_run.sh"
    content = templatefile("${path.module}/files/run.tpl", {
      data    = google_service_account_key.service_account_key
      project = var.GCP_PROJECT_ID
    })
    permissions = "0700"
  }

  file {
    destination = "/root/setup.sh"
    content     = file("${path.module}/files/setup.sh")
    permissions = "0700"
  }

  commands   = ["/root/setup.sh"]
  depends_on = [ssh_resource.auth_files]
}
