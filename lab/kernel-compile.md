# Kernel Compile Lab

Compile a minimal Linux kernel from source. (package manager: xbps)

```
curl -sfL https://cdn.kernel.org/pub/linux/kernel/v7.x/linux-7.0.tar.xz -o linux-7.0.tar.xz
tar -xf linux-7.0.tar.xz && mv linux-7.0 linux
cd linux
make tinyconfig
# adjust options as needed
make menuconfig
make -j$(nproc)
# output: arch/x86/boot/bzImage
file arch/x86/boot/bzImage
strings arch/x86/boot/bzImage | grep "Linux version"
# optional: install sanitized userspace headers
make headers_install ARCH=x86_64 INSTALL_HDR_PATH=/usr/local/kernel-headers
```

---

## Adventure: Compile with Clang

```
xbps-install -y clang lld llvm
make LLVM=1 -j$(nproc)
```

`LLVM=1` swaps in the full LLVM toolchain — clang as the compiler, lld as the linker, and llvm-ar/llvm-nm/etc. for the rest.
