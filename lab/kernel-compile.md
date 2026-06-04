# Kernel Compile Lab

Compile a minimal Linux kernel from source — no modules, no bloat.

## Goal

Understand what goes into a kernel build: configuration, compilation, and the output artifacts.

## TODO

- [ ] Get kernel source (kernel.org tarball)
- [ ] Configure — start from `tinyconfig` or `defconfig`, strip down
- [ ] Disable modules entirely (`CONFIG_MODULES=n`)
- [ ] Compile
- [ ] Note what the output artifacts are (`vmlinuz`, `bzImage`) and where they land
