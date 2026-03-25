# Validation Gate Reference

The self-improvement loop validates every implementation branch before merging to main. A single bad merge poisons subsequent rounds (later branches fork from main), so validation is the highest-leverage quality control.

This guide documents all 7 gates in execution order. Gates run sequentially — the first failure rejects the branch and skips remaining gates.

**Source:** `self-improvement.sh` lines 456–639
**Design rationale:** `docs/decisions/005-validation-step-self-improvement.md`

---

## Pipeline overview

| Gate | Name | Phase | Type | Can skip? |
|------|------|-------|------|-----------|
| 1a | Commit count | 1 (Structural) | Deterministic | No |
| 1b | Diff size cap | 1 (Structural) | Deterministic | No |
| 1c | File scope | 1 (Structural) | Deterministic | No |
| 1d | Critical file protection | 1 (Structural) | Deterministic | No |
| 1e | BATS tests | 1 (Structural) | Deterministic | Yes (no test dir or no bats) |
| 1f | Shellcheck | 1 (Structural) | Deterministic | Yes (no .sh files or no shellcheck) |
| 1g | Self-eval | 3 (LLM) | Claude-driven | Yes (no skills/workflows changed) |

Gates record results via `record_gate()` to the round's JSON log file, which is persisted to `docs/working/round-N-report.json` and appended to `docs/working/round-history.json`.

---

## Gate 1a: Commit count

**What it checks:** The branch has at least one commit beyond main.

**Rationale:** A branch with zero commits means implementation failed silently — the Claude session started but produced nothing. Merging an empty branch is a no-op but wastes a merge slot and pollutes logs.

**Fail message:** `no commits on branch`

**Common failure patterns:**

| Pattern | Cause | Fix |
|---------|-------|-----|
| Claude session timed out | Task was too large or ambiguous for a single session | Break into smaller tasks with clearer scope in `tasks.json` |
| Worktree setup failed | Git worktree creation error (e.g., branch already exists) | Check for stale worktrees/branches from prior aborted runs |

---

## Gate 1b: Diff size cap

**What it checks:** Total lines changed (insertions + deletions) does not exceed 500.

**Rationale:** Large diffs indicate scope creep. They're harder to review, more likely to introduce regressions, and more likely to conflict with parallel branches. The 500-line cap keeps changes focused and mergeable.

**Fail message:** `diff too large (N lines, max 500)`

**Common failure patterns:**

| Pattern | Cause | Fix |
|---------|-------|-----|
| Implementation agent rewrote existing files | Task description was too broad | Constrain `description` in tasks.json to a specific change, not a rewrite |
| Generated test fixtures inflated the diff | Verbose test data | Use compact fixtures; consider generating at test runtime instead |
| Touched many files for a cross-cutting concern | Task inherently requires wide changes | Split into multiple tasks, each touching a subset of files |

---

## Gate 1c: File scope enforcement

**What it checks:** Every file in the branch diff is either (a) listed in the task's `files_touched` array in `tasks.json`, or (b) under `docs/working/` (always allowed).

**Rationale:** The `files_touched` declaration is a planning contract. It forces the idea-generation step to anticipate what files will change, and it prevents implementation from silently expanding scope. Without this gate, an implementation agent might "helpfully" refactor unrelated files.

**Fail message:** `files outside declared scope:\n  <file1>\n  <file2>`

**Common failure patterns:**

| Pattern | Cause | Fix |
|---------|-------|-----|
| Implementation created ancillary files (e.g., helper scripts) | Agent decided to factor out shared logic | Add the additional files to `files_touched` in the task definition, or inline the logic |
| Modified CLAUDE.md or other config files | Agent updated docs to reference new feature | Either add the config file to `files_touched` or handle the cross-reference in a separate task |
| Review artifacts written outside `docs/working/` | Self-eval or review output landed in `docs/reviews/` | Ensure review outputs go to `docs/working/` during implementation; move to `docs/reviews/` in a follow-up |

### Worked example: `self-eval-skill` task (Round 1)

The `self-eval-skill` task declared `files_touched` as:
```json
["skills/self-evaluation.md", "docs/reviews/"]
```

If the implementation agent also created a helper script at `scripts/run-eval.sh` or modified `CLAUDE.md` to document the new skill, Gate 1c would reject:

```
REJECTED: files outside declared scope:
  scripts/run-eval.sh
  CLAUDE.md
```

**Fix options:**
1. **Expand the declaration** — add the needed files to `files_touched` before the round runs.
2. **Restructure the implementation** — keep the helper logic inside the skill file itself rather than factoring it out.
3. **Use `docs/working/`** — put auxiliary outputs there (always allowed), then promote them in a later task.

**Key insight:** Gate 1c uses `grep -qF` (fixed-string match), so declaring `docs/reviews/` in `files_touched` matches any file path containing that string. But declaring `skills/self-evaluation.md` requires an exact filename match — `skills/self-eval.md` would not match.

---

## Gate 1d: Critical file protection

**What it checks:** None of these files were deleted: `self-improvement.sh`, `docs/evaluation-rubric.md`, `CLAUDE.md`.

**Rationale:** These are bootstrap files. Deleting them breaks the loop itself or removes the quality criteria it depends on. Modifications are allowed — only deletion triggers rejection.

**Fail message:** `deleted critical file: <filename>`

**Common failure patterns:**

| Pattern | Cause | Fix |
|---------|-------|-----|
| Agent renamed a critical file | Attempted to reorganize repo structure | Rename via a two-step approach: add new file first, then update references, keeping the original |
| `git mv` on critical file | Move counts as delete + add | Same as rename — keep the original path |

---

## Gate 1e: BATS tests

**What it checks:** If a `test/` directory exists in the worktree and `bats` is installed, all BATS tests pass.

