#!/usr/bin/env bash
# Provision a t3.small EC2 VM behind Cloudflare (proxied A record, Flexible SSL,
# zone IP Access Rules) and start the compose stack on origin HTTP :80.
set -euo pipefail

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  cat <<'EOF'
Deploy the QMS demo to a t3.small EC2 VM behind Cloudflare.

  CLOUDFLARE_API_TOKEN=... CF_ZONE_ID=... DEMO_HOSTNAME=test.example.com ./scripts/deploy-aws.sh

Needs Terraform, AWS credentials, and a Cloudflare API token that can edit
DNS, zone settings, and IP Access Rules for CF_ZONE_ID. Copy .env.example
to a gitignored .env and fill it in, or export these vars. Optional env:
  DEMO_HOSTNAME           required public DNS name (must be in the Cloudflare zone)
  CF_ZONE_ID              required Cloudflare zone ID
  CLOUDFLARE_API_TOKEN    required; read from the environment only (never printed)
  CF_ALLOW_IPS            comma-separated CIDRs for zone IP Access Rules (default: this machine)
  ALLOWED_CIDR            CIDR allowed to hit SSH :22 (default: this machine)
  AWS_REGION              default eu-central-1
  INSTANCE_TYPE           default t3.small
EOF
  exit 0
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/aws-deploy.sh
source "$ROOT/scripts/lib/aws-deploy.sh"
load_dotenv "$ROOT"

INFRA="$ROOT/infra/aws"
KEY_DIR="$INFRA/.ssh"
KEY="$KEY_DIR/qms-demo"
SSH_USER="ec2-user"

require_cmd terraform curl ssh ssh-keygen

if [[ -z "${DEMO_HOSTNAME:-}" ]]; then
  echo "Set DEMO_HOSTNAME to a hostname in your Cloudflare zone (for example test.example.com)." >&2
  exit 1
fi
DEMO_HOSTNAME="$(normalize_hostname "$DEMO_HOSTNAME")"

if [[ -z "${CF_ZONE_ID:-}" ]]; then
  echo "Set CF_ZONE_ID to the Cloudflare zone ID that owns ${DEMO_HOSTNAME}." >&2
  exit 1
fi

if [[ -z "${CLOUDFLARE_API_TOKEN:-}" ]]; then
  echo "Set CLOUDFLARE_API_TOKEN in the environment (Terraform reads it; it is not a Terraform variable)." >&2
  exit 1
fi

if [[ -z "${AWS_ACCESS_KEY_ID:-}" && ! -f "${HOME}/.aws/credentials" && ! -f "${HOME}/.aws/config" && -z "${AWS_PROFILE:-}" && -z "${AWS_CONTAINER_CREDENTIALS_RELATIVE_URI:-}" ]]; then
  echo "No AWS credentials found. Configure the AWS CLI or export AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY." >&2
  exit 1
fi

if [[ -n "${ALLOWED_CIDR:-}" ]]; then
  ALLOWED_CIDR="$(normalize_cidr "$ALLOWED_CIDR")"
else
  ALLOWED_CIDR="$(normalize_cidr "$(detect_operator_ip)")"
fi

ALLOW_CIDRS=()
if [[ -n "${CF_ALLOW_IPS:-}" ]]; then
  IFS=',' read -ra _cf_allow_raw <<< "$CF_ALLOW_IPS"
  for _raw in "${_cf_allow_raw[@]}"; do
    [[ -z "${_raw// }" ]] && continue
    ALLOW_CIDRS+=("$(normalize_cidr "$_raw")")
  done
  if [[ "${#ALLOW_CIDRS[@]}" -eq 0 ]]; then
    echo "CF_ALLOW_IPS was set but contained no CIDRs." >&2
    exit 1
  fi
else
  ALLOW_CIDRS=("$ALLOWED_CIDR")
fi
ALLOW_CIDRS_TF="$(tf_string_list "${ALLOW_CIDRS[@]}")"

mkdir -p "$KEY_DIR"
chmod 700 "$KEY_DIR"
if [[ ! -f "$KEY" ]]; then
  ssh-keygen -t ed25519 -f "$KEY" -N "" -C "qms-demo-operator" >/dev/null
  chmod 600 "$KEY"
fi

cat > "$INFRA/hostname.auto.tfvars" <<EOF
hostname           = "${DEMO_HOSTNAME}"
cloudflare_zone_id = "${CF_ZONE_ID}"
allow_cidrs        = ${ALLOW_CIDRS_TF}
EOF

export TF_IN_AUTOMATION=1
terraform -chdir="$INFRA" init -input=false
terraform -chdir="$INFRA" apply -input=false -auto-approve \
  -var="allowed_cidr=${ALLOWED_CIDR}" \
  -var="hostname=${DEMO_HOSTNAME}" \
  -var="cloudflare_zone_id=${CF_ZONE_ID}" \
  -var="allow_cidrs=${ALLOW_CIDRS_TF}" \
  -var="ssh_public_key=$(cat "${KEY}.pub")" \
  ${AWS_REGION:+-var="aws_region=${AWS_REGION}"} \
  ${INSTANCE_TYPE:+-var="instance_type=${INSTANCE_TYPE}"}

