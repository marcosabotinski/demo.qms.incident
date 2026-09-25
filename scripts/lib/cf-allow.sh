# Cloudflare zone IP Access Rules helpers for allow-my-ip.sh.
# shellcheck shell=bash

# Zone endpoint, not the account endpoint: an account rule would apply to every
# zone in the account. The API host is fixed so an env var cannot redirect the
# bearer token.

cf_py() {
  # Script on fd 3 so a piped JSON body can stay on stdin.
  python3 /dev/fd/3 "$@" 3<<'PY'
import ipaddress
import json
import sys

cmd = sys.argv[1]


def classify(raw, family):
    raw = raw.strip()
    try:
        ip = ipaddress.ip_address(raw)
    except ValueError:
        return 1
    if family not in (0, ip.version):
        return 1
    if isinstance(ip, ipaddress.IPv6Address) and ip.ipv4_mapped:
        return 2
    if (
        ip.is_multicast
        or ip.is_reserved
        or ip.is_loopback
        or ip.is_link_local
        or ip.is_unspecified
        or not ip.is_global
    ):
        return 2
    print(ip)
    return 0


def same_ip(left, right):
    if left is None or right is None:
        return False
    if str(left) == str(right):
        return True
    try:
        return ipaddress.ip_address(str(left)) == ipaddress.ip_address(str(right))
    except ValueError:
        return False


def load_doc():
    try:
        doc = json.load(sys.stdin)
    except json.JSONDecodeError:
        return None
    if not isinstance(doc, dict):
        return None
    return doc


def rules_of(doc):
    result = doc.get("result")
    if isinstance(result, dict):
        return [result]
    if isinstance(result, list):
        return [rule for rule in result if isinstance(rule, dict)]
    return []


if cmd == "classify":
    sys.exit(classify(sys.argv[2], int(sys.argv[3])))

if cmd == "payload":
    json.dump(
        {
            "mode": "whitelist",
            "notes": sys.argv[4],
            "configuration": {"target": sys.argv[2], "value": sys.argv[3]},
        },
        sys.stdout,
    )
    sys.exit(0)

if cmd == "match":
    target, value = sys.argv[2], sys.argv[3]
    doc = load_doc()
    if doc is None or not doc.get("success"):
        sys.exit(2)
    other = False
    for rule in rules_of(doc):
        cfg = rule.get("configuration") or {}
        if cfg.get("target") != target or not same_ip(cfg.get("value"), value):
            continue
        if rule.get("mode") == "whitelist":
            sys.exit(0)
        other = True
    sys.exit(4 if other else 1)

if cmd == "create_result":
    doc = load_doc()
    if doc is None:
        sys.exit(1)
    if doc.get("success"):
        sys.exit(0)
    for err in doc.get("errors") or []:
        if not isinstance(err, dict):
            continue
        msg = str(err.get("message") or "").lower()
        if err.get("code") == 10009 or "duplicate" in msg or "already" in msg:
            sys.exit(3)
    sys.exit(1)

if cmd == "errors":
    doc = load_doc()
    if doc is None:
        sys.exit(1)
    for err in doc.get("errors") or []:
        if isinstance(err, dict) and err.get("message"):
            print(err["message"])
    sys.exit(0)

sys.exit(1)
PY
}

_cf_curl() {
  if declare -F cf_curl_hook >/dev/null 2>&1; then
    cf_curl_hook "$@"
    return
  fi
  command curl "$@"
}

# Echo-service failures mean this host has no usable public address for that
# family (no route, or the service returned something that is not global).
_detect_public_ip() {
  local family="$1"
  shift
  local flag="-4"
  [[ "$family" == "6" ]] && flag="-6"
  local url ip norm
  for url in "$@"; do
    if ip="$(_cf_curl -fsS "$flag" --connect-timeout 2 --max-time 4 "$url" 2>/dev/null)"; then
      if norm="$(cf_py classify "$ip" "$family")"; then
        printf '%s\n' "$norm"
        return 0
      fi
    fi
  done
  return 1
}

detect_public_ipv4() {
  _detect_public_ip 4 \
    "https://checkip.amazonaws.com/" \
    "https://api.ipify.org" \
    "https://ipv4.icanhazip.com"
}

detect_public_ipv6() {
  _detect_public_ip 6 \
    "https://api6.ipify.org" \
    "https://ipv6.icanhazip.com"
}

