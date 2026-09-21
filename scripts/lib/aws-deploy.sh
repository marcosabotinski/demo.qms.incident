# Shared helpers for deploy-aws.sh / destroy-aws.sh / tests.
# shellcheck shell=bash

normalize_cidr() {
  local raw="${1-}"
  raw="$(printf '%s' "$raw" | tr -d '[:space:]')"
  if [[ "$raw" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    printf '%s/32\n' "$raw"
    return 0
  fi
  if [[ "$raw" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+$ ]]; then
    printf '%s\n' "$raw"
    return 0
  fi
  echo "Expected an IPv4 address or CIDR, got: ${1-}" >&2
  return 1
}

detect_operator_ip() {
  local ip=""
  local url
  for url in \
    "https://checkip.amazonaws.com/" \
    "https://api.ipify.org" \
    "https://ifconfig.me/ip"; do
    if ip="$(curl -fsS --max-time 8 "$url" 2>/dev/null)"; then
      ip="$(printf '%s' "$ip" | tr -d '[:space:]')"
      if [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        printf '%s\n' "$ip"
        return 0
      fi
    fi
  done
  echo "Could not detect the public IPv4 of this machine." >&2
  return 1
}

require_cmd() {
  local cmd
  for cmd in "$@"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      echo "Missing required command: $cmd" >&2
      return 1
    fi
  done
}

compose_aws_host_ports() {
  # Published host ports in compose.aws.yml. Used by tests to keep the
  # frontend-only exposure invariant from drifting.
  awk '
    $1 == "ports:" { in_ports = 1; next }
    in_ports && $1 ~ /^-/ {
      print $2
      next
    }
    in_ports && $0 !~ /^[[:space:]]/ { in_ports = 0 }
  ' "$1"
}
