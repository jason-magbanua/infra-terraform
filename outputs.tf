resource "local_file" "ansible_inventory" {
  filename = "/opt/infra/ansible/inventory/lab/hosts"

  content = <<EOT
[all:vars]
ansible_user=infra
ansible_ssh_private_key_file=~/.ssh/id_rsa_ansible
ansible_python_interpreter=/usr/bin/python3

[proxmox]
pve1 ansible_host=10.10.200.8 ansible_user=root ansible_ssh_private_key_file=~/.ssh/root-sshkey.rsa


[proxmox_vms]
%{ for vm in module.vms ~}
${vm.name} ansible_host=${[for ip in flatten(vm.ipv4_addresses) : ip if ip != "127.0.0.1"][0]}
%{ endfor }

[proxmox_containers]
%{ for ct in module.containers ~}
${ct.hostname} ansible_host=${[for ip in ct.ipv4 : ip if ip != "127.0.0.1"][0]} ansible_user=root
%{ endfor }
EOT
}
