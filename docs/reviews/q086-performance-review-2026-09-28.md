Commit: 1ef3090

# Performance Review — review/q086 (Q-086: add GNU parallel to the cc-isolated image)

**Scope:** `git diff main...HEAD` in `/workspace/.claude/wt-q086` (one added line, `devcontainer-config/Dockerfile:40`) plus the commit message of 1ef3090
**Date:** 2026-09-28
**Based on:** `docs/reviews/q086-code-fact-check-report.md` (k=1 loop pass)

## Data Flow and Hot Paths

The change adds the Debian package `parallel` to the first `apt-get install` RUN of the image (`Dockerfile:19-43`). It has two performance surfaces:

1. **Image build.** This is cold: it runs once per rebuild, which happens after an install.sh re-bless. Editing the RUN text busts Docker's layer cache for that layer and for every instruction after it (fact-check Claim 8).
2. **Test-suite wall time, the premise.** The change exists so that a later change (Q-090, not in this diff) can call `bats --jobs N` from `scripts/run-tests.sh`. The measured baseline is **742 s wall for 2,129 tests in 123 files, serial, on 16 cores** (`docs/working/proposal-2026-09-27-smaller-review-units.md:109-111`; fact-check Claim 3, Verified). That is about 0.35 s wall per test on average. The runner is a developer loop and the pr-prep gate, so it runs many times a day. This is the path where the payoff is meant to land.

The diff has no runtime code, so there are no loops, queries, caches or allocations to review. The findings below are about the build cost of where the line sits, and about whether the mechanism this change enables behaves as the commit message assumes.

## Findings

#### 1. `bats --jobs N` in bats 1.8.2 also runs tests in parallel *within* each file, using a shared semaphore that polls once a second. No test file opts out.

**Severity:** Informational
**Location:** `/usr/libexec/bats-core/bats-exec-suite:30-36`, `/usr/libexec/bats-core/bats-exec-file:294-296`; bears on commit 1ef3090 message
**Move:** Find the contention point / check the asymptotic behavior (does the planned speedup mechanism work the way the premise assumes?)
**Classification:** Macro (the concurrency model of the whole suite run) / Cold for this diff (nothing runs yet); Hot for Q-090 (every full-suite run)
**Confidence:** High for the mechanism (bats source read). Low for the size of its effect (not measured).
**Baseline:** 742 s wall, full suite, serial, `bats -T`, main 2bf5979, 2026-09-28 (`docs/working/proposal-2026-09-27-smaller-review-units.md:109-111`)
**Legibility-target:** for-orchestrator-synthesis

Evidence:

```bash
# /usr/libexec/bats-core/bats-exec-suite:33-36
  -j)
    shift
    num_jobs="$1"
    flags+=('-j' "$num_jobs")
```
(excerpt ends :36 inside the option `case`; the `;;` and the `-T` arm follow; read)

```bash
# /usr/libexec/bats-core/bats-exec-file:294-296
  if [[ "$num_jobs" != 1 && "${BATS_NO_PARALLELIZE_WITHIN_FILE-False}" == False ]]; then
    export BATS_SEMAPHORE_NUMBER_OF_SLOTS="$num_jobs"
    bats_run_tests_in_parallel "$BATS_RUN_TMPDIR/parallel_output" || bats_exec_file_status=1
```
(excerpt ends :296; an `else` branch with the serial per-test loop follows; read)

The commit message and the Q-090 entry describe the plan as "suite-level `bats --jobs`", with GNU parallel fanning out across files. In bats 1.8.2, `--jobs N` does more than that. The suite forwards `-j N` to every `bats-exec-file`, and each file then runs its own tests through `bats_semaphore_run` unless `--no-parallelize-within-files` or `BATS_NO_PARALLELIZE_WITHIN_FILE` is set. All files share one `BATS_RUN_TMPDIR`, so total concurrency stays capped at N slots. But slot acquisition is a busy-wait: `bats_semaphore_acquire_slot` runs a `find | wc -l` and then `sleep 1` in a loop (`/usr/lib/bats-core/semaphore.bash`, `bats_semaphore_acquire_slot`). With up to N file processes all waiting on one pool and an average test of about 0.35 s, freed slots sit idle for part of each polling interval. The speedup can therefore land well short of N×.

