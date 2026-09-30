Commit: ff99d86

# Security Review — feat/run-tests-jobs (Q-090 `--jobs N`, final confirming pass)

**Scope:** `git diff main...HEAD -- scripts test` at ff99d86: scripts/run-tests.sh (header "Parallel runs" `:84-109`, `--jobs` parsing `:136-146`, lowering and GNU check `:399-414`, `exec bats` `:431`) and test/scripts/run-tests.bats (`parallel_shim` `:333-342`, 11 `--jobs` tests `:344-499`). Context read: scripts/run-tests.sh `:120-160`, `:219-261`, `:360-431`; `/usr/libexec/bats-core/bats-exec-suite:1-110, 380-430`; `/usr/libexec/bats-core/bats-exec-file:1-30, 285-300`; `/usr/bin/parallel:3319-3368, 10685-10705`.
**Date:** 2026-09-30
**Based on:** pass-1 review docs/reviews/q090-security-review-2026-09-30.md (F1 Low, F2 Info); pass-3 fact-checks docs/reviews/q090-pass3-code-fact-check-report-r{1,2,3}.md (41/40/35 claims; 2/4/1 Incorrect, all comment or commit-body wording).
**User goal:** pinned upstream by the orchestrator's goal preamble (land `--jobs N` for scripts/run-tests.sh after a clean review-fix loop).

No escalation pattern matched (no secrets, no auth surface, no injection into user-facing code, no TLS change, no key material).

Probes ran with `LC_ALL=C.UTF-8`, under `timeout`, with N never above 50. Logs are in `/tmp/claude-1000/-workspace/21797f19-046e-4351-9c55-0471f4b3d3b6/scratchpad/run-tests-jobs/sec-final/`. The real suite was not run. Q1 ran the worktree runner only with values that exit while flags are parsed, before the lock is taken. A final `ps` check found no probe process left.

| Probe | What | Result |
|---|---|---|
| Q1 | Worktree runner `--jobs V`, V in `999` (then an unknown flag), `1000`, `0999`, `999x`, `$'9\n'`, `٩`, `９`, `1e2`, `' 5'`, `+5`, `-5`, `''`; `1000`/`٩`/`９` again under ambient `LANG=xx_XX.UTF-8` | 999 passes the validator and exits 1 at the unknown flag. Every other value exits 2, in both locales |
| Q2 | Fresh `HOME`: `parallel --plain --version`, then `parallel --keep-order --jobs 2 echo ::: a b` | The probe writes nothing. The real run creates `~/.parallel/tmp/sshlogin/<host>/{linelen,setpgrp_func}`. `setpgrp_func` holds perl source (`*open3_setpgrp = \&open3_setpgrp_internal`) |
| Q3 | `exec 9>lock; flock 9; timeout -s TERM 0.3 bats --jobs 50 --no-parallelize-within-files` on 50 one-test files (`sleep 2`) | bats rc 124. `parallel` is orphaned (ppid 1) at t+0 and the lock is held. By t+1 s: 0 `sleep 10101` dummies, 0 `parallel`, lock free. Nothing left by t+6 s |
| Q4 | bats directly, 2 files (a: 2 × 1 s tests, b: 1 × 1 s): (a) `BATS_NUMBER_OF_PARALLEL_JOBS=3 bats a b` (the runner's N=1 argv); (b) `BATS_NO_PARALLELIZE_ACROSS_FILES=1 bats --jobs 2 --no-parallelize-within-files a b` (the runner's N>1 argv); (c) as (b) with no `parallel` on PATH | (a) 1.14 s, 3 ok: tests within a file ran concurrently. (b) 3.12 s, 3 ok: serial. (c) 3.15 s, 3 ok: no abort |
| Q5 | `bats --filter jobs test/scripts/run-tests.bats` | 11/11 ok, rc 0 |

---

## Pass-1 findings: do the fixes hold?

