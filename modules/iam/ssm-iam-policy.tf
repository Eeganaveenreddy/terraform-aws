resource "aws_iam_role_policy_attachments_exclusive" "ec2_role_policies" {
  role_name = aws_iam_role.ec2_role.name

  policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMFullAccess",
    "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
  ]
}
