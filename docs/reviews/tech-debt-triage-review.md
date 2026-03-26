# Tech Debt Triage: Foregrounding Tests in RPI

**Branch:** `feat/foreground-tests` vs `main`
**Scope:** 15 files, 807 insertions, 593 deletions
**Date:** 2026-03-26

---

## Summary Ranking

| # | Item | Nature | Carrying Cost | Fix Cost | Recommendation |
|---|------|--------|--------------|----------|----------------|
| 1 | Review artifacts overwritten with branch-specific content | Structural | Medium | Low | Fix before merge |
| 2 | Freshness metadata stripped from review artifacts | Structural | Low | Low | Fix opportunistically |
| 3 | Decision log numbering gap (2-5 missing) | Naming | Low | Low | Carry intentionally |
| 4 | RPI growing toward prose density ceiling | Structural | Low | Medium | Defer and monitor |
| 5 | No usage evidence for new test specification format | Testing | Low | Low | Carry intentionally |

---

## Item 1: Review artifacts overwritten with branch-specific content

**Location:** `docs/reviews/api-consistency-review.md`, `code-fact-check-report.md`, `code-review-rubric.md`, `cowen-critique.md`, `fact-check-report.md`, `performance-review.md`, `security-review.md`, `verification-rubric.md`, `yglesias-critique.md`

**Nature:** Structural — review artifact lifecycle

The 11 modified review files in `docs/reviews/` previously contained analysis of the `feat/r1-skill-output-schema-validation` branch (and related work). This branch overwrites them with new reviews scoped to `feat/foreground-tests`. The old reviews — which documented findings about the BATS test suite, helper patterns, schema validation, etc. — are replaced entirely. After merge, the review history for the earlier feature will only exist in git history, not in the working tree.

**Carrying Cost: Medium.** If anyone references these review artifacts to understand past decisions or findings (e.g., the FINDINGS_BODY over-inclusion bug noted in the old tech-debt triage, the Impact/Severity mismatch in the performance test), they won't find them at the expected path. The reviews are nominally "disposable" (like working docs), but some contained actionable findings that were not yet resolved. The old fact-check report had 14 claims checked with specific accuracy ratings; the old API consistency review documented BATS test conventions. These are not trivially re-derivable.

**Fix Cost:** Low scope, low risk. Options: (a) version review artifacts by branch or date (e.g., `api-consistency-review-r1-schema.md`), (b) archive old reviews before overwriting, (c) accept that git history is the archive and document that convention.

**Urgency Triggers:** Someone tries to follow up on a finding from a previous review cycle and can't find it. The old tech-debt triage noted an Impact/Severity bug that becomes a blocker "when someone generates a performance review report and runs the tests" — that finding is now gone from the working tree.

**Recommendation: Fix before merge.** At minimum, the prior tech-debt-triage findings (Impact/Severity bug, FINDINGS_BODY scoping) should be tracked somewhere persistent — either a separate file or an issue — since they describe actual bugs in `test/skills/`. Broader convention for review artifact lifecycle (overwrite vs. archive) would prevent this recurring but is a separate decision.

---

## Item 2: Freshness metadata stripped from review artifacts

**Location:** All modified `docs/reviews/*.md` files

**Nature:** Structural — convention compliance

The old review artifacts had YAML frontmatter with `Last verified` dates and `Relevant paths` lists, per the freshness tracking convention described in `guides/doc-freshness.md` and referenced in CLAUDE.md. The new versions drop this frontmatter entirely. For example, `self-eval-research-plan-implement.md` lost:

```yaml
---
Last verified: 2026-03-23
Relevant paths:
  - workflows/research-plan-implement.md
---
```

**Carrying Cost: Low.** Review artifacts are closer to "disposable" than "long-lived" in the doc taxonomy. The freshness tracking convention was added to these files in commit `06f53b2` on main, so it's relatively recent. If review artifacts are treated as regenerated per-branch (which the overwrite pattern in Item 1 implies), freshness tracking adds no value — they're always "fresh" for the current analysis and stale for everything else. However, dropping the metadata without deciding the convention leaves ambiguity about whether reviews should have it.

**Fix Cost:** Low. Either re-add the frontmatter (mechanical) or document that review artifacts are exempt from freshness tracking (one line in a guide).

**Urgency Triggers:** A future session follows the `doc-freshness.md` heuristic, expects `Last verified` on review artifacts, and gets confused by its absence.

**Recommendation: Fix opportunistically.** Clarify whether review artifacts need freshness metadata. If they're regenerated per-feature-branch, they probably don't. Either way, make the convention explicit rather than leaving it implicit.

