# Choosing an OS Image for k3s VMs

## Requirements

- Lightweight, minimal footprint
- Proxmox-friendly (cloud image available)
- Works well with k3s
- Non-systemd preferred

## Decision

**Alpine Linux**

- Non-systemd (OpenRC) — no bloat
- ~130 MB base, genuinely minimal
- k3s installs cleanly, no workarounds needed
- Fast to boot in a VM
- Large docs/community for k3s on Alpine

## Why not immutable OS (Flatcar, CoreOS, MicroOS)

Immutable OSes are designed for **ops at scale** — large fleets where you can't trust humans touching nodes, or edge devices you can't physically reach. The benefits are:

- Atomic updates with rollback (no bricking remote devices)
- Guaranteed identical nodes across a fleet (no config drift)
- Read-only OS partition (malware can't persist across reboots)

For a homelab k3s cluster on Proxmox, this is overkill. k3s writes binaries, CNI plugins, and config to the OS partition (`/usr/local/bin`, `/etc/rancher`, `/opt/cni/bin`). Immutable OSes make this painful — workarounds exist but add friction to updates, debugging, and adding packages.

## Does kubectl work without systemd?

Yes. kubectl is a CLI that talks to the Kubernetes API over HTTP — it has no dependency on systemd. k3s manages its own process supervision and integrates with OpenRC on Alpine. kubectl works identically regardless of init system.

## Previous candidates considered (dropped)

| OS | Reason dropped |
|----|----------------|
| Flatcar Container Linux | Immutable, systemd-based, k3s needs workarounds |
| Fedora CoreOS | Immutable, systemd, aggressive release cycle |
| openSUSE MicroOS | Immutable, systemd, transactional-update friction |
| Kairos | No pre-built qcow2, newer/less mature project |
| K3OS | Archived and unmaintained by Rancher — do not use |
