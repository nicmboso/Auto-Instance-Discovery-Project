#!/bin/bash
echo "${var.private-key}" >> /home/ec2-user/.ssh/id_rsa
chmod 400 /home/ec2-user/.ssh/id_rsa
sudo chown ec2-user:ec2-user /home/ec2-user/.ssh/id_rsa
# sudo yum install mysql-server -y
sudo hostnamectl set-hostname bastion