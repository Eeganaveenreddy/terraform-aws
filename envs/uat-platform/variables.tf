variable "aws_region" {
  description = "Region where resources will be deployed"
  type        = string
  default     = "ap-south-1"
}

variable "env" {
  type = string
}

variable "vpc_cidr" {
  description = "Main CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "server_config" {
  description = "Platform server map and ALB target group map"
  type = map(object({
    ami_id           = string
    instance_type    = string
    ingress_ports    = list(number)
    server_name      = string
    alb_enabled      = bool
    is_db            = optional(bool)
    role             = optional(string)
    root_volume_size = optional(number)
  }))
}

variable "alb_name" {}
variable "acm_certificate_arn" {
  description = "ACM certificate ARN for ALB HTTPS listener"
  type        = string
}
variable "additional_acm_certificate_arns" {
  description = "Additional ACM certificate ARNs for ALB HTTPS listener (SNI)"
  type        = list(string)
  default     = []
}

variable "backup_vault_name" {
  description = "AWS Backup vault name for UAT backups"
  type        = string
  default     = "ec2-daily-backup-vault-uat"
}

variable "backup_role_name" {
  description = "IAM role name used by AWS Backup service"
  type        = string
  default     = "aws-backup-service-role-uat"
}

variable "backup_plan_name" {
  description = "AWS Backup plan name"
  type        = string
  default     = "daily-ec2-backup-plan-uat"
}

variable "backup_selection_name" {
  description = "AWS Backup selection name"
  type        = string
  default     = "ec2-daily-backup-selection-uat"
}

variable "backup_schedule" {
  description = "Backup schedule in cron format"
  type        = string
  default     = "cron(30 19 * * ? *)"
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 2
}

variable "backup_selection_tag_key" {
  description = "Tag key used by backup selection"
  type        = string
  default     = "Backup"
}

variable "backup_selection_tag_value" {
  description = "Tag value used by backup selection"
  type        = string
  default     = "Daily"
}
