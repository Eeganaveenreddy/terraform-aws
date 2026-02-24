resource "aws_backup_vault" "ec2_vault" {
  name = var.vault_name
}

resource "aws_iam_role" "backup_role" {
  name = var.backup_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "backup.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "backup_policy" {
  role       = aws_iam_role.backup_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_backup_plan" "daily_plan" {
  name = var.plan_name

  rule {
    rule_name         = var.rule_name
    target_vault_name = aws_backup_vault.ec2_vault.name
    schedule          = var.schedule
    lifecycle {
      delete_after = var.delete_after_days
    }

    start_window      = var.start_window_minutes
    completion_window = var.completion_window_minutes
  }
}

resource "aws_backup_selection" "ec2_selection" {
  name         = var.selection_name
  plan_id      = aws_backup_plan.daily_plan.id
  iam_role_arn = aws_iam_role.backup_role.arn

  selection_tag {
    type  = "STRINGEQUALS"
    key   = var.selection_tag_key
    value = var.selection_tag_value
  }
}
