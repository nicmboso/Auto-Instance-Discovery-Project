#Create nexus server
resource "aws_instance" "nexus" {
  ami                         = var.redhat
  instance_type               = "t2.medium"
  associate_public_ip_address = true
  subnet_id                   = var.nexus-subnet
  key_name                    = var.public-key
  vpc_security_group_ids      = [var.nexus-sg]
  user_data = base64encode(templatefile("./module/nexus/nexus-script.sh", {
    newrelic-license-key = var.newrelic-user-licence,
    newrelic-account-id  = var.newrelic-acct-id,
    newrelic-region      = var.newrelic-reg

  }))
  # user_data                   = file("./module/nexus/nexus-script.sh")
  tags = {
    Name = "nexus-server"
  }
}

#elb
# Create a new load balancer
resource "aws_elb" "nexus-elb" {
  name            = "nexus-elb"
  security_groups = [var.nexus-sg]
  # availability_zones = ["eu-west-1a", "eu-west-1b"]
  subnets = var.pub-subnets

  listener {
    instance_port      = 8081
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = var.cert-arn
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:8081"
    interval            = 30
  }

  instances                   = [aws_instance.nexus.id]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "nexus-elb"
  }
}
