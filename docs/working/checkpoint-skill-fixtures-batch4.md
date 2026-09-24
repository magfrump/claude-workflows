# Checkpoint: skill-fixtures-batch4
Date: 2026-09-24
Branch: skill-fixtures
Research: docs/working/research-skill-fixtures-batch4.md
Plan: docs/working/plan-skill-fixtures-batch4.md

## Project state
- **Branch purpose**: add runnable fixture sets for the skills that had none (HC1)
- **Position in larger initiative**: batch 4 of 4; batches 1-3 merged at `68ffae7`
- **Blocked on**: nothing for the approved scope, which is implemented (ef05331..fa3c5c0). Q-059 (arithmetic-eval Bash grant) and Q-060 (code-review/draft-review depth) hold steps 5 and 9 only.

## Key findings
- Headless `claude -p --tools "Agent,Read"` dispatches sub-agents fine. The JSON/stream output reports `subagent_stats`. Sub-agents inherit the `--tools` restriction. [observed]
- The claude.ai MCP connector (Claude Docs create/update/delete) leaks into every fixture run, including `--tools ""`. `--strict-mcp-config` removes it. [observed]
- The arithmetic-eval `check.py` extracts cleanly with awk between `<<'AE_CHECK_EOF'` and `AE_CHECK_EOF`, and runs. [observed]
- Headless: Write is denied and Read is confined to cwd (FP-075/076). Tree fixtures must contain everything the skill reads, and prompts must say "print to stdout."
- Don't use `--bare` (FP-097).

## Plan
1. `--strict-mcp-config` in generate-reports, plus an argv test.
2. `FIXTURE_TRANSCRIPT=1` → stream-json sidecar, with the report extracted from the final `result`; `tool_called:` / `subagents_min:` checks.
3. `FIXTURE_MODE=tree` (directory fixtures, `fixture_base` hook, `REQUEST.md` → prompt).
4. `arithmetic-eval-gate.bats`: deterministic Mode 1 and check.py tests.
5. (Q-059 [2] only) arithmetic-eval LLM set with restricted Bash.
6. divergent-design set (tree; route check via Read of the workflow + `◇ step 1`).
7. self-eval set (tree; the real rubric plus synthetic siblings; table-row checks).
8. matrix-analysis set (inline, Agent; `subagents_min`) + `REPORT_PATH` fix in two format suites.
9. (Q-060 ≠ [1]) code-review/draft-review sets.
10. Update plan-skill-fixtures.md.

Order: `1 → [2, 3] → [4, 6, 7, 8] → 10`

## Invariants
- No Write/Edit in fixture runs, and the fixture name never reaches the model (generate-reports.bats).
- Every `fixtures/` dir has a runner.bash and a `<skill>-eval.bats`.
- KEY_CHECK patterns contain no `;`.
- No real report generation (memory run-a8-measurement-after-settling).

## File map
- `test/skills/generate-reports.bash`: steps 1-3
- `test/generate-reports.bats`: steps 1-3 tests
- `test/skills/eval-helpers.bash`: step 2 checks
- `test/skills/arithmetic-eval-gate.bats`: step 4 (new)
- `test/skills/divergent-design/`, `divergent-design-eval.bats`: step 6
- `test/skills/self-eval/`, `self-eval-eval.bats`: step 7
- `test/skills/matrix-analysis/`, `matrix-analysis-eval.bats`: step 8
- `test/skills/matrix-analysis-format.bats`, `draft-review-format.bats`: step 8 REPORT_PATH
- `docs/working/plan-skill-fixtures.md`: step 10

## Open questions
- Q-059, Q-060 (docs/working/questions.md)
- Sub-agents inherit `~/.claude/CLAUDE.md`, a hermeticity gap across all batches. Whether `--setting-sources` covers it is [assumed] no.
