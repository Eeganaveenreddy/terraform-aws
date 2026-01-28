variable "vpc_id" {}
variable "ami_id" {}
variable "instance_type" {}
# variable "public_subnet_id" {}
variable "private_subnet_id" {}
variable "server_name" {}
variable "ingress_ports" {}
variable "key_name" {
#   description = "Key pair name for DB EC2"
#   type        = string
}
variable "sg_id" {}