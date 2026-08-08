resource "aws_instance" "pmm_server" {
  ami                         = var.config.image_id
  instance_type               = var.config.instance_type
  key_name                    = var.config.key_name
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.security_group_ids
  iam_instance_profile        = var.iam_instance_profile
  associate_public_ip_address = false
  user_data                   = file("${path.module}/user_data.sh")

  root_block_device {
    volume_size = var.config.volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "PMM Server"
  }
}
