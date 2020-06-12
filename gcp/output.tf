output "instance_ip_addr" {
    value = google_compute_address.terraform_ext.address
}