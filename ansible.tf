resource "local_file" "ansible_inventory" {
  filename = var.ansible_inventory_path

  content = <<EOT
[all:vars]
ansible_user=${var.ansible_user}
ansible_ssh_private_key_file=${var.ansible_ssh_key}
ansible_python_interpreter=/usr/bin/python3

[proxmox]
pve1 ansible_host=${var.proxmox_host_ip} ansible_user=root ansible_ssh_private_key_file=${var.proxmox_root_ssh_key}


[proxmox_vms]
%{ for vm in module.vms ~}
%{ if try([for ip in flatten(vm.ipv4_addresses) : ip if ip != "127.0.0.1"][0], "") != "" ~}
${vm.name} ansible_host=${try([for ip in flatten(vm.ipv4_addresses) : ip if ip != "127.0.0.1"][0], "")}
%{ endif ~}
%{ endfor ~}

[proxmox_containers]
%{ for ct in module.containers ~}
%{ if try([for ip in ct.ipv4 : ip if ip != "127.0.0.1"][0], "") != "" ~}
${ct.hostname} ansible_host=${try([for ip in ct.ipv4 : ip if ip != "127.0.0.1"][0], "")}
%{ endif ~}
%{ endfor ~}

[proxmox_containers:vars]
ansible_user=root
EOT
}