- **Pass-1 F1 (unbounded N, orphaned slot probe holding the lock): holds.** The validator is now `^[1-9][0-9]{0,2}$` (`:139`). Q1 shows 1000 and every malformed value exit 2 in both locales. N is then lowered to the file count (`:406`). Test 7 (`--jobs 999` on 2 files hands bats `--jobs 2`) passes (Q5). So the most dummies the slot probe can fork is the number of selected files. At N=50 under TERM (Q3), the orphaned `parallel` finished the probe, killed its dummies and released the lock within 1 s. Pass 1 saw hours at N=20000. The one remaining way past the bound is a user-exported `BATS_NUMBER_OF_PARALLEL_JOBS` on the N=1 path. That path is not new (main runs the same argv), and it is part of Finding 1.
- **Pass-1 F2 (ambient parallel config unscrubbed): partly addressed, deliberately.** `unset PARALLEL` (`:408`) removes `$PARALLEL`, and test 8 pins that (Q5). `--plain` on the probe keeps config files from failing the GNU check (test 9). Config files still reach bats' run. The header documents that (`:98-101`), and override-log row 174 settles the `PARALLEL_HOME` reversal. Finding 1 lists what else is still unscrubbed. Everything probed fails closed or falls back to serial.

## Trust Boundary Map

```
B1:       [--jobs N argv, invoking user/agent]     → [regex ^[1-9][0-9]{0,2}$ :139; lowered to file count :406] → [bats --jobs N → parallel slot probe + job spawn]
B2:       [PATH lookup of `parallel`]              → [`parallel --plain --version` prefix check :409]          → [bats-exec-suite:420 runs it with full env and lock fd 9]
B3:       [ambient PARALLEL_CSH, config files,
           PARALLEL_SHELL, BATS_NUMBER_OF_PARALLEL_JOBS,
           BATS_NO_PARALLELIZE_ACROSS_FILES]        → [`unset PARALLEL` only :408]                              → [parallel option parsing / bats scheduling → TAP stream, exit status, run log]
B4:       [test/ file paths]                       → [realpath-under-test/ check (pre-existing)]               → [parallel `{}` substitution → shell → bats-exec-file]
B5 (new): [$cache_dir/tmp/sshlogin/<host>/setpgrp_func
           (~/.parallel, $XDG_CACHE_HOME/parallel, $PARALLEL_HOME)] → [none: parallel `eval`s it]             → [perl inside every --jobs run]
```

B1 to B4 are the pass-1 boundaries with the new guards. B5 was not in the pass-1 map. It becomes reachable because the runner now executes GNU parallel. Q2 shows the cache file being created, and `/usr/bin/parallel:10693-10700` shows it being evaluated.

Input sources:

```
S1: --jobs N argv                    — request-time   — trusted for exec/path sinks (digits only, Q1); bounded for resource sinks (≤ file count)
S2: PATH                             — deploy-time    — trusted for exec (whoever sets PATH already runs code as this uid)
S3: PARALLEL_CSH, parallel config files, PARALLEL_SHELL,
    BATS_NUMBER_OF_PARALLEL_JOBS,
    BATS_NO_PARALLELIZE_ACROSS_FILES — deploy-time (session env/home) — trusted for exec; NOT hermetic for the TAP/exit/run-log sinks the runner's checks read
S4: test/**/*.bats paths             — code-constant  — trusted for exec; shell-quoted by parallel (pass-1 P7)
S5: $T / BATS_TEST_TMPDIR (tests)    — deploy-time    — trusted (test-only code generation in parallel_shim)
S6: parallel cache dir under $HOME   — runtime-mutable by this uid — UNTRUSTED toward the perl-eval sink by class; any writer is already this uid (see Finding 2)
```

Two things enter from outside: one argument (S1), now bounded, and one PATH-resolved executable (S2). That executable reads its own ambient configuration (S3) and a self-written cache (S6). The diff assumes S3 either does not break the run or breaks it visibly. Every probed case bears that out. None reached a false pass (exit 0 with a failing test, or a complete log with a forged result). No authentication, secret or network surface is touched.

## Findings

#### 1. After `unset PARALLEL`, other ambient parallel and bats inputs still shape a `--jobs` run; every probed one fails closed or falls back to serial

