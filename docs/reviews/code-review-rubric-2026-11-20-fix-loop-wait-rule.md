# Code Review Rubric

**Scope:** fix/loop-wait-rule vs main at 5e335ef8 (full branch) | **Reviewed:** 2026-11-20 | **Status: 🟢 PASS** — iteration 1 found 0 red, 2 amber, 6 green; both ambers and one green fixed in the following commit, re-checked by the author against test 3 (11/11 bats)

Iteration 1: one fresh general-purpose reviewer, single pass (k=1), no sub-critic panel: a prompt-text change to one heredoc line plus its test, no trust boundary beyond the static `sh -c` body. The reviewer fact-checked the research doc and commit against the code and both source research docs, re-ran L2, ran the bats file and the hermeticity lint, and mutated each new clause on a git-archive copy (six mutations, each failed test 3).

## 🔴 Must Fix

| # | Finding | Domain | Severity | Source | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|---|

None.

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | "Wait 30 minutes at most in all" can read as a run total, stopping a loop after several review rounds that each returned. | Correctness | Medium | reviewer | for-author | none | Fixed: "Wait at most 30 minutes for any one subagent or job"; test 3 pins it | |
| A2 | The research doc's S6 thresholds counted two hand-backs as support, unlike the wait research's "zero or one". | Process | Low | reviewer | for-author | none | Fixed: zero or one supports, two inconclusive, three or more revert | |

## 🟢 Consider

| # | Finding | Source | Status |
|---|---|---|---|
| C3 | The trigger names pr-prep and code-review waits only, not a research subagent's. | reviewer | Won't-Fix: drafted scope (S3, when-to-wait stays with those docs); widen if such a hand-back is recorded |
| C4 | "(Claude Code refuses a subagent's report file)" overstates an inferred, name-based refusal. | reviewer | Fixed: "(Claude Code has refused subagents' report files)" |
| C5 | The `sh -c` body is static, the path arrives as `"$1"` with `./`; the escape prints a literal `$1`. | reviewer | Confirmed, no change |
| C6 | The stopped exit fits the marker parser and the other marker rules. | reviewer | Confirmed, no change |
| C7 | Every factual claim in the research doc and commit checked against code and sources. | reviewer | Confirmed, no change |
| C8 | Test 3 catches a regression of each new clause (six mutations). | reviewer | Confirmed, no change |

## ⏭️ Skipped Core Critics

- security-reviewer, performance-reviewer, api-consistency-reviewer as separate dispatches: the one reviewer covered the diff (one prompt line, its test, a doc), and the only shell text is a static `sh -c` body checked against CLAUDE.md's first Code rule.
