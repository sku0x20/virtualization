# Step 4 — Install k3s Manually

VM is running (from step 3). SSH in and install k3s by hand.

---

## SSH Into the VM

```bash
ssh core@<vm-ip>    # Flatcar default user is "core"
```

Find the IP via Proxmox UI: VM → Summary, or check your router's DHCP leases.

---

## Install k3s (Control Plane)

```bash
curl -sfL https://get.k3s.io | sh -
```

This installs k3s and starts it as a systemd service automatically.

### Verify

```bash
sudo k3s kubectl get nodes
sudo systemctl status k3s
```

### Get the Node Token (needed for workers)

```bash
sudo cat /var/lib/rancher/k3s/server/node-token
```

---

## Install k3s (Worker Node)

On each worker VM, run:

```bash
curl -sfL https://get.k3s.io | K3S_URL=https://<control-plane-ip>:6443 K3S_TOKEN=<token> sh -
```

Replace `<control-plane-ip>` and `<token>` from the control plane above.

### Verify from Control Plane

```bash
sudo k3s kubectl get nodes
```

All nodes should show `Ready`.

---

## Use kubectl from Your Mac

Copy the kubeconfig from the control plane:

```bash
scp core@<control-plane-ip>:/etc/rancher/k3s/k3s.yaml ~/.kube/config
```

Edit `~/.kube/config` — replace `127.0.0.1` with the control plane IP.

Then from your Mac:
```bash
kubectl get nodes
```

---

## k3s Basics

| Command | What it does |
|---------|-------------|
| `sudo k3s kubectl get nodes` | list all nodes |
| `sudo k3s kubectl get pods -A` | list all pods across namespaces |
| `sudo systemctl status k3s` | check k3s service |
| `sudo systemctl restart k3s` | restart k3s |
| `sudo journalctl -u k3s -f` | follow k3s logs |
