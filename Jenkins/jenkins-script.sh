#!/bin/bash

#install git, wget, maven, java and jenkins
sudo yum update -y
sudo yum install git wget maven -y
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo yum upgrade -y
sudo yum install java-17-openjdk -y
sudo yum install jenkins -y
sudo systemctl daemon-reload
sudo systemctl enable jenkins
sudo systemctl start jenkins

#Install docker
#docker needed to build image on jenkins server
#curl http://checkip.amazonaws.com
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install docker-ce -y
sudo systemctl enable docker
sudo systemctl start docker

#Add ec2-user and jenkins to docker group
sudo usermod -aG docker ec2-user
sudo usermod -aG docker jenkins
sudo chmod 777 /var/run/docker.sock


# Install trivy for container scanning
RELEASE_VERSION=$(grep -Po '(?<=VERSION_ID=")[0-9]' /etc/os-release)
cat << EOT | sudo tee -a /etc/yum.repos.d/trivy.repo
[trivy]
name=Trivy repository
baseurl=https://aquasecurity.github.io/trivy-repo/rpm/releases/$RELEASE_VERSION/\$basearch/
gpgcheck=0
enabled=1
EOT
sudo yum -y update
sudo yum -y install trivy

#Install newrelic infra. agent and configure with license key
curl -Ls https://download.newrelic.com/install/newrelic-cli/scipts/install.sh | bash && sudo NEW_RELIC_API_KEY="${var.nr-key}" NEW_RELIC_ACCOUNT_ID="${var.nr-acc-id}" NEW_RELIC_REGION=EU /usr/local/bin/newrelic install -y

sudo hostnamectl set-hostname jenkins

#below tasks for jenkins UI &pipeline:
#Configure Jenkins to push to Nexus docker repo
#Install plugins like terraform, AWS Credentials, ssh-agent, slack and maven integration