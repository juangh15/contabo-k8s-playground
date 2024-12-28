terraform {
  required_providers {
    contabo = {
      source = "contabo/contabo"
      version = "0.1.26"
    }
  }
}

provider "contabo" {
  alias = "playground"
  oauth2_client_id = var.contabo_client_id
  oauth2_client_secret = var.contabo_client_secret
  oauth2_user = var.contabo_api_user
  oauth2_pass = var.contabo_api_password
}

module "deploy_main_vps_secrets" {
  source       = "../../modules/secrets"

  providers = {
    contabo = contabo.playground
  }

  contabo_main_ssh_key_name = "main_ssh_key"
  contabo_main_root_password_name = "main_root_password"
}


module "deploy_main_vps_instances" {
  depends_on = [module.deploy_main_vps_secrets]
  source       = "../../modules/instances"

  providers = {
    contabo = contabo.playground
  }
  init_script_path = "../../modules/instances/cloud_init.yml"
  os_version = "ubuntu_22_04"
  ssh_public_key = module.deploy_main_vps_secrets.ssh_public_key
  contabo_ssh_secret_ids = [module.deploy_main_vps_secrets.ssh_public_key_id]
}