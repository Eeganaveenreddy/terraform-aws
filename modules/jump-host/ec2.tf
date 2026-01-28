# Security Group for the Jump Host
resource "aws_security_group" "jump_sg" {
  name        = "jump-sg"
  description = "Allow SSH from specific IP"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    # IMPORTANT: Change this to your actual IP (e.g., "1.2.3.4/32") 
    # for real-time practice. Never use 0.0.0.0/0 for SSH in prod.
    cidr_blocks = ["0.0.0.0/0"] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# The Jump Host Instance
resource "aws_instance" "jump_host" {
  ami                         = "ami-087d1c9a513324697"
  instance_type               = "t2.micro" # Keep it cheap
  subnet_id = var.public_subnet_id[0]
  vpc_security_group_ids      = [aws_security_group.jump_sg.id]
  key_name                    = aws_key_pair.key_pair.key_name
  associate_public_ip_address = true # Must be public

  tags = {
    Name = "terra-jump-host"
  }
}

# Generate the Private Key
resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save the Private Key locally (the .pem file)
resource "local_file" "private_key" {
  content  = tls_private_key.key.private_key_pem
  filename = "${path.module}/jump-key.pem" # Unique file for each server
  file_permission = "0600" # Important: SSH won't work if permissions are too open
}

# Upload the Public Key to AWS
resource "aws_key_pair" "key_pair" {
  key_name   = "jumpserver-key" # This makes it unique (e.g., Jenkins-Server-key)
  public_key = tls_private_key.key.public_key_openssh
}

