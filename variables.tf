variable "proxmox_endpoint" {
  description = "URL of the Proxmox API endpoint"
  type        = string
}

variable "proxmox_api_token" {
  description = "Proxmox API token for authentication"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "Proxmox node name where resources will be created"
  type        = string
  default     = "pve1"
}
