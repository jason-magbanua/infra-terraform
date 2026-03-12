# Proxmox Ubuntu Cloud Template

This document explains how to prepare the **Ubuntu 24.04 LTS cloud image template** used by Terraform in this repository.

All virtual machines are cloned from this template using the `bpg/proxmox` Terraform provider.

The template only needs to be prepared **once**.

---

# Overview

Terraform provisions infrastructure using this workflow:

```
Ubuntu Cloud Image
        ↓
Proxmox Template (VM 9000)
        ↓
Terraform clone
        ↓
Cloud-init configuration
        ↓
VM ready for Ansible
```

The template provides:

- Ubuntu 24.04 LTS base system
- cloud-init support
- QEMU guest agent
- SSH access for the `infra` user
- DHCP networking

---

# Step 1 — Download Ubuntu Cloud Image

Download the Ubuntu cloud image from the official Ubuntu servers.

```bash
wget https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img \
  -O /mnt/ssd_1T/vz/template/iso/noble-server-cloudimg-amd64.img
```

---

# Step 2 — Create the Base VM

Create the VM that will later become the template.

```bash
qm create 9000 \
  --name template-ubuntu-2404 \
  --memory 1024 \
  --cores 1 \
  --cpu x86-64-v2-AES \
  --machine q35 \
  --net0 virtio,bridge=vmbr4,tag=200 \
  --serial0 socket \
  --vga serial0 \
  --agent enabled=1
```

Explanation:

- **VM ID `9000`** will be used by Terraform as the clone source
- **q35 machine type** provides modern PCIe virtualization
- **serial console** is recommended for cloud images
- **QEMU guest agent** allows Terraform to detect VM IP addresses

---

# Step 3 — Import the Cloud Image Disk

Import the downloaded Ubuntu image into Proxmox storage.

```bash
qm importdisk 9000 \
  /mnt/ssd_1T/vz/template/iso/noble-server-cloudimg-amd64.img \
  local-ssd \
  --format qcow2
```

Attach the imported disk to the VM:

```bash
qm set 9000 --scsihw virtio-scsi-pci
qm set 9000 --scsi0 local-ssd:9000/vm-9000-disk-0.qcow2,discard=on,ssd=1
```

Why virtio-scsi?

- better performance
- discard/TRIM support
- recommended for Linux guests

---

# Step 4 — Enable Cloud-Init

Attach the cloud-init drive.

```bash
qm set 9000 --ide2 local-ssd:cloudinit
qm set 9000 --boot order=scsi0
```

This enables Terraform to configure the VM during boot.

---

# Step 5 — Configure Default Cloud-Init Settings

Set the default login user and SSH key.

```bash
qm set 9000 --ciuser infra
qm set 9000 --cipassword 'VerySecurePassword'
qm set 9000 --sshkey ~/.ssh/id_rsa_ansible.pub
qm set 9000 --ciupgrade 0
qm set 9000 --ipconfig0 ip=dhcp
```

Explanation:

| Setting | Purpose |
|--------|--------|
| ciuser | default cloud-init user |
| sshkey | injects SSH public key |
| ipconfig0 | DHCP networking |
| ciupgrade | disables automatic package upgrades |

Terraform and Ansible will connect using the **infra user**.

---

# Step 6 — Convert the VM to a Template

Convert the VM into a reusable template.

```bash
qm template 9000
```

Terraform will now clone VMs from this template.

---

# Verify Template Configuration

Run:

```bash
qm config 9000
```

Expected configuration should include:

```
agent: enabled=1
ide2: local-ssd:cloudinit
scsi0: local-ssd:9000/vm-9000-disk-0.qcow2
```

---

# How Terraform Uses This Template

Terraform clones the template using:

```hcl
clone {
  vm_id = 9000
}
```

Cloud-init then applies configuration such as:

- networking
- SSH access
- hostname
- system initialization

---

# Result

Every VM created from this template will:

- boot with **cloud-init enabled**
- allow SSH login using **infra**
- obtain an IP address via **DHCP**
- support the **QEMU guest agent**

This provides a reliable base for Terraform and Ansible automation.

---

# Important Notes

- Template ID **9000 must remain constant**
- Updating the template does **not update existing VMs**
- Always verify SSH access before converting to template
- Avoid modifying the template frequently once infrastructure is deployed
