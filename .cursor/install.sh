#!/usr/bin/env bash
set -euo pipefail

# The cloud image installs Node.js 24 in /usr/local/bin. An older runtime Node
# can sit earlier on PATH, so use the image binary when it is new enough.
if [ -x /usr/local/bin/node ]; then
  image_major="$(/usr/local/bin/node -p "Number(process.versions.node.split('.')[0])")"
  if [ "$image_major" -ge 24 ]; then
    export PATH="/usr/local/bin:${PATH}"
  fi
fi

major="$(node -p "Number(process.versions.node.split('.')[0])")"
if [ "$major" -lt 24 ]; then
  echo "This lab requires Node.js 24 LTS or newer. Found $(node -v)." >&2
  exit 1
fi

npm install
