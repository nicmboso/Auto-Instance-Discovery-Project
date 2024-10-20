# create baston_host
resource "aws_instance" "bastion-host" {
  ami                         = var.redhat
  instance_type               = "t2.micro"
  subnet_id                   = var.bastion-subnet
  associate_public_ip_address = true
  vpc_security_group_ids      = [var.bastion-sg]
  key_name                    = var.public-key
  user_data                   = templatefile("./module/bastion-host/bastion-userdata.sh", {
    private_key_file = var.private-key
  })
  tags = {
    Name = "bastion-server"
  }
}