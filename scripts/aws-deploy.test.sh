#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/aws-deploy.sh
source "$ROOT/scripts/lib/aws-deploy.sh"

failed=0
assert_eq() {
  local got="$1" want="$2" label="$3"
  if [[ "$got" != "$want" ]]; then
    echo "FAIL: ${label}" >&2
    echo "  got:  ${got}" >&2
    echo "  want: ${want}" >&2
    failed=1
  else
    echo "ok  ${label}"
  fi
}

assert_fail() {
  local label="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    echo "FAIL: expected error: ${label}" >&2
    failed=1
  else
    echo "ok  ${label}"
  fi
}

assert_eq "$(normalize_cidr '  203.0.113.10 ')" "203.0.113.10/32" "bare IPv4 becomes /32"
assert_eq "$(normalize_cidr '203.0.113.10/32')" "203.0.113.10/32" "existing /32 is kept"
assert_eq "$(normalize_cidr $'198.51.100.4\n')" "198.51.100.4/32" "trailing newline is stripped"
assert_fail "rejects non-IP input" normalize_cidr "not-an-ip"
assert_fail "rejects empty input" normalize_cidr ""

ports="$(compose_aws_host_ports "$ROOT/compose.aws.yml")"
assert_eq "$ports" '"80:80"' "compose.aws.yml publishes only host port 80"

if grep -E '["'\''](5432|4000):' "$ROOT/compose.aws.yml" >/dev/null; then
  echo "FAIL: compose.aws.yml must not publish Postgres or the API" >&2
  failed=1
else
  echo "ok  compose.aws.yml does not publish 5432 or 4000"
fi

if ! grep -q 'aws_security_group" "nsg"' "$ROOT/infra/aws/main.tf"; then
  echo "FAIL: expected aws_security_group.nsg" >&2
  failed=1
else
  echo "ok  terraform defines the NSG security group"
fi

if ! grep -A20 'from_port   = 80' "$ROOT/infra/aws/main.tf" | grep -q 'local.allowed_cidr'; then
  echo "FAIL: HTTP ingress is not locked to local.allowed_cidr" >&2
  failed=1
else
  echo "ok  HTTP ingress uses the operator CIDR"
fi

if ! grep -A20 'from_port   = 22' "$ROOT/infra/aws/main.tf" | grep -q 'local.allowed_cidr'; then
  echo "FAIL: SSH ingress is not locked to local.allowed_cidr" >&2
  failed=1
else
  echo "ok  SSH ingress uses the operator CIDR"
fi

help_out="$("$ROOT/scripts/deploy-aws.sh" --help)"
if [[ "$help_out" == *"ALLOWED_CIDR"* && "$help_out" == *"t3.small"* ]]; then
  echo "ok  deploy-aws.sh --help"
else
  echo "FAIL: deploy-aws.sh --help output" >&2
  failed=1
fi

if grep -q 'default     = "t3.small"' "$ROOT/infra/aws/variables.tf"; then
  echo "ok  terraform default instance_type is t3.small"
else
  echo "FAIL: expected instance_type default t3.small" >&2
  failed=1
fi

if command -v terraform >/dev/null 2>&1; then
  if terraform -chdir="$ROOT/infra/aws" fmt -check >/dev/null && \
     terraform -chdir="$ROOT/infra/aws" init -backend=false -input=false >/dev/null && \
     terraform -chdir="$ROOT/infra/aws" validate >/dev/null; then
    echo "ok  terraform fmt + validate"
  else
    echo "FAIL: terraform fmt/validate" >&2
    failed=1
  fi
fi

if [[ "$failed" -ne 0 ]]; then
  echo "aws-deploy tests failed" >&2
  exit 1
fi

echo "aws-deploy tests passed"
