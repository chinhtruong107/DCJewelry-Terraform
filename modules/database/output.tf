output "endpoint" {
  value = aws_db_instance.database.address
}

output "identifier" {
  value = aws_db_instance.database.identifier
}
