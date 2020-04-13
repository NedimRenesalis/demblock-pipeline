# Terraform state will be stored in google bucket
terraform {
  backend "gcs" {
    bucket = "tf-demblock"
    prefix = "terraform/state"
  }
}

# Required vars
variable "SQL_USER" {}
variable "SQL_PASSWORD" {}

# Auth
provider "google" {
  project = "demblock"
  region  = "europe-west1"
}

# Private network
resource "google_compute_network" "demblock_network" {
  name = "demblock-shared"
}

resource "google_compute_global_address" "private_ip_address" {
  name          = "demblock-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.demblock_network.self_link
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.demblock_network.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

# Kubernetes cluster
resource "google_container_cluster" "eu_demblock_cluster" {
  project            = "demblock"
  name               = "eu-demblock-cluster"
  location           = "europe-north1-a"
  initial_node_count = 2

  depends_on = [google_service_networking_connection.private_vpc_connection]
  network    = google_compute_network.demblock_network.self_link
  node_config {
    machine_type = "g1-small"
    disk_size_gb = "50"
  }

  ip_allocation_policy {
  }

  timeouts {
    create = "30m"
    update = "40m"
  }
}


# K8s auth
data "google_client_config" "default" {
}

data "google_container_cluster" "demblock-cluster" {
  name     = "eu-demblock-cluster"
  location = "europe-north1-a"
}

provider "kubernetes" {
  load_config_file = false
  host             = "https://${data.google_container_cluster.demblock-cluster.endpoint}"
  token            = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(
    data.google_container_cluster.demblock-cluster.master_auth.0.cluster_ca_certificate,
  )
}

# PostgreSQL database
resource "google_sql_database_instance" "demblock_db_instance" {
  project = "demblock"
  name    = "eu-demblock-db"
  region  = "europe-north1"

  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.demblock_network.self_link
    }
  }
}

# DB User
resource "google_sql_user" "users" {
  name     = var.SQL_USER
  password = var.SQL_PASSWORD
  instance = google_sql_database_instance.demblock_db_instance.name
}

# SQL DBs for Demblock
resource "google_sql_database" "demblock_db" {
  project  = "demblock"
  name     = "demblock"
  instance = google_sql_database_instance.demblock_db_instance.name
}

resource "google_sql_database" "demblock_tge_db" {
  project  = "demblock"
  name     = "demblock-tge"
  instance = google_sql_database_instance.demblock_db_instance.name
}

# Demblock Persistent Data
resource "google_compute_disk" "demblock-disk" {
  name  = "demblock-disk"
  type  = "pd-standard"
  zone  = "europe-north1-a"
  size  = 15
  physical_block_size_bytes = 4096
}