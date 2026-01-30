
server_config = {
  "jenkins-terraform" = {
    ami_id        = "ami-02b8269d5e85954ef"
    instance_type = "t3.micro"
    ingress_ports = [8080, 22] # Jenkins app port
    server_name   = "jenkins-terraform"
    alb_enabled   = true
  },
  "app-terraform" = {
    ami_id        = "ami-02b8269d5e85954ef"
    instance_type = "t3.micro"
    ingress_ports = [8069] # Odoo app port ONLY
    server_name   = "app-terraform"
    alb_enabled   = true
  },
  "db-terraform" = {
    ami_id        = "ami-02b8269d5e85954ef"
    instance_type = "t3.micro"
    ingress_ports = [5432] # Odoo app port ONLY
    server_name   = "db-terraform"
    alb_enabled   = false
    is_db         = true
  },
  "terraform-runner" = {
    ami_id        = "ami-02b8269d5e85954ef"
    instance_type = "t3.micro"
    ingress_ports = [] 
    server_name = "terraform-runner"
    alb_enabled = false
  }
}

alb_name = "alb-terraform"
