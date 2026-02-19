output "vpc_id" {
  value = module.vpc.vpc_id
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "alb_sg_id" {
  value = module.app_alb.alb_sg_id
}

output "target_group_arns" {
  value = module.app_alb.target_group_arns
}

output "iam_instance_profile_ec2instances" {
  value = module.iam.iam_instance_profile_ec2instances
}

output "iam_instance_profile_terraform_runner" {
  value = module.iam.iam_instance_profile_terraform_runner
}
