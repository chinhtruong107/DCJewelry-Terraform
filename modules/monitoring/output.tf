output "private_ip" {
  value = aws_instance.pmm_server.private_ip
}

output "instance_id" {
  value = aws_instance.pmm_server.id
}
