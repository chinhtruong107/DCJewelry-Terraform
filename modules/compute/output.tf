output "instance_ip_addr_public" {
  value = aws_eip.demo-eip.public_ip
}

output "instance_ip_addr_private" {
  value = aws_instance.Frontend-instance.private_ip
}

output "control_node_public_ip" {
  value = aws_eip.control-node-eip.public_ip
}

output "backend_private_ip" {
  value = aws_instance.Backend-instance.private_ip
}

output "instance_ids" {
  value = {
    frontend     = aws_instance.Frontend-instance.id
    backend      = aws_instance.Backend-instance.id
    control_node = aws_instance.Control-node.id
  }
}
