Commit: b4fd792

# Performance Review: ans/copy-install Q-058 restart (9ae6e46..b4fd792)

**Scope:** 8 commits, limited to `devcontainer-config/install.sh`, `test/install-host.bats`, `test/cc-isolated-functions.bats`, `README.md`, `docs/decisions/037-bare-host-copy-install.md`, `guides/bare-host-hook-wiring.md`, `docs/working/plan-copy-install-bare-host.md` and the commit messages. Code read in the worktree `/workspace/.claude/wt-copyinstall` at b4fd792.
**Date:** 2026-09-24
**Based on:** the Q-058 code-fact-check reports `docs/reviews/code-fact-check-report-r1.md`, `-r2.md` and `-r3.md` (k=3). One timing run by this reviewer is saved as `docs/reviews/execution-logs/q058-perf-b4fd792-suite-timing.log`. It is a baseline measurement only, not a behaviour verdict.

## Data Flow and Hot Paths

`install.sh` is a human-driven CLI that runs once per install, from a terminal. **Every path in it is cold.** The one latency-sensitive stretch is the time a human waits at the terminal: before the first output, and between typing `y` and the writes.

What the restart adds on that path:

- **`agent_gate`** (`install.sh:838-886`) runs up to three times per run: at startup (`:947`), after the devcontainer y (`:391`) and after the host y (`:695`). A `--yes` run calls it twice, because target 2 is skipped (fact-check r1, Claim 3: "NOTES=2"). Each call makes:
  - one `pgrep -u <uid> -af`, a single pass over `/proc`;
  - one `timeout 20 docker ps --filter label=cc-project`, plus a `mktemp`, `rm` and some `awk`/`printf` forks.
- **The NUL scan in `extract_commit`** (`:185-199`) runs `find | sort -z | perl -0ne`, which reads every staged file whole. The payload at b4fd792 is 122 files and 2,120,753 bytes. The claude-home part is 107 files and 1,927,394 bytes. The largest file is 99,052 bytes (`scripts/self-improvement.sh`). Measured with `git archive b4fd792 … | tar -tv` by this reviewer; the fact-check r3 count of 122 files agrees.
- **The `-L` walk** (`:334-345`) covers the path components between `REPO_ROOT` and `claude-home`.
- **The no-follow rebuild** (`:353-358`) is `rm`, then `mkdir`, then `cp -Rp …/.`.
- **Tests:** 15 new tests in `install-host.bats` (T50-T64), plus 2 stub files and a `chmod` added to the `setup()` of `install-host.bats` and `cc-isolated-functions.bats`. `install-host.bats` is `@category slow`, and `cc-isolated-functions.bats` is `@category fast`. `scripts/health-check.sh` step 5 runs both through `scripts/run-tests.sh`.

## Findings

#### 1. The docker probe can stall each gate silently for up to 20 s, three times per run (up to about 60 s)

**Severity:** Low
**Location:** `devcontainer-config/install.sh:859-868` (inside `agent_gate`, `:838-886`); call sites `:947`, `:391`, `:695`
**Move:** Count the hidden multiplications
**Classification:** Micro (fixed per-call timeout) / Cold path, but it blocks an interactive, latency-sensitive wait: a human at the terminal. Escalated from Informational to Low for that reason.
**Confidence:** High for the upper bound on docker's own process (fact-check r1 Claim 3 and r2/r3 read the `timeout 20`; see Finding 2 for the caveat). Medium for how often a host's docker actually hangs rather than failing fast.
**Baseline:** no baseline available — flagged as speculative
**Legibility-target:** the user running `install.sh` on the bare WSL host, and whoever maintains `agent_gate`

**Evidence:**
```bash
    errf="$(mktemp "${TMPDIR:-/tmp}/cw-docker-err.XXXXXX")"
    if ! ctrs="$(timeout 20 docker ps --filter label=cc-project \
                   --format '{{.Names}} cc-project={{.Label "cc-project"}}' 2>"$errf")"; then
      err="$(head -n 1 "$errf" 2>/dev/null)"
      echo "NOTE: docker is unreachable ($err): cc-isolated containers not checked, treated as none running." | vis
      ctrs=""
    fi
    rm -f "$errf"
    ctrs="$(printf '%s\n' "$ctrs" | awk 'NF')"
  fi
  if [ -z "$procs" ] && [ -z "$ctrs" ]; then return 0; fi
  … (excerpt ends at :869; agent_gate continues to :886 with the refusal block and `exit 1`, read)
```
```bash
  agent_gate "Nothing was staged or installed."        # :947, main, before any output about staging
  agent_gate "Nothing was installed. (devcontainer config)"   # :391, after the devcontainer y
  agent_gate "Nothing was installed into the host target."    # :695, after the host y
```

