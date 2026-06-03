# BusyBox Compile Lab

Compile BusyBox as a static binary from source — one binary, all tools, no shared libs.

## Goal

Understand how BusyBox bundles hundreds of tools into a single binary and how to build it statically so it works in any minimal root without a dynamic linker.

## Steps

### Prerequisites

- Ubuntu Server (minimal install) environment
- Internet access — needed to download the BusyBox tarball

**Install build tools**
```
apt-get update
apt-get install -y gcc make musl-tools perl bzip2
```

`musl-tools` provides the `musl-gcc` wrapper — use it instead of `gcc` when compiling BusyBox. Musl is designed for clean static linking; glibc is not (it `dlopen()`s NSS modules at runtime for DNS/user lookups, so a "static" glibc binary isn't truly portable).

---

### 1. Get the source

Check the latest stable release at busybox.net/downloads, then:

```
curl -sfL https://busybox.net/downloads/busybox-1.38.0.tar.bz2 -o busybox-1.38.0.tar.bz2
tar -xf busybox-1.38.0.tar.bz2
cd busybox-1.38.0
```

---

### 2. Configure

Generate a default config:

```
make defconfig
```

This writes `.config` with sane defaults for the current arch. Two settings need changing for a clean static musl build:

**Enable static linking**
```
sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config
```

Without this, BusyBox links against the system libc dynamically — which defeats the point of using musl.

**Point the compiler at musl-gcc**
```
sed -i 's|^CONFIG_CROSS_COMPILER_PREFIX=.*|CONFIG_CROSS_COMPILER_PREFIX=""|' .config
```

You'll pass `CC=musl-gcc` at compile time instead; clearing the cross-compiler prefix avoids a double-wrap.

Verify both took:

```
grep -E 'CONFIG_STATIC|CONFIG_CROSS_COMPILER_PREFIX' .config
```

Expected:
```
CONFIG_STATIC=y
CONFIG_CROSS_COMPILER_PREFIX=""
```

---

## TODO

- [ ] Get BusyBox source (busybox.net tarball)
- [ ] Configure — `make defconfig`, then set `CONFIG_STATIC=y`
- [ ] Compile
- [ ] Verify it's statically linked (`file busybox`, `ldd busybox`)
- [ ] Install symlinks (`busybox --install -s /path/to/bin`)
- [ ] Drop into the GPT+GRUB lab in place of the downloaded binary
