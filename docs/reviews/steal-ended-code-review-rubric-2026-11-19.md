# Code review rubric: build-loop.sh --prompt --steal --ended (brief 2026-11-19-steal-ended)

Branch `fix/steal-ended`, reviewed at f0df51ba (round 1) and e2d917cc (round 2). One fresh read-only reviewer covering code-fact-check (header, usage, comments and SKILL text against the code), security and trust boundary (S1: honest same-uid slips only), API consistency of the new flag and output line, and test coverage against the research doc's Tests bullet (`docs/working/research-2026-11-19-steal-wait-research.md`, "For the dev cycle").

| # | Area | Round 1 | Finding | Fix | Round 2 |
|---|---|---|---|---|---|
| 1 | `steal()` / `--ended` parse correctness | green | BASH_REMATCH group 3 is the lock time; set -e and pipefail safe; unreadable tip time fails closed; only a dispatch lock of this brief with the exact LOCKTIME and a tip before ENDTIME is taken | none | green |
| 2 | SKILL step 7/10, record template | amber | a dispatch printed but not started had no `10.` line form carrying ENDTIME, nor a step 10 instruction to pass `--ended` | not-started form on the `10.` line and in steps 7 and 10 | green |
| 3 | header wording (`lock UTC TIME`) | amber | "should this loop end unseen" read opposite to the spec | "should this loop be seen to end with no marker" | green |
| 4 | readers of the old line 2 | green | no reader missed outside `test/scripts/build-loop-dispatch.bats`; orchestrator pin still passes | none | green |
| 5 | tests: in-window commit | amber | the take case's commit predated the lock, so a commit between LOCKTIME and ENDTIME being accepted was not shown | hand-set lock at -5 min, commit at -3 min, ENDTIME now | green |
| 6 | tests: coverage, flakiness | green | every Tests-bullet item covered; times minutes apart or hand-set, no same-second race | none | green |
| 7 | security | green | values reach only `[[ ]]` and `date -d` argv; residuals are the research's accepted ones | none | green |
| 8 | research doc | green | claims match the code; line numbers were base-commit positions | "at 04bf7b11" added | green |

Result: 0 red, 0 amber after round 2. Loop ends clean.
