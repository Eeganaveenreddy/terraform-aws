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
  }

}

locals {
  # Define the script separately
  app_script = <<-EOF
#!/bin/bash
sudo apt update -y
sudo apt install nginx -y
sudo systemctl start nginx
sudo systemctl enable nginx

# Create a simple success file we can check later
echo "Terraform Userdata Setup Success" > /home/ubuntu/success.txt
EOF
}

locals {
  jenkins_script = <<-EOF
#!/bin/bash
# 1. Wait for apt lock (prevents race conditions with cloud-init)
while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do 
  echo "Waiting for apt lock..."
  sleep 5
done

# 2. Cleanup ANY previous attempts (Safe even on new instances)
sudo rm -f /etc/apt/sources.list.d/jenkins.list
sudo rm -f /usr/share/keyrings/jenkins-keyring.gpg
sudo rm -f /etc/apt/trusted.gpg.d/jenkins.gpg

# 3. Install Dependencies
sudo apt update -y
sudo apt install fontconfig openjdk-21-jre -y
java -version

# 4. Add Jenkins Key
sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key

# 5. Add the Repository
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

# 6. Install Jenkins
sudo apt update -y
sudo apt install jenkins -y

# --- Configure Jenkins Path Prefix ---
# This creates a systemd override to add the --prefix=/jenkins argument
sudo mkdir -p /etc/systemd/system/jenkins.service.d
# echo -e "[Service]\nEnvironment=\"JENKINS_OPTS=--prefix=/jenkins\"" | sudo tee /etc/systemd/system/jenkins.service.d/override.conf
cat <<EOT | sudo tee /etc/systemd/system/jenkins.service.d/override.conf
[Service]
Environment="JENKINS_OPTS=--prefix=/jenkins"
Environment="JENKINS_ARGS=--prefix=/jenkins"
EOT

# 7. Service Management (CRITICAL)
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable jenkins
sudo systemctl restart jenkins


# 8. Password Retrieval Loop
# Jenkins takes a moment to generate the file on the first run
echo "Waiting for Jenkins to generate admin password..."
for i in {1..15}; do
    if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
        sudo cat /var/lib/jenkins/secrets/initialAdminPassword | sudo tee /home/ubuntu/jenkins_admin_password.txt > /dev/null
        sudo chown ubuntu:ubuntu /home/ubuntu/jenkins_admin_password.txt
        echo "Jenkins Setup Success" > /home/ubuntu/success.txt
        break
    fi
    sleep 10
done
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




