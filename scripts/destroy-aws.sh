#!/usr/bin/env bash
# Destroy the demo VM and the surrounding VPC / NSG.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/aws-deploy.sh
source "$ROOT/scripts/lib/aws-deploy.sh"

INFRA="$ROOT/infra/aws"
KEY="$INFRA/.ssh/qms-demo"

require_cmd terraform

if [[ ! -f "$INFRA/terraform.tfstate" ]]; then
  echo "No local Terraform state at ${INFRA}/terraform.tfstate — nothing to destroy." >&2
  exit 0
fi

PUBKEY=""
if [[ -f "${KEY}.pub" ]]; then
  PUBKEY="$(cat "${KEY}.pub")"
else
  PUBKEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPlaceholderForDestroyOnly qms-demo-destroy"
fi

export TF_IN_AUTOMATION=1
terraform -chdir="$INFRA" init -input=false
terraform -chdir="$INFRA" destroy -input=false -auto-approve \
  -var="ssh_public_key=${PUBKEY}" \
  ${ALLOWED_CIDR:+-var="allowed_cidr=${ALLOWED_CIDR}"} \
  ${AWS_REGION:+-var="aws_region=${AWS_REGION}"}

echo "AWS demo resources destroyed."
