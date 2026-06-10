# BusyBox Compile Lab

Compile BusyBox statically from source.

## Steps

### Prerequisites

- [Avoid](https://www.github.com/sku0x20/avoid) (Void-based) environment
- Internet access — needed to download the BusyBox tarball

**Install build tools**
```
xbps-install -Su
xbps-install -y gcc make musl perl bzip2 ncurses-devel xz flex bison rsync
```

`musl-tools` provides the `musl-gcc` wrapper — use it instead of `gcc` when compiling BusyBox. Musl
is designed for clean static linking; glibc is not (it `dlopen()`s NSS modules at runtime for
DNS/user lookups, so a "static" glibc binary isn't truly portable).

**Install kernel headers**

The `linux-headers` xbps package is for building kernel modules — not suitable for userspace
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
- *Settings* → check `Build BusyBox as a static binary`
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
xbps-install -y clang lld musl-devel
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
  CFLAGS="-nostdinc -isystem /usr/include/x86_64-linux-musl -isystem /usr/local/kernel-headers/include" \
  LDFLAGS="-nostdlib -rtlib=compiler-rt -fuse-ld=lld -L /usr/lib/x86_64-linux-musl -lc"
```

- `HOSTCC=clang` — builds host-side build tools (e.g. `fixdep`) with clang too
- `--target=x86_64-linux-musl` — sets the target ABI; alone it doesn't change which libc gets
  linked, clang still searches system paths where glibc lives
- `-nostdinc` — disables all default include paths so glibc headers under `/usr/include` are not
  picked up; only explicitly passed `-isystem`/`-I` paths are searched
- `-isystem /usr/include/x86_64-linux-musl` — musl's headers (installed by `musl-dev`); `-isystem`
  instead of `-I` so warnings from musl's own headers are suppressed
- `-nostdlib` — disables default lib search paths and startup files so glibc's `libc.a` and
  `crt0.o` are not pulled in
- `-L/usr/lib/x86_64-linux-musl -lc` — explicitly link musl's `libc.a` from its install location
- `-nodefaultlibs` — weaker than `-nostdlib`, skips default libs but keeps startup files; useful
  when you want musl's libc but still need the compiler runtime (`libgcc`/`compiler-rt`)
- `-rtlib=compiler-rt` — The compiler runtime provides low-level helpers the compiler itself emits calls to — things like software division, 64-bit arithmetic on 32-bit systems,
  sanitizer support. gcc has libgcc for this, clang has compiler-rt.
- `-fuse-ld=lld` — tells clang to use lld instead of the system linker (GNU ld)
- `-ffreestanding` — tells the compiler no stdlib exists; without it the compiler may silently
  replace loops/mem ops with `memcpy`/`memset` calls that don't exist in a no-libc setup

**Verify the same way**
```
file busybox
ldd busybox
./busybox echo "hello from clang busybox"
```

The "Avoid gcc-specific code constructs" setting from step 2 is what makes this work cleanly —
without it, clang chokes on a handful of gcc extensions in the BusyBox source.

---

## Adventure: Compile with GCC + self-compiled musl

An alternative to step 3 when musl is compiled from source and installed locally (e.g. at
`/usr/local/musl`) rather than pulled in via `musl-tools`.

The `musl-gcc` wrapper from `musl-tools` works by embedding musl's paths into a GCC specs file so
the compiler finds musl automatically. Without that wrapper, stock gcc's default specs put
`/usr/include` first — which means glibc headers win. `-nostdinc` strips all default include paths,
and then explicit `-isystem` ordering puts musl first.

The include and lib paths used below come directly from musl's own specs file. Inspect it to find
the right values for your install:
```
cat /usr/local/musl/lib/musl-gcc.specs
```

**Compile**
```
make -j$(nproc) \
  CFLAGS="-nostdinc -isystem /usr/local/musl/include -isystem /usr/include" \
  LDFLAGS="-L /usr/local/musl/lib"
```

- `-nostdinc` — disables gcc's default include search paths; without it gcc's specs inject
  `/usr/include` before anything you pass, so glibc headers are found first
- `-isystem /usr/local/musl/include` — musl's headers from the local install; listed before
  `/usr/include` so musl wins when both define the same header
- `-isystem /usr/include` — system includes, needed for linux kernel headers
  (`/usr/include/linux`); these are shipped by glibc's dev package and are sufficient for BusyBox —
  no separate `headers_install` step required
- `-L /usr/local/musl/lib` — points the linker at musl's static library; `CONFIG_STATIC=y` in
  `.config` tells BusyBox's Makefile to pass `-static` to the linker, so musl's `libc.a` is linked in

**Verify the same way**
```
file busybox
ldd busybox
./busybox echo "hello from self-compiled musl busybox"
```
