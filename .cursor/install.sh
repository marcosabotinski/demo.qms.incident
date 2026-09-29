#!/usr/bin/env bash
set -euo pipefail

major="$(node -p "Number(process.versions.node.split('.')[0])")"
if [ "$major" -lt 24 ]; then
  echo "This lab requires Node.js 24 LTS or newer. Found $(node -v)." >&2
  exit 1
fi

npm install
