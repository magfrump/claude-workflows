Commit: 04c0746

# Code Review Rubric

**Scope:** `skill-fixtures` vs `answers-2026-09-20`. **Pass 1 of a split review: harness code only** (40 files: `generate-reports.bash`, `eval-helpers.bash` and their bats suites, `arithmetic-eval-gate.bats`, `health-check.sh`/`.bats`, `.gitignore`, 22 `runner.bash`, 10 `*-format.bats`). Pass 2 (fixture data: `fixtures/`, `eval-criteria.md`, `expected-verdicts.bash`, `*-eval.bats`, ~10k lines) is deferred. | **Reviewed:** 2026-09-24 | **Status: 🟡 CONDITIONAL PASS** — 7 amber item(s) awaiting resolution or justification

Run shape:
- **Fact-check:** k=3 on opus, merged most-severe-wins into `code-fact-check-report-skill-fixtures.md`. 45 claims: 26 V · 8 MA · 2 Stale · 3 I · 6 U. Agreement 40/45.
- **Critics:** security, performance, api-consistency, architecture and tech-debt-triage, dispatched in parallel on opus. test-strategy was not selected: the changed source is test infrastructure and ships with its own tests.
- **Delivery mode: self-read.** The diff (80 KB, ~20k tokens) was within the inline-diff-only budget, but agents read it from the scope spec rather than having the orchestrator transcribe it into eight prompts.
- **Deviations from the skill's letter:**
  - Agents read their SKILL.md files instead of receiving pasted copies.
  - Stage 2.5 was not dispatched separately. The two routed security endorsements rest on executed Stage-1 claims (FC 21's guard log, FC 22's argv). The canary probes they ask for need live `claude` calls; see A2/A3.

---

## 🔴 Must Fix