Nothing is printed before the probe. The NOTE line appears only once `timeout` fires.

On a host where docker hangs instead of failing fast, each of these runs adds a silent 20 s:
- the startup gate, before the first line of output;
- each post-`y` gate, between the user's answer and the writes.

An interactive run that answers y twice pays this three times, about 60 s. A `--yes` run pays it twice, about 40 s. Examples of a hanging docker: a Docker Desktop WSL integration whose VM is still starting, or a stale `DOCKER_HOST` pointing at an unresponsive endpoint.

The gate never reuses an earlier "unreachable" outcome. That is correct: a docker that comes up mid-run could start a container, so re-probing is the right trade. So the multiplication is the design, and the cost is in the per-call bound and the silence.

The usual cases cost little:
- docker absent: a `command -v` miss;
- docker daemon down: the CLI fails at once on a refused socket.

The ordering has a side effect that belongs to the security reviewer, not here. `pgrep` runs (`:845`) *before* the docker wait. A Claude Code process that starts during a slow docker probe is therefore not seen by that gate call, so the probe's latency widens the gap between sampling and writing. See Escalate.

**Recommendation:**
- Print a progress line such as `Checking for cc-isolated containers (docker)…` before the probe, so a stall is visible.
- Consider lowering the timeout to about 5 s: `docker ps` against a live local daemon normally answers well under that. This needs a real-host measurement first; see the note at the end.
- Consider probing docker before `pgrep`, so the slow detector does not sit between the fast detector's sample and the writes.

#### 2. `timeout 20` bounds docker's own process, not the pipe that `$( … )` waits on

