# create db subnet group
resource "aws_db_subnet_group" "rds-subnet" {
  name       = var.rds-subgroup
  subnet_ids = var.rds-subnet
  tags = {
    Name = "rds-subnet-grp"
  }
}

# aws db
resource "aws_db_instance" "petclinic" {
  identifier             = "petclinic"
  engine                 = "mysql"
  engine_version         = "5.7"
  db_name                = var.db-name
  username               = var.db-username
  password               = var.db-password
  db_subnet_group_name   = aws_db_subnet_group.rds-subnet.name
  vpc_security_group_ids = var.rds-sg
  allocated_storage      = 10
  instance_class         = "db.t3.micro"
  parameter_group_name   = "default.mysql5.7"
  storage_type           = "gp2"
  skip_final_snapshot    = true
  publicly_accessible    = false
}