# Installing k3s on Alpine Linux

## Cloud Image

```
https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/cloud/generic_alpine-3.23.4-x86_64-uefi-tiny-r0.qcow2
```

BIOS variant (if not using UEFI):
```
https://dl-cdn.alpinelinux.org/alpine/v3.23/releases/cloud/nocloud_alpine-3.23.4-x86_64-bios-tiny-r0.qcow2
```

## Prerequisites

### 1. Required packages

```sh
apk add --no-cache curl bash iptables
```

### 2. Kernel modules

```sh
modprobe br_netfilter
modprobe overlay
modprobe nf_conntrack
```

Persist across reboots — create `/etc/modules-load.d/k3s.conf`:

```
br_netfilter
overlay
nf_conntrack
```

### 3. Sysctl settings

Add to `/etc/sysctl.conf`:

```
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
```

Apply: `sysctl -p`

### 4. Disable swap

```sh
swapoff -a
```

## Install k3s

The install script auto-detects OpenRC and creates `/etc/init.d/k3s`:

```sh
export K3S_KUBECONFIG_MODE="644"
curl -sfL https://get.k3s.io | sh -
```

## Service management (OpenRC, not systemctl)

```sh
rc-service k3s start
rc-service k3s stop
rc-service k3s status

# enable on boot
rc-update add k3s default
```

Logs: `/var/log/k3s.log`

## Verify

```sh
k3s kubectl get nodes
# or
kubectl get nodes   # if KUBECONFIG is set
```
