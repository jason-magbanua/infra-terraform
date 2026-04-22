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

variable "proxmox_host_ip" {
  description = "IP address of the Proxmox host (used in Ansible inventory)"
  type        = string
  default     = "172.16.1.8"
}

variable "ansible_user" {
  description = "SSH user for Ansible managed hosts"
  type        = string
  default     = "infra"
}

variable "ansible_ssh_key" {
  description = "Path to SSH private key for Ansible"
  type        = string
  default     = "~/.ssh/id_rsa_ansible"
}

variable "ansible_ssh_public_key" {
  description = "Path to SSH public key to inject into containers"
  type        = string
  default     = "~/.ssh/id_rsa_ansible.pub"
}

variable "proxmox_root_ssh_key" {
  description = "Path to SSH private key for Proxmox root access (used in Ansible inventory)"
  type        = string
  default     = "~/.ssh/root-sshkey.rsa"
}

variable "ansible_inventory_path" {
  description = "File path where the Ansible inventory will be written"
  type        = string
  default     = "/opt/infra/ansible/inventory/lab/hosts"
}
