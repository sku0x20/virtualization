resource "proxmox_virtual_environment_file" "control_userdata" {
  node_name    = var.proxmox_node
  content_type = "snippets"
  datastore_id = "local"

  source_raw {
    data      = templatefile("${path.module}/userdata/control.yaml.tftpl", { k3s_token = var.k3s_token })
    file_name = "k3s-control-vendor.yaml"
  }
}

resource "proxmox_virtual_environment_vm" "control" {
  name      = "k3s-control"
  node_name = var.proxmox_node
  started          = true
  stop_on_destroy  = true

  machine = "q35"
  bios    = "ovmf"

  cpu {
    cores = 2
    type  = "host"
  }

  memory {
    dedicated = 2048
    floating  = 2048
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  scsi_hardware = "virtio-scsi-pci"

  efi_disk {
    datastore_id      = var.storage
    type              = "4m"
    pre_enrolled_keys = false
  }

  disk {
    datastore_id = var.storage
    import_from  = var.alpine_image_id
    interface    = "scsi0"
    size         = 12
    file_format  = "raw"
    cache        = "writeback"
  }

  serial_device {}

  boot_order = ["scsi0"]

  # qemu-guest-agent installed via cloud-init; Tofu polls until it responds
  # so it can read the DHCP IP before creating agent snippet/VMs.
  agent {
    enabled = true
    timeout = "15m"
  }

  initialization {
    vendor_data_file_id = proxmox_virtual_environment_file.control_userdata.id
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }
}

locals {
  # ipv4_addresses: [[loopback IPs], [eth0 IPs], ...]
  control_ip = proxmox_virtual_environment_vm.control.ipv4_addresses[1][0]
}
