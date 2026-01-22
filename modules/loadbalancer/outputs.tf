# output "target_group_arn" {
#   value = aws_lb_target_group.tg.arn
# }

output "target_group_arns" {
  # This creates a map: { "jenkins-terraform" = "arn:...", "app-terraform" = "arn:..." }
  value = { for k, tg in aws_lb_target_group.tg : k => tg.arn }
}

output "alb_sg_id" {
  value = aws_security_group.alb_sg.id
}