Commit: 368a3194

# Performance Review — feat/build-loop-u2b2, iteration 2 (U2b2, the gate's checkout)

**Scope:** c10b972a..368a3194 (fix commits 639f7b40, 368a3194): `scripts/build-loop.sh` `callervar`, `gate_repo`, `checkout_gate` (:626-690, read whole), `check_line` (:697-753, read whole), the `check)` mode block (:764-775); the lib header and bats changes read for context only
**Date:** 2026-10-08
**Based on:** docs/reviews/code-fact-check-report-build-loop-u2b2-i2.md (k=1; 26 claims, 3 Incorrect about documented order, fixed in 368a3194; none in the performance domain); iteration-1 report docs/reviews/performance-reviewer-review-2026-10-08-build-loop-u2b2.md

## Data Flow and Hot Paths

The one structural performance change in this delta: `checkout_gate` moved from once per `--check` run (parent shell, gated on the stricter policy) into `check_line`, which runs once per brief in a subshell (`out="$(check_line "$a")"`, :771). It now runs per brief whose own policy is self-merge, and only after that brief has passed status, branch, `--expect`, `merge_result`, `diff-tree` and the record-count check (:703-729), so a brief refused earlier never pays for it. Inside, the steps are unchanged in kind: `rev-parse --local-env-vars`, the HEAD check (a loop's advisory run from its own branch exits here), three `git config` reads, `ls-files -v`, `git status`, `ls-files --others`, `ls-tree -r -z` into a file, a bash read loop over every record, and one `hash-object --no-filters --stdin-paths` over every regular file main stores. The function now runs under an exported `LC_ALL=C`.

Path temperature: **cold**. `--check` runs once per merge decision by the orchestrator and as a loop's advisory dry run (plan D6/D7); nothing calls it per request. N for the new multiplication is the number of self-merge briefs in one `--check`'s ARGS; plan D9 caps live loops at `Build-loop slots: N` (1-9, default 3), though `--check BRIEF...` itself takes any number of arguments.

Probe (git 2.39.5, bash 5.2.15, warm cache; load average 0.53-0.60 before and after, no busy leftover processes; temp dirs /tmp/perf2u2b2-*, removed and confirmed gone). The gate's steps replayed read-only against this worktree's tree (3,170 files, 71 MB):

| Measurement | Time |
|---|---|
| Whole gate, one brief (5 runs) | 0.238-0.252 s |
| Nine gates back to back (D9's slot maximum) | 2.385 s |
| bash record loop alone, this repo, `LC_ALL=C` / `C.UTF-8` | 0.104 s / 0.122 s |
| `hash-object --stdin-paths` alone, this repo | 0.118 s |
| 50,000 synthetic records: i1 loop body / i2 loop body, `LC_ALL=C` | 1.612 s / 1.533 s |
| same, `C.UTF-8` | 1.631 s / 1.548 s |

## Findings

#### The checkout gate's full cost now multiplies by the number of self-merge briefs in one --check

**Severity:** Low
**Location:** `scripts/build-loop.sh:734`
**Evidence:**
```bash
  co=""; if [[ "$pol" == self-merge ]] && ! checkout_gate; then co="refuse $a: a self-merge brief needs --check run from a clean checkout of the default branch's commit; $CHECKOUT_WHY"; fi
```
(removed from the `check)` block: `if [[ "$POLICY" == self-merge ]]; then checkout_gate || true; fi`)
**Move:** Find the work that moved to the wrong place / count the hidden multiplications
**Classification:** Macro (cost × K self-merge briefs, each pass linear in tracked bytes and tracked-file count) / Cold path (once per merge decision)
**Confidence:** High (mechanism, measured); Medium (realistic K, from the plan's slot cap)
**Baseline:** 0.24 s per gate and 2.385 s for nine gates on this repo's 3,170 files (probe above, 2026-10-08)
**Legibility-target:** for-author

Iteration 1 moved the gate into `check_line` so its verdict lands per brief and after the path lines; the price is that the checkout is re-listed and every tracked byte re-hashed once per self-merge brief, though the result depends only on the checkout and MAIN_SHA, not on the brief. At D9's default of 3 slots that is about 0.7 s in this repo, at 9 about 2.4 s; in the iteration-1 synthetic repo (50k files, one 200 MB binary, ~2.7 s per gate) nine briefs would cost about 24 s. The cost does not grow with load, only with K and repo size, and running the gate fresh before each brief's decision matches the contract's per-decision stance (item 4, `import_reset` per decision), so the repeat buys freshness, not nothing.

**Recommendation:** No change for this repo. If a large repo adopts the gate, hoist one gate run per `--check` (in the parent shell, as before, but only when some brief in ARGS is self-merge) and accept that the U2c walk then trusts a checkout check made up to K briefs earlier; or leave it per brief and record the K × repo-size scaling beside the `--stdin-paths` comment at :685.

#### Carried from iteration 1: full rehash, record loop, unexcluded --others listing (unchanged in kind)

**Severity:** Informational
**Location:** `scripts/build-loop.sh:659-689`
**Evidence:**
```bash
  x="$(printf '%s\n' "${ps[@]}" | git hash-object --no-filters --stdin-paths 2>/dev/null)" \
```
**Move:** Ask "what's the size of N?"
**Classification:** Macro (linear in tracked bytes / tracked files / ignored files) / Cold path
**Confidence:** High
**Baseline:** 0.118 s hash and 0.104 s record loop on this repo; 1.533 s for the loop over 50,000 synthetic records (probe above)
**Legibility-target:** for-orchestrator-synthesis

Iteration 1's three Low/Informational scaling notes stand as written; the delta does not worsen any of them per pass. The record loop's new body (a `case` on the mode, a `p=` copy, three glob tests per record, refusal instead of `continue` on a non-matching record) measured no slower than iteration 1's (1.533 s vs 1.612 s per 50k records), and the C locale is slightly faster here (0.104 s vs 0.122 s). Symlinks (120000) are now skipped rather than unmatched, so they still cost no hash. Their only change is the multiplication in the finding above.

**Recommendation:** None beyond iteration 1's.

## Endorsements

- The gate is now skipped for a review brief and for a run where every brief is review policy, which closes iteration 1 finding 1's note that the rehash ran whenever the stricter policy was self-merge, even with no self-merge brief in ARGS. [read: scripts/build-loop.sh:734, 764-775]
- A self-merge brief refused for status, branch, `--expect`, a conflict, a failed merge or an unreadable diff returns before the gate, so it pays nothing for it. [read: scripts/build-loop.sh:703-729]
- The gate still returns at the HEAD check for a loop's advisory run from its own branch, so the per-brief move costs that run only two `rev-parse` calls per self-merge brief beyond the merge it already computed. [read: scripts/build-loop.sh:632-638]
- The i2 record loop is not slower than the i1 loop per record, and the exported C locale does not slow it (1.533 s vs 1.612 s per 50k records; 0.104 s C vs 0.122 s UTF-8 on this repo). [unverified — submitted as claim] (my probe above; not from the fact-check report)
- `status` output now goes to `$GATE_TMP/status` rather than a `$(...)` capture, so its memory is flat in the size of a dirty checkout's status listing. [read: scripts/build-loop.sh:652-654]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | checkout_gate re-run per self-merge brief: K × (~0.24 s here), 2.4 s at 9 slots | Low | `scripts/build-loop.sh:734` | High |
| 2 | Iteration 1's scaling notes carried, no per-pass regression | Informational | `scripts/build-loop.sh:659-689` | High |

## Overall Assessment

Still a cold, bounded change. The only new cost is the move of the gate from once per run to once per self-merge brief, which multiplies a ~0.24 s pass by at most the slot count in practice (2.4 s at 9) and buys a fresh checkout check before each brief's decision; it also removed the iteration-1 waste of running the gate when no self-merge brief was present. The per-pass work did not grow: the stricter record loop and the C locale measured at or below iteration 1's cost. Nothing needs fixing before merge; a hoist is worth considering only if a repo with GB-scale tracked binaries adopts the gate.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-build-loop-u2b2/docs/reviews/performance-reviewer-review-2026-10-08-build-loop-u2b2-i2.md (first line `Commit: 368a3194`), structured per the critic skill.
- Answered: yes; the per-brief multiplication from iteration 1's move is measured and priced, and the delta's other changes are checked for per-pass regressions.
- Out of scope: c10b972a's code beyond the delta (reviewed in iteration 1); security of the refusal rules; the U2c floor walk's own cost (not built).
- Escalate: nothing.
- Decisions I made: took K's realistic bound from plan D9's slot cap (1-9), since `--check` itself takes any number of briefs; timed the gate by replaying its steps read-only against the worktree rather than running `--check` end to end, which would need a self-merge brief fixture.
