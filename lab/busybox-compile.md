# BusyBox Compile Lab

Compile BusyBox as a static binary from source — one binary, all tools, no shared libs.

## Goal

Understand how BusyBox bundles hundreds of tools into a single binary and how to build it statically so it works in any minimal root without a dynamic linker.

## Steps

### Prerequisites

- Alpine Linux environment (live ISO or VM)
- Internet access — needed to download the BusyBox tarball

**Alpine: Install build tools**
```
apk update
apk add gcc musl-dev make perl
```

`musl-dev` provides the static musl libc headers and `crt` objects — required to produce a fully static binary on Alpine. Without it, the linker has no static libc to link against and the build fails.

---

## TODO

- [ ] Get BusyBox source (busybox.net tarball)
- [ ] Configure — `make defconfig`, then set `CONFIG_STATIC=y`
- [ ] Compile
- [ ] Verify it's statically linked (`file busybox`, `ldd busybox`)
- [ ] Install symlinks (`busybox --install -s /path/to/bin`)
- [ ] Drop into the GPT+GRUB lab in place of the downloaded binary
