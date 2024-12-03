locals {
  name = "pet-adoption"
}

module "vpc" {
  source   = "./module/vpc"
  az1      = "eu-west-1a"
  az2      = "eu-west-1b"
  vpc-name = "${local.name}-vpc"
  pub1     = "${local.name}-pub1"
  pub2     = "${local.name}-pub2"
  prv1     = "${local.name}-prv1"
  prv2     = "${local.name}-prv2"
  igw      = "${local.name}-igw"
  eip      = "${local.name}-eip"
  nat      = "${local.name}-nat"
  pub-rt   = "${local.name}-pub-rt"
  prv-rt   = "${local.name}-prv-rt"
}

module "security-group" {
  source = "./module/security-group"
  vpc-id = module.vpc.vpc-id
}

module "keypair" {
  source       = "./module/keypair"
  prv_filename = "${local.name}-private-key"
  pub_filename = "${local.name}-public-key"

}

# module "docker" {
#   source       = "./module/docker"
#   redhat       = "ami-07d4917b6f95f5c2a"
#   docker-sg    = module.security-group.docker-sg
#   subnet-id    = module.vpc.pubsub-1-id
#   pub-key-name = module.keypair.public-key-id
# }

module "bastion-host" {
  source = "./module/bastion-host"
  redhat = "ami-07d4917b6f95f5c2a"
  bastion-subnet = module.vpc.pubsub-1-id
  bastion-sg = module.security-group.bastion-sg
  public-key = module.keypair.public-key-id
  private-key = module.keypair.private-key-pem
}

module "nexus" {
  source = "./module/nexus"
  redhat = "ami-07d4917b6f95f5c2a"
  nexus-subnet = module.vpc.pubsub-1-id
  public-key = module.keypair.public-key-id
  nexus-sg = module.security-group.nexus-sg
  pub-subnets = [module.vpc.pubsub-1-id, module.vpc.pubsub-2-id]
  cert-arn = data.aws_acm_certificate.certificate.arn
  newrelic-user-licence = data.vault_generic_secret.vault-secret-nr.data["NEW_RELIC_ACCOUNT_ID"]
  newrelic-acct-id = data.vault_generic_secret.vault-secret-nr.data["NEW_RELIC_API_KEY"]
  newrelic-reg = "EU"
}

module "sonarqube" {
  source       = "./module/sonarqube"
  ubuntu       = "ami-0c38b837cd80f13bb"
  public-key      = module.keypair.public-key-id
  sonar-sg     = module.security-group.sonarqube-sg
  sonar-subnet = module.vpc.pubsub-1-id
  cert-arn     = data.aws_acm_certificate.certificate.arn
  pub-subnets      = [module.vpc.pubsub-1-id, module.vpc.pubsub-2-id]
}

module "ansible" {
  source               = "./module/ansible"
  redhat               = "ami-07d4917b6f95f5c2a"
  ansible-subnet       = module.vpc.prvsub-1-id
  pub-key              = module.keypair.public-key-id
  ansible-sg           = [module.security-group.ansible-sg]
  private-key          = module.keypair.private-key-pem
  bastion-host         = module.bastion-host.bastion-ip
  newrelic-license-key  = data.vault_generic_secret.vault-secret-nr.data["NEW_RELIC_API_KEY"]
  newrelic-acct-id      = data.vault_generic_secret.vault-secret-nr.data["NEW_RELIC_ACCOUNT_ID"]
  deployment           = "./module/ansible/deployment.yml"
  prod-bashscript      = "./module/ansible/prod-bashscript.sh"
  stage-bashscript     = "./module/ansible/stage-bashscript.sh"
  nexus-ip             = module.nexus.nexus-ip
}

module "rds" {
  source       = "./module/rds"
  rds-subgroup = "rds_subgroup" #can be given any name
  rds-subnet   = [module.vpc.prvsub-1-id, module.vpc.prvsub-2-id]
  db-name      = "petclinic"
  db-username  = data.vault_generic_secret.vault-secret.data["username"]
  db-password  = data.vault_generic_secret.vault-secret.data["password"]
  rds-sg       = [module.security-group.rds-sg]
}

module "production-asg" {
  source        = "./module/production-asg"
  vpc-id        = module.vpc.vpc-id
  prod-sg       = module.security-group.docker-sg
  prod-subnets       = [module.vpc.pubsub-1-id, module.vpc.pubsub-2-id] #under load balancer configuration
  alb-prod-name = "${local.name}-prod-asg"
  redhat        = "ami-07d4917b6f95f5c2a"
  # asg-sg = module.security-group.docker-sg
  pub-key               = module.keypair.public-key-id
  nex-ip = module.nexus.nexus-ip
  newrelic-user-licence  = data.vault_generic_secret.vault-secret-nr.data["NEW_RELIC_API_KEY"]
  newrelic-acct-id      = data.vault_generic_secret.vault-secret-nr.data["NEW_RELIC_ACCOUNT_ID"]
  # newrelic-user-licence = var.newrelic-api
  newrelic-reg       = "EU"
  prod-asg-name         = "${local.name}-prod-asg"
  vpc-zone-identifier   = [module.vpc.prvsub-1-id, module.vpc.prvsub-2-id] #under asg configuration
  prod-asg-policy-name  = "prod-asg-policy"
  cert-arn              = data.aws_acm_certificate.certificate.arn
}

module "stage-asg" {
  source   = "./module/stage-asg"
  vpc-id        = module.vpc.vpc-id
  stage-sg      = module.security-group.docker-sg
  stage-subnets       = [module.vpc.pubsub-1-id, module.vpc.pubsub-2-id] #under load balancer configuration
  alb-stage-name = "${local.name}-stage-asg"
  redhat        = "ami-07d4917b6f95f5c2a"
  # asg-sg = module.security-group.docker-sg
  pub-key               = module.keypair.public-key-id
  nex-ip = module.nexus.nexus-ip
  # newrelic-user-licence = var.newrelic-api
  newrelic-user-licence  = data.vault_generic_secret.vault-secret-nr.data["NEW_RELIC_API_KEY"]
  newrelic-acct-id      = data.vault_generic_secret.vault-secret-nr.data["NEW_RELIC_ACCOUNT_ID"]
  newrelic-reg       = "EU"
  stage-asg-name         = "${local.name}-stage-asg"
  vpc-zone-identifier   = [module.vpc.prvsub-1-id, module.vpc.prvsub-2-id] #under asg configuration
  stage-asg-policy-name  = "prod-asg-policy"
  cert-arn              = data.aws_acm_certificate.certificate.arn
}

module "route53" {
  source                = "./module/route53"
  domain_name           = "dobetabeta.shop"
  nexus_domain_name     = "nexus2.dobetabeta.shop"
  nexus_lb_dns_name     = module.nexus.nexus-dns
  nexus_lb_zone_id      = module.nexus.nexus-zone-id
  sonarqube_domain_name = "sonarqube2.dobetabeta.shop"
  sonarqube_lb_dns_name = module.sonarqube.sonar-dns
  sonarqube_lb_zone_id  = module.sonarqube.sonar-zone-id
  prod_domain_name      = "prod2.dobetabeta.shop"
  prod_lb_dns_name      = module.production-asg.prod-lb-dns
  prod_lb_zone_id       = module.production-asg.prod-zone-id
  stage_domain_name     = "stage2.dobetabeta.shop"
  stage_lb_dns_name     = module.stage-asg.stage-lb-dns
  stage_lb_zone_id      = module.stage-asg.stage-zone-id
}

data "aws_acm_certificate" "certificate" {
  domain      = "dobetabeta.shop"
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}