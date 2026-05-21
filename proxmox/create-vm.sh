#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 -n <vm-name> -i <image-path> [-d <vm-id>] [-s <storage>] [-c <cores>] [-m <memory-mb>] [-u <snippet-filename>] [-k <k3s-token>] [-p <server-ip>]"
  echo ""
  echo "  -n  VM name (required)"
  echo "  -i  Path to disk image to import (required)"
  echo "  -d  VM ID (default: next available starting at 100)"
  echo "  -s  Proxmox storage (default: local-lvm)"
  echo "  -c  vCPU cores (default: 2)"
  echo "  -m  RAM in MB (default: 2048)"
  echo "  -u  Snippet filename in /var/lib/vz/snippets/ (optional) — passed as vendor config so Proxmox still injects hostname"
  echo "  -k  k3s token for agent join (substitutes %%K3S_TOKEN%% in snippet)"
  echo "  -p  Control plane IP for agent join (substitutes %%K3S_URL%% in snippet)"
  exit 1
}

VM_NAME=""
IMAGE_PATH=""
VM_ID=""
STORAGE="local-lvm"
CORES=2
MEMORY=2048
USERDATA_PATH=""
K3S_TOKEN=""
SERVER_IP=""

while getopts "n:i:d:s:c:m:u:k:p:h" opt; do
  case $opt in
    n) VM_NAME="$OPTARG" ;;
    i) IMAGE_PATH="$OPTARG" ;;
    d) VM_ID="$OPTARG" ;;
    s) STORAGE="$OPTARG" ;;
    c) CORES="$OPTARG" ;;
    m) MEMORY="$OPTARG" ;;
    u) USERDATA_PATH="$OPTARG" ;;
    k) K3S_TOKEN="$OPTARG" ;;
    p) SERVER_IP="$OPTARG" ;;
    h) usage ;;
    *) usage ;;
  esac
done

[[ -z "$VM_NAME" ]] && { echo "Error: VM name is required (-n)"; usage; }
[[ -z "$IMAGE_PATH" ]] && { echo "Error: Image path is required (-i)"; usage; }
[[ ! -f "$IMAGE_PATH" ]] && { echo "Error: Image not found: $IMAGE_PATH"; exit 1; }
[[ -n "$USERDATA_PATH" && ! -f "/var/lib/vz/snippets/$USERDATA_PATH" ]] && { echo "Error: Snippet not found: /var/lib/vz/snippets/$USERDATA_PATH"; exit 1; }

# pick next available VM ID if not specified
if [[ -z "$VM_ID" ]]; then
  VM_ID=100
  while qm status "$VM_ID" &>/dev/null; do
    ((VM_ID++))
  done
fi

echo "Creating UEFI VM: name=$VM_NAME id=$VM_ID storage=$STORAGE cores=$CORES memory=${MEMORY}MB"

qm create "$VM_ID" \
  --name "$VM_NAME" \
  --cores "$CORES" \
  --memory "$MEMORY" \
  --machine q35 \
  --bios ovmf \
  --cpu host \
  --net0 "virtio,bridge=vmbr0" \
  --ipconfig0 "ip=dhcp" \
  --scsihw virtio-scsi-pci \
  --serial0 socket

qm set "$VM_ID" --efidisk0 "${STORAGE}:1,efitype=4m,pre-enrolled-keys=0"

qm disk import "$VM_ID" "$IMAGE_PATH" "$STORAGE"
qm set "$VM_ID" --scsi0 "${STORAGE}:vm-${VM_ID}-disk-1"

qm resize "$VM_ID" scsi0 +10G

qm set "$VM_ID" --boot order=scsi0

qm set "$VM_ID" --ide2 "${STORAGE}:cloudinit"

if [[ -n "$USERDATA_PATH" ]]; then
  SNIPPET_SRC="/var/lib/vz/snippets/${USERDATA_PATH}"
  SNIPPET_DEST="${SNIPPET_SRC}"

  if [[ -n "$K3S_TOKEN" && -n "$SERVER_IP" ]]; then
    SNIPPET_DEST="/var/lib/vz/snippets/${VM_NAME}-vendor.yaml"
    sed -e "s|%%K3S_TOKEN%%|${K3S_TOKEN}|g" \
        -e "s|%%K3S_URL%%|https://${SERVER_IP}:6443|g" \
        "$SNIPPET_SRC" > "$SNIPPET_DEST"
  fi

  qm set "$VM_ID" --cicustom "vendor=local:snippets/$(basename "$SNIPPET_DEST")"
  qm cloudinit update "$VM_ID"
fi

echo "VM $VM_ID ($VM_NAME) created. Start with: qm start $VM_ID"
