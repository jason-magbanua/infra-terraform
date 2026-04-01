variable "node_name" {
  description = "Proxmox node where the VM will be created"
  type        = string
}

variable "clone_vm_id" {
  description = "Proxmox VM ID to clone as the base image"
  type        = number
  default     = 9000
}

variable "vm" {
  description = "VM configuration"
  type = object({
    hostname = string
    cores    = number
    memory   = number
    disk = object({
      size      = number
      datastore = string
      format    = string
    })
    additional_disks = optional(list(object({
      size      = number
      datastore = string
      format    = string
    })), [])
    network = object({
      bridge  = string
      vlan    = optional(number)
      address = optional(string, "dhcp")
      gateway = optional(string)
    })
    memory_floating = optional(number)
    on_boot         = optional(bool, true)
})
}
