output "infra_summary" {
  description = "Short infrastructure overview"

  value = {
    vms = {
      for name, vm in module.vms :
      name => try(
        [for ip in flatten(vm.ipv4_addresses) : ip if ip != "127.0.0.1"][0],
        null
      )
    }

    containers = {
      for name, ct in module.containers :
      name => try(
        [for ip in ct.ipv4 : ip if ip != "127.0.0.1"][0],
        null
      )
    }
  }
}
