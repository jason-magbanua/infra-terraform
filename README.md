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

## Security

`*.tfvars` and `*.tfstate` are excluded by `.gitignore`. Never commit API tokens or state files.
