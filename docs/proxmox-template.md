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

## Defining Infrastructure

All VMs and containers are defined as `locals` in `terraform/main.tf`. Terraform iterates over them with `for_each` and passes each entry to the appropriate module.

### Adding a VM

VMs are defined under `local.vms`. There are two patterns:

**1. Clone from a defaults group** (e.g. `wp_hosts`):

```hcl
wp_hosts = {
  wp-host1 = {}        # uses all wp_host_defaults
  wp-host2 = {
    memory = 8192      # override a single field
  }
}
```

`wp_host_defaults` provides: 4 cores, 4096 MB RAM, 20 GB boot disk, two 40 GB extra disks, VLAN 200, DHCP.

**2. Define a standalone VM** (inline in the `vms` merge block):

```hcl
my-vm = {
  hostname = "my-vm"
  cores    = 2
  memory   = 4096

  disk = {
    size      = 20
    datastore = "local-ssd"
    format    = "qcow2"
  }

  network = {
    bridge  = "vmbr4"
    vlan    = 200
    address = "10.10.200.10/29"  # omit for DHCP
    gateway = "10.10.200.1"      # omit for DHCP
  }
}
```

All VMs are cloned from the template at `clone_vm_id` (default `9000`). The QEMU guest agent must be running in the template for IP reporting to work.

### Adding an LXC Container

Containers are defined under `local.containers`. Same two patterns apply:

**1. Clone from a defaults group** (e.g. `monitoring_hosts`):

```hcl
monitoring_hosts = {
  my-exporter = {}          # uses all monitoring_defaults
  prometheus   = {
    memory = 2048           # override a single field
  }
}
```

`monitoring_defaults` provides: 1 core, 1024 MB RAM, 8 GB disk, Ubuntu 24.04 template, VLAN 200, DHCP.

**2. Define a standalone container**:

```hcl
my-app = {
  hostname = "my-app"
  cores    = 2
  memory   = 1024
  disk     = 16
  template = local.ubuntu_template
  os_type  = "ubuntu"       # optional, defaults to "ubuntu"

  network = {
    bridge  = "vmbr4"
    vlan    = 200
    address = "10.10.200.20/29"  # omit for DHCP
    gateway = "10.10.200.1"      # omit for DHCP
  }
}
```

### Shared Template Reference

The Ubuntu template path is defined once as `local.ubuntu_template` and referenced by all containers:

```hcl
ubuntu_template = "local-ssd:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
```

To upgrade the template, change it in one place.

---

## Modules

### `proxmox_vm`

Clones a VM from a base template and applies CPU, memory, disk, and network configuration via cloud-init.

| Variable      | Type     | Description                        | Default |
|---------------|----------|------------------------------------|---------|
| `node_name`   | `string` | Target Proxmox node                | —       |
| `clone_vm_id` | `number` | VM ID to clone from                | `9000`  |
| `vm`          | `object` | Full VM config (see variables.tf)  | —       |

**Outputs:**

| Output           | Description                      |
|------------------|----------------------------------|
| `name`           | VM hostname as registered in PVE |
| `ipv4_addresses` | All IPv4 addresses from agent    |

**Notes:**
- The `initialization` block is in `ignore_changes` — cloud-init only runs on first creation. IP/hostname changes require destroy + recreate.
- `additional_disks` is optional and defaults to `[]`. Disks are attached as `scsi1`, `scsi2`, etc.

### `proxmox_lxc`

Creates an unprivileged LXC container with an injected SSH public key.

| Variable        | Type     | Description                              | Default       |
|-----------------|----------|------------------------------------------|---------------|
| `node_name`     | `string` | Target Proxmox node                      | —             |
| `datastore_id`  | `string` | Datastore for the container disk         | `"local-ssd"` |
| `ssh_public_key`| `string` | Path to SSH public key file              | —             |
| `container`     | `object` | Full container config (see variables.tf) | —             |

**Outputs:**

| Output     | Description                        |
|------------|------------------------------------|
| `hostname` | Container hostname                 |
| `ipv4`     | IPv4 addresses from the container  |

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
