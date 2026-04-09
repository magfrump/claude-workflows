# Scope Exception: CLAUDE.md routing table update needed

## Context
The `security-reviewer.md` skill now triggers on dependency manifest changes, but the
CLAUDE.md routing table (both global and project-level) still reads:

> Diff touches **auth, input handling, crypto, trust boundaries, file I/O, network calls, serialization**

This should be updated to include **dependency manifests** in the trigger list so that the
skill routing table is consistent with the skill's own `when` field and `description`.

## Files that need updating (outside allowed scope)
- `CLAUDE.md` (project root) — skill routing table
- `~/.claude/CLAUDE.md` (global) — skill routing table

## Why this wasn't done
File scope constraint for this task limits changes to `skills/security-reviewer.md` and
`docs/working/` only.

## Impact
The skill's own frontmatter (`when` and `description`) is updated, so orchestrators that
read the skill file directly will pick up the trigger. The CLAUDE.md routing table is a
human-readable summary that may be stale until updated separately.
