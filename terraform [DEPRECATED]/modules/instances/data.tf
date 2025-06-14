data "contabo_image" "ubuntu_20_04" {
  id = "db1409d2-ed92-4f2f-978e-7b2fa4a1ec90"
}

data "contabo_image" "ubuntu_22_04" {
  id = "afecbb85-e2fc-46f0-9684-b46b1faf00bb"
}

data "contabo_image" "ubuntu_24_04" {
  id = "d64d5c6c-9dda-4e38-8174-0ee282474d8a"
}

locals {
  contabo_images = {
    ubuntu_20_04 = "db1409d2-ed92-4f2f-978e-7b2fa4a1ec90"
    ubuntu_22_04 = "afecbb85-e2fc-46f0-9684-b46b1faf00bb"
    ubuntu_24_04 = "d64d5c6c-9dda-4e38-8174-0ee282474d8a"
  }
}


data "template_file" "cloud_config" {
  template = file(var.init_script_path)

  vars = {
    ssh_public_key = chomp(var.ssh_public_key)
  }
}