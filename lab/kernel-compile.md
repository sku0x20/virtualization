# Kernel Compile Lab

Compile a minimal Linux kernel from source — no modules, no bloat.

## Goal

Understand what goes into a kernel build: configuration, compilation, and the output artifacts.

## TODO

- [ ] Get kernel source (kernel.org tarball)
- [ ] Configure — start from `tinyconfig` or `defconfig`, strip down
- [ ] Disable modules entirely (`CONFIG_MODULES=n`)
- [ ] Compile
- [ ] Note what the output artifacts are and where they land

## Steps

### Prerequisites

- Ubuntu Server (minimal install) environment
- Internet access — needed to download the kernel tarball

### 1. Get the source

Check the latest stable release at kernel.org, then:

```
apt-get install -y curl xz-utils
curl -sfL https://cdn.kernel.org/pub/linux/kernel/v7.x/linux-7.0.tar.xz -o linux-7.0.tar.xz
tar -xf linux-7.0.tar.xz
cd linux-7.0
```

### 2. Configure

```
apt-get install -y make gcc flex bison perl libncurses-dev
make tinyconfig
```

Adjust options according to need:

```
make menuconfig
```

### 3. Compile

```
apt-get install -y libelf-dev bc
make -j$(nproc)
```

### 4. Output

The kernel image lands at:

```
arch/x86/boot/bzImage
```

`vmlinuz` is just the name distros use after installing — same file.

### 5. Verify

```
file arch/x86/boot/bzImage
strings arch/x86/boot/bzImage | grep "Linux version"
```

---

## Adventure: Compile with Clang

A drop-in swap for step 3. Everything else (config) stays the same.

```
apt-get install -y clang lld llvm
make LLVM=1 -j$(nproc)
```

`LLVM=1` swaps in the full LLVM toolchain — clang as the compiler, lld as the linker, and llvm-ar/llvm-nm/etc. for the rest. No need to set `CC`, `LD`, and friends individually.

