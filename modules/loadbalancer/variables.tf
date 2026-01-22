variable "alb_name" {}
# variable "alb_sg_id" {}
variable "public_subnet_id" {
    type = list(string)
}
# variable "private_subnet_id" {
#     type = list(string)
# }
variable "vpc_id" {}
variable "server_config" {
  description = "Configuration for EC2 instances and their load balancing"
  type = map(object({
    ami_id        = string
    instance_type = string
    ingress_ports = list(number)
    server_name   = string
    alb_enabled   = bool
  }))
}