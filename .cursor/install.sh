#!/usr/bin/env bash
set -euo pipefail

# PostgreSQL is baked into the environment snapshot. Guard-install it so the
# script also works from a plain base image without the snapshot.
if ! command -v pg_ctlcluster >/dev/null 2>&1; then
  sudo apt-get update -y
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y postgresql postgresql-contrib
fi

# Refresh Node dependencies for both apps (no lockfiles are committed).
( cd api && npm install )
( cd web && npm install )