**Severity:** Informational
**Location:** `scripts/run-tests.sh:406-414`, `scripts/run-tests.sh:94-101`
**Boundary:** B3 (and B1 for the env-var route past the N bound)
**Move:** 1 (trust boundaries), 11 (bypasses for the guardrail), 3 (error path)
**Confidence:** High (executed: Q4; fact-check r1 E2/E3, r2 P3/P5d, r3 E9)
**Legibility-target:** for-author

Evidence. Only one variable is cleared:

```bash
# scripts/run-tests.sh:406-414 (the lowering and GNU-check block, complete)
(( jobs > ${#files[@]} )) && jobs=${#files[@]}
if [[ "$jobs" -gt 1 ]]; then
  unset PARALLEL
  if [[ "$(parallel --plain --version 2>/dev/null)" == "GNU parallel"* ]]; then
    bats_args+=(--jobs "$jobs" --no-parallelize-within-files)
  else
    echo "WARNING: --jobs $jobs needs GNU parallel, and the first parallel on PATH is missing or is not GNU parallel; running serially" >&2
  fi
fi
```

parallel reads a second option variable:

```perl
# /usr/bin/parallel:3362-3368 (excerpt of the option-assembly block that starts at :3319 — read)
	if($ENV{'PARALLEL'}) {
	    push @ARGV_env, shell_words($ENV{'PARALLEL'});
	}
	# Add options from env_parallel.csh via $PARALLEL_CSH
	if($ENV{'PARALLEL_CSH'}) {
	    push @ARGV_env, shell_words($ENV{'PARALLEL_CSH'});
```

bats takes its scheduling from the environment unless argv overrides it:

```bash
# /usr/libexec/bats-core/bats-exec-suite:6-7 (excerpt of the variable setup before option parsing — read)
num_jobs=${BATS_NUMBER_OF_PARALLEL_JOBS:-1}
bats_no_parallelize_across_files=${BATS_NO_PARALLELIZE_ACROSS_FILES-}
```

What each one does, and how it fails:
- **`$PARALLEL_CSH`** reaches bats' run. r2 P5d: `PARALLEL_CSH=--dry-run` under `--jobs 2` gave `Executed 0 instead of expected 4 tests`, exit 1. Fails closed. Only `env_parallel` under csh sets it.
- **Config files.** This residue is documented, and it fails closed in the ways that matter. r2 P3 probed `--dry-run`, `--tag`, `--retries 2` and `--halt now,fail=1`, and all exited 1. The header's "--failed refuses that log" (`:101`) is broader than the behaviour (r2 Claim 9c, Incorrect). With `--tag` or `--retries`, `--failed` accepts the log. It is safe to accept, though: that log holds a real result line for every test, so nothing is forged. A config such as `--ungroup` or `-j 1` changes the run without breaking it (r3 E9, r2 P3). That is an output-order effect, not a pass/fail one.
- **`PARALLEL_SHELL`** set to something unusable fails the `--plain` probe, so the runner prints a false "not GNU parallel" warning and runs serially (r1 E3). Fails safe.
- **`BATS_NO_PARALLELIZE_ACROSS_FILES`** makes a `--jobs` run serial (Q4b: 3.12 s against ~2 s), and bats then also skips its "needs GNU parallel" abort (Q4c). Fails safe, but silently: the runner still says nothing, while bats gets `--jobs N`.
- **`BATS_NUMBER_OF_PARALLEL_JOBS`** affects only the N=1 path (default, or a one-file run), where the runner hands bats no `--jobs`. There bats parallelizes *within* files (Q4a: 1.14 s against ~3 s serial), using `parallel` with `$PARALLEL` still set, and with no 999 bound on the slot probe. This is pre-existing: main hands bats the same argv. It does contradict the header's framing that within-file serial is "the only way the suites have ever run" (`:87`) whenever a user exports it.

None of these crosses a trust boundary an attacker can reach. Each needs control of this user's environment or home directory, which already means code execution as this uid. So this is non-hermeticity, not a vulnerability. It is listed so the pass-1 F2 closure is not read as "parallel's inputs are scrubbed".

