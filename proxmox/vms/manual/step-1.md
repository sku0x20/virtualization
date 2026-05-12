# Step 1 — Create a VM via Proxmox UI (ISO)

Goal: understand Proxmox's virtual hardware model by creating a VM manually through the UI.

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
- `SeaBIOS` — legacy BIOS, simpler, works for most Linux
- `OVMF` — UEFI firmware, required for Secure Boot or Windows

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
| ISO Image | select uploaded ISO |
| Guest OS Type | Linux |
| Kernel version | 6.x - 2.6 Kernel |

### System
| Field | Value |
|-------|-------|
| Machine | q35 |
| BIOS | SeaBIOS |
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

## Upload an ISO

`local` storage → **ISO Images** → **Upload** (from your machine)
or **Download from URL** (fetches directly on the Proxmox host — faster).

---

## Notes on Flatcar + ISO

Flatcar does not ship a traditional click-through installer ISO.
This step is for learning the Proxmox UI. The production workflow (step 3) uses a pre-built disk image instead.

If you want to explore the ISO path anyway, Flatcar provides a rescue ISO — you boot it, then run `flatcar-install` to write the OS onto the disk manually.
