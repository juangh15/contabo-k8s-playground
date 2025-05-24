terraform {
  required_providers {
    contabo = {
      source = "contabo/contabo"
      version = "0.1.31"
    }
  }
}

resource "contabo_instance" "main_vps" {
  display_name = var.display_name
  image_id = local.contabo_images[var.os_version]
  ssh_keys = var.contabo_ssh_secret_ids
  user_data = data.template_file.cloud_config.rendered
}