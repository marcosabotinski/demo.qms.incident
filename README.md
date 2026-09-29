# demo.qms.incident

Mock eQMS for a lab quality-incident workshop. The working path is **create a quality incident**, then list and open the record. The rest of the UI is chrome so it looks like a real system.

Acme Quality branding. No Docker required.

## Requirements

Node.js 24 LTS. The API uses `better-sqlite3` 13, which ships prebuilt binaries for Node.js 24 and the current Node.js release, so `npm install` does not need a C++ toolchain.

## Run (default — no Docker)

```bash
npm install
npm run seed
npm run dev
```

Open [http://localhost:5173](http://localhost:5173).

- Home is a thin quality-incident list plus **New incident**
- **Incidents** is the inbox
- **Create incident** persists a `Draft` record in a local SQLite file

SQLite path: `api/data/qms.sqlite` (override with `SQLITE_PATH`). Vite proxies `/api` and `/demo` to the API on port 4000.

Re-seed without wiping extra records:

```bash
npm run seed
```

Wipe the file DB and restore only the demo records:

```bash
npm run seed -- --reset
```

## Optional / legacy: Compose

Podman or Docker Compose is optional. Prefer the npm path above.

```bash
podman compose up --build
```

Compose no longer starts Postgres. The API uses a SQLite volume.

## Workshop

Exercise titles are in `LAB.md`. `.cursor/rules` is empty on purpose.

## Seeded records

| ID | Status | Notes |
|---|---|---|
| `INC-2026-0142` | Draft | Slack bot temperature excursion |
| `DEV-2026-0088` | Closed | Older deviation so the inbox is not empty |
| `INC-2026-0138` | Under QA Review | Balance drift |
| `INC-2026-0131` | Investigation | Sample receipt mismatch |
