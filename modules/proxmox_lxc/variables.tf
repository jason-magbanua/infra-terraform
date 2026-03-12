variable "node_name" {
  description = "Proxmox node where container will run"
  type        = string
}

variable "datastore_id" {
  description = "Datastore used for container disk"
  type        = string
  default     = "local-ssd"
}

variable "ssh_public_key" {
  description = "SSH public key injected into container"
  type        = string
}

variable "container" {
  description = "Container configuration object"
  type        = any
}
