resource "aws_instance" "db_instance" {
  ami = var.ami_id
  instance_type = var.instance_type
  subnet_id = var.private_subnet_id
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  # key_name = var.key_name
  iam_instance_profile = var.iam_instance_profile

  user_data = file("${path.module}/mount_disk_on_dbserver.sh")
  user_data_replace_on_change = true

  tags = {
    Name        = var.server_name
    Environment = var.env
    Role        = var.role
    # Role        = coalesce(var.is_db, false) ? "database" : "null"
    Region     = var.region
  }

  lifecycle {
    create_before_destroy = true # Builds the new server before killing the old one
  }
  depends_on = [ var.private_subnet_id ]
}

data "aws_subnet" "private" {
  id = var.private_subnet_id
}
