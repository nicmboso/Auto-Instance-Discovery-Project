output "vault-server-ip" {
  value = aws_instance.vault-server.public_ip
}

output "vault-elb" {
  value = aws_elb.vault-elb.dns_name
}