---

## Item 3: Decision log numbering gap (2-5 missing from log.md)

**Location:** `docs/decisions/log.md`

**Nature:** Naming — numbering convention

The decision log jumps from entry 1 to entry 6. Entries 2-5 exist as full decision records (`002-critic-style-code-review.md` through `005-validation-step-self-improvement.md`) but were never added to the log table. The log was created at decision 1 (per commit history), and decisions 2-5 predate or were concurrent with its creation, so they were never back-filled.

**Carrying Cost: Low.** The log table says "use this for one-line decisions where the context and rationale fit in a sentence or two" and "use a full record instead" for complex decisions. Decisions 2-5 all have full records and arguably don't need log entries. The gap is cosmetic — anyone looking for decision 3 would find `003-critic-moves-in-divergent-design.md` in the directory listing.

**Fix Cost:** Low. Add 4 rows to the table. No risk.

**Urgency Triggers:** None foreseeable. The numbering is clear from the directory listing.

**Recommendation: Carry intentionally.** The log's purpose is lightweight decisions that don't warrant full records. Decisions 2-5 have full records. Back-filling would be correct but isn't necessary. If it bothers someone, it's a 2-minute fix.

---

## Item 4: RPI growing toward prose density ceiling

**Location:** `workflows/research-plan-implement.md` (173 lines on main, 202 lines on branch)

**Nature:** Structural — document maintainability

The RPI workflow grew by 29 lines (17%) in this branch. The new test specification section in step 3 adds a table template, a 4-item taxonomy, diagnostic expectation guidance, a security note, and a complexity escape valve. Step 5 adds a test-first gate with a human checkpoint. The document is now 202 lines of dense procedural prose.

This isn't a problem yet. But the RPI workflow is the most-referenced document in the system — it's the default workflow, invoked from CLAUDE.md, and acts as the integration point for spikes, DD, onboarding, task decomposition, and pr-prep. Every addition increases the cognitive load on both humans reading it and LLMs following it.

**Carrying Cost: Low.** 202 lines is manageable. The test specification section is well-structured (table + taxonomy + guidance + escape valve). The test-first gate is concise. No immediate readability problem.

**Fix Cost: Medium** (if it becomes necessary). Extracting sections into referenced sub-documents (e.g., moving the test taxonomy to a shared guide referenced by both RPI and test-strategy) would require careful cross-referencing and risks fragmenting the workflow's self-contained readability. The "inline vs. reference" tradeoff is real — inline keeps everything visible; references keep the document short but require readers to follow links.

**Urgency Triggers:** (a) RPI crosses ~300 lines, at which point the document is competing with its own length for the reader's attention. (b) The test taxonomy in RPI drifts from the fuller taxonomy in `skills/test-strategy.md`, creating an inconsistency. (c) LLMs start truncating or skipping sections because the document is too long for their effective attention.

**Recommendation: Defer and monitor.** No action needed now. Watch for the triggers above. If RPI continues to grow with future features, consider extracting the test taxonomy and diagnostic guidance into a shared reference (perhaps expanding `skills/test-strategy.md` to serve double duty) and replacing the inline content with a cross-reference.

---

## Item 5: No usage evidence for new test specification format

**Location:** `workflows/research-plan-implement.md` (step 3 test specification, step 5 test-first gate)

**Nature:** Testing — process validation

The self-eval (`docs/reviews/self-eval-research-plan-implement.md`) explicitly flags this: "the new test specification format has zero usage evidence yet: no plan doc in `docs/working/` contains the new table format, and the test-first gate (step 5) has not been exercised on a real implementation task." The branch adds process steps that are prescriptive but unvalidated.

**Carrying Cost: Low.** The format is reasonable and the escape valve ("for simple features, this section can be brief") prevents it from being burdensome. If it turns out to be awkward in practice, it can be revised. The risk is that the format calcifies into convention before anyone discovers it doesn't work well for certain common cases.

**Fix Cost:** Low. Use it on a real task and see what happens. Revise based on experience.

**Urgency Triggers:** The format is followed rigidly on a real task and produces friction (table columns don't map to the actual information the human wants to express, diagnostic expectations are hard to specify in advance, etc.) without anyone questioning whether the format needs revision.

**Recommendation: Carry intentionally.** This is expected for any new process addition — it ships untested and gets validated through use. The escape valve is the key mitigation. The self-eval already flags this gap, which means future evaluators will look for usage evidence. No action needed beyond being willing to revise after first real use.
