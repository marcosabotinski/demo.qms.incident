# demo.qms.incident

Mock eQMS for a lab quality-incident demo. The working path is **create a quality incident**; the rest of the record is shown so the UI looks like a real system.

## Run with Podman

```bash
podman machine start   # if the local machine is stopped
podman compose up --build
```

Open [http://localhost:8080](http://localhost:8080).

- Dashboard is the start page
- **Incidents** is the inbox
- **Create incident** persists a `Draft` record in Postgres

## Local development (without containers)

Postgres must be reachable at `postgres://qms:qms@localhost:5432/qms`.

```bash
# terminal 1
cd api && npm install && DATABASE_URL=postgres://qms:qms@localhost:5432/qms npm start

# terminal 2
cd web && npm install && npm run dev
```

Vite proxies `/api` and `/demo` to the API on port 4000.

## Seeded records

| ID | Status | Notes |
|---|---|---|
| `INC-2026-0142` | Draft | Slack bot temperature excursion |
| `DEV-2026-0088` | Closed | Older deviation so the inbox is not empty |
| `INC-2026-0138` | Under QA Review | Balance drift |
| `INC-2026-0131` | Investigation | Sample receipt mismatch |
