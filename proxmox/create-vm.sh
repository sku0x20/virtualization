#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 -n <vm-name> -i <image-path> [-d <vm-id>] [-s <storage>] [-c <cores>] [-m <memory-mb>] [-z <disk-size>] [-k <ssh-pubkey-file>] [-u <snippet-filename>]"
  echo ""
  echo "  -n  VM name (required)"
  echo "  -i  Path to disk image to import (required)"
  echo "  -d  VM ID (default: next available starting at 100)"
  echo "  -s  Proxmox storage (default: local-lvm)"
  echo "  -c  vCPU cores (default: 2)"
  echo "  -m  RAM in MB (default: 2048)"
  echo "  -z  Disk size after import, e.g. 8G (default: +2G — grow by 2G; fixes GPT PMBR mismatch)"
  echo "  -k  SSH public key file to inject (recommended for Alpine/tiny-cloud)"
  echo "  -u  Snippet filename in /var/lib/vz/snippets/ (optional, e.g. user-data.yaml)"
  exit 1
}

VM_NAME=""
IMAGE_PATH=""
VM_ID=""
STORAGE="local-lvm"
CORES=2
MEMORY=2048
DISK_SIZE="+2G"
SSH_KEY_FILE=""
USERDATA_PATH=""

while getopts "n:i:d:s:c:m:z:k:u:h" opt; do
  case $opt in
    n) VM_NAME="$OPTARG" ;;
    i) IMAGE_PATH="$OPTARG" ;;
    d) VM_ID="$OPTARG" ;;
    s) STORAGE="$OPTARG" ;;
    c) CORES="$OPTARG" ;;
    m) MEMORY="$OPTARG" ;;
    z) DISK_SIZE="$OPTARG" ;;
    k) SSH_KEY_FILE="$OPTARG" ;;
    u) USERDATA_PATH="$OPTARG" ;;
    h) usage ;;
    *) usage ;;
  esac
done

[[ -z "$VM_NAME" ]] && { echo "Error: VM name is required (-n)"; usage; }
[[ -z "$IMAGE_PATH" ]] && { echo "Error: Image path is required (-i)"; usage; }
[[ ! -f "$IMAGE_PATH" ]] && { echo "Error: Image not found: $IMAGE_PATH"; exit 1; }
[[ -n "$SSH_KEY_FILE" && ! -f "$SSH_KEY_FILE" ]] && { echo "Error: SSH key file not found: $SSH_KEY_FILE"; exit 1; }
[[ -n "$USERDATA_PATH" && ! -f "/var/lib/vz/snippets/$USERDATA_PATH" ]] && { echo "Error: Snippet not found: /var/lib/vz/snippets/$USERDATA_PATH"; exit 1; }

if [[ -z "$SSH_KEY_FILE" && -z "$USERDATA_PATH" ]]; then
  echo "Warning: no SSH key (-k) or user-data (-u) provided — tiny-cloud-boot will fail on Alpine images"
fi

# pick next available VM ID if not specified
if [[ -z "$VM_ID" ]]; then
  VM_ID=100
  while qm status "$VM_ID" &>/dev/null; do
    ((VM_ID++))
  done
fi

echo "Creating UEFI VM: name=$VM_NAME id=$VM_ID storage=$STORAGE cores=$CORES memory=${MEMORY}MB disk=$DISK_SIZE"

qm create "$VM_ID" \
  --name "$VM_NAME" \
  --cores "$CORES" \
  --memory "$MEMORY" \
  --machine q35 \
  --bios ovmf \
  --cpu host \
  --balloon 1 \
  --net0 "virtio,bridge=vmbr0" \
  --ipconfig0 "ip=dhcp" \
  --serial0 socket

qm set "$VM_ID" --efidisk0 "${STORAGE}:1,efitype=4m,pre-enrolled-keys=0"

qm disk import "$VM_ID" "$IMAGE_PATH" "$STORAGE"
qm set "$VM_ID" --scsi0 "${STORAGE}:vm-${VM_ID}-disk-1"
qm set "$VM_ID" --scsihw virtio-scsi-pci
qm resize "$VM_ID" scsi0 "$DISK_SIZE"
# after resize the backup GPT is no longer at the last LBA; move it so UEFI can boot
sgdisk -e "$(pvesm path "${STORAGE}:vm-${VM_ID}-disk-1")"
qm set "$VM_ID" --boot order=scsi0

qm set "$VM_ID" --ide2 "${STORAGE}:cloudinit"

[[ -n "$SSH_KEY_FILE" ]] && qm set "$VM_ID" --sshkeys "$SSH_KEY_FILE"

if [[ -n "$USERDATA_PATH" ]]; then
  qm set "$VM_ID" --cicustom "user=local:snippets/${USERDATA_PATH}"
  qm cloudinit update "$VM_ID"
fi

echo "VM $VM_ID ($VM_NAME) created. Start with: qm start $VM_ID"
