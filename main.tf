provider "aws" {
  region = var.region
}

#Create a complete VPC using module networking
module "networking" {
  source              = "./modules/networking"
  region              = var.region
  availability_zone_1 = var.availability_zone_1
  availability_zone_2 = var.availability_zone_2
  cidr_block          = var.cidr_block
  public_subnet_ips   = var.public_subnet_ips
  private_subnet_ips  = var.private_subnet_ips
}
module "security" {
  source = "./modules/security"
  region = var.region
  vpc_id = module.networking.vpc_id
}

resource "aws_key_pair" "udemy-keypair" {
  key_name   = "udemy-keypair"
  public_key = file(var.keypair_path)
}
module "compute" {
  source                 = "./modules/compute"
  region                 = var.region
  image_id               = var.amis[var.region]
  key_name               = aws_key_pair.udemy-keypair.key_name
  instance_type          = var.instance_type
  security_group_public  = [module.security.public_security_group_id]
  security_group_private = [module.security.private_security_group_id]
  subnet_id_frontend     = module.networking.public_subnet_ids[0]
  subnet_id_backend      = module.networking.private_subnet_ids[1]
}

module "database" {
  source                     = "./modules/database"
  subnet_ids                 = [module.networking.private_subnet_ids[1], module.networking.private_subnet_ids[2]]
  database_security_group_id = module.security.private_security_group_id
  db_name                    = var.db_name
  db_username                = var.db_username
  db_password                = var.db_password
}
