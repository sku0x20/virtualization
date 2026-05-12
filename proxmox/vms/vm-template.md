# Creating a VM Template on Proxmox (Flatcar + k3s)

## Why Cloud Images over ISO

- ISO = boot an installer, click through setup (like a physical machine)
- Cloud image (qcow2) = pre-built disk, import directly, configure on first boot
- No installer, boots in seconds, repeatable via cloning

## Workflow: Cloud Image → Template → Clone

### 1. Download Flatcar Image

Flatcar ships a Proxmox-specific image (no decompression needed).
Download directly on the Proxmox host:

```bash
wget https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_proxmoxve_image.img
```

### 2. Create VM & Import Disk

Proxmox UI only supports ISO images — VM creation must be done via CLI:

```bash
export VM_ID=9000

qm create $VM_ID --name flatcar-template --cores 2 --memory 2048 \
  --net0 "virtio,bridge=vmbr0" --ipconfig0 "ip=dhcp"

qm disk import $VM_ID flatcar_production_proxmoxve_image.img local-lvm

qm set $VM_ID --scsi0 local-lvm:vm-$VM_ID-disk-0
qm set $VM_ID --boot order=scsi0

# Required even for Ignition config
qm set $VM_ID --ide2 local-lvm:cloudinit
```

### 3. Configure First-Boot

Pick **one** — Ignition and cloud-init share the same `user-data` slot and can't coexist.

**Option A: cloud-init (basic — SSH key, hostname, network)**
Set via UI: VM → Cloud-Init tab

**Option B: Ignition (full control — systemd units, files, k3s install)**

Create `/var/lib/vz/snippets/user-data`:
```json
{
  "ignition": { "version": "3.0.0" },
  "passwd": {
    "users": [{
      "name": "core",
      "sshAuthorizedKeys": ["ssh-ed25519 your-public-ssh-key"]
    }]
  }
}
```

Apply:
```bash
qm set $VM_ID --cicustom "user=local:snippets/user-data"
```

Note: cloud-init services will log failures when Ignition is used — expected, harmless.

### 4. Convert to Template

```bash
qm template $VM_ID
```

Or UI: right-click VM → **Convert to Template**

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

## Reference

https://www.flatcar.org/docs/latest/installing/community-platforms/proxmoxve/
