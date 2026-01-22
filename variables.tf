variable "aws_region" {
  description = "Region where resources will be deployed"
  type        = string
  default     = "ap-south-1"
}

variable "vpc_cidr" {
  description = "Main CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "server_config" {
  description = "A map of server configurations for the EC2 module"
  type = map(object({
    ami_id        = string
    instance_type = string
    ingress_ports = list(number)
    server_name   = string
    alb_enabled   = bool
  }))
  # No default needed here if you provide it in .tfvars
}

variable "alb_name" {
  type = string
}

# variable "iam_instance_profile_name" {
#   description = "Name for the Jenkins IAM profile"
#   type        = string
#   default     = "jenkins-instance-profile"
# }


