resource "aws_instance" "instances" {
  ami = var.ami_id
  instance_type = var.instance_type
  subnet_id = var.private_subnet_id
  vpc_security_group_ids = [aws_security_group.sg.id]
#   iam_instance_profile = aws_iam_instance_profile.jenkins_profile.name

  # Connect the Jenkins script here
#   user_data = file("${path.module}/install_jenkins.sh")

  key_name = aws_key_pair.jenkins_key_pair.key_name

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

  jenkins_script = <<EOF
#!/bin/bash
# Wait for apt lock
while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do sleep 5; done

# 1. Install Java (Jenkins requirement)
sudo apt update -y
sudo apt install fontconfig openjdk-17-jre -y

# 2. Install Jenkins
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/" | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt update -y
sudo apt install jenkins -y
sudo systemctl start jenkins
sudo systemctl enable jenkins

# 3. Install Git
sudo apt install git -y

# Save the Initial Admin Password to a file for easy access
sudo cat /var/lib/jenkins/secrets/initialAdminPassword > /home/ubuntu/jenkins_admin_password.txt
chown ubuntu:ubuntu /home/ubuntu/jenkins_admin_password.txt
echo "Terraform Userdata Setup Success in jenkins machine" > /home/ubuntu/success.txt

EOF
}

# Generate the Private Key
resource "tls_private_key" "jenkins_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save the Private Key locally (the .pem file)
resource "local_file" "private_key" {
  content  = tls_private_key.jenkins_key.private_key_pem
  filename = "${path.module}/${var.server_name}-key.pem" # Unique file for each server
  file_permission = "0600" # Important: SSH won't work if permissions are too open
}

# Upload the Public Key to AWS
resource "aws_key_pair" "jenkins_key_pair" {
  key_name   = "${var.server_name}-key" # This makes it unique (e.g., Jenkins-Server-key)
  public_key = tls_private_key.jenkins_key.public_key_openssh
}




