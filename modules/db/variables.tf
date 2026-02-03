variable "vpc_id" {}
variable "ami_id" {}
variable "instance_type" {}
# variable "public_subnet_id" {}
variable "private_subnet_id" {}
variable "server_name" {}
variable "ingress_ports" {}
variable "iam_instance_profile" {}
variable "sg_id" {}
variable "env" {
  description = "Environment name (dev, sit, prod)"
  type        = string
}
variable "region" {
  description = "AWS region"
  type        = string
}
