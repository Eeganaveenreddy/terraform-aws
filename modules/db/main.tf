resource "aws_instance" "db_instance" {
  ami = var.ami_id
  instance_type = var.instance_type
  subnet_id = var.private_subnet_id
  vpc_security_group_ids = var.sg_id

  key_name = var.key_name

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
