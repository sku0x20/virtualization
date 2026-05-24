resource "proxmox_virtual_environment_download_url" "alpine" {
  node_name    = var.proxmox_node
  content_type = "iso"
  datastore_id = "local"
  url          = var.alpine_image_url
  file_name    = "alpine-cloud.qcow2"
}
