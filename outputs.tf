output "ansible_inventory" {
  value = <<EOT
[proxmox_vms]
%{ for vm in module.vms ~}
${vm.name} ansible_host=${[for ip in flatten(vm.ipv4_addresses) : ip if ip != "127.0.0.1"][0]} ansible_user=infra
%{ endfor }

[proxmox_containers]
%{ for ct in module.containers ~}
${ct.hostname} ansible_host=${[for ip in ct.ipv4 : ip if ip != "127.0.0.1"][0]} ansible_user=root
%{ endfor }
EOT
}
