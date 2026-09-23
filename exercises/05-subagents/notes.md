# Facilitator notes — merge and conflicts

## Likely collisions

| File | Agent A | Agent B | Merge rule |
|---|---|---|---|
| `docs/incident-lifecycle.md` | Owns | Should not touch | Keep A |
| `api/src/index.js` | Should not touch | Adds comment routes | Keep B; drop any status handlers A sneaks in |
| `api/src/schema.js` | Tempted to expand enums | Unused for v1 comments | Keep existing enums unless both agreed |
| `web/src/pages/IncidentDetail.jsx` | Might annotate QA buttons | Adds comments UI | Prefer B’s UI; do not leave A’s dead code comments in JSX |
| `web/src/api.js` | None | `getComments` / `postComment` | Keep B |
| `api/src/http.test.js` | None | New cases | Keep B; do not let A delete the list/create tests |
| `exercises/**` | Out of scope | Out of scope | Revert |

## Conflict patterns

- **Both add a `comments` key** — A as documentation example JSON, B as real storage. Only B’s runtime shape matters. A’s doc should describe B’s contract after merge (`GET/POST …/comments`).
- **Audit trail vs comments.** If B writes comments *only* as audit events, the History tab will look like a thread and you cannot GET comments. Fail the implementer.
- **`qaComments` reuse.** That field is a single QA decision note in the spec. A thread of lab chatter is a list. Keep them apart.
- **ID allocation.** `ATT-001` style vs UUID. Either is fine; mixing both in one PR is not.

## Integration tips

- Merge A first if it is docs-only. Rebase B. Run `node --test api/src/http.test.js` (or repo test script).
- Manual check: open `/incidents/INC-2026-0142`, submit a comment, confirm History gained an audit row **and** the thread shows the body.
- If B stored comments in JSON `data` and A’s doc said “new table,” update the doc in the merge commit — one sentence, do not reopen the explorer.

## When to fail the exercise

- Only one agent ran
- Explorer implemented Promote-to-deviation “while they were there”
- Implementer shipped pagination or a Skill
- Merge discarded the comment route to resolve a conflict
- `.cursor/` rules appeared under `exercises/`

## Bar

Two artifacts (lifecycle doc + working comments) in one branch, tests green, QA buttons still chrome. That is a pass.
