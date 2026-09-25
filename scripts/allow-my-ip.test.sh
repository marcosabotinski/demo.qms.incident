#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/aws-deploy.sh
source "$ROOT/scripts/lib/aws-deploy.sh"
# shellcheck source=lib/cf-allow.sh
source "$ROOT/scripts/lib/cf-allow.sh"

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

assert_rc() {
  local want="$1" label="$2"
  shift 2
  local rc=0
  "$@" >/dev/null 2>&1 || rc=$?
  if [[ "$rc" -ne "$want" ]]; then
    echo "FAIL: ${label} (rc ${rc}, want ${want})" >&2
    failed=1
  else
    echo "ok  ${label}"
  fi
}

assert_ok() {
  local label="$1"
  shift
  if "$@"; then
    echo "ok  ${label}"
  else
    echo "FAIL: ${label}" >&2
    failed=1
  fi
}

V4="1.1.1.1"
V6="2606:4700:4700::1111"
ZONE="0123456789abcdef0123456789abcdef"
export CF_ZONE_ID="$ZONE"
export CLOUDFLARE_API_TOKEN="test-token-not-a-secret"

assert_eq "$(cf_py classify '  1.1.1.1 ' 4)" "1.1.1.1" "classify trims a public IPv4"
assert_eq "$(cf_py classify '2606:4700:4700:0000:0000:0000:0000:1111' 6)" "$V6" "classify compresses public IPv6"
assert_rc 1 "classify rejects an IPv4 passed as IPv6" cf_py classify "$V4" 6
assert_rc 2 "classify rejects a private IPv4" cf_py classify "192.168.1.1" 4
assert_rc 2 "classify rejects a documentation IPv4" cf_py classify "203.0.113.10" 4
assert_rc 2 "classify rejects multicast" cf_py classify "224.0.0.1" 4
assert_rc 2 "classify rejects IPv4-mapped IPv6" cf_py classify "::ffff:1.1.1.1" 6
assert_rc 2 "classify rejects link-local IPv6" cf_py classify "fe80::1" 6

payload="$(cf_py payload ip6 "$V6" "qms-demo bot allow ${V6}")"
python3 -c 'import json,sys; d=json.loads(sys.argv[1]); assert d["mode"]=="whitelist"; assert d["configuration"]["target"]=="ip6"; assert d["configuration"]["value"]==sys.argv[2]; assert d["notes"]=="qms-demo bot allow "+sys.argv[2]' "$payload" "$V6"
echo "ok  whitelist payload uses ip6 target"

list_hit="$(printf '%s' "{\"success\":true,\"result\":[{\"mode\":\"whitelist\",\"configuration\":{\"target\":\"ip\",\"value\":\"${V4}\"}}]}")"
printf '%s' "$list_hit" | cf_py match ip "$V4"
echo "ok  match finds an existing whitelist rule"
printf '%s' '{"success":true,"result":[]}' | cf_py match ip "$V4" && rc=0 || rc=$?
assert_eq "$rc" "1" "match misses an empty list"
printf '%s' "{\"success\":true,\"result\":[{\"mode\":\"block\",\"configuration\":{\"target\":\"ip\",\"value\":\"${V4}\"}}]}" | cf_py match ip "$V4" && rc=0 || rc=$?
assert_eq "$rc" "4" "match reports a non-whitelist rule"
printf '%s' '{"success":false,"errors":[{"code":9109,"message":"Unauthorized"}]}' | cf_py create_result && rc=0 || rc=$?
assert_eq "$rc" "1" "create_result fails on an API error"
printf '%s' '{"success":false,"errors":[{"code":10009,"message":"firewallaccessrules.api.duplicate_of_existing"}]}' | cf_py create_result && rc=0 || rc=$?
assert_eq "$rc" "3" "create_result treats duplicate as already present"
printf '%s' '{"success":true,"result":{"id":"abc"}}' | cf_py create_result
echo "ok  create_result accepts success"

