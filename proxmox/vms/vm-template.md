# Creating a VM Template on Proxmox (Flatcar + k3s)

## Why Cloud Images over ISO

- ISO = boot an installer, click through setup (like a physical machine)
- Cloud image (qcow2) = pre-built disk, import directly, configure on first boot
- No installer, boots in seconds, repeatable via cloning

## Workflow: Cloud Image → Template → Clone

### 1. Download Flatcar Image

In Proxmox web UI: `local` storage → **ISO Images** → **Download from URL**

```
https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_qemu_image.img.bz2
```

Decompress on the Proxmox host after download:
```bash
cd /var/lib/vz/template/iso
bunzip2 flatcar_production_qemu_image.img.bz2
```

### 2. Create VM & Import Disk

SSH into Proxmox host:

```bash
qm create 9000 --name flatcar-template --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0
qm importdisk 9000 /var/lib/vz/template/iso/flatcar_production_qemu_image.img local-lvm
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --serial0 socket --vga serial0
```

### 3. Configure First-Boot

Flatcar supports both Ignition and cloud-init. Proxmox's native cloud-init works for basics (SSH key, user).

Add a cloud-init drive:
```bash
qm set 9000 --ide2 local-lvm:cloudinit
```

Set SSH key and user via UI: VM → **Cloud-Init tab**

For anything beyond basics (e.g. auto-installing k3s on boot), pass a custom user-data file:
```bash
qm set 9000 --cicustom "user=local:snippets/flatcar-user-data.yaml"
```

### 4. Convert to Template

```bash
qm template 9000
```

Or UI: right-click VM → **Convert to Template** (VM becomes read-only, cloneable)

### 5. Clone for Each k3s Node

```bash
qm clone 9000 101 --name k3s-control --full
qm clone 9000 102 --name k3s-worker-1 --full
qm clone 9000 103 --name k3s-worker-2 --full
```

Start each clone — first-boot config runs automatically.

## Resource Allocation (8 GB host RAM)

| Node | Role | RAM | CPU |
|------|------|-----|-----|
| 101 | control plane | 2 GB | 2 |
| 102 | worker | 2 GB | 2 |
| 103 | worker | 2 GB | 2 |

Leaves ~2 GB for the Proxmox host itself.
