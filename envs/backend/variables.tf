variable "aws_region" {
  description = "AWS region for backend resources"
  type        = string
  default     = "ap-south-1"
}

variable "lock_table_name" {
  description = "DynamoDB table name for Terraform state locking"
  type        = string
  default     = "terraform-state-locks"
}
