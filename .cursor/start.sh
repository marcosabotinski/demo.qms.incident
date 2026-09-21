#!/usr/bin/env bash
set -euo pipefail

# Bring the PostgreSQL cluster up if it is not already accepting connections.
if ! pg_isready -h localhost -p 5432 >/dev/null 2>&1; then
  sudo pg_ctlcluster 16 main start
fi

# Wait until the server is ready before creating roles / databases.
for _ in $(seq 1 30); do
  if pg_isready -h localhost -p 5432 >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

# Ensure the application role and database exist (idempotent).
sudo -u postgres psql -v ON_ERROR_STOP=1 -c \
  "DO \$\$ BEGIN IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname='qms') THEN CREATE ROLE qms LOGIN PASSWORD 'qms'; END IF; END \$\$;"
sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname='qms'" | grep -q 1 \
  || sudo -u postgres createdb -O qms qms

# The API creates its tables and seeds demo records on first start; nothing else
# to do here. Return so the agent's terminals can launch the API and web dev server.
echo "PostgreSQL ready at postgres://qms:qms@localhost:5432/qms"
