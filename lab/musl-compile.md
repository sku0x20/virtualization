# Musl Compile Lab

Compile musl libc from source. (package manager: xbps)

```
curl -sfL https://musl.libc.org/releases/musl-1.2.6.tar.gz -o musl-1.2.6.tar.gz
tar -xf musl-1.2.6.tar.gz && mv musl-1.2.6 musl
cd musl
./configure --prefix=/usr/local/musl
make -j$(nproc)
# run the .so directly to verify — musl prints its version
./lib/libc.so
# optional step; to install in /usr/local/musl
make install
```

## Adventure: Compile with Clang

```
xbps-install -y clang
./configure --prefix=/usr/local/musl CC=clang
make -j$(nproc)
```
