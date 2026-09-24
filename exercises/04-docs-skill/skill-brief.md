# Skill brief — documentation updater

## What the Skill should do

When the user asks to “update the Quality Incident Hub docs” / “refresh documentation.md”:

1. Read `documentation.md` if it exists.
2. Split **maintained** vs **one-off** sections using `exercises/04-docs-skill/doc-format.md`.
3. Inspect the repo (README, `api/src/index.js`, `schema.js`, `db.js`, `web/src/App.jsx`, pages, tests, seed list).
4. Rewrite maintained sections so they match **current** code.
5. Keep one-off section bodies intact (create stubs if absent).
6. Write `documentation.md` (repo root unless the user names another path).
7. Report a short diff summary: which maintained sections changed, which one-off sections were preserved.

The Skill is a procedure + checklist, not a dump of the current API into the Skill file itself. If the API gains pagination later, a Skill run should pick that up from `index.js`, not from frozen prose inside the Skill.

## Suggested Skill shape

Attendees may use the host Skill format they were taught. Minimum content:

- **Name / description:** triggers on documentation refresh for this eQMS demo
- **When to use:** after a lab slice (Ask, pagination, comments) or before a demo
- **When not to use:** unrelated repos; do not run as a substitute for tests
- **Steps:** the seven steps above
- **Section contract:** pointer to `doc-format.md` (do not fork the outline in the Skill)
- **Voice:** lab-neutral Acme Quality; concise; file-path citations

Do **not** put project rules that belong in `.cursor/rules` into the Skill. `.cursor/rules` is empty on purpose for this workshop.

## Optional Notion / Confluence MCP

If a Notion or Confluence MCP is connected:

- After a successful local write, the Skill **may** offer to publish or update a page titled “Acme Quality — Quality Incident Hub”
- Mapping: one `documentation.md` → one page; maintained sections replace the corresponding page blocks; one-off sections are appended only if missing
- If the MCP is missing or auth fails, the local file still counts as success. Do not fail the Skill because Confluence is down
- Never paste secrets from MCP config into `documentation.md`

If no MCP is available in the room, skip this paragraph in the live run. Keep the optional step in the Skill so the same file works in a connected environment.

## Invocation examples

- “Refresh documentation.md from the repo using the documentation skill.”
- “Update only maintained sections; leave Workshop decisions alone.”
- “Write documentation.md, then if Notion is available, publish a copy.”

## Non-goals

- Generating `exercises/**` content
- Opening a PR as part of the Skill (the human / later Agent does that)
- Implementing product features named in Known gaps
