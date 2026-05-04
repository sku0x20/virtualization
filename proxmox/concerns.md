# Proxmox Concerns & Open Questions

## Network Setup

- **Plan:** Reinstall with static IPv4 only, clear all IPv6 fields during install

## Self-Signed Certificate

- Proxmox generates a self-signed cert at install — browser will warn on every access
- For now: accept the browser exception
- Later: domain already points to the node (IPv6) — can use Let's Encrypt via Proxmox's built-in ACME support (System → Certificates) once IPv6 is set up

## Web UI Complexity

- UI has a lot of options — need to read docs before touching things
- Resources: https://pve.proxmox.com/pve-docs/

---

## TODO

- [ ] Add IPv6 support — domain already resolves to IPv6 address, use for Let's Encrypt cert
