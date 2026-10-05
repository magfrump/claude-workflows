Commit: 0ae7d801

# Performance Review — feat/build-loop-u1b (U1b, review-fix loop iteration 2)

**Scope:** `feat/build-loop-u1a...feat/build-loop-u1b` (scripts/build-loop.sh, test/lib/build-loop-fixtures.bash, test/scripts/build-loop-read.bats); docs/reviews/ files are review records, not reviewed
**Date:** 2026-10-05
**Based on:** shared Stage-2 context (review-u1b-i2/shared-stage2.md) and the merged Stage-1 fact-check summary (docs/reviews/code-fact-check-report-build-loop-u1b.md). No fact-check claim concerns performance; none is contradicted here.

## Data Flow and Hot Paths

`build-loop.sh --settings` is a one-shot CLI read: one `scrub_reexec` (a child bash plus two perl filters), `git rev-parse`, `resolve_main` (a few `show-ref`/`rev-parse` forks), one `main_entry` (`ls-tree`, Won't-Fix per override log), then one `git cat-file blob | awk "$FENCE_AWK$SETTINGS_AWK"` pass over docs/dev-cycle.md, and a bash parse of at most three result lines. **Path temperature: cold** — the dev cycle's orchestrator runs it once before dispatch (and U1c/U2 will call `read_settings` once per process); nothing loops over it. Input size: docs/dev-cycle.md on main, today a few hundred lines; it is repo text a build loop can propose but only main's commit is read.

Measurements (this machine, mawk, `LC_ALL=C.UTF-8`, probe repos under the performance scratch dir, wall time of the whole script including re-exec):

| Input | Wall time |
|---|---|
| this repo's docs/dev-cycle.md (3 runs) | 16–19 ms |
| 200,000 plain lines | 157 ms |
| one line of 1,000,000 `> ` markers (2 MB) | 440 ms |
| one line of 1,000,000 `*` | 303 ms |
| one line of 1,000,000 `1. ` | 139 ms |
| `Self-merge never:` with 1,000 / 10,000 / 100,000 entries | 42 / 259 / 2,411 ms |
| test/scripts/build-loop-read.bats, 9 tests (`@category fast`) | 2,430 ms total; slowest T45 789 ms |

Every input scales linearly (10x input → ~10x time). The SETTINGS_AWK leading-marker strip (`build-loop.sh:106`) is a single anchored `match()`, the same shape the lib adopted in `refdef` to avoid the quadratic `sub()` loop; it shows no super-linear behaviour on the worst marker runs tried.

## Findings

#### Self-merge never: entry count is unbounded; the per-entry bash loop costs ~24 µs per entry

**Severity:** Informational
**Location:** `scripts/build-loop.sh:161-167`
**Move:** Ask "what's the size of N?" / asymptotic behaviour
**Classification:** Micro (constant per-entry bash work, linear overall) / Cold path (one-shot CLI read, once per process)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Baseline:** 2,411 ms wall time for a 100,000-entry never line (259 ms at 10,000; 42 ms at 1,000), measured 2026-10-05 with the probe in the performance scratch dir

Evidence:
```
        IFS=' ' read -ra parts <<<"$v"  # not a bare $v: the shell would expand * and ? against files
        for g in "${parts[@]}"; do
          i=$((i + 1))
          if ! globform "${g%/}"; then why="lists entry $i, which is not an allowed glob form"; break; fi
          if [[ -n "${seen[${g%/}]-}" ]]; then why="lists entry $i twice"; break; fi
          seen[${g%/}]=1
        done
```
(excerpt ends :167; enclosing read_settings() runs :135–:185 — read in full)

Each entry costs one `globform` call (a bash regex plus a per-part `while` loop, no forks) and one associative-array lookup; the whole-line single-space regex at :157 costs ~92 ms at 100,000 entries, so the loop dominates. Growth is linear and there is no fork per entry, so this is not a scaling problem: a realistic list (tens of globs) costs well under 1 ms, and reaching one second needs ~40,000 entries on main's commit. Recorded only so U2's gate, which will match every changed path against `NEVER`, starts from the right number: that matching (paths × globs) is where a product, not a sum, would appear.

**Recommendation:** No change in U1b. In U2, match the brief's changed paths against the globs in one `git` call (`:(glob)` pathspecs, as the lib's path rule says) rather than a bash double loop, and keep `read_settings` to one call per process.

## Endorsements

- The leading-marker strip in SETTINGS_AWK is one anchored `match()` plus one `substr()` per line, so its cost is linear in line length; a 2 MB line of `> ` markers ran in 440 ms end to end. [read: scripts/build-loop.sh:101-117] (linearity measured on the inputs in the table above, not proven for every regex engine)
- The settings file is read in a single awk pass with FENCE_AWK prepended, and bash parses at most three output lines (one per key), so bash-side work does not grow with file length. [read: scripts/build-loop.sh:89, :101-117, :145-149]
- No per-entry fork in the never-line validation: `globform` and the `seen` check are bash builtins only. [read: scripts/build-loop.sh:122-129, :161-167]
- `read_settings` is called once per `--settings` run, and U1c/U2 will call it once per process as well. [unverified — submitted as claim] (U1c/U2 are not in this diff)

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Never-list entry count unbounded; linear ~24 µs/entry loop | Informational | `scripts/build-loop.sh:161-167` | High |

## Overall Assessment

The unit is a cold, one-shot read with a measured cost of ~17 ms on the real settings file, and every adversarial input tried (2 MB marker lines, 200,000 lines, 100,000 never entries) scales linearly with no fork per line or per entry. No change is needed for performance. The one note is forward-looking: U2's gate will match changed paths against `NEVER`, and that is where a product of two sizes would first appear. The bats suite adds ~2.4 s to the fast category, which is in line with its sibling suites' per-test cost. The ls-tree cost of `main_entry` is settled (Won't-Fix, u1a) and is not raised again.

## Goal-Alignment Note

**Success criterion:** a markdown report saved to /workspace/.claude/wt-build-loop-u1b/docs/reviews/performance-reviewer-review-2026-10-05-build-loop-u1b.md, structured per the performance-reviewer skill.

**Answered:** Performance posture of U1b's `--settings` mode and its tests: cold path, measured ~17 ms on the real file, linear on every adversarial input tried; one Informational finding (never-list size), no blocking issue.

**Out of scope:** E1/E3 (hidden rendered key copies; security and API), E2 (unenforced non-final `&&` assertions in bats; test-strategy), the correctness of the never-glob rules, and any U1c/U2 code.

**Escalate:**
- For api-consistency / orchestrator synthesis (for-orchestrator-synthesis): a `Self-merge never:` line long enough to make the printed never line exceed 4,096 bytes (~700 short globs) is cut by the lib's scrub, so the printed line ends `... [line cut at 4096 bytes]` and loses its `set: line N of ...` tail, while `NEVER` in the process keeps the whole list. Observed in the 1,000-entry probe. Not a performance problem; a reader of the printed line sees a truncated list.
- For U1c/U2 authors (for-author): `read_settings` does not reset `POLICY` and `NEVER` at its start (only the top-level line :133 does), so a second call in one process whose file is not read keeps the first call's values. Harmless today (one call per process, one main commit), but a caller that re-reads after main moves would inherit stale values.

**Questions / Decisions:** None.
