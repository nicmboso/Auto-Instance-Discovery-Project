locals {
  name = "pet-adoption"
}

module "vpc" {
  source   = "./modules/vpc"
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
  source = "./modules/security-group"
  vpc-id = module.vpc.vpc-id
}

module "keypair" {
  source       = "./modules/keypair"
  prv_filename = "${local.name}-private-key"
  pub_filename = "${local.name}-public-key"

}

module "docker" {
  source       = "./modules/docker"
  redhat       = "ami-07d4917b6f95f5c2a"
  docker-sg    = module.security-group.docker-sg
  subnet-id    = module.vpc.pubsub-1-id
  pub-key-name = module.keypair.public-key-id
}

module "bastion" {
  source          = "./modules/bastion"
  redhat          = "ami-07d4917b6f95f5c2a"
  subnet-id       = module.vpc.pubsub-1-id
  bastion-sg      = module.security-group.bastion-sg
  public-key-name = module.keypair.public-key-id
  private-key     = module.keypair.private-key-pem
}

module "nexus" {
  source       = "./modules/nexus"
  redhat       = "ami-07d4917b6f95f5c2a"
  nexus_subnet = module.vpc.pubsub-1-id
  pub_key      = module.keypair.public-key-id
  nexus-sg     = module.security-group.nexus-sg
  cert-arn     = data.aws_acm_certificate.certificate.arn
  subnets      = [module.vpc.pubsub-1-id, module.vpc.pubsub-2-id]
}

module "sonar" {
  source       = "./modules/sonar"
  ubuntu       = "ami-0c38b837cd80f13bb"
  pub_key      = module.keypair.public-key-id
  sonar-sg     = module.security-group.sonarqube-sg
  sonar-subnet = module.vpc.pubsub-1-id
  cert-arn     = data.aws_acm_certificate.certificate.arn
  subnets      = [module.vpc.pubsub-1-id, module.vpc.pubsub-2-id]
}

module "ansible" {
  source               = "./modules/ansible"
  redhat               = "ami-07d4917b6f95f5c2a"
  ansible-subnet       = module.vpc.prvsub-1-id
  pub-key              = module.keypair.public-key-id
  ansible-sg           = [module.security-group.ansible-sg]
  private-key          = module.keypair.private-key-pem
  bastion-host         = module.bastion.bastion-ip
  newrelic-license-key = "${var.newrelic-api}"
  newrelic-acct-id     = "4566826"
  deployment           = "./modules/ansible/deployment.yml"
  prod-bashscript      = "./modules/ansible/prod-bashscript.sh"
  stage-bashscript     = "./modules/ansible/stage-bashscript.sh"
  nexus-ip             = module.nexus.nexus-ip
}

module "database" {
  source       = "./modules/database"
  rds-subgroup = "rds_subgroup" #can be given any name
  rds-subnet   = [module.vpc.prvsub-1-id, module.vpc.prvsub-2-id]
  db-name      = "petclinic"
  db-username  = data.vault_generic_secret.vault-secret.data["username"]
  db-password  = data.vault_generic_secret.vault-secret.data["password"]
  rds-sg       = [module.security-group.rds-sg]
}

module "prod-asg" {
  source        = "./modules/prod-asg"
  vpc-id        = module.vpc.vpc-id
  prod-sg       = module.security-group.docker-sg
  subnets       = [module.vpc.pubsub-1-id, module.vpc.pubsub-2-id] #under load balancer configuration
  name-alb-prod = "${local.name}-prod-asg"
  redhat        = "ami-07d4917b6f95f5c2a"
  # asg-sg = module.security-group.docker-sg
  pub-key               = module.keypair.public-key-id
  prod-asg-name         = "${local.name}-prod-asg"
  vpc-zone-identifier   = [module.vpc.prvsub-1-id, module.vpc.prvsub-2-id] #under asg configuration
  prod-asg-policy-name  = "prod-asg-policy"
  nexus-ip              = module.nexus.nexus-ip
  newrelic-user-licence = "${var.newrelic-api}"
  newrelic-acct-id      = 4566826
  newrelic-region       = "EU"
  cert-arn              = data.aws_acm_certificate.certificate.arn
}

module "stage-asg" {
  source   = "./modules/stage-asg"
  vpc-id   = module.vpc.vpc-id
  stage-sg = module.security-group.docker-sg
  #subnet variable is under load balancer configuration
  subnets               = [module.vpc.pubsub-1-id, module.vpc.pubsub-2-id]
  name-alb-stage        = "${local.name}-stage-asg"
  redhat                = "ami-07d4917b6f95f5c2a"
  pub-key               = module.keypair.public-key-id
  stage-asg-name        = "${local.name}-stage-asg"
  vpc-zone-identifier   = [module.vpc.prvsub-1-id, module.vpc.prvsub-2-id] #this variable is under asg configuration
  stage-asg-policy-name = "stage-asg-policy"
  nexus-ip              = module.nexus.nexus-ip
  newrelic-user-licence = "${var.newrelic-api}"
  newrelic-acct-id      = 4566826
  newrelic-region       = "EU"
  cert-arn              = data.aws_acm_certificate.certificate.arn
}

module "route53" {
  source                = "./modules/route53"
  domain_name           = "dobetabeta.shop"
  nexus_domain_name     = "nexus.dobetabeta.shop"
  nexus_lb_dns_name     = module.nexus.nexus-dns
  nexus_lb_zone_id      = module.nexus.nexus-zone-id
  sonarqube_domain_name = "sonarqube.dobetabeta.shop"
  sonarqube_lb_dns_name = module.sonar.sonarqube-dns
  sonarqube_lb_zone_id  = module.sonar.sonarqube-zone-id
  prod_domain_name      = "prod.dobetabeta.shop"
  prod_lb_dns_name      = module.prod-asg.prod-lb-dns
  prod_lb_zone_id       = module.prod-asg.prod-zone-id
  stage_domain_name     = "stage.dobetabeta.shop"
  stage_lb_dns_name     = module.stage-asg.stage-lb-dns
  stage_lb_zone_id      = module.stage-asg.stage-zone-id
}

data "aws_acm_certificate" "certificate" {
  domain      = "dobetabeta.shop"
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}