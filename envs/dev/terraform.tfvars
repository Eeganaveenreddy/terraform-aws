aws_region = "ap-south-1"
env        = "dev"
alb_name   = "alb-terraform"

server_config = {
  "jenkins-terraform" = {
    ami_id        = "ami-02b8269d5e85954ef"
    instance_type = "t3.micro"
    ingress_ports = [8080]
    server_name   = "jenkins-terraform"
    alb_enabled   = true
  },
  "app-terraform" = {
    # ami_id        = "ami-02b8269d5e85954ef"
    ami_id        = "ami-015ed7dbfc98f9d7c"
    instance_type = "t3.micro"
    ingress_ports = [8069]
    server_name   = "app-terraform"
    alb_enabled   = true
  },
  "db-terraform" = {
    # ami_id        = "ami-02b8269d5e85954ef"
    ami_id        = "ami-06d67eedaf8ee98fe"
    instance_type = "t3.micro"
    ingress_ports = [5432]
    server_name   = "db-terraform"
    alb_enabled   = false
    is_db         = true
  },
  "terraform-runner" = {
    ami_id        = "ami-02b8269d5e85954ef"
    instance_type = "t3.micro"
    ingress_ports = []
    server_name   = "terraform-runner"
    alb_enabled   = false
  }
}
