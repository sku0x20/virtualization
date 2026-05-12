# Choosing an OS Image for k3s VMs

## Requirements

- Lightweight, minimal footprint
- Immutable (no package manager, container-first)
- Proxmox-friendly (qcow2 cloud image available)
- Works well with k3s

## Candidates

| OS | Image download | Disk (provisioned) | Min RAM | Provisioning |
|----|---------------|-------------------|---------|-------------|
| **Flatcar Container Linux** | ~477 MB | ~20 GB | 2 GB | Ignition |
| **Fedora CoreOS** | varies (compressed) | ~10 GB | 1 GB (2 GB rec) | Ignition |
| **openSUSE MicroOS** | ~518 MB | not documented | 1 GB | Combustion |
| **Kairos** | no pre-built qcow2 | 8–40 GB (flavor-dependent) | 2 GB | cloud-init |

## Notes

- **Flatcar** — most mature, strongest k3s community, conservative release cycle
- **Fedora CoreOS** — smallest provisioned disk, lowest min RAM, but aggressive ~2 week release cycle
- **openSUSE MicroOS** — transactional package support if needed, shell-script provisioning (easier than Ignition JSON)
- **Kairos** — pre-bundles k3s, Proxmox docs exist, but newer project and no pre-built qcow2

## Provisioning: Ignition vs cloud-init

Flatcar and CoreOS use **Ignition** — runs in initramfs *before* the OS boots, one-time only. Can inject systemd units, SSH keys, k3s install script before first boot. Different from cloud-init (which runs in userspace after boot).

## K3OS

Rancher built K3OS as a purpose-built OS for k3s. It is now **archived and unmaintained** — do not use.

## Decision

**Flatcar Container Linux** — host has 8 GB RAM, stability preferred over minimum footprint.
3-node k3s cluster (1 control + 2 workers) at 2 GB each = 6 GB, leaves ~2 GB for Proxmox host.
