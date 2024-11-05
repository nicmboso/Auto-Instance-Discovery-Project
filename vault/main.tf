provider "aws" {
  region  = "eu-west-1"
  profile = "team2"
}

# dynamic keypair resource
resource "tls_private_key" "keypair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  content         = tls_private_key.keypair.private_key_pem
  filename        = "vault-private-key"
  file_permission = "600"
}

resource "aws_key_pair" "public_key" {
  key_name   = "vault-public-key"
  public_key = tls_private_key.keypair.public_key_openssh
}

# Vault SG
resource "aws_security_group" "vault-sg" {
  name        = "vault-sg"
  description = "Vault Security Group"


  # Inbound Rules
  ingress {
    description = "ssh access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "vault port"
    from_port   = 8200
    to_port     = 8200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "https port"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "http port"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Vault-sg"
  }
}

#create kms key
resource "aws_kms_key" "vault-key" {
  description             = "This is the key to our vault server"
  deletion_window_in_days = 10
  tags = {
    Name = "vault-kms-key"
  }
}

resource "aws_instance" "vault-server" {
  ami                    = var.ubuntu
  instance_type          = "t2.medium"
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.id
  key_name               = aws_key_pair.public_key.id
  vpc_security_group_ids = [aws_security_group.vault-sg.id]
  user_data = templatefile("./vault-script.sh", {
    var1 = "eu-west-1"
    var2 = aws_kms_key.vault-key.id
  })
  tags = {
    Name = "vault-server"
  }
}

#elb
# Create a new load balancer
resource "aws_elb" "vault-elb" {
  name               = "vault-elb"
  security_groups    = [aws_security_group.vault-sg.id]
  availability_zones = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]

  listener {
    instance_port     = 8200
    instance_protocol = "http"
    lb_port           = 443
    lb_protocol       = "https"
    #associating the certificate to the load balancer
    ssl_certificate_id = data.aws_acm_certificate.certificate.arn
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:8200"
    interval            = 30
  }

  instances                   = [aws_instance.vault-server.id]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "vault-elb"
  }
}

data "aws_route53_zone" "route53" {
  name         = "dobetabeta.shop"
  private_zone = false
}

resource "aws_route53_record" "vault_record" {
  zone_id = data.aws_route53_zone.route53.zone_id
  name    = "vault.dobetabeta.shop"
  type    = "A"
  alias {
    name                   = aws_elb.vault-elb.dns_name
    zone_id                = aws_elb.vault-elb.zone_id
    evaluate_target_health = true
  }
}

data "aws_acm_certificate" "certificate" {
  domain      = "dobetabeta.shop"
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}