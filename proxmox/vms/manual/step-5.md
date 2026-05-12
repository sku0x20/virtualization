# Step 5 — Automate with Ignition + Templates

Instead of SSHing into each VM to install k3s, bake everything into the VM image. Clone once, get a ready node.

---

## The Flow

1. Write an Ignition config (SSH key + k3s install unit)
2. Create one VM with that config
3. Convert to template
4. Clone for each node — they come up with k3s already running

---

## Ignition Config

Ignition runs in initramfs before the OS boots — one time only. Network isn't up yet during Ignition itself, so k3s install is deferred to a systemd unit that fires after network is ready.

Create `/var/lib/vz/snippets/flatcar-ignition.json` on the Proxmox host:

```json
{
  "ignition": { "version": "3.0.0" },
  "passwd": {
    "users": [{
      "name": "core",
      "sshAuthorizedKeys": ["ssh-ed25519 YOUR_PUBLIC_KEY"]
    }]
  },
  "systemd": {
    "units": [{
      "name": "k3s-install.service",
      "enabled": true,
      "contents": "[Unit]\nDescription=Install k3s\nAfter=network-online.target\nWants=network-online.target\nConditionPathExists=!/etc/k3s-installed\n\n[Service]\nType=oneshot\nRemainAfterExit=yes\nExecStart=/bin/sh -c 'curl -sfL https://get.k3s.io | sh -'\nExecStartPost=/bin/touch /etc/k3s-installed\n\n[Install]\nWantedBy=multi-user.target"
    }]
  }
}
```

`ConditionPathExists=!/etc/k3s-installed` ensures it runs only once — flag file prevents re-runs on subsequent boots.

---

## Apply Ignition to VM

```bash
qm set $VM_ID --cicustom "user=local:snippets/flatcar-ignition.json"
```

Note: Ignition and cloud-init share the same `user-data` slot. Picking Ignition means no cloud-init. Cloud-init services will log harmless failures — expected.

---

## Create Template

```bash
qm template $VM_ID
```

VM becomes read-only. Can be cloned but not started directly.

---

## Clone for Each Node

```bash
qm clone 9000 101 --name k3s-control --full
qm clone 9000 102 --name k3s-worker-1 --full
qm clone 9000 103 --name k3s-worker-2 --full
```

Start them:
```bash
qm start 101
qm start 102
qm start 103
```

Each VM boots, Ignition runs (SSH key injected), then the systemd unit fires and installs k3s automatically.

---

## Worker Node Config

Worker nodes need `K3S_URL` and `K3S_TOKEN` at install time. Add them to the Ignition unit:

```
ExecStart=/bin/sh -c 'curl -sfL https://get.k3s.io | K3S_URL=https://<control-ip>:6443 K3S_TOKEN=<token> sh -'
```

Or pass via a file that Ignition writes before the unit runs:

```json
"storage": {
  "files": [{
    "path": "/etc/k3s-env",
    "mode": 384,
    "contents": {
      "source": "data:,K3S_URL%3Dhttps%3A%2F%2F<control-ip>%3A6443%0AK3S_TOKEN%3D<token>%0A"
    }
  }]
}
```

Then in the unit: `EnvironmentFile=/etc/k3s-env`

---

## Ignition vs cloud-init Summary

| | Ignition | cloud-init |
|--|---------|-----------|
| Runs | initramfs (pre-boot) | userspace (post-boot) |
| Timing | once, never again | configurable |
| Network available | no | yes |
| Use for | SSH keys, files, systemd units | package install, scripts |
| Used by | Flatcar, CoreOS | Ubuntu, Debian, most distros |
