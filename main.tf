############################################################
# Infrastructure Definitions
############################################################

locals {

  wp_host_defaults = {
    cores  = 4
    memory = 4096

    disk = { size = 20, datastore = "local-ssd", format = "qcow2" }

    additional_disks = [
      { size = 40, datastore = "local-ssd", format = "qcow2" },
      { size = 40, datastore = "local-ssd", format = "qcow2" }
    ]

    network = { bridge = "vmbr4", vlan = 200, dhcp = true }
  }

  wp_hosts = {
    wp-host1 = { hostname = "wp-host1" }
  }

  vms = {
    for name, host in local.wp_hosts :
    name => merge(local.wp_host_defaults, host)
  }

  containers = {

    jump-host = {
      hostname = "jump-host"
      cores    = 1
      memory   = 512
      disk     = 8
      template = "local-ssd:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
    
      network = {
        bridge = "vmbr4"
        vlan   = 200
        dhcp   = true
      }
    }

    jump-host = {
      hostname = "jump-host"
      cores    = 1
      memory   = 512
      disk     = 8
      template = "local-ssd:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
    
      network = {
        bridge = "vmbr4"
        vlan   = 200
        dhcp   = true
      }
    }

  }
}

############################################################
# VM Blueprint
############################################################

module "vms" {
  source = "./modules/proxmox_vm"

  for_each = local.vms

  node_name = "pve1"
  vm        = each.value
}

############################################################
# LXC Blueprint
############################################################

module "containers" {
  source = "./modules/proxmox_lxc"

  for_each = local.containers

  node_name      = "pve1"
  datastore_id   = "local-ssd"
  ssh_public_key = "~/.ssh/id_rsa_ansible.pub"

  container = each.value
}
