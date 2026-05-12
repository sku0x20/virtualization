# VM Creation via Cloud Images & Templates

## Why Cloud Images over ISO

- ISO = boot an installer, click through setup (like a physical machine)
- Cloud image (qcow2) = pre-built disk, import directly, configure via cloud-init
- No installer, boots in seconds, repeatable

## Workflow: Cloud Image → Template → Clone

### 1. Download Cloud Image

In Proxmox web UI: `local` storage → **ISO Images** → **Download from URL**

Recommended: Ubuntu Server cloud image (has cloud-init pre-installed)
- URL: https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img

### 2. Create VM & Import Disk

```bash
# SSH into Proxmox host, then:
qm create 9000 --name ubuntu-cloud-template --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0
qm importdisk 9000 /var/lib/vz/template/iso/noble-server-cloudimg-amd64.img local-lvm
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
```

### 3. Add Cloud-Init Drive

```bash
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --serial0 socket --vga serial0
```

Or via UI: VM → Hardware → Add → CloudInit Drive

### 4. Configure Cloud-Init

VM → **Cloud-Init tab** in the UI:
- User: set a username
- Password or SSH key: paste your public key
- IP Config: DHCP or static

### 5. Convert to Template

```bash
qm template 9000
```

Or UI: right-click VM → **Convert to Template**
The VM is now read-only and can be cloned.

### 6. Clone for Each Node

```bash
# Full clone (independent copy)
qm clone 9000 101 --name k3s-control --full
qm clone 9000 102 --name k3s-worker-1 --full
qm clone 9000 103 --name k3s-worker-2 --full
```

Or UI: right-click template → **Clone**

Then start each clone — cloud-init runs on first boot, applies SSH key, hostname, network config.

## Why This Matters for k3s

Spinning up a k3s cluster = 1 control plane + 2 workers.
With a template, each node is ready in ~10 seconds instead of going through an installer 3 times.
