module "vpc" {
  source   = "../../modules/vpc"
  vpc_cidr = var.vpc_cidr
}

module "iam" {
  source = "../../modules/iam"
}

module "ec2" {
  source = "../../modules/ec2"

  # Platform instances only: Jenkins + terraform-runner
  for_each = {
    for k, v in var.server_config :
    k => v
    if !coalesce(v.is_db, false) && contains(["ci", "terraform-runner"], coalesce(v.role, "compute"))
  }

  server_name   = each.key
  ami_id        = each.value.ami_id
  instance_type = each.value.instance_type
  ingress_ports = each.value.ingress_ports

  env    = var.env
  region = var.aws_region

  is_db = coalesce(each.value.is_db, false)
  role  = coalesce(each.value.role, "compute")

  iam_instance_profile = coalesce(each.value.role, "compute") == "terraform-runner" ? module.iam.iam_instance_profile_terraform_runner : module.iam.iam_instance_profile_ec2instances

  vpc_id            = module.vpc.vpc_id
  private_subnet_id = module.vpc.private_subnet_ids[0]
  alb_sg_id         = module.app_alb.alb_sg_id

  root_volume_size = try(each.value.root_volume_size, null)
}

module "app_alb" {
  source              = "../../modules/loadbalancer"
  alb_name            = var.alb_name
  acm_certificate_arn = var.acm_certificate_arn
  server_config       = var.server_config

  vpc_id           = module.vpc.vpc_id
  public_subnet_id = module.vpc.public_subnet_ids
}

resource "aws_lb_target_group_attachment" "jenkins_attachment" {
  for_each = {
    for key, value in var.server_config : key => value
    if value.alb_enabled == true && key == "jenkins-terraform"
  }

  target_group_arn = module.app_alb.target_group_arns[each.key]
  target_id        = module.ec2[each.key].instance_id
  port             = 8080
}
