# Jenkins + SSM + GitHub Troubleshooting Notes (Historical)

This document captures the debugging session history that led to the current operational runbook.

## Summary

A sequence of Jenkins pipeline failures on Terraform execution was traced across pipeline failure semantics, SSH host verification, Git transport/auth mode, execution-user key context, formatting gates, ALB health thresholds, and Session Manager runtime availability.

## Timeline of Issues and Fixes

## 1) Stage-level failure visibility was unclear

### Symptom
- Failure surfaced in `post { always { ... } }`, making stage-level failure less obvious.

### Fix
- Moved remote SSM status failure checks into `stage('Wait For SSM Result')`.
- Left `post` for logs/artifacts only.

### Files touched
- `Jenkinsfile.plan`
- `Jenkinsfile.apply`

---

## 2) Git clone failed with `Host key verification failed`

### Symptom
- Remote clone to `git@github.com:...` failed due to missing host trust.

### Fix
- Added `known_hosts` bootstrap:
```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
touch ~/.ssh/known_hosts && chmod 600 ~/.ssh/known_hosts
ssh-keyscan -H github.com >> ~/.ssh/known_hosts
```
- Set SSH option:
```bash
-o StrictHostKeyChecking=accept-new
```

### Files touched
- `Jenkinsfile.plan`
- `Jenkinsfile.apply`

---

## 3) Git clone failed with `could not read Username for 'https://github.com'`

### Root cause
- HTTPS clone attempted in a non-interactive context without credential helper/token.

### Fix
- Re-enabled URL rewrite from GitHub HTTPS to SSH (`git@github.com:...`).

### Files touched
- `Jenkinsfile.plan`
- `Jenkinsfile.apply`

---

## 4) Git auth failed with `Permission denied (publickey)`

### Root cause
- SSM command ran as root while SSH key existed under `/home/ubuntu/.ssh`.

### Fix
- Forced Git/SSH to use Ubuntu key context:
```bash
HOME=/home/ubuntu
GIT_SSH_COMMAND='ssh -i /home/ubuntu/.ssh/id_ed25519 -o StrictHostKeyChecking=accept-new'
```
- Added key existence precheck:
```bash
test -f /home/ubuntu/.ssh/id_ed25519 || ... exit 1
```

### Validation command
```bash
sudo -u ubuntu ssh -i /home/ubuntu/.ssh/id_ed25519 -T git@github.com
```

### Files touched
- `Jenkinsfile.plan`
- `Jenkinsfile.apply`

---

## 5) Pipeline failed after checkout with `exit status 1/3`

### Most likely cause
- `terraform fmt -check -recursive` gate failed.

### Fix
- Improved failure output and showed diffs:
```bash
terraform fmt -check -recursive -diff || (echo 'terraform fmt check failed. Run: terraform fmt -recursive' && exit 1)
```
- Enabled tracing (`set -eux`) to expose the exact failing command.

### Files touched
- `Jenkinsfile.plan`
- `Jenkinsfile.apply`

---

## 6) Jenkins ALB target unhealthy (`Request timed out`)

### Likely cause
- Jenkins response latency under load with strict health check settings.

### Fix
- Relaxed target group health check values:
- `healthy_threshold = 3`
- `unhealthy_threshold = 5`
- `timeout = 15`

### File touched
- `modules/loadbalancer/main.tf`

---

## 7) Session Manager showed `Not connected`

### Findings
- IAM policy attachment was in place.
- Runtime likely issue: SSM agent state or outbound connectivity.

### Fix
- Hardened Jenkins userdata for SSM agent install/start/enable.

### File touched
- `modules/ec2/install_jenkins.sh`

---

## 8) Terraform failed with `UnauthorizedOperation` on AZ lookup

### Error
- `ec2:DescribeAvailabilityZones` denied for:
- `arn:aws:sts::566579489861:assumed-role/Terraform-Runner-Role/...`
- Failure point:
- `module.vpc.data.aws_availability_zones.available`

### Root cause
- `Terraform-Runner-Role` did not include EC2 read permissions needed by Terraform data sources.

### Fix
- Attached `AmazonEC2ReadOnlyAccess` to `Terraform-Runner-Role`.

### File touched
- `modules/iam/iam-policy-for-terraform-runner.tf`

---

## One-time Runner Setup Used During Debugging

### Generate SSH key (Ubuntu)
```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
ssh-keygen -t ed25519 -C "terraform-runner-github" -f ~/.ssh/id_ed25519 -N ""
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
touch ~/.ssh/known_hosts && chmod 600 ~/.ssh/known_hosts
ssh-keyscan -H github.com >> ~/.ssh/known_hosts
cat ~/.ssh/id_ed25519.pub
```

### Validate repo access
```bash
sudo -u ubuntu GIT_SSH_COMMAND="ssh -i /home/ubuntu/.ssh/id_ed25519 -o StrictHostKeyChecking=accept-new" \
git ls-remote git@github.com:<org-or-user>/<repo>.git
```

---

## Related Docs

- Operational runbook: `docs/runbooks/jenkins-ssm-incident-runbook.md`

---

## Additional Incident: Remote State Overwrite in CI

### What happened
- Jenkins init command used `-migrate-state -force-copy` on each run.
- Runner local state (partial) was copied into S3 backend key.
- Subsequent plans showed large unexpected creates/destroys.

### Root cause
- One-time migration flags were left in recurring CI pipeline.

### Impact
- Drift between expected infra and Terraform state.
- Risk of duplicate creation or unintended replacement/destruction.

### Corrective actions
1. Switched Jenkins init to `terraform init -reconfigure ...`.
2. Split dev stack into:
- `envs/dev-platform`
- `envs/dev-workload`
3. Defaulted Jenkins `TF_WORKING_DIR` to `envs/dev-workload`.
4. Removed old monolithic `envs/dev` stack from repo to prevent accidental use.

### Preventive controls
- Never use `-migrate-state -force-copy` in scheduled/standard CI jobs.
- Reserve migration flags for one-time operator-run backend transitions.
- Validate `terraform state list` and backend key when plan behavior changes abruptly.
