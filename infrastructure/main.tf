#=======================================================================
# Terraform state will be stored in Google Bucket
terraform {
  backend "gcs" {
    bucket = "tf-demblock"
    prefix = "terraform/state"
  }
}

#=======================================================================
# Required vars
#=======================================================================
variable "SQL_USER" {}
variable "SQL_PASSWORD" {}
variable "GKE_CLUSTER" {}
variable "GKE_ZONE" {}
variable "DB_INSTANCE" {}
variable "DB_LOCATION" {}

#=======================================================================
# Google Auth
#=======================================================================
provider "google" {
  project = "demblock"
  region  = "europe-west1"
}

#=======================================================================
# Private network
#=======================================================================
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

#=======================================================================
# Kubernetes cluster
#=======================================================================
resource "google_container_cluster" "eu_demblock_cluster" {
  project            = "demblock"
  name               = var.GKE_CLUSTER
  location           = var.GKE_ZONE
  initial_node_count = 4

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

#=======================================================================
# K8s auth
#=======================================================================
data "google_client_config" "default" {
}

data "google_container_cluster" "demblock-cluster" {
  name     = var.GKE_CLUSTER
  location = var.GKE_ZONE
}

provider "kubernetes" {
  load_config_file = false
  host             = "https://${data.google_container_cluster.demblock-cluster.endpoint}"
  token            = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(
    data.google_container_cluster.demblock-cluster.master_auth.0.cluster_ca_certificate,
  )
}

#=======================================================================
# Global IPs for services
#=======================================================================

# 1) IP ADDRESSES
resource "google_compute_global_address" "demblock" {
 name = "demblock-static-ip"
}

resource "google_compute_global_address" "demblock-tge" {
 name = "demblock-tge-static-ip"
}

resource "google_compute_global_address" "demblock-token" {
 name = "demblock-token-static-ip"
}

#=======================================================================
# 2) DNS ZONES
resource "google_dns_managed_zone" "demblock-com" {
 count    = "1"
 dns_name = "demblock.com"
 name     = "demblock"
}

resource "google_dns_managed_zone" "demblock-tge-com" {
 count    = "1"
 dns_name = "demblock-tge.com"
 name     = "demblock-tge"
}

#=======================================================================
# 3) RECORDS
resource "google_dns_record_set" "demblock" {
 project      = "demblock"
 managed_zone = "demblock"
 name         = "demblock.com"
 type         = "A"
 ttl          = 300
 rrdatas      = ["${google_compute_global_address.demblock.address}"]
}

resource "google_dns_record_set" "backend-demblock" {
 project      = "demblock"
 managed_zone = "demblock"
 name         = "backend.demblock.com"
 type         = "A"
 ttl          = 300
 rrdatas      = ["${google_compute_global_address.demblock.address}"]
}

#=======================================================================

resource "google_dns_record_set" "demblock-tge" {
 project      = "demblock"
 managed_zone = "demblock-tge"
 name         = "demblock-tge.com"
 type         = "A"
 ttl          = 300
 rrdatas      = ["${google_compute_global_address.demblock-tge.address}"]
}

resource "google_dns_record_set" "backend-demblock-tge" {
 project      = "demblock"
 managed_zone = "demblock-tge"
 name         = "backend.demblock-tge.com"
 type         = "A"
 ttl          = 300
 rrdatas      = ["${google_compute_global_address.demblock-tge.address}"]
}

#=======================================================================

resource "google_dns_record_set" "token-demblock-tge" {
 project      = "demblock"
 managed_zone = "demblock-tge"
 name         = "token.demblock-tge.com"
 type         = "A"
 ttl          = 300
 rrdatas      = ["${google_compute_global_address.demblock-token.address}"]
}


#=======================================================================
# SQL DBs for Demblock
#=======================================================================
resource "google_sql_database_instance" "demblock_db_instance" {
  project = "demblock"
  name    = var.DB_INSTANCE
  region  = var.DB_LOCATION

  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.demblock_network.self_link
    }
  }
}

resource "google_sql_user" "users" {
  name     = var.SQL_USER
  password = var.SQL_PASSWORD
  instance = google_sql_database_instance.demblock_db_instance.name
}

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

#=======================================================================
# Demblock Persistent Data
#=======================================================================
resource "google_compute_disk" "demblock-disk" {
  name                      = "demblock-disk"
  type                      = "pd-standard"
  zone                      = "europe-north1-a"
  size                      = 20
  physical_block_size_bytes = 4096
}

resource "kubernetes_persistent_volume" "demblock-volume" {
  metadata {
    name = "demblock-pv"
  }
  spec {
    capacity = {
      storage = "15Gi"
    }
    access_modes       = ["ReadWriteMany"]
    storage_class_name = "standard"
    persistent_volume_source {
      gce_persistent_disk {
        pd_name = "demblock-disk"
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "demblock-pvc" {
  metadata {
    name = "demblock-pvc"
  }
  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = "standard"
    resources {
      requests = {
        storage = "15Gi"
      }
    }
    volume_name = kubernetes_persistent_volume.demblock-volume.metadata.0.name
  }
}