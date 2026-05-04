# Proxmox Concerns & Open Questions

## IPv6 Issue

- Installer auto-detected IPv6 (router has it enabled by default)
- Don't want IPv6 — unclear how it behaves for VMs, global addresses are exposed, routing is tricky
- **Plan:** Reinstall with static IPv4 only, leave IPv6 fields blank or clear them during install

## Self-Signed Certificate

- Proxmox generates a self-signed cert at install — browser will warn on every access
- Options to fix:
  - Add a browser exception (quick but annoying)
  - Replace with a Let's Encrypt cert via the UI (requires a domain name pointing to the node)
  - Use a local CA and trust it on your machines

## Web UI Complexity

- UI has a lot of options — need to read docs before touching things
- Resources: https://pve.proxmox.com/pve-docs/