require_cf_env() {
  if [[ -z "${CLOUDFLARE_API_TOKEN:-}" ]]; then
    echo "Set CLOUDFLARE_API_TOKEN (Account Firewall Access Rules Edit on the zone's account). The token is not printed." >&2
    return 1
  fi
  if [[ -z "${CF_ZONE_ID:-}" ]]; then
    echo "Set CF_ZONE_ID to the Cloudflare zone id that owns the website." >&2
    return 1
  fi
  CF_ZONE_ID="$(printf '%s' "$CF_ZONE_ID" | tr -d '[:space:]')"
  if [[ ! "$CF_ZONE_ID" =~ ^[0-9a-fA-F]{32}$ ]]; then
    echo "CF_ZONE_ID must be a 32-character hex Cloudflare zone id." >&2
    return 1
  fi
  export CF_ZONE_ID
}

# Writes the response body to $1. Runs in the current shell so CF_HTTP_STATUS
# survives; command substitution would drop it.
cf_api_request() {
  local dest="$1" method="$2"
  shift 2
  if [[ -z "${CLOUDFLARE_API_TOKEN:-}" ]]; then
    echo "CLOUDFLARE_API_TOKEN is not set." >&2
    return 1
  fi
  if [[ ! "${CF_ZONE_ID:-}" =~ ^[0-9a-fA-F]{32}$ ]]; then
    echo "CF_ZONE_ID is not set to a 32-character hex zone id." >&2
    return 1
  fi

  local tmp http
  tmp="$(mktemp)"
  local url="https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/firewall/access_rules/rules"

  if [[ "$method" == "GET" ]]; then
    local mode="$1" target="$2" value="$3" notes="$4"
    local -a args=(
      -sS
      --proto '=https'
      --tlsv1.2
      --max-redirs 0
      --connect-timeout 5
      --max-time 15
      -G
      -o "$tmp"
      -w '%{http_code}'
      -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}"
      --data-urlencode "per_page=100"
      --data-urlencode "match=all"
    )
    [[ "$mode" != "-" ]] && args+=(--data-urlencode "mode=${mode}")
    if [[ "$target" != "-" ]]; then
      args+=(--data-urlencode "configuration.target=${target}")
      args+=(--data-urlencode "configuration.value=${value}")
    fi
    [[ "$notes" != "-" ]] && args+=(--data-urlencode "notes=${notes}")
    if ! http="$(_cf_curl "${args[@]}" "$url")"; then
      rm -f "$tmp"
      return 1
    fi
  elif [[ "$method" == "POST" ]]; then
    local json="$1"
    if ! http="$(
      _cf_curl -sS \
        --proto '=https' \
        --tlsv1.2 \
        --max-redirs 0 \
        --connect-timeout 5 \
        --max-time 15 \
        -o "$tmp" \
        -w '%{http_code}' \
        -X POST \
        -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
        -H "Content-Type: application/json" \
        --data "$json" \
        "$url"
    )"; then
      rm -f "$tmp"
      return 1
    fi
  else
    rm -f "$tmp"
    echo "Unsupported Cloudflare API method." >&2
    return 1
  fi

  CF_HTTP_STATUS="$http"
  cat "$tmp" >"$dest"
  rm -f "$tmp"
}

cf_print_errors() {
  local body="$1"
  local msgs
  msgs="$(printf '%s' "$body" | cf_py errors || true)"
  if [[ -n "$msgs" ]]; then
    printf '%s\n' "$msgs" >&2
  elif [[ -n "${CF_HTTP_STATUS:-}" ]]; then
    echo "Cloudflare API HTTP ${CF_HTTP_STATUS}." >&2
  fi
}

# Prints the response body into LOOKUP_BODY.
# Returns 0 whitelist match, 1 absent, 2 bad API response, 4 other mode, 10 transport.
_lookup_match() {
  local filter_mode="$1" filter_target="$2" match_target="$3" value="$4" notes="$5"
  local body_file rc=0
  body_file="$(mktemp)"
  if ! cf_api_request "$body_file" GET "$filter_mode" "$filter_target" "$value" "$notes"; then
    LOOKUP_BODY=""
    rm -f "$body_file"
    return 10
  fi
  LOOKUP_BODY="$(cat "$body_file")"
  rm -f "$body_file"
  printf '%s' "$LOOKUP_BODY" | cf_py match "$match_target" "$value" || rc=$?
  return "$rc"
}

