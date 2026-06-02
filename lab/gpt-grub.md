# GPT + GRUB Lab

Learn by doing — replicate what an OS installer does, manually.

## Goal

Understand the boot chain: UEFI firmware → ESP → GRUB → kernel → root partition.

## Plan

1. Raw disk, live boot into Debian live ISO
2. Partition manually – GPT, ESP, root, home
3. Build minimal root — busybox + `/etc/passwd` `/etc/shadow` `/etc/group` `/etc/fstab`
4. Download kernel + initrd onto ESP
5. Install GRUB (UEFI target)
6. Boot it — initrd finds root, mounts home, get a shell
7. Create a user with `adduser`, verify home dir lands on home partition
8. Break → recover scenarios

## Steps

### Prerequisites

- Booted into a Debian live ISO
- Valid UEFI environment required (EFI variables must be writable)
- An empty disk available — steps assume `/dev/sda`

---

### 1. Identify the disk

```
fdisk -l
```

Confirm `/dev/sda` is the target and note its size.

---

### 2. Partition

```
fdisk /dev/sda
```

Inside fdisk:

| Key sequence | Action |
|---|---|
| `g` | New GPT partition table |
| `n` → `1` → ↵ → `+512M` | Partition 1 — ESP |
| `t` → `1` | Set type: EFI System |
| `n` → `2` → ↵ → `+2G` | Partition 2 — root |
| `n` → `3` → ↵ → ↵ | Partition 3 — home (rest) |
| `p` | Verify layout |
| `w` | Write and exit |

Format:

```
mkfs.vfat -F32 /dev/sda1
mkfs.ext4 /dev/sda2
mkfs.ext4 /dev/sda3
```

Capture UUIDs now — needed for fstab and grub.cfg:

```
ROOT_UUID=$(blkid -s UUID -o value /dev/sda2)
HOME_UUID=$(blkid -s UUID -o value /dev/sda3)
echo "root: $ROOT_UUID  home: $HOME_UUID"
```

---

### 3. Build the minimal root

Mount root first, then home — home must be mounted before writing to it or files land on the root partition under the mount point:

```
mkdir -p /mnt/root
mount /dev/sda2 /mnt/root
mkdir -p /mnt/root/{bin,sbin,etc,lib,lib64,proc,sys,dev,tmp,root,home,boot/efi}
mount /dev/sda1 /mnt/root/boot/efi
mount /dev/sda3 /mnt/root/home
```

Install busybox — static binary so the minimal root needs no dynamic linker:

```
apt-get install -y busybox-static
cp /usr/bin/busybox /mnt/root/bin/busybox
chroot /mnt/root /bin/busybox --install -s /bin
ln -s /bin/busybox /mnt/root/sbin/init
```

`/sbin/init` is required — the initrd execs it after pivot_root.

Create `/etc/passwd`, `/etc/shadow`, `/etc/group`:

```
printf 'root:x:0:0:root:/root:/bin/sh\n' > /mnt/root/etc/passwd
printf 'root::19000:0:99999:7:::\n'       > /mnt/root/etc/shadow
printf 'root:x:0:\n'                       > /mnt/root/etc/group
chmod 640 /mnt/root/etc/shadow
```

Create `/etc/fstab`:

```
cat > /mnt/root/etc/fstab << EOF
UUID=${ROOT_UUID}  /      ext4  defaults  0 1
UUID=${HOME_UUID}  /home  ext4  defaults  0 2
EOF
```

---

### 4. Get kernel and initrd

The live ISO's initrd is built for the live system and will not boot a plain ext4 root. Install a real kernel package to get a proper initrd:

```
apt-get install -y linux-image-amd64
```

Copy to the root partition's `/boot`:

```
ls /boot/vmlinuz-*      # note the version string, e.g. 6.1.0-18-amd64
KVER=<version>
cp /boot/vmlinuz-${KVER}   /mnt/root/boot/vmlinuz
cp /boot/initrd.img-${KVER} /mnt/root/boot/initrd.img
```

---

### 5. Install GRUB

```
apt-get install -y grub-efi-amd64

grub-install \
  --target=x86_64-efi \
  --efi-directory=/mnt/root/boot/efi \
  --boot-directory=/mnt/root/boot \
  --bootloader-id=grub
```

This copies the GRUB EFI binary to the ESP and writes a UEFI NVRAM boot entry. `efibootmgr` is called internally — you do not call it directly.

Write `grub.cfg`:

```
cat > /mnt/root/boot/grub/grub.cfg << EOF
set timeout=5
set default=0

menuentry "Minimal Linux" {
    linux /boot/vmlinuz root=UUID=${ROOT_UUID} rw
    initrd /boot/initrd.img
}
EOF
```

Unmount cleanly:

```
umount /mnt/root/boot/efi
umount /mnt/root/home
umount /mnt/root
```

---

### 6. Boot

Remove the live ISO. The UEFI firmware reads the NVRAM boot entry, loads `grubx64.efi` from the ESP, which reads `grub.cfg` from the root partition and loads the kernel + initrd.

The initrd finds the root device by UUID, mounts `/dev/sda2`, and execs `/sbin/init`. You get a shell.

Login as `root` — no password.

---

### 7. Create a user

```
adduser alice
```

Verify the home directory landed on the home partition, not the root partition:

```
mount | grep home
ls /home/alice
```

---

### 8. Break → recover scenarios

**a. Missing GRUB config**
Delete `/boot/grub/grub.cfg` and reboot. GRUB drops to its rescue shell. Boot live ISO, remount root, rewrite `grub.cfg`.

**b. Wrong root UUID**
Edit `grub.cfg`, corrupt the `root=UUID=` value. Reboot. Kernel panics: `VFS: Unable to mount root fs`. Boot live ISO, fix UUID.

**c. Wiped ESP**
```
dd if=/dev/zero of=/dev/sda1 bs=1M count=1
```
Reboot — firmware finds no EFI binary. Boot live ISO, reformat ESP (`mkfs.vfat -F32`), reinstall GRUB.

**d. Bypass init**
At the GRUB menu, press `e`, append `init=/bin/sh` to the `linux` line, press `Ctrl-x`. Kernel execs `/bin/sh` directly, bypassing `/sbin/init` and login.

---

## Next

- lvm
- luks
- custom initrd
