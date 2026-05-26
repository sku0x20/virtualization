resource "proxmox_virtual_environment_file" "agent_userdata" {
  node_name    = var.proxmox_node
  content_type = "snippets"
  datastore_id = "local"

  source_raw {
    data = templatefile("${path.module}/userdata/agent.yaml.tftpl", {
      k3s_url   = "https://${local.control_ip}:6443"
      k3s_token = var.k3s_token
    })
    file_name = "k3s-agent-vendor.yaml"
  }
}

resource "proxmox_virtual_environment_vm" "agent" {
  count     = 1
  name      = "k3s-agent-${count.index + 1}"
  node_name = var.proxmox_node
  started          = true
  stop_on_destroy  = true

  machine = "q35"
  bios    = "ovmf"

  cpu {
    cores = 1
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
    datastore_id      = "local-lvm"
    type              = "4m"
    pre_enrolled_keys = false
  }

  disk {
    datastore_id = "local-lvm"
    import_from  = "local:import/nocloud_alpine-3.23.4-x86_64-uefi-cloudinit-r0.qcow2"
    interface    = "scsi0"
    size         = 12
    file_format  = "raw"
    cache        = "writeback"
  }

  serial_device {}

  boot_order = ["scsi0"]

  agent {
    enabled = true
    timeout = "15m"
  }

  initialization {
    vendor_data_file_id = proxmox_virtual_environment_file.agent_userdata.id
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }
}
