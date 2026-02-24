aws_region          = "ap-south-1"
env                 = "uat"
alb_name            = "alb-terraform"
acm_certificate_arn = "arn:aws:acm:ap-south-1:566579489861:certificate/698776da-a9fc-4ebb-a9e5-6c65986eb048"
additional_acm_certificate_arns = [
  "arn:aws:acm:ap-south-1:566579489861:certificate/d6d75517-38d0-414c-9c84-3ca648f08b59"
]
backup_vault_name          = "ec2-daily-backup-vault-uat"
backup_role_name           = "aws-backup-service-role-uat"
backup_plan_name           = "daily-ec2-backup-plan-uat"
backup_selection_name      = "ec2-daily-backup-selection-uat"
backup_schedule            = "cron(1 * * * ? *)"
backup_retention_days      = 2
backup_selection_tag_key   = "Backup"
backup_selection_tag_value = "Daily"

server_config = {
  "jenkins-terraform" = {
    # ami_id        = "ami-0fe95f30c3e96b8cd"
    ami_id        = "ami-0ae70a9f8c97a4e6c"
    instance_type = "t3.small"
    ingress_ports = [8080]
    server_name   = "jenkins-terraform"
    alb_enabled   = true
    role          = "ci"
  },
  # Keep app target group in platform ALB; app instance lives in workload stack.
  "app-terraform" = {
    ami_id           = "ami-0f480abe64df75f41"
    instance_type    = "c5a.xlarge"
    ingress_ports    = [8069]
    server_name      = "app-terraform"
    alb_enabled      = true
    role             = "app"
    root_volume_size = 50
  },
  "terraform-runner" = {
    # ami_id        = "ami-02b8269d5e85954ef" # old terraform runner image
    ami_id        = "ami-0738438d177a758a6"
    instance_type = "t3.micro"
    ingress_ports = []
    server_name   = "terraform-runner"
    alb_enabled   = false
    role          = "terraform-runner"
  }
}
