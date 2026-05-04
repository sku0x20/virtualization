# Proxmox Concerns & Open Questions

## Network Setup

- Installer auto-detected IPv6; domain already points to this IPv6 address
- Need to also add a static IPv4 for local network access
- **Plan:** Keep IPv6, add static IPv4 alongside it — no reinstall needed, configure via UI (System → Network) or `/etc/network/interfaces`

## Self-Signed Certificate

- Proxmox generates a self-signed cert at install — browser will warn on every access
- Options to fix:
  - Add a browser exception (quick but annoying)
  - Replace with a Let's Encrypt cert via the UI (requires a domain name pointing to the node)
  - Use a local CA and trust it on your machines
- **Plan:** Use Let's Encrypt via domain (resolves to IPv6) — Proxmox has built-in ACME support under System → Certificates

## Web UI Complexity

- UI has a lot of options — need to read docs before touching things
- Resources: https://pve.proxmox.com/pve-docs/
