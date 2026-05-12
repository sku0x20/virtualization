# Step 3 — Create a VM from a Cloud/QEMU Image

Skip the ISO installer entirely. Import a pre-built disk image, configure via cloud-init, boot directly.

---

## Why Cloud Images

- No installer — the disk is already set up
- Boot in seconds
- Configure SSH keys, hostname, network via cloud-init before first boot
- Cloneable into templates (see step 5)

---

## Option A: Generic QEMU Image (any distro)

Use this for Ubuntu, Debian, Alpine, etc.

### 1. Download

On the Proxmox host:
```bash
wget https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img
# or Debian:
wget https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2
```

### 2. Create VM

```bash
export VM_ID=101

qm create $VM_ID \
  --name my-vm \
  --cores 2 \
  --memory 2048 \
  --net0 "virtio,bridge=vmbr0" \
  --ipconfig0 "ip=dhcp" \
  --serial0 socket \
  --vga serial0
```

### 3. Import Disk

```bash
qm disk import $VM_ID noble-server-cloudimg-amd64.img local-lvm
qm set $VM_ID --scsi0 local-lvm:vm-$VM_ID-disk-0
qm set $VM_ID --scsihw virtio-scsi-pci
qm set $VM_ID --boot order=scsi0
```

### 4. Add Cloud-Init Drive

```bash
qm set $VM_ID --ide2 local-lvm:cloudinit
```

Set SSH key, user, IP via UI: VM → **Cloud-Init tab** → Regenerate Image.

### 5. Start

```bash
qm start $VM_ID
```

---

## Option B: Proxmox-Specific Flatcar Image ★

Flatcar ships a purpose-built Proxmox image — no SCSI/VGA tweaks needed, works out of the box.

### 1. Download

```bash
wget https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_proxmoxve_image.img
```

### 2. Create VM & Import

```bash
export VM_ID=101

qm create $VM_ID \
  --name flatcar-test \
  --cores 2 \
  --memory 2048 \
  --net0 "virtio,bridge=vmbr0" \
  --ipconfig0 "ip=dhcp"

qm disk import $VM_ID flatcar_production_proxmoxve_image.img local-lvm

qm set $VM_ID --scsi0 local-lvm:vm-$VM_ID-disk-0
qm set $VM_ID --boot order=scsi0
qm set $VM_ID --ide2 local-lvm:cloudinit   # required even for Ignition
```

### 3. Set SSH Key

UI: VM → **Cloud-Init tab** → paste public key → **Regenerate Image**

### 4. Start

```bash
qm start $VM_ID
```

### 5. SSH In

Default user on Flatcar is `core`:
```bash
ssh core@<vm-ip>
```

---

## `qm disk import` vs `qm importdisk`

`qm disk import` is the current command. `qm importdisk` is deprecated — don't use it.

## Ref

https://www.flatcar.org/docs/latest/installing/community-platforms/proxmoxve/
