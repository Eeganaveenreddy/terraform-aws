# ALB Host-Header Routing and SSL (Terraform)

## Scope
This stack configures ALB routing for:
- `awserp.esanchaya.com` -> app target group
- `jenkins.esanchaya.com` -> jenkins target group

It also configures SSL certificates on the HTTPS listener using:
- Primary/default ACM cert in `modules/loadbalancer`
- Additional SNI cert attachments in `modules/alb-ssl`

## Current file locations
- ALB + listeners + listener rules: `modules/loadbalancer/main.tf`
- ALB security group: `modules/loadbalancer/sg.tf`
- Load balancer outputs: `modules/loadbalancer/outputs.tf`
- Additional SSL cert module: `modules/alb-ssl/main.tf`
- UAT platform wiring: `envs/uat-platform/main.tf`
- UAT values: `envs/uat-platform/terraform.tfvars`

## Key variables
- Default HTTPS certificate ARN: `acm_certificate_arn`
- Additional certificates (SNI): `additional_acm_certificate_arns`

`additional_acm_certificate_arns` is provided from `envs/uat-platform/terraform.tfvars` and attached via `module "app_alb_ssl"`.

## Rule priorities
- App host rule priority: `10`
- Jenkins host rule priority: `100`

If AWS returns `PriorityInUse`, choose a free priority value.

## Important note
Do not change ALB name unless explicitly required. Domain mapping depends on existing ALB setup.

## AWS Backup (Tag-Based)
### Scope
Backup is configured once in `uat-platform` and protects instances across both `uat-platform` and `uat-workload` using tag-based selection.

### Module and wiring
- Backup module: `modules/aws-snapshot/main.tf`
- Backup module variables: `modules/aws-snapshot/variables.tf`
- Platform wiring: `envs/uat-platform/main.tf` (`module "aws_snapshot"`)
- Platform backup inputs: `envs/uat-platform/variables.tf`
- Platform backup values: `envs/uat-platform/terraform.tfvars`

### Selection model
- AWS Backup selection uses tag: `Backup=Daily`
- `resource_tags = { Backup = "Daily" }` is applied to:
- EC2 instances in `envs/uat-platform/main.tf`
- EC2 instances in `envs/uat-workload/main.tf`
- DB instances in `envs/uat-workload/main.tf`

### Default schedule and retention
- Schedule: `cron(30 19 * * ? *)` (01:00 AM IST)
- Retention: `2` days

### Apply order
1. Apply `envs/uat-platform` (creates vault/plan/selection/role and platform tags)
2. Apply `envs/uat-workload` (adds workload instance tags for backup selection)
