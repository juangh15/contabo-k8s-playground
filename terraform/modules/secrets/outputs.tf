output "ssh_private_key" {
  description = "Main VPS Private key generated"
  value = chomp(tls_private_key.ssh_key.private_key_openssh)
  sensitive = true
}

output "ssh_public_key" {
  description = "Main VPS Public key generated"
  value = chomp(contabo_secret.main_ssh_key.value)
  sensitive = true
}

output "ssh_public_key_id" {
  description = "ID of Main VPS Public key generated"
  value = chomp(contabo_secret.main_ssh_key.id)
}

output "root_password" {
  description = "Root password generated"
  value = chomp(contabo_secret.main_root_password.value)
  sensitive = true
}

output "root_password_id" {
  description = "ID of Root password generated"
  value = chomp(contabo_secret.main_root_password.id)
}