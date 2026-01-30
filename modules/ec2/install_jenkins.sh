#!/bin/bash
set -euxo pipefail

LOG=/var/log/jenkins-userdata.log
exec > >(tee -a $LOG) 2>&1

export DEBIAN_FRONTEND=noninteractive

# echo "=== Waiting for cloud-init and apt locks ==="
# while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || \
#       sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1 || \
#       # pgrep -x cloud-init >/dev/null 2>&1; do
#   echo "Waiting for apt/cloud-init..."
#   sleep 5
# done

echo "=== Waiting for apt locks (max 3 minutes) ==="
MAX_WAIT=180
WAITED=0

while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || \
      sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do

  if [ "$WAITED" -ge "$MAX_WAIT" ]; then
    echo "Timeout reached, continuing anyway..."
    break
  fi

  echo "Waiting for apt locks..."
  sleep 5
  WAITED=$((WAITED+5))
done

echo "=== Cleanup old Jenkins configs (safe on fresh VM) ==="
sudo rm -f /etc/apt/sources.list.d/jenkins.list
sudo rm -f /usr/share/keyrings/jenkins-keyring.gpg
sudo rm -f /etc/apt/trusted.gpg.d/jenkins.gpg

echo "=== Installing Java 17 ==="
sudo apt-get update -y
sudo apt-get install -y fontconfig openjdk-17-jre-headless

echo "=== Verify Java ==="
java -version

JAVA_PATH=$(readlink -f $(which java))
JAVA_HOME=$(dirname $(dirname $JAVA_PATH))
echo "JAVA_HOME=$JAVA_HOME"

echo "=== Add Jenkins Repo & Key ==="
sudo mkdir -p /etc/apt/keyrings
sudo wget -q -O /etc/apt/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key

echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | \
  sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

echo "=== Install Jenkins ==="
sudo apt-get update -y
sudo apt-get install -y jenkins

echo "=== Configure Jenkins systemd override ==="
sudo mkdir -p /etc/systemd/system/jenkins.service.d

cat <<EOT | sudo tee /etc/systemd/system/jenkins.service.d/override.conf
[Service]
Environment="JAVA_HOME=$JAVA_HOME"
Environment="PATH=$JAVA_HOME/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
Environment="JENKINS_OPTS=--prefix=/jenkins"
Environment="JENKINS_ARGS=--prefix=/jenkins"
EOT

echo "=== Enable & Restart Jenkins ==="
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable jenkins
sudo systemctl restart jenkins

# # -----------------------------
# # Fix Jenkins Offline Mode
# # -----------------------------
# echo "=== Fixing Jenkins Update Center Offline Mode ==="

# # Wait for update center file to exist
# for i in {1..30}; do
#   if [ -f /var/lib/jenkins/hudson.model.UpdateCenter.xml ]; then
#     sed -i 's/<offline>true/<offline>false/' /var/lib/jenkins/hudson.model.UpdateCenter.xml
#     systemctl restart jenkins
#     echo "Jenkins offline mode disabled"
#     break
#   fi
#   echo "Waiting for Jenkins update center file..."
#   sleep 10
# done

# -----------------------------
# Get Admin Password
# -----------------------------
echo "=== Waiting for Jenkins Admin Password ==="
for i in {1..20}; do
  if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
    sudo cat /var/lib/jenkins/secrets/initialAdminPassword | sudo tee /home/ubuntu/jenkins_admin_password.txt > /dev/null
    sudo chown ubuntu:ubuntu /home/ubuntu/jenkins_admin_password.txt
    echo "Jenkins Setup Success" > /home/ubuntu/success.txt
    break
  fi
  sleep 10
done

echo "=== Jenkins User-Data Completed ==="