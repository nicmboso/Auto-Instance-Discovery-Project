provider "aws" {
  region = "eu-west-1"
  # profile = "personal"
  # profile = "team-20"
}

resource "aws_instance" "jenkins" {
  ami                         = "ami-07d4917b6f95f5c2a"
  instance_type               = "t3.medium"
  vpc_security_group_ids      = [aws_security_group.jenkins-sg.id]
  key_name                    = aws_key_pair.public-key.id
  iam_instance_profile        = aws_iam_instance_profile.jenkins_instance_profile.id
  associate_public_ip_address = true
  user_data                   = file("./jenkins-script.sh")

  tags = {
    Name = "jenkins-server"
  }
}

# dynamic keypair resource
resource "tls_private_key" "keypair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private-key" {
  content         = tls_private_key.keypair.private_key_pem
  filename        = "jenkins-key.pem"
  file_permission = 660
}

resource "aws_key_pair" "public-key" {
  key_name   = "jenkins-key-nicc"
  public_key = tls_private_key.keypair.public_key_openssh
}

resource "aws_security_group" "jenkins-sg" {
  name = "jenkins-sg-nicc"
  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "http"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "https"
    from_port   = 443
    to_port     = 443
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
    Name = "jenkins-sg"
  }
}


# # elb
# Create a new load balancer
resource "aws_elb" "jenkins-elb" {
  name               = "jenkins-elb-nicc"
  security_groups    = [aws_security_group.jenkins-sg.id]
  availability_zones = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]

  listener {
    instance_port      = 8080
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = aws_acm_certificate.ssl-cert.arn
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:8080"
    interval            = 30
  }

  instances                   = [aws_instance.jenkins.id]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "jenkins-elb"
  }
}

data "aws_route53_zone" "dobetashop" {
  name         = "dobetabeta.shop"
  private_zone = false
}

# # #IP address of jenkins is linked directly to IP
# resource "aws_route53_record" "jenkins_record" {
#   zone_id = data.aws_route53_zone.route53.zone_id
#   name    = "jenkins.dobetabeta.shop"
#   type    = "A"
#   ttl     = 300
#   records = [aws_instance.jenkins.public_ip]
# }

# load balancer of jenkins is linked directly to route53
resource "aws_route53_record" "jenkins_record" {
  zone_id = data.aws_route53_zone.dobetashop.zone_id
  name    = "jenkins2.dobetabeta.shop"
  type    = "A"
  alias {
    name                   = aws_elb.jenkins-elb.dns_name
    zone_id                = aws_elb.jenkins-elb.zone_id
    evaluate_target_health = true
  }
}

#creates the acm
resource "aws_acm_certificate" "ssl-cert" {
  domain_name               = "dobetabeta.shop"
  subject_alternative_names = ["*.dobetabeta.shop"]
  validation_method         = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

#validates the acm
#attaching route53 and the certificate- connecting route53 to the certificate
resource "aws_route53_record" "validation-record" {
  for_each = {
    for anybody in aws_acm_certificate.ssl-cert.domain_validation_options : anybody.domain_name => {
      name   = anybody.resource_record_name
      record = anybody.resource_record_value
      type   = anybody.resource_record_type
    }
  }
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.dobetashop.zone_id
}

#validates the record and acm is on aws account
resource "aws_acm_certificate_validation" "valid-acm-cert" {
  certificate_arn         = aws_acm_certificate.ssl-cert.arn
  validation_record_fqdns = [for record in aws_route53_record.validation-record : record.fqdn]
}

#to destroy only the jenkins server
#terraform init
# terraform destroy --target=aws_instance.jenkins -auto-approve