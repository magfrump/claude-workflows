Commit: 16f2978

# Performance Review — answers-2026-09-20, iteration 2 (fix commits f023357..16f2978)

**Scope:** `git diff f023357..answers-2026-09-20` (partial: fix commits only; earlier branch commits are context)
**Date:** 2026-09-21
**Based on:** `docs/reviews/code-fact-check-report-iter2.md` (merged k=3); iteration-1 rubric `docs/reviews/code-review-rubric-2026-09-21-answers-2026-09-20.md`

## Data Flow and Hot Paths

- **`hooks/guard-trusted-writes.py`** is the only hot path in this diff. It is a PreToolUse hook on `Edit|Write|MultiEdit|Bash`, so it starts a fresh `python3` process on every such tool call. The fix adds module-level work: `config_dir()`, 2–5 `resolve()` calls, and one `CONFIG_DIR.glob("settings*.json")` directory listing (`:79-93`). For file tools, `classify_path` now builds three candidates (lexical, `normpath`, `resolve()`) (`:122-133`). For Bash, it adds three linear regex scans that only run after `WRITE_PRIMITIVE` matches (`:190-205`).
  - **Measured on this host (hermetic temp HOME, 40 calls each, under whatever contention the sandbox has):**
    - Old hook: 17.6–18.5 ms per call.
    - New hook: 19.6–20.3 ms per call.
    - Bare `python3 -c pass`: 8.1 ms.
    - In-process: module execution went from 0.16 to 0.30 ms and `classify_path` from 54 to 81 µs. So the ~2 ms end-to-end gap is mostly process-launch noise, and at most ~0.2 ms comes from the new code. Python startup dominates the cost either way.
  - Probe: `scratchpad/performance/time.sh.txt`.
- **`test/scripts/health-check.bats`** is cold (the `--slow` test gate). The cache fix is at `:20-25`.
- **`scripts/lib/si-morning-summary.sh`**, `scripts/questions.sh` and `scripts/self-improvement.sh` are cold. Each runs once per SI round or once per user command, over files numbering in the tens. The new `_valid_run_id`, `_live_run_matches`, `replace_with` (mktemp + mv) and `_split_row_fields` sentinel work costs O(1) or O(row length) on each call.

## Findings

#### Negative frontmatter tests still run the full health check twice (A9 residual)

**Severity:** Low
**Location:** `test/scripts/health-check.bats:127`, `test/scripts/health-check.bats:140`
**Move:** Count the hidden multiplications
**Classification:** Macro (whole-script re-run for a single-gate assertion) / Cold path (slow test gate, run per health check)
**Confidence:** High
**Baseline:** 54–60 s wall time for this bats file with 3 real script runs (fact-check Claim 15, executed by r1/r2/r3). The commit comment at `:23-24` puts one run at ~18 s.

**Evidence:**
```
  HEALTH_CHECK_SKILLS_DIR="$skills_dir" run bash "$SCRIPT"
```
(`:127`; `:140` is identical. Both sit inside `@test "detects skill file with no YAML frontmatter"` / `"... missing description field"`, and the remaining assertions of each test are not quoted.)

bd07c4e fixed the real cause: `$$` differs in every bats test process, so the cache never hit. That removed about 350 s. The fix iteration 1 proposed was different: call `check_skill_frontmatter` directly through the `BASH_SOURCE` guard at `scripts/health-check.sh:1064`. That fix was not applied. So each negative test still runs all 13 non-bats gates just to check one gate, and those two runs make up roughly 2/3 of the file's remaining ~55 s.

**Recommendation:** Optional. Source `scripts/health-check.sh` (the `BASH_SOURCE` guard allows this) and call `check_skill_frontmatter` with `HEALTH_CHECK_SKILLS_DIR` set. That should cut the file to about one run (~20 s) without weakening what the negative tests prove. Whether it proves the same thing needs a check by test-strategy or code-fact-check.

#### `_days_since_round` still omits `$run` when it calls `_find_tasks_file` (C3, still open)

**Severity:** Informational
**Location:** `scripts/lib/si-morning-summary.sh:1368`
**Move:** Count the hidden multiplications
**Classification:** Micro (a repeated newest-first scan plus extra `jq` spawns) / Cold path (once per deferred hypothesis per morning summary)
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative

**Evidence:**
```
        tasks_file=$(_find_tasks_file "$round" "$tid" "$working_dir")
```
(inside `_days_since_round`, `:1347-1392`. The lines after this call, which do the prefix derivation and the report fallback, are not quoted.)

