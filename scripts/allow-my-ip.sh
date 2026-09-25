#!/usr/bin/env bash
# Add this machine's current public IPv4 and IPv6 to the Cloudflare zone IP
# Access Rules allowlist (mode whitelist). Does not run Terraform and does not
# open a port.
#
# The website allowlist is cloudflare_access_rule in infra/aws (zone IP Access
# Rules). The EC2 security group is SSH plus Cloudflare's origin ranges, not
# the visitor allowlist. Rules created here are not in Terraform state, so a
# later apply does not delete them.
#
# Env (export these, or put them in a gitignored .env — same loader as
# deploy-aws.sh; already-exported values win; values are never printed):
#   CLOUDFLARE_API_TOKEN   required. Minimum permission: Account Firewall
#                          Access Rules Edit (write) on the account that owns
#                          the zone. DNS and zone-settings permissions are not
#                          required.
#   CF_ZONE_ID             required. 32-hex zone id that owns the website.
#
# Already-listed addresses are success. If this host has no public address for
# one family, that family is skipped. The command fails only when no address
# could be allowlisted, or a Cloudflare API call failed.
set -euo pipefail

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  cat <<'EOF'
Add this machine's current public IPv4 and IPv6 to the Cloudflare zone allowlist.

  CLOUDFLARE_API_TOKEN=... CF_ZONE_ID=... ./scripts/allow-my-ip.sh

Uses the zone IP Access Rules API (POST /zones/{CF_ZONE_ID}/firewall/access_rules/rules),
not Terraform. A gitignored .env is loaded; already-exported values win.
The token is never printed.

  CLOUDFLARE_API_TOKEN   required. Account Firewall Access Rules Edit (write)
                         on the account that owns the zone. Not a DNS token.
  CF_ZONE_ID             required Cloudflare zone id for the website.

Skips a family when this host has no public address for it. Already-present
rules are left in place. Exits non-zero when nothing was allowlisted or the
API call failed.
EOF
  exit 0
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/aws-deploy.sh
source "$ROOT/scripts/lib/aws-deploy.sh"
# shellcheck source=lib/cf-allow.sh
source "$ROOT/scripts/lib/cf-allow.sh"
load_dotenv "$ROOT"
_cf_allow_main
