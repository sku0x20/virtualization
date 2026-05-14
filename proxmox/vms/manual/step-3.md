# Step 3 — Create a VM from a Cloud/QEMU Image

Skip the ISO installer entirely. Import a pre-built disk image, configure via cloud-init, boot directly.

---

## Why Cloud Images

- No installer — the disk is already set up
- Boot in seconds
- Configure SSH keys, hostname, network via cloud-init before first boot
- Cloneable into templates (see step 5)

---

## Image Types

"QEMU image" just means the file format (`.img` / `.qcow2`) — not a category. What matters is what's baked inside.

| Type | Example | What's inside | Best for |
|------|---------|---------------|----------|
| **Generic QEMU** | `flatcar_production_qemu_image.img` | Bare OS, no hypervisor tuning | Any KVM hypervisor |
| **Cloud image** | `noble-server-cloudimg-amd64.img` | Generic QEMU + cloud-init pre-installed | Ubuntu, Debian on any cloud/hypervisor |

**Preference:** Cloud image if the distro ships one (Ubuntu, Debian). Generic QEMU otherwise (Flatcar, Alpine, etc.).

---

## Steps

### Via UI

**1. Download**

`local` storage → **Import** → **Download from URL** → paste the image URL → Download.

**2. Create VM**

Follow the step-1 wizard. In the OS step, select **Do not use any media**.

**3. Attach Disk**

VM → **Hardware** → **Add** → **Import Disk** → select the downloaded image → Storage: `local-lvm` → **Import**.

The disk appears as Unused Disk 0. Click it → **Edit** → confirm it's on `scsi0`.

**4. Set Boot Order**

VM → **Options** → **Boot Order** → enable `scsi0`, disable others.

**5. Add Cloud-Init Drive**

VM → **Hardware** → **Add** → **CloudInit Drive** → Storage: `local-lvm` → **Add**.

**6. Configure Cloud-Init**

VM → **Cloud-Init** tab → set SSH key, user, IP (DHCP) → **Regenerate Image**.

**7. Start**

VM → **Start** button.

---

### Via CLI

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

qm disk import $VM_ID noble-server-cloudimg-amd64.img local-lvm
qm set $VM_ID --scsi0 local-lvm:vm-$VM_ID-disk-0
qm set $VM_ID --scsihw virtio-scsi-pci
qm set $VM_ID --boot order=scsi0
qm set $VM_ID --ide2 local-lvm:cloudinit
qm start $VM_ID
```

---

## UI Import vs CLI Import — Disk Size

`qm disk import` (CLI) converts the source image to raw format and expands it to the full virtual disk size (e.g. 400 MB qcow2 → 12 GB raw). This is correct for `local-lvm`, which is an LVM thin pool expecting raw volumes.

UI "Import Disk" keeps the original format (stays at 400 MB). LVM storage may not boot from a thin qcow2 file. **Prefer CLI import for `local-lvm`.**

## `qm disk import` vs `qm importdisk`

`qm disk import` is the current command. `qm importdisk` is deprecated — don't use it.