**Recommendation:** Optional. `unset PARALLEL PARALLEL_CSH` closes the one residue that is the same kind as the fix. Unsetting `BATS_NUMBER_OF_PARALLEL_JOBS BATS_NO_PARALLELIZE_ACROSS_FILES` near the top of the runner would make "tests within a file stay serial" hold unconditionally and route N through the bounded flag only. Skip both if ambient bats/parallel settings are meant as a user feature. If they stay, narrow the header's `:97` to "options in `$PARALLEL`" as r1 suggests.

#### 2. `--jobs` runs now execute perl that GNU parallel caches under the user's home and `eval`s on every run

**Severity:** Informational
**Location:** `scripts/run-tests.sh:410` (reaches `/usr/bin/parallel:10690-10702` through `bats-exec-suite:420`)
**Boundary:** B5
**Move:** 1 (trust boundaries), 7 (deserialization of stored data into code)
**Confidence:** High for the mechanism (executed Q2, read-static source); Low for any exploit path (needs same-uid write)
**Legibility-target:** for-orchestrator-synthesis

Evidence:

```perl
# /usr/bin/parallel:10690-10702 (excerpt of sub open3_setpgrp; continues past :10702 — read to :10705)
    sub open3_setpgrp {
	my $setgprp_cache = $Global::cache_dir . "/tmp/sshlogin/" .
	    ::hostname() . "/setpgrp_func";
	sub read_cache() {
	    -e $setgprp_cache || return 0;
	    local $/ = undef;
	    open(my $fh, "<", $setgprp_cache) || return 0;
	    eval <$fh> || return 0;
	    close $fh;
	    return 1;
	}
	if(not read_cache()) {
	    redefine_open3_setpgrp($setgprp_cache);
```

In Q2, one `parallel --keep-order --jobs 2` run in a fresh `HOME` created `~/.parallel/tmp/sshlogin/<host>/setpgrp_func` containing `*open3_setpgrp = \&open3_setpgrp_internal`. Later runs `eval` that file. Whoever can write it gets perl execution inside every `--jobs` test run, holding the run lock and running before any test. The serial path never executes parallel, so this sink is new to the runner. It is not exploitable across a boundary: the file sits in this user's home, and anyone who can write it can already write `~/.bashrc`. The floor rule's reachable-attacker bar is not met. It is recorded because S6 is exactly the runtime-mutable, eval-reachable kind of source that move #1 says to name, and a later change that shares `HOME` between sandboxed sessions with different write allowlists would make it matter.

**Recommendation:** No change needed for this branch. If per-session sandboxes ever allow writes to `~/.parallel` but not to shell startup files, point `PARALLEL_HOME` (which also relocates the cache) at a runner-owned directory. Override-log row 174 removed an earlier `PARALLEL_HOME` export for config reasons, and that decision stands.

## Untested bypass candidates

Guardrails in scope: the `--jobs` validator plus lowering (B1), and the GNU prefix check (B2). Tested:
- **B1:** 13 values in two locales (Q1); `--jobs 999` lowered to the file count (test 7, Q5); TERM at the maximum reachable N class (Q3); the env route `BATS_NUMBER_OF_PARALLEL_JOBS` (Q4a, Finding 1).
- **B2:** a moreutils-style `parallel` (test 10, Q5); no `parallel` on PATH (test 11); a config file holding a bad option (test 9); `$PARALLEL` holding a bad option (test 8); `PARALLEL_SHELL` (r1 E3, Finding 1).

Not tested:
- **B2, a non-GNU binary that prints "GNU parallel…" to `--plain --version`.** It passes the prefix check and bats then runs it. Not constructed because the source is S2 (PATH), which already runs arbitrary code as this uid. The check exists to prevent mistakes, not attacks, and prefix matching is enough for that.
- **B3, a config that forges `ok` lines for a failing test** (for example a `--shell` or wrapper-style option pointing at a script that rewrites output). This would need a config written by this uid. The bats count validator and the per-test run-log lines are written by bats-exec-file, not by parallel, so forging a pass would take control of the test processes themselves, which is the same as controlling the host.
- **B1, SIGHUP (terminal closed) during a run at N ≤ file count.** Not run. Q3's TERM result suggests the short probe window makes this benign, but that was not observed.

Because of these, neither guardrail appears in Endorsement Claims as bypass-resistant. The claims below cover properties.

