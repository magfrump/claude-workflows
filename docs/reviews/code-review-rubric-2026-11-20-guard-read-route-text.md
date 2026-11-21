# Code Review Rubric

**Scope:** fix/guard-read-route-text vs main at 0423fe3b (full branch) | **Reviewed:** 2026-11-20 | **Status: 🟢 PASS** — iteration 1 found 0 red, 0 amber, 3 nits; all three fixed in 4fa2ea80, re-checked by the author (hook suites plus `test/link-claude-home-wiring.bats`, 143/143)

Iteration 1: one fresh general-purpose reviewer, single pass (k=1), no sub-critic panel: a deny-message sentence, two docstrings, one guide line and their tests; no change to what the guard decides. The reviewer stripped comments and strings from the hook diff to confirm the decision logic is unchanged, checked the Read tool is not gated by the guard's matcher, fact-checked the taint wording against `web-taint-mark.py` and F-021, checked the research doc's line citations at 0423fe3b and rubric row A2 of `docs/reviews/code-review-rubric-2026-09-23-ans-guard-q048-q050.md`, and mutated copies of the hook (sentence removed, caveat dropped, a stray script route added): each mutation failed the A1/A2 case, and the first two also failed the F-022 case.

## 🔴 Must Fix

| # | Finding | Domain | Severity | Source | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|---|

None.

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|

None.

## 🟢 Consider

| # | Finding | Source | Status |
|---|---|---|---|
| C1 | Research doc line numbers were the dispatch commit's, unmarked. | reviewer | Fixed: marked as at 0423fe3b |
| C2 | Research doc listed `WRITE_PRIMITIVE` as only `>`, `tee`, `sed -i`, `cp`/`mv` and `python3 -c`. | reviewer | Fixed: full list (`dd of=`, `truncate`, `install`, `rsync`, `node`/`perl`/`ruby` `-c`/`-e`) |
| C3 | "Put the check in a script file" did not say how; a Bash heredoc naming the path hits the same deny. | reviewer | Fixed: "write the check to a script file with the Write tool"; the reads-only caveat keeps A2's intent; tests updated |
| C4 | What the guard denies is unchanged; both F-022 shapes are still denied. | reviewer | Confirmed, no change |
| C5 | The sentence is conditional and true for project and global targets. | reviewer | Confirmed, no change |

## ⏭️ Skipped Core Critics

- security-reviewer, performance-reviewer, api-consistency-reviewer as separate dispatches: the one reviewer covered the diff (message text, comments, a guide line, tests) and the one security question, the A2 steering concern, which the research doc's design choice addresses.
