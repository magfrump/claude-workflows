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

## Plan

Other choices, one line each:
- Concurrency: skills run sequentially within a skill (the generator's loop); up to three skills at once, since 15 GB is free and one `claude` is about 0.5 GB (brief item 4 allows "a few at once").
- Suites per skill: every file under `test/skills/` whose header is `# @needs-reports <skill>`, run with plain `bats` after that skill's reports.
- A failing suite on a fresh report is recorded below, not fixed (brief item 5).

## Ledger

| Skill | Fixtures | Failed (.failed) | Suites (pass/total files) | Tests failing | Tokens / turns |
|---|---|---|---|---|---|

## Findings (suites failing on fresh reports)

