# Ex 01 — Ask mode / codebase understanding

## Goal

Attendees stay in **Ask mode** and build a shared mental model of the Quality Incident Hub. They should be able to point at the API, the SQLite file, the React surfaces, and the intended incident lifecycle — without writing code.

This exercise does **not** start from an architecture diagram. Do not hand out a starter diagram. If someone draws one later, that is their own artifact, not a given.

## What exists today

The working path is **create a quality incident**, then list and open the record. The rest of the UI is eQMS chrome.

- Vite app on `http://localhost:5173` (`web/`)
- Express API on port 4000 (`api/`), proxied at `/api` and `/demo`
- Local SQLite file `api/data/qms.sqlite` (override with `SQLITE_PATH`)
- Seeded inbox: `INC-2026-0142` (Draft), `DEV-2026-0088` (Closed), `INC-2026-0138` (Under QA Review), `INC-2026-0131` (Investigation)

## Success

A participant can answer, from the repo and Ask-mode replies:

1. Which HTTP routes create, list, and open a record?
2. What is stored as columns vs. JSON `data` on `incidents`?
3. Which React pages share `getIncidents()`?
4. Which lifecycle states are enumerated vs. actually transitioned by the API?

## Out of scope

- Implementing pagination, comments, or QA actions
- Editing `.cursor/` rules
- Drawing a facilitator-supplied architecture diagram
