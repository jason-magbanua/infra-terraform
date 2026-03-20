terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
    }
  }
}

resource "proxmox_virtual_environment_vm" "vm" {

  name      = var.vm.hostname
  node_name = var.node_name

  clone {
    vm_id = 9000
  }

  cpu {
    cores = var.vm.cores
  }

  memory {
    dedicated = var.vm.memory
  }

  disk {
    datastore_id = var.vm.disk.datastore
    interface    = "scsi0"
    size         = var.vm.disk.size
    file_format  = var.vm.disk.format
    ssd          = true
  }

  dynamic "disk" {
    for_each = try(var.vm.additional_disks, {})
    content {
      datastore_id = disk.value.datastore
      interface    = "scsi${disk.key + 1}"
      size         = disk.value.size
      file_format  = disk.value.format
      ssd          = true
    }
  }

  network_device {
    bridge  = var.vm.network.bridge
    vlan_id = try(var.vm.network.vlan, null)
  }

  agent {
    enabled = true
  }

  initialization {
    datastore_id = var.vm.disk.datastore

    ip_config {
      ipv4 {
        address = try(var.vm.network.address, "dhcp")
        gateway = try(var.vm.network.gateway, null)
      }
    }
  }

  lifecycle {
    ignore_changes = [
      initialization
    ]
  }
}
