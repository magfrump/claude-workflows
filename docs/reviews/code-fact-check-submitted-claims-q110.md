Commit: 40f524df

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-q110 (branch `fix/q110-not-run-undercount`)
**Scope:** Submitted claims 23-25 only (security-reviewer, performance-reviewer) against `scripts/run-tests.sh`, `scripts/health-check.sh`, `test/lib/hermetic-env.bash`, `test/skills/runner-contract.bash`, and the suites that run the runner again; no harvesting from the diff
**Checked:** 2026-10-14
**Total claims checked:** 5 (claims 23 and 25 split into a/b on verdict divergence)
**Summary:** 3 verified, 1 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read first: no claim below matches a logged pattern.

Execution note: the caller barred `scripts/run-tests.sh` inside the worktree (a health-check run holds its lock), so every executed check ran on copies of `scripts/run-tests.sh`, `test/lib/hermetic-env.bash` and `test/skills/runner-contract.bash` (all at 40f524df) in a throwaway layout `/home/node/.claude/jobs/00bcf178/tmp/q110/tmp.wAR9vOXVKx/repo`. That layout held two fast fixture suites, `a.bats` and `b.bats`, each writing `${RUN_TESTS_NOT_RUN_FILE-unset}` to a per-process file, and a PATH shim `bats` that logs its first argument and its view of the variable and then execs `/usr/bin/bats`. The directory was removed afterwards. Real bats 1.8.2 and GNU parallel 20221122 were used. The captured output, kept outside the repo, is `/home/node/.claude/jobs/00bcf178/tmp/q110/cfc-submitted-23-25-exec.log`. Runs A-E all exited 0, with timestamps from 2026-10-15T04:28:38Z to 04:28:44Z (UTC; local date 2026-10-14).

---

## Submitted Claims

## Claim 23a: "After the diff, no process bats starts (via `bats --count` or `exec bats`, serial or `--jobs N`) has `RUN_TESTS_NOT_RUN_FILE` in its environment, even when the caller exported it rather than env-prefixing it" (the inherited-value part)

**Submitted by:** security-reviewer
**Location:** `scripts/run-tests.sh:359-368`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a value the runner inherits from its caller, whether exported or env-prefixed: it is absent from `bats --count`, from serial `exec bats`, from `exec bats --jobs 2`, and from every test process under GNU parallel. It does not cover a value re-created downstream by caller-supplied code (`PARALLEL_ENV`, see 23b; `BASH_ENV`, not run). It does not cover the early `exit` paths, which start no bats.
**Legibility-target:** security-reviewer and the code-review rubric. Clears "the inherited path does not leak", not "nothing can set it".

The runner writes the count and then removes the variable before any later step:

```bash
# scripts/run-tests.sh:359-368
if [[ -n "${RUN_TESTS_NOT_RUN_FILE:-}" ]]; then
  echo "${#not_run[@]}" > "$RUN_TESTS_NOT_RUN_FILE"
fi
# The file is this run's answer to its caller, ...
...
unset RUN_TESTS_NOT_RUN_FILE
```

