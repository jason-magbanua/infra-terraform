locals {
  ansible_user          = "infra"
  ansible_ssh_key       = "~/.ssh/id_rsa_ansible"
  proxmox_host_ip       = "172.16.1.8"
  proxmox_root_ssh_key  = "~/.ssh/root-sshkey.rsa"
  ansible_inventory_path = "/opt/infra/ansible/inventory/lab/hosts"
}

resource "local_file" "ansible_inventory" {
  filename = local.ansible_inventory_path

  content = <<EOT
[all:vars]
ansible_user=${local.ansible_user}
ansible_ssh_private_key_file=${local.ansible_ssh_key}
ansible_python_interpreter=/usr/bin/python3

[proxmox]
pve1 ansible_host=${local.proxmox_host_ip} ansible_user=root ansible_ssh_private_key_file=${local.proxmox_root_ssh_key}


[proxmox_vms]
%{ for vm in module.vms ~}
${vm.name} ansible_host=${try([for ip in flatten(vm.ipv4_addresses) : ip if ip != "127.0.0.1"][0], "")}
%{ endfor }

[proxmox_containers]
%{ for ct in module.containers ~}
${ct.hostname} ansible_host=${try([for ip in ct.ipv4 : ip if ip != "127.0.0.1"][0], "")}
%{ endfor }

[proxmox_containers:vars]
ansible_user=root
EOT
}
