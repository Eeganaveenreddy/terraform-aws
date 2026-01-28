resource "aws_instance" "instances" {
  ami = var.ami_id
  instance_type = var.instance_type
  subnet_id = var.private_subnet_id
  vpc_security_group_ids = [aws_security_group.sg.id]
#   iam_instance_profile = aws_iam_instance_profile.jenkins_profile.name

  # Connect the Jenkins script here
#   user_data = file("${path.module}/install_jenkins.sh")

  key_name = aws_key_pair.key_pair.key_name

#   iam_instance_profile = aws_iam_instance_profile.ssm_profile.name # To enable AWS Systems Manager(SSM) Session Manager (the "keyless" connection method)

# Use a simple conditional on the pre-defined local
  user_data = var.server_name == "app-terraform" ? local.app_script : (var.server_name == "jenkins-terraform" ? local.jenkins_script : null)
  user_data_replace_on_change = true

  tags = {
    Name = var.server_name
  }

  lifecycle {
    create_before_destroy = true # Builds the new server before killing the old one
    replace_triggered_by = [
    aws_key_pair.key_pair.id
  ]
  }
  depends_on = [ var.private_subnet_id ]
}

locals {
  # Define the script separately
  app_script = null
#   app_script = <<-EOF
# #!/bin/bash
# sudo apt update -y
# sudo apt install nginx -y
# sudo systemctl start nginx
# sudo systemctl enable nginx

# # Create a simple success file we can check later
# echo "Terraform Userdata Setup Success" > /home/ubuntu/success.txt
# EOF
}

locals {
  jenkins_script = <<-EOF
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
EOF
}


# Generate the Private Key
resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save the Private Key locally (the .pem file)
resource "local_file" "private_key" {
  content  = tls_private_key.key.private_key_pem
  filename = "${path.module}/${var.server_name}-key.pem" # Unique file for each server
  file_permission = "0600" # Important: SSH won't work if permissions are too open
}

# Upload the Public Key to AWS
resource "aws_key_pair" "key_pair" {
  key_name   = "${var.server_name}-key" # This makes it unique (e.g., Jenkins-Server-key)
  public_key = tls_private_key.key.public_key_openssh
}




