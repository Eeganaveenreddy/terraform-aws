
server_config = {
  "jenkins-terraform" = {
    ami_id        = "ami-087d1c9a513324697"
    instance_type = "t3.medium"
    ingress_ports = [8080, 22]
    server_name   = "jenkins-terraform"
    alb_enabled   = true
  },
  "app-terraform" = {
    ami_id        = "ami-02b8269d5e85954ef"
    instance_type = "t3.micro"
    ingress_ports = [80, 443, 22]
    server_name   = "app-terraform"
    alb_enabled   = true
  }
}

alb_name = "alb-terraform"
