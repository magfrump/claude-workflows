Commit: 182d143

# API Consistency Review — `review/q087` (final confirming pass)

**Scope:** full branch, `git diff main...HEAD` at 182d143, excluding `docs/reviews/q087-*` outputs
**Date:** 2026-09-28
**Based on:** `docs/reviews/q087-code-fact-check-report.md` (k=3 merged, final pass)

## Baseline Conventions

- **`code-review` replication contract.** Every run's k is fixed by its flags. Before this branch, the final pass was the exception: it was classified by rubric state (a canonical rubric with no `Loop closed at` line meant k=1). The merged report's header is a parsed contract: `**Replication:** k=3`, `k=2 (one replicate failed)` or `k=1 (loop pass, decision 031)` (`skills/code-review/SKILL.md:448`, `:607-613`). Gate 1h reads it (`scripts/self-improvement.sh:1581`) and treats anything other than `k=3*` as a degraded or absent replication, advisory (`:1605-1618`).
- **Invocation from workflows.** `workflows/pr-prep.md:244` and `:250-254` delegate k to the skill ("`--loop-pass` also sets the fact-check replicate count … code-review's SKILL.md owns both"). `workflows/review-fix-loop.md:7` names the code-review skill as the owner of `--loop-pass`.
- **Decision-record amendments.** A header bullet `**Superseded in part (noted YYYY-MM-DD)**` or `**Amended in part (noted …)**` is used (precedents: `docs/decisions/030-lightweight-review-path.md:11`, `docs/decisions/021-reviewer-context-management.md:24`). Decision-log rows mark an in-place amendment inline as `**Amended YYYY-MM-DD (Q-NNN [n]):**` (precedent: `docs/decisions/log.md:76`, row 53).
- **Override log.** New rows go at the top (`skills/code-review/references/override-log.md:35`; the HTML comment in `docs/reviews/override-log.md`). Stale rows are kept and struck through in the `Finding` cell (`skills/code-review/SKILL.md:1260`).
- **Replication test naming.** `@test` titles state the rule under test and assertions grep `stage1_flat` for literal phrases (`test/skills/code-review-factcheck-replication.bats:141-161`).

## Name-Pattern Audit

This branch adds no new public names: no flags, no header fields, no marker lines and no functions. It changes what one existing flag means for k, adds one decision-log row and one decision-record note, and adds and strikes override-log rows. The table covers the new or changed identifiers that consumers see.

| New / changed name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `--loop-pass` (now the only thing that sets k) | CLI flag semantics | `--full`, `--range`, `--no-gate` | `skills/code-review/SKILL.md:100-110`, `:739` | Consistent: a flag-driven rule, with no rubric-state inference |
| `**Replication:** k=3` on the final pass | parsed header value | `k=1 (loop pass, decision 031)`, `k=2 (one replicate failed)` | `skills/code-review/SKILL.md:448`, `:609` | Consistent: existing vocabulary, no new value |
| `decision log 63` / `(decision log 63, Q-087 [2])` citation | doc cross-ref | `decision 031`, `decision 032 #4`, `log #48` | `skills/code-review/SKILL.md:20`, `docs/decisions/030-lightweight-review-path.md:11` | Consistent |
| `**Amended in part (noted 2026-09-28)**` | decision-record header note | `**Superseded in part (noted 2026-09-26)**` | `docs/decisions/030-lightweight-review-path.md:11`, `021-…:24` | Consistent: same shape, and "Amended" is the right verb for a narrowing |
| `**Amended 2026-09-28 (Q-087 [2]):**` inside row 60 | log-row amendment | row 53's `**Amended 2026-09-27 (Q-070 [1], Q-077):**` | `docs/decisions/log.md:76` | Consistent |
| `@test "replication is loop-aware: … k=3 standalone and on the final pass"` | test title | the same test's former title | `test/skills/code-review-factcheck-replication.bats:141` | Consistent |

## Findings

No findings.

Consumer-contract trace (move 3), for the record:

- **Gate 1h.** Before this branch, a gate run in a worktree that held an open canonical rubric from the worker's own loop could be classed as a final pass. It then emitted `**Replication:** k=1 (loop pass, decision 031)`, which Gate 1h reports as "degraded". The gate prompt passes no `--loop-pass` (`scripts/self-improvement.sh` has no `loop-pass` match), so now it always gets k=3 and `k=3*` matches (`:1605`). This narrows a false advisory. It does not change the contract.
- **Loop passes.** They still emit `k=1 (loop pass, decision 031)` (`skills/code-review/SKILL.md:448`), unchanged. The workflows delegate k to the skill, so neither `pr-prep.md` nor `review-fix-loop.md` needs to change. `pr-prep.md:250-254` already says to run the confirming pass without `--loop-pass`, and that is the input the new rule keys on.
- **Stale wording.** No final-pass k=1 wording is left in `SKILL.md`, `references/rubric.md` or the workflows. The remaining `k=1` mentions are loop-pass or short-circuit scoped (`SKILL.md:739`, `:1033`, `:1279`) or historical (`:456`).
- **Log numbering.** Row 63 follows row 61 on this branch. Row 62 exists on `main`, so the number is correct after the merge. The merge conflict itself is the orchestrator's escalation, not an API finding.

## What Looks Good

- **k keys on one explicit input** (the flag), not on inferred rubric state. This removes the ambiguity the u4 override row recorded (`skills/code-review/SKILL.md:453-454`: "The flag alone sets k, so no rubric check is needed"). route: code-fact-check
- **The Dependencies bullet, the Stage 1 paragraph, Step 1's cost note and Important Reminders all say the same thing** (`SKILL.md:20`, `:131-133`, `:443-456`, `:1278-1281`). Each cites decision log 63.
- **The decision 031 amendment follows the header-note convention** of 030 and 021, and row 60's inline `**Amended …:**` follows row 53.
- **The struck u4 override row keeps its original columns** and puts the strikethrough in `Finding` only, as `SKILL.md:1260` prescribes. The new rows sit at the top of the table.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---|---|---|---|
| — | No findings | — | — | High |

## Overall Assessment

The change is consistent with the consumer-facing surface. The `--loop-pass` flag now fully determines fact-check k. The parsed `**Replication:**` vocabulary is unchanged, and Gate 1h now sees `k=3` on non-loop runs where it could see a spurious `k=1` before. The workflows that call the skill already delegate k to it, so they need no edits. The decision-log, decision-record and override-log edits follow repo precedent. The only cross-branch concern is the merge conflict with `main`'s row 62, which the orchestrator already holds as an escalation.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the output path your role section names, structured per your role skill, every finding/claim carrying verbatim Evidence with `path:line`, and a Goal-Alignment Note appended.
- Answered: yes
- Out of scope: the merge conflict with `main` (rows 62/63, override-log), which is already the orchestrator's escalation. Step 7's "3 fact-check replicates" agent count (fact-check claim 20), which predates this branch.
- Escalate: nothing
