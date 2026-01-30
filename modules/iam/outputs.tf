output "iam_instance_profile_ec2instances" {
  value = aws_iam_instance_profile.instances.name
}

output "iam_instance_profile_terraform_runner" {
  value = aws_iam_instance_profile.terraform_runner.name
}