None.

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Location | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|---|
| A1 | **A failed generation scores as a pass on every clean-negative fixture.** The absence-only checks (`no_severity:`, `no_verdict:`, `no_field:`, `no_pattern:`) pass on an empty report. `format_check` skips on it, and a skip exits 0. `generate-reports.bash` writes an empty report on every failure path (`\|\| true`, `\|\| : > report`). So a dead `claude` passes all 14 negative controls (tc-sec7, tc-sec8, tc-arch6, tc-per7, …). Executed: `eval_fixture security-reviewer tc-sec7…` against a zero-byte report → `ok 1`. Fix: `eval_fixture` fails on an empty report. | API / Tests | Inconsistent (executed) | api-consistency #1 | `test/skills/generate-reports.bash:212` — `> "$out_path" 2>/dev/null \|\| true` | for-author | — | 🟡 Open | — |
| A2 | **Inline mode runs `claude` in the real repo, and matrix-analysis grants `Agent` there.** Whether sub-agents inherit `--tools` was never probed (FC 30, Unverifiable). Agent types with `*` tools could read `expected-verdicts.bash` or write the real checkout. The cwd also loads the repo's CLAUDE.md. Fix: run inline mode in an empty `mktemp -d` too. | Security / Architecture | Medium (security F3); Coupling (architecture F1) | security-reviewer F3; architecture-review F1; FC Escalations | `test/skills/matrix-analysis/runner.bash:5` — `# Sub-agents inherit the same tool list, so they cannot read the repo either;` | for-author | — | 🟡 Open | — |
| A3 | **The no-cheat guarantee in repo/tree mode rests on cwd placement.** The header claims the model "cannot reach expected-verdicts.bash". Read/Grep/Glob take absolute paths, and no probe has checked that `-p` confines them (FC 19, Unverifiable). Fix: a canary probe, and a CLI-enforced deny rule if reads escape. | Security | Medium (Low confidence); Unverified-High-Risk | security-reviewer F2; FC 19 | `test/skills/generate-reports.bash:48-50` — `# the working directory holds only the fixture, so the model cannot reach` | for-author | — | 🟡 Open | — |
| A4 | **The Write/Edit guard is an exact-token denylist.** `Read, Write`, `Write(*)`, `write`, `MultiEdit`, `NotebookEdit` and `Bash` all pass it (executed). `CLAUDE_FLAGS` is appended unvalidated. No committed runner is misconfigured today. Fix: a host-owned allowlist of tool tokens, plus `--disallowedTools` for the write-capable tools. | Security / Fact-check | Incorrect (medium); Medium | FC 21 (r2 Incorrect, r1/r3 MA); security-reviewer F1; architecture F1; tech-debt D1 (Convergence ×4) | `test/skills/generate-reports.bash:89-90` — `case ",$FIXTURE_TOOLS," in` / `*,Write,*\|*,Edit,*)` | for-author | — | 🟡 Open | — |
| A5 | **The runner contract is only validated on a paid run.** The fast test "every committed fixture set has a runner the generator accepts" only checks that the file exists (FC 2, Incorrect-high, unanimous). A runner with a bad mode or tools fails only when `claude` is called. Fix: extract `validate_runner` and have the fast test source every committed runner through it. | Architecture / Tests | Coupling; Incorrect (high), test-name | architecture F2; FC 2; api #12 | `test/generate-reports.bats:278` — `[ -f "$skill_dir/runner.bash" ] \|\| missing+=("$(basename "$skill_dir")")` | for-author | — | 🟡 Open | — |
| A6 | **Stale or wrong harness comments.** "in both modes" (three now; FC 16, Stale). "--tools stays last … must not swallow the next flag" gives the wrong reason (FC 27, Incorrect-medium; bats :126 too). eval-helpers arg docs name only fact-check/code-fact-check (FC 40, Stale). Other FC MA items: REQUEST.md is copied then removed, `.fixture-*` also removes dirs, "inline runs in the real repo" means the caller's cwd, the pandas test name tests `json.load`, and the security-reviewer runner says "no git history". | Docs | Stale; Incorrect (medium), comment-only; Mostly Accurate | FC 16, 17, 27, 38, 40, 41, 42, 6; tech-debt D3; api #7 | `test/skills/generate-reports.bash:32-33` — `# neutral name is what fixture_prompt receives in both modes.` | for-author | — | 🟡 Open | — |
| A7 | **The stub `claude` in `generate-reports.bats` scans the whole working directory on every inline call.** `find .` from the repo root lists 395k files into a 37 MB line. Measured: 13.9 s from /workspace vs 1.3 s from the scratchpad, about 10% of the `--fast` gate. Fix: `cd "$TEST_TMPDIR"` in `setup()`. | Performance | Medium (executed) | performance-reviewer F1 | `test/generate-reports.bats:22` — `printf 'FILES: %s\n' "\$(find . -path ./.git -prune -o -type f -print \| sort \| tr '\n' ' ')"` | for-author | — | 🟡 Open | — |

---

## 🟢 Consider

