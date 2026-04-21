# infra-terraform

Terraform IaC for provisioning a home lab on Proxmox VE. Terraform handles infrastructure provisioning; Ansible handles configuration management.

---

## Structure

```
terraform/
├── main.tf               # All VM and container definitions
├── providers.tf          # Provider config and version pins
├── variables.tf          # Root input variables
├── outputs.tf            # infra_summary output
├── ansible.tf            # Auto-generated Ansible inventory
├── docs/
│   └── proxmox-template.md  # Proxmox provisioning reference
└── modules/
    ├── proxmox_vm/       # Reusable module for Proxmox VMs
    └── proxmox_lxc/      # Reusable module for LXC containers
```

---

## Requirements

- Terraform >= 1.3
- Proxmox API token with VM/CT create permissions
- A base VM template at ID `9000` on the target node

---

## Quick Start

Create a `terraform.tfvars`:

```hcl
proxmox_endpoint  = "https://<proxmox-ip>:8006"
proxmox_api_token = "root@pam!terraform=<token>"
proxmox_node      = "pve1"
proxmox_host_ip   = "172.16.1.8"
```

Then:

```bash
terraform init
terraform plan
terraform apply
```

The Ansible inventory is written to `/opt/infra/ansible/inventory/lab/hosts` automatically on apply.

---

## Proxmox Provisioning

For full details on adding VMs and containers, module inputs/outputs, and design decisions, see [docs/proxmox-template.md](docs/proxmox-template.md).

---

## k3s Cluster

The k3s cluster is provisioned as VMs on VLAN 200:

| Host | IP | Role |
|------|----|------|
| k3s-control | 10.10.200.60 | Control plane |
| k3s-worker1 | 10.10.200.61 | Worker |
| k3s-worker2 | 10.10.200.62 | Worker |
| k3s-worker3 | 10.10.200.63 | Worker |
| k3s-worker4 | 10.10.200.64 | Worker |

All k3s VMs have `on_boot = false` — start manually.

The control node's `/home/infra/manifests` is mounted on the infra server via sshfs so manifests can be edited through VSCode Remote SSH:

```
# /etc/fstab on infra-server
k3s-control:/home/infra/manifests  /opt/infra/k3s-control/manifests  fuse.sshfs  noauto,x-systemd.automount,_netdev,reconnect,uid=1000,gid=1000,IdentityFile=/home/infra/.ssh/id_rsa  0  0
```

---

## Security

`*.tfvars` and `*.tfstate` are excluded by `.gitignore`. Never commit API tokens or state files.

State is stored **locally** — back up `terraform.tfstate` before major changes. Losing the state file means manually running `terraform import` for every resource.
