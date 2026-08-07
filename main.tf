provider "aws" {
  region = var.region
}

# Complete VPC and subnets.
module "networking" {
  source = "./modules/networking"
  config = var.networking
}

module "security" {
  source = "./modules/security"
  vpc_id = module.networking.vpc_id
  config = var.security
}

resource "aws_key_pair" "dcjewelry_keypair" {
  key_name   = var.compute.key_name
  public_key = file(var.compute.keypair_path)
}

module "compute" {
  source                 = "./modules/compute"
  config                 = merge(var.compute, { key_name = aws_key_pair.dcjewelry_keypair.key_name })
  security_group_public  = [module.security.public_security_group_id]
  security_group_private = [module.security.private_security_group_id]
  security_group_control = [module.security.control_security_group_id]
  subnet_id_frontend     = module.networking.public_subnet_ids[0]
  subnet_id_backend      = module.networking.private_subnet_ids[1]
  subnet_id_control      = module.networking.public_subnet_ids[0]
}

module "database" {
  source                     = "./modules/database"
  config                     = var.database
  subnet_ids                 = [module.networking.private_subnet_ids[0], module.networking.private_subnet_ids[1]]
  database_security_group_id = module.security.database_security_group_id
}


module "monitoring" {
  source             = "./modules/monitoring"
  config             = merge(var.monitoring, { key_name = aws_key_pair.dcjewelry_keypair.key_name })
  subnet_id          = module.networking.private_subnet_ids[0]
  security_group_ids = [module.security.monitoring_security_group_id]
  depends_on         = [module.networking]
}
