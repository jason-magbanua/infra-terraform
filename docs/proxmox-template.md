# Proxmox VM & LXC Provisioning

Terraform provisions Proxmox VMs and LXC containers via the [`bpg/proxmox`](https://registry.terraform.io/providers/bpg/proxmox/latest/docs) provider. All infrastructure is defined in `terraform/main.tf` and deployed through two reusable modules.

---

## Directory Structure

```
terraform/
├── main.tf               # All VM and container definitions
├── providers.tf          # Provider config and version pins
├── variables.tf          # Root input variables (endpoint, token, node)
├── outputs.tf            # infra_summary output (name → IP map)
├── ansible.tf            # Ansible inventory generated from provisioned IPs
└── modules/
    ├── proxmox_vm/       # Reusable module for Proxmox VMs
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── proxmox_lxc/      # Reusable module for LXC containers
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

---

## Prerequisites

- Terraform >= 1.3 (required for `optional()` typed variables)
- Proxmox API token with VM/CT create permissions
- A base VM template at ID `9000` on the target node (for VM cloning)
- Ubuntu LXC template available at `local-ssd:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst`
- SSH keypair at `~/.ssh/id_rsa_ansible` / `~/.ssh/id_rsa_ansible.pub`

---

## Configuration

### Variables

| Variable             | Description                              | Default |
|----------------------|------------------------------------------|---------|
| `proxmox_endpoint`   | URL of the Proxmox API endpoint          | —       |
| `proxmox_api_token`  | Proxmox API token (sensitive)            | —       |
| `proxmox_node`       | Node name where resources are created    | `pve1`  |

Set these via a `terraform.tfvars` file or environment variables (`TF_VAR_*`).

Example `terraform.tfvars`:
```hcl
proxmox_endpoint  = "https://172.16.1.8:8006"
proxmox_api_token = "root@pam!terraform=<token>"
proxmox_node      = "pve1"
```

---

## Network

| Local        | Value             | Description                     |
|--------------|-------------------|---------------------------------|
| `local.gw`   | `10.10.200.1`     | Default gateway for VLAN 200    |
| `local.lxc_net` | `{ bridge = "vmbr1", vlan = 200 }` | Default container network |

**Subnet:** `10.10.200.0/24`
**Static range:** `.2` – `.100`
**DHCP range:** `.101` – `.200`

### IP Allocations

| IP               | Host             | Type      |
|------------------|------------------|-----------|
| 10.10.200.1      | gateway (VyOS)   | —         |
| 10.10.200.3      | jump-host        | LXC       |
| 10.10.200.4      | apt-cacher-ng    | LXC       |
| 10.10.200.10     | traefik          | LXC       |
| 10.10.200.20     | prometheus       | LXC       |
| 10.10.200.21     | alertmanager     | LXC       |
| 10.10.200.22     | grafana          | LXC       |
| 10.10.200.23     | loki             | LXC       |
| 10.10.200.24     | alloy            | LXC       |
| 10.10.200.30     | postgresql       | LXC       |
| 10.10.200.31     | redis            | LXC       |
| 10.10.200.40     | hashicorp-vault  | LXC       |
| 10.10.200.41     | vaultwarden      | Docker    |
| 10.10.200.42     | authentik        | Docker    |
| 10.10.200.43     | wiki.js          | Docker    |
| 10.10.200.50     | docker-host      | VM        |

---

## Defining Infrastructure

All VMs and containers are defined as `locals` in `terraform/main.tf`. Terraform uses `for_each` to iterate over them and pass each entry to the appropriate module.

The **hostname** is always derived from the map key — do not set it explicitly.

### Adding a VM

Add an entry to `local._vms`. The `hostname` is injected automatically from the key.

```hcl
_vms = {
  my-vm = {
    cores  = 2
    memory = 4096
    disk   = { size = 20, datastore = "local-ssd", format = "qcow2" }

    # Static IP:
    network = { bridge = "vmbr1", vlan = 200, address = "10.10.200.X/24", gateway = local.gw }

    # DHCP (omit address and gateway):
    # network = { bridge = "vmbr1", vlan = 200 }

    # Optional — extra disks attached as scsi1, scsi2, ...:
    # additional_disks = [
    #   { size = 40, datastore = "local-ssd", format = "qcow2" },
    # ]
  }
}
```

All VMs are cloned from the template at `clone_vm_id` (default `9000`). The QEMU guest agent must be running in the template for IP reporting to work.

### Adding an LXC Container

Add an entry to `local._containers`. The **hostname** and **template** (`ubuntu-24.04`) are injected automatically. The **bridge** and **vlan** come from `local.lxc_net` and don't need to be specified.

```hcl
_containers = {
  my-app = {
    cores  = 1
    memory = 512
    disk   = 8

    # Static IP:
    network = { address = "10.10.200.X/24", gateway = local.gw }

    # DHCP (omit network entirely, or use network = {}):
  }
}
```

To override the template or OS type for a specific container:

```hcl
my-app = {
  cores    = 1
  memory   = 512
  disk     = 8
  template = "local-ssd:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst"
  os_type  = "debian"
  network  = { address = "10.10.200.X/24", gateway = local.gw }
}
```

---

## Modules

### `proxmox_vm`

Clones a VM from a base template and applies CPU, memory, disk, and network configuration via cloud-init.

| Variable      | Type     | Description                        | Default |
|---------------|----------|------------------------------------|---------|
| `node_name`   | `string` | Target Proxmox node                | —       |
| `clone_vm_id` | `number` | VM ID to clone from                | `9000`  |
| `vm`          | `object` | Full VM config (see variables.tf)  | —       |

**`vm` object fields:**

| Field              | Type     | Required | Default  | Description                        |
|--------------------|----------|----------|----------|------------------------------------|
| `hostname`         | `string` | yes      | —        | Injected from map key in `main.tf` |
| `cores`            | `number` | yes      | —        |                                    |
| `memory`           | `number` | yes      | —        | MB                                 |
| `disk`             | `object` | yes      | —        | `size`, `datastore`, `format`      |
| `additional_disks` | `list`   | no       | `[]`     | Attached as `scsi1`, `scsi2`, …    |
| `network.bridge`   | `string` | yes      | —        |                                    |
| `network.vlan`     | `number` | no       | —        |                                    |
| `network.address`  | `string` | no       | `"dhcp"` | CIDR notation e.g. `10.0.0.2/24`  |
| `network.gateway`  | `string` | no       | —        |                                    |

**Notes:**
- The `initialization` block is in `ignore_changes` — cloud-init only runs on first creation. IP/hostname changes require destroy + recreate.

### `proxmox_lxc`

Creates an unprivileged LXC container with an injected SSH public key.

| Variable         | Type     | Description                              | Default       |
|------------------|----------|------------------------------------------|---------------|
| `node_name`      | `string` | Target Proxmox node                      | —             |
| `datastore_id`   | `string` | Datastore for the container disk         | `"local-ssd"` |
| `ssh_public_key` | `string` | Path to SSH public key file              | —             |
| `container`      | `object` | Full container config (see variables.tf) | —             |

**`container` object fields:**

| Field              | Type     | Required | Default     | Description                          |
|--------------------|----------|----------|-------------|--------------------------------------|
| `hostname`         | `string` | yes      | —           | Injected from map key in `main.tf`   |
| `cores`            | `number` | yes      | —           |                                      |
| `memory`           | `number` | yes      | —           | MB                                   |
| `disk`             | `number` | yes      | —           | GB                                   |
| `template`         | `string` | yes      | —           | Injected from `local.ubuntu_template`|
| `os_type`          | `string` | no       | `"ubuntu"`  |                                      |
| `network.bridge`   | `string` | yes      | —           | Injected from `local.lxc_net`        |
| `network.vlan`     | `number` | no       | —           | Injected from `local.lxc_net`        |
| `network.address`  | `string` | no       | `"dhcp"`    | CIDR notation e.g. `10.0.0.2/24`    |
| `network.gateway`  | `string` | no       | —           |                                      |

**Notes:**
- Containers run unprivileged with `nesting = true` (required for Docker inside LXC).
- `swap = 0` — swap is disabled on all containers.
- The `initialization` block is in `ignore_changes` for the same reason as VMs.
- `ssh_public_key` supports `~` expansion via `pathexpand()`.

---

## Ansible Integration

After `terraform apply`, an Ansible inventory is written to `/opt/infra/ansible/inventory/lab/hosts`. It is generated automatically from the provisioned IPs using the `local_file` resource in `ansible.tf`.

To change Ansible connection defaults (user, key path, Proxmox host IP), edit the locals at the top of `ansible.tf`:

```hcl
locals {
  ansible_user         = "infra"
  ansible_ssh_key      = "~/.ssh/id_rsa_ansible"
  proxmox_host_ip      = "172.16.1.8"
  proxmox_root_ssh_key = "~/.ssh/root-sshkey.rsa"
}
```

---

## Usage

```bash
cd terraform/

# First time
terraform init

# Preview changes
terraform plan

# Apply
terraform apply

# Inspect IPs
terraform output infra_summary
```

---

## Notes & Caveats

- **TLS verification is disabled** (`insecure = true` in `providers.tf`). This is acceptable for a homelab with a self-signed cert but should be replaced with proper cert trust in any shared environment.
- **No remote state backend** is configured — state is stored locally. If the machine running Terraform is itself managed by Terraform, losing the state file means manual `terraform import` for every resource.
- The `proxmox_node` variable defaults to `pve1`. If you add a second node, you'll need to parameterise the module calls or duplicate them.
