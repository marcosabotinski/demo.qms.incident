# Reference Ask-mode prompts

Facilitator copies (or paraphrases) these after attendees have tried their own questions. Keep the session in Ask mode. Do not paste a solution architecture.

## Orientation

- How do I run this repo without Docker, and which ports do the web app and API use?
- What is the Quality Incident Hub supposed to do for a Berlin Lab QA reviewer? Stay with what the README and spec actually say.
- Who is the mocked current user, and where is that defined?

## API and persistence

- List every Express route in `api/src/index.js` and what each returns. Call out anything that looks like a mutation but does not change status.
- How is SQLite opened and where does the file live? What tables exist after `initSchema()`?
- `incidents` has both typed columns and a `data` JSON blob. Which fields are columns, and what does `listProjection()` expose to the inbox?
- `POST /api/incidents` — which body fields are required, what status is written, and how is the new ID allocated?
- How do attachments work? Distinguish demo static files under `/demo/attachments` from blobs in `attachment_blobs`.

## React surfaces

- Map routes in `web/src/App.jsx` to page components. What does each page fetch?
- Home (`/`) and Incidents (`/incidents`) both call `getIncidents()`. What does each render, and is filtering client-side or server-side?
- On the record page, which tabs exist, and which QA buttons are wired to the API?
- Trace `createIncident` from the create form to the inbox. What would I see after a successful POST?

## Incident lifecycle

- What statuses does `ENUMS.status` allow? Which of those appear on seeded records?
- The spec describes Draft → QA review → investigation / CAPA / not-a-deviation. Which parts of that path are implemented as HTTP today, and which are UI-only or spec-only?
- Where is the audit trail stored, and what events are written on create vs. attach?

## Seeded records (use as concrete examples)

- Walk me through `INC-2026-0142` as if I am Maria Alvarez opening a Slack-drafted temperature excursion.
- Why does `DEV-2026-0088` exist if the working path is “create an incident”?
- Compare `INC-2026-0138` and `INC-2026-0131` — what should I expect on Impact / Investigation / CAPA tabs?

## Checks that keep Ask honest

- Do not propose pagination, comment APIs, or status-transition endpoints unless I ask. Tell me what is missing instead.
- Quote file paths and function names. Do not invent routes that are not in `createApp()`.
