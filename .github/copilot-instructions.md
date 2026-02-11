# Copilot / AI Agent Instructions — terraform-aws

Purpose: Help an AI agent be productive in this Terraform repo by describing the
high-level architecture, where to make changes, and repository-specific
patterns and commands with concrete file examples.

1) Big picture
- This repo builds a small AWS environment using Terraform with a single
  environment under `envs/dev` and reusable module code in `modules/`.
- Orchestration lives in [envs/dev/main.tf](envs/dev/main.tf#L1-L120): it
  composes modules: `vpc`, `iam`, `ec2`, `db`, and `loadbalancer`.

2) Key modules / responsibilities
- `modules/vpc` — VPC, subnets, NAT/IGW and route tables ([modules/vpc/main.tf](modules/vpc/main.tf#L1-L200)).
- `modules/ec2` — generic EC2 instance module. Handles `user_data`, IAM profile,
  and root volume sizing ([modules/ec2/ec2.tf](modules/ec2/ec2.tf#L1-L200)).
- `modules/db` — DB instance (separate SG and user-data to attach/mount disks)
  ([modules/db/main.tf](modules/db/main.tf#L1-L120)).
- `modules/iam` — IAM roles and instance profiles; the terraform-runner role is
  explicitly created in [modules/iam/terraform-runner-role.tf](modules/iam/terraform-runner-role.tf#L1-L80).

3) How instances are configured
- The environment's server fleet is defined with a single map in
  [envs/dev/terraform.tfvars](envs/dev/terraform.tfvars#L1-L80) (`server_config`).
  Edit that map to add/remove servers or change AMIs/roles/ports.
- `envs/dev/main.tf` filters that map into two module sets: non-db EC2
  instances and DB instances using `for_each` with `coalesce(...is_db, false)`
  — see the filtering pattern at
  [envs/dev/main.tf](envs/dev/main.tf#L1-L40).

4) Notable patterns and project conventions
- IAM profile selection: `iam_instance_profile` is chosen per-server (see
  ternary in [envs/dev/main.tf](envs/dev/main.tf#L20-L40)).
- ALB wiring: `modules/loadbalancer` is created and a top-level
  `aws_lb_target_group_attachment` iterates only over servers where
  `alb_enabled == true` (see the `for_each` filter in
  [envs/dev/main.tf](envs/dev/main.tf#L60-L120)).
- Lifecycle behavior: modules use `create_before_destroy` to minimize downtime
  (see `modules/ec2/ec2.tf` and `modules/db/main.tf`).
- Root volume override: `root_block_device.volume_size` is set from
  `root_volume_size` when provided in `server_config`.

5) Startup scripts and automation
- `modules/ec2` injects `user_data` based on `role`:
  - `install_terraform.sh` for `terraform-runner` ([modules/ec2/install_terraform.sh](modules/ec2/install_terraform.sh#L1-L200))
  - `install_jenkins.sh` for CI (`jenkins-terraform`) ([modules/ec2/install_jenkins.sh](modules/ec2/install_jenkins.sh#L1-L200))
- DB module runs `mount_disk_on_dbserver.sh` to prepare block devices
  ([modules/db/mount_disk_on_dbserver.sh](modules/db/mount_disk_on_dbserver.sh#L1-L80)).

6) Provider / version and run commands
- Required Terraform and provider are declared in
  [envs/dev/providers.tf](envs/dev/providers.tf#L1-L40): Terraform >= 1.0 and
  `hashicorp/aws` ~> 5.0.
- Typical local workflow (run from `envs/dev`):
  - `terraform init`
  - `terraform plan -out=plan.tfplan` (the repo uses `terraform.tfvars` so
    explicit `-var-file` is not required)
  - `terraform apply plan.tfplan`

7) State and assumptions
- There is no backend block in `envs/dev/providers.tf`; this repo stores state
  locally by default. Confirm remote backend usage before changing state.
- Many templates index the first private subnet (`private_subnet_ids[0]`) — the
  code assumes at least one private subnet exists.

8) Quick examples to edit common tasks
- Add a new server: update the `server_config` map in
  [envs/dev/terraform.tfvars](envs/dev/terraform.tfvars#L1-L80) and run plan/apply.
- Change an AMI for `app-terraform`: update the `ami_id` in
  [envs/dev/terraform.tfvars](envs/dev/terraform.tfvars#L1-L40).

9) When modifying modules
- Preserve module inputs/outputs and keep behavior idempotent. Many modules
  are referenced by index/key (e.g., `module.ec2[each.key]`) — changing output
  shapes will break callers.

10) Where to look for more context
- Primary orchestration: [envs/dev/main.tf](envs/dev/main.tf#L1-L120)
- Server defaults: [envs/dev/terraform.tfvars](envs/dev/terraform.tfvars#L1-L120)
- EC2/user-data examples: [modules/ec2](modules/ec2)

If anything here is unclear or you want more detailed examples (e.g., a
walkthrough of adding a server and showing the exact `terraform` commands),
tell me which area to expand and I will update this file.

11) CI/CD: plan + manual apply via SSM
- There are now two workflows:
  - `terraform-runner-ssm.yml` — runs on push and `workflow_dispatch`, performs
    `terraform init` + `terraform plan` in `envs/dev`, saves `plan.tfplan`,
    `plan.txt`, and `plan.json`, and uploads them as artifacts for review.
  - `terraform-apply-ssm.yml` — manual `workflow_dispatch` that requires a
    `ref` input (branch/tag). When triggered it sends an SSM command to the
    EC2 instance tagged `Name=terraform-runner` to run `terraform apply` on
    that `ref`.

- Required secrets (add to repo Settings → Secrets):
  - `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION` — IAM user with
    `ssm:SendCommand`, `ssm:ListCommandInvocations`, and related `ssm` permissions.
  - `GITHUB_TOKEN` — used for cloning the repository on the remote instance.

- How it works: The plan workflow runs automatically and uploads plan
  artifacts for reviewers. A reviewer inspects the `plan.txt` / `plan.json` in
  the Actions UI, then manually triggers the `terraform-apply-ssm.yml` workflow
  to perform the remote apply on `terraform-runner`.

- Notes & safety:
  - The manual apply still runs `terraform apply -auto-approve` on the
    instance. Consider protecting the repository environment or adding a PR
    approval step before triggering the manual dispatch for production.
  - Ensure the `terraform-runner` instance's IAM profile has SSM and S3 (if
    using remote state) permissions; `modules/iam/ssm-iam-policy.tf` shows
    the project's SSM policy attachments.
  - For private repositories, the apply workflow clones using `GITHUB_TOKEN`;
    ensure the token has repo read access.
