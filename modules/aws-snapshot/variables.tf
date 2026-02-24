variable "vault_name" {
  description = "Name of AWS Backup vault"
  type        = string
}

variable "backup_role_name" {
  description = "IAM role name for AWS Backup service"
  type        = string
}

variable "plan_name" {
  description = "Name of backup plan"
  type        = string
}

variable "rule_name" {
  description = "Name of backup rule"
  type        = string
  default     = "daily-ec2-snapshot"
}

variable "selection_name" {
  description = "Name of backup selection"
  type        = string
}

variable "schedule" {
  description = "Backup schedule in cron expression"
  type        = string
  default     = "cron(30 19 * * ? *)"
}

variable "delete_after_days" {
  description = "Retention period in days"
  type        = number
  default     = 2
}

variable "start_window_minutes" {
  description = "Start window in minutes"
  type        = number
  default     = 60
}

variable "completion_window_minutes" {
  description = "Completion window in minutes"
  type        = number
  default     = 120
}

variable "selection_tag_key" {
  description = "Tag key used for backup selection"
  type        = string
  default     = "Backup"
}

variable "selection_tag_value" {
  description = "Tag value used for backup selection"
  type        = string
  default     = "Daily"
}
