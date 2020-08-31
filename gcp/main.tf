provider "google" {
  region      = "us-east1"
}

resource "random_integer" "cloud_sql_modifier" {
  min     = 100
  max     = 200
}

resource "google_compute_address" "terraform_ext" {
  name = "terraform-ext-address"
}

resource "google_compute_address" "terraform_int" {
  name = "terraform-int-address"
  address_type = "INTERNAL"
}

resource "google_compute_firewall" "terraform" {
  name    = "terraform-firewall"
  network = "default"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["80", "8800", "443", "22"]
  }
}

resource "google_storage_bucket" "terraform" {
  name          = "terraform-bucket-123"
  location      = "US"
  force_destroy = true

  lifecycle_rule {
    condition {
      age = "3"
    }
    action {
      type = "Delete"
    }
  }
}

resource "google_sql_database_instance" "terraform" {
  name             = join("", ["terraform-instance",random_integer.cloud_sql_modifier.result])
  database_version = "POSTGRES_11"
  region           = "us-east1"

  settings {
    tier = "db-f1-micro"

    ip_configuration {

      authorized_networks {
        name = "terraform-machine"
        value = google_compute_address.terraform_ext.address
      }

    }
  }
}

resource "google_sql_database" "terraform" {
  name     = "terraformdb"
  instance = google_sql_database_instance.terraform.name
}

resource "google_sql_user" "terraform" {
  name     = var.pg_admin_username
  instance = google_sql_database_instance.terraform.name
  password = var.pg_admin_password
}

resource "google_compute_instance" "terraform" {
  name         = "terraform-machine"
  machine_type = "n1-standard-2"
  zone         = "us-east1-c"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1604-lts"
      size = "60"
    }
  }

  network_interface {
    network = "default"
    network_ip = google_compute_address.terraform_int.address
    access_config {
      nat_ip = google_compute_address.terraform_ext.address
    }
  }



  metadata_startup_script = templatefile("scripts/terraform.sh", {
    "PRIVATE_IP_ADDRESS" = google_compute_address.terraform_int.address,
    "PUBLIC_IP_ADDRESS"  = google_compute_address.terraform_ext.address,
    "ENCRYPTION_PASSWORD"= var.encryption_password,
    "GCS_CREDENTIALS"    = replace(file(var.gcs_credentials_path), "\\n", ""),
    "GCS_PROJECT"        = google_storage_bucket.terraform.project,
    "GCS_BUCKET"         = google_storage_bucket.terraform.name,
    "PG_DB_NAME"         = google_sql_database.terraform.name,
    "PG_USERNAME"        = var.pg_admin_username,
    "PG_PASSWORD"        = var.pg_admin_password,
    "PG_ENDPOINT"        = google_sql_database_instance.terraform.public_ip_address,
    "LICENSE"            = var.license
  })
  
  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro", "monitoring-write", "logging-write", "cloud-platform"]
  }
  
}