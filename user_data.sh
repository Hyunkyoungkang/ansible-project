#!/bin/bash

# Update package index
sudo apt update -y
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
sudo apt update -y

# Install required packages
sudo apt install -y docker.io openjdk-17-jdk git ruby wget unzip

# Install AWS CLI
cd /home/ubuntu
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Set JAVA_HOME
echo 'export JAVA_HOME="/usr/lib/jvm/java-1.17.0-openjdk-amd64"' >> /home/ubuntu/.bashrc
echo 'export PATH=$PATH:$JAVA_HOME/bin' >> /home/ubuntu/.bashrc
source /home/ubuntu/.bashrc

# Install CodeDeploy Agent
wget https://aws-codedeploy-ap-northeast-2.s3.amazonaws.com/latest/install
chmod u+x ./install
sudo ./install auto
sudo service codedeploy-agent status
rm -rf ./install

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.1.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Add ubuntu user to Docker group
sudo usermod -aG docker ubuntu

# Start Docker service
sudo systemctl enable docker
sudo systemctl start docker

# Run Jenkins container
sudo docker run -d \
  -p 80:8080 \
  --name jenkins \
  --privileged \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v jenkins_home:/var/jenkins_home \
  luvlee79/jenkins-docker_jenkins:latest

# ## swap 파일을 생성해준다.
sudo mkdir -p /var/spool/swap
sudo touch /var/spool/swap/swapfile
sudo dd if=/dev/zero of=/var/spool/swap/swapfile count=2048000 bs=1024

# ## swap 파일을 설정한다.
sudo chmod 600 /var/spool/swap/swapfile
sudo mkswap /var/spool/swap/swapfile
sudo swapon /var/spool/swap/swapfile

# ## swap 파일을 등록한다.
echo "/var/spool/swap/swapfile none swap defaults 0 0" | sudo tee -a /etc/fstab


# Wait for Jenkins to initialize
sleep 30

# Get the initial admin password
sudo docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword > /home/ubuntu/jenkins_admin_password_test.txt
