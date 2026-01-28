#!/bin/bash
# 1. Update system packages
sudo apt-get update -y

# 2. Install Java 17 (The engine Jenkins runs on)
sudo apt-get install openjdk-17-jdk -y

# 3. Add Jenkins GPG Key
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key

# 4. Add Jenkins Repository to sources list
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/" | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

# 5. Install Jenkins
sudo apt-get update -y
sudo apt-get install jenkins -y

# 6. Start Jenkins service
sudo systemctl enable jenkins
sudo systemctl start jenkins