The fix commits added `_valid_run_id` to both functions (`:1189`, `:1350`) but did not pass `"$run"` at `:1368`. When the run-specific report is missing, this call falls back to the newest-first scan, and on each candidate that doesn't match, it spawns one `jq` per file. Separately, `_find_tasks_file` still lists `tasks-round-$round.json` twice when the live run matches (`:1199-1202`), so a miss runs `jq` on that file twice. With N at around ten archived copies, the cost is negligible. Passing `$run` would also make the fallback choose the row's own run, which may matter more for correctness than for speed.

**Recommendation:** Pass `"$run"` as the 4th argument at `:1368`. Optionally, skip the duplicate live candidate in `_find_tasks_file`.

## Endorsements (evidence-gated)

- The new `HOME_INDICATOR` / `CFG_INDICATOR` / `CLAUDE_MD` / `SETTINGS_OR_HOOKS` regexes are alternations of literals or anchored prefixes with no nested quantifiers. They should add only linear time to a Bash call, and only after `WRITE_PRIMITIVE` has matched. `[read: hooks/guard-trusted-writes.py:171-205]`
- Claim to verify: across the three request shapes (Bash hard, Write none, Bash no-write), the fix adds ≤0.3 ms of in-process work per hook call, and end-to-end latency stays within ~2 ms of the pre-fix hook (≈20 ms/call vs ≈18 ms). `[unverified — submitted as claim]` (self-measured, not a fact-check execution verdict)
- Claim to verify: the pathological-input times for `WRITE_PRIMITIVE` are unchanged by the fix. Measured with 40 KB inputs: `"sed "`×10k took 1.51 s on both old and new; `"dd "`×13k took 1.48 s old and 1.40 s new; `"python "`×6k took 0.83 s old and 0.86 s new. `[unverified — submitted as claim]`

## Iteration-1 finding status

- A9: resolved — the real cause was per-test `$$` cache misses, and `test/scripts/health-check.bats:25` now uses `$BATS_FILE_TMPDIR/hc-cache` (fact-check Claim 15: 54–60 s, down from ~405 s). A residual of two full runs remains at `:127,:140` (Low, above).
- A13: resolved — `skills/performance-reviewer/SKILL.md:46` now carries the large-data / nightly-batch exception, and `:283` says "same exceptions as the hot-path gate" (fact-check Claim 27, Verified).
- C2: still-open — this diff does not touch `test/init-firewall-rules.bats`, and `:2` still says `# @category fast`. It is a pre-existing Consider item and not a regression.
- C3: still-open — `scripts/lib/si-morning-summary.sh:1368` still calls `_find_tasks_file` without `$run`. It is a pre-existing Consider item and not a regression.
- C4: still-open — the `WRITE_PRIMITIVE` alternation at `hooks/guard-trusted-writes.py:156-164` is unchanged. Pathological 40 KB inputs now measure 0.8–1.5 s, the same on old and new, so the fix did not regress it. It is pre-existing, cold in practice (real commands are short) and Informational.
- Hook-latency effect of the new `resolve()`/`normpath` and co-occurrence logic: no regression of note. The new code adds about 0.1–0.2 ms in-process against ~18–20 ms per call, which Python startup dominates. The module-level `glob("settings*.json")` is a single directory listing (`:88`).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Negative tests re-run the full health check twice (A9 residual) | Low | `test/scripts/health-check.bats:127,140` | High |
| 2 | `_days_since_round` omits `$run` for `_find_tasks_file` (C3) | Informational | `scripts/lib/si-morning-summary.sh:1368` | High |

## Overall Assessment

The fix commits are performance-neutral to positive. bd07c4e removes the dominant cost in the slow gate (~350 s per health check). The guard hook's new path resolution and co-occurrence rules add work that is small next to Python startup on a path that runs on every tool call, and they add no new super-linear regex. What remains are pre-existing cold-path items: C2, C3, C4, plus the two extra full runs in the negative tests. All of them can be fixed in place, none blocks, and none needs profiling beyond the probes already run.

## Goal-Alignment Note

- **Success criterion (restated verbatim):** A markdown critique saved to /workspace/docs/reviews/performance-review-2026-09-21-answers-iter2.md, structured per your role skill, with an `## Iteration-1 finding status` section covering your domain items, ending with a Goal-Alignment Note.
- **Answered:** A9, A13, C2, C3 and C4 are adjudicated. The guard hook's per-call latency was measured hermetically, old vs new, and so were its pathological-regex times. Two residual findings were filed.
- **Out of scope:** commits before f023357, and the security completeness of the Bash co-occurrence rule (fact-check Claim 1 goes to security-reviewer). I did not reproduce the latency numbers on the host outside the sandbox.
- **Escalate:** none. The two `[unverified — submitted as claim]` endorsements go to code-fact-check intake if synthesis wants them as Confirmed-Good.
