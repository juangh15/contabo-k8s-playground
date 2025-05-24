# Output our newly created instances
output "main_vps_output" {
  description = "Main VPS Output"
  value = contabo_instance.main_vps.id
}

output "main_vps_cloud_config_file" {
  description = "Main VPS Cloud Config"
  value = contabo_instance.main_vps.user_data
}