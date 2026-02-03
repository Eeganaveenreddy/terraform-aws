module "vpc" {
  source   = "../../modules/vpc"
  vpc_cidr = var.vpc_cidr
}

module "iam" {
  source = "../../modules/iam"
}

module "ec2" {
  source = "../../modules/ec2"
  # for_each      = var.server_config
  for_each = {
    for k, v in var.server_config :
    k => v
    if !coalesce(v.is_db, false)
  }

  server_name   = each.key
  ami_id        = each.value.ami_id
  instance_type = each.value.instance_type
  ingress_ports = each.value.ingress_ports

  env    = var.env
  region = var.aws_region

  is_db = coalesce(each.value.is_db, false)
  role = coalesce(each.value.role, "compute")

  # IAM instance profile logic
  # terraform-runner → terraform IAM role
  # all others       → common EC2 IAM role
  iam_instance_profile = coalesce(each.value.role, "compute") == "terraform-runner" ? module.iam.iam_instance_profile_terraform_runner : module.iam.iam_instance_profile_ec2instances

  vpc_id            = module.vpc.vpc_id
  private_subnet_id = module.vpc.private_subnet_ids[0]

  alb_sg_id = module.app_alb.alb_sg_id
}

module "db" {
  source = "../../modules/db"
  # for_each = var.server_config
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

  # 👇 PASS FROM SERVER CONFIG
  is_db = coalesce(each.value.is_db, false)
  role = coalesce(each.value.role, "database")

  iam_instance_profile = each.key == "db-terraform" ? module.iam.iam_instance_profile_ec2instances : null

  vpc_id            = module.vpc.vpc_id
  private_subnet_id = module.vpc.private_subnet_ids[0]
}

module "app_alb" {
  source        = "../../modules/loadbalancer"
  alb_name      = var.alb_name
  server_config = var.server_config

  # sg_id            = [for instance in module.ec2 : instance.sg_id]
  # sg_id = [
  #   for key, value in module.ec2 : value.sg_id
  #   if key == "app-terraform"
  # ]

  vpc_id           = module.vpc.vpc_id
  public_subnet_id = module.vpc.public_subnet_ids
}

resource "aws_lb_target_group_attachment" "app_attachment" {

  # Filter the map to ONLY include the "app-terraform" key
  for_each = {
    for key, value in var.server_config : key => value
    if value.alb_enabled == true
  }

  target_group_arn = module.app_alb.target_group_arns[each.key]
  target_id        = module.ec2[each.key].instance_id
  port             = each.key == "jenkins-terraform" ? 8080 : 8069
}
