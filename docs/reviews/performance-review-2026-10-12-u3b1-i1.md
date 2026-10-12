# Performance Review — feat/build-loop-u3b1 (U3b1, review-fix iteration 1)

**Scope:** `git diff main...HEAD` on `feat/build-loop-u3b1` (`scripts/build-loop.sh`; the test file and plan note were read for intent only)
**Date:** 2026-10-12
**Based on:** `docs/reviews/code-fact-check-report-u3b1-i1.md` (Claims 1, 19, 21, 24; override row 690)

Probe provenance: git 2.39.5, bash 5.2, WSL2, 16 cores. Every probe ran under `set -eu` in its own `mktemp -d /tmp/u3b1perf-XXXX` directory, refused to run git outside it, and removed it at the end. No worktree file was changed. The scripts and logs are in `/tmp/claude-1000/-workspace/402ec840-a464-40f5-96ae-98af0cc535cf/scratchpad/u3b1/perf/` (`p1`–`p4`, with `.sh` and `.log` files), abbreviated `$PF` below. Peak RSS is `RUSAGE_CHILDREN.ru_maxrss` read by `$PF/rss.py`. That is the largest single descendant process, not the sum across them.

## Data Flow and Hot Paths

- **`--state`** (`scripts/build-loop.sh:1527-1529`, `state_start` at `:1149-1155`, `caller_gate` at `:517-529`, the new `default_gate` check at `:544-545`) runs once at the start of every orchestrator iteration. It is the most frequent of the new paths but still a per-iteration CLI call, not a tight loop. Its cost is dominated by `store_check --main`, which existed before this branch and re-hashes every tree and blob of main and lists every pack index. The diff adds 3 small git processes: `rev-parse --local-env-vars`, `config --list`, and `show-ref`.
- **`--marker BRIEF`** (`:800-844`) runs once per blocked or stopped marker SHA. Plan D4/`:65` files an entry "once per marker SHA". So the path is cold by frequency, but its input is untrusted: the commit message at a loop's branch tip has no size bound.
- Data sizes: main's tree here is 3,778 entries and 66.8 MB of blobs (`git ls-tree -r -l main` on /workspace). A marker body is whatever the loop commits. The brief gives "multi-MB" as realistic.

## Findings

#### --marker slurps the whole untrusted body into Perl arrays before the 100-line cap: about 70x memory amplification

**Severity:** Medium
**Location:** `scripts/build-loop.sh:811-828` (the `body="$(printf '%s\n' "$body" | scrub | env ... perl -e '...')"` block in `marker()`; the remainder of `marker()`, `:829-844`, works only on the capped output)
**Move:** Memory lifecycle / what's the size of N
**Classification:** Macro (memory grows with body size, with no bound) / Cold path (once per marker SHA) over untrusted, unbounded data, so escalated per the hot-path gate
**Confidence:** High (measured)
**Baseline:** 1,156 MB peak RSS and 16.7 s wall for `--marker` on a 16 MB body of 3-byte lines (5.6 M lines). For comparison, `--status` on the same tip took 131 MB and 1.3 s. Measured 2026-10-12, `$PF/p3.log`.
**Legibility-target:** implementer of `marker()`, and the orchestrator design (plan D11), which assumes `--marker` either prints or skips

Evidence (verbatim, `:813`):
```perl
    my @l = map { s/\n\z//r } <STDIN>; pop @l while @l && $l[-1] =~ /^[ \t]*\z/;
```
followed at `:818` by `my ($k, $cut) = (@l > $ENV{N} ? $ENV{N} : scalar @l, 0);`. The cap is applied only after every line is held. Excerpt ends inside the perl program: the per-line rule loop is at `:814-817` and the cap/print loop at `:818-827`.

`<STDIN>` in list context builds one list of every line, and `map` builds a second. Perl's per-scalar overhead is roughly 50+ bytes, so short lines cost far more than their size. Isolated on the same 16 MB input, this Perl program alone peaked at 1,157 MB and took 4.2 s (`$PF/p4.log`). Time scales linearly; I measured no quadratic term:

| Body | `--marker` | `--status` |
|---|---|---|
| 4 MB, 3-byte lines | 4.0 s / 292 MB | 0.37 s / 31 MB |
| 16 MB, 3-byte lines | 16.7 s / 1,156 MB | 1.3 s / 131 MB |
| 16 MB, 52-byte lines | 3.1 s / 146 MB | 1.0 s / 146 MB |
| 16 MB, one line | 2.2 s / 133 MB | 1.4 s / 132 MB |

