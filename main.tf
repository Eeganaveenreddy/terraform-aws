module "vpc" {
  source   = "./modules/vpc"
  vpc_cidr = var.vpc_cidr
}

module "ec2" {
  source        = "./modules/ec2"
  # for_each      = var.server_config
  for_each = {
    for k, v in var.server_config :
    k => v
    if !try(v.is_db, false)
  }

  server_name   = each.key
  ami_id        = each.value.ami_id
  instance_type = each.value.instance_type
  ingress_ports = each.value.ingress_ports

  vpc_id            = module.vpc.vpc_id
  private_subnet_id = module.vpc.private_subnet_ids[0]
  #   iam_instance_profile_name = var.iam_instance_profile_name

  alb_sg_id = module.app_alb.alb_sg_id
}

module "db" {
  source = "./modules/db"
  # for_each = var.server_config
  for_each = {
  for k, v in var.server_config :
  k => v
  if try(v.is_db, false)
}

  server_name = each.key
  ami_id = each.value.ami_id
  instance_type = each.value.instance_type
  ingress_ports = each.value.ingress_ports

  vpc_id            = module.vpc.vpc_id
  private_subnet_id = module.vpc.private_subnet_ids[0]

  sg_id = module.ec2.sg_id

  key_name = module.ec2.key_name

}

module "app_alb" {
  source        = "./modules/loadbalancer"
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

module "jump-server" {
  source           = "./modules/jump-host"
  vpc_id           = module.vpc.vpc_id
  public_subnet_id = module.vpc.public_subnet_ids
}