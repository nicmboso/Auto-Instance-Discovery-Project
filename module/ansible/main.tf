resource "aws_instance" "ansible" {
  ami                    = var.redhat
  instance_type          = "t2.micro"
  subnet_id              = var.ansible-subnet
  key_name               = var.pub-key
  vpc_security_group_ids = var.ansible-sg
  user_data              = local.ansible_userdata
  tags = {
    Name = "ansible-server"
  }
}

resource "aws_iam_user" "ansible" {
  name = "ansible-user-2"
  tags = {
    tag-key = "ansible"
  }
}

resource "aws_iam_access_key" "ansible" {
  user = aws_iam_user.ansible.name
}

resource "aws_iam_group" "ansible" {
  name = "ansible-group-2"
}

resource "aws_iam_user_group_membership" "ansible" {
  user   = aws_iam_user.ansible.name
  groups = [aws_iam_group.ansible.name]
}

resource "aws_iam_group_policy_attachment" "ansible-attach" {
  group      = aws_iam_group.ansible.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}
# resource "null_resource" "copy-playbook-dir" {
#   connection {
#     type = "ssh"
#     host = aws_instance.ansible.private_ip
#     user = "ec2-user"
#     private_key = var.private-key
#     bastion_host = var.bastion-host
#     bastion_private_key = var.private-key
#     bastion_user = "ec2-user"
#   }
#   provisioner "file" {
#     source = "${path.root}/modules/ansible/playbooks"
#     destination = "/home/ec2-user/playbooks"
#   }
# }