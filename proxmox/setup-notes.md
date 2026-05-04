# Setup Notes — How This Came Together

## Network / Infrastructure

- Using TP-Link Deco mesh network, taking ethernet from one of the nodes
- Configured Deco in AP mode (not router mode) — avoids double NAT, Proxmox sits directly on the main network
- Accessible from the work network seamlessly
- In router mode Deco handed out IPv4 via its own DHCP; in AP mode it bridges to the main router which prefers IPv6 — that's why Proxmox auto-detected IPv6 during install
- Fix: assign a static IPv4 manually during Proxmox install, ignore the router's preference
