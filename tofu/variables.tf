variable "proxmox_endpoint" {
  description = "Proxmox API endpoint, e.g. https://192.168.1.x:8006/"
  type        = string
}

variable "proxmox_api_token" {
  description = "API token in the form USER@REALM!TOKENID=UUID, e.g. root@pam!tofu=xxxxxxxx-..."
  type        = string
  sensitive   = true
}

variable "proxmox_ssh_username" {
  description = "SSH username for Proxmox host (used for snippet uploads)"
  type        = string
  default     = "root"
}

variable "proxmox_ssh_private_key_path" {
  description = "Path to the SSH private key file for Proxmox host (used for snippet uploads)"
  type        = string
  default     = "~/.ssh/proxmox_tofu"
}

variable "proxmox_node" {
  description = "Proxmox node name (shown in the web UI under Datacenter)"
  type        = string
  default     = "pve"
}

variable "proxmox_node_address" {
  description = "Proxmox node address"
  type = string
  default = "pve.local"
}

variable "storage" {
  description = "Proxmox storage for VM disks"
  type        = string
  default     = "local-lvm"
}

variable "alpine_image_id" {
  description = "Proxmox storage path to the Alpine cloud image, e.g. local:iso/alpine-cloud.qcow2"
  type        = string
  default     = "local:iso/generic_alpine-3.23.4-x86_64-uefi-cloudinit-r0.qcow2"
}

variable "k3s_token" {
  description = "Shared secret for k3s cluster join"
  type        = string
  sensitive   = true
}

variable "agent_count" {
  description = "Number of k3s agent nodes"
  type        = number
  default     =  3
}

variable "control_cores" {
  type    = number
  default = 1
}

variable "control_memory" {
  description = "RAM in MB for control plane"
  type        = number
  default     = 1024
}

variable "agent_cores" {
  type    = number
  default = 2
}

variable "agent_memory" {
  description = "RAM in MB for each agent"
  type        = number
  default     = 2048
}
