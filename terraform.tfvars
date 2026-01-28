
server_config = {
  "jenkins-terraform" = {
    ami_id        = "ami-087d1c9a513324697"
    instance_type = "t3.micro"
    ingress_ports = [8080,22] # Jenkins app port
    server_name   = "jenkins-terraform"
    alb_enabled   = true
  },
  "app-terraform" = {
    ami_id        = "ami-02b8269d5e85954ef"
    instance_type = "t3.micro"
    ingress_ports = [8069,22] # Odoo app port ONLY
    server_name   = "app-terraform"
    alb_enabled   = true
  },
  "db-terraform" = {
    ami_id        = "ami-02b8269d5e85954ef"
    instance_type = "t3.micro"
    ingress_ports = [5432,22] # Odoo app port ONLY
    server_name   = "db-terraform"
    alb_enabled   = false
    is_db = true
  }
}

alb_name = "alb-terraform"
