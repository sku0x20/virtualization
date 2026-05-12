# Step 1 — Create a VM via Proxmox UI

Goal: understand Proxmox's virtual hardware model by creating a VM manually through the UI.

Prefer cloud images over ISOs — they boot directly as pre-built disks with no installer step. The wizard still applies; disk is imported separately after VM creation (see step 3).

---

## Virtual Hardware Concepts

Before clicking through the wizard, understand what each piece is:

**vCPU**
A virtual CPU core assigned to the VM. Proxmox maps these to physical cores on the host.
- Type `host` passes through the host CPU's instruction set — best performance for Linux VMs.

**RAM**
Fixed allocation from the host. Balloon driver allows Proxmox to reclaim unused RAM from a running VM dynamically.

**Disk**
A virtual block device backed by host storage. Two formats matter:
- `raw` — flat file, fastest I/O
- `qcow2` — supports snapshots, copy-on-write, slightly more overhead
Proxmox uses `local-lvm` (thin-provisioned LVM) by default — good performance, supports snapshots.

**Network Bridge (vmbr0)**
A virtual switch on the host. VMs connect to `vmbr0` and appear on your LAN as if they're physical machines.
- NIC model `virtio` is paravirtualized — the VM knows it's virtual and uses an optimized driver. Always prefer this over emulated (e1000, rtl8139).

**Machine Type**
- `i440fx` — older chipset emulation, stable, broad compatibility
- `q35` — modern PCIe chipset, required for some features (NVMe, USB3, UEFI Secure Boot)

**BIOS**
- `OVMF` — UEFI firmware, enables GPT partition tables and modern boot. Preferred.
- `SeaBIOS` — legacy BIOS, MBR-only. Avoid for new VMs.

**SCSI Controller**
- `VirtIO SCSI` — paravirtualized, best disk throughput for Linux

---

## Create VM via UI

Right-click the node → **Create VM**

### General
| Field | Value |
|-------|-------|
| VM ID | any number (e.g. 101) |
| Name | descriptive (e.g. `flatcar-test`) |

### OS
| Field | Value |
|-------|-------|
| ISO Image | Do not use any media |
| Guest OS Type | Linux |
| Kernel version | 6.x - 2.6 Kernel |

### System
| Field | Value |
|-------|-------|
| Machine | q35 |
| BIOS | OVMF (UEFI) |
| EFI Disk | Add EFI disk → local-lvm, pre-enrolled keys off |
| SCSI Controller | VirtIO SCSI single |

### Disks
| Field | Value |
|-------|-------|
| Storage | local-lvm |
| Disk size | 20 GB |
| Cache | Write back |

### CPU
| Field | Value |
|-------|-------|
| Cores | 2 |
| Type | host |

### Memory
| Field | Value |
|-------|-------|
| Memory | 2048 MB |
| Ballooning | enabled |

### Network
| Field | Value |
|-------|-------|
| Bridge | vmbr0 |
| Model | VirtIO |

---

## Appendix: ISO Installation (e.g. Ubuntu Server)

Some distros (Ubuntu Server, Debian) ship a traditional installer ISO. Steps if you want to use that path:

1. Upload the ISO: `local` storage → **ISO Images** → **Upload** or **Download from URL**
2. In the OS step, select the uploaded ISO instead of "Do not use any media"
3. Boot the VM — the installer runs interactively, partitions the disk, and installs the OS

Not applicable for Flatcar or other cloud-image-only distros.
