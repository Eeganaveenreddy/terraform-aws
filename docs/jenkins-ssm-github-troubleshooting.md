# Jenkins + Terraform Runner Troubleshooting Notes

This file captures the key issues and fixes from the recent debugging session.

## 1) Jenkins pipeline not showing red clearly on remote failure

### Symptom
- Pipeline failure was raised in `post { always { ... } }`, so stage-level red status was unclear.

### Fix
- Move remote SSM status failure checks into `stage('Wait For SSM Result')`.
- Keep `post` for log/artifact collection only.

### Files updated
- `Jenkinsfile.plan`
- `Jenkinsfile.apply`

---

## 2) Git clone failed: `Host key verification failed`

### Symptom
- Remote clone using `git@github.com:...` failed with host key verification.

### Fixes applied
- Added known_hosts bootstrap in remote commands:
  - create `~/.ssh`
  - `ssh-keyscan -H github.com >> ~/.ssh/known_hosts`
- Also set SSH command with:
  - `-o StrictHostKeyChecking=accept-new`

### Files updated
- `Jenkinsfile.plan`
- `Jenkinsfile.apply`

---

## 3) Git clone failed: `could not read Username for 'https://github.com'`

### Root cause
- HTTPS clone requires username/token when no credential helper is configured.

### Fix
- Re-enabled GitHub URL rewrite to SSH (`git@github.com:...`) for GitHub HTTPS URLs.

### Files updated
- `Jenkinsfile.plan`
- `Jenkinsfile.apply`

---

## 4) Git auth failed: `Permission denied (publickey)`

### Root cause
- SSM RunCommand executes as root in many setups; SSH key existed under `/home/ubuntu/.ssh`, not root.

### Fixes applied
- Force git to use Ubuntu key explicitly:
  - `HOME=/home/ubuntu`
  - `GIT_SSH_COMMAND='ssh -i /home/ubuntu/.ssh/id_ed25519 -o StrictHostKeyChecking=accept-new'`
- Added explicit precheck:
  - `test -f /home/ubuntu/.ssh/id_ed25519 || ... exit 1`

### Files updated
- `Jenkinsfile.plan`
- `Jenkinsfile.apply`

### Validation command
```bash
sudo -u ubuntu ssh -i /home/ubuntu/.ssh/id_ed25519 -T git@github.com
```
Expected: authenticated message from GitHub.

---

## 5) Pipeline failed after checkout with `exit status 1/3`

### Most likely cause
- `terraform fmt -check -recursive` failing.

### Fixes applied
- Improved fmt check output to show diffs and clear message:
```bash
terraform fmt -check -recursive -diff || (echo 'terraform fmt check failed. Run: terraform fmt -recursive' && exit 1)
```
- Enabled command tracing:
  - changed `set -eu` to `set -eux` in remote command list to print exact failing command.

### Files updated
- `Jenkinsfile.plan`
- `Jenkinsfile.apply`

---

## 6) ALB target group unhealthy during Jenkins runs (`Request timed out`)

### Likely cause
- Jenkins response delay under load (instance size/resource pressure), strict health checks.

### Fixes applied
- Relaxed Jenkins target group health check:
  - `healthy_threshold`: 3
  - `unhealthy_threshold`: 5
  - `timeout`: 15s

### File updated
- `modules/loadbalancer/main.tf`

---

## 7) Session Manager showed `Not connected`

### Findings
- IAM role wiring includes SSM managed policy.
- Common runtime causes:
  - SSM agent not running on Jenkins AMI
  - outbound path/NAT issue from private subnet

### Fix applied
- Added SSM agent install/start hardening to Jenkins userdata script.

### File updated
- `modules/ec2/install_jenkins.sh`

---

## Useful one-time server setup commands (terraform-runner)

### Generate SSH key for GitHub (Ubuntu user)
```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
ssh-keygen -t ed25519 -C "terraform-runner-github" -f ~/.ssh/id_ed25519 -N ""
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
touch ~/.ssh/known_hosts && chmod 600 ~/.ssh/known_hosts
ssh-keyscan -H github.com >> ~/.ssh/known_hosts
cat ~/.ssh/id_ed25519.pub
```

### Test repo access
```bash
sudo -u ubuntu GIT_SSH_COMMAND="ssh -i /home/ubuntu/.ssh/id_ed25519 -o StrictHostKeyChecking=accept-new" \
git ls-remote git@github.com:<org-or-user>/<repo>.git
```

---

## What to check next if pipeline still fails

1. Open archived artifacts:
- `ssm-stdout.log`
- `ssm-stderr.log`

2. Identify the exact command failing (trace enabled via `set -eux`).

3. If ALB still flips unhealthy:
- increase Jenkins EC2 size (`t3.small` or `t3.medium`)
- confirm Jenkins service health on instance
- verify SG/NAT/SSM agent status

---

## IAM wiring for Terraform runner (where role is configured)

This is how `Terraform-Runner-Role` gets attached to the `terraform-runner` EC2.

1. Role definition
- File: `modules/iam/terraform-runner-role.tf:2`
- Creates IAM role `Terraform-Runner-Role`.
- Trust policy allows EC2 service (`ec2.amazonaws.com`) to assume it.

2. Instance profile definition
- File: `modules/iam/instance-profile.tf:2`
- Creates instance profile `Terraform-Runner-Profile`.

3. Role bound to instance profile
- File: `modules/iam/instance-profile.tf:3`
- `Terraform-Runner-Profile` is attached to `aws_iam_role.terraform_runner`.

4. IAM output exported
- File: `modules/iam/outputs.tf:5`
- Exposes `iam_instance_profile_terraform_runner` for use by env modules.

5. Profile selection logic in env
- File: `envs/dev/main.tf:33`
- If server role is `terraform-runner`, it picks `module.iam.iam_instance_profile_terraform_runner`.
- Otherwise it picks default instance profile for other servers.

6. Profile passed into EC2 resource
- File: `modules/ec2/ec2.tf:7`
- EC2 resource uses `iam_instance_profile = var.iam_instance_profile`.

7. Server marked as terraform runner
- File: `envs/dev/terraform.tfvars:41`
- `role = "terraform-runner"` marks that server entry, which triggers step 5 logic.

End-to-end flow:
- `terraform.tfvars` marks runner -> `envs/dev/main.tf` selects runner profile -> `modules/ec2/ec2.tf` attaches it -> profile points to runner role -> role permissions are used by Terraform/AWS CLI on that EC2 (no `aws configure` needed on runner).

---

## Terraform remote backend setup (S3 + DynamoDB) using Terraform code

### Backend infra code location
- `envs/backend/main.tf`
- `envs/backend/providers.tf`
- `envs/backend/variables.tf`
- `envs/backend/outputs.tf`
- `envs/backend/terraform.tfvars`

### Create backend infrastructure
```bash
cd envs/backend
# Edit terraform.tfvars if you want non-default region/table
terraform init
terraform plan
terraform apply
```

### Configure dev stack to use S3 backend
- Backend block file: `envs/dev/backend.tf`

```bash
cd ../dev
terraform init -migrate-state \
  -backend-config="bucket=<your-backend-bucket-name>" \
  -backend-config="key=terraform-aws/envs/dev/terraform.tfstate" \
  -backend-config="region=ap-south-1" \
  -backend-config="dynamodb_table=terraform-state-locks" \
  -backend-config="encrypt=true"
terraform plan
```

### Notes
- Run backend stack first, then migrate `envs/dev` local state to S3.
