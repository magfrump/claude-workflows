# Research: re-stamp the 81 pre-grant report stamps

Date: 2026-11-20 · Brief: `docs/working/briefs/2026-11-20-restamp-pre-grant-reports.md` · Branch: `fix/restamp-pre-grant-reports` (dispatched at 977c3f70)

## Mechanism (re-read)

- `report_stamp` (`test/skills/runner-contract.bash`) writes a `format 2` line and `skill`, `runner`, `fixture`, `harness` hash lines. `check_report_stamp` fails on a changed skill/runner/fixture line and only warns on a changed harness line.
- The harness hash (`_stamp_harness_hash`) covers `generate-reports.bash` and `transcript.jq` with comment and blank lines dropped, plus `declare -p RUNNER_ALLOWED_TOOLS` and `declare -f reset_runner_settings check_runner_settings`.
- The grant (8abd0b51, then comment-only 846eee77) added one block to `generate-reports.bash`: build `WEB_GRANT` from the names in both `FIXTURE_TOOLS` and `RUNNER_ALLOWED_TOOLS` that are `WebSearch` or `WebFetch`, and append `--allowedTools "$WEB_GRANT"` to `claude_args` only when it is non-empty.

## Preconditions (brief criterion 2)

### P1: no runner of the 11 skills offers WebSearch or WebFetch — holds

```
$ rg -n 'WebSearch|WebFetch' test/skills/{api-consistency-reviewer,architecture-review,business-plan-critique-unit-economics,code-fact-check,cowen-critique,design-space-situating,divergent-design,matrix-analysis,performance-reviewer,pre-mortem,self-eval}/runner.bash; echo "rg exit $?"
rg exit 1
```

Each runner assigns `FIXTURE_TOOLS` once (`rg -n FIXTURE_TOOLS test/skills/<skill>/runner.bash`): `Read,Grep,Glob` for api-consistency-reviewer, architecture-review, code-fact-check, divergent-design, performance-reviewer and self-eval; `none` for business-plan-critique-unit-economics, cowen-critique, design-space-situating and pre-mortem; `Agent` for matrix-analysis.

### P2: no harness change after 846eee77 — holds

```
$ git log --format=%h 846eee77..HEAD -- test/skills/generate-reports.bash test/skills/transcript.jq test/skills/runner-contract.bash
(no output)
```

`runner-contract.bash` holds the runner settings the hash covers (`RUNNER_ALLOWED_TOOLS`, `reset_runner_settings`, `check_runner_settings`). Over the whole span, `git diff --stat 8abd0b51^ HEAD -- <the same three files>` shows only `test/skills/generate-reports.bash | 27 +++`, the grant's additions.

### P3: the current hash is 2c1d5c13… — holds

Computed by sourcing each commit's `runner-contract.bash` and calling `_stamp_harness_hash` on that commit's copies of the three files (probe script in the scratchpad), plus the live tree:

```
8abd0b51^ e1fffa7cc309774f8e0138e4110d9683a84e88d86f643bbb9296d469e0dea53b
8abd0b51  2c1d5c13a464cb4f8af9a996cf194501b0661017980e363f92b98a4247c73d9b
846eee77  2c1d5c13a464cb4f8af9a996cf194501b0661017980e363f92b98a4247c73d9b
HEAD      2c1d5c13a464cb4f8af9a996cf194501b0661017980e363f92b98a4247c73d9b
live tree 2c1d5c13a464cb4f8af9a996cf194501b0661017980e363f92b98a4247c73d9b
```

So the old hash is exactly the parent of the grant commit, and the grant commit is the only change between it and today's value.

## Why the generated output is unchanged (the argv argument)

For these 11 runners no name in `FIXTURE_TOOLS` is `WebSearch` or `WebFetch`, so the new loop leaves `WEB_GRANT` empty and `claude_args` gets no `--allowedTools`. The loop's only other effect is temporary variables it unsets. Nothing else in the hashed inputs changed, so the argv and environment each run builds are the same before and after the grant, and so is the generated output. Re-stamping records that fact; it does not hide a change.

## Counts

| | Before | After |
|---|---|---|
| stamps with `harness e1fffa7c…` | 81 | 0 |
| stamps with `harness 2c1d5c13…` | 49 | 130 |
| `changed since generation` lines in `scripts/health-check.sh` output | 312 (see note) | 0 |

Per skill (old-hash stamps): api-consistency-reviewer 8, architecture-review 6, business-plan-critique-unit-economics 7, code-fact-check 19, cowen-critique 7, design-space-situating 6, divergent-design 5, matrix-analysis 4, performance-reviewer 7, pre-mortem 7, self-eval 5.

## Tests

- `scripts/confine-tests.sh --probe`: exit 3, first line `confine-tests: NO CONFINEMENT PRIMITIVE AVAILABLE — refusing to run.` So the touched suites run through `scripts/run-tests.sh` and the health check, plus `scripts/hermeticity-lint --root .`.
- Before (tree at 977c3f70): `timeout 580 scripts/health-check.sh` printed 312 `changed since generation` lines, all the harness warning, then hit the 580 s timeout on this loaded host (exit 124) while still running test files. The count matches the 312 the brief and the earlier research report, and the pre-grant stamps are the only stamps that warn, so it is the full count.
- After (commit 00d51833): `rg -l e1fffa7c -g '*.stamp' test/skills` prints nothing (exit 1). The 23 suites of the 11 skills (`scripts/run-tests.sh --all --jobs 4 <the 23 files>`): exit 0, 314 ok, 0 not ok, 0 `changed since generation` lines. `scripts/hermeticity-lint --root .`: exit 0, 150 files, no unstubbed network spawns. `scripts/health-check.sh` (timeout 1700): exit 0, `All checks passed.`, 0 `changed since generation` lines.
- `git diff --stat 977c3f70 00d51833`: 81 files changed, 81 insertions, 81 deletions, all `test/skills/<one of the 11>/output/*.stamp`; every removed line is the old harness line and every added line the new one.
- Review: one independent code-fact-check subagent re-derived the hashes, the runners' tool lists and the diff shape, and ran `check_report_stamp` on all 81 changed stamps (81 pass, no warning). Verdict green; two amber notes, neither a defect: it did not run the health check itself, and the hash cannot speak for inputs outside it (such as the CLI version), which the commit does not claim.

## Design choices

- How to edit: a one-off replacement of the full 64-hex old value with the new one, applied only to the files `rg -l` lists for the old hash. Only one viable option (regeneration is out of scope and costs headless runs), so no divergent design.

## Gotchas

- Failure-pattern grep: no matches found (`rg -n -i 'stamp|stale report|harness hash' docs/failure-patterns.md`).
- Failure-pattern skip: the commits re-stamp generated test data after a verified no-op harness change; no slip happened that a future loop should be warned about.
- zsh reads `"$c:t…"` as a history modifier: `git show "$c:test/..."` in an interactive zsh call mangles the path. Use `${c}:` or a bash script.