## Endorsement Claims

- **Claim:** `--jobs` accepts exactly 1 to 999 in ASCII digits with no leading zero, and exits 2 for everything else before the lock or any bats step, in both the pinned and a broken ambient locale.
  **Location:** `scripts/run-tests.sh:136-146`
  **Evidence:** executed
  **Verified:** Q1 (13 values, 2 locales) and test 1 (Q5: missing, 0, non-numeric, 1000).
  **Not verified:** values arriving with `--jobs=N` syntax, which hit the pre-existing unknown-flag branch (exit 1, override-log row 169).
  **route: code-fact-check**

- **Claim:** The N bats receives is at most the number of selected files, so at N=50 a TERM-killed run leaves no slot-probe dummy and releases the run lock within about 1 s.
  **Location:** `scripts/run-tests.sh:406`, `scripts/run-tests.sh:410`
  **Evidence:** executed
  **Verified:** test 7 (`--jobs 999` on 2 files → `--jobs 2`), Q3 (bats directly with fd 9 locked, 50 files, TERM at 0.3 s).
  **Not verified:** the same TERM through the real runner's `exec bats` with the full suite (N up to the real file count). Q3 used bats directly.
  **route: code-fact-check**

- **Claim:** A `$PARALLEL` set by the user neither reaches bats' parallel run nor makes the GNU check fail.
  **Location:** `scripts/run-tests.sh:408-409`
  **Evidence:** executed
  **Verified:** test 8 (`PARALLEL="--dry-run --no-such-option"`: 4 tests run, no serial warning, `--no-parallelize-within-files` handed on), Q5.
  **Not verified:** `$PARALLEL_CSH`, which does reach the run (Finding 1).
  **route: code-fact-check**

- **Claim:** Among the ambient inputs probed across this pass and the pass-3 fact-checks (`--dry-run`, `--tag`, `--retries 2`, `--halt now,fail=1`, an unknown option, `PARALLEL_CSH=--dry-run`, both `BATS_*` variables), none produced exit 0 for a run with a failing or missing test.
  **Location:** `scripts/run-tests.sh:406-431`, `scripts/run-tests.sh:237-261`
  **Evidence:** executed
  **Verified:** r2 P3 and P5d (exit 1 each), r1 E4, Q4 (all 3 tests ok under both `BATS_*` variables).
  **Not verified:** config options outside that list, such as `--timeout` or `--sshlogin`.
  **route: code-fact-check**

- **Claim (scoped prose, carried from pass 1):** the lock fd 9 reaches every test process under parallel, and file paths with shell metacharacters are quoted by parallel. **Evidence:** executed in pass 1 (P1, P7). The relevant code (`:223-225`, `:431`, bats-exec-suite:420) is unchanged since. **Not verified:** re-run at ff99d86.

## Primitive sweep

