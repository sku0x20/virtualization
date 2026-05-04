# Proxmox Installation

## Why Proxmox/virtualization?
- to virtualize hardware
- to run multiple OSes on a single machine
- decoupled compute and ram
- decoupled storage and network
- test different k8s distributions, different storage strategies.

## 1. Prepare Bootable USB with Ventoy

[Ventoy](https://www.ventoy.net) lets you boot multiple ISOs from a single USB drive — no re-flashing needed.

1. Download Ventoy and install it onto your USB drive (this formats the USB)
2. Download the [Proxmox VE ISO](https://www.proxmox.com/en/downloads)
3. Copy the `.iso` file onto the Ventoy USB (drag and drop)
4. Boot the target machine from USB → Ventoy menu → select Proxmox ISO

> Disable Secure Boot in BIOS before booting.

## 2. Install Proxmox

1. Follow the installer:
   - Select target disk
   - Set country/timezone
   - Set root password + email
   - Configure network: set a static IP (e.g. `192.168.1.50`), gateway, DNS
2. Reboot, remove USB

## 3. Access Web UI

- Open browser: `https://<proxmox-ip>:8006`
- Login: `root` + password set during install
- Dismiss the "no subscription" popup (expected for free tier)
