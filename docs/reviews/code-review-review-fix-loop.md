# Code Review Rubric

**Scope:** `feat/review-fix-loop-workflow` vs `main` (4 files, 212 lines added, 13 removed) | **Reviewed:** 2026-03-24 | **Status: 🔴 DOES NOT PASS** — 1 red item(s) unresolved

---

## 🔴 Must Fix

Issues that must be resolved before merge. Draft cannot pass review with any red items unresolved.

| # | Finding | Domain | Location | Status |
|---|---|---|---|---|
| R1 | Broken relative link: `../../.claude/workflows/pr-prep.md` is incorrect from `workflows/review-fix-loop.md` — should be `pr-prep.md` (both files are in the same directory) | Fact-check | `workflows/review-fix-loop.md:3` | 🔴 Unresolved |

---

## 🟡 Must Address

Issues that must be fixed or acknowledged by the author with justification for why they stand. Each must carry a resolution or author note.

| # | Finding | Domain | Source | Status | Author note |
|---|---|---|---|---|---|
| A1 | "RPI produces a reviewed implementation" oversimplifies — RPI includes human review of the plan but not necessarily a code review pass on the output. The review-fix loop is what adds code review, making the claim slightly circular. Consider "RPI produces an implementation" or "RPI produces a plan-reviewed implementation." | Fact-check | Code fact-check (mostly accurate, medium confidence) | 🟡 Open | — |

---

## 🟢 Consider

Advisory findings from contextual critics, single-critic suggestions, and improvement opportunities. Not required to pass review.

| # | Finding | Source |
|---|---|---|
| C1 | `review-fix-loop.md` lives in `workflows/` alongside standalone workflows (RPI, spike, DD) but explicitly says "It should not be run as a standalone workflow." Consider either: (a) moving it to a `workflows/reference/` subdirectory, or (b) adding a brief "When to use" section that says "Do not use standalone — invoked as part of pr-prep Step 3." This would make its non-standalone nature visible from the file structure or its heading conventions. | API consistency |
| C2 | The upgrade from optional self-review ("optional but recommended") to required review-fix loop ("This is required, not optional") is a meaningful process change. The pr-prep description doesn't call this out — worth a note in the PR description or a commit message explaining the rationale for making review mandatory. | API consistency |
| C3 | The committed version has 4 anti-patterns in `review-fix-loop.md` while pr-prep Step 3e duplicates two of them (verifying findings, convergence ceiling). The anti-patterns section lacks framing text explaining its relationship to pr-prep Step 3, so readers encounter the same guidance in two places without understanding which is primary. | API consistency |

---

## ✅ Confirmed Good

Patterns, implementations, or claims confirmed correct by fact-check and/or critics.

| Item | Verdict | Source |
|---|---|---|
| Skills referenced (`/code-review`, `/self-eval`) exist and work as described | ✅ Confirmed | Code fact-check |
| `workflows/review-fix-loop.md` file exists at the path referenced by pr-prep | ✅ Confirmed | Code fact-check |
| Review artifacts output to `docs/reviews/*.md` as claimed, and code-review skill confirms overwrite-on-rerun behavior | ✅ Confirmed | Code fact-check |
| Tier table (Must Fix / Must Address / Consider) matches code-review rubric tiers exactly | ✅ Confirmed | API consistency |
| Step renumbering in pr-prep is internally consistent (no gaps, no duplicate numbers) | ✅ Confirmed | API consistency |
| Workflow composes existing skills without introducing new dependencies | ✅ Confirmed | API consistency |
| No security surface in diff (documentation only) | ✅ Confirmed | Security reviewer |
| No performance surface in diff (documentation only) | ✅ Confirmed | Performance reviewer |

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or carry an author note. 🟢 items are optional.

---

## Methodology Note

The Agent tool was unavailable in this environment, so sub-agent dispatch was not possible. All four analyses (code fact-check, security reviewer, performance reviewer, API consistency reviewer) were conducted directly by the orchestrator. No contextual critics were triggered (diff is under 10 files / 500 lines, no dependency manifests changed, no source-without-test pattern).
