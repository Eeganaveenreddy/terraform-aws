resource "aws_ebs_volume" "db_data" {
  count = var.server_name == "db-terraform" ? 1 : 0

  availability_zone = data.aws_subnet.private.availability_zone
  size              = 250
  type              = "gp3"

  tags = {
    Name        = "${var.env}-db-data"
    Environment = var.env
    Role        = "database"
  }
}

resource "aws_volume_attachment" "db_attach" {
  count = var.server_name == "db-terraform" ? 1 : 0

  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.db_data[0].id
  instance_id = aws_instance.instances.id

  force_detach = true
}
