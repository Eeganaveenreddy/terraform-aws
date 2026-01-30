#!/bin/bash
set -euo pipefail

LOG=/var/log/terraform-userdata.log
exec > >(tee -a "$LOG") 2>&1

export DEBIAN_FRONTEND=noninteractive

echo "=============================="
echo " Terraform Runner Bootstrap "
echo "=============================="

# -----------------------------
# Wait for apt locks
# -----------------------------
echo "Waiting for apt locks..."
until ! fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 && \
      ! fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do
  sleep 5
done

# -----------------------------
# Update system
# -----------------------------
echo "Updating system..."
apt-get update -y

# -----------------------------
# Base packages
# -----------------------------
echo "Installing base packages..."
apt-get install -y \
  unzip \
  git \
  curl \
  wget \
  gnupg \
  software-properties-common

# -----------------------------
# Install AWS CLI v2 (Official)
# -----------------------------
echo "Installing AWS CLI v2..."
cd /tmp

if ! command -v aws >/dev/null 2>&1; then
  curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip
  ./aws/install
else
  echo "AWS CLI already installed"
fi

# -----------------------------
# Install Terraform (HashiCorp Repo - Prod Method)
# -----------------------------
echo "Installing Terraform..."

if ! command -v terraform >/dev/null 2>&1; then
  curl -fsSL https://apt.releases.hashicorp.com/gpg | \
    gpg --dearmor -o /usr/share/keyrings/hashicorp.gpg

  echo "deb [signed-by=/usr/share/keyrings/hashicorp.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
  > /etc/apt/sources.list.d/hashicorp.list

  apt-get update -y
  apt-get install -y terraform
else
  echo "Terraform already installed"
fi

# -----------------------------
# Install / Verify SSM Agent
# -----------------------------
echo "Installing SSM Agent..."

if ! systemctl status snap.amazon-ssm-agent.amazon-ssm-agent >/dev/null 2>&1; then
  snap install amazon-ssm-agent --classic
  systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent
  systemctl start snap.amazon-ssm-agent.amazon-ssm-agent
else
  echo "SSM Agent already running"
fi

# -----------------------------
# Final Verification
# -----------------------------
echo "=============================="
echo " Installation Complete "
echo "=============================="

echo "Terraform:"
terraform -v || true

echo "AWS CLI:"
aws --version || true

echo "Git:"
git --version || true

echo "SSM Agent:"
systemctl status snap.amazon-ssm-agent.amazon-ssm-agent --no-pager || true

echo "=== USERDATA COMPLETE ==="