resource "aws_db_subnet_group" "database" {
  name       = "dcjewelry-db-subnet-group"
  subnet_ids = var.subnet_ids
}

resource "aws_db_instance" "database" {
  identifier             = var.db_identifier
  engine                 = "mysql"
  engine_version         = var.db_engine_version
  instance_class         = var.db_instance_class
  allocated_storage      = var.db_allocated_storage
  storage_type           = var.db_storage_type
  multi_az               = var.db_multi_az
  storage_encrypted      = true
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.database.name
  vpc_security_group_ids = [var.database_security_group_id]
  publicly_accessible    = false
  skip_final_snapshot    = true
}
