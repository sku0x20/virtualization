output "control_ip" {
  description = "DHCP IP of the k3s control plane node"
  value       = local.control_ip
}

output "agent_ips" {
  description = "DHCP IPs of the k3s agent nodes"
  value       = [for vm in proxmox_virtual_environment_vm.agent : vm.ipv4_addresses[1][0]]
}

output "kubeconfig_hint" {
  description = "How to fetch kubeconfig from the control node"
  value       = "scp alpine@${local.control_ip}:/etc/rancher/k3s/k3s.yaml ./kubeconfig && sed -i 's/127.0.0.1/${local.control_ip}/' ./kubeconfig"
}
