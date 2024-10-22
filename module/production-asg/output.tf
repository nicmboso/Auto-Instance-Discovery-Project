output "prod-asg-id" {
  value = aws_autoscaling_group.prod-asg.id
}

output "prod-asg-name" {
  value = aws_autoscaling_group.prod-asg.name
}

output "Prod-lt-id" {
  value = aws_launch_template.prod_lt.id #check
}

output "prod-lb-dns" {
  value = aws_lb.alb-prod.dns_name
}

output "prod-zone-id" {
  value = aws_lb.alb-prod.zone_id
}