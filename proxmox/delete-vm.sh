#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 <vm-id>"
  exit 1
}

[[ $# -lt 1 ]] && usage

VM_ID="$1"

if ! qm status "$VM_ID" &>/dev/null; then
  echo "Error: VM $VM_ID not found"
  exit 1
fi

STATUS=$(qm status "$VM_ID" | awk '{print $2}')
if [[ "$STATUS" == "running" ]]; then
  echo "Stopping VM $VM_ID..."
  qm stop "$VM_ID"
fi

echo "Destroying VM $VM_ID..."
qm destroy "$VM_ID" --purge

echo "VM $VM_ID deleted."
