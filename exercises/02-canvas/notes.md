# Facilitator tips — reviewing canvases

## Pass

- Vite and Express are separate boxes; SQLite is a file, not “the cloud”
- List vs. detail payloads are distinguished (`listProjection` vs. full `data`)
- Create is the only status-writing API; other QA verbs are labeled **intended**
- All three business branches are present (happy, reject/not-a-deviation, investigate/CAPA)
- Acme Quality / Berlin Lab language; Quality Incident vs. Deviation is a promotion, not two apps

## Push back

- **One box labeled “QMS”** with no routes or tables — send them to `createApp()` and `initSchema()`
- **Postgres / Docker as the default path** — default is `npm install && npm run seed && npm run dev`
- **Status machine drawn as fully implemented** — detail buttons are not wired
- **Missing Evidence** — that is the Slack-bot payoff in the spec
- **Pagination or comments drawn as current API** — those are later exercises
- **Customer or GxP product names** — keep the lab generic

## Review questions (use two, not ten)

1. If I POST a new incident, which canvas node changes, and what status is stored?
2. If Maria clicks “Promote to deviation,” what does the canvas claim happens in SQLite *today*?
3. Where would a “not a deviation” decision be recorded so the inbox does not lose the record?

## Timebox

Fifteen minutes to draw, five to compare two canvases side by side. Do not “fix” their diagram by pasting a reference architecture. Ex 01 forbade a starter diagram; this exercise is where *they* produce one.

## Carry forward

Photograph or export the canvas. Ex 03 (pagination) should not redraw the system. Ex 05 (lifecycle subagent) should reuse the business-flow fork.
