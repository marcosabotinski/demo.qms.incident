#!/usr/bin/env bash
# Destroy the demo VM, the surrounding VPC / NSG, and the Cloudflare DNS / IP Access Rule resources.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/aws-deploy.sh
source "$ROOT/scripts/lib/aws-deploy.sh"
load_dotenv "$ROOT"

INFRA="$ROOT/infra/aws"
KEY="$INFRA/.ssh/qms-demo"
TFVARS="$INFRA/hostname.auto.tfvars"

require_cmd terraform

if [[ ! -f "$INFRA/terraform.tfstate" ]]; then
  echo "No local Terraform state at ${INFRA}/terraform.tfstate — nothing to destroy." >&2
  exit 0
fi

if [[ -z "${CLOUDFLARE_API_TOKEN:-}" ]]; then
  echo "Set CLOUDFLARE_API_TOKEN in the environment so Terraform can destroy Cloudflare resources." >&2
  exit 1
fi

PUBKEY=""
if [[ -f "${KEY}.pub" ]]; then
  PUBKEY="$(cat "${KEY}.pub")"
else
  PUBKEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPlaceholderForDestroyOnly qms-demo-destroy"
fi

DESTROY_ARGS=()

if [[ -n "${DEMO_HOSTNAME:-}" ]]; then
  DESTROY_ARGS+=(-var="hostname=$(normalize_hostname "$DEMO_HOSTNAME")")
elif [[ ! -f "$TFVARS" ]] || ! grep -q '^hostname ' "$TFVARS"; then
  echo "Set DEMO_HOSTNAME (or keep infra/aws/hostname.auto.tfvars from deploy) so Terraform can destroy." >&2
  exit 1
fi

if [[ -n "${CF_ZONE_ID:-}" ]]; then
  DESTROY_ARGS+=(-var="cloudflare_zone_id=${CF_ZONE_ID}")
elif [[ ! -f "$TFVARS" ]] || ! grep -q '^cloudflare_zone_id ' "$TFVARS"; then
  echo "Set CF_ZONE_ID (or keep cloudflare_zone_id in infra/aws/hostname.auto.tfvars) so Terraform can destroy Cloudflare resources." >&2
  exit 1
fi

if [[ -n "${CF_ALLOW_IPS:-}" ]]; then
  ALLOW_CIDRS=()
  IFS=',' read -ra _cf_allow_raw <<< "$CF_ALLOW_IPS"
  for _raw in "${_cf_allow_raw[@]}"; do
    [[ -z "${_raw// }" ]] && continue
    ALLOW_CIDRS+=("$(normalize_cidr "$_raw")")
  done
  DESTROY_ARGS+=(-var="allow_cidrs=$(tf_string_list "${ALLOW_CIDRS[@]}")")
fi

export TF_IN_AUTOMATION=1
terraform -chdir="$INFRA" init -input=false

terraform -chdir="$INFRA" destroy -input=false -auto-approve \
  -var="ssh_public_key=${PUBKEY}" \
  ${ALLOWED_CIDR:+-var="allowed_cidr=${ALLOWED_CIDR}"} \
  ${AWS_REGION:+-var="aws_region=${AWS_REGION}"} \
  "${DESTROY_ARGS[@]}"

echo "AWS and Cloudflare demo resources destroyed."
