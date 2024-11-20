output "ansible" {
  value = module.ansible.ansible-ip
}

output "nexus" {
  value = module.nexus.nexus-ip
}

output "sonarqube" {
  value = module.sonarqube.sonar-ip
}

output "rds-endpoint" {
  value = module.rds.rds-endpoint
}

output "bastion-ip" {
  value = module.bastion-host.bastion-ip
}