# Terraform state will be stored in google bucket
terraform {
  backend "gcs" {
    bucket  = "tf-state-demblock"
    prefix  = "terraform/state"
  }
}

# Authentication
provider "google" {
  project     = "demblock"
  region      = "europe-west1"
}

# Kubernetes cluster
resource "google_container_cluster" "eu_demblock_cluster" {
  project            = "demblock"
  name               = "eu-demblock-cluster"
  network            = "default"
  location           = "europe-west1"
  initial_node_count = 2

  node_config {
    machine_type = "f1-micro"
    disk_size_gb = "50"

  }

  timeouts {
    create = "30m"
    update = "40m"
  }
}

# Private network
resource "google_compute_network" "private_network" {
  name = "private-network"
}

resource "google_compute_global_address" "private_ip_address" {
  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.private_network.self_link
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.private_network.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

# PostgreSQL database
resource "google_sql_database_instance" "demblock_db_instance" {
  project  = "demblock"
  name    = "eu-demblock-db-instance"
  region  = "europe-west1"
  
  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.private_network.self_link
    }
  }
}

resource "google_sql_database" "demblock_db" {
  project  = "demblock"
  name     = "demblock-db"
  instance = google_sql_database_instance.demblock_db_instance.name
}

# MongoDB
resource "kubernetes_persistent_volume" "mongodb-demblock" {
  metadata {
    name = "mongodb-demblock"
  }
  spec {
    capacity = {
      storage = "2Gi"
    }
    access_modes = ["ReadWriteMany"]
    persistent_volume_source {
      vsphere_volume {
        volume_path = "/mongodb/data"
      }
    }
  }
}