(`$PF/p2.log`, `$PF/p3.log`.) Extrapolating linearly, which is speculative beyond 16 MB, a 100 MB marker of short lines needs about 7 GB. That is enough for the OOM killer on a WSL2 VM. The run then dies with no `ok` or `skip` line. The header (`:368`) documents a `--marker` skip as an exit-0 line, so a dead run is a third outcome the orchestrator's flow does not name. A loop can produce it just by committing a large message.

**Recommendation:** Stream the Perl program with `while (my $s = <STDIN>)`. Check the rule on each line as it arrives, which keeps the deliberate rule-past-the-cap behaviour (fact-check Claim 2). Keep only the first `N` lines, count the rest, and track trailing blank lines with a counter instead of `pop`. Memory then drops to O(N·B), about 30 KB. Optionally also cap the body's bytes before `scrub` (for example `head -c` some multiple of `N*B`), with a skip when it is exceeded. That bounds time too. The cost is that a grammar line very deep in a huge body would no longer be seen, which is acceptable because it is never printed. Add a test with a body over the byte cap.

#### --marker runs scrub over the full unbounded body: about 4 s per 16 MB of short lines before any cap

**Severity:** Low
**Location:** `scripts/build-loop.sh:811` (`printf '%s\n' "$body" | scrub | ...`); `scrub` is at `scripts/lib/dev-cycle-read.sh:127-145`
**Move:** Hidden multiplication (per-line Perl regex loop × unbounded line count)
**Classification:** Micro (constant per-line cost) / Cold path (once per marker SHA)
**Confidence:** High (measured)
**Baseline:** `scrub` alone took 3.98 s wall at 9 MB RSS on 16 MB of 3-byte lines. Measured 2026-10-12, `$PF/p4.log`.
**Legibility-target:** implementer of `marker()`

Evidence (`:810-811`):
```bash
  # Scrubbed first, so the rules, the caps and FENCE_AWK read what is printed.
  # Prints "rule N", or the quoted lines (no lines: nothing but blanks).
```
`scrub` streams, so its memory stays bounded. Its 4096-byte line cut bounds work per line but not the number of lines. With the Perl slurp above, scrub accounts for about a quarter of the 16.7 s. Scrubbing before the rule is a correctness choice (fact-check Claim 19), and I do not recommend reordering it. A byte cap on the input, as suggested in the first finding, bounds this cost as well.

**Recommendation:** No separate change needed. Folding a pre-scrub byte cap into the first finding's fix addresses both.

#### --marker reads the marker commit a fourth time

**Severity:** Informational
**Location:** `scripts/build-loop.sh:808` (`m="$(git cat-file commit "${STATUS[sha]}")"`); the earlier reads are in `marker_kind` at `:708` and `:714`, reached through `status_fields` at `:803`
**Move:** Work in the wrong place (repeated reads of the same object)
**Classification:** Micro / Cold
**Confidence:** High
**Baseline:** `--status` on a 16 MB marker, which includes marker_kind's reads, took 1.0 s. On the same input `--marker` took 3.1 s (52-byte lines; `$PF/p3.log`). The extra `cat-file` plus bash copies are a small part of that difference.
**Legibility-target:** implementer (no action expected)

Evidence (`:808`, in a comment line above it at `:807`): `# marker_kind has refused a NUL and a second subject line; the headers end at the first empty line.` / `m="$(git cat-file commit "${STATUS[sha]}")" || { echo "skip $a: its marker could not be read"; return; }`. Reading the object again is the simpler design: it avoids threading marker_kind's `msg` out through `STATUS`. The cost is linear and small next to the first finding.

**Recommendation:** Leave it. Revisit only if the first finding's fix makes the read a measurable share.

#### --state's per-iteration cost is store_check's full re-hash of main, which scales with the repository

