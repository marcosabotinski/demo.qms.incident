# `documentation.md` section contract

The Skill must read and write **one** Markdown file (default path: `/documentation.md` at repo root). Headings below are the contract. Do not add a second top-level outline.

Use `##` for these sections, in this order.

## Maintained sections (regenerate from the repo)

The Skill **replaces** the body of these sections on every run. A previous paragraph that contradicts the code loses.

| Section | Source of truth | Must include |
|---|---|---|
| `## Purpose` | `README.md`, `LAB.md` (titles only) | Acme Quality mock eQMS; working path is create → list → open a quality incident |
| `## Run locally` | `README.md` | `npm install`, `npm run seed`, `npm run dev`; URL; SQLite path; `--reset` |
| `## System map` | `web/src/App.jsx`, `api/src/index.js`, `api/src/db.js` | Ports, proxy, tables, route list |
| `## HTTP API` | `createApp()` | Method, path, request/response notes; say “unpaged” until pagination exists |
| `## Data model` | `schema.js`, `initSchema()`, spec field groups | Columns vs. `data` JSON; `CREATE_REQUIRED`; attachment blobs |
| `## UI surfaces` | `web/src/pages/*` | Routes, what each page fetches, client-side inbox filter |
| `## Incident lifecycle` | `ENUMS.status`, spec § workflow | States; **implemented vs. intended** transitions |
| `## Seeded records` | `README.md` / `seed.js` | The four demo IDs and why each exists |
| `## Tests` | `api/src/*.test.js` | What `http.test.js` and `db.test.js` cover |

Rules for maintained sections:

- Prefer file paths and current behavior over the spec when they disagree
- No Bayer or customer names
- No secrets, tokens, or local absolute home paths
- If a feature is missing (pagination, comments, status PATCH), say **Not implemented** — do not write the future API as fact

## One-off sections (create once, then preserve)

The Skill **must not clobber** these if they already have attendee content. If missing, insert the heading plus a one-line stub.

| Section | Intent |
|---|---|
| `## Workshop decisions` | What this cohort chose (e.g. pagination envelope, Dashboard uses `total`) |
| `## Known gaps` | Facilitator/attendee list: chrome QA buttons, no comment thread, etc. |
| `## Demo script scraps` | Slack copy, talking points for `INC-2026-0142` — narrative, not code |
| `## Changelog (session)` | Dated bullets from this workshop only |

Preserve means: parse existing `documentation.md`, copy the one-off bodies through, and write maintained sections fresh.

## Front matter (optional)

If the Skill adds YAML front matter, limit it to:

```yaml
---
title: Acme Quality — Quality Incident Hub
maintained: true
---
```

Do not store Cursor rule text here.

## Anti-patterns

- Pasting all of `qms-incident-demo-spec.md` into the file
- A “TODO: the agent should fill this in” maintained section
- A different heading set each run (`# API` vs `## HTTP API`)
- Copying `.cursor/install.sh` or environment JSON into the doc