**Rationale:** Catches regressions in tested functionality. Skips gracefully when tests don't exist (common for docs-only tasks) or bats isn't installed.

**Fail message:** `bats tests failed`

**Recording states:** pass / fail / skip

**Common failure patterns:**

| Pattern | Cause | Fix |
|---------|-------|-----|
| Existing tests broke due to changed file paths | Implementation moved or renamed files that tests reference | Update test fixtures/paths to match the new structure |
| New tests fail on first run | Test was written against expected output that doesn't match actual | Run tests locally before committing; fix assertions |
| Tests pass locally but fail in worktree | Relative path assumptions broken in worktree context | Use `$BATS_TEST_DIRNAME` or absolute paths in test setup |

---

## Gate 1f: Shellcheck

**What it checks:** All `.sh` files in the branch diff pass `shellcheck` static analysis.

**Rationale:** Prevents unquoted variables, syntax errors, and common bash anti-patterns. Shell scripts in this repo (especially `self-improvement.sh` and `health-check.sh`) are critical infrastructure — a shellcheck error in a merged script can break the entire loop.

**Fail message:** `shellcheck failed: <filename>`

**Recording states:** pass / fail / skip

**Common failure patterns:**

| Pattern | Cause | Fix |
|---------|-------|-----|
| SC2086: unquoted variable | `$VAR` instead of `"$VAR"` | Quote all variable expansions: `"$VAR"` |
| SC2046: unquoted command substitution | `$(cmd)` instead of `"$(cmd)"` | Quote: `"$(cmd)"` |
| SC2034: unused variable | Variable assigned but never referenced | Remove the variable or use it; if intentional, add `# shellcheck disable=SC2034` |
| SC2155: declare and assign separately | `local var=$(cmd)` masks return code | Split: `local var; var=$(cmd)` |

### Worked example: Shellcheck failures in Round 1

The `self-improvement.sh` script itself was the target of shellcheck validation during the R1 observability implementation (`feat/r1-self-improvement-observability`). The code review (`docs/reviews/code-review-r1-observability.md`) identified:

- **JSON via string interpolation** — building JSON with `echo "{\"key\": \"$val\"}"` instead of `jq`. Shellcheck flags unescaped quotes and word splitting. **Fix:** switched to `jq -n --arg` / `--argjson` for all JSON construction.
- **Unquoted variables in conditionals** — `if [ $COUNT -eq 0 ]` fails if `$COUNT` is empty. **Fix:** quote: `if [ "$COUNT" -eq 0 ]`.
- **Useless use of cat** — `cat file | grep pattern` flagged as UUOC (SC2002). **Fix in commit 6b46d59:** replaced with `grep pattern file` or input redirection.

**Takeaway:** When writing or modifying `.sh` files for this repo, run `shellcheck <file>` locally before committing. The gate runs shellcheck only on changed files, so existing violations in untouched files won't cause failure.

---

## Gate 1g: Self-eval

**What it checks:** Any changed `.md` files under `skills/` or `workflows/` pass self-evaluation with fewer than 2 Weak automated scores.

**Rationale:** Structural checks (gates 1a–1f) can't assess whether a skill or workflow is semantically well-formed. This gate uses the project's own `skills/self-eval.md` to evaluate quality across 5 automated dimensions.

**Fail message:** `self-eval: <filename> has N Weak automated scores`

**Recording states:** pass / fail / skip

**Automated dimensions scored** (from `docs/evaluation-rubric.md`):
1. Testability investment
2. Trigger clarity
3. Overlap and redundancy
4. Test coverage
5. Pipeline readiness

**Threshold:** 2+ Weak scores → reject. A single Weak is logged but allowed through, because test coverage is universally Weak across the repo (per decision 005). Setting the threshold at 1 would reject everything.

**Common failure patterns:**

| Pattern | Cause | Fix |
|---------|-------|-----|
| Missing trigger section | Skill doesn't specify when to invoke it | Add a clear trigger description to the skill's frontmatter or opening section |
| Overlaps with existing skill | New skill duplicates purpose of an existing one | Differentiate scope or merge into the existing skill |
| Unparseable self-eval output | Claude didn't follow the `SELF_EVAL_RESULT: N` format | This logs a warning but does **not** reject — the gate is lenient on parse failures |
| 2+ Weak scores on a draft skill | Skill needs more structure | Address the specific Weak dimensions before re-running |

---

## Verdict and cleanup

After all gates run, the branch receives a verdict:

- **APPROVED:** Added to the merge queue. Worktree preserved for the merge step.
- **REJECTED:** Logged with the rejection reason. Worktree and branch are deleted (`git worktree remove`, `git branch -D`).

If all tasks in a round are rejected, the round logs `outcome: "all_rejected"` and proceeds to the next round.

---

## Debugging a rejection

1. **Check the validation log:** `docs/working/validation-round-N.log` has one line per task with the verdict and reason.
2. **Check the round report:** `docs/working/round-N-report.json` has structured gate-by-gate results under `.validation.<task_id>`.
3. **Identify which gate failed:** Gates run in order (1a→1g). The first failure is the rejection reason. Earlier gates that show "pass" are confirmed clean.
4. **Fix the root cause** using the patterns above, then re-run.

---

## Quick reference: Pre-submission checklist

Before running the self-improvement loop, verify:

- [ ] Each task's `files_touched` in `tasks.json` lists all files the implementation will modify
- [ ] Task scope is narrow enough to stay under 500 lines changed
- [ ] If the task modifies `.sh` files, they pass `shellcheck` locally
- [ ] If the task modifies skills/workflows, they have clear triggers and don't overlap with existing ones
- [ ] Critical files (`self-improvement.sh`, `docs/evaluation-rubric.md`, `CLAUDE.md`) are not being deleted
