############################################################
# Infrastructure Definitions
############################################################

locals {

  ubuntu_template = "local-ssd:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
  gw              = "10.10.200.1"
  lxc_net         = { bridge = "vmbr1", vlan = 200 }

  ############################################################
  # VMs  (hostname injected from map key)
  ############################################################

  _vms = {

    docker-host = {
      cores           = 2
      memory          = 2048
      memory_floating = 1536
      on_boot         = false
      disk            = { size = 20, datastore = "local-ssd", format = "qcow2" }
      network         = { bridge = "vmbr1", vlan = 200, address = "10.10.200.50/24", gateway = local.gw }
    }

    k3s-control = {
      cores           = 2
      memory          = 3072
      memory_floating = 2048
      on_boot         = false
      disk            = { size = 20, datastore = "local-ssd", format = "qcow2" }
      network         = { bridge = "vmbr1", vlan = 200, address = "10.10.200.60/24", gateway = local.gw }
    }

    k3s-worker1 = {
      cores           = 2
      memory          = 2048
      memory_floating = 1536
      on_boot         = false
      disk            = { size = 20, datastore = "local-ssd", format = "qcow2" }
      network         = { bridge = "vmbr1", vlan = 200, address = "10.10.200.61/24", gateway = local.gw }
    }

    k3s-worker2 = {
      cores           = 2
      memory          = 2048
      memory_floating = 1536
      on_boot         = false
      disk            = { size = 20, datastore = "local-ssd", format = "qcow2" }
      network         = { bridge = "vmbr1", vlan = 200, address = "10.10.200.62/24", gateway = local.gw }
    }

    k3s-worker3 = {
      cores           = 2
      memory          = 2048
      memory_floating = 1536
      on_boot         = false
      disk            = { size = 20, datastore = "local-ssd", format = "qcow2" }
      network         = { bridge = "vmbr1", vlan = 200, address = "10.10.200.63/24", gateway = local.gw }
    }

    k3s-worker4 = {
      cores           = 2
      memory          = 2048
      memory_floating = 1536
      on_boot         = false
      disk            = { size = 20, datastore = "local-ssd", format = "qcow2" }
      network         = { bridge = "vmbr1", vlan = 200, address = "10.10.200.64/24", gateway = local.gw }
    }

    # Commenting this for example
    # wp-host1 = {
    #   cores  = 4
    #   memory = 2048
    #   disk   = { size = 20, datastore = "local-ssd", format = "qcow2" }
    #   additional_disks = [
    #     { size = 40, datastore = "local-ssd", format = "qcow2" },
    #     { size = 40, datastore = "local-ssd", format = "qcow2" },
    #   ]
    #   network = { bridge = "vmbr1", vlan = 200, address = "10.10.200.80/24", gateway = local.gw }
    # }

    #  wp-host2-dhcp = {
    #   cores  = 4
    #   memory = 2048
    #   disk   = { size = 20, datastore = "local-ssd", format = "qcow2" }
    #   additional_disks = [
    #     { size = 40, datastore = "local-ssd", format = "qcow2" },
    #     { size = 40, datastore = "local-ssd", format = "qcow2" },
    #   ]
    #   network = { bridge = "vmbr1", vlan = 200}
    # }

  }

  vms = { for k, v in local._vms : k => merge(v, { hostname = k }) }

  ############################################################
  # Containers  (hostname, template, bridge/vlan injected from defaults)
  # Static IP:  network = { address = "10.10.200.X/24", gateway = local.gw }
  # DHCP:       network = {}
  ############################################################

  _containers = {

    # --- Infrastructure Core -------------------------------------------
    # jump-host     = { cores = 1, memory = 512,  disk = 4,  network = { address = "10.10.200.3/24",  gateway = local.gw } }
    # apt-cacher-ng = { cores = 1, memory = 512,  disk = 20, network = { address = "10.10.200.4/24",  gateway = local.gw } }

    # --- Networking & Proxy --------------------------------------------
    traefik       = { cores = 1, memory = 512,  disk = 4,  network = { address = "10.10.200.10/24", gateway = local.gw } }

    # --- Observability -------------------------------------------------
    prometheus    = { cores = 1, memory = 1024, disk = 8,  network = { address = "10.10.200.20/24", gateway = local.gw }, on_boot = false }
    grafana       = { cores = 1, memory = 1024, disk = 8,  network = { address = "10.10.200.21/24", gateway = local.gw }, on_boot = false }

  }

  containers = {
    for k, v in local._containers : k => merge(
      { hostname = k, template = local.ubuntu_template },
      v,
      { network = merge(local.lxc_net, lookup(v, "network", {})) }
    )
  }
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
