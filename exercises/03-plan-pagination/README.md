# Ex 03 — Plan mode: paginate the incidents list

## Goal

In **Plan mode**, attendees produce a plan to add pagination to the quality-incident **inbox** (API + UI). They do not implement in this exercise unless the facilitator later switches to Agent.

`GET /api/incidents` currently returns the full table, newest `created_at` first. `IncidentList.jsx` and `Dashboard.jsx` both consume that array. Client-side search and status filter run on whatever came back.

## Why this plan

The seeded inbox is four rows. Pagination is pointless until someone creates more records — which is exactly why it is a clean Plan-mode demo: the gap is obvious, the change set is bounded, and off-by-one bugs are easy to discuss.

## Success

A plan that a reviewer can execute later without re-discovering:

- Query parameters and response shape
- Stable sort + total count
- Inbox UI controls (page size, next/prev, “showing x–y of z”)
- What happens to Dashboard (same hook vs. separate summary)
- Tests to add in `api/src/http.test.js` and any list-page checks
- Explicit non-goals (server-side full-text search, infinite scroll, changing record IDs)

## Out of scope for the plan artifact

- Shipping the code in this folder
- Reworking QA workflow or comments
- Copying Cursor rules into the app
