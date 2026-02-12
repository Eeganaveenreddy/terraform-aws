variable "aws_region" {
  description = "Region where resources will be deployed"
  type        = string
  default     = "ap-south-1"
}

variable "env" {
  type = string
}

variable "platform_state_bucket" {
  description = "S3 bucket containing dev-platform Terraform state"
  type        = string
}

variable "platform_state_key" {
  description = "S3 key for dev-platform Terraform state"
  type        = string
  default     = "terraform-aws/envs/dev-platform/terraform.tfstate"
}

variable "state_lock_table" {
  description = "DynamoDB lock table used by Terraform backend"
  type        = string
  default     = "terraform-state-locks"
}

variable "server_config" {
  description = "Workload server map (app/db)"
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
