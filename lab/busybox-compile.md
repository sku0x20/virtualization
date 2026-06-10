# BusyBox Compile Lab

Compile BusyBox statically from source. (package manager: xbps)

---

## With gcc & Musl

- `-isystem /usr/include` required for linux headers
- not using `musl-gcc` which uses `musl-gcc.specs` cause it put user provided dirs before its dirs. then /usr/include gets priority rather than musl include dirs.

```
curl -sfL https://busybox.net/downloads/busybox-1.38.0.tar.bz2 -o busybox-1.38.0.tar.bz2
tar -xf busybox-1.38.0.tar.bz2 && mv busybox-1.38.0 busybox
cd busybox
# Generate a default config:
make menuconfig
```

In menuconfig:

- _Networking Utilities_ → uncheck `tc` (uses removed kernel code)
- _Settings_ → check `Build BusyBox as a static binary`
- _Settings_ → uncheck `Use -static-libgcc` - not needed when linking against musl
- _Settings_ → check `Avoid using gcc-specific code constructs` - keeps the build portable and musl-compatible

```
# should be CONFIG_STATIC=y in .config
grep CONFIG_STATIC .config
# musl => install via package-manager or build && make install
make -j$(nproc) CFLAGS="-nostdinc -isystem /usr/local/musl/include -isystem /usr/include" LDFLAGS="-L /usr/local/musl/lib"
file busybox
ldd busybox
./busybox echo "hello from busybox"
./busybox ls /
./busybox --list | wc -l
```

- `-nostdlib -lc` is same as not passing linker automatically links it.
- also `-static` flag is passed implicitly by the busybox config.

## With Clang & Musl

clang is mostly a drop in replacement so most of the things should work out of the box just just `CC` change

```
# direct correspondance only CC change
make -j2 CC="clang" CFLAGS="-nostdinc -isystem /usr/local/musl/include -isystem /usr/include" LDFLAGS="-L /usr/local/musl/lib"
# can be improved a bit more
make -j2 CC="clang" CFLAGS="-nostdinc -isystem /usr/local/musl/include -isystem /usr/include" LDFLAGS="-L /usr/local/musl/lib -rtlib=compiler-rt -fuse-ld=lld"
```

=============================

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

```

```
