# Research: why every health check warns "the shared harness changed since generation"

Brief: `docs/working/briefs/2026-11-20-stale-report-warnings.md` (research only; Paths: none).
Branch: `docs/stale-report-warnings`, dispatched at 9f55e405.

Failure-pattern grep: `rg -n -i 'stamp|stale report|warning' docs/failure-patterns.md` gives 1 hit, FP-022 (a setlocale warning breaking exact assertions), unrelated; no entry covers stamp or harness drift.
Failure-pattern skip: this branch has no fix(...) commits; it changes one research doc and the brief's Status line.

## Answer in one paragraph

The 81 warned stamps (in 11 skills) were written by the regeneration's dispatch 1 (956bb566 and c0d9f5ea), which ran on base 69587d02, before the web-tools grant (8abd0b51, 846eee77, merged 6c0563b5) changed `test/skills/generate-reports.bash`. Their harness line is the pre-grant hash. Dispatch 2 (0d51e240) merged main, grant included, and reran only fixtures whose gating lines (skill, runner, fixture) were stale. It said so: "Not rerun: the 9 skills whose stamps still match" (regeneration research doc, line 14). So the reports are older than the grant, and the check compares the right thing. But none of the 11 skills' runners offers WebSearch or WebFetch. For them the grant's only code path (`WEB_GRANT`) is empty, so the `claude` argv is byte-identical before and after it. The harness change cannot alter their output. Recommended fix: re-stamp the 81 harness lines (no headless runs). Regenerating gives the same end state for about 80 minutes of runs, and the model's run-to-run variation adds a churn risk.

## Evidence

### What the check compares (`test/skills/runner-contract.bash`)

- `report_stamp` (l. 223-230) writes four inputs: `skill`, `runner`, `fixture` and `harness`. `check_report_stamp` (l. 250-275) fails only on the first three (Q-071 [1], the owner's ruling that only a skill's own inputs gate freshness). A different `harness` line only calls `_stamp_warn` (l. 272-273), which prints `# WARNING:` on bats fd 3, even in passing tests.
- `_stamp_harness_hash` (l. 186-196) hashes `generate-reports.bash` and `transcript.jq` with comment and blank lines dropped, plus `declare -p RUNNER_ALLOWED_TOOLS` and `declare -f reset_runner_settings check_runner_settings`. It is one hash for the whole harness, not a per-skill one: any code-line change to `generate-reports.bash` changes it for every skill.
- The check runs inside `resolve_skill_report` (`test/skills/helpers.bash:51`) and the claim-report loader (`test/skills/eval-helpers.bash:69`). Format suites call them from `setup()` and eval suites from each test body (through `eval_fixture`), so either way they run once per test. So one stale stamp warns once per test that loads it, not once per report. That is how 81 stamps become the roadmap's 312 lines. I did not re-count the 312: that needs the per-skill suites, which the brief's command list leaves out.

### The stamps today

`rg --no-filename -o '^harness .*' -g '*.stamp' test/skills | sort | uniq -c`:

| Harness value | Stamps | Skills |
|---|---|---|
| `e1fffa7c…0dea53b` (pre-grant) | 81 | api-consistency-reviewer 8, architecture-review 6, business-plan-critique-unit-economics 7, code-fact-check 19, cowen-critique 7, design-space-situating 6, divergent-design 5, matrix-analysis 4, performance-reviewer 7, pre-mortem 7, self-eval 5 |
| `2c1d5c13…c73d9b` (current) | 49 | ai-personas-critique 7, architecture-review 1, arithmetic-eval 5, business-plan-critique-market-sizing 7, code-fact-check 1, dependency-upgrade 6, security-reviewer 8, ui-visual-review 8, what-if-analysis 6 |

`2c1d5c13…` is the hash the check computes today. Those 49 stamps do not warn, and no harness input has changed since they were written. `git log 69587d02..9f55e405 -- test/skills/generate-reports.bash test/skills/transcript.jq test/skills/runner-contract.bash` lists only 8abd0b51 and 846eee77. I did not recompute the hash myself, because the brief allows only `git`, `rg`, reads and the freshness suite.

### Which dispatch wrote which stamp

| Commit | Base has the grant? | Stamps added | Harness value |
|---|---|---|---|
| c0d9f5ea (dispatch 1, matrix-analysis proof) | no (parent chain from 69587d02) | 4 | all `e1fffa7c…` |
| 956bb566 (dispatch 1, 21 more skills) | no (`git merge-base --is-ancestor 6c0563b5 c0d9f5ea` fails) | 152 | all `e1fffa7c…` |
| 0608a8c7 (dispatch 2 merges main 81d1663a) | yes (6c0563b5 is an ancestor of 81d1663a) | — | — |
| 0d51e240 (dispatch 2, the 70 stale reports in 13 skills) | yes | 70 | all `2c1d5c13…` |
| b4f458c9 (fact-check, 23 reports) | yes | 23 | all `2c1d5c13…` |
| 577930d5 (holds back 5 failing skills) | — | removes moat, fact-check, tech-debt-triage, test-strategy, yglesias-critique | — |

All 11 warned skills were generated before the grant. Two skills are split because dispatch 2 reran one fixture in each: one in architecture-review and one in code-fact-check (of 7 and 20 that dispatch 1 wrote). The F2-F7 format fixes had changed those two fixtures' gating inputs. The brief says "the 12 other regenerated skills". The tree shows 9 skills fully on the current hash, plus the 2 split ones. The other regenerated skills (fact-check and the 4 held-back skills from 0d51e240) have no reports in the tree, so they cannot warn.

