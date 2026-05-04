# Checkpoint: persona-critique-freshness
Date: 2026-05-03
Branch: feat/r1-persona-critique-freshness
Research: docs/working/research-persona-critique-freshness.md
Plan: docs/working/plan-persona-critique-freshness.md

## Project state
- **Branch purpose**: Add a `persona-last-sampled` frontmatter field to persona-critique skills and a soft-warning health-check that flags entries >~6 months old. Re-sampling is a future task.
- **Position in larger initiative**: r1 round, sibling to other r1/r2/r3 branches. Standalone for this loop.
- **Blocked on**: nothing.

## Key findings
- Three target skills carry `lens:` in their YAML frontmatter, but `lens` is **not** in `allowed_keys` of `scripts/health-check.sh`. The unknown-key check currently flags it. [observed via `git show f6629f7` + reading the script regex]
- Check #11 (`check_doc_freshness`, lines 548-633) is the prior art: walks docs, awk-extracts a date field, validates `^[0-9]{4}-[0-9]{2}-[0-9]{2}$`, compares to git or today, prints soft warnings + summary. Mirror its structure.
- Soft-warning checks (#9, #10, #11) print `warn` but do not set `FAIL=1`. The new check follows the same convention — task brief says "flag", not "block".
- `test/skills/frontmatter-fields.bats` enforces `name`, `description`, `when|trigger` independently. Anything else (lens, persona-last-sampled) is health-check's domain.

## Plan
1. Add `persona-last-sampled: 2026-05-03` after `lens:` in skills/cowen-critique.md, skills/yglesias-critique.md, skills/ai-personas-critique.md.
2. In scripts/health-check.sh:
   - Append `lens` and `persona-last-sampled` to `allowed_keys` (line 92).
   - Add new function `check_persona_freshness` (mirrors `check_doc_freshness`): walk `skills/*.md`, extract `persona-last-sampled` from YAML, validate date, warn if >180 days old, skip silently if field absent.
   - Wire into `main()` after `check_doc_freshness`.
3. Re-run health-check, commit, push.

## Invariants
- `name`, `description`, `when|trigger` must remain on every skill.
- Health-check exit 0 must hold; the new check is soft-warning only.
- Field placement: keep persona-identity metadata (`lens`, `persona-last-sampled`) grouped after `name`.

## File map
- `skills/cowen-critique.md` — add `persona-last-sampled: 2026-05-03` (step 1)
- `skills/yglesias-critique.md` — add `persona-last-sampled: 2026-05-03` (step 1)
- `skills/ai-personas-critique.md` — add `persona-last-sampled: 2026-05-03` (step 1)
- `scripts/health-check.sh` — widen allowed_keys, add check_persona_freshness, wire into main (step 2)

## Open questions
- Exactly what threshold counts as "~6 months"? Using **180 days** as a simple, slightly-stricter approximation. The constant is a one-liner if the reviewer prefers calendar-month math.
- The `lens` allowed-keys widening is a sneaky cross-cutting fix that lands in the same commit as the new field — surfaced explicitly in the commit message.
