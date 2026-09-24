# Facilitator notes — what a good understanding walkthrough covers

A strong Ask session ends with the same four maps. If someone only recites the spec, they have not understood the repo.

## 1. API

Cover `createApp()` in `api/src/index.js`, not just the spec.

| Method | Path | Today |
|---|---|---|
| `GET` | `/api/health` | SQLite ping + path |
| `GET` | `/api/meta` | `ENUMS` + current user Maria Alvarez |
| `GET` | `/api/incidents` | **All** rows, `ORDER BY created_at DESC`, `listProjection` |
| `GET` | `/api/incidents/:id` | Full JSON record (404 if missing) |
| `POST` | `/api/incidents` | Creates `Draft`; required: `title`, `priority`, `description` |
| `POST` | `/api/incidents/:id/attachments` | Multipart files → `attachment_blobs` + `data.attachments` |
| `GET` | `/api/incidents/:id/attachments/:attId` | Serves blob |

Also: static `/demo/attachments` for seed evidence. No PATCH, no status-transition route, no comment route, no `limit`/`offset`/`page` query params.

A good walkthrough says that out loud. QA header buttons on the detail page are chrome until a later exercise.

## 2. SQLite

File: `api/data/qms.sqlite` via `better-sqlite3` (`api/src/db.js`). WAL + foreign keys.

Tables:

- `incidents` — `id`, `title`, `status`, `priority`, `department`, `owner`, `created_at`, `updated_at`, `data` (full record JSON)
- `incident_id_seq` — next numeric suffix (seeded at 142 so the next create is `INC-{year}-0143`)
- `attachment_blobs` — binary content keyed by `(incident_id, att_id)`

`query()` parses `data` on SELECT. List columns are denormalized for the inbox; the detail view rehydrates the blob. `npm run seed` inserts missing demo rows; `npm run seed -- --reset` wipes the file DB.

If attendees treat SQLite as “just JSON files,” have them open `initSchema()` and `listProjection()`.

## 3. React surfaces

| Route | Page | Role |
|---|---|---|
| `/` | `Dashboard.jsx` | KPI “total incidents” + recent table; same list API |
| `/incidents` | `IncidentList.jsx` | Inbox: search + status filter **in the browser** over the full array |
| `/incidents/new` | `IncidentCreate.jsx` | Manual intake → `POST /api/incidents` |
| `/incidents/:id` | `IncidentDetail.jsx` | Header + tabs: Overview, Impact, Investigation, CAPA, Evidence, History |

Shared client: `web/src/api.js`. Shell chrome: Acme Quality / Berlin Lab, user Maria Alvarez (`AppShell.jsx`).

Empty QA fields render “To be completed by QA.” Seeded Slack drafts can show a bot banner. Evidence is the demo payoff (thumbnails / file chips).

Watch for the shared-state trap: Dashboard total and inbox rows both come from the unpaged list. Pagination later must not silently desync those two surfaces.

## 4. Incident lifecycle

`ENUMS.status` in `api/src/schema.js` (and the spec):

`Draft` → `Submitted` → `Under QA Review` → `Investigation` → `CAPA Required` | `No CAPA` → `Pending QA Approval` → `Approved` → `Closed`

Also: `Cancelled`, `Not a Deviation`. Record types: Incident, Deviation, Lab Investigation.

**Implemented today:** create always writes `Draft` and an audit event. Attachments append audit. Seeded rows already sit in later states.

**Not implemented as API:** submit, QA approve / promote / reject / request-more-info, investigation start, CAPA decision, close. Detail-page buttons do not persist.

A good walkthrough uses one concrete record:

- Happy path (create → QA review → approve as incident or promote to deviation)
- Rejection / `Not a Deviation`
- Escalation into Investigation and CAPA

…and then says which hops are spec vs. code.

## Facilitator cues

- No starter architecture diagram. If they ask for one, send them back to `createApp()`, `initSchema()`, and `App.jsx`.
- If Ask invents a comments table or `?page=`, have the attendee verify against `index.js`.
- `.cursor/rules` is empty on purpose. Do not “complete” this exercise by copying rules into `exercises/`.
