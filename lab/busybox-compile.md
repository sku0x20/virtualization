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

clang is mostly a drop in replacement so most of the things should work out of the box just `CC` change

```
# direct correspondance only CC change
make -j2 CC="clang" CFLAGS="-nostdinc -isystem /usr/local/musl/include -isystem /usr/include" LDFLAGS="-L /usr/local/musl/lib"
# can be improved a bit more
make -j2 CC="clang" CFLAGS="-nostdinc -isystem /usr/local/musl/include -isystem /usr/include" LDFLAGS="-L /usr/local/musl/lib -rtlib=compiler-rt -fuse-ld=lld"
```

## With Kernel Headers From Source

- /usr/include is mostly handled by glibc and most of the time installed when installing gcc.
- /linux is also from glibc in most case.
- if not there install linux headers via package-manager.
- else follow this to make them from src. and include them in the `CFLAGS`

```
curl -sfL https://cdn.kernel.org/pub/linux/kernel/v7.x/linux-7.0.tar.xz -o linux-7.0.tar.xz
tar -xf linux-7.0.tar.xz && mv linux-7.0 linux
cd linux
# cleanup
make mrproper
make defconfig
make headers_install ARCH=x86_64 INSTALL_HDR_PATH=/usr/local/kernel-headers
```
