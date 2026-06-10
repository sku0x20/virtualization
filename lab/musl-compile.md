# Musl Compile Lab

Compile musl libc from source. (package manager: xbps)

```
xbps-install -y curl xz gcc make
curl -sfL https://musl.libc.org/releases/musl-1.2.6.tar.gz -o musl-1.2.6.tar.gz
tar -xf musl-1.2.6.tar.gz && mv musl-1.2.6 musl
cd musl
./configure --prefix=/usr/local/musl
make -j$(nproc)
# run the .so directly to verify — musl prints its version
./lib/libc.so
```

Output under `lib/` and `include/`:

- `lib/libc.so` — shared library
- `lib/libc.a` — static library
- `lib/musl-gcc.specs` — specs file used by the `musl-gcc` wrapper
- `include/` — musl's C standard headers

---

## Adventure: Compile with Clang

```
xbps-install -y clang
./configure --prefix=/usr/local/musl CC=clang
make -j$(nproc)
```
