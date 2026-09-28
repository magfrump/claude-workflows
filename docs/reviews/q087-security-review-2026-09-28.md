Commit: 27d483b

# Security Review — review/q087 (Q-087 [2]: k=3 on the loop's final confirming pass)

**Scope:** `git diff main...HEAD` in `/workspace/.claude/wt-q087` (one commit, 27d483b): `docs/decisions/log.md` (+1 row), `skills/code-review/SKILL.md` (four places), `test/skills/code-review-factcheck-replication.bats` (one test extended)
**Date:** 2026-09-28
**Based on:** `docs/reviews/q087-code-fact-check-report.md` (Stage-1, k=1 loop pass)

## Trust Boundary Map

The diff contains no executable code other than one added bats assertion. The security-relevant surface is the review pipeline itself: the fact-check replication count is part of the gate that decides what merges.

```
B1: [orchestrator's pass classification (--loop-pass flag present/absent)] → [Stage 1 replication rule, SKILL.md:443-456] → [k=1 or k=3 fact-check → merge-blocking 🔴 verdicts]
B2: [merged fact-check report **Replication:** header]                     → [Gate 1h parse, scripts/self-improvement.sh:1581,1605-1617] → [advisory NOTE / validation log]
B3: [SKILL.md text (repo file)]                                            → [bats grep -qiE, test/...replication.bats:155] → [CI pass/fail]
```

Input sources:

```
S1: --loop-pass flag            — request-time (set by pr-prep's loop / the orchestrator) — trusted as an honest pass classification; UNTRUSTED as assurance evidence (self-declared)
S2: canonical rubric file state ("Loop closed at" line) — runtime-mutable (written by prior passes) — informational only after this diff; no longer decides k
S3: SKILL.md content            — code-constant (tracked file)  — trusted (test input; no exec/eval sink)
S4: **Replication:** header     — runtime-mutable (written by the fact-check pass) — advisory sink only (Gate 1h never blocks on it)
```

What changes: before this diff, every pass of a review-fix loop, including the final confirming pass, ran the fact-check at k=1. After it, k is chosen by S1 alone: `--loop-pass` → k=1, anything else → k=3. Replication only increases, and the default when the flag is absent is the higher-assurance k=3, so the rule fails safe. S2 (the rubric's `Loop closed at` line), which is runtime-mutable, still appears as a "recognized by" clause (SKILL.md:452-454). But both outcomes of that check now give k=3: a final pass is k=3 and a standalone review is k=3. That removes any way to downgrade replication by tampering with the rubric state. Before this diff, a rubric without `Loop closed at` classified a non-flag pass as a loop final pass, which ran at k=1.

## Findings

No findings.

Checks performed:
- **Move 5 (invert the control): which passes still get k=1?** Only runs carrying `--loop-pass` (SKILL.md:444-445, "Every `--loop-pass` of a review-fix loop … runs **k=1**"). The flag is documented as "Never pass it on the terminal pass" (SKILL.md:251-252). A mislabelled terminal pass would get k=1 and also skip the panel. That exposure predates this diff and is unchanged by it.
- **Move 3 (error path): Gate 1h.** `scripts/self-improvement.sh:1605-1617` treats `k=3*` as nothing-to-report and anything else as an advisory NOTE. More final passes reporting k=3 means fewer advisory NOTEs. The gate stays advisory, so it does not block on k=1 before or after this diff. No weakening.
- **Move 11 (bypass enumeration) on the added test guard** (`test/skills/code-review-factcheck-replication.bats:155`). It is a documentation-presence pin, not a security guardrail. Candidates: (a) the `.` in `loop.s` matches any character, so wording such as "loops final" still passes, which is harmless because the intent is the apostrophe. (b) The phrase could survive while the surrounding sentence is negated, since this is a known limitation of grep pins shared by every sibling assertion. (c) `stage1_flat` bounds the extraction at `### Fact-Check Gate`, and a separate test (bats:136-139) guards that anchor. None of these is a security bypass. The test reads a tracked file and passes a fixed pattern to `grep -qiE`, so there is no eval, no interpolation of untrusted input, and no exec sink. I executed it: `timeout 120 bats -f 'replication is loop-aware' …` → `ok 1`.
- **Assurance scope note (not a finding).** `docs/decisions/log.md:85` keeps the first loop pass at k=1 ("`--loop-pass` passes stay k=1"). The first pass is full-branch only on a loop's first iteration, so the first full draw of untouched code is single-sample. The final pass now gives that code a k=3 draw before merge. The merge gate is therefore at least as strong as before on every path.

Untested bypass candidates: none. The only guard the diff adds is a doc-pin test, and its candidates are dispositioned above.

## Endorsement Claims

- **Claim:** After this diff, the only pass class that runs the fact-check at k=1 is a run carrying `--loop-pass`. Every run without the flag (standalone, or a loop's final confirming pass) is directed to the k=3 protocol.
  **Location:** `skills/code-review/SKILL.md:443-456`
  **Evidence:** read-static
  **Verified:** Read the whole "Replication is loop-aware" paragraph and the surrounding "Why three" section. :444-445 reads "Every `--loop-pass` of a review-fix loop … runs **k=1**", and :451-452 reads "The **k=3 protocol below applies to standalone single-pass reviews and to a loop's final confirming pass**".
  **Not verified:** the rest of the file may state k differently. Step 7's agent count (SKILL.md:259-260, "3 fact-check replicates", pre-existing) and the short-circuit mechanic's "implies … k=1" (SKILL.md:739) are the nearest hops. Both apply to `--loop-pass` runs or are unchanged, but consistency across the file was not executed.
  **route: code-fact-check**

- **Claim:** The added bats assertion introduces no command-injection or eval sink: it pipes a tracked file's extracted text into `grep -qiE` with a literal pattern.
  **Location:** `test/skills/code-review-factcheck-replication.bats:155-156`
  **Evidence:** executed
  **Verified:** Read lines 141-161 (the whole `@test`) and `stage1_flat` usage, then ran the test under `timeout`, which passed.
  **Not verified:** the body of `stage1_flat`/`stage1` helper definitions above :136 was read only at the anchor check (:136-139).

## Primitive sweep

Primitive sweep: no dangerous primitives in scope.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| — | No findings | — | — | — | — |

## Overall Assessment

The change strictly raises fact-check replication on the pass that immediately precedes merge, and it chooses k from the explicit `--loop-pass` flag, defaulting to the higher k. It therefore fails safe, and it removes the older dependency of k on runtime-mutable rubric state. The test change is a benign grep pin. I found no findings within the code paths I read. Endorsement claims are pending execution verification for the whole-file k-consistency claim. The fact-check report's Incorrect (log row 63's falsifier attribution) and Stale items are documentation accuracy issues, not security issues, and they do not change this assessment.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the output path your role section names, structured per your role skill, every finding/claim carrying verbatim Evidence with `path:line`, and a Goal-Alignment Note appended.
- Answered: yes
- Out of scope: I did not re-verify the documentation-accuracy items the fact-check owns (row 63 falsifier attribution, row 60 staleness, the Q-087 archive commit). They are not security-relevant.
- Escalate: nothing
- Decisions I made: I treated the review pipeline's merge gate as the trust boundary, as the brief directed. I left out the pre-existing "mislabelled terminal pass gets k=1" exposure as a finding because this diff does not change it.
