output "sonar-ip" {
  value = aws_instance.sonarqube.public_ip
}

output "sonar-dns" {
  value = aws_elb.sonar-elb.dns_name
}

output "sonar-zone-id" {
  value = aws_elb.sonar-elb.zone_id
}