resource "aws_instance" "instances" {
  ami = var.ami_id
  instance_type = var.instance_type
  subnet_id = var.private_subnet_id
  vpc_security_group_ids = [aws_security_group.sg.id]

  iam_instance_profile = var.iam_instance_profile

  # user_data = var.server_name == "terraform-runner" ? file("${path.module}/install_terraform.sh") : (var.server_name == "jenkins-terraform" ? file("${path.module}/install_jenkins.sh") : null)
  user_data = (
  var.role == "terraform-runner"  ? file("${path.module}/install_terraform.sh") :
  var.role == "ci"      ? file("${path.module}/install_jenkins.sh") :
  null
  )

  user_data_replace_on_change = true

  tags = {
    Name = var.server_name
    Environment = var.env
    Region     = var.region
    Role        = var.role
  }

  lifecycle {
    create_before_destroy = true # Builds the new server before killing the old one
  }
  depends_on = [ var.private_subnet_id ]
}

data "aws_subnet" "private" {
  id = var.private_subnet_id
}


# # Generate the Private Key
# resource "tls_private_key" "key" {
#   algorithm = "RSA"
#   rsa_bits  = 4096
# }

# # Save the Private Key locally (the .pem file)
# resource "local_file" "private_key" {
#   content  = tls_private_key.key.private_key_pem
#   filename = "${path.module}/${var.server_name}-key.pem" # Unique file for each server
#   file_permission = "0600" # Important: SSH won't work if permissions are too open
# }

# # Upload the Public Key to AWS
# resource "aws_key_pair" "key_pair" {
#   key_name   = "${var.server_name}-key" # This makes it unique (e.g., Jenkins-Server-key)
#   public_key = tls_private_key.key.public_key_openssh
# }




