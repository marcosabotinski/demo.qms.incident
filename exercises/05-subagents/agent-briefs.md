# Subagent briefs

Run both. Do not give one agent both briefs.

Suggested launch (wording for the facilitator):

> Two subagents on `demo.qms.incident`. Agent A explores only. Agent B implements only. Neither edits `exercises/` or `.cursor/`. I will merge.

## Agent A — Incident lifecycle explorer

**Role:** research / Ask-style. **No product-feature implementation.**

**Read:** `qms-incident-demo-spec.md` (workflow + QA decisions), `api/src/schema.js` (`ENUMS.status`, `recordType`), `api/src/index.js` (what POST actually writes), `api/src/seed.js` (which statuses already exist), `web/src/pages/IncidentDetail.jsx` (QA buttons and tabs).

**Write (only):** a single Markdown file, `docs/incident-lifecycle.md` (create `docs/` if needed), covering:

1. Allowed statuses and record types
2. Intended happy path, not-a-deviation / cancel, investigation → CAPA
3. What HTTP exists today (create + attach + audit entries)
4. What the four QA buttons do in the UI (nothing, unless that changed)
5. Recommended future endpoints **as a list**, not as code — e.g. submit, request-more-info, approve-as-incident, promote-to-deviation, mark-not-a-deviation, start-investigation
6. Where a comment thread should hook without inventing a second audit log (see Agent B’s contract below — do not implement it)

**Do not:** change `schema.js` enums “to be complete,” wire the QA buttons, add pagination, or edit `documentation.md` unless asked.

**Done when:** `docs/incident-lifecycle.md` is accurate enough that a facilitator can grade Ex 01/02 against it.

## Agent B — Comment thread implementer

**Role:** implement a minimal, testable comment thread. **Do not implement the status machine.**

### Product contract

- Comments belong to one incident
- Fields: `id` (e.g. `CMT-001`), `body` (non-empty string), `author` (default Maria Alvarez / current user from `/api/meta`), `at` (ISO timestamp)
- Newest last in the UI (chronological thread)
- Creating a comment also appends an `auditTrail` event (`action: "Commented"`) so History stays complete
- QA comments (`qaComments` on the record) stay a separate field — do not overload it

### Suggested API

```
GET  /api/incidents/:id/comments   → { comments: [...] }
POST /api/incidents/:id/comments   → 201 { comment }  body: { "body": "…" }
```

404 if the incident is missing. 400 if `body` is empty.

Storage: acceptable v1 is `data.comments` on the existing JSON blob (no new SQLite table required). A `comments` table is fine if the agent prefers it — then say so in the PR description. Do not store comment text only inside `auditTrail`.

### UI

- Record page: a **Comments** block (own tab *or* a section on Overview/History — pick one and stick to it)
- Text area + submit; show author + time
- Empty state: “No comments yet”
- Do not wire “Request more info” to this thread unless the explorer doc already defined that (it should not, in v1)

### Tests

Extend `api/src/http.test.js`: create or open a seed incident, POST a comment, GET it back, 400 on empty body, 404 on unknown id.

### Do not

- Implement pagination
- Implement status transitions
- Rewrite seed narratives
- Touch `exercises/05-subagents/` except to read this brief

**Done when:** a reviewer can open `INC-2026-0142`, add “QA: confirm IC-12 is still out of service,” refresh, and see the comment.

## How to run them together

1. Start Agent A and Agent B at the same time, each with only its brief.
2. If they share a worktree, tell Agent B the files it **owns**: `api/src/index.js` (comment routes only), `api/src/http.test.js` (comment cases), `web/src/api.js`, `IncidentDetail.jsx` (comments UI). Tell Agent A it **owns** `docs/incident-lifecycle.md` only.
3. If your host supports isolated worktrees, give each agent its own branch (`cursor/lifecycle-explore-…`, `cursor/incident-comments-…`) and merge Agent A first (docs-only), then Agent B.
4. After both finish: run `npm test` (or the API test file) and click the record page.
5. If Agent B “helpfully” implemented Promote to deviation, revert that hunk. That belongs to a later exercise.

## Merge order

Docs first, then code. If both edited `IncidentDetail.jsx`, keep B’s comments UI and A’s notes out of the JSX (A should not have edited it).
