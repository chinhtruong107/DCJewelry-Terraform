resource "aws_db_subnet_group" "database" {
  name       = "dcjewelry-db-subnet-group"
  subnet_ids = var.subnet_ids
}

resource "aws_db_instance" "database" {
  identifier             = "dcjewelry-database"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  storage_type           = "gp3"
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.database.name
  vpc_security_group_ids = [var.database_security_group_id]
  publicly_accessible    = false
  skip_final_snapshot    = true
}
