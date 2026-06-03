module "networking" {
  source = "../../modules/aws/networking"

  environment  = "staging"
  project_name = var.project_name
  vpc_cidr     = var.aws_vpc_cidr
  azs          = var.aws_azs
}

module "database" {
  source = "../../modules/aws/database"

  environment            = "staging"
  project_name           = var.project_name
  private_subnet_ids     = module.networking.private_subnet_ids
  data_security_group_id = module.networking.data_security_group_id
  multi_az               = true
  backup_retention       = 7
  instance_class         = "db.t4g.medium"
}

module "cache" {
  source = "../../modules/aws/cache"

  environment            = "staging"
  project_name           = var.project_name
  private_subnet_ids     = module.networking.private_subnet_ids
  data_security_group_id = module.networking.data_security_group_id
  node_type              = "cache.t4g.medium"
  num_cache_nodes        = 2
}

module "messaging" {
  source = "../../modules/aws/messaging"

  environment                 = "staging"
  project_name                = var.project_name
  private_subnet_ids          = module.networking.private_subnet_ids
  messaging_security_group_id = module.networking.messaging_security_group_id
  number_of_broker_nodes      = 2
  instance_type               = "kafka.m5.large"
  partitions_per_topic        = 3
}

module "secrets" {
  source = "../../modules/aws/secrets"

  environment  = "staging"
  project_name = var.project_name
  db_password  = module.database.db_password
}

module "compute" {
  source = "../../modules/aws/compute"

  environment           = "staging"
  project_name          = var.project_name
  vpc_id                = module.networking.vpc_id
  public_subnet_ids     = module.networking.public_subnet_ids
  private_subnet_ids    = module.networking.private_subnet_ids
  app_security_group_id = module.networking.app_security_group_id
  alb_security_group_id = module.networking.alb_security_group_id
  min_capacity          = 2
  max_capacity          = 5
  rds_endpoint          = module.database.rds_endpoint
  redis_endpoint        = module.cache.redis_endpoint
  kafka_brokers         = module.messaging.bootstrap_brokers
  secrets_manager_arns  = values(module.secrets.secret_arns)
}

module "firebase_auth" {
  source = "../../modules/gcp/firebase-auth"

  environment                = "staging"
  project_name               = var.project_name
  gcp_project_id             = var.gcp_project_id
  google_oauth_client_id     = var.google_oauth_client_id
  google_oauth_client_secret = var.google_oauth_client_secret
}

module "azure_ai_ml" {
  source = "../../modules/azure/ai-ml"

  environment         = "staging"
  project_name        = var.project_name
  resource_group_name = var.azure_resource_group_name
  location            = var.azure_region
  gpt4_capacity       = 5
}