Both bats starts come after it: `expected="$(bats --count "${files[@]}" 2>/dev/null)" || expected="?"` (`scripts/run-tests.sh:441`) and `exec bats "${bats_args[@]}" "${files[@]}"` (`scripts/run-tests.sh:452`, the script's last line). In bash, `unset` removes a variable from the exported environment whether it was exported or env-prefixed. Executed result:

- Command: `env PATH=<shim>:$PATH LC_ALL=C.UTF-8 bash -c "export RUN_TESTS_NOT_RUN_FILE=<repo>/nr; exec bash scripts/run-tests.sh --fast"`. Cwd: the throwaway repo. Exit 0, 2026-10-15T04:28:38Z (run A, serial, exported). Shim log `bats --count -> unset;bats .../run-log-anchor -> unset;`. Both suites report `unset`. `nr` reads `0`.
- Run B, the same with `--jobs 2`. Exit 0, 04:28:39Z. Shim log `bats --count -> unset;bats --jobs -> unset;`. Both suites, run under parallel, report `unset`.
- Run C, env-prefixed with `--jobs 2`. Exit 0, 04:28:40Z. Same results.

The caller's own count still arrives in every run (`nr file: 0`, which is right for the fixture, since no suite is gated).

**Evidence:** `scripts/run-tests.sh:359-368`, `scripts/run-tests.sh:441`, `scripts/run-tests.sh:452`, `/home/node/.claude/jobs/00bcf178/tmp/q110/cfc-submitted-23-25-exec.log` (runs A, B, C)

---

## Claim 23b: "... no process bats starts ... has `RUN_TESTS_NOT_RUN_FILE` in its environment" — and nothing in the parallel path (`--env`, env_parallel, PARALLEL settings) can reintroduce it

**Submitted by:** security-reviewer
**Location:** `scripts/run-tests.sh:428-435`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three parallel-side routes that were checked: bats' own `parallel` call, a caller's `$PARALLEL` (which is neutralized), and a caller's `$PARALLEL_ENV` (which is not). It does not cover parallel config files carrying `--env`, which only copy variables already present, so there is nothing to copy. It does not cover `BASH_ENV` (not run) or remote `--sshlogin` setups.
**Legibility-target:** security-reviewer. Its "even when exported" holds. The absolute "no process" needs the qualifier "unless the caller supplies shell code via `PARALLEL_ENV`".

bats starts parallel with no env-forwarding option:

```bash
# /usr/libexec/bats-core/bats-exec-suite:420
parallel --keep-order --jobs "$num_jobs" bats-exec-file "$(printf "%q " "${flags[@]}")" "{}" "$TESTS_LIST_FILE" ::: "${BATS_UNIQUE_TEST_FILENAMES[@]}" 2>&1 || bats_exec_suite_status=1
```

The runner clears the two parallel option variables, `unset PARALLEL PARALLEL_CSH` (`scripts/run-tests.sh:429`). Run E set `PARALLEL="--env RUN_TESTS_NOT_RUN_FILE"` on the caller (exit 0, 04:28:44Z) and both suites still reported `unset`.

GNU parallel also reads `PARALLEL_ENV`, which the runner does not unset. Parallel puts its contents, as shell code, in front of every job:

```perl
# /usr/bin/parallel:9824-9833
	if($Global::parallel_env) {
	    # If $PARALLEL_ENV set, put that in front of the command
	    # Used for env_parallel.*
	    ...
		$command = $Global::parallel_env."\n".$command;
	    }
	}
```

(excerpt ends :9833; the enclosing job-command builder continues past :9840 — read to :9840, the remainder handles `--cat`/`--fifo`.)

Run D set `RUN_TESTS_NOT_RUN_FILE=<repo>/nr PARALLEL_ENV="export RUN_TESTS_NOT_RUN_FILE=<repo>/injected"` with `--jobs 2` (exit 0, 04:28:42Z). The shim logged `unset` for both bats starts, but both suites under parallel reported `<repo>/injected`. So the variable can reappear in test processes under `--jobs N`. It is not the inherited value, though: it is a new one written by caller-supplied code that parallel runs. A caller who can set `PARALLEL_ENV` can already run arbitrary code in every job, so this is not a way around the fix's boundary. The serial path is unaffected, because parallel is never started there. That is why the verdict is Mostly accurate and not Incorrect. The precise version of the claim reads "... unless the caller supplies `PARALLEL_ENV` (or `BASH_ENV`) code that sets it."

**Evidence:** `scripts/run-tests.sh:428-435`, `/usr/libexec/bats-core/bats-exec-suite:415-420`, `/usr/bin/parallel:2586-2607`, `/usr/bin/parallel:9824-9833`, `/home/node/.claude/jobs/00bcf178/tmp/q110/cfc-submitted-23-25-exec.log` (runs D, E)

---

## Claim 24: "The diff does not remove the variable before its only consumer in the runner: the single read/write is at :359-360 and :369-452 have no other reference."

**Submitted by:** security-reviewer
**Location:** `scripts/run-tests.sh:359-452`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every reference to the name in `scripts/run-tests.sh` and in the two files it sources (`test/lib/hermetic-env.bash` at :177, `test/skills/runner-contract.bash` at :325). It does not cover consumers outside the runner process: health-check.sh reads the file only after the runner exits, which the unset does not affect.
**Legibility-target:** security-reviewer and the rubric. Clears "the unset breaks nothing in the runner".

A repo-wide grep (excluding `docs/reviews/`) finds the name in `scripts/run-tests.sh` at :19 and :320 (header comments), at `if [[ -n "${RUN_TESTS_NOT_RUN_FILE:-}" ]]; then` / `  echo "${#not_run[@]}" > "$RUN_TESTS_NOT_RUN_FILE"` (`scripts/run-tests.sh:359-360`), and at `unset RUN_TESTS_NOT_RUN_FILE` (`scripts/run-tests.sh:368`). It has no hit between :369 and :452. Neither sourced file mentions it: paraphrased — no quote available because the claim covers absence of code (zero grep hits in `test/lib/hermetic-env.bash` and `test/skills/runner-contract.bash`). Both files define only functions and constants. Their only `export`s are `export LC_ALL="$candidate" LANG="$candidate"` and `export LC_ALL=C LANG=C` (`test/lib/hermetic-env.bash:31`, `:39`), and both sit inside `pin_hermetic_locale`, which the runner never calls. The only other hits are in `scripts/health-check.sh` (:377, :425 comments; `:431` and `:439` set the variable for their own child) and in suites that set it for their own nested runners. Nothing after :368 in the runner, neither the `--failed` filter (:382-397), the early `exit 0` paths (:395, :401) nor the parallel and recording blocks, needs it.

**Evidence:** `scripts/run-tests.sh:19`, `scripts/run-tests.sh:177`, `scripts/run-tests.sh:320-325`, `scripts/run-tests.sh:359-452`, `test/lib/hermetic-env.bash:1-80`, `test/skills/runner-contract.bash:1-275`, `scripts/health-check.sh:425-446`

---

## Claim 25a: "The unset sits before the `--jobs` branch, so under `--jobs N` the concurrent suite files no longer share one inherited output path"

**Submitted by:** performance-reviewer
**Location:** `scripts/run-tests.sh:368`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the order of the lines (unset at :368, `--jobs` branch at :428-435) and the effect at runtime: concurrent suite files under `--jobs 2` see no path. It does not cover a path re-created via caller `PARALLEL_ENV` (Claim 23b).
**Legibility-target:** performance-reviewer.

`unset RUN_TESTS_NOT_RUN_FILE` (`scripts/run-tests.sh:368`) comes before `if [[ "$jobs" -gt 1 ]]; then` / `    bats_args+=(--jobs "$jobs" --no-parallelize-within-files)` (`scripts/run-tests.sh:428-431`). The health check uses this path: `HEALTH_CHECK_SKIP_BATS=1 RUN_TESTS_NOT_RUN_FILE="$nr_dir/fast" "$runner" --fast --jobs "$jobs"` (`scripts/health-check.sh:431`). In runs B and C (`--jobs 2`, exit 0), both concurrently run fixture suites reported `unset`.

**Evidence:** `scripts/run-tests.sh:368`, `scripts/run-tests.sh:428-435`, `scripts/health-check.sh:431`, `/home/node/.claude/jobs/00bcf178/tmp/q110/cfc-submitted-23-25-exec.log` (runs B, C)

---

## Claim 25b: "on the old runner, parallel suites that each nested the runner could race on that single file, last writer wins"

**Submitted by:** performance-reviewer
**Location:** `scripts/run-tests.sh:428-435`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which suites in this tree run the runner again with the inherited environment, and whether those writes could run at the same time on the old runner. It does not cover suites added after 40f524df. The old runner was not executed (barred in the worktree, and the result follows from the suite set).
**Legibility-target:** performance-reviewer and the rubric. The Q-110 defect was a sequential overwrite that `--jobs` neither causes nor worsens. The claim should not be carried as a concurrency finding.

Only one suite file runs the runner again with the inherited variable. In `test/skills/eval-helpers-gating.bats` (fast), tests 1-3 set their own path (`run env RUN_TESTS_NOT_RUN_FILE="$T/nr" bash "$T/scripts/run-tests.sh" --fast`, `:50`, `:63`, `:82`). Tests 4-6 do not (`run bash "$T/scripts/run-tests.sh" --fast`, `:90`, `:97`, `:105`). The other suites that call the runner clear their environment first:

- `test/scripts/run-tests.bats` (slow) uses `run env -i PATH="$path" HOME="$HOME" TMPDIR="$BATS_TEST_TMPDIR" "${assigns[@]}" \` (`test/scripts/run-tests.bats:66`), `timeout -s TERM 60 env -i ...` (`:82`), and `run env -i` at `:471` and `:503`.
- `test/scripts/health-check.bats` uses a stub runner, and health-check.sh hands that stub its own path (`scripts/health-check.sh:431`). Paraphrased — no quote available because this combines `test/scripts/health-check.bats:485-493` with the env-prefix in `scripts/health-check.sh:431-439`.

Within that one file, tests run one at a time even under `--jobs N`: `bats_args+=(--jobs "$jobs" --no-parallelize-within-files)` (`scripts/run-tests.sh:431`). The parent runner wrote its count once, before bats started. So on the old runner, the writes to the shared file during a health-check run came from one file's tests, one after another, and none were concurrent. The last writer won by order, not by a race. The author's reproduction is serial (no `--jobs`) and shows the overwrite (4 instead of the parent's count), which confirms the defect does not depend on `--jobs`. The claim's mechanism, concurrent suite files racing, does not happen with this suite set. The hypothetical ("could") would need a second inheriting suite in the same category, and there is none.

**Evidence:** `test/skills/eval-helpers-gating.bats:49-108`, `test/scripts/run-tests.bats:58-85`, `test/scripts/run-tests.bats:467-512`, `test/scripts/health-check.bats:484-498`, `scripts/run-tests.sh:428-435`, `scripts/health-check.sh:431-446`

---

## Claims Requiring Attention

### Incorrect
- **Claim 25b** (`scripts/run-tests.sh:428-435`): there was no cross-suite race on the old runner. Only `eval-helpers-gating.bats` inherited the path, and its tests run one at a time. The overwrite was sequential and does not depend on `--jobs`.

### Stale
(none)

### Mostly Accurate
- **Claim 23b** (`scripts/run-tests.sh:428-435`): add "unless the caller supplies `PARALLEL_ENV` (or `BASH_ENV`) code that sets it". The runner unsets `PARALLEL`/`PARALLEL_CSH` but not `PARALLEL_ENV`, and run D showed parallel re-creating the variable in test processes under `--jobs 2`.

### Unverifiable
(none)

---

## Goal-Alignment Note

The PR's goal is that a nested runner can no longer overwrite the health check's NOT RUN count. Claims 23a, 24 and 25a confirm the fix delivers that, by execution on a copy of the 40f524df runner in serial and `--jobs 2` modes, with the variable both exported and env-prefixed, and by grep showing nothing after the unset needs it. The two non-Verified results do not block the goal. 23b is a caller-controlled code-injection edge (`PARALLEL_ENV`) that the health check never sets. If the author wants the header's "never see it" to be absolute under `--jobs`, the existing `unset PARALLEL PARALLEL_CSH` line is where `PARALLEL_ENV` would go, but that is the author's call. 25b corrects a critic's description of the old failure and does not affect the fix.
