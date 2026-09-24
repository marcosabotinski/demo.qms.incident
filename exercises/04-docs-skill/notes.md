# Review checklist — documentation Skill

Facilitator uses this against the attendee’s Skill file **and** a sample `documentation.md` it produced.

## Skill file

- [ ] Has a clear trigger description (refresh / update `documentation.md`)
- [ ] Points at `doc-format.md` instead of inventing headings
- [ ] Distinguishes maintained vs one-off
- [ ] Tells the agent to read the code, not the spec, when they disagree
- [ ] Mentions MCP publish as optional; local write is the success criteria
- [ ] Does not embed `.cursor/` install or environment scripts
- [ ] Does not paste customer branding

## Produced `documentation.md`

- [ ] Headings match the contract, in order
- [ ] `## HTTP API` lists the real routes (health, meta, list, detail, create, attachments)
- [ ] List endpoint described as returning **all rows** unless pagination actually landed
- [ ] Lifecycle section marks QA actions as unimplemented if buttons are still dead
- [ ] Seed table includes `INC-2026-0142` and `DEV-2026-0088`
- [ ] Run section is the npm path, not Compose-first
- [ ] One-off sections survived a second Skill run (plant a unique sentence and re-run)

## Failure modes to demo

1. **Clobber:** first run writes a workshop decision; second run deletes it → Skill is not done.
2. **Spec fan-fiction:** doc claims `PATCH /api/incidents/:id/status` exists.
3. **Array vs envelope:** if someone already implemented pagination, the doc still says “returns an array.”
4. **Wrong file:** Skill updates `README.md` or the spec instead of `documentation.md`.

## Bar

A Skill that produces a slightly dry but accurate doc beats a polished doc that lies about the API. Accuracy is the grade.
