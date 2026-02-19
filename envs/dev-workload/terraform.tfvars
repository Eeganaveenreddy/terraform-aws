aws_region = "ap-south-1"
env        = "dev"

platform_state_bucket = "terraform-state-566579489861-ap-south-1"
platform_state_key    = "terraform-aws/envs/dev-platform/terraform.tfstate"
state_lock_table      = "terraform-state-locks"

server_config = {
  "app-terraform" = {
    ami_id           = "ami-0f480abe64df75f41"
    instance_type    = "c5a.2xlarge"
    ingress_ports    = [8069]
    server_name      = "app-terraform"
    alb_enabled      = true
    role             = "app"
    root_volume_size = 250
  },
  "db-terraform" = {
    ami_id        = "ami-07a82f67f1dd0b930"
    instance_type = "c5a.xlarge"
    ingress_ports = [5432]
    server_name   = "db-terraform"
    alb_enabled   = false
    is_db         = true
    role          = "database"
  }
}
