# Musl Compile Lab

Compile musl libc from source — the clean, minimal C standard library.

## Goal

Understand how a C standard library is built and what it produces.

## TODO

- [ ] Get musl source
- [ ] Configure
- [ ] Compile
- [ ] Note output artifacts

## Steps

### Prerequisites

- Ubuntu Server (minimal install) environment
- Internet access — needed to download the musl tarball

### 1. Get the source

Check the latest release at musl.libc.org, then:

```
apt-get install -y curl xz-utils
curl -sfL https://musl.libc.org/releases/musl-1.2.5.tar.gz -o musl-1.2.5.tar.gz
tar -xf musl-1.2.5.tar.gz
cd musl-1.2.5
```
