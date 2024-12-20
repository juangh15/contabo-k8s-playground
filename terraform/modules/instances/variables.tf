variable "contabo_ssh_secret_ids" {
  description = "Set of ids of the ssh keys stored in Contabo Secrets Manager"
  type        = set(string)
  sensitive   = true
}

variable "display_name" {
  description = "Name of the main_vps on the Contabo Console"
  type        = string
  default     = "MainVPS"
}

variable "init_script_path" {
  description = "Path of initialization script for the instance"
  type        = string
  default     = "./cloud_init.yml"
}

variable "os_version" {
  description = "OS version to use on the VPS. They should be defined in the data.tf file."
  type        = string
  default     = "ubuntu_22_04"
}

variable "ssh_public_key" {
  description = "ssh-rsa key used for encrypt instance SSH connections"
  type        = string
  sensitive   = true
}