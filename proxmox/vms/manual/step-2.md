# Step 2 — Create a VM via CLI (qm commands)

Same as step 1 but entirely from the command line. SSH into the Proxmox host first.

Prefer cloud images — no ISO or installer needed. Disk is imported separately after VM creation (see step 3).

---

## Core Tool: `qm`

`qm` is the Proxmox CLI for managing QEMU/KVM VMs.

```
qm create <vmid>     — create a new VM
qm set <vmid>        — modify VM config
qm start <vmid>      — start VM
qm stop <vmid>       — stop VM (hard)
qm shutdown <vmid>   — graceful shutdown
qm status <vmid>     — show running state
qm terminal <vmid>   — attach to serial console
qm destroy <vmid>    — delete VM
```

---

## Create a VM

```bash
export VM_ID=101

qm create $VM_ID \
  --name flatcar-test \
  --cores 2 \
  --memory 2048 \
  --machine q35 \
  --bios ovmf \
  --net0 "virtio,bridge=vmbr0"
```

## Add an EFI Disk

Required when using OVMF. Proxmox stores UEFI vars (boot order, Secure Boot state) here.

```bash
qm set $VM_ID --efidisk0 local-lvm:1,efitype=4m,pre-enrolled-keys=0
```

## Add a Disk

```bash
qm set $VM_ID --scsi0 local-lvm:20   # creates a new 20 GB LVM volume
qm set $VM_ID --scsihw virtio-scsi-pci
```

## Configure CPU and Memory

```bash
qm set $VM_ID --cpu host
qm set $VM_ID --balloon 1            # enable memory ballooning
```

## Start and Connect

```bash
qm start $VM_ID
qm status $VM_ID

# attach to serial console (works for VMs with --serial0 socket)
qm terminal $VM_ID
```

Press `Ctrl+O` to detach from the terminal.

## Inspect Config

```bash
qm config $VM_ID          # show full VM config
cat /etc/pve/qemu-server/$VM_ID.conf   # same, as raw file
```

---

## Useful Flags Reference

| Flag | Example | Meaning |
|------|---------|---------|
| `--cores` | `2` | vCPU count |
| `--memory` | `2048` | RAM in MB |
| `--machine` | `q35` | chipset type |
| `--bios` | `ovmf` | UEFI firmware (enables GPT) |
| `--efidisk0` | `local-lvm:1,efitype=4m,pre-enrolled-keys=0` | EFI var store (required for OVMF) |
| `--cpu` | `host` | CPU model (pass-through) |
| `--net0` | `virtio,bridge=vmbr0` | first NIC |
| `--scsi0` | `local-lvm:20` | first SCSI disk |
| `--boot` | `order=scsi0` | boot device order |
| `--serial0` | `socket` | serial console (needed for cloud images) |
| `--vga` | `serial0` | redirect VGA to serial |

---

## Appendix: ISO Installation (e.g. Ubuntu Server)

If using a traditional installer ISO instead of a cloud image:

```bash
qm set $VM_ID --ide2 local:iso/ubuntu-server.iso,media=cdrom
qm set $VM_ID --boot order=ide2
```

Boot the VM — the installer runs interactively. Not applicable for Flatcar or other cloud-image-only distros.
