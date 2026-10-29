# Research: the flaky "file that vanishes" ancestor-listing test

Brief: `docs/working/briefs/2026-10-29-flaky-vanish-test.md` · Date: 2026-10-29 · Branch: fix/flaky-vanish-test

## The case

`test/scripts/build-loop-check.bats`, "the ancestor listing skips a file that vanishes between
find's readdir and its stat, ... (Q-145)". A PATH shim wraps `find`; on the `-H` top-level
listing (`top_files` in `scripts/lib/dev-cycle-read.sh`) it injects a clause that deletes
`vic*` entries under the fixture's ancestor (`$BATS_TEST_TMPDIR`) mid-listing, and logs each
listing's exit status. The asserts compare that log exactly: no failed listing for vanished
files, `1 0` for a vanished directory (one failed try, one clean retry), and `1 1 1` / `0 0 0`
for the fail-closed cases.

## Reproduction

Reproduction: `for i in $(seq 8); do timeout 170 bash -c 'while :; do d=$(mktemp -d /tmp/vchurn.XXXXXX) && sleep 0.005 && rmdir "$d"; done' & done; for i in $(seq 6); do timeout 300 bats -f "vanishes between" test/scripts/build-loop-check.bats; done`
(at 690f099d): **0 of 6 pass**.

- With no churn of mine (meant as a CPU-load run, but a script bug let the busy loops end
  before the runs began, so this was the machine's ambient load from other sessions): 19 of
  20 pass; the failure was `want a failed try, then a clean one: 1 1 0` (the clean retry
  failed too). find's stderr was not captured for it; by H1 the likely source is another
  session's `mktemp -d` under `/tmp`.
- Under the churn the failures were `a listing failed: 1` (files section),
  `want a failed try, then a clean one: 1 ...` (directories section) and `tree: walk: failed`
  (all three tries failed), and find's stderr named the churned directories:
  `/usr/bin/find: '/tmp/vchurn.Q2szsb': No such file or directory`.
- Alone, on a quiet machine: passes.

## Hypothesis log

- H1: the shim's listings also read start points outside the fixture, and another process's
  short-lived directory there vanishes between find's readdir and its stat, so find exits 1 on
  a listing the test's log expects to be clean · tested: logged the shim's argv (the tops are
  `$a $a/.. .../bats-run-X/test /tmp/bats-run-X /tmp / $a/.claude`, so `/tmp` and `/` are read
  at depth 1), then ran the case under short-lived `/tmp` directory churn with find's stderr
  teed to a scratch log · result: confirmed · learned: 0 of 6 pass, and every extra error names
  a churned `/tmp` entry. (A first churn of `mkdir`+`rmdir` with no gap passed 10 of 10: the
  window needs a directory that lives long enough to be read, as a real `mktemp -d` does.)

## Cause

Not the code under test. `top_files` behaves as designed (Q-145): a vanished directory fails
a listing and `config_seeds` retries up to three times, failing closed after three. The test
is what depends on the machine: its exact exit-status log assumes the only racing entries are
the ones its shim deletes, but the walk lists every ancestor of the fixture, and `/tmp` (and
the bats run directory, shared by files run in parallel under `--jobs`) holds other processes'
short-lived directories. On a loaded machine with parallel suites and concurrent sessions
(load 8 to 11 in the failing health checks) one of them vanishes mid-listing often enough to
add an unexpected `1` to the log.

Not the skill-frontmatter flakes in the idea log: nothing shared was found (this cause needs a
`find` listing of `/tmp`).

## Options (divergent design, seeded with docs/constraints.md and the brief)

| Option | Deterministic | Keeps the proof | Within Paths | Verdict |
|---|---|---|---|---|
| A. The shim drops start points outside `$a` before calling the real find | yes: no shared directory is read | yes: the injected race and every asserted status are unchanged | yes | chosen |
| B. Loosen the asserts (accept extra `1`s, check only "some retry happened") | no for the walk-failed case | no: `1 0` vs `1 1 0` is what proves a clean retry is used | yes | rejected |
| C. Move the fixture so its ancestors are quiet | no: `/tmp` and `/` stay tops whatever `$BATS_TEST_TMPDIR` is | yes | yes | rejected (cannot) |
| D. Retry the whole case on failure | no: masks | partly | yes | rejected (hides real regressions, S3 spirit) |
| E. Change `top_files` / `config_seeds` | n/a | n/a | no: gate code, out of Paths | rejected (the code is not wrong) |

A dominates: decide and continue.

## Fix

In the case's shim, start points that are absolute paths outside `$a` are dropped; every
argument that is not an absolute path (the options) and every path at or under `$a` is kept (with the existing `SHIM_RMTOP=drop` exception), and the shim exits
8 if `$a` itself is ever missing from the kept list, so a change in how tops are passed fails
the case loudly rather than turning it into a no-op. The lib still computes every top and
rechecks each with `-d`; only find's reading of the shared ancestors is cut, which no assert
depended on.

## Verification

- The case passes alone.
- Under the reproducing churn (the 8 loops that failed the old case 6 of 6) plus 16 busy
  loops, load average 24 to 33: **20 of 20 pass**.
- Falsifiers, run by the reviewer on scratch copies of the lib (nothing committed): with
  `-ignore_readdir_race` removed from `top_files`, the fixed case fails at
  `a listing failed: 1`; with `config_seeds` cut to a single `top_files` try, it fails at
  `tree: walk: failed`. So it still proves what it proved.
- `shellcheck -S warning` and `scripts/hermeticity-lint --root .` pass, and the whole
  file passes (154 of 154).
- Review: one independent reviewer pass, verdict correct, three low findings (two doc
  wording items, fixed here; one pre-existing residual, noted below).

Residual: `config_seeds` also lists `/tmp/.claude` and `/.claude` as config dirs when they
exist, with unshimmed finds; neither exists here, and a test fixture cannot control them.
The lib failing a real walk closed after three listings that each meet a vanished directory
(seen under the heavy churn) is its documented Q-145 design, not changed here.
