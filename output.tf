output "ansible" {
  value = module.ansible.ansible-ip
}

output "nexus" {
  value = module.nexus.nexus-ip
}

output "sonarqube" {
  value = module.sonar.sonar-ip
}

output "rds-endpoint" {
  value = module.database.db-endpoint
}

output "bastion-ip" {
  value = module.bastion.bastion-ip
}