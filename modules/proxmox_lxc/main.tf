terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
    }
  }
}

resource "proxmox_virtual_environment_container" "container" {

  node_name     = var.node_name
  unprivileged  = true
  start_on_boot = true

  operating_system {
    template_file_id = var.container.template
    type             = "ubuntu"
  }

  initialization {
    hostname = var.container.hostname

    user_account {
      keys = [
        file(var.ssh_public_key)
      ]
    }

    ip_config {
      ipv4 {
        address = var.container.network.dhcp ? "dhcp" : null
      }
    }
  }

  cpu {
    cores = var.container.cores
  }

  memory {
    dedicated = var.container.memory
    swap      = 0
  }

  disk {
    datastore_id = var.datastore_id
    size         = var.container.disk
  }

  network_interface {
    name    = "eth0"
    bridge  = var.container.network.bridge
    vlan_id = var.container.network.vlan
  }

  features {
    nesting = true
  }
}
