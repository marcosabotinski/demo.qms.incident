# Ex 02 — Canvas: architecture + quality-incident flow

## Goal

Attendees use **Canvas** (or an equivalent visual workspace) to produce two pictures of the Quality Incident Hub:

1. **Technical architecture** — Vite, Express, SQLite, seed/attachments, what is mocked
2. **Business flow** — create and progress a quality incident in Acme Quality eQMS

The pictures should match this repo plus `qms-incident-demo-spec.md`. They should mark **implemented vs. intended** so later Plan/Agent work does not treat chrome as shipped workflow.

## Why Canvas here

Ask (Ex 01) is verbal and file-based. Canvas forces a single shared diagram: routes, tables, and QA decisions on one page. That is the briefing artifact for Ex 03–05.

## Success

A reviewable canvas includes:

- Client (`web/`, port 5173) talking to API (`api/`, port 4000) via `/api` proxy
- SQLite file + `incidents` / `attachment_blobs` (not a real identity provider, not a real QMS)
- Create → Draft persist → inbox → record tabs
- At least three business branches: happy path, rejection / not-a-deviation, escalation to investigation / CAPA

## Out of scope

- Implementing the missing transitions
- A pixel-perfect Figma of the current CSS
- Customer-specific branding (stay Acme Quality / Berlin Lab)