**Severity:** Informational
**Location:** `devcontainer-config/install.sh:860-861`
**Move:** Trace the resource lifecycle
**Classification:** Micro / Cold (an edge case of Finding 1's bound)
**Confidence:** Low
**Baseline:** no baseline available — flagged as speculative
**Legibility-target:** the maintainer of `agent_gate`, and the fact-check stage (submitted claim)

**Evidence:**
```bash
    if ! ctrs="$(timeout 20 docker ps --filter label=cc-project \
                   --format '{{.Names}} cc-project={{.Label "cc-project"}}' 2>"$errf")"; then
```

`timeout` sends SIGTERM to its direct child after 20 s, and there is no `-k` escalation to SIGKILL. The command substitution returns only when every holder of its stdout pipe has closed it.

That gives two ways past the 20 s:
- a `docker` that is a wrapper script running the real CLI as a child instead of via `exec`;
- a CLI that ignores SIGTERM while it is blocked.

In either case the substitution can outlast 20 s and, in the worst case, never return. The fact-checks read the 20-second bound (r1 Claim 3; r2 and r3 scope notes) but did not execute a hanging docker. They note that the "hangs past 20 s" case was not established.

**Submitted claim:** "With a `docker` stub that runs `sleep 60` as a non-exec child, `agent_gate` returns after about 60 s, not 20 s. `timeout -k 5 20` does not change that, because the orphaned grandchild still holds the pipe." `[unverified — submitted as claim]`

**Recommendation:** If the fact-check stage confirms the claim, redirect the probe's stdout to the existing temp-file pattern instead of a pipe (as stderr already is), and add `-k 5`. The gate then waits at most 25 s whatever docker spawns.

#### 3. T50-T64 add about 20 s (+35%) to the two changed suites, and a third of that is `path_without`

**Severity:** Low
**Location:** `test/install-host.bats:382-396` (`path_without`), called by T52 (`:454`), T53 (`:475`) and T57 (`:526`); fixed sleeps in T55 (`:878-879`) and T54 (through `FEED_TAMPER`, `:164-166`, which predates this range)
**Move:** Count the hidden multiplications
**Classification:** Micro (per-executable fork) / Cold (test suite, but it runs in every `health-check.sh` and `run-tests.sh --slow`)
**Confidence:** High for the totals (measured). Medium for how much of each test is `path_without` (inferred by comparing tests, not profiled).
**Baseline:** `bats --timing` on `test/install-host.bats` and `test/cc-isolated-functions.bats` at b4fd792: the per-test times sum to 77,922 ms across 156 tests. T50-T64 sum to 20,166 ms. Measured 2026-09-25T06:57Z in this sandbox; log at `docs/reviews/execution-logs/q058-perf-b4fd792-suite-timing.log`. The runner's `wall_s` line is empty because `bc` is missing, so the per-test `--timing` figures are the measurement.
**Legibility-target:** whoever maintains `scripts/run-tests.sh` and `health-check.sh` runtime, and the author of `install-host.bats`

**Evidence:**
```bash
path_without() {
  local farm="$S/farm" dir f skip
  mkdir -p "$farm"
  local IFS=:
  for dir in $PATH; do
    [ "$dir" = "$STUB" ] && continue
    for f in "$dir"/*; do
      [ -x "$f" ] && [ ! -d "$f" ] || continue
      for skip in "$@"; do [ "${f##*/}" = "$skip" ] && continue 2; done
      [ -e "$farm/${f##*/}" ] || ln -s "$f" "$farm/${f##*/}"
    done
  done
  for skip in "$@"; do rm -f "$STUB/$skip"; done
  printf '%s:%s\n' "$STUB" "$farm"
}
```

Measured per-test times from the log above:

| Test | What it does | Time |
|---|---|---|
| T51 | refused at the startup gate, stubs only | 59 ms |
| T53 | refused at the startup gate after `path_without pgrep` | 2,342 ms |
| T57 | refused before the gate after `path_without perl` | 2,393 ms |
| T52 | two runs plus one `path_without docker` | 2,351 ms |

T51 and T53 refuse at the same point, so the roughly 2.3 s difference is `path_without`. That fits this PATH: 2,018 executables, each costing one `ln -s` fork (`sizes.sh` count by this reviewer). Three calls come to about 6.8 s, around a third of the 20.2 s the new tests add.

T54 (2,325 ms) and T55 (3,173 ms) spend most of their time in fixed `sleep 2` and `sleep 1` waits. Those are deliberate pty-timing waits, and T54's comes from the older `FEED_TAMPER` helper.

The added `setup()` stubs cost only two `printf` calls and a `chmod` per test, which is negligible. The scaling factor is the size of the PATH on the machine running the tests. The cost is linear and bounded, but it is paid three times on every slow-suite run.

**Recommendation:**
- Build the farm once per file in `setup_file`, or cache it under `$BATS_FILE_TMPDIR` keyed by the skipped name.
- Or link only the handful of tools `install.sh` needs (`bash git perl find sort diff tar mktemp timeout awk sed …`) instead of all 2,018 executables.

Either cuts about 6 s from each slow run. This is not a merge blocker.

#### 4. The claude-home payload is NUL-scanned three times per interactive run

**Severity:** Informational
**Location:** `devcontainer-config/install.sh:185-199` (inside `extract_commit`, `:140-200`); callers `:219` (`assemble`, both targets) and `:349`
**Move:** Count the hidden multiplications / Find the work that moved to the wrong place
**Classification:** Micro / Cold
**Confidence:** High (the structure is read; the call sites are confirmed by fact-check r2 and r3, "Claim 5"/"r3:66-77")
**Baseline:** no baseline available — flagged as speculative. The payload size above is a size, not a timing.
**Legibility-target:** the maintainer of `extract_commit`

**Evidence:**
```bash
  local nul
  if ! nul="$(cd "$dir" && find . -type f -print0 | LC_ALL=C sort -z | LC_ALL=C perl -0ne '
        chomp; open(my $f, "<:raw", $_) or die "$_: $!\n";
        my $c = do { local $/; <$f> };
        print substr($_, 2), "\n" if defined $c && index($c, "\0") >= 0;')"; then
```
```bash
  assemble "$stage/claude-home" "${dc_paths[@]}"          # :348 → extract_commit on $stage/claude-home
  extract_commit "$STAGED_COMMIT" "$stage" "${dc_paths[@]}"   # :349 → find . over $stage, claude-home included
```

The `:349` call scans `$stage`, which already contains the claude-home that `assemble` scanned a line earlier. The host target's `assemble` (`:585`) then scans a fresh claude-home a third time. That is about 1.93 MB × 3 + 0.19 MB, roughly 6 MB, read by perl per interactive run.

Each file is slurped whole, so peak memory is bounded by the largest file (99 KB). This is far below anything a human would notice, and it grows only linearly with the committed payload. The commit note's "well under a second" is consistent with these sizes.

**Recommendation:** None needed now. If the payload ever takes large or binary-allowlisted files, scope the `:349` scan to the items that call just extracted, for example with `find "$@basenames"`.

## Endorsements

- **The `-L` walk is constant-cost.** `SRC` is the script's directory (`:78`) and `REPO_ROOT` is `$SRC/..` (`:85`), so `${SRC#"$REPO_ROOT"/}/claude-home` is `devcontainer-config/claude-home`. The walk makes two `[ -L ]` builtin tests and forks nothing except on the refusal path. `[read: devcontainer-config/install.sh:78,85,334-345]`
- **The no-follow rebuild costs the same as the copy it replaced.** Replacing `cp -Rp src dst` with `mkdir dst` plus `cp -Rp src/. dst/` adds one `mkdir` fork and copies the same tree once. `[read: devcontainer-config/install.sh:353-358]`
- **Checking the vis exit adds no work.** It reads `PIPESTATUS` from the pipeline already run per item, with no extra process or pass over the diff. `[read: devcontainer-config/install.sh:261-271]`
- **The `pgrep` detector costs one pass over `/proc` per gate call, a few milliseconds even on a busy host,** and its output is post-filtered by one `awk`. `[unverified — submitted as claim]`
- **The per-test stubs in `setup()` of both suites add under 5 ms per test.** Consistent with T51's 59 ms total, but not isolated. `[unverified — submitted as claim]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Docker probe: a silent stall of up to 20 s per gate, 3 gates (about 60 s) when docker hangs | Low | `install.sh:859-868`, `:391`, `:695`, `:947` | High (bound) / Medium (frequency) |
| 3 | T50-T64 add 20.2 s (+35%) to the two suites; `path_without` is about 6.8 s of it | Low | `test/install-host.bats:382-396` | High (totals) / Medium (attribution) |
| 2 | `timeout 20` does not bound a docker whose child holds the stdout pipe | Informational | `install.sh:860-861` | Low |
| 4 | claude-home NUL-scanned 3× per run (about 6 MB, sub-second) | Informational | `install.sh:185-199`, `:349` | High |

## Overall Assessment

The restart has a sound performance posture for a once-per-install, human-driven CLI, and nothing here should block the merge. Every new cost sits on a cold path and scales with small, bounded inputs:
- the 122-file, 2.1 MB payload;
- two path components in the `-L` walk;
- one `/proc` pass per gate.

The only user-visible risk is Finding 1: on a host where docker hangs rather than failing fast, the gate adds up to about 60 s of silent waiting. Part of that wait falls between the user's `y` and the writes. A progress line fixes the silence in place. Shortening the timeout needs a real-host measurement first: time `docker ps` against the user's Docker Desktop on WSL, both when it is running and when it is stopped.

Finding 2 is a possible hole in the 20 s bound and should go to the fact-check stage as a submitted claim.

Finding 3 is a test-runtime cost worth trimming in a follow-up. It is roughly 6.8 s per slow-suite run, spent in `path_without`.

No structural problem.

## Goal-Alignment Note
- Success criterion (restated verbatim): "a markdown report saved to the output path named at the end of this prompt, structured per the skill."
- Answered:
  - The worst-case wall time of the three docker probes is about 60 s interactive and about 40 s under `--yes`, all of it silent (Finding 1). It may be unbounded if docker's child holds the pipe (Finding 2, unverified).
  - The NUL scan is about 6 MB of reads per run, with 3× redundancy on claude-home. That is negligible (Finding 4).
  - The `-L` walk is constant: two builtin tests (Endorsements).
  - T50-T64 add 20,166 ms to a 77,922 ms two-suite total, +35% over the prior 57.8 s. About 6.8 s of that is `path_without`, and about 3 s is fixed pty sleeps (Finding 3).
  - On performance grounds the Q-058 restart is safe to merge: no finding is above Low.
- Out of scope:
  - whether the gate catches every agent (security or fact-check);
  - whether the reds R1 and R2 are resolved;
  - the correctness of decision 037's residual text;
  - the `docs/reviews/` files, which were context only;
  - live behaviour of a real docker, since there is no docker in the sandbox.
- Escalate:
  - To security-reviewer: `agent_gate` samples `pgrep` before a docker probe that can take up to 20 s (`:845` vs `:860`). A Claude Code process that starts during a slow probe is not seen by that call, so the probe's latency widens the gap between sampling and writing on the post-`y` gates.
  - To the fact-check stage: Finding 2's submitted claim, `timeout` plus the pipe held by a grandchild.
  - To the user (you: terminal): time `docker ps --filter label=cc-project` on the bare host with Docker Desktop stopped and started. That measurement decides whether Finding 1's timeout should shrink.
