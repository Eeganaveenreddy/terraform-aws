# resource "aws_ebs_volume" "db_data" {
#   count = length(data.aws_ebs_volumes.existing_db.ids) > 0 ? 0 : 1

#   availability_zone = data.aws_subnet.private.availability_zone
#   size              = 250
#   type              = "gp3"

#   tags = {
#     Name        = "${var.env}-db-data"
#     Environment = var.env
#     Role        = "database"
#   }
#   lifecycle {
#     prevent_destroy = true
#   }
# }

# resource "aws_volume_attachment" "db_attach" {
#   count = var.server_name == "db-terraform" ? 1 : 0

#   device_name = "/dev/sdf"
#   volume_id   = local.db_volume_id
#   instance_id = aws_instance.db_instance.id

#   force_detach = true
#   depends_on = [
#     data.aws_ebs_volumes.existing_db,
#     aws_ebs_volume.db_data
#   ]
# }

# data "aws_ebs_volumes" "existing_db" {
#   filter {
#     name   = "tag:Name"
#     values = ["${var.env}-db-data"]
#   }
#   filter {
#     name   = "availability-zone"
#     values = [data.aws_subnet.private.availability_zone]
#   }
# }

# locals {
#   db_volume_id = try(
#     data.aws_ebs_volumes.existing_db.ids[0],
#     aws_ebs_volume.db_data[0].id
#   )
# }


