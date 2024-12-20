output "ssh_private_key" {
  description = "Main VPS Private key generated"
  value = chomp(tls_private_key.ssh_key.private_key_openssh)
  sensitive = true
}

output "root_password" {
  description = "Root password generated"
  value = chomp(contabo_secret.main_root_password.value)
  sensitive = true
}