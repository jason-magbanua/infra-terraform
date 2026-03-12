# infra-terraform

Terraform Infrastructure-as-Code for provisioning Proxmox VMs, LXC containers, and multi-cloud resources (GCP, OCI, AWS).

This repository contains Terraform configurations used to provision and manage infrastructure for a home lab environment. It focuses on maintaining a simple, modular, and data-driven Infrastructure-as-Code structure that can grow as the infrastructure expands.

Terraform is responsible for **infrastructure provisioning**, while configuration management is handled separately using Ansible.

---

## Infrastructure Providers

Current and planned providers supported in this repository:

- Proxmox VE (VMs and LXC containers)
- Google Cloud Platform (GCP) *(future)*
- Oracle Cloud Infrastructure (OCI) *(future)*
- Amazon Web Services (AWS) *(future)*

---

## Repository Structure

Example layout:

```
infra-terraform/
├── modules/        # Reusable Terraform modules
├── providers/      # Provider configurations
├── environments/   # Environment-specific infrastructure
├── scripts/        # Helper scripts used by Terraform
├── main.tf         # Root Terraform configuration
├── variables.tf
├── outputs.tf
└── README.md
```

This structure keeps infrastructure modular and easier to scale as new environments or providers are added.

---

## Design Principles

This repository follows several key principles:

- Data-driven infrastructure definitions
- Avoid unnecessary complexity
- Easy to maintain and expand
- Clear separation of infrastructure provisioning and configuration management

Terraform provisions infrastructure resources such as VMs, containers, disks, and networks.

---

## Requirements

Required tools:

- Terraform (>= 1.14)
- Access credentials for infrastructure providers
- SSH access where required

---

## Usage

Initialize Terraform:

```
terraform init
```

Preview planned changes:

```
terraform plan
```

Apply infrastructure changes:

```
terraform apply
```

---

## Security

Sensitive data such as API tokens and credentials should **not be committed to the repository**.

Use local variable files such as:

```
secrets.auto.tfvars
```

Ensure these files are excluded from version control using `.gitignore`.

---

## Future Goals

Planned improvements include:

- Multi-cloud infrastructure support
- Kubernetes cluster provisioning
- Additional reusable Terraform modules
- Infrastructure automation pipelines

---

## License

This project is licensed under the MIT License.
