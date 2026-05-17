# Step 4 — Custom Cloud-Init Configuration

The Proxmox Cloud-Init UI tab covers basics (SSH keys, IP, DNS). For anything beyond that — like setting a password — use a custom snippet.

---

## Why Custom Snippets

The UI tab only exposes a fixed set of fields. It cannot set a password for the `alpine` user (or any user beyond what Proxmox hardcodes). Custom snippets give you full cloud-init `user-data` control.

---

## Steps

### 1. Enable snippet storage

On the Proxmox host, the `local` storage must have **Snippets** enabled.

Datacenter → Storage → `local` → Edit → Content → check **Snippets** → OK.

### 2. Create the user-data file

SSH into the Proxmox host and create the snippet:

```bash
nano /var/lib/vz/snippets/user-data.yaml
```

To set a password for the `alpine` user:

```yaml
#cloud-config
users:
  - name: alpine
    passwd: $6$rounds=4096$yoursalt$yourhash
    lock_passwd: false
ssh_pwauth: true
```

Linux never stores plain passwords — it stores a hash. Cloud-init follows the same convention: the `passwd:` field expects an already-hashed value, which it writes directly into `/etc/shadow` on the VM.

Generate the hash on any Linux machine:

```bash
openssl passwd -6
# type your password when prompted
# outputs: $6$somesalt$longhashstring...
```

Paste the entire output as the `passwd` value. The format is:

- `$6$` — SHA-512 algorithm
- `somesalt$` — random salt (generated automatically)
- `longhashstring` — the resulting hash

> Using `plain_text_passwd` instead is possible but not recommended — it leaves your password in plain text in the snippet file on the Proxmox host.

### 3. Point the VM at the snippet

```bash
qm set $VM_ID --cicustom "user=local:snippets/user-data.yaml"
```

### 4. Regenerate the cloud-init image

```bash
qm cloudinit update $VM_ID
```

Run this after every change to the snippet — Proxmox caches the cloud-init ISO and won't pick up edits automatically.

### 5. Start (or reboot) the VM

Cloud-init runs once on first boot. To re-run it on an already-booted VM, you need to reset the cloud-init state first:

```bash
# on the Alpine VM
rm /var/lib/cloud/instances/*/sem/config_*
reboot
```

---

## Mixing UI and Custom Snippets

`--cicustom` overrides only the sections you specify. If you set `user=local:snippets/user-data.yaml`, Proxmox still applies its own generated `network` and `meta` data. You can override each independently:

```bash
qm set $VM_ID --cicustom "user=local:snippets/user-data.yaml,network=local:snippets/network.yaml"
```

---

## Notes

- `local` in `--cicustom` refers to the Proxmox storage named `local` (backed by `/var/lib/vz`). Adjust if your snippets storage has a different name.
- The Alpine cloud image login user is `alpine` — not `root`. SSH key injection and cloud-init both target this user by default.
