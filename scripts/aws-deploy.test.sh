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

assert_eq "$(normalize_hostname '  HTTPS://Demo.Example.COM/path ')" "demo.example.com" "hostname strips scheme, path, case"
assert_fail "rejects a bare IPv4 as hostname" normalize_hostname "203.0.113.10"
assert_fail "rejects empty hostname" normalize_hostname ""

ports="$(compose_aws_host_ports "$ROOT/compose.aws.yml")"
if echo "$ports" | grep -q '"80:80"' && ! echo "$ports" | grep -q '"443:443"'; then
  echo "ok  compose.aws.yml publishes host port 80 only"
else
  echo "FAIL: compose.aws.yml must publish only 80:80" >&2
  echo "  got: ${ports}" >&2
  failed=1
fi

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

if grep -A20 'from_port   = 80' "$ROOT/infra/aws/main.tf" | grep -q 'cloudflare_ip_ranges'; then
  echo "ok  HTTP ingress uses Cloudflare IP ranges"
else
  echo "FAIL: HTTP ingress must use data.cloudflare_ip_ranges" >&2
  failed=1
fi

if awk '/from_port[[:space:]]+= 80/,/^  }/' "$ROOT/infra/aws/main.tf" | grep -q '0.0.0.0/0'; then
  echo "FAIL: HTTP ingress must not be world-open" >&2
  failed=1
else
  echo "ok  HTTP ingress is not world-open"
fi

if grep -q 'from_port   = 443' "$ROOT/infra/aws/main.tf"; then
  echo "FAIL: origin must not have a :443 ingress rule" >&2
  failed=1
else
  echo "ok  no :443 ingress"
fi

if ! grep -A20 'from_port   = 22' "$ROOT/infra/aws/main.tf" | grep -q 'local.allowed_cidr'; then
  echo "FAIL: SSH ingress is not locked to local.allowed_cidr" >&2
  failed=1
else
  echo "ok  SSH ingress uses the operator CIDR"
fi

if grep -q 'cloudflare/cloudflare' "$ROOT/infra/aws/versions.tf"; then
  echo "ok  versions.tf declares the cloudflare provider"
else
  echo "FAIL: expected cloudflare provider in versions.tf" >&2
  failed=1
fi

if grep -q 'resource "cloudflare_dns_record"' "$ROOT/infra/aws/main.tf" && \
   grep -q 'proxied = true' "$ROOT/infra/aws/main.tf"; then
  echo "ok  terraform declares a proxied cloudflare_dns_record"
else
  echo "FAIL: expected proxied cloudflare_dns_record" >&2
  failed=1
fi

if grep -q 'resource "cloudflare_access_rule"' "$ROOT/infra/aws/main.tf" && \
   grep -q 'mode    = "whitelist"' "$ROOT/infra/aws/main.tf"; then
  echo "ok  terraform declares zone IP Access Rules"
else
  echo "FAIL: expected cloudflare_access_rule whitelist" >&2
  failed=1
fi

help_out="$("$ROOT/scripts/deploy-aws.sh" --help)"
if [[ "$help_out" == *"DEMO_HOSTNAME"* && "$help_out" == *"ALLOWED_CIDR"* && "$help_out" == *"t3.small"* ]]; then
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

if grep -q 'default     = "eu-central-1"' "$ROOT/infra/aws/variables.tf"; then
  echo "ok  terraform default aws_region is eu-central-1"
else
  echo "FAIL: expected aws_region default eu-central-1" >&2
  failed=1
fi

if grep -q 'resource "aws_eip" "demo"' "$ROOT/infra/aws/main.tf"; then
  echo "ok  terraform allocates an Elastic IP"
else
  echo "FAIL: expected aws_eip.demo" >&2
  failed=1
fi

if grep -q 'https://\${var.hostname}' "$ROOT/infra/aws/outputs.tf"; then
  echo "ok  demo_url is https://hostname"
else
  echo "FAIL: expected demo_url to use https://hostname" >&2
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
