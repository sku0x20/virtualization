resource "proxmox_virtual_environment_file" "agent_userdata" {
  node_name    = var.proxmox_node
  content_type = "snippets"
  datastore_id = "local"

  source_raw {
    data = templatefile("${path.module}/userdata/agent.yaml.tftpl", {
      k3s_url   = "https://${local.control_ip}:6443"
      k3s_token = local.k3s_node_token
    })
    file_name = "k3s-agent-vendor.yaml"
  }
}

resource "proxmox_virtual_environment_vm" "agent" {
  count     = var.agent_count
  name      = "k3s-agent-${count.index + 1}"
  node_name = var.proxmox_node
  started          = true
  stop_on_destroy  = true

  machine = "q35"
  bios    = "ovmf"

  cpu {
    cores = var.agent_cores
    type  = "host"
  }

  memory {
    dedicated = var.agent_memory
    floating  = var.agent_memory
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
