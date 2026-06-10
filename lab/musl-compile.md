# Musl Compile Lab

Compile musl libc from source. (package manager: xbps)

### 1. Get the source

Check the latest release at musl.libc.org, then:

```
xbps-install -y curl xz
curl -sfL https://musl.libc.org/releases/musl-1.2.6.tar.gz -o musl-1.2.6.tar.gz
tar -xf musl-1.2.6.tar.gz && mv musl-1.2.6 musl
cd musl
```

### 2. Configure

```
xbps-install -y gcc make
./configure --prefix=/usr/local/musl
```

### 3. Compile

```
make -j$(nproc)
```

### 4. Output

Build produces under `lib/` and `include/`:

- `lib/libc.so` — shared library
- `lib/libc.a` — static library
- `lib/musl-gcc.specs` — specs file used by the `musl-gcc` wrapper
- `include/` — musl's C standard headers

### 5. Verify

```
./lib/libc.so
```

musl prints its version when the shared library is run directly.

---

## Adventure: Compile with Clang

A drop-in swap for steps 2 and 3. Everything else stays the same.

```
xbps-install -y clang
./configure --prefix=/usr/local/musl CC=clang
make -j$(nproc)
```
