# Canvas brief — what the picture should show

Facilitator prompt: “Diagram the system as it is, then overlay how a quality incident is supposed to move. Label gaps.”

## Technical architecture (must appear)

```
Browser  →  Vite :5173 (React)  --proxy /api,/demo-->  Express :4000
                                                          │
                                                          ├─ GET/POST /api/incidents…
                                                          ├─ /demo/attachments (seed files)
                                                          └─ better-sqlite3
                                                               api/data/qms.sqlite
                                                               incidents + incident_id_seq
                                                               + attachment_blobs
```

Call out mocks: no real auth (Maria Alvarez is hardcoded), no Slack bot in-process (seed + `draftedFromSlack` flag), no validated Part 11 signatures, JSON blob for most record fields.

Optional boxes only if they exist in the repo: `npm run seed`, Compose/SQLite volume, `GET /api/meta` enums.

Do not invent Kafka, Postgres, or an identity service.

## Business flow — create / progress a quality incident

Use **Quality Incident** as the intake type. QA may later promote to **Deviation**. That is how this eQMS demo is specified.

### Happy path

1. Intake (manual form or Slack-drafted seed such as `INC-2026-0142`)
2. Record opens as `Draft` with evidence if present
3. QA reviews Overview + Impact; containment / classification
4. QA **Approve as incident** *or* **Promote to deviation**
5. If investigation is required, assign owner / due date
6. CAPA yes/no + justification
7. Pending QA approval → Approved → Closed, with audit + optional e-sign meaning

Mark which of these steps persist today (create + attach) vs. UI-only buttons.

### Rejection / not a deviation

- QA decides the Slack/manual report is not a quality event
- Status → `Not a Deviation` or `Cancelled`
- Comment / rationale required on the canvas (even if `qaComments` is not writable yet)
- Record remains findable in the inbox so the lab does not re-open the same noise
- Audit event: actor, from-status, to-status

This branch is spec + chrome today. The canvas should not pretend the API already does it.

### Escalation to investigation / CAPA

- Product, patient-safety, or data-integrity impact is Possible/Confirmed, **or** repeat event, **or** equipment still out of spec
- Status → `Investigation` (see `INC-2026-0131`)
- Investigation tab: required flag, owner, RCA method, root cause
- Then `CAPA Required` (linked CAPA IDs) **or** `No CAPA` with justification
- Effectiveness check only if CAPA is required

Show this as a fork after QA review, not as a second product.

## Record surfaces to pin on the canvas

- Inbox columns: ID, title, status, priority, department, created, owner
- Record tabs: Overview, Impact, Investigation, CAPA, Evidence, History
- QA actions: Request more info, Approve as incident, Promote to deviation, Cancel

## Seeded anchors (so the canvas is not generic)

| ID | Use on the canvas |
|---|---|
| `INC-2026-0142` | Slack-drafted happy-path start (Draft, evidence attached) |
| `INC-2026-0138` | Mid-flow: Under QA Review |
| `INC-2026-0131` | Escalation: Investigation |
| `DEV-2026-0088` | Closed deviation — inbox is not a single-record demo |
