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
apt-get install -y gcc make musl-tools perl
```

`musl-tools` provides the `musl-gcc` wrapper — use it instead of `gcc` when compiling BusyBox. Musl is designed for clean static linking; glibc is not (it `dlopen()`s NSS modules at runtime for DNS/user lookups, so a "static" glibc binary isn't truly portable).

---

### 1. Get the source

Check the latest stable release at busybox.net/downloads, then:

```
curl -sfL https://busybox.net/downloads/busybox-1.37.0.tar.bz2 -o busybox-1.37.0.tar.bz2
tar -xf busybox-1.37.0.tar.bz2
cd busybox-1.37.0
```

---

## TODO

- [ ] Get BusyBox source (busybox.net tarball)
- [ ] Configure — `make defconfig`, then set `CONFIG_STATIC=y`
- [ ] Compile
- [ ] Verify it's statically linked (`file busybox`, `ldd busybox`)
- [ ] Install symlinks (`busybox --install -s /path/to/bin`)
- [ ] Drop into the GPT+GRUB lab in place of the downloaded binary
