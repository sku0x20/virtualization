# BusyBox Compile Lab

Compile BusyBox as a static binary from source — one binary, all tools, no shared libs.

## Goal

Understand how BusyBox bundles hundreds of tools into a single binary and how to build it statically
so it works in any minimal root without a dynamic linker.

## Steps

### Prerequisites

- Ubuntu Server (minimal install) environment
- Internet access — needed to download the BusyBox tarball

**Install build tools**
```
apt-get update
apt-get install -y gcc make musl-tools perl bzip2 libncurses-dev xz-utils flex bison rsync
```

`musl-tools` provides the `musl-gcc` wrapper — use it instead of `gcc` when compiling BusyBox. Musl
is designed for clean static linking; glibc is not (it `dlopen()`s NSS modules at runtime for
DNS/user lookups, so a "static" glibc binary isn't truly portable).

**Install kernel headers**

The `linux-headers-*` apt package is for building kernel modules — not suitable for userspace
compilation. Download the kernel source and run `headers_install` instead, which produces sanitized
userspace-only headers:

```
curl -sfL https://cdn.kernel.org/pub/linux/kernel/v7.x/linux-7.0.tar.xz -o linux-7.0.tar.xz
tar -xf linux-7.0.tar.xz
cd linux-7.0
make mrproper
make defconfig
make headers_install ARCH=x86_64 INSTALL_HDR_PATH=/usr/local/kernel-headers
cd ..
```

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
make menuconfig
```

In menuconfig, make the following changes:

- *Networking Utilities* → uncheck `tc` — it uses kernel headers removed in 7.0
- *Settings* → uncheck `Use -static-libgcc` — not needed when linking against musl
- *Settings* → check `Avoid using gcc-specific code constructs` — keeps the build portable and musl-compatible

Verify:
```
grep CONFIG_STATIC .config
```
Expected: `CONFIG_STATIC=y`

---

### 3. Compile

```
make CC=musl-gcc -j$(nproc) CFLAGS="-I/usr/local/kernel-headers/include"
```

`CC=musl-gcc` routes all compilation through musl's wrapper so the static binary has no glibc dependency.

---

### 4. Verify

```
file busybox
ldd busybox
```

`file` should report `statically linked`. `ldd` should say `not a dynamic executable`.

```
./busybox echo "hello from busybox"
./busybox ls /
./busybox --list | wc -l
```

`--list` prints every applet compiled in — the count gives a quick sanity check that nothing was silently skipped.

---

## Adventure: Compile with Clang

A drop-in swap for step 3. Everything else (config, kernel headers) stays the same.

**Install clang and musl dev files**
```
apt-get install -y clang musl-dev
```

`musl-dev` provides the musl headers and static lib so clang can link against it instead of glibc.

> **Why not needed for `musl-gcc`?** `musl-tools` installs `musl-gcc` as a wrapper script around
> `gcc` with musl's header and library paths baked in via a GCC specs file — the wrapper finds musl
> automatically. Clang has no such wrapper; `--target=x86_64-linux-musl` only sets the ABI, clang
> still picks up glibc from system paths unless `--sysroot` redirects it. `musl-dev` installs musl
> under `/usr/lib/x86_64-linux-musl`, which is what `--sysroot` points at. (Also: `musl-tools`
> already depends on `musl-dev`, so it's pulled in automatically when using `musl-gcc`.)

**Compile**
```
make CC="clang --target=x86_64-linux-musl" \
  HOSTCC=clang -j$(nproc) \
  CFLAGS="-nostdinc -isystem /usr/include/x86_64-linux-musl -I/usr/local/kernel-headers/include" \
  LDFLAGS="-nostdlib -L/usr/lib/x86_64-linux-musl -lc"
```

- `--target=x86_64-linux-musl` — sets the target ABI; alone it doesn't change which libc gets
  linked, clang still searches system paths where glibc lives
- `-nostdinc` — disables all default include paths so glibc headers under `/usr/include` are not
  picked up; only explicitly passed `-isystem`/`-I` paths are searched
- `-isystem /usr/include/x86_64-linux-musl` — musl's headers (installed by `musl-dev`); `-isystem`
  instead of `-I` so warnings from musl's own headers are suppressed
- `-nostdlib` — disables default lib search paths and startup files so glibc's `libc.a` and
  `crt0.o` are not pulled in
- `-L/usr/lib/x86_64-linux-musl -lc` — explicitly link musl's `libc.a` from its install location
- `-ffreestanding` — tells the compiler no stdlib exists; without it the compiler may silently
  replace loops/mem ops with `memcpy`/`memset` calls that don't exist in a no-libc setup
- `-nodefaultlibs` — weaker than `-nostdlib`, skips default libs but keeps startup files; useful
  when you want musl's libc but still need the compiler runtime (`libgcc`/`compiler-rt`)
- `-rtlib=compiler-rt` — use clang's own runtime instead of `libgcc`; pairs better with musl
- `HOSTCC=clang` — builds host-side build tools (e.g. `fixdep`) with clang too

**Verify the same way**
```
file busybox
ldd busybox
./busybox echo "hello from clang busybox"
```

The "Avoid gcc-specific code constructs" setting from step 2 is what makes this work cleanly —
without it, clang chokes on a handful of gcc extensions in the BusyBox source.
