output "nexus-ip" {
  value = aws_instance.nexus.public_ip
}

output "nexus-dns" {
  value = aws_elb.nexus-elb.dns_name
}

output "nexus-zone-id" {
  value = aws_elb.nexus-elb.zone_id
}