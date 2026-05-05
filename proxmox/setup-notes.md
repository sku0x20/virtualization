# Setup Notes — How This Came Together

## Network / Infrastructure

- Using TP-Link Deco mesh network, taking ethernet from one of the nodes
- Configured Deco in AP mode (not router mode) — avoids double NAT, Proxmox sits directly on the main network
- Accessible from the work network seamlessly
- In router mode Deco handed out IPv4 via its own DHCP; in AP mode it bridges to the main router which prefers IPv6 — that's why Proxmox auto-detected IPv6 during install
- Fix: assign a static IPv4 manually (either during install or from the UI later) — no way to ask it to auto-detect IPv4, has to be static either way

## TLS Certificate via Let's Encrypt ACME

- Proxmox installs with a self-signed cert by default — browser warns on every access until replaced
- Added a trusted HTTPS certificate using Let's Encrypt ACME (Node → System → Certificates → ACME)
- Used the HTTP-01 challenge type with the node's IPv6 address as the domain (e.g. `[2xxx:...].nip.io` or a DNS record pointing to the IPv6)
- After issuance, Proxmox automatically uses the certificate for its web interface (port 8006) — no manual restart needed

## Web UI

- UI has a lot of options — read docs before touching things
- Docs: https://pve.proxmox.com/pve-docs/

## IPv6 Neighbor Discovery (NDP) Across Mesh Nodes

- Devices on different Deco mesh nodes cannot discover each other via `ping6 ff02::1%<iface>` (all-nodes multicast) — the mesh drops this broadcast across nodes
- Unicast NDP resolution (solicited-node multicast `ff02::1:ffXX:XXXX`) still works — the mesh proxies it, so IPv6→MAC resolution functions normally
- Practically: `ndp -a` / `ip -6 neigh show` only shows neighbors you've already communicated with; you can't do a blanket scan across mesh nodes