| # | Finding | Domain | Severity | Source | Location | Status |
|---|---|---|---|---|---|---|
| C1 | **The user's own hooks fire inside fixture runs.** `dd-routing-reminder.sh` matches tc-dd1's REQUEST.md and injects the workflow path the fixture tests whether the model finds unaided (executed). `log-usage.sh` writes fixture runs into `~/.claude/logs/usage.jsonl`, inflating the usage telemetry. | Security / eval validity | Low (executed) | security-reviewer F4 | `test/skills/generate-reports.bash:159` (argv has no hook isolation) | 🟢 Open |
| C2 | A fixture name with a dot but no real extension leaks its tail into `subject.<ext>` (e.g. `tc-2.4-inaccurate` → `subject.4-inaccurate`). Latent: no committed fixture has one. | Security | Informational | security F6; FC 15/41 | `test/skills/generate-reports.bash:146` | 🟢 Open |
| C3 | An aborted generation leaves the previous report on disk, and it gets scored as current. Fix: `rm -f "$report_path"` alongside the transcript. | Security / Tests | Informational | security F7 | `test/skills/generate-reports.bash:137` | 🟢 Open |
| C4 | `CLAUDE_FLAGS`/`CLAUDE_MODEL` are passed through word-split and unvalidated. They are operator-controlled. | Security | Informational | security F5 | `generate-reports.bash:210-211` | 🟢 Open |
| C5 | Check-name drift: `subagents_min` vs `min_claims`; `_match` has two meanings; leading-word vs whole-line matching differs across checks; `None`/`none`/`high` placeholder case varies. | API | Minor | api #2-#5 | `test/skills/eval-helpers.bash` | 🟢 Open |
| C6 | Runners locate repo files three ways (`$REPO_ROOT`, the private `$SCRIPT_DIR`, `BASH_SOURCE`), and are sourced into the generator's global scope. | API / Architecture | Minor; Coupling (part of F2) | api #6; architecture F2 | `test/skills/self-eval/runner.bash:23` | 🟢 Open |
| C7 | Fixture sets depend on live repo files (the DD workflow, the evaluation rubric, personas.md) with no declared dependency or provenance hash. | Architecture | Minor | architecture F3 | runners with `fixture_base` | 🟢 Open |
| C8 | `generate_one` has grown wide (three modes + transcript), and the `claude` pipeline is duplicated at :197-201 and :208-212. The summary line counts only fact-check headings, so it prints "0 claims" for 20 of 22 skills. | Tech debt | Fix opportunistically | tech-debt D2 | `test/skills/generate-reports.bash:197-212` | 🟢 Open |
| C9 | Once any report exists, all 22 eval suites join the `--fast` gate, and each `format_check` starts a nested bats (~20 s, extrapolated). | Performance | Low | performance F2 | `test/skills/eval-helpers.bash:134-137` | 🟢 Open |
| C10 | The `generate-reports.bats:74-76` empty-`--tools` test fails with `CLAUDE_MODEL` exported (not env-isolated). | Tests | Mostly Accurate | FC Escalations (r2) | `test/generate-reports.bats:74` | 🟢 Open |
| C11 | Other minor items: the report/transcript format is defined in three places; there are 22 near-duplicate runners (carry); overlapping assert helpers (carry); hard-coded title windows (defer); the redundant `${REPORT_PATH:-}` in two format suites; `field_values` loosens `assert_verdict`. | Various | Minor / Informational | architecture F4; tech-debt D4-D6; api #10, #11 | various | 🟢 Open |

---

## ↩️ Considered Overrides

No prior overrides matched this diff.

---

## ✅ Confirmed Good

| # | Claim | Evidence | Backing |
|---|---|---|---|
| G1 | A stale transcript never pairs with a fresh report, on any generator path. | `generate-reports.bash:137` — `rm -f "$transcript_path"` | FC 25 (executed, k=3 unanimous; scope covers claude failure, jq failure and non-transcript mode) |
| G2 | `jq -rR 'fromjson? …'` keeps the report when a non-JSON line is present. Strict `jq` exits 4 and loses it. | `generate-reports.bash:224` | FC 28 (executed; d700f62's tests failed pre-fix) |
| G3 | `arithmetic-eval-gate.bats` tests the live SKILL.md text, and all three mutations b5bf458 names fail a test. | `test/skills/arithmetic-eval-gate.bats:16-28` | FC 5 (executed) |
| G4 | `eval_fixture` fails the call on any failing check, under `run` and in conditionals. | `eval-helpers.bash` eval_fixture loop | FC 10 (executed) |

---

## ⚠️ Unverified Findings

- Whether `--strict-mcp-config` removes the claude.ai connectors under `--tools ""` and inside sub-agents (FC 23). The only recorded probe used `--tools Read`.
- Whether `claude -p --tools ""` means no tools (FC 24).
- Whether real stream-json output matches the synthetic transcript shape used by the transcript tests (FC 9).

---

## ⏭️ Skipped Core Critics

All core critics ran; no skips applied.

---

## 🧩 Composition check

| Cluster | Fragments | Disposition |
|---|---|---|
| `generate-reports.bash:48-94` (tool safety) | FC 19, 21; security F1-F3; architecture F1; tech-debt D1 | distinct defects: architecture F1 already states the joint root and fix (host-owned allowlist + empty cwd for inline). No unstated root. |
| `generate-reports.bash:157-158` + `generate-reports.bats:126` | FC 27; api #7; tech-debt D3 | distinct defects: one comment, each fragment complete. |
| `generate-reports.bats:272-281` | FC 2; architecture F2; api #12 | distinct defects: same test, fix stated in architecture F2. |
