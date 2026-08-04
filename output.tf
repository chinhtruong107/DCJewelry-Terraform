output "instance_ip_addr_public" {
  value = module.compute.instance_ip_addr_public
}

output "instance_ip_addr_private" {
  value = module.compute.instance_ip_addr_private
}

output "control_node_public_ip" {
  value = module.compute.control_node_public_ip
}
