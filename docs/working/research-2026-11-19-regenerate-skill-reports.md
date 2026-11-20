# Research: regenerate the skill eval reports

Brief: docs/working/briefs/2026-11-19-regenerate-skill-reports.md (at 69587d02)
Branch: measure/regenerate-skill-reports
Date: 2026-11-19

Failure-pattern grep: `rg -n '^- \*\*FP-' docs/failure-patterns.md | rg -i 'report|stamp|fixture|eval|headless|bare'` -> FP-097 (`--bare` drops subscription auth; generate-reports.bash already omits it), FP-172 (a failed generation leaves an empty report that absence-only checks pass; the generator's `.failed` marker covers it). Neither changes the plan: this branch runs the generator as it is.

## What I read

- `test/skills/generate-reports.bash` (header and body): runs `claude -p` per fixture in a fresh temp dir with `--restricted --safe-mode --strict-mcp-config`, writes `<fixture>.report.md`, a `.stamp` only on success, a `.failed` marker otherwise, and `<fixture>.transcript.jsonl` for runners with `FIXTURE_TRANSCRIPT=1`. Fixtures run one at a time within a skill.
- `test/skills/runner-contract.bash`: the runner allowlist and `report_stamp` / `skill_has_reports`.
- `docs/working/audit-test-constraint-2026-09-26.md` batch G: the gating and stamp fixes (T1-T6) that this regeneration finally exercises.
- `scripts/run-tests.sh` report gating: a `@needs-reports <skill>` suite runs only when that skill's `output/` holds a report.
- `.gitignore`: admits `*.report.md`, `*.stamp`, `*.failed` and `*.transcript.jsonl` under `test/skills/*/output/`.

## Findings before running

1. **code-review has no runner.** The brief's step 2 says to prove the pipeline on code-review's reports, but `test/skills/code-review/` holds only `rubric-current-format.md`; `code-review-format.bats` says "code-review has no fixture generator". The same holds for draft-review. So `code-review-format.bats` and `draft-review-format.bats` stay NOT RUN after this work, and so do `eval-helpers-gating.bats` and `test/scripts/run-tests.bats` (tagged, but they test the gating itself). The 23 runners cover 47 of the 51 tagged suites plus the two `dimensions.bats`.
   - Decision (one line, no 3-way choice): prove the pipeline on **matrix-analysis** instead, the smallest skill (4 fixtures), one changed tonight, and one that exercises the transcript path (`FIXTURE_TRANSCRIPT=1`, Agent dispatch). This keeps the brief's intent (prove before spending ~180 runs). Blocking on the wrong skill name was the other option and is dominated.
2. **Headless claude works here.** A probe (`claude -p --output-format json --tools "" --restricted --safe-mode --strict-mcp-config`, temp dir) returned `is_error` absent, `terminal_reason: completed`, model claude-opus-5-5. CLI 2.1.329.
3. **Tokens and turns.** The generator keeps only the report text for non-transcript runners, so tokens/turns are recorded only for transcript runners (matrix-analysis, divergent-design, arithmetic-eval), read from the stream's result event. Changing the generator to record them is out of scope.
4. **Transcripts are committed too.** They are generated files under `output/` that `.gitignore` admits and that the eval suites read (`tool_called:`, `subagents_min:`); without them those suites fail. Brief item 6 lists reports, stamps and `.failed`; transcripts fall in its "generated files under output/" scope.
5. Total fixtures across the 23 runners: 179, under the ~200-run stop line.
6. **fact-check's web tools are denied in every headless run.** Its 23 reports all came out "Unverified" with "I wasn't allowed to use web search or web fetch". A probe confirmed it: `claude -p --tools WebSearch,WebFetch --restricted --safe-mode` returned `permission_denials: [{"tool_name":"WebSearch",...}]`. `--tools` makes a tool visible but does not grant it; Read, Grep, Glob and Agent need no grant, WebSearch and WebFetch do, and `--restricted` ignores the settings files that could allow them. So fact-check's reports grade the generator, not the skill (finding F1 below).

## Plan

Other choices, one line each:
- Concurrency: skills run sequentially within a skill (the generator's loop); up to three skills at once, since 15 GB is free and one `claude` is about 0.5 GB (brief item 4 allows "a few at once").
- Suites per skill: every file under `test/skills/` whose header is `# @needs-reports <skill>`, run with plain `bats` after that skill's reports.
- A failing suite on a fresh report is recorded below, not fixed (brief item 5), and its reports are committed anyway: holding them back would hide the drift the regeneration exists to show, and leaving them red is what the brief asks for.
- fact-check's reports are **not committed** (kept outside the repo): every one is degraded by the permission denial in finding 6, so committing them would turn fact-check's suites red for a reason that is not the skill's. Its suites stay NOT RUN, as before. Committing them was the other option and is dominated: a red that blames the wrong thing.

## Ledger

Runs: 179 fixtures (4 matrix-analysis proof runs, then 175), three skills at a time, 9,878 s of generation in all. No run wrote a `.failed` marker, so the stop line (more than half of a skill's fixtures failed) never fired. "Suites" counts the skill's `@needs-reports` files that passed whole; "Tests failing" counts top-level cases (an eval case runs the format suite inside it, so one format slip can fail several eval cases). Tokens and turns exist only for the three transcript runners; the figures sum each transcript's last result event, which is the event the generator reads.

| Skill | Fixtures | Failed (.failed) | Suites (pass/total files) | Tests failing | Tokens / turns |
|---|---|---|---|---|---|
| matrix-analysis | 4 | 0 | 0/2 | 5 of 22 | turns 7, out tokens 19381, cost $1.52 |
| ai-personas-critique | 7 | 0 | 0/2 | 4 of 29 | - |
| api-consistency-reviewer | 8 | 0 | 2/2 | 0 of 26 | - |
| architecture-review | 7 | 0 | 1/2 | 2 of 29 | - |
| arithmetic-eval | 5 | 0 | 0/1 | 3 of 9 | turns 9, out tokens 5948, cost $0.33 |
| business-plan-critique-market-sizing | 7 | 0 | 1/2 | 2 of 25 | - |
| business-plan-critique-moat | 7 | 0 | 1/2 | 2 of 25 | - |
| business-plan-critique-unit-economics | 7 | 0 | 2/2 | 0 of 20 | - |
| code-fact-check | 20 | 0 | 2/3 | 1 of 69 | - |
| cowen-critique | 7 | 0 | 3/3 | 0 of 23 | - |
| dependency-upgrade | 6 | 0 | 1/2 | 2 of 22 | - |
| design-space-situating | 6 | 0 | 2/2 | 0 of 39 | - |
| divergent-design | 5 | 0 | 0/1 | 1 of 5 | turns 18, out tokens 34650, cost $1.36 |
| performance-reviewer | 7 | 0 | 2/2 | 0 of 25 | - |
| pre-mortem | 7 | 0 | 0/2 | 5 of 23 | - |
| security-reviewer | 8 | 0 | 0/2 | 3 of 26 | - |
| self-eval | 5 | 0 | 2/2 | 0 of 33 | - |
| tech-debt-triage | 6 | 0 | 1/2 | 2 of 22 | - |
| test-strategy | 6 | 0 | 1/2 | 1 of 25 | - |
| ui-visual-review | 8 | 0 | 0/2 | 5 of 37 | - |
| what-if-analysis | 6 | 0 | 0/2 | 4 of 28 | - |
| yglesias-critique | 7 | 0 | 2/3 | 1 of 24 | - |
| fact-check (not committed, F1) | 23 | 0 | 0/3 | 23 of 65 | - |

Totals for the committed 22 skills: 156 fixtures, 0 failed runs, 23 of 45 suite files pass, 43 failing cases. 6 skills pass whole: api-consistency-reviewer, business-plan-critique-unit-economics, cowen-critique, design-space-situating, performance-reviewer, self-eval (and every suite but one in code-fact-check and yglesias-critique).

## Findings (suites failing on fresh reports)

Not fixed here (brief item 5). Each names the failing case and what the report did.

- **F1 harness (fact-check):** WebSearch/WebFetch are offered by `--tools` but denied without a grant, so every fact-check report is all-Unverified and 23 cases fail. The generator would need a grant for the runner's web tools (for example `--allowedTools` limited to those names) before fact-check can be regenerated; that is a change to `test/skills/generate-reports.bash`, out of this brief's scope.
- **F2 cross-skill: field values carry trailing prose.** The vocabulary checks fail because a field holds the word and then an explanation: pre-mortem `**Plausibility:** Plausible. It depends on...` and `**Severity:** Medium to High` (pre-mortem-format 8, 9; eval tc-pm1, tc-pm4, tc-pm6); ai-personas-critique `**Severity:** Significant weakness (conditional...)` (format 12; eval tc-per1, tc-per3, tc-per7); business-plan-critique-moat `**Confidence:** Medium-High (strong mechanism...` (tc-moat7); market-sizing Confidence and Verdict (tc-mkt5, tc-mkt6); security-reviewer `**Confidence:** Low. This only matters if...` (tc-sec8); dependency-upgrade `**Recommendation:**` without the vocabulary word on the line (tc-dep3) and a missing `**Estimated effort:**` (tc-dep2).
- **F3 cross-skill: a preamble before the title.** matrix-analysis opens with "Stage 2 (evaluation) complete..." and "# Deliverable 1: Chat synthesis", so `assert_title_matches '^# .*Matrix.*Analysis'` fails on all four fixtures; security-reviewer tc-sec4 opens "Here's the report. I printed it here as you asked..." (format 1).
- **F4 arithmetic-eval:** in tc-ae1, tc-ae2 and tc-ae3 the one Bash call uses the Mode 1 wrapper "but the program differs from SKILL.md's (by AST)", so no Mode 1 value is counted.
- **F5 verdict or severity drift (skill judgment vs the expected verdict):** code-fact-check tc-c2.5 says Incorrect where Unverifiable is expected; architecture-review tc-arch6 reports Structural and Coupling findings on clean ports-and-adapters, and tc-arch7 (internal-only patch) gives no Dependency Map or Findings section; test-strategy tc-ts6 rates gaps high on a well-tested parser and gives 3 "What it verifies" fields for 7 tests; ui-visual-review tc-uv1/uv2 rate the planted Critical as Major, tc-uv6/uv7 miss the Minor fix, and a finding lacks a Recommendation line (format 16); what-if-analysis tc-wi6 tags a [REVERSIBILITY CLIFF] where none is expected; divergent-design tc-dd1 recommends without the `recommend [n] ... postgres` shape.
- **F6 what-if-analysis format:** no `**Assumption:**` entries under Assumptions Examined (format 14; eval tc-wi1, tc-wi4, tc-wi6).
- **F7 pattern misses:** business-plan-critique-moat tc-moat1 names the head start without the pattern's wording; tech-debt-triage tc-td2 misses the EOL-runway pattern and tc-td4 the `Carrying Cost: Medium` heading; yglesias-critique tc-ygl4's Boring Lever section lacks the word "lever".
- **Consequence for the health check:** these suites are `@category fast`, so `scripts/health-check.sh` gate 5 (bats) goes red on main once this lands, and stays red until each finding is fixed in its skill or test. That red is the measurement the brief asked for.

