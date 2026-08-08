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
  iam_instance_profile   = module.observability.cloudwatch_agent_instance_profile_name
}

module "database" {
  source                     = "./modules/database"
  config                     = var.database
  subnet_ids                 = [module.networking.private_subnet_ids[0], module.networking.private_subnet_ids[1]]
  database_security_group_id = module.security.database_security_group_id
}

module "observability" {
  source = "./modules/observability"

  alert_topic_name    = var.observability.alert_topic_name
  log_retention_days  = var.observability.log_retention_days
  telegram_bot_token  = var.observability.telegram_bot_token
  telegram_chat_id    = var.observability.telegram_chat_id
  ec2_instances       = merge(module.compute.instance_ids, { pmm = module.monitoring.instance_id })
  database_identifier = module.database.identifier

  cpu_threshold_percent    = var.observability.cpu_threshold_percent
  memory_threshold_percent = var.observability.memory_threshold_percent
  disk_threshold_percent   = var.observability.disk_threshold_percent
  rds_free_storage_gib     = var.observability.rds_free_storage_gib
}

module "monitoring" {
  source               = "./modules/monitoring"
  config               = merge(var.monitoring, { key_name = aws_key_pair.dcjewelry_keypair.key_name })
  subnet_id            = module.networking.private_subnet_ids[0]
  security_group_ids   = [module.security.monitoring_security_group_id]
  iam_instance_profile = module.observability.cloudwatch_agent_instance_profile_name
  depends_on           = [module.networking]
}
