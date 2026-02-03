variable "vpc_id" {}
variable "ami_id" {}
variable "instance_type" {}
# variable "public_subnet_id" {}
variable "private_subnet_id" {}
variable "server_name" {}
variable "ingress_ports" {}
variable "iam_instance_profile" {}
variable "env" {
  description = "Environment name (dev, sit, prod)"
  type        = string
}
variable "region" {
  description = "AWS region"
  type        = string
}
variable "is_db" {
  description = "Flag to indicate if this instance is a database server"
  type        = bool
  default     = false
}
variable "role" {
  description = "Logical role of the instance (ci, app, database, runner, compute)"
  type        = string
  default     = "database"
  validation {
    condition     = contains(["database"], var.role)
    error_message = "DB module only supports role = database"
  }
}

