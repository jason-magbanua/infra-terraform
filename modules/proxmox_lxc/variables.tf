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
  description = "Path to SSH public key file to inject into container"
  type        = string
}

variable "container" {
  description = "Container configuration"
  type = object({
    hostname = string
    cores    = number
    memory   = number
    disk     = number
    template = string
    os_type  = optional(string, "ubuntu")
    network = object({
      bridge  = string
      vlan    = optional(number)
      address = optional(string, "dhcp")
      gateway = optional(string)
    })
  })
}
