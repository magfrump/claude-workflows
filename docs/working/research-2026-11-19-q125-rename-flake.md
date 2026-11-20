# Research: `test/q125-verify-check.bats` rename case flaky under load

Brief: `docs/working/briefs/2026-11-19-q125-rename-flake.md`. Branch `fix/q125-rename-flake`.

Failure-pattern grep: FP-174, FP-175 (`rg -n 'flak|under load|timing|race'` over the FP entry lines; both are flakes under parallel load, but from a `find` racing deletions and a SIGPIPE under pipefail, not a timing window, so neither's fix shape applies)
Failure-pattern skip: the fix is a test-only margin on a fixed timing window plus one fixed sleep swapped for a poll; the lesson ("wait on a signal, not a sleep") is generic, and no gate or shipped code was wrong

## Reproduction

`bats -f unsandboxed <copy of the test with Q125_X4_SECONDS=1>` fails 3 of 3 (0, 1 and 0 renames). At the shipped value 2 it passes idle with 2 to 3 renames against a need of 2, so one rename of slack. A CPU-spinner load (2 spinners, 10 runs; 24 spinners on 16 cores, 6 runs) did not reproduce it on the old file (10/10, 6/6): the observed failures came from parallel bats suites, which load process spawning, not just CPU. A deterministic stand-in for load (the renamer's 0.5 s sleep made 2.5 s in a copy of the check script) fails the old test on both renamer cases and passes the new one (below).

## Cause

`docs/working/q125-verify-check.sh` starts a background renamer that polls every 0.5 s for `$SIG/go`, then replaces the credential by rename every 0.5 s until `$SIG/stop`, writing its count to `$D/renames`. `X4-renamer-ran` passes on a count of at least 2. Two places in the test bound how long the renamer gets:

1. **The exec case** (line ~190). x.sh (inside the script) touches `go`, reads for `Q125_X4_SECONDS` on bash's integer `SECONDS` clock (`end=$((SECONDS + x4s))`, so the window is between x4s-1 and x4s seconds), then touches `stop`. The renamer needs up to 1 s idle for two renames (up to 0.5 s to see `go`, then 0.5 s between renames). With 2 the window can be just over 1 s: no margin.
2. **The canned cases** (the fake `claude`'s own go/stop act). It slept a fixed 1.5 s between `go` and `stop`: about 0.5 s of margin. Same cause; "every check passes" asserts `X4-renamer-ran pass` too.

The script offers no signal x.sh's window could wait on (its loop ends only on its own clock), and the script is not this brief's to edit.

## Design choice (divergent design, short form)

Options for the exec case, seeded by the brief (test file only, do not weaken) and constraints H3 (hermetic), S4/S8 (small, explicit):

| Option | What | Verdict |
|---|---|---|
| A. Bigger fixed window for the exec case only | `Q125_X4_SECONDS=8` on that case | survives; costs about 6 s on one case |
| B. PATH `sleep` shim that holds x.sh until renames >= 2 | event-bound | rejected: the shim also slows the renamer and the script; clever, opaque |
| C. Fake `claude` touches `go` itself and waits for renames before running x.sh | event-bound | rejected: x.sh's own `go` signal goes untested, which weakens the case |
| D. Fake `claude` rewrites the seconds argument | | rejected: runs a command other than the allowed rule; same effect as A, hidden |
| E. Make x.sh end its window on the renames file | | out of scope: edits the check script (would be a blocked marker) |

Path A: A dominates. For the canned cases the fake `claude` is the test's own code, so it waits on the observable the brief asks for: it polls `$D/renames` (D is the directory of x.sh, argv[1]) until it reads 2 or more, giving up at 30 s so a dead renamer still fails.

Why 8 is enough: the window is then more than 7 s, against up to 1 s of renamer work idle, seven times the idle need. Idle it gets about 16 renames.

## Change

`test/q125-verify-check.bats` only: the exec case passes `Q125_X4_SECONDS=8` (setup keeps 2; no other case runs x.sh), with a comment giving the bound; the fake `claude`'s canned go/stop waits on `$D/renames` (>= 2, 30 s cap) instead of `sleep 1.5`.

## Mutations (a copy of the check script, run through a copy of the test)

| Mutant | "every check passes" | exec case |
|---|---|---|
| renamer never renames (`plant` and the count write replaced by `:`) | fails (0 renames) | fails (0 renames) |
| renamer stops after one rename (`-lt 400` to `-lt 1`) | fails (1 rename) | fails (1 rename) |
| renamer five times slower (`sleep 0.5` to `sleep 2.5`), OLD test | fails (1 rename) | fails |
| renamer five times slower, NEW test | passes (2 renames) | passes (4 renames) |

So the cases still fail when the renamer does not run (or runs once), and the new file tolerates a slow renamer the old one did not.

## Counts

New file, `bats test/q125-verify-check.bats` (all 10 cases) each run:

- 10 runs with two `timeout 900 sh -c 'while :; do :; done'` spinners alongside (started and stopped by PID in the probe script): **10/10 passed**.
- 1 run with no load: **1/1 passed**.
- No spinner left running afterwards (`ps` checked).

For comparison, the old file under the same 2-spinner load passed 10/10 and under 24 spinners 6/6: CPU spinners alone do not reproduce the flake on this 16-core machine, which is why the slowed-renamer mutant above is the evidence that the new margin matters.

## Review

One review round (fresh subagent, read-only): no blocking or should-fix findings. Nits taken: the window's upper bound was stated too tightly (the last loop pass adds about 0.2 s; measured 1.2-1.8 s at x4s=2), and "2-3 renames" / "sevenfold" were loose; the comment now states only the lower bound and the idle need.
