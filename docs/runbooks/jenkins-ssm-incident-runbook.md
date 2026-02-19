# Jenkins + Terraform Runner Incident Runbook

Use this runbook when Jenkins pipelines fail while running Terraform through AWS SSM on the terraform-runner instance.

## Scope

Covers failures across:
- Jenkins pipeline stage reporting
- SSM command execution
- GitHub SSH auth/clone
- Terraform formatting gate
- Jenkins ALB health checks
- Session Manager connectivity

---

## Fast Triage (5-10 minutes)

1. Confirm failing stage in Jenkins.
- Prioritize failures in `Wait For SSM Result`.

2. Open archived logs from the build.
- `ssm-stdout.log`
- `ssm-stderr.log`

3. Find first failing command.
- Remote execution should be traced with `set -eux`.
- Use the first command that returned non-zero as the root signal.

4. Map error text to the playbook section below.
- `Host key verification failed` -> [GitHub host key bootstrap](#2-github-clone-fails-host-key-verification-failed)
- `could not read Username for 'https://github.com'` -> [HTTPS rewrite to SSH](#3-github-clone-fails-could-not-read-username-for-httpsgithubcom)
- `Permission denied (publickey)` -> [SSH key path/user mismatch](#4-github-auth-fails-permission-denied-publickey)
- `exit status 1` after checkout -> [Terraform fmt gate](#5-pipeline-fails-after-checkout-with-exit-status-13)
- `Request timed out` (ALB target unhealthy) -> [Jenkins health check tuning](#6-alb-target-group-unhealthy-request-timed-out)
- Session Manager `Not connected` -> [SSM agent/network checks](#7-session-manager-not-connected)

5. Re-run pipeline after fix and validate stage-level status is explicit.

---

## 1) Jenkins pipeline not red at stage level on remote failure

### Symptom
- Build fails, but failure appears from `post { always { ... } }` rather than the execution stage.

### Root cause
- SSM failure check evaluated in `post` block, masking stage-level failure visibility.

### Fix standard
- Perform SSM status validation inside `stage('Wait For SSM Result')`.
- Keep `post` block for log/artifact collection only.

### Files
- `Jenkinsfile.plan`
- `Jenkinsfile.apply`

---

## 2) GitHub clone fails: `Host key verification failed`

### Symptom
- Clone to `git@github.com:...` fails during remote execution.

### Root cause
- `known_hosts` missing/empty for execution user.

### Fix standard
- Bootstrap SSH known_hosts before clone:
```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
touch ~/.ssh/known_hosts && chmod 600 ~/.ssh/known_hosts
ssh-keyscan -H github.com >> ~/.ssh/known_hosts
```
- Use:
```bash
GIT_SSH_COMMAND='ssh -o StrictHostKeyChecking=accept-new'
```

### Files
- `Jenkinsfile.plan`
- `Jenkinsfile.apply`

---

## 3) GitHub clone fails: `could not read Username for 'https://github.com'`

### Symptom
- Clone attempts HTTPS URL and prompts for non-interactive credentials.

### Root cause
- HTTPS transport without credential helper/token in SSM execution context.

### Fix standard
- Rewrite GitHub HTTPS URLs to SSH format (`git@github.com:...`) before clone.

### Files
- `Jenkinsfile.plan`
- `Jenkinsfile.apply`

---

## 4) GitHub auth fails: `Permission denied (publickey)`

### Symptom
- SSH auth to GitHub fails even though key exists on the instance.

### Root cause
- SSM commonly executes as root; key is under `/home/ubuntu/.ssh`.

### Fix standard
- Force SSH key/user context explicitly:
```bash
HOME=/home/ubuntu
GIT_SSH_COMMAND='ssh -i /home/ubuntu/.ssh/id_ed25519 -o StrictHostKeyChecking=accept-new'
```
- Add fail-fast precheck:
```bash
test -f /home/ubuntu/.ssh/id_ed25519 || { echo 'Missing /home/ubuntu/.ssh/id_ed25519'; exit 1; }
```

### Validation
```bash
sudo -u ubuntu ssh -i /home/ubuntu/.ssh/id_ed25519 -T git@github.com
```
Expected: GitHub authenticated message.

### Files
- `Jenkinsfile.plan`
- `Jenkinsfile.apply`

---

## 5) Pipeline fails after checkout with `exit status 1/3`

### Symptom
- Failure occurs after checkout and before/around planning/apply.

### Most likely cause
- `terraform fmt -check -recursive` failed.

### Fix standard
- Keep explicit fmt error output:
```bash
terraform fmt -check -recursive -diff || (echo 'terraform fmt check failed. Run: terraform fmt -recursive' && exit 1)
```
- Keep tracing enabled (`set -eux`) to expose exact failing command.

### Files
- `Jenkinsfile.plan`
- `Jenkinsfile.apply`

---

## 6) ALB target group unhealthy: `Request timed out`

### Symptom
- Jenkins target flips unhealthy during load/pipeline execution.

### Likely causes
- Jenkins instance resource pressure.
- Health checks too strict for response latency.

### Fix standard
- Set target group health check to:
- `healthy_threshold = 3`
- `unhealthy_threshold = 5`
- `timeout = 15`

### File
- `modules/loadbalancer/main.tf`

### If still unstable
- Increase Jenkins instance size (for example `t3.small` or `t3.medium`).
- Validate Jenkins service health on instance.
- Re-check SG, NAT egress, and dependent services.

---

## 7) Session Manager: `Not connected`

### Symptom
- Session Manager cannot connect to Jenkins/runner instance.

### Checks
- IAM instance profile has SSM managed policy attached.
- SSM agent installed and running.
- Instance has outbound path (NAT/VPC endpoints) for SSM endpoints.

### Fix standard
- Harden userdata to install/start/enable SSM agent.

### File
- `modules/ec2/install_jenkins.sh`

---

## 8) Terraform fails with `UnauthorizedOperation` for `DescribeAvailabilityZones`

### Symptom
- Terraform fails on `data.aws_availability_zones.available` with:
- `ec2:DescribeAvailabilityZones` not authorized for `Terraform-Runner-Role`.

### Root cause
- Runner instance role is missing required EC2 read permissions.

### Fix standard
- Attach AWS managed policy:
- `arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess`

### File
- `modules/iam/iam-policy-for-terraform-runner.tf`

---

## One-time terraform-runner bootstrap (Ubuntu)

### Generate GitHub SSH key
```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
ssh-keygen -t ed25519 -C "terraform-runner-github" -f ~/.ssh/id_ed25519 -N ""
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
touch ~/.ssh/known_hosts && chmod 600 ~/.ssh/known_hosts
ssh-keyscan -H github.com >> ~/.ssh/known_hosts
cat ~/.ssh/id_ed25519.pub
```

### Validate repository access
```bash
sudo -u ubuntu GIT_SSH_COMMAND="ssh -i /home/ubuntu/.ssh/id_ed25519 -o StrictHostKeyChecking=accept-new" \
git ls-remote git@github.com:<org-or-user>/<repo>.git
```

---

## Operator Checklist

Run this checklist each time before closing an incident:

1. Failure is visible in execution stage (not only in `post`).
2. `ssm-stdout.log` and `ssm-stderr.log` were reviewed.
3. First non-zero command identified from traced output (`set -eux`).
4. GitHub connectivity verified for Ubuntu key if auth-related.
5. Terraform fmt gate passed or formatting was corrected.
6. Jenkins target health stable during and after rerun.
7. SSM connectivity verified if Session Manager was impacted.
8. Runner IAM role has required read permissions for Terraform data sources.
9. Rerun succeeded and linked to incident notes.

---

## Change History Captured by This Runbook

This runbook reflects fixes already applied in:
- `Jenkinsfile.plan`
- `Jenkinsfile.apply`
- `modules/loadbalancer/main.tf`
- `modules/ec2/install_jenkins.sh`
- `modules/iam/iam-policy-for-terraform-runner.tf`

---

## Current Stack Layout (UAT)

Use split stacks to avoid CI self-destruction:

- Platform stack: `envs/uat-platform`
  - VPC, IAM, Jenkins, terraform-runner, ALB, target groups, Jenkins TG attachment
- Workload stack: `envs/uat-workload`
  - app/db instances, app TG attachment via platform remote state

### Jenkins defaults

- `TF_WORKING_DIR` defaults to `envs/uat-workload` in all Jenkinsfiles.
- Set `TF_WORKING_DIR=envs/uat-platform` only for platform changes.

### Repo URL normalization regex note

- Pattern used: `(?:\.git)+$`
- `(?: ... )` means a non-capturing group (used for matching, not storing).
- `\.git` means literal `.git`.
- `+` means one or more times.
- `$` means end of string.
- This matches `.git`, `.git.git`, `.git.git.git`, etc., only when it appears at the end.
- Practical use in Jenkinsfiles:
  `repoUrl = repoUrl.replaceAll(/(?:\.git)+$/, '') + '.git'`
  to ensure the URL ends with exactly one `.git`.

---

## Backend State Safety Rules

1. Do not run `terraform init -migrate-state -force-copy` in routine Jenkins jobs.
2. Use `terraform init -reconfigure ...` in CI.
3. Use state migration (`-migrate-state`) only one-time during backend migration.
4. If plan suddenly shows mass creates for existing infra, stop and validate state source/key before apply.

---

## Related Docs

- Historical troubleshooting notes: `docs/postmortems/jenkins-ssm-github-troubleshooting-notes.md`