The larger risk is correctness, which also decides whether the speedup is usable. 0 of 123 `.bats` files set `BATS_NO_PARALLELIZE_WITHIN_FILE` (`rg -l` count). 3 files use `setup_file` and 2 use `BATS_FILE_TMPDIR`, which is state shared between tests in a file. The suite has only ever run tests within a file one at a time. This review ran no parallel suite, so the effect is unmeasured.

**Recommendation:** This does not block this diff. GNU parallel is the prerequisite for across-file parallelism whichever way Q-090 goes (fact-check Claim 2). For Q-090: start with `bats --jobs N --no-parallelize-within-files`, which uses across-file parallelism only (GNU parallel, no semaphore polling, and no change to how tests inside a file interact). Measure it against the 742 s baseline, then try within-file parallelism as a separate step.

#### 2. The Q-062 `/proc` scan in install.sh reads the real process table, and concurrent test processes will be in it

**Severity:** Informational
**Location:** `devcontainer-config/install.sh:1166-1182` (`procs_in_checkout`), exercised by `test/install-host.bats`
**Move:** Find the contention point (shared global state: the host's process table)
**Classification:** Macro (couples one test file to every other process of the uid) / Hot for Q-090's full-suite runs
**Confidence:** Low. The mechanism was read; no failure was observed under `--jobs`.
**Baseline:** no baseline available — flagged as speculative
**Legibility-target:** for-orchestrator-synthesis

Evidence:

```bash
# devcontainer-config/install.sh:1166-1175
procs_in_checkout() {
  local root d pid cwd cmd kind
  [ -d /proc/self ] || return 2
  root="$(cd "$REPO_ROOT" && pwd -P)" || return 3
  for d in /proc/[0-9]*; do
    [ -O "$d" ] || continue                     # this uid's processes only
    if cwd="$(readlink "$d/cwd" 2>/dev/null)"; then
      case "$cwd" in "$root"|"$root"/*) kind=in ;; *) continue ;; esac
    else
      kind=unknown
```
(excerpt ends :1175 inside the loop; the loop continues to :1181, where `in_lineage` exempts the script's own ancestors and descendants and prints `in`/`unknown` lines, and the function ends at :1182; read)

`install-host.bats` stubs `pgrep` (`test/install-host.bats:41`) but not this `/proc` walk. In serial runs the only other processes of the uid are the agent and its tools. pr-prep records that leftover probe processes already made install-host T33, T83 and T6 fail in full runs (`workflows/pr-prep.md` step 5a, "Quiesce before the gate"). Under `--jobs`, every concurrent test's processes also become "other processes of this uid". Each test's `ROOT` is its own `$BATS_TEST_TMPDIR/repo` (`test/install-host.bats:33`), so a sibling's readable cwd will almost never match `kind=in`. The exposure is to `kind=unknown`: any concurrent same-uid process whose cwd cannot be read (a non-dumpable process, for example one that exec'd a setuid binary) is refused. A flaky refusal under `--jobs` would cost a re-run and would also erode trust in the parallel gate.

**Recommendation:** This is not about this diff. When Q-090 adds `--jobs`, run `test/install-host.bats` repeatedly (for example 5 times) alongside the rest of the suite before trusting the parallel gate. If it flakes, run that file serially, or stub the `/proc` scan the way `pgrep` is stubbed.

#### 3. Putting `parallel` in the base apt layer rebuilds every layer from `Dockerfile:19` onward on the next image build

**Severity:** Low
**Location:** `devcontainer-config/Dockerfile:19-43` (added line :40)
**Move:** Price the deployment environment (build cost), and find the work that moved to the wrong place
**Classification:** Macro (a cache miss for most of the build) / Cold (one rebuild after a re-bless)
**Confidence:** Medium. Docker's layer-cache semantics apply; the actual rebuild time was not measured because there is no Docker in the sandbox.
**Baseline:** no baseline available — flagged as speculative
**Legibility-target:** for-author

Evidence:

```dockerfile
# devcontainer-config/Dockerfile:19-20, 38-43
RUN apt-get update && apt-get install -y --no-install-recommends \
  less \
  ...
  vim \
  bats \
  parallel \
  ripgrep \
  shellcheck \
  && apt-get clean && rm -rf /var/lib/apt/lists/*
```
(elided :21-37 are the other base packages; read in full)

Changing this RUN's text misses the cache for this layer and for every instruction after it. From the Dockerfile's instruction list, that covers the git-delta download (:87), uv (:113), shfmt (:168), the poppler and JDK apt layers (:195, :220), the Android cmdline-tools/platform/build-tools download (:238), rustup plus a pinned toolchain (:302), the .NET SDK (:360), zsh-in-docker (:391), `npm install -g @anthropic-ai/claude-code@latest` (:400) and elan/Lean (:454). Any Dockerfile edit changes `CC_CONFIG_HASH` (:481), so the layers after :481 rebuild regardless. The marginal cost of this placement is roughly lines 20-480, which are dominated by large toolchain downloads. This is a one-off cost on a cold path, and the rebuild happens anyway for the re-bless. One side effect to note: the claude-code layer at :400 floats on `latest`, so this rebuild also moves the baked Claude Code version.

**Recommendation:** Accept as is. The header's "Keep this file minimal-diff against upstream" rule (`Dockerfile:6`) and bats sitting in this list argue for the base layer, and the cost is paid once. The alternative, a separate late `apt-get install parallel` layer, would keep the cache but would re-run `apt-get update` and add another local divergence. Only take it if base-layer edits become frequent.

## Endorsements

- The added package goes through `--no-install-recommends` and the same RUN's `apt-get clean && rm -rf /var/lib/apt/lists/*`, so this edit adds no apt index or Recommends to the layer. `[read: devcontainer-config/Dockerfile:19-43]`
- Whether `parallel` pulls in extra Depends (for example `sysstat`) and how much installed size it adds is not established. Claim: "the `parallel` package adds under ~5 MB installed to the image, including any Depends not already present in `node:22`." Check with `dpkg-query -W -f='${Installed-Size}\n' parallel` in the rebuilt image. `[unverified — submitted as claim]` (route: code-fact-check)
- Concurrent run-log writes under `--jobs` are one short line per test, appended with `>>` (`/usr/libexec/bats-core/bats-exec-test:186`). The claim that these appends stay intact under parallel file execution, so `--failed` counting in `run-tests.sh` keeps working, has not been verified. `[unverified — submitted as claim]` (route: code-fact-check; check in Q-090 by comparing `.bats/last-run`'s count with the log's line count after a `--jobs` run)

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 3 | Base-layer placement rebuilds lines 20-480 (toolchains, SDKs, claude-code@latest) on the next build | Low | `devcontainer-config/Dockerfile:40` | Medium |
| 1 | `bats --jobs N` also parallelizes within files through a polling semaphore; 0/123 files opt out, so Q-090 should start with `--no-parallelize-within-files` | Informational | `/usr/libexec/bats-core/bats-exec-file:294-296` | High (mechanism) / Low (magnitude) |
| 2 | install.sh's Q-062 `/proc` scan sees concurrent test processes; install-host may flake under `--jobs` | Informational | `devcontainer-config/install.sh:1166-1182` | Low |

(Ordered by severity; numbering follows the Findings section.)

## Overall Assessment

The one-line change is fine from a performance standpoint. Its only direct cost is a one-off, cold-path rebuild of most of the image, which the re-bless triggers anyway. The premise also holds: GNU parallel is required for across-file `bats --jobs`, which is the right lever for a 742 s serial suite on 16 cores. The things that matter are for Q-090, not this diff:

- **Use across-file parallelism only at first.** Bare `--jobs N` also turns on within-file parallelism through bats' busy-wait semaphore, and this suite has never been exercised that way.
- **Watch install-host under `--jobs`.** Its `/proc` scan is the suite's one known coupling to "other processes of this uid".
- **The fixed `bats --count` step (~15 s, `scripts/run-tests.sh:52,364`) is not parallelized.** After a good speedup it becomes a noticeable share of wall time.

All three need a measured `--jobs` run in the rebuilt image, compared against the 742 s baseline.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-q086/docs/reviews/q086-performance-review-2026-09-28.md, structured per the performance-reviewer skill.
- Answered: yes
- Out of scope: building the image or measuring rebuild time (no Docker, no egress); running the suite under `--jobs` (`parallel` is not installed in the sandbox, and the brief forbids full-suite runs); the Q-090 run-tests.sh change itself (not in this diff).
- Escalate: Findings 1 and 2 are inputs to Q-090: `--no-parallelize-within-files` as the first configuration, and a repeated-run check of `test/install-host.bats` under `--jobs`. Both should be recorded on the Q-090 entry when this item merges.
- Decisions I made: I rated the base-layer placement Low rather than Informational because the invalidated span holds large network downloads, and it is still a cold path. I kept the premise findings Informational because they concern a follow-up, not this line.
