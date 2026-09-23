# Ex 05 — Subagents: lifecycle explore + comment thread

## Goal

Run **two subagents in parallel**, then merge their work on this repo:

1. **Explorer** — document how a quality incident is supposed to move (and what the code actually does)
2. **Implementer** — add a **comment thread** on the incident record (API + a place to render it)

The point is coordination: one agent should not rewrite `ENUMS.status` while the other is adding `POST /api/incidents/:id/comments` to the same files.

## Why two agents

Lifecycle and comments both touch the record page, the JSON `data` blob, and the audit trail. A single Agent run will usually “helpfully” implement QA transitions *and* comments. Splitting the briefs keeps Ex 05 from becoming a full workflow build.

## Success

- Explorer output: a short lifecycle map (implemented vs intended) that matches Ex 01/02
- Implementer output: comments persist and show on the record (History tab or a Comments panel)
- Merge: one working tree; no lost comment route; no accidental pagination or Skill rewrite
- Tests updated for the new comment path (`http.test.js` or equivalent)

## Out of scope

- Pagination (Ex 03 plan only, unless already merged)
- A real Slack integration
- Copying Cursor rules into this folder
- Promoting records to Deviation unless the explorer only *describes* it
