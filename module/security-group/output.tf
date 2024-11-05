output "docker-sg" {
  value = aws_security_group.docker-sg.id
}

output "bastion-sg" {
  value = aws_security_group.bastion-sg.id
}

output "nexus-sg" {
  value = aws_security_group.nexus-sg.id
}

output "sonarqube-sg" {
  value = aws_security_group.sonarqube-sg.id
}

output "rds-sg" {
  value = aws_security_group.rds-sg.id
}

output "ansible-sg" {
  value = aws_security_group.ansible-sg.id
}