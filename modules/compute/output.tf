output "instance_ip_addr_public" {
  value = aws_eip.demo-eip.public_ip
}

output "instance_ip_addr_private" {
  value = aws_instance.Frontend-instance.private_ip
}

output "control_node_public_ip" {
  value = aws_eip.control-node-eip.public_ip
}
