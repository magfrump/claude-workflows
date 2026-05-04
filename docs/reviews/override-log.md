# Code Review Override Log

This is the persistent log of human reviewer decisions to **override** what the code-review
pipeline produced — demoting a 🔴 Must Fix or 🟡 Must Address finding (Won't-Fix), or
upgrading a 🟢 Consider finding (Must-Fix). Entries are read at the start of every
`code-review` run (per `skills/code-review.md`, Before You Begin Step 4) so that prior
decisions explicitly inform the next review and the same finding is not re-litigated each
pass.

## What counts as an override

An override is a tier change initiated by a **human reviewer** relative to what the
pipeline produced — not a change initiated by the pipeline itself, and not a general code
review note. Specifically:

- **Demote**: 🔴 → 🟢 (or 🟡 → 🟢, or 🔴 → 🟡) — the human accepts the finding as real but
  decides not to fix it (this PR or ever). Often "Won't-Fix-this-PR" with a follow-up
  reference, sometimes "Won't-Fix-ever" with working-as-intended rationale.
- **Upgrade**: 🟢 → 🟡 (or 🟢 → 🔴, or 🟡 → 🔴) — the human treats a Consider/nit as
  binding for this codebase or this surface, often because of context the critic could
  not see (a prior incident, a contractual obligation, a load-bearing convention).

What does **not** belong here:

- Findings the author simply addressed in the rubric's normal "Author note" workflow on a
  🟡 row — that's resolution, not override.
- Critic disagreements resolved during the review-fix loop — those are review iteration,
  not override. Only post-loop human decisions about what survives become overrides.
- Generic style preferences, lint rule choices, or codebase-wide conventions — those
  belong in `docs/decisions/` or a style guide, not the override log.

## How to read

The log is append-only. Each entry is a top-level section with the schema below. Most-
recent entries appear at the top. The orchestrator scans entries by `Location` (file path)
and by free-text match against the changed-file list and current findings; the human
reads them top-to-bottom for chronological context.

## How to add an entry

After the `code-review` skill produces a rubric and the human reviewer decides to
override one or more findings, the orchestrator drafts a new entry, reads it back to the
human for confirmation, then appends it to this file. The skill MUST NOT write entries
without explicit human authorization (see `skills/code-review.md`, "Post-Review: Capture
Overrides").

If you are adding an entry by hand, copy the schema below, increment the `OV-NNN`
identifier (the next unused integer; see the most recent entry), and fill in every field.
Empty rationale is not acceptable — the rationale is the load-bearing reason the override
exists.

## Entry schema

```markdown
## OV-NNN · YYYY-MM-DD · <Demote 🔴 → 🟢 | Demote 🟡 → 🟢 | Upgrade 🟢 → 🔴 | …> · `path/to/file:line`

**Scope:** <branch name and PR number, or "ad-hoc review" if no PR>
**Original finding:** <one-line description of the finding as the rubric stated it>
**Domain:** <Security | Performance | API Consistency | Fact-Check | contextual critic name>
**Original verdict:** <🔴 Must Fix | 🟡 Must Address | 🟢 Consider> (severity, confidence)
**Override verdict:** <new tier> — <"won't fix this PR" | "won't fix ever" | "must fix in this codebase">
**Rationale:** <Why this override is being recorded. This is the load-bearing field — must
contain enough context that a future reviewer (or the skill on its next run) can decide
whether the override still applies or whether circumstances have changed enough to
re-evaluate. Multi-line is fine.>
**Decided by:** <reviewer handle or name>
**Re-evaluate when:** <a concrete trigger — e.g., "issue INGEST-456 lands", "the auth
middleware migration completes", "the file changes in a way that would shift the
calculus" — or "never (working as intended)" if the override is permanent>
```

---

## Entries

<!--
The first entry below is a template / worked example. Real entries are appended above it
(most-recent first). Once at least one real entry exists, this notice can be removed and
the example entry can stay as the bottom-of-log reference, or be deleted by the next
human reviewer who edits the log directly.
-->

## OV-000 · 2026-05-03 · Demote 🔴 → 🟢 · `src/example.ts:42` (template / worked example)

**Scope:** ad-hoc review (template entry, not from a real PR)
**Original finding:** Token stored in plaintext localStorage instead of httpOnly cookie
**Domain:** Security
**Original verdict:** 🔴 Must Fix (High severity, High confidence)
**Override verdict:** 🟢 Consider — won't fix this PR
**Rationale:** Token storage migration is tracked separately under a parallel initiative;
this PR's scope is the public API surface only and changing storage here would require
rolling a backwards-compatible migration that is being designed elsewhere. The finding
is real and high-severity — it is not being dismissed, only deferred. Future reviews on
this file should still surface the issue, but the orchestrator should note that an
override exists and skip re-flagging it as a blocker.
**Decided by:** template-author
**Re-evaluate when:** the token-storage migration initiative lands, OR if this file is
modified in a way that changes the storage path itself
