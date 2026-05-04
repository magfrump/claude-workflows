---
Goal: Add a 12th health check to scripts/health-check.sh that diff-summarizes CLAUDE.md, AGENTS.md, and GEMINI.md and flags semantic drift.
Project state: r1 round adds multi-agent MD drift detector to health-check.sh · standalone · not blocked
Task status: in progress
---

## Context

`scripts/health-check.sh` already has two MD-related checks:
- `check_workflow_crossrefs` (#2): each workflow filename referenced in CLAUDE.md/AGENTS.md/GEMINI.md must resolve to `workflows/<name>.md`.
- `check_md_consistency` (#3): all three files must reference the same set of workflow filenames.

Both check filename-level cross-references only. They do not catch semantic divergence in the *content* of the three files. Concretely, today CLAUDE.md is 194 lines while AGENTS.md and GEMINI.md are 69 lines each — CLAUDE.md has unique sections (Operating Modes, Session Hygiene, Review Artifacts, Workflow decision tree, Debugging defaults, How workflows compose) that have not propagated. AGENTS.md and GEMINI.md reference more skills than CLAUDE.md (draft-review, fact-check, design-space-situating, etc.). Since AGENTS.md and GEMINI.md are not consumed by Claude Code, this drift is silent.

## Plan

Add `check_md_semantic_divergence` as check #12 (after `check_doc_freshness`). Soft-warning only (no hard fails) — same pattern as #9–#11.

For each of CLAUDE.md, AGENTS.md, GEMINI.md, extract:
- H2 section headers (`^## ` lines)
- H3 section headers (`^### ` lines)
- References to known skills (any token-boundary match against `skills/*.md` basenames)
- Line count

Then emit:
1. **Per-file summary** (always shown): `<file>: <N> lines, <H2c> H2 + <H3c> H3 sections, <Sc> skill ref(s)`
2. **AGENTS.md vs GEMINI.md strict parity**: warn if their H2/H3 sets differ (these should be kept in sync; they cover different tools but with the same content).
3. **CLAUDE.md vs each sibling — H2 diff**: list section names present in one but not the other. Renames will appear on both sides; this is acceptable noise — humans can judge alignment vs rename.
4. **CLAUDE.md vs each sibling — skill ref diff**: list known skill names referenced in one but not the other. This is the highest-signal output — it points to specific skills whose mention has not propagated.
5. **Footer reminder** if any divergence detected: "AGENTS.md and GEMINI.md are not read by Claude Code — content updates in CLAUDE.md may drift silently."

Update the script header comment listing checks 1–11 to include #12.

## Why soft warning, not hard fail

Some divergence is intentional: CLAUDE.md has Operating Modes (active/away) which is Claude-specific UX and doesn't belong in tool-agnostic AGENTS.md. The check exists to surface drift for human review, not to gate on it. Hard-failing would require maintaining a per-file "intentionally unique" allowlist, which is more maintenance burden than the check itself.

## Verification

1. `bash -n scripts/health-check.sh` parses cleanly.
2. `shellcheck -x -e SC1091 -s bash scripts/health-check.sh` passes.
3. `scripts/health-check.sh` runs and the new section appears with realistic warnings reflecting the current divergence (CLAUDE.md unique sections, AGENTS/GEMINI unique skills).
4. Existing checks still pass at their previous status.
