resource "proxmox_virtual_environment_vm" "vm" {

  name      = var.vm.hostname
  node_name = var.node_name

  clone {
    vm_id = var.vm.clone_vm_id
  }

  cpu {
    cores = var.vm.cores
  }

  on_boot = var.vm.on_boot

  memory {
    dedicated = var.vm.memory
    floating  = var.vm.memory_floating
  }

  disk {
    datastore_id = var.vm.disk.datastore
    interface    = "scsi0"
    size         = var.vm.disk.size
    file_format  = var.vm.disk.format
    ssd          = true
  }

  dynamic "disk" {
    for_each = var.vm.additional_disks
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
    vlan_id = var.vm.network.vlan
  }

  agent {
    enabled = true
  }

  initialization {
    datastore_id = var.vm.disk.datastore

    ip_config {
      ipv4 {
        address = var.vm.network.address
        gateway = var.vm.network.gateway
      }
    }
  }

  lifecycle {
    ignore_changes = [
      initialization,
      started,
    ]
  }
}
