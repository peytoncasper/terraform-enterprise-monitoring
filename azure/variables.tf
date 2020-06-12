variable "vm_admin_username" {
    type = "string"
    default = "terraformadmin"
}

variable "public_key_path" {
    type = "string"
    default = "~/.ssh/id_rsa.pub"
}

variable "encryption_password" {
    type = "string" 
    default = "jzrtY@KE-bQ@mwQdxhYxj"
}

variable "pg_admin_username" {
    type = "string"
    default = "terraform"
}

variable "pg_admin_password" {
    type = "string"
    default = "{6h[BBs*-P"
}

variable "license" {
    type = "string"
}