resource "aws_db_subnet_group" "database" {
  name       = "dcjewelry-db-subnet-group"
  subnet_ids = var.subnet_ids
}

resource "aws_db_instance" "database" {
  identifier             = var.config.identifier
  engine                 = "mysql"
  engine_version         = var.config.engine_version
  instance_class         = var.config.instance_class
  allocated_storage      = var.config.allocated_storage
  storage_type           = var.config.storage_type
  multi_az               = var.config.multi_az
  storage_encrypted      = true
  db_name                = var.config.name
  username               = var.config.username
  password               = var.config.password
  db_subnet_group_name   = aws_db_subnet_group.database.name
  vpc_security_group_ids = [var.database_security_group_id]
  publicly_accessible    = false
  skip_final_snapshot    = true
}
