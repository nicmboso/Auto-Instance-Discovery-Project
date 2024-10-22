#create target group for stage asg
# Creating load balancer Target Group for stage asg
resource "aws_lb_target_group" "lb-tg-stage" {
  name     = "lb-tg-stage"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = var.vpc-id

  health_check {
    interval            = 30
    timeout             = 10
    healthy_threshold   = 3
    unhealthy_threshold = 5
  }
}

# Creating Application Load Balancer for stage asg
resource "aws_lb" "alb-stage" {
  name                       = "asg-stage-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [var.stage-sg]
  subnets                    = var.priv-subnets
  enable_deletion_protection = false

  tags = {
    Name = var.alb-stage-name
  }
}

#Creating Load Balancer Listener for https
resource "aws_lb_listener" "lb_lsnr-https" {
  load_balancer_arn = aws_lb.alb-stage.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.cert-arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb-tg-stage.arn
  }
}

# Creating Load Balancer Listener for http
resource "aws_lb_listener" "lb_lsnr-http" {
  load_balancer_arn = aws_lb.alb-stage.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb-tg-stage.arn
  }
}

#######creating asg resources
# Create Launch Template
resource "aws_launch_template" "stage_lt" {
  image_id               = var.redhat
  instance_type          = "t2.medium"
  vpc_security_group_ids = [var.stage-sg]
  key_name               = var.pub-key
  user_data = base64encode(templatefile("./modules/stage-asg/docker-script.sh", {
    nexus-ip             = var.nex-ip,
    newrelic-license-key = var.newrelic-user-licence,
    newrelic-account-id  = var.newrelic-acct-id,
    newrelic-region      = var.newrelic-reg
  }))
}

#Create AutoScaling Group
resource "aws_autoscaling_group" "stage-asg" {
  name                      = var.stage-asg-name
  desired_capacity          = 1
  max_size                  = 5
  min_size                  = 1
  health_check_grace_period = 120
  health_check_type         = "EC2"
  force_delete              = true
  vpc_zone_identifier       = var.vpc-zone-identifier
  target_group_arns         = [aws_lb_target_group.lb-tg-stage.arn]
  launch_template {
    id = aws_launch_template.stage_lt.id
  }
  tag {
    key                 = "Name"
    value               = var.stage-asg-name
    propagate_at_launch = true
  }
}

#Create ASG Policy
resource "aws_autoscaling_policy" "stage-asg-policy" {
  name                   = var.stage-asg-policy-name
  adjustment_type        = "ChangeInCapacity"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.stage-asg.id
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50.0
  }
}