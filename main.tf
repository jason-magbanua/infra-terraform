############################################################
# Infrastructure Definitions
############################################################

locals {

  ubuntu_template = "local-ssd:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"

  wp_host_defaults = {
    cores  = 4
    memory = 4096

    disk = { size = 20, datastore = "local-ssd", format = "qcow2" }

    additional_disks = [
      { size = 40, datastore = "local-ssd", format = "qcow2" },
      { size = 40, datastore = "local-ssd", format = "qcow2" }
    ]

    network = { bridge = "vmbr1", vlan = 200 }
  }

  wp_hosts = {
    wp-host1 = {}
  }

  monitoring_defaults = {
    cores    = 1
    memory   = 1024
    disk     = 8
    template = local.ubuntu_template
    network  = { bridge = "vmbr1", vlan = 200 }
  }

  monitoring_hosts = {
    # prometheus   = {}
    # grafana      = {}
    # loki         = {}
    # alertmanager = {}
  }

  vms = merge(
    {
      for name, host in local.wp_hosts :
      name => merge(local.wp_host_defaults, { hostname = name }, host)
    },
    {
      docker-host = {
        hostname = "docker-host"
        cores    = 2
        memory   = 2048

        disk = {
          size      = 10
          datastore = "local-ssd"
          format    = "qcow2"
        }

        network = {
          bridge  = "vmbr1"
          vlan    = 200
          address = "10.10.200.4/29"
          gateway = "10.10.200.1"
        }
      }
    }
  )

  containers = merge(
    {
      for name, host in local.monitoring_hosts :
      name => merge(local.monitoring_defaults, { hostname = name }, host)
    },
    # {
    #   jump-host = {
    #     hostname = "jump-host"
    #     cores    = 1
    #     memory   = 512
    #     disk     = 8
    #     template = local.ubuntu_template
    #     network  = { bridge = "vmbr1", vlan = 200 }
    #   }

    #   tailscale = {
    #     hostname = "tailscale"
    #     cores    = 1
    #     memory   = 512
    #     disk     = 4
    #     template = local.ubuntu_template
    #     network  = { bridge = "vmbr1", vlan = 200 }
    #   }

    #   coredns = {
    #     hostname = "coredns"
    #     cores    = 1
    #     memory   = 1024
    #     disk     = 8
    #     template = local.ubuntu_template
    #     network  = { bridge = "vmbr1", vlan = 200 }
    #   }
    # }
  )
}

############################################################
# VM Blueprint
############################################################

module "vms" {
  source = "./modules/proxmox_vm"

  for_each = local.vms

  node_name = var.proxmox_node
  vm        = each.value
}

############################################################
# LXC Blueprint
############################################################

module "containers" {
  source = "./modules/proxmox_lxc"

  for_each = local.containers

  node_name      = var.proxmox_node
  datastore_id   = "local-ssd"
  ssh_public_key = "~/.ssh/id_rsa_ansible.pub"

  container = each.value
}
