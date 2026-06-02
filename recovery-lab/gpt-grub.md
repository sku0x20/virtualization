# GPT + GRUB Lab

Learn by doing — replicate what an OS installer does, manually.

## Goal

Understand the boot chain: UEFI firmware → ESP → GRUB → kernel → root partition.

## Steps

1. Raw disk, live boot into Debian live ISO
2. Partition manually with `sgdisk` — GPT, ESP, root, home
3. Build minimal root — busybox + `/etc/passwd` `/etc/shadow` `/etc/group` `/etc/fstab`
4. Download kernel + initrd onto ESP
5. Install GRUB (UEFI target)
6. Boot it — initrd finds root, mounts home, get a shell
7. Create a user with `adduser`, verify home dir lands on home partition
8. Break → recover scenarios

## VM Spec

- UEFI mode (not SeaBIOS)
- 1 disk, ~20GB, no OS pre-installed
- Boot from Debian live ISO

## Next

- lvm
- luks
- custom initrd
