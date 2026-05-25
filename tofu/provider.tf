terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.107"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = false

  ssh {
    username    = var.proxmox_ssh_username
    private_key = file(var.proxmox_ssh_private_key_path)
  }
}
