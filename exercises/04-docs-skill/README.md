# Ex 04 — Documentation skill

## Goal

Attendees write a **Cursor Skill** that creates or updates a single `documentation.md` at the repo root (or a path the brief agrees). The Skill encodes the section contract in `doc-format.md` so Agent mode does not invent a new outline every run.

This is a process exercise. The Skill is the deliverable, not a rewritten eQMS.

## Why a Skill

Phase 1 already produced Ask notes, a Canvas, and a pagination plan. Those rot if they only live in chat. A Skill is the repeatable way to fold “what this mock eQMS is” into one maintained doc.

## Success

- Skill file exists in the attendee’s Skill location (project or user), not as a dump of `.cursor/rules`
- Running it against this repo yields a `documentation.md` that follows `doc-format.md`
- Maintained sections are overwritten from the code; one-off sections are preserved
- Optional: the Skill *mentions* publishing a copy to Notion or Confluence via MCP — it does not require those MCPs to succeed locally

## Out of scope

- Implementing pagination or comments
- Duplicating Cursor rules from `.cursor/` into `exercises/`
- Treating `qms-incident-demo-spec.md` as the Skill output (that spec stays the product brief)
