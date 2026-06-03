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

Open `.config` in an editor:

```
nano .config
```

Find and set these two lines (use `Ctrl+W` to search):

**Static linking** — find the line `# CONFIG_STATIC is not set` and replace it with:
```
CONFIG_STATIC=y
```

**Compiler prefix** — find `CONFIG_CROSS_COMPILER_PREFIX` and make sure it's empty:
```
CONFIG_CROSS_COMPILER_PREFIX=""
```

You'll pass `CC=musl-gcc` at compile time instead; clearing the prefix avoids a double-wrap.

Save and exit (`Ctrl+O`, `Ctrl+X`), then verify:

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
