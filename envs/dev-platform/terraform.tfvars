aws_region = "ap-south-1"
env        = "dev"
alb_name   = "alb-terraform"

server_config = {
  "jenkins-terraform" = {
    ami_id        = "ami-0fe95f30c3e96b8cd"
    instance_type = "t3.small"
    ingress_ports = [8080]
    server_name   = "jenkins-terraform"
    alb_enabled   = true
    role          = "ci"
  },
  # Keep app target group in platform ALB; app instance lives in dev-workload.
  "app-terraform" = {
    ami_id        = "ami-0f480abe64df75f41"
    instance_type = "t3.micro"
    ingress_ports = [8069]
    server_name   = "app-terraform"
    alb_enabled   = true
    role          = "app"
    root_volume_size = 50
  },
  "terraform-runner" = {
    ami_id        = "ami-02b8269d5e85954ef"
    instance_type = "t3.micro"
    ingress_ports = []
    server_name   = "terraform-runner"
    alb_enabled   = false
    role          = "terraform-runner"
  }
}
