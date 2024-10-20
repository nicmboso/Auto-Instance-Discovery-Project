output "vpc-id" {
  value = aws_vpc.vpc.id
}

output "pubsub-1-id" {
  value = aws_subnet.pubsub-1.id
}

output "pubsub-2-id" {
  value = aws_subnet.pubsub-2.id
}

output "prvsub-1-id" {
  value = aws_subnet.prvsub-1.id
}

output "prvsub-2-id" {
  value = aws_subnet.prvsub-2.id
}