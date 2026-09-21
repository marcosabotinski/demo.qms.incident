#!/usr/bin/env bash
# Provision a free-tier EC2 VM, lock HTTP/SSH to this machine's public IP,
# copy the demo onto the instance, and start the full compose stack on port 80.
set -euo pipefail

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  cat <<'EOF'
Deploy the QMS demo to a free-tier EC2 VM.

  ./scripts/deploy-aws.sh

Needs Terraform and AWS credentials. Optional env:
  ALLOWED_CIDR    CIDR allowed to hit :80 and :22 (default: this machine's public IP)
  AWS_REGION      default us-east-1
  INSTANCE_TYPE   default t3.micro
EOF
  exit 0
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/aws-deploy.sh
source "$ROOT/scripts/lib/aws-deploy.sh"

INFRA="$ROOT/infra/aws"
KEY_DIR="$INFRA/.ssh"
KEY="$KEY_DIR/qms-demo"
SSH_USER="ec2-user"

require_cmd terraform curl ssh ssh-keygen

if [[ -z "${AWS_ACCESS_KEY_ID:-}" && ! -f "${HOME}/.aws/credentials" && ! -f "${HOME}/.aws/config" && -z "${AWS_PROFILE:-}" && -z "${AWS_CONTAINER_CREDENTIALS_RELATIVE_URI:-}" ]]; then
  echo "No AWS credentials found. Configure the AWS CLI or export AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY." >&2
  exit 1
fi

if [[ -n "${ALLOWED_CIDR:-}" ]]; then
  ALLOWED_CIDR="$(normalize_cidr "$ALLOWED_CIDR")"
else
  ALLOWED_CIDR="$(normalize_cidr "$(detect_operator_ip)")"
fi

mkdir -p "$KEY_DIR"
chmod 700 "$KEY_DIR"
if [[ ! -f "$KEY" ]]; then
  ssh-keygen -t ed25519 -f "$KEY" -N "" -C "qms-demo-operator" >/dev/null
  chmod 600 "$KEY"
fi

export TF_IN_AUTOMATION=1
terraform -chdir="$INFRA" init -input=false
terraform -chdir="$INFRA" apply -input=false -auto-approve \
  -var="allowed_cidr=${ALLOWED_CIDR}" \
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
  if ssh "${SSH_OPTS[@]}" "$SSH_USER@$PUBLIC_IP" 'test -f /opt/qms/.bootstrap-complete' 2>/dev/null; then
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
    --exclude 'infra/aws/terraform.tfstate' \
    --exclude 'infra/aws/terraform.tfstate.backup' \
    "$ROOT/" "$SSH_USER@$PUBLIC_IP:/opt/qms/"
else
  ssh "${SSH_OPTS[@]}" "$SSH_USER@$PUBLIC_IP" 'rm -rf /opt/qms/* /opt/qms/.[!.]* 2>/dev/null || true; mkdir -p /opt/qms'
  tar -C "$ROOT" \
    --exclude '.git' \
    --exclude 'node_modules' \
    --exclude 'web/dist' \
    --exclude 'infra/aws/.terraform' \
    --exclude 'infra/aws/.ssh' \
    --exclude 'infra/aws/terraform.tfstate' \
    --exclude 'infra/aws/terraform.tfstate.backup' \
    -cf - . | ssh "${SSH_OPTS[@]}" "$SSH_USER@$PUBLIC_IP" 'tar -C /opt/qms -xf -'
fi

echo "Starting the compose stack (first build on t3.micro can take several minutes)..."
ssh "${SSH_OPTS[@]}" "$SSH_USER@$PUBLIC_IP" \
  'cd /opt/qms && sudo docker compose -f compose.aws.yml up --build -d'

echo "Waiting for the frontend on ${DEMO_URL} ..."
ready=0
for _ in $(seq 1 60); do
  if curl -fsS --max-time 5 "$DEMO_URL" >/dev/null 2>&1; then
    ready=1
    break
  fi
  sleep 5
done
if [[ "$ready" -ne 1 ]]; then
  echo "Stack started but HTTP is not answering yet. Try ${DEMO_URL} in a minute." >&2
  echo "SSH: ssh ${SSH_OPTS[*]} ${SSH_USER}@${PUBLIC_IP}"
  exit 1
fi

cat <<EOF

Demo is up.
  URL:          ${DEMO_URL}
  Allowed CIDR: ${ALLOWED_CIDR}
  SSH:          ssh -i ${KEY} ${SSH_USER}@${PUBLIC_IP}

Only this public IP can reach port 80. Tear down with:
  ./scripts/destroy-aws.sh
EOF