PUBLIC_IP="$(terraform -chdir="$INFRA" output -raw public_ip)"
DEMO_URL="$(terraform -chdir="$INFRA" output -raw demo_url)"

SSH_OPTS=(
  -i "$KEY"
  -o IdentitiesOnly=yes
  -o StrictHostKeyChecking=accept-new
  -o UserKnownHostsFile="$KEY_DIR/known_hosts"
  -o ConnectTimeout=8
)

echo "Waiting for SSH on ${PUBLIC_IP}..."
ready=0
for _ in $(seq 1 60); do
  if ssh "${SSH_OPTS[@]}" -o BatchMode=yes "$SSH_USER@$PUBLIC_IP" 'true' 2>/dev/null; then
    ready=1
    break
  fi
  sleep 5
done
if [[ "$ready" -ne 1 ]]; then
  echo "Timed out waiting for SSH on ${PUBLIC_IP}." >&2
  exit 1
fi

echo "Waiting for instance bootstrap (Docker + swap)..."
ready=0
for _ in $(seq 1 60); do
  if ssh "${SSH_OPTS[@]}" "$SSH_USER@$PUBLIC_IP" \
    'test -f /opt/qms/.bootstrap-complete || command -v docker >/dev/null'; then
    ready=1
    break
  fi
  sleep 5
done
if [[ "$ready" -ne 1 ]]; then
  echo "Timed out waiting for /opt/qms/.bootstrap-complete. Check /var/log/qms-bootstrap.log on the instance." >&2
  exit 1
fi

echo "Copying the demo onto the instance..."
if command -v rsync >/dev/null 2>&1; then
  rsync -az --delete \
    -e "ssh ${SSH_OPTS[*]}" \
    --exclude '.git/' \
    --exclude 'node_modules/' \
    --exclude 'web/dist/' \
    --exclude 'infra/aws/.terraform/' \
    --exclude 'infra/aws/.ssh/' \
    --exclude 'infra/aws/*.auto.tfvars' \
    --exclude 'infra/aws/terraform.tfstate' \
    --exclude 'infra/aws/terraform.tfstate.backup' \
    --exclude '.env' \
    --exclude '.bootstrap-complete' \
    "$ROOT/" "$SSH_USER@$PUBLIC_IP:/opt/qms/"
else
  ssh "${SSH_OPTS[@]}" "$SSH_USER@$PUBLIC_IP" 'rm -rf /opt/qms/* /opt/qms/.[!.]* 2>/dev/null || true; mkdir -p /opt/qms'
  tar -C "$ROOT" \
    --exclude '.git' \
    --exclude 'node_modules' \
    --exclude 'web/dist' \
    --exclude 'infra/aws/.terraform' \
    --exclude 'infra/aws/.ssh' \
    --exclude 'infra/aws/hostname.auto.tfvars' \
    --exclude 'infra/aws/terraform.tfstate' \
    --exclude 'infra/aws/terraform.tfstate.backup' \
    -cf - . | ssh "${SSH_OPTS[@]}" "$SSH_USER@$PUBLIC_IP" 'tar -C /opt/qms -xf -'
fi

echo "Starting the compose stack (first image build can take several minutes)..."
ssh "${SSH_OPTS[@]}" "$SSH_USER@$PUBLIC_IP" \
  'cd /opt/qms && sudo docker compose -f compose.aws.yml up --build -d'

echo "Waiting for Cloudflare HTTPS on ${DEMO_URL} (first-request cert/proxy warmup can take a minute)..."
ready=0
for _ in $(seq 1 60); do
  if curl -fsS --max-time 8 "$DEMO_URL" >/dev/null 2>&1; then
    ready=1
    break
  fi
  sleep 5
done
if [[ "$ready" -ne 1 ]]; then
  echo "Stack started but ${DEMO_URL} is not answering yet. Try again in a minute." >&2
  echo "SSH: ssh ${SSH_OPTS[*]} ${SSH_USER}@${PUBLIC_IP}"
  exit 1
fi

cat <<EOF

Demo is up.
  URL:               ${DEMO_URL}
  Hostname:          ${DEMO_HOSTNAME}
  Origin Elastic IP: ${PUBLIC_IP}
  SSH CIDR:          ${ALLOWED_CIDR}
  IP Access allow:   ${ALLOW_CIDRS[*]}
  SSH:               ssh -i ${KEY} ${SSH_USER}@${PUBLIC_IP}

Only Cloudflare IP ranges can reach origin :80. Zone IP Access Rules whitelist
allow_cidrs for this website (they do not block everyone else).
Tear down with:
  ./scripts/destroy-aws.sh
EOF
