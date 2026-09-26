# Bug-Diagnosis Cleanup Inventory

> Working doc for Task A.1 of `docs/superpowers/plans/2026-05-18-superpowers-integration-minimal.md`.
> Feeds Task A.3 (the redirect/delete pass) as a checklist.

Generated 2026-05-18 by running:

```
grep -rn "bug-diagnosis\|bug_diagnosis" --include="*.md" /home/magfrump/claude-workflows/.claude/worktrees/superpowers-minimal-integration
```

## Summary

- **Total files matched:** 22
- **Total reference lines:** 126
- **Live files needing redirect/edit:** 11 (CLAUDE.md, AGENTS.md, GEMINI.md, workflows/codebase-onboarding.md, workflows/pr-prep.md, workflows/research-plan-implement.md, docs/workflow-selection.md, docs/workflow-dependency-graph.md, guides/workflow-selection.md, guides/README.md, guides/skill-creation.md, docs/thoughts/failure-patterns.md — *plus* deletion of workflows/bug-diagnosis.md and skills/bug-diagnosis/SKILL.md)
- **Files to delete entirely:** 2 (workflows/bug-diagnosis.md, skills/bug-diagnosis/SKILL.md)
- **Files marked historical (leave as-is):** 7 (docs/decisions/008-..., docs/human-author/feedback.md, docs/reviews/*, docs/superpowers/plans/*, docs/working/hypothesis-backlog.md, docs/working/reports/external-skill-audit.md)
- **Failure-pattern-library / FP-NNN references flagged separately:** see "Failure-pattern library references" section below.

### Per-category counts

| Category | Reference count |
|---|---|
| Routing reference | 6 |
| Composition note | 3 |
| Composition-narrative-inside-workflow | 10 |
| Historical reference (leave as-is) | 93 |
| Skill description | 5 |
| To-be-deleted (self-reference inside files slated for deletion) | 9 |

(Sum: 126.)

### Per-category file/line breakdown

- **Routing reference (6):** AGENTS.md:16 · GEMINI.md:16 · docs/workflow-dependency-graph.md:16 · docs/workflow-selection.md:9 · guides/workflow-selection.md:56,93
- **Composition note (3):** CLAUDE.md:105 · workflows/codebase-onboarding.md:178 · workflows/research-plan-implement.md:21
- **Composition-narrative-inside-workflow (10):** CLAUDE.md:30,32,38,43 · workflows/pr-prep.md:50,55 · workflows/research-plan-implement.md:119 · docs/thoughts/failure-patterns.md:3,9,77
- **Skill description (5):** guides/README.md:31 · guides/skill-creation.md:76,94,113,128
- **To-be-deleted self-reference (9):** workflows/bug-diagnosis.md:24,233,273,356 · skills/bug-diagnosis/SKILL.md:2,5,13,25,140
- **Historical reference (93):** all references in docs/decisions/, docs/human-author/, docs/reviews/, docs/superpowers/plans/, docs/working/ — see per-reference table for full list

## Categorization rules (from plan)

- **Routing reference** — table entry or decision-tree row. **Action:** replace `bug-diagnosis` with `superpowers:systematic-debugging`.
- **Composition note** — cross-workflow handoff line. **Action:** redirect to `superpowers:systematic-debugging → research phase of RPI`.
- **Composition-narrative-inside-workflow** — a *section* of another workflow describing its interaction with bug-diagnosis. **Action:** judgment call — rewrite to reference `superpowers:systematic-debugging`, or delete/simplify if the narrative depended on bug-diagnosis-specific structure (e.g., step numbers) that systematic-debugging lacks.
- **Historical reference** — `docs/working/`, `docs/thoughts/`, `docs/decisions/`, `docs/reviews/`, `docs/human-author/`, plus plan files in `docs/superpowers/plans/` (they describe the current change). **Action:** leave as-is — dated artifacts.
- **Skill description** — `guides/skill-creation.md`, `guides/README.md`. **Action:** redirect to `superpowers:systematic-debugging`.
- **To-be-deleted (self-reference)** — line lives inside `workflows/bug-diagnosis.md` or `skills/bug-diagnosis/SKILL.md` (files Task A.3 deletes). **Action:** none — the deletion handles it.

## Per-reference detail

| File | Line | Category | Action |
|---|---|---|---|
| AGENTS.md | 16 | Routing reference | Replace bullet text: remove `@./workflows/bug-diagnosis.md`; add a one-line note pointing to `superpowers:systematic-debugging` for debugging work (preserve AGENTS.md's `@./` prefix convention) |
| CLAUDE.md | 30 | Composition-narrative-inside-workflow | Section heading "Debugging defaults (absorbed from bug-diagnosis)" — drop the parenthetical; section content stays |
| CLAUDE.md | 32 | Composition-narrative-inside-workflow | Replace "The standalone `bug-diagnosis.md` workflow is deprecated" with the new framing: invoke `superpowers:systematic-debugging` for the core loop; the numbered principles are the local extension |
| CLAUDE.md | 38 | Composition-narrative-inside-workflow | Update wording "Full template lives in `workflows/bug-diagnosis.md` step 5" — `workflows/bug-diagnosis.md` is being deleted; either inline the handoff template here or drop the pointer |
| CLAUDE.md | 43 | Composition-narrative-inside-workflow | Remove the line "For complex bugs that need a formal diagnosis log, the template and full process remain available in `workflows/bug-diagnosis.md`." — `workflows/bug-diagnosis.md` is being deleted |
| CLAUDE.md | 105 | Composition note | "Bug diagnosis → RPI" — rewrite to "`superpowers:systematic-debugging` → RPI" and drop the `workflows/bug-diagnosis.md` step-5 pointer in favor of inline handoff template (or local reference if A.3 chooses to inline it in CLAUDE.md) |
| GEMINI.md | 16 | Routing reference | Same edit pattern as AGENTS.md line 16 (without the `@./` prefix — GEMINI.md uses bare filenames) |
| docs/decisions/008-hypothesis-screening-workflow.md | 62 | Historical reference | Leave as-is. Dated decision record (H-03 tracking row). |
| docs/human-author/feedback.md | 25 | Historical reference | Leave as-is. Dated author feedback. |
| docs/human-author/feedback.md | 34 | Historical reference | Leave as-is. Dated author feedback. |
| docs/reviews/critique-superpowers-integration-plan.md | 12 | Historical reference | Leave as-is. Critique that motivated the current plan. |
| docs/reviews/critique-superpowers-integration-plan.md | 14 | Historical reference | Leave as-is. |
| docs/reviews/critique-superpowers-integration-plan.md | 16 | Historical reference | Leave as-is. |
| docs/reviews/critique-superpowers-integration-plan.md | 64 | Historical reference | Leave as-is. |
| docs/reviews/critique-superpowers-integration-plan.md | 96 | Historical reference | Leave as-is. |
| docs/reviews/critique-superpowers-integration-plan.md | 114 | Historical reference | Leave as-is. |
| docs/reviews/critique-superpowers-integration-plan.md | 134 | Historical reference | Leave as-is. |
| docs/reviews/critique-superpowers-integration-plan.md | 146 | Historical reference | Leave as-is. |
| docs/reviews/critique-superpowers-integration-plan.md | 210 | Historical reference | Leave as-is. |
| docs/reviews/self-eval-bug-diagnosis.md | 1 | Historical reference | Leave as-is. Entire file is a self-eval artifact dated 2026-03-27. (Note: the file itself is not deleted, only marked historical — Task A.3 should not touch it.) |
| docs/reviews/self-eval-bug-diagnosis.md | 3 | Historical reference | Leave as-is. |
| docs/reviews/self-eval-bug-diagnosis.md | 14 | Historical reference | Leave as-is. |
| docs/reviews/self-eval-bug-diagnosis.md | 61 | Historical reference | Leave as-is. |
| docs/reviews/self-eval-bug-diagnosis.md | 63 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration-minimal.md | 8 | Historical reference | Leave as-is. This is the current plan; references describe the work itself. |
| docs/superpowers/plans/2026-05-18-superpowers-integration-minimal.md | 19 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration-minimal.md | 22 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration-minimal.md | 26 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration-minimal.md | 32 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration-minimal.md | 33 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration-minimal.md | 46 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration-minimal.md | 47 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration-minimal.md | 52 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration-minimal.md | 61 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration-minimal.md | 65 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration-minimal.md | 67 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration-minimal.md | 71 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration-minimal.md | 73 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration-minimal.md | 77 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration-minimal.md | 80 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration-minimal.md | 83 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration-minimal.md | 102 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration-minimal.md | 103 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration-minimal.md | 115 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration-minimal.md | 119 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration-minimal.md | 123 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration-minimal.md | 129 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration-minimal.md | 138 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration-minimal.md | 147 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration-minimal.md | 154 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration-minimal.md | 160 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration-minimal.md | 161 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration-minimal.md | 165 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration-minimal.md | 171 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration-minimal.md | 172 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration-minimal.md | 177 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration-minimal.md | 183 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration-minimal.md | 222 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration-minimal.md | 238 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration-minimal.md | 294 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration.md | 210 | Historical reference | Leave as-is. Earlier (superseded) version of the integration plan. |
| docs/superpowers/plans/2026-05-18-superpowers-integration.md | 212 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration.md | 214 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration.md | 221 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration.md | 222 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration.md | 229 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration.md | 230 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration.md | 234 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration.md | 239 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration.md | 240 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration.md | 251 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration.md | 254 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration.md | 257 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration.md | 268 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration.md | 270 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration.md | 274 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration.md | 281 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration.md | 287 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration.md | 288 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration.md | 292 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration.md | 298 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration.md | 299 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration.md | 304 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration.md | 310 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration.md | 315 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration.md | 318 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration.md | 332 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration.md | 336 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration.md | 341 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration.md | 342 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration.md | 634 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration.md | 641 | Historical reference | Leave as-is. |
| docs/superpowers/plans/2026-05-18-superpowers-integration.md | 734 | Historical reference | Leave as-is. |
| docs/thoughts/failure-patterns.md | 3 | **Composition-narrative-inside-workflow** (special — see Failure-pattern library section below) | Header comment cites `workflows/bug-diagnosis.md` as the write-side. Plan Task A.2 owns the rewrite — A.3 should NOT separately edit this file. |
| docs/thoughts/failure-patterns.md | 9 | **Composition-narrative-inside-workflow** (special) | `Relevant paths: workflows/bug-diagnosis.md` — same as above; A.2 territory. |
| docs/thoughts/failure-patterns.md | 77 | **Composition-narrative-inside-workflow** (special) | "In a bug-diagnosis hypothesis, the source-tag form is `[from prior bug FP-NNN]`." — rewrite under A.2 to drop the `bug-diagnosis hypothesis` framing. |
| docs/workflow-dependency-graph.md | 16 | Routing reference | Replace `bug-diagnosis ←──────→ RPI` with `superpowers:systematic-debugging ←──────→ RPI` (or drop the row if A.3 chooses — systematic-debugging is a skill, not a workflow, and the graph is workflow-scoped) |
| docs/workflow-selection.md | 9 | Routing reference | Replace decision-tree row text "Bug with a known area of code → **bug-diagnosis**" with a pointer to `superpowers:systematic-debugging` |
| docs/working/hypothesis-backlog.md | 17 | Historical reference | Leave as-is. H-03 row, dated 2026-04-06. |
| docs/working/hypothesis-backlog.md | 29 | Historical reference | Leave as-is. H-08 row, dated 2026-04-08. |
| docs/working/reports/external-skill-audit.md | 79 | Historical reference | Leave as-is. Dated audit report. |
| docs/working/reports/external-skill-audit.md | 106 | Historical reference | Leave as-is. |
| docs/working/reports/external-skill-audit.md | 125 | Historical reference | Leave as-is. |
| docs/working/reports/external-skill-audit.md | 127 | Historical reference | Leave as-is. |
| docs/working/reports/external-skill-audit.md | 147 | Historical reference | Leave as-is. |
| guides/README.md | 31 | Skill description | Update "Use when unsure whether to reach for bug-diagnosis vs research-plan-implement" — drop the `bug-diagnosis` example or replace with `superpowers:systematic-debugging` (skill, not workflow, so phrasing differs from the rest of the list) |
| guides/skill-creation.md | 76 | Skill description | Paragraph "Workflows shrinking into skills" cites `bug-diagnosis` as worked example with mention of `skills/bug-diagnosis.md`. Rewrite to reflect the current state (workflow + skill both removed; superpowers:systematic-debugging is the canonical form), or — if A.3 prefers — leave the historical narrative but add a closing sentence noting the workflow and local skill were ultimately removed |
| guides/skill-creation.md | 94 | Skill description | "as `bug-diagnosis` showed" — phrasing remains accurate as historical; A.3 may leave as-is or fold the example into past tense |
| guides/skill-creation.md | 113 | Skill description | Workflows-inventory table row `bug-diagnosis | Deprecated | Core loop extracted to skill.` — remove this row; the workflow no longer exists |
| guides/skill-creation.md | 128 | Skill description | Skills-inventory table row `bug-diagnosis | Strong | Extracted from workflow.` — remove this row; the skill no longer exists |
| guides/workflow-selection.md | 56 | Routing reference | "For complex bugs that need a formal diagnosis log, the template remains in `workflows/bug-diagnosis.md`." — delete this line; `workflows/bug-diagnosis.md` is being removed |
| guides/workflow-selection.md | 93 | Routing reference | Workflow Reference table row `[bug-diagnosis](../workflows/bug-diagnosis.md) | Deprecated as standalone; debugging defaults absorbed into CLAUDE.md` — remove this row |
| skills/bug-diagnosis/SKILL.md | 2 | To-be-deleted (self-reference) | File slated for deletion in plan Task A.3 step 3 (`git rm -r skills/bug-diagnosis/`) — no edit needed. |
| skills/bug-diagnosis/SKILL.md | 5 | To-be-deleted (self-reference) | Same — file deletion handles it. |
| skills/bug-diagnosis/SKILL.md | 13 | To-be-deleted (self-reference) | Same. |
| skills/bug-diagnosis/SKILL.md | 25 | To-be-deleted (self-reference) | Same. |
| skills/bug-diagnosis/SKILL.md | 140 | To-be-deleted (self-reference) | Same. |
| workflows/bug-diagnosis.md | 24 | To-be-deleted (self-reference) | File slated for deletion in plan Task A.3 step 3 (`git rm workflows/bug-diagnosis.md`) — no edit needed. |
| workflows/bug-diagnosis.md | 233 | To-be-deleted (self-reference) | Same. |
| workflows/bug-diagnosis.md | 273 | To-be-deleted (self-reference) | Same. |
| workflows/bug-diagnosis.md | 356 | To-be-deleted (self-reference) | Same. |
| workflows/codebase-onboarding.md | 178 | Composition note | Inline link "`workflows/bug-diagnosis.md`" → drop the trailing pointer or replace with `superpowers:systematic-debugging`. Phrasing currently reads "composes with the failure-pattern library (`docs/thoughts/failure-patterns.md`) used in [`workflows/bug-diagnosis.md`](./bug-diagnosis.md)" — after A.2 the failure-pattern library is owned by pr-prep + RPI, so the simplest rewrite drops the bracketed link entirely (the failure-pattern library reference stands on its own) |
| workflows/pr-prep.md | 50 | **Composition-narrative-inside-workflow** (failure-pattern coupling) | Inside the FP-coverage advisory: `echo "  appending an FP-NNN entry per workflows/bug-diagnosis.md step 8."` — Task A.2 owns this rewrite (replace pointer with inline append prompt). A.3 should NOT touch — A.2 already covers it. |
| workflows/pr-prep.md | 55 | **Composition-narrative-inside-workflow** (failure-pattern coupling) | "If yes for any of them, return to `bug-diagnosis.md` step 8 and append the entry before opening the PR." — Task A.2 owns the rewrite (exact replacement text is specified in plan Task A.2 step 2). A.3 should NOT touch. |
| workflows/research-plan-implement.md | 21 | Composition note | RPI "When to pivot" → Bug Diagnosis entry. Rewrite both halves of the line (the `→` and `←` directions are on different lines; this is the `→` direction at line 21). Replace "the **Bug Diagnosis workflow** (`bug-diagnosis.md`)" with reference to `superpowers:systematic-debugging`. The "skip to bug-diagnosis's Fix and Verify steps" phrase relies on bug-diagnosis-specific step names; rewrite to point to systematic-debugging's equivalent move (or simplify if systematic-debugging is structured differently) |
| workflows/research-plan-implement.md | 119 | **Composition-narrative-inside-workflow** (failure-pattern coupling) | "an append-only log of root-caused bugs maintained by `bug-diagnosis.md`" — Task A.2 owns the rewrite (new sentence describes the pr-prep write-side instead of bug-diagnosis). A.3 should NOT touch. |

## Files to delete entirely (no edits — `git rm` only)

These appear in the table above under category "To-be-deleted (self-reference)" but are listed together here for clarity:

- `workflows/bug-diagnosis.md` (4 self-references inside the file)
- `skills/bug-diagnosis/SKILL.md` (5 self-references inside the file)

Plan Task A.3 step 3 runs `git rm workflows/bug-diagnosis.md` and `git rm -r skills/bug-diagnosis/`.

## Files to leave alone (historical artifacts)

Per the plan's exclusion rule, files under these paths are dated artifacts and must NOT be edited by Task A.3:

- `docs/decisions/` — 1 file, 1 reference (008-hypothesis-screening-workflow.md)
- `docs/human-author/` — 1 file, 2 references (feedback.md)
- `docs/reviews/` — 2 files, 14 references (critique-superpowers-integration-plan.md, self-eval-bug-diagnosis.md)
- `docs/superpowers/plans/` — 2 files, 56 references (2026-05-18-superpowers-integration-minimal.md, 2026-05-18-superpowers-integration.md). These are the planning artifacts that *describe* the current change; rewriting them would falsify their record of what was planned.
- `docs/working/` — 2 files, 7 references (hypothesis-backlog.md, reports/external-skill-audit.md)

Note: `docs/thoughts/failure-patterns.md` IS under `docs/thoughts/` but is explicitly NOT historical — it has live couplings to RPI and pr-prep and is rewritten by Task A.2 of the minimal plan. Treated separately.

## Failure-pattern library references

Per Task A.1 step 3 of the plan, every reference to `docs/thoughts/failure-patterns.md` and to the `FP-NNN` / "Failure-pattern grep" tokens is called out here. Task A.2 owns the actual edits to these references — Task A.3 must NOT touch them.

### Files containing failure-pattern-library references

| File | Line | Reference | Owner |
|---|---|---|---|
| docs/thoughts/failure-patterns.md | 3 | "Append-only one-line log of root-caused bugs from `workflows/bug-diagnosis.md`" — header comment naming bug-diagnosis as write-side | A.2 |
| docs/thoughts/failure-patterns.md | 9 | `Relevant paths: workflows/bug-diagnosis.md` — self-declared dead-link target after A.3 deletion | A.2 |
| docs/thoughts/failure-patterns.md | 77 | "When citing a matched pattern in a diagnosis log, commit message, or hypothesis, use the form `FP-NNN`. In a bug-diagnosis hypothesis, the source-tag form is `[from prior bug FP-NNN]`." | A.2 |
| workflows/pr-prep.md | 44–53 (advisory block) | Counts `fix(...)` commits vs. `FP-NNN` entries; current `echo` line points at `workflows/bug-diagnosis.md step 8` | A.2 |
| workflows/pr-prep.md | 55 | "return to `bug-diagnosis.md` step 8 and append the entry before opening the PR" — exact text A.2 replaces | A.2 |
| workflows/research-plan-implement.md | 117–148 | "Failure-pattern lookup (final sub-step of research)" sub-section — mandatory grep audit with `Failure-pattern grep:` token and `Done when` checkbox. Specifically line 119 names `bug-diagnosis.md` as the maintainer of the log. | A.2 |
| docs/thoughts/failure-patterns.md | 13 (not a bug-diagnosis line but failure-pattern-library context) | "Bug diagnosis step 2 greps this file" — describes the read-side using bug-diagnosis vocabulary | A.2 |
| docs/thoughts/failure-patterns.md (entire file) | — | The file's overall framing (header, schema, "When to read this file" section) is built around the bug-diagnosis loop. A.2 must rewrite the framing to match the new write-side (pr-prep on `fix(...)` commits) and read-side (RPI research-phase grep). | A.2 |

### "Failure-pattern grep" / `FP-NNN` audit token references

The audit handle `Failure-pattern grep:` and the entry token `FP-NNN` appear in:

- `workflows/research-plan-implement.md` lines 117–148 — defines the audit token, the recording requirement, and the `Done when` checklist row that gates step 2.
- `workflows/pr-prep.md` lines 40–60 — advisory check that counts `^\+- \*\*FP-[0-9]+\*\*` additions on the branch.
- `docs/thoughts/failure-patterns.md` schema body — defines `FP-NNN YYYY-MM-DD symptom:<...> cause:<...> fix:<...> ref:<...>`.

These are flagged for Task A.2 — they are NOT to be touched by Task A.3.

## Judgment calls and notes

1. **`docs/superpowers/plans/2026-05-18-superpowers-integration.md`** — This is the *superseded* (older, more ambitious) plan, but I marked all 28 references as Historical reference per the exclusion rule. If A.3 wants to be aggressive, this file could arguably be deleted outright, but that's outside Task A.1's scope. The minimal plan (`2026-05-18-superpowers-integration-minimal.md`) is the one that survives.

2. **`docs/reviews/self-eval-bug-diagnosis.md`** — The entire file is about the bug-diagnosis workflow's rubric scoring. Marked Historical. After A.3 deletes the workflow, this self-eval describes a workflow that no longer exists. That's fine — it's a dated artifact, and the file's title and "Evaluated: 2026-03-27" header make the temporal context obvious. Not for A.3 to touch.

3. **`docs/workflow-dependency-graph.md` line 16** (`bug-diagnosis ←──────→ RPI`) — Marked Routing reference. Note: systematic-debugging is a skill, not a workflow, so the graph's "Workflow Pivots" section may need a structural rethink rather than a one-token substitution. A.3 should choose: (a) replace `bug-diagnosis` with `superpowers:systematic-debugging` and accept that one node is now a skill, or (b) drop the row entirely (the bidirectional handoff is documented in CLAUDE.md's debugging defaults already).

4. **`docs/workflow-selection.md` line 9** — Marked Routing reference. The decision tree puts `bug-diagnosis` ahead of `divergent-design` and `research-plan-implement` for "Bug with a known area of code." The new row should either point to `superpowers:systematic-debugging` (and clarify it's a skill, not a workflow) or be deleted in favor of CLAUDE.md's debugging-defaults guidance. A.3's call.

5. **`CLAUDE.md` lines 30–43** — These are categorized as Composition-narrative-inside-workflow because they form a *block* (the "Debugging defaults" section) whose framing depends on bug-diagnosis being the canonical structured-debugging surface. The plan's Phase A diff (lines 110–125 of the plan) shows the new framing — the block should reference `superpowers:systematic-debugging` for the loop itself and keep the numbered principles as the local extension. A.3 should follow the plan-supplied diff verbatim.

6. **`workflows/research-plan-implement.md` line 21** — The "→ Bug Diagnosis" pivot row references bug-diagnosis-specific step names ("Fix and Verify steps"). The systematic-debugging skill does not necessarily structure itself in steps with those names. A.3 should rewrite the entire bullet, not just substitute the name. The simplest version: "→ Bug fixing in known code: invoke `superpowers:systematic-debugging` directly — it skips the plan approval gate and iterates rapidly between hypothesis and test."

7. **`workflows/codebase-onboarding.md` line 178** — Categorized as Composition note. The inline link `[workflows/bug-diagnosis.md](./bug-diagnosis.md)` will be a dead link after A.3 deletes the file. Recommendation: drop the bracketed link entirely — the sentence still makes sense referencing only the failure-pattern library.

8. **Counting note** — Many "files" in the matched list have multiple references each. The "Total files" count is 22; the "Total reference lines" count is 126. The per-category counts sum to 126 (matching total lines), not 22 (total files), because the categorization is per-reference, not per-file.

## Next step

Task A.3 (the actual redirect/delete pass) uses this inventory as its checklist. The categorization rules tell A.3 what action to take per row; the Failure-pattern library section reserves those references for Task A.2. The judgment-call notes above flag where A.3 needs to think harder than a mechanical substitution.
