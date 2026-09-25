#!/usr/bin/env bash
set -euo pipefail

npm run seed
echo "SQLite ready at api/data/qms.sqlite"