**Severity:** Informational
**Location:** `scripts/build-loop.sh:1149-1155` (`state_start`), `:1527-1529` (the `state)` case); store_check at `:899-941` (unchanged by this diff)
**Move:** Size of N / price the deployment environment
**Classification:** Macro (linear in main's blob bytes and in pack-index entries) / Warm (once per orchestrator iteration)
**Confidence:** High (measured)
**Baseline:** `--state` took 0.33 s wall (3 runs: 0.325, 0.326, 0.337 s) on a `--no-local` clone of /workspace main (20,211 objects, 1 pack, 27.9 MB pack, 3,778 tree entries). `--status` on the same clone took 0.065 s. Measured 2026-10-12, `$PF/p1.log`.
**Legibility-target:** orchestrator design (D13), and row 690's revisit

Evidence (`:1149-1155`):
```bash
state_start() {
  default_gate || exit 2
  GATE_TMP="$(mktemp -d)"; trap 'rm -rf -- "$GATE_TMP"' EXIT
  gate_repo || { echo "refuse state gate: its merge repository could not be set up"; exit 2; }
  store_check --main "$MAIN_SHA" \
    || { echo "refuse state objects: ...
}
```
(The refusal text is abbreviated; the function ends at `:1155`.) Every iteration re-hashes all of main's 66.8 MB of blobs and lists every pack's index. That is fine at today's size: 0.33 s per iteration. It grows linearly with repo size and pack count. The /workspace checkout itself holds 5 packs and 22 k objects against the clone's 1 pack. The diff's own additions to `--state` (caller_gate's 2 git calls, default_gate's `show-ref`) are a few milliseconds each and do not appear in the 0.33 s at this resolution. As the fact-check report notes (Claim 24), row 690's dispatch-cost half is unchanged: `--start` and `--prompt` still run the full `gate_start`. This diff neither adds that cost nor removes it.

**Recommendation:** No change for U3b1. If the repo grows by an order of magnitude, measure again before relying on `--state` at every iteration.

## Endorsements

- `--marker`'s FENCE_AWK passes and its `sed` de-quote run on the capped output, at most 101 lines of about 302 bytes each, not on the raw body. Their cost is therefore bounded whatever the marker's size. `[read: scripts/build-loop.sh:829-841]`
- `--marker`'s cost scales linearly with body size across 1, 4 and 16 MB, with no quadratic term from bash's `${m#*$'\n\n'}` / `${m#*$'\n'}` prefix strips on multi-MB strings (lines: 0.23 / 0.72 / 2.86 s; one line: 0.17 / 0.46 / 1.99 s). `[unverified — submitted as claim]` I measured this (`$PF/p2.log`), but not as a fact-check execution verdict.
- `--marker` is ungated, so a blocked brief does not repeat `store_check`. The orchestrator's single `--state` per iteration covers the store, and the gated cost is paid once rather than once per brief. `[read: scripts/build-loop.sh:561-563]`
- harden's decimal check for GIT_CONFIG_COUNT and caller_gate's work are constant-size: one regex, one `rev-parse --local-env-vars`, one `git config --list`. `[read: scripts/build-loop.sh:446-450, 517-529]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | --marker slurps the whole untrusted body into Perl arrays before the cap (1.16 GB per 16 MB of short lines) | Medium | `scripts/build-loop.sh:811-828` | High |
| 2 | scrub runs over the full unbounded body (about 4 s per 16 MB of short lines) | Low | `scripts/build-loop.sh:811` | High |
| 3 | Marker commit read a fourth time | Informational | `scripts/build-loop.sh:808` | High |
| 4 | --state per iteration = store_check's full re-hash of main (0.33 s today) | Informational | `scripts/build-loop.sh:1149-1155` | High |

## Overall Assessment

The branch is performance-sound on its warm path. `--state` costs 0.33 s per iteration at today's repo size, and almost all of that is the pre-existing `store_check`. The new caller and default-branch checks are negligible. The one real issue is Finding 1. `--marker` takes an unbounded, loop-controlled commit message and materializes every line in Perl before applying its 100-line cap. A loop can push memory to gigabytes and wall time into tens of seconds just by committing a large message of short lines, and at the extreme get the run killed with no `ok`/`skip` line. The fix stays in place: stream the Perl loop, optionally byte-cap the input before scrub, and keep the rule semantics. It needs no structural change. All numbers above are measured, not estimated. Only the extrapolation past 16 MB is speculative.

## Goal-Alignment Note

The unit's goal is a `--marker` that turns an untrusted loop body into a safe, bounded quote the orchestrator can paste into a questions entry, plus a `--state` check cheap enough to run every iteration. `--state` meets its goal. `--marker` bounds its *output* (100 × 300 bytes, quoted) but not its *work*. Plan D11's "caps the body at 100 lines of 300 bytes" reads as a bound on what is processed, while the code bounds only what is printed. Finding 1 closes that gap without touching the rules. No finding argues against landing U3b1 after that fix. Row 690's dispatch-cost half is untouched by this diff and stays the fact-check report's open item, not a performance regression here.