Primitive: process exec / shell command construction

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/run-tests.sh:431` `exec bats "${bats_args[@]}" "${files[@]}"` | S1, S4 | array expansion, no shell; S1 digits-only, ≤ file count | cleared (Q1, test 7) |
| `scripts/run-tests.sh:409` `parallel --plain --version` | S2, S3 | `--plain` ignores config and `$PARALLEL`/`$PARALLEL_CSH` | cleared: output-only probe, no side effects in a fresh HOME (Q2); `PARALLEL_SHELL` false negative → serial (Finding 1) |
| `bats-exec-suite:420` `parallel --keep-order --jobs "$num_jobs" bats-exec-file … "{}" … ::: files` (via `:410`) | S1, S2, S3, S4 | `%q` on flags; parallel quotes `{}` | S1 cleared (bounded); S2 cleared (trusted PATH); S3 Finding 1; S4 cleared (pass-1 P7) |
| `/usr/bin/parallel:7901` `exec 'sleep', 10101` (slot probe, once per slot) | S1 | N ≤ file count | cleared: bounded (Q3) |
| `/usr/bin/parallel:10697` `eval <$fh>` of the setpgrp cache | S6 | none | Finding 2 (Informational, same-uid only) |
| `test/scripts/run-tests.bats:337-339` generated shim (`exec '$real' "$@"`, `'$T/parallel.args'`) | S5 | single quotes | cleared: test-only, deploy-time source |
| `test/scripts/run-tests.bats:486` `ln -s "$f" "$bin/${f##*/}"` over `$PATH` entries | S2 | writes only under `$BATS_TEST_TMPDIR` | cleared: test-only |
| `test/scripts/run-tests.bats:491` `bash -c 'command -v parallel \|\| bash "$1" …' _ "$T/scripts/run-tests.sh"` | S5 | positional `$1`, not interpolated | cleared |

Primitive: echo of untrusted text to the terminal

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/run-tests.sh:140` `echo "--jobs takes a number from 1 to 999, got: ${2:-(nothing)}" >&2` | S1 (raw) | none | cleared: the text goes back to the party that typed it |
| `scripts/run-tests.sh:412` `echo "WARNING: --jobs $jobs …"` | S1 (validated) | regex | cleared |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Beyond `$PARALLEL`, ambient inputs still shape a `--jobs` run (`PARALLEL_CSH`, config files, `PARALLEL_SHELL`, `BATS_NUMBER_OF_PARALLEL_JOBS`, `BATS_NO_PARALLELIZE_ACROSS_FILES`); each probed one fails closed or falls back to serial | Informational | B3, B1 | `scripts/run-tests.sh:406-414`, `:94-101` | High |
| 2 | `--jobs` runs execute perl that parallel caches in `~/.parallel/tmp/sshlogin/<host>/setpgrp_func` and `eval`s; same-uid write only | Informational | B5 | `scripts/run-tests.sh:410` → `/usr/bin/parallel:10690-10702` | High (mechanism) / Low (exploit) |

## Overall Assessment

Pass 1's one real defect is fixed and the fix holds. `--jobs` is bounded to 999 and then to the file count. At the reachable N, a TERM-killed run leaves no dummy processes and releases the run lock within a second, where pass 1 saw hours at N=20000. `$PARALLEL` no longer reaches the run, and config files cannot fail the GNU check. What is left is two Informational observations, both needing someone who already runs code as this uid. Finding 1: the ambient scrub covers `$PARALLEL` only. The clearest one-word follow-up is `PARALLEL_CSH`, and the header's fail-closed sentence overclaims `--failed` refusal, harmlessly (r2 Claim 9c). Finding 2: parallel evaluates its own home-directory cache. Neither blocks merge. No findings within the code paths read rise above Informational. The endorsement claims are executed and scoped with their `Not verified` hops named, and those that could anchor a rubric row are marked `route: code-fact-check`.

Fact-check cross-reference: r1/r2/r3's Incorrect verdicts (the test-27 comment about `--dry-run`; the `unset`-before-check ordering claim in 78b3b08's body, redundant now that `--plain` exists; the "--failed refuses that log" wording; r3 Claim 33a's coverage claim) are wording and coverage issues with no security consequence. Moving `unset PARALLEL` behind the check is harmless (r3 E2 mA). The residues the brief named, `$PARALLEL_CSH`, config files failing closed, and user-exported `BATS_NUMBER_OF_PARALLEL_JOBS`/`BATS_NO_PARALLELIZE_ACROSS_FILES`, are all folded into Finding 1 with their failure direction. None fails open.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the path named below, structured per the skill.
- Answered: yes. Saved at docs/reviews/q090-final-security-review-2026-09-30.md. The pass-1 F1/F2 fixes are re-checked by execution, and the fact-check residues are dispositioned.
- Out of scope: the real suite and install-host.bats under `--jobs` (brief bars the real suite); N above 50 (brief cap); re-raising override-log rows 166-174.
- Escalate: nothing blocking. Optional one-word follow-up `unset PARALLEL PARALLEL_CSH` plus narrowing the header's `:97`/`:101` wording, which the orchestrator may batch with the fact-check wording fixes.
- Decisions I made: rated both findings Informational rather than Low, because each needs same-uid control and fails closed or safe (the alternative was Low for Finding 1, citing the header's overclaim). Counted `BATS_NUMBER_OF_PARALLEL_JOBS` on the N=1 path as a residue of this diff's bound, though the argv is unchanged from main.
