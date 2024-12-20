output "playground_ssh_private_key" {
  description = "Main VPS Private key generated"
  value = module.deploy_main_vps_secrets.ssh_private_key
  sensitive = true
}

output "playground_root_password" {
  description = "Root password generated"
  value = module.deploy_main_vps_secrets.root_password
  sensitive = true
}