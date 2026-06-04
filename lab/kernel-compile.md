# Kernel Compile Lab

Compile a minimal Linux kernel from source — no modules, no bloat.

## Goal

Understand what goes into a kernel build: configuration, compilation, and the output artifacts.

## TODO

- [ ] Get kernel source (kernel.org tarball)
- [ ] Configure — start from `tinyconfig` or `defconfig`, strip down
- [ ] Disable modules entirely (`CONFIG_MODULES=n`)
- [ ] Compile
- [ ] Note what the output artifacts are (`vmlinuz`, `bzImage`) and where they land

## Steps

### Prerequisites

- Ubuntu Server (minimal install) environment
- Internet access — needed to download the kernel tarball

**Install build tools**
```
apt-get update
apt-get install -y gcc make flex bison libssl-dev libelf-dev bc perl xz-utils curl
```

---

### 1. Get the source

Check the latest stable release at kernel.org, then:

```
curl -sfL https://cdn.kernel.org/pub/linux/kernel/v7.x/linux-7.0.tar.xz -o linux-7.0.tar.xz
tar -xf linux-7.0.tar.xz
cd linux-7.0
```

---
