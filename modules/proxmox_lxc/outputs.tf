output "hostname" {
  value = proxmox_virtual_environment_container.container.initialization[0].hostname
}

output "ipv4" {
  value = proxmox_virtual_environment_container.container.ipv4
}