### Whether the grant can change these skills' output

The grant (diff `eb5b55c1..846eee77 -- test/skills/generate-reports.bash`) adds one behaviour. It sets `WEB_GRANT` to the names that appear in all three of: the runner's `FIXTURE_TOOLS`, `WebSearch|WebFetch`, and `RUNNER_ALLOWED_TOOLS`. It appends `--allowedTools "$WEB_GRANT"` only when that is non-empty. 846eee77 changed only comments. The other added lines are comments too, which the hash drops anyway.

The 11 runners' `FIXTURE_TOOLS` are `Read,Grep,Glob` (api-consistency-reviewer, architecture-review, code-fact-check, divergent-design, performance-reviewer, self-eval), `none` (business-plan-critique-unit-economics, cowen-critique, design-space-situating, pre-mortem) and `Agent` (matrix-analysis). `rg -n 'WebSearch|WebFetch' test/skills/*/runner.bash` matches only `test/skills/fact-check/runner.bash`. For all 11, `WEB_GRANT` is empty and the argv is unchanged. matrix-analysis's sub-agents inherit `--tools Agent`, which has no web tool.

The inputs the stamp does not cover (`workflows/divergent-design.md` and `docs/evaluation-rubric.md`, copied in by tree-mode runners) are a separate gap. Dispatch 2 already recorded them as unchanged since 69587d02. That gap does not cause this warning.

### Freshness suite

`timeout 600 bats test/skills/eval-helpers-freshness.bats` passes (33 of 33). It tests the check on a synthetic `demo` skill, not on the committed reports, so it neither shows nor rules out the warning.

## Options (divergent design)

Diagnosis: the warning is information, not a gate, by design (Q-071 [1]). The harm is noise: 312 lines on every run hide a new warning (S5's motive holds). Whatever the fix, it must keep the warning able to fire on a harness change that can alter output (H2: nothing present but inert), must add no recurring cost (S2, S10), and must reuse the stamp mechanism (S3).

| Option | What it means | Cost | Weakness |
|---|---|---|---|
| **[1] Regenerate** the 81 reports with `generate-reports.bash` | Fresh stamps from fresh runs | 81 headless runs. Dispatch 2 took 5,683 s for 93 runs, three at a time, so about 80 min at the same rate; no owner time | Same argv, so no information gained. Model variation can flip graded verdicts and turn green suites red with no input change. |
| **[2] Re-stamp** the harness line of the 81 stamps to the current hash, after confirming each one's skill, runner and fixture lines still pass | Stamps record that generation under today's harness would use the same argv | One small doc-backed commit; no runs; no owner time | The stamp asserts a harness the report did not run under. It is sound only with the argv argument above, which the commit body must carry. A later harness change that touches every skill warns again. |
| **[3] Narrow the hash**: hash the argv a skill's generation would build (or its `WEB_GRANT` and tool list) instead of the whole harness | A harness change warns only the skills it can affect | Code in `runner-contract.bash` and the generator, plus tests; one build loop | It duplicates the generator's argv logic in the stamp (against S3), or it needs a dry-run mode. The existing 81 stamps would still need re-stamping or a format bump (a format bump fails all 130, which is worse). |
| **[4] Aggregate the warning**: print one summary line per suite instead of one per test | Less noise per run | Small change to `_stamp_warn` callers | The warning is still always on, so it still hides a new one, just in fewer lines. It does not touch the cause. |
| [0] Status quo | Keep warning | none | The brief's motive: a warning on every run hides a new one. |

Pick: **[2], Path A (one option dominates).** It reaches [1]'s end state with no runs and no churn risk. [3] costs a build loop and still needs [2] for the existing stamps. It would pay only if harness changes that affect every skill keep landing. [4] treats the symptom. Revisit [3] if a second harness change leaves warnings behind that a re-stamp has to clear.

Other choices, one line each:
- Re-stamp scope: only the 81 stamps carrying `e1fffa7c…`, never a blanket rewrite. A stamp whose gating lines fail is regenerated instead.
- Script vs. hand edit: a one-time replacement of one literal hash with another, checked by the suites running warning-free. A new `--restamp` mode would be a standing way to silence the check, and S4's tested-script rule targets recurring steps.

## For the dev cycle

Suggested brief: **re-stamp the 81 pre-grant report stamps**.
- Goal: in the 81 `test/skills/*/output/*.stamp` files whose harness line is `e1fffa7cc309774f8e0138e4110d9683a84e88d86f643bbb9296d469e0dea53b`, replace that value with the current harness hash. Copy the value from an untouched current stamp (today `2c1d5c13a464cb4f8af9a996cf194501b0661017980e363f92b98a4247c73d9b`) and confirm it matches `report_stamp`'s output. First re-confirm that no runner among the 11 skills lists WebSearch or WebFetch, and that no harness input changed after 846eee77. If either check fails, regenerate those fixtures instead.
- Acceptance: `rg -l e1fffa7c -g '*.stamp' test/skills` prints nothing; each of the 11 skills' suites passes with no `shared harness … changed since generation` line; only harness lines change (`git diff --stat` shows only `.stamp` files, one line each). The commit body carries the argv argument from this doc.
- Paths: `test/skills/{api-consistency-reviewer,architecture-review,business-plan-critique-unit-economics,code-fact-check,cowen-critique,design-space-situating,divergent-design,matrix-analysis,performance-reviewer,pre-mortem,self-eval}/output/*.stamp`
- Policy: self-merge (generated test data, not on the floor).
- Cost: no headless runs and no owner time.
