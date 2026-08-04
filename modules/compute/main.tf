resource "aws_instance" "Frontend-instance" {
  ami                    = var.image_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = var.security_group_public
  subnet_id              = var.subnet_id_frontend
  tags = {
    Name = "Frontend"
  }
}

resource "aws_instance" "Backend-instance" {
  ami                    = var.image_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = var.security_group_private
  subnet_id              = var.subnet_id_backend
  tags = {
    Name = "Backend"
  }
}

resource "aws_eip" "demo-eip" {
  domain   = "vpc"
  instance = aws_instance.Frontend-instance.id
}
