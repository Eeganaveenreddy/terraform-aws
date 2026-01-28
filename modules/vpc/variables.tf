variable "vpc_cidr" {
  description = "CIDR block passed from root"
  type        = string
}

variable "public_subnet_count" { 
    default = 2
}

variable "private_subnet_count" { 
    default = 1
}

