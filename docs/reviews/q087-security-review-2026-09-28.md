Commit: 182d143

# Security Review — review/q087 (final confirming pass)

**Scope:** full branch, `git diff main...HEAD` in `/workspace/.claude/wt-q087` (HEAD 182d143), excluding `docs/reviews/q087-*` outputs
**Date:** 2026-09-28
**Based on:** `docs/reviews/q087-code-fact-check-report.md` (k=3 merged, final pass), summarized in the shared block

## Trust Boundary Map

The diff is prose and a bats test. It adds no code that executes. The only "boundaries" are the review pipeline's own assurance channels: which inputs decide how many fact-check draws guard the merge gate, and which log rows can suppress a later finding.

```
B1: [orchestrator invocation flags (--loop-pass)] → [SKILL.md Stage 1 replication rule] → [fact-check k (1 or 3) guarding the merge gate]
B2: [docs/reviews/override-log.md rows]            → [SKILL.md Step 3.5 match rules]     → [findings skipped as "Re-flagged settled decisions"]
B3: [skills/code-review/SKILL.md prose]            → [test/skills/code-review-factcheck-replication.bats greps] → [CI green/red on the k rule]
B4 (removed): [rubric file state (no `Loop closed at` line)] → [final-pass classification] → [fact-check k]
```

Input-source classification:

```
S1: --loop-pass flag                 — request-time (set by the invoking agent per pr-prep 3d) — trusted toward k selection; caller-controlled, so it is a process input, not an integrity control
S2: docs/reviews/code-review-rubric-* — runtime-mutable (rewritten every pass)  — no longer consulted for k (B4 removed); still consulted for scope and short-circuit marker (unchanged)
S3: docs/reviews/override-log.md rows — runtime-mutable (appended by the fix pass) — trusted toward triage suppression only after the Step 3.5 match; untrusted as evidence
S4: SKILL.md prose                    — deploy-time (committed)                  — trusted; pinned by S5
S5: bats test regexes                 — code-constant                             — trusted
```

Summary: the change moves the k decision off rubric-file state (B4, removed) onto the invocation flag alone (B1), and adds four override-log rows (B2) plus one struck row. No input from outside the repository or its agents reaches any of these. The questions are assurance questions: can the final pass still run at k=1, and do the new rows suppress anything real?

## Findings

No findings.

Notes (reviewed and cleared, not findings):

- **B1, final pass run at k=1 by passing `--loop-pass`.** The flag alone sets k (`skills/code-review/SKILL.md:452-453`: "The flag alone sets k, so no rubric check is needed to tell the two apart."). A caller that passes `--loop-pass` on what it means as the final pass gets k=1. But such a run is by definition not the final confirming pass. Only a run without the flag writes `Loop closed at` (`:126-128`: "Only the final confirming pass (the one run to declare the branch clean) runs without `--loop-pass` … when it is clean, it adds `Loop closed at <reviewed HEAD sha>`"). pr-prep 3d already tells the author to run the confirming pass without the flag (`workflows/pr-prep.md:250`). The Gate 1h consumer in `scripts/self-improvement.sh:1605-1616` treats anything other than `k=3*` as advisory "degraded", so a k=1 final pass is visible there. Cleared.
- **B4 removal is a net assurance gain.** The old text classified the final pass by "the branch's canonical rubric existing without a `Loop closed at` line". That was file state any pass rewrites (S2). The prior u4 override row recorded a real misclassification from it (standalone re-review drawn at k=1). The flag rule removes that dependency.
- **B2, new override-log rows (`docs/reviews/override-log.md:80-83`).** B4 and A3 concern a commit-message count and a questions-doc status. C5 is pre-existing and deferred. C4 (Won't-Fix) covers a *missing absence-test*. Under Step 3.5 rule 3 (`SKILL.md:173`, "describes substantively the same claim"), it would not match a later finding that stale final-pass k=1 wording has *reappeared*: that is a different claim, a regression rather than a coverage gap. None of the rows suppresses a security-class finding. The struck u4 row (`:131`) keeps its `Defer` verdict with the strikethrough. Step 3.5 does not say how struck rows match; C5 already records that gap. The row describes a condition that the new rule makes unreachable, so it cannot suppress a live finding.
- **B3, test regex changes (`test/skills/code-review-factcheck-replication.bats:153-157`).** `.--loop-pass.` and `loop.s` use `.` to match a backtick and an apostrophe. They are slightly permissive and pin the positive rule. The test does not pin the Dependencies bullet or the absence of stale wording (C4, Won't-Fix). A regression there would be doc drift, not a bypass of any runtime control. No repo test or script still greps the old phrase `applies to standalone`.

Primitive sweep: no dangerous primitives in scope. The diff contains no exec, fetch, deserialization, SQL, HTML, path construction or eval. The bats changes are `grep -qiE` over extracted skill text.

## Endorsement Claims

- **Claim:** In the Stage 1 replication paragraph, the only condition that selects k=1 is the `--loop-pass` flag. No rubric-file check remains in that paragraph.
  **Location:** `skills/code-review/SKILL.md:443-456`
  **Evidence:** read-static
  **Verified:** Read the whole replication paragraph (`:443-456`) and the Dependencies bullet (`:20`); the diff deletes the "recognized by the branch's canonical rubric existing without a `Loop closed at` line" clause.
  **Not verified:** the short-circuit section's mechanic 6 (`:739`) still says "The run still implies `--no-gate` and k=1". That is scoped to `--loop-pass` runs and was not traced for every other place k is mentioned (e.g. Step 7's plan count, fact-check claim 20).
  **route: code-fact-check**
- **Claim:** A rubric gets `Loop closed at` only from a run without `--loop-pass`, so every closed loop's final pass is one that the new rule assigns k=3.
  **Location:** `skills/code-review/SKILL.md:126-128`, `:450-453`
  **Evidence:** read-static
  **Verified:** Step 1's loop-pass default range paragraph (`:112-134`, read in full) and the replication paragraph.
  **Not verified:** whether the orchestrator's actual rubric-writing step (Stage 3 / references/rubric.md) writes the line only under that condition.
  **route: code-fact-check**

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| — | No findings | — | — | — | — |

## Overall Assessment

The change raises the fact-check draw count on the loop's final confirming pass. It also replaces a classification based on mutable rubric state with the invocation flag, which strengthens the merge gate's assurance. The new override-log rows do not suppress security-relevant findings. The test changes pin the positive rule with no runtime-bypass exposure. There are no findings within the code paths read, and the endorsement claims are pending execution verification.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the output path your role section names, structured per your role skill, every finding/claim carrying verbatim Evidence with `path:line`, and a Goal-Alignment Note appended.
- Answered: yes
- Out of scope: the merge conflict with current `main` (`docs/decisions/log.md` row 62/63, `override-log.md`) and the duplicate Q-087 archive on `answers-2026-09-28`. Both are orchestrator escalations from Stage 1 with no security bearing.
- Escalate: nothing
