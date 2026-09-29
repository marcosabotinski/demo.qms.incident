#!/usr/bin/env bash
set -euo pipefail

# Match install.sh: prefer the image Node.js 24 over an older runtime Node.
if [ -x /usr/local/bin/node ]; then
  image_major="$(/usr/local/bin/node -p "Number(process.versions.node.split('.')[0])")"
  if [ "$image_major" -ge 24 ]; then
    export PATH="/usr/local/bin:${PATH}"
  fi
fi

npm run seed
echo "SQLite ready at api/data/qms.sqlite"
