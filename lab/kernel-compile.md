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

---

### 1. Get the source

```
apt-get install -y curl xz-utils
```

Check the latest stable release at kernel.org, then:

```
curl -sfL https://cdn.kernel.org/pub/linux/kernel/v7.x/linux-7.0.tar.xz -o linux-7.0.tar.xz
tar -xf linux-7.0.tar.xz
cd linux-7.0
```

---

### 2. Configure

```
apt-get install -y make gcc flex bison perl libncurses-dev
```

Start from the smallest possible base:

```
make tinyconfig
```

`tinyconfig` produces a `.config` with nearly everything off — modules already disabled. From here, use `menuconfig` to enable anything specific you need:

```
make menuconfig
```

Verify modules are off:

```
grep CONFIG_MODULES .config
```

Expected: `CONFIG_MODULES=n`

---