_family_label() {
  if [[ "$1" == "ip6" ]]; then
    printf 'IPv6\n'
  else
    printf 'IPv4\n'
  fi
}

ensure_zone_whitelist() {
  local raw="$1"
  local norm target label notes payload body rc=0
  if ! norm="$(cf_py classify "$raw" 0)"; then
    echo "Refusing to allowlist ${raw}: not a public IP." >&2
    return 1
  fi
  if [[ "$norm" == *:* ]]; then
    target="ip6"
  else
    target="ip"
  fi
  label="$(_family_label "$target")"
  notes="qms-demo bot allow ${norm}"

  _lookup_match whitelist "$target" "$target" "$norm" - || rc=$?
  case "$rc" in
    0)
      echo "${label} ${norm} already on the Cloudflare zone allowlist."
      return 0
      ;;
    1)
      ;;
    4)
      echo "A Cloudflare access rule for ${norm} exists but is not whitelist. Not changing it." >&2
      return 1
      ;;
    10)
      echo "Cloudflare API request failed while looking up ${norm}." >&2
      return 1
      ;;
    *)
      # configuration.target=ip6 is not a documented list filter. Notes search is.
      rc=0
      _lookup_match whitelist - "$target" "$norm" "$norm" || rc=$?
      case "$rc" in
        0)
          echo "${label} ${norm} already on the Cloudflare zone allowlist."
          return 0
          ;;
        1)
          ;;
        *)
          cf_print_errors "$LOOKUP_BODY"
          echo "Cloudflare API rejected the lookup for ${norm}." >&2
          return 1
          ;;
      esac
      ;;
  esac

  payload="$(cf_py payload "$target" "$norm" "$notes")"
  local body_file
  body_file="$(mktemp)"
  if ! cf_api_request "$body_file" POST "$payload"; then
    rm -f "$body_file"
    echo "Cloudflare API request failed while adding ${norm}." >&2
    return 1
  fi
  body="$(cat "$body_file")"
  rm -f "$body_file"
  rc=0
  printf '%s' "$body" | cf_py create_result || rc=$?
  if [[ "$rc" -eq 0 ]]; then
    echo "${label} ${norm} added to the Cloudflare zone allowlist."
    return 0
  fi
  if [[ "$rc" -eq 3 ]]; then
    rc=0
    _lookup_match - "$target" "$target" "$norm" - || rc=$?
    if [[ "$rc" -ne 0 && "$rc" -ne 4 ]]; then
      _lookup_match - - "$target" "$norm" "$norm" || rc=$?
    fi
    if [[ "$rc" -eq 0 ]]; then
      echo "${label} ${norm} already on the Cloudflare zone allowlist."
      return 0
    fi
    if [[ "$rc" -eq 4 ]]; then
      echo "A Cloudflare access rule for ${norm} exists but is not whitelist. Not changing it." >&2
      return 1
    fi
    echo "Cloudflare reported a duplicate rule for ${norm}, but the allowlist entry was not confirmed." >&2
    return 1
  fi
  cf_print_errors "$body"
  echo "Cloudflare API failed while adding ${norm}." >&2
  return 1
}

allow_current_public_ips() {
  local tmp4 tmp6 p4 p6 v4 v6 added=0 failed=0
  tmp4="$(mktemp)"
  tmp6="$(mktemp)"
  detect_public_ipv4 >"$tmp4" &
  p4=$!
  detect_public_ipv6 >"$tmp6" &
  p6=$!
  wait "$p4" || true
  wait "$p6" || true
  v4="$(tr -d '[:space:]' <"$tmp4")"
  v6="$(tr -d '[:space:]' <"$tmp6")"
  rm -f "$tmp4" "$tmp6"

  if [[ -z "$v4" ]]; then
    echo "No public IPv4 detected on this host; skipping IPv4."
  elif ensure_zone_whitelist "$v4"; then
    added=1
  else
    failed=1
  fi

  if [[ -z "$v6" ]]; then
    echo "No public IPv6 detected on this host; skipping IPv6."
  elif ensure_zone_whitelist "$v6"; then
    added=1
  else
    failed=1
  fi

  if [[ "$failed" -ne 0 ]]; then
    return 1
  fi
  if [[ "$added" -eq 0 ]]; then
    echo "No public address could be added to the Cloudflare allowlist." >&2
    return 1
  fi
}

_cf_allow_main() {
  require_cf_env
  require_cmd curl python3
  allow_current_public_ips
}
