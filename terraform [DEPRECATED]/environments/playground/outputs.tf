output "playground_ssh_private_key" {
  description = "Main VPS Private key generated"
  value = module.deploy_main_vps_secrets.ssh_private_key
  sensitive = true
}

output "playground_ssh_public_key" {
  description = "Main VPS Public key generated"
  value = module.deploy_main_vps_secrets.ssh_public_key
  sensitive = true
}

output "playground_root_password" {
  description = "Root password generated"
  value = module.deploy_main_vps_secrets.root_password
  sensitive = true
}

output "playground_cloud_config_file" {
  description = "Cloud config file used to provision Main VPS"
  value = module.deploy_main_vps_instances.main_vps_cloud_config_file
  sensitive = true
}