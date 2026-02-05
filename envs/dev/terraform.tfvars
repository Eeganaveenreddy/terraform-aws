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
    role          = "ci"
  },
  "app-terraform" = {
    ami_id        = "ami-0e31485356635bd6a"  # new App Image
    # ami_id        = "ami-008356bd30e9e5e2c"  
    instance_type = "t3.micro"
    ingress_ports = [8069]
    server_name   = "app-terraform"
    alb_enabled   = true
    role          = "app"
  },
  "db-terraform" = {
    # ami_id        = "ami-03248082faa96aff5" 
    ami_id        = "ami-0741a849252f9202b" # new DB image
    instance_type = "t3.medium"
    ingress_ports = [5432]
    server_name   = "db-terraform"
    alb_enabled   = false
    is_db         = true
    role          = "database"
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