CF_CURL_LOG="$(mktemp)"
cf_curl_hook() {
  local arg url=""
  for arg in "$@"; do
    if [[ "$arg" == https://* ]]; then
      url="$arg"
    fi
    if [[ "$arg" == *"${CLOUDFLARE_API_TOKEN}"* && "$arg" != "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" ]]; then
      echo "token appeared outside the Authorization header" >&2
      return 1
    fi
  done
  printf '%s\n' "$url" >>"$CF_CURL_LOG"
  printf '%s\n' "$*" >>"$CF_CURL_LOG"
  local prev="" outfile=""
  for arg in "$@"; do
    if [[ "$prev" == "-o" ]]; then
      outfile="$arg"
    fi
    prev="$arg"
  done
  if [[ -n "$outfile" ]]; then
    printf '%s' '{"success":true,"result":[]}' >"$outfile"
  fi
  printf '200'
}
body_file="$(mktemp)"
cf_api_request "$body_file" GET whitelist ip "$V4" -
body="$(cat "$body_file")"
rm -f "$body_file"
assert_eq "$body" '{"success":true,"result":[]}' "GET returns the response body"
if grep -q "https://api.cloudflare.com/client/v4/zones/${ZONE}/firewall/access_rules/rules" "$CF_CURL_LOG" && \
   ! grep -q '/accounts/' "$CF_CURL_LOG" && \
   grep -q 'configuration.target=ip' "$CF_CURL_LOG" && \
   grep -q "configuration.value=${V4}" "$CF_CURL_LOG" && \
   grep -q 'mode=whitelist' "$CF_CURL_LOG"; then
  echo "ok  GET targets the zone access-rules endpoint"
else
  echo "FAIL: zone access-rules request" >&2
  failed=1
fi
unset -f cf_curl_hook
rm -f "$CF_CURL_LOG"

CF_CURL_LOG="$(mktemp)"
cf_curl_hook() {
  printf '%s\n' "$*" >>"$CF_CURL_LOG"
  if [[ "$*" == *"ipv4.icanhazip.com"* ]]; then
    printf '%s\n' "  ${V4}  "
    return 0
  fi
  return 1
}
assert_eq "$(detect_public_ipv4)" "$V4" "detect_public_ipv4 falls through to the next echo service"
if grep -q -- '-4' "$CF_CURL_LOG" && grep -q -- '--max-time 4' "$CF_CURL_LOG"; then
  echo "ok  IPv4 detection forces -4 and a short timeout"
else
  echo "FAIL: IPv4 curl flags" >&2
  failed=1
fi
unset -f cf_curl_hook
rm -f "$CF_CURL_LOG"

CF_CURL_LOG="$(mktemp)"
cf_curl_hook() {
  printf '%s\n' "$*" >>"$CF_CURL_LOG"
  if [[ "$*" == *"api6.ipify.org"* ]]; then
    printf '%s\n' 'fd00::1'
    return 0
  fi
  if [[ "$*" == *"ipv6.icanhazip.com"* ]]; then
    printf '%s\n' '2606:4700:4700:0000:0000:0000:0000:1111'
    return 0
  fi
  return 1
}
assert_eq "$(detect_public_ipv6)" "$V6" "detect_public_ipv6 skips a non-global answer"
if grep -q -- '-6' "$CF_CURL_LOG"; then
  echo "ok  IPv6 detection forces -6"
else
  echo "FAIL: IPv6 curl flags" >&2
  failed=1
fi
unset -f cf_curl_hook
rm -f "$CF_CURL_LOG"

cf_curl_hook() { return 1; }
assert_rc 1 "detect_public_ipv6 fails when no public address is found" detect_public_ipv6
unset -f cf_curl_hook

# Counters live in files: allow_current_public_ips is invoked in a command
# substitution, so assignments inside the mock would not survive.
CF_STATE="$(mktemp -d)"
reset_cf_state() {
  printf '0\n' >"$CF_STATE/gets"
  printf '0\n' >"$CF_STATE/posts"
  : >"$CF_STATE/seen"
}
cf_gets() { tr -d '[:space:]' <"$CF_STATE/gets"; }
cf_posts() { tr -d '[:space:]' <"$CF_STATE/posts"; }
reset_cf_state
cf_api_request() {
  local dest="$1" method="$2"
  if [[ "$method" == "GET" ]]; then
    printf '%s\n' "$(($(cf_gets) + 1))" >"$CF_STATE/gets"
    local value="$5"
    local target="ip"
    [[ "$value" == *:* ]] && target="ip6"
    if grep -Fxq "$value" "$CF_STATE/seen"; then
      printf '{"success":true,"result":[{"mode":"whitelist","configuration":{"target":"%s","value":"%s"}}]}' "$target" "$value" >"$dest"
    else
      printf '%s' '{"success":true,"result":[]}' >"$dest"
    fi
    return 0
  fi
  if [[ "$method" == "POST" ]]; then
    printf '%s\n' "$(($(cf_posts) + 1))" >"$CF_STATE/posts"
    local value
    value="$(python3 -c 'import json,sys; print(json.loads(sys.argv[1])["configuration"]["value"])' "$3")"
    printf '%s\n' "$value" >>"$CF_STATE/seen"
    printf '%s' '{"success":true,"result":{"id":"rule"}}' >"$dest"
    return 0
  fi
  return 1
}

detect_public_ipv4() { printf '%s\n' "$V4"; }
detect_public_ipv6() { printf '%s\n' "$V6"; }

out="$(allow_current_public_ips)"
assert_eq "$(cf_posts)" "2" "first run creates IPv4 and IPv6 rules"
assert_ok "first run succeeds" test -n "$out"
posts_after_first="$(cf_posts)"
out2="$(allow_current_public_ips)"
assert_eq "$(cf_posts)" "$posts_after_first" "second run does not POST existing addresses"
if [[ "$out2" == *"already on the Cloudflare zone allowlist"* && "$out2" == *"$V4"* && "$out2" == *"$V6"* ]]; then
  echo "ok  second run reports both addresses already listed"
else
  echo "FAIL: idempotent output" >&2
  echo "$out2" >&2
  failed=1
fi

detect_public_ipv6() { return 1; }
reset_cf_state
out="$(allow_current_public_ips)"
rc=0
if [[ "$out" == *"skipping IPv6"* && "$out" == *"added"* && "$out" != *"IPv6 ${V6} added"* ]]; then
  echo "ok  missing IPv6 is skipped and IPv4 is added"
else
  echo "FAIL: skip IPv6 output" >&2
  echo "$out" >&2
  failed=1
fi
assert_eq "$(cf_posts)" "1" "skipped IPv6 does not create a rule"

detect_public_ipv4() { return 1; }
detect_public_ipv6() { return 1; }
reset_cf_state
rc=0
out="$(allow_current_public_ips 2>&1)" || rc=$?
assert_eq "$rc" "1" "fails when neither family has a public address"
assert_eq "$(cf_gets)" "0" "no API call when nothing was detected"
if [[ "$out" == *"skipping IPv4"* && "$out" == *"skipping IPv6"* && "$out" == *"No public address could be added"* ]]; then
  echo "ok  both-skipped message"
else
  echo "FAIL: both-skipped message" >&2
  echo "$out" >&2
  failed=1
fi

detect_public_ipv4() { printf '%s\n' "$V4"; }
detect_public_ipv6() { return 1; }
cf_api_request() {
  local dest="$1"
  if [[ "$2" == "GET" ]]; then
    printf '%s' '{"success":true,"result":[]}' >"$dest"
    return 0
  fi
  printf '%s' '{"success":false,"errors":[{"code":9109,"message":"Unauthorized to access requested resource"}]}' >"$dest"
  return 0
}
rc=0
out="$(allow_current_public_ips 2>&1)" || rc=$?
assert_eq "$rc" "1" "fails when the Cloudflare API returns an error"
if [[ "$out" == *"Unauthorized to access requested resource"* && "$out" != *"test-token-not-a-secret"* ]]; then
  echo "ok  API error is reported without the token"
else
  echo "FAIL: API error output" >&2
  echo "$out" >&2
  failed=1
fi

cf_api_request() { return 1; } # transport failure: no body file written
rc=0
allow_current_public_ips >/dev/null 2>&1 || rc=$?
assert_eq "$rc" "1" "fails when the API request cannot be sent"

detect_public_ipv4() { printf '%s\n' "$V4"; }
detect_public_ipv6() { printf '%s\n' "$V6"; }
cf_api_request() {
  local dest="$1"
  if [[ "$2" == "POST" ]]; then
    local value
    value="$(python3 -c 'import json,sys; print(json.loads(sys.argv[1])["configuration"]["value"])' "$3")"
    if [[ "$value" == "$V4" ]]; then
      printf '%s' '{"success":false,"errors":[{"code":9109,"message":"Unauthorized to access requested resource"}]}' >"$dest"
      return 0
    fi
    printf '%s' '{"success":true,"result":{"id":"rule"}}' >"$dest"
    return 0
  fi
  printf '%s' '{"success":true,"result":[]}' >"$dest"
}
rc=0
out="$(allow_current_public_ips 2>&1)" || rc=$?
assert_eq "$rc" "1" "fails when one family succeeds and the other API call fails"
if [[ "$out" == *"IPv6 ${V6} added"* && "$out" == *"Unauthorized"* ]]; then
  echo "ok  the successful family is still reported"
else
  echo "FAIL: partial API failure output" >&2
  echo "$out" >&2
  failed=1
fi

detect_public_ipv6() { return 1; }
cf_api_request() {
  local dest="$1" method="$2"
  if [[ "$method" == "GET" ]]; then
    local mode="$3" target="$4"
    if [[ "$mode" == "-" && "$target" == "ip" ]]; then
      printf '{"success":true,"result":[{"mode":"whitelist","configuration":{"target":"ip","value":"%s"}}]}' "$V4" >"$dest"
      return 0
    fi
    printf '%s' '{"success":true,"result":[]}' >"$dest"
    return 0
  fi
  printf '%s' '{"success":false,"errors":[{"code":10009,"message":"firewallaccessrules.api.duplicate_of_existing"}]}' >"$dest"
}
out="$(allow_current_public_ips)"
if [[ "$out" == *"already on the Cloudflare zone allowlist"* && "$out" == *"skipping IPv6"* ]]; then
  echo "ok  duplicate whitelist rule is success"
else
  echo "FAIL: duplicate whitelist output" >&2
  echo "$out" >&2
  failed=1
fi

cf_api_request() {
  local dest="$1"
  if [[ "$2" == "GET" ]]; then
    local mode="$3" target="$4"
    if [[ "$mode" == "-" && "$target" == "ip" ]]; then
      printf '{"success":true,"result":[{"mode":"block","configuration":{"target":"ip","value":"%s"}}]}' "$V4" >"$dest"
      return 0
    fi
    printf '%s' '{"success":true,"result":[]}' >"$dest"
    return 0
  fi
  printf '%s' '{"success":false,"errors":[{"code":10009,"message":"firewallaccessrules.api.duplicate_of_existing"}]}' >"$dest"
}
rc=0
out="$(allow_current_public_ips 2>&1)" || rc=$?
assert_eq "$rc" "1" "duplicate block rule is not treated as allowlisted"
if [[ "$out" == *"not whitelist"* ]]; then
  echo "ok  block-rule conflict is explained"
else
  echo "FAIL: block-rule message" >&2
  echo "$out" >&2
  failed=1
fi

unset -f detect_public_ipv4 detect_public_ipv6 cf_api_request

rc=0
require_cf_env >/dev/null 2>&1 || rc=$?
# token and zone are set above
assert_eq "$rc" "0" "require_cf_env accepts the test token and zone id"
saved_token="$CLOUDFLARE_API_TOKEN"
CLOUDFLARE_API_TOKEN=""
rc=0
msg="$(require_cf_env 2>&1)" || rc=$?
assert_eq "$rc" "1" "require_cf_env fails when the token is missing"
if [[ "$msg" == *"CLOUDFLARE_API_TOKEN"* && "$msg" != *"Bearer"* ]]; then
  echo "ok  missing-token error names the variable"
else
  echo "FAIL: missing-token error" >&2
  failed=1
fi
CLOUDFLARE_API_TOKEN="$saved_token"
CF_ZONE_ID="not-a-zone"
rc=0
require_cf_env >/dev/null 2>&1 || rc=$?
assert_eq "$rc" "1" "require_cf_env rejects a non-hex zone id"
export CF_ZONE_ID="$ZONE"

help_out="$("$ROOT/scripts/allow-my-ip.sh" --help)"
if [[ "$help_out" == *"CLOUDFLARE_API_TOKEN"* && "$help_out" == *"CF_ZONE_ID"* && "$help_out" == *"Firewall Access Rules"* && "$help_out" != *"terraform apply"* ]]; then
  echo "ok  allow-my-ip.sh --help documents the env vars"
else
  echo "FAIL: help text" >&2
  failed=1
fi

if grep -q 'terraform' "$ROOT/scripts/allow-my-ip.sh" "$ROOT/scripts/lib/cf-allow.sh"; then
  # The script header mentions Terraform only to say it does not run it.
  if grep -E 'terraform[[:space:]]+(apply|destroy|import)' "$ROOT/scripts/allow-my-ip.sh" "$ROOT/scripts/lib/cf-allow.sh"; then
    echo "FAIL: script invokes terraform" >&2
    failed=1
  else
    echo "ok  script does not invoke terraform"
  fi
else
  echo "ok  script does not invoke terraform"
fi

if grep -E 'http\.server|flask|nc -l|listen\(' "$ROOT/scripts/allow-my-ip.sh" "$ROOT/scripts/lib/cf-allow.sh" >/dev/null; then
  echo "FAIL: script exposes an HTTP listener" >&2
  failed=1
else
  echo "ok  script does not listen for registrations"
fi

if grep -q 'scripts/allow-my-ip.sh' "$ROOT/infra/aws/main.tf" && \
   grep -q 'resource "cloudflare_access_rule" "visitor_allow"' "$ROOT/infra/aws/main.tf"; then
  echo "ok  terraform keeps per-CIDR access rules and records the out-of-band script"
else
  echo "FAIL: expected out-of-band access-rule comment" >&2
  failed=1
fi

# Run a copy of the script. Its ROOT is this temp tree, so load_dotenv cannot
# see the repo .env or a home-directory .env. A curl stub is first on PATH so
# this case cannot reach the Cloudflare API even if a credential leaked in.
isolate="$(mktemp -d)"
mkdir -p "$isolate/project/scripts/lib" "$isolate/home" "$isolate/bin"
cp "$ROOT/scripts/allow-my-ip.sh" "$isolate/project/scripts/allow-my-ip.sh"
cp "$ROOT/scripts/lib/aws-deploy.sh" "$isolate/project/scripts/lib/aws-deploy.sh"
cp "$ROOT/scripts/lib/cf-allow.sh" "$isolate/project/scripts/lib/cf-allow.sh"
chmod +x "$isolate/project/scripts/allow-my-ip.sh"
printf '%s\n' 'CLOUDFLARE_API_TOKEN=sentinel-not-a-token' 'CF_ZONE_ID=0123456789abcdef0123456789abcdef' > "$isolate/home/.env"
cat > "$isolate/bin/curl" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >> "${CURL_BLOCK_LOG:?}"
exit 97
EOF
chmod +x "$isolate/bin/curl"
: > "$isolate/curl.log"
if [[ -e "$isolate/project/.env" ]]; then
  echo "FAIL: isolated script root must not contain .env" >&2
  failed=1
else
  echo "ok  isolated script root has no .env"
fi
env -i \
  HOME="$isolate/home" \
  PATH="$isolate/bin:/usr/bin:/bin" \
  CURL_BLOCK_LOG="$isolate/curl.log" \
  "$isolate/project/scripts/allow-my-ip.sh" \
  >"$isolate/out" 2>"$isolate/err" && rc=0 || rc=$?
assert_eq "$rc" "1" "script exits 1 when token and zone are unset"
if grep -q 'CLOUDFLARE_API_TOKEN' "$isolate/err" \
  && ! grep -q 'Bearer' "$isolate/err" \
  && ! grep -q 'sentinel-not-a-token' "$isolate/err" "$isolate/out"; then
  echo "ok  script missing-env error does not print a token"
else
  echo "FAIL: script missing-env error" >&2
  failed=1
fi
if [[ -s "$isolate/curl.log" ]]; then
  echo "FAIL: missing-env test invoked curl" >&2
  failed=1
else
  echo "ok  missing-env test did not call curl"
fi
rm -rf "$isolate"

if grep -q 'load_dotenv "$ROOT"' "$ROOT/scripts/allow-my-ip.sh"; then
  echo "ok  normal runs still load the repo .env"
else
  echo "FAIL: allow-my-ip.sh no longer loads the repo .env" >&2
  failed=1
fi

if [[ "$failed" -ne 0 ]]; then
  echo "allow-my-ip tests failed" >&2
  exit 1
fi

echo "allow-my-ip tests passed"
