# Homelab: Proxmox + k3s

Documenting the setup of a homelab on spare hardware.

**Stack:** Proxmox VE (bare metal hypervisor) → Ubuntu VMs → k3s (lightweight Kubernetes)

---

## Phase 1: Proxmox Installation

### 1.1 Prepare Bootable USB with Ventoy

[Ventoy](https://www.ventoy.net) lets you boot multiple ISOs from a single USB drive — no re-flashing needed.

**Steps:**
1. Download Ventoy and install it onto your USB drive (this formats the USB)
2. Download the [Proxmox VE ISO](https://www.proxmox.com/en/downloads)
3. Copy the `.iso` file onto the Ventoy USB drive (just drag and drop)
4. Boot the target machine from the USB → Ventoy menu appears → select the Proxmox ISO

### 1.2 Install Proxmox

1. Boot from USB, select Proxmox VE ISO in Ventoy
2. Follow the installer:
   - Select target disk
   - Set country/timezone
   - Set root password + email
   - Configure network: set a static IP (e.g. `192.168.1.50`), gateway, DNS
3. Reboot, remove USB

### 1.3 Access Web UI

- Open browser: `https://<proxmox-ip>:8006`
- Login: `root` + password set during install
- Dismiss the "no subscription" popup (expected for free tier)

---

## Phase 2: VMs for k3s

_TODO_

---

## Phase 3: k3s Installation

_TODO_

---

## Phase 4: kubectl from Laptop

_TODO_
