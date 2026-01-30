resource "aws_iam_instance_profile" "terraform_runner" {
  name = "Terraform-Runner-Profile"
  role = aws_iam_role.terraform_runner.name
}

resource "aws_iam_instance_profile" "instances" {
  name = "instance-Profile"
  role = aws_iam_role.ec2_role.name
}
