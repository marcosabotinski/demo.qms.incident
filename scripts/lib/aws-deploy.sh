# Shared helpers for deploy-aws.sh / destroy-aws.sh / tests.
# shellcheck shell=bash

# Load ${root}/.env if present. Shell-exported values win; empty/unset keys
# are filled from the file. Never prints values.
load_dotenv() {
  local root="${1-}"
  local env_file="${root}/.env"
  [[ -n "$root" && -f "$env_file" ]] || return 0

  local line key value
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%$'\r'}"
    [[ "$line" =~ ^[[:space:]]*(#|$) ]] && continue

    line="${line#"${line%%[![:space:]]*}"}"
    if [[ "$line" =~ ^export[[:space:]]+ ]]; then
      line="${line#export}"
      line="${line#"${line%%[![:space:]]*}"}"
    fi

    [[ "$line" == *=* ]] || continue
    key="${line%%=*}"
    value="${line#*=}"
    key="${key%"${key##*[![:space:]]}"}"
    [[ "$key" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || continue

    # Already-exported (non-empty) env wins over .env.
    [[ -n "${!key:-}" ]] && continue

    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    case "$value" in
      '"'?*'"')
        value="${value#\"}"
        value="${value%\"}"
        ;;
      "'"?*"'")
        value="${value#\'}"
        value="${value%\'}"
        ;;
    esac

    printf -v "$key" '%s' "$value"
    export "$key"
  done < "$env_file"
}

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

normalize_hostname() {
  local raw="${1-}"
  raw="$(printf '%s' "$raw" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')"
  raw="${raw#http://}"
  raw="${raw#https://}"
  raw="${raw%%/*}"
  if [[ ! "$raw" =~ ^[a-z0-9]([a-z0-9.-]*[a-z0-9])?\.[a-z]{2,}$ ]]; then
    echo "Expected a DNS hostname (for example demo.example.com), got: ${1-}" >&2
    return 1
  fi
  printf '%s\n' "$raw"
}

tf_string_list() {
  local first=1 item out="["
  for item in "$@"; do
    [[ "$first" -eq 1 ]] || out+=","
    first=0
    out+="\"${item}\""
  done
  out+="]"
  printf '%s\n' "$out"
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
