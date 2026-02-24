data "terraform_remote_state" "platform" {
  backend = "s3"

  config = {
    bucket       = var.platform_state_bucket
    key          = var.platform_state_key
    region       = var.aws_region
    use_lockfile = true
    encrypt      = true
  }
}

module "ec2" {
  source = "../../modules/ec2"

  # Workload compute instances (exclude runner/jenkins and db).
  for_each = {
    for k, v in var.server_config :
    k => v
    if !coalesce(v.is_db, false) && !contains(["ci", "terraform-runner"], coalesce(v.role, "compute"))
  }

  server_name   = each.key
  ami_id        = each.value.ami_id
  instance_type = each.value.instance_type
  ingress_ports = each.value.ingress_ports

  env    = var.env
  region = var.aws_region

  is_db = coalesce(each.value.is_db, false)
  role  = coalesce(each.value.role, "compute")

  iam_instance_profile = data.terraform_remote_state.platform.outputs.iam_instance_profile_ec2instances

  vpc_id            = data.terraform_remote_state.platform.outputs.vpc_id
  private_subnet_id = data.terraform_remote_state.platform.outputs.private_subnet_ids[0]
  alb_sg_id         = data.terraform_remote_state.platform.outputs.alb_sg_id

  root_volume_size = try(each.value.root_volume_size, null)
  resource_tags    = { Backup = "Daily" }
}

module "db" {
  source = "../../modules/db"

  for_each = {
    for k, v in var.server_config :
    k => v
    if coalesce(v.is_db, false)
  }

  server_name   = each.key
  ami_id        = each.value.ami_id
  instance_type = each.value.instance_type
  ingress_ports = each.value.ingress_ports

  env    = var.env
  region = var.aws_region

  is_db = coalesce(each.value.is_db, false)
  role  = coalesce(each.value.role, "database")

  iam_instance_profile = data.terraform_remote_state.platform.outputs.iam_instance_profile_ec2instances

  vpc_id            = data.terraform_remote_state.platform.outputs.vpc_id
  private_subnet_id = data.terraform_remote_state.platform.outputs.private_subnet_ids[0]
  resource_tags     = { Backup = "Daily" }
}

resource "aws_lb_target_group_attachment" "app_attachment" {
  for_each = {
    for key, value in var.server_config : key => value
    if value.alb_enabled == true && key == "app-terraform"
  }

  target_group_arn = data.terraform_remote_state.platform.outputs.target_group_arns[each.key]
  target_id        = module.ec2[each.key].instance_id
  port             = 8069
}
