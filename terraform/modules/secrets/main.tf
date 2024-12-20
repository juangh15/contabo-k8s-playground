terraform {
  required_providers {
    contabo = {
      source = "contabo/contabo"
      version = "0.1.26"
    }
  }
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "random_password" "password" {
  length           = 16
  special          = false
}

resource "contabo_secret" "main_ssh_key" {
  name        = var.contabo_main_ssh_key_name
  type        = "ssh"
  value       = chomp(tls_private_key.ssh_key.public_key_openssh)
}

resource "contabo_secret" "main_root_password" {
  name        = var.contabo_main_root_password_name
  type        = "password"
  value       = chomp(random_password.password.result)
}
