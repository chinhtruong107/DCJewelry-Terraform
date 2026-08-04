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
  source            = "./modules/security"
  region            = var.region
  vpc_id            = module.networking.vpc_id
  control_node_cidr = var.control_node_cidr
}

resource "aws_key_pair" "dcjewelry_keypair" {
  key_name   = "dcjewelry-keypair"
  public_key = file(var.keypair_path)
}
module "compute" {
  source                 = "./modules/compute"
  region                 = var.region
  image_id               = var.amis[var.region]
  key_name               = aws_key_pair.dcjewelry_keypair.key_name
  instance_type          = var.instance_type
  security_group_public  = [module.security.public_security_group_id]
  security_group_private = [module.security.private_security_group_id]
  security_group_control = [module.security.control_security_group_id]
  subnet_id_frontend     = module.networking.public_subnet_ids[0]
  subnet_id_backend      = module.networking.private_subnet_ids[1]
  subnet_id_control      = module.networking.public_subnet_ids[0]
}

module "database" {
  source                     = "./modules/database"
  subnet_ids                 = [module.networking.private_subnet_ids[1], module.networking.private_subnet_ids[2]]
  database_security_group_id = module.security.database_security_group_id
  db_name                    = var.db_name
  db_username                = var.db_username
  db_password                = var.db_password
  db_engine_version          = var.db_engine_version
  db_instance_class          = var.db_instance_class
  db_allocated_storage       = var.db_allocated_storage
  db_storage_type            = var.db_storage_type
  db_multi_az                = var.db_multi_az
}
