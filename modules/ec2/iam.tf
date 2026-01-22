# resource "aws_iam_role" "jenkins_role" {
#   name = "jenkins-controller-role"
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Action = "sts:AssumeRole"
#       Effect = "Allow"
#       Principal = { Service = "ec2.amazonaws.com" }
#     }]
#   })
# }

# # 2. Attach permissions (EC2, ECR, etc.)
# resource "aws_iam_role_policy_attachment" "jenkins_ec2_admin" {
#   role       = aws_iam_role.jenkins_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
# }

# # 3. Create the Instance Profile (The bridge to EC2)
# resource "aws_iam_instance_profile" "jenkins_profile" {
#   name = "jenkins-instance-profile"
#   role = aws_iam_role.jenkins_role.name
# }