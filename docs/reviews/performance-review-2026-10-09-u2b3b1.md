Commit: 8ed86432

# Performance Review — feat/build-loop-u2b3b1 (U2b3b1, iteration 1)

**Scope:** `git diff main...HEAD` in /workspace/.claude/wt-build-loop-u2b3b1 (scripts/lib/dev-cycle-read.sh, scripts/build-loop.sh, scripts/dev-cycle.sh, docs/dev-cycle.md)
**Date:** 2026-10-09
**Based on:** docs/reviews/code-fact-check-report-build-loop-u2b3b1.md (17 claims, 0 Incorrect)

## Data Flow and Hot Paths

`reader_settings` (lib:602) runs once per process in build-loop.sh (every mode, :305) and dev-cycle.sh (every run including the digest, :192): one `main_entry` + `git cat-file` + one awk pass over docs/dev-cycle.md. `import_readers` (lib:1015) runs once per decision (memoized, D7 now memoizes refusals too) and builds the root list; G8 appends, for each caller root, a re-spelling of every registered worktree beneath the main worktree, so roots ≈ (1 + C) × W for C caller roots and W worktrees under main. Each walk (main_imports, imported_names) then passes all roots to the awk parser per file, whose charged work grows superlinearly in the root count and is capped at IMPORT_WORK_MAX = 50,000,000 per walk (fail closed). Path temperature: cold. These are gate/CLI decisions run a few times per build-loop or dev-cycle invocation, not per-item loops at scale; the floor walk is not yet wired into build-loop.sh (U2c), so today only dev-cycle.sh's --check-path/--check-fix walk.

Measurements (probes p1-p4 in scratch dir `.../u2b3b1-i1/performance/`, read-only, 2026-10-09T07:55-07:57Z, shared host, wall clock; synthetic aliases `/home/magfrump/aliasN` stand in for further `Reader roots:` entries, with `IMPORT_READER_HOMES=/home/magfrump`; work = summed parser trailers via a wrapped `import_work`):

| Run from | Caller roots | Roots | Names | Work per walk | main s | tree s |
|---|---|---|---|---|---|---|
| /workspace | 0 | 25 | 128 | 347,710 | 1.39 | 1.54 |
| /workspace | 1 | 49 | 128 | 868,530 | 1.40 | 1.58 |
| /workspace | 10 | 265 | 128 | 12,295,110 | 3.41 | 2.79 |
| /workspace | 20 | 505 | 128 | 39,249,710 | 5.94 | 6.22 |
| u2b3b1 worktree | 0 | 25 | 64 | 153,855 | 0.88 | 0.82 |
| u2b3b1 worktree | 1 | 49 | 64 | 395,065 | 0.79 | 0.81 |
| u2b3b1 worktree | 4 | 121 | 64 | 1,567,975 | 0.91 | 1.00 |
| u2b3b1 worktree | 20 | 505 | 64 | 19,220,855 | 3.06 | 3.10 |

`import_readers` itself: 5.9 ms at 25 roots, 5.7 ms at 49, 24 ms at 505. `reader_settings`: 4.0-4.3 ms per call (20 calls in one process; main's file has no reader lines yet). Adversarial file (400,000 distinct relative names, p4): the per-walk bound is spent and the parser fails closed in 1.95 s at 25 roots and 2.05 s at 49 roots, so the doubling does not lengthen the worst-case time-to-refuse.

## Findings

#### F1. One host alias halves the registry size at which the honest walks fail closed; further aliases are unbounded

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:1033-1037` (G8 re-spelling), `scripts/lib/dev-cycle-read.sh:747-752` (bound comment), `scripts/lib/dev-cycle-read.sh:620-628` (reader_settings accepts any number of roots)
**Move:** Ask "what's the size of N?" / asymptotic behaviour
**Classification:** Macro (superlinear in roots, roots multiplied by 1 + C) / Cold path (once-per-decision gate walk)
**Confidence:** High (measured)
**Baseline:** /workspace main walk 347,710 work units at 25 roots vs 868,530 at 49 roots (2.50x), probe p3, 2026-10-09T07:56Z
**Evidence:**
```
  for rs_cr in "${rs_c[@]}"; do
    [[ -n "$rs_cr" ]] || continue
    rs_r+=("$rs_cr"); for p in "${rs_w[@]}"; do [[ -z "$rs_m" || "$p" != "$rs_m"/* ]] || rs_r+=("$rs_cr${p#"$rs_m"}"); done
  done
```
and the comment: "the honest walks spend this bound near 570 roots and then fail closed: prune the registry (git worktree prune) long before" / "Each caller root re-spells the worktrees under the main worktree, so one host alias about doubles the count".

Wall time barely moves at today's size (1.39 s to 1.40 s; fixed costs dominate), so there is no present latency problem. The scaling change is that roots ≈ (1 + C) × W: the measured curve (39.2 M work at 505 roots) puts the fail-closed point near 570 roots, as the comment says, but with this repo's one `Reader roots:` entry that is now about 285 registered worktrees beneath the main worktree, not about 570. Each further `Reader roots:` entry costs another W roots. reader_settings sets no limit on the count, and at 20 entries the walks spend 78% of the bound (6 s per walk). The settings line lives on the reviewed default branch, so this is a headroom and legibility issue, not an attack path. The comment states the threshold in roots and the remedy in worktrees, which leaves the reader to do the conversion.

**Recommendation:** Restate the threshold in the comment in registry terms ("about 570 / (1 + caller roots) worktrees beneath the main worktree: about 285 with this repo's one host alias"). Optionally have reader_settings or `--settings` report the projected root count, or refuse more than a small number of `Reader roots:` entries, so the bound cannot be reached through settings alone.

**Legibility-target:** for-author-fix

#### F2. The IMPORT_WORK_MAX comment's /workspace work figure goes stale when the reader lines land

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:746`
**Move:** Build on stale claims
**Classification:** Micro (documentation of a constant) / Cold path
**Confidence:** High (measured)
**Baseline:** 868,530 work units per /workspace walk at 49 roots, probe p3, 2026-10-09T07:56Z
**Evidence:** "/workspace's walks spend about 330,600 each over its 24 reader roots (8,200 with one; 2026-10-08)."

This branch's docs/dev-cycle.md adds `Reader roots: /home/magfrump/claude-workflows`. Once it merges, the walks spend about 868,530 each at 49 roots (2.6x the quoted figure). The comment at :751-752 adds the 49-root timing but not the work figure. The headroom statement it supports ("near 570 roots") still holds.

**Recommendation:** Update the figure to the 49-root measurement, for example "about 868,500 each over 49 roots with the host alias (347,700 at 25)".

**Legibility-target:** for-author-fix

#### F3. docs/dev-cycle.md is read and parsed twice per build-loop.sh settings/status/check run; the digest pays reader_settings without walking

**Severity:** Informational
**Location:** `scripts/build-loop.sh:305` and `scripts/build-loop.sh:349-353`; `scripts/dev-cycle.sh:192`
**Move:** Find the work that moved to the wrong place
**Classification:** Micro (one extra git cat-file + awk, about 4 ms) / Cold path (once per process)
**Confidence:** High
**Baseline:** reader_settings 4.0-4.3 ms per call, probe p1, 2026-10-09T07:55Z
**Evidence:** `reader_settings` at build-loop.sh:305 (top level, every mode), then `read_settings() { ... if ! main_file "$f" "$SETTINGS_AWK"; then` at :349-353 for status, settings and check, the same file through the same awk program. dev-cycle.sh:192 `reader_settings` runs before the digest, which runs no walk.

Both cost about 4 ms per process, which is negligible next to a 1.4 s walk. This is recorded only because the brief asked about per-process cost. A shared single parse (FILE_OUT cached by MAIN_SHA) would remove it if more settings readers are added.

**Recommendation:** None needed now. If a third reader of docs/dev-cycle.md appears, memoize main_file's output for docs/dev-cycle.md on MAIN_SHA.

**Legibility-target:** for-orchestrator-synthesis

## Endorsements

- import_readers memoizes a refusal before the registry listing, so a refusing decision lists the registry once and the key including IMPORT_READER_WHY lets a cleared state recompute [fact-check: claim 10a — Verified]
- The G8-expanded root list, including every re-spelled worktree, is still resolved in a single `realpath -mz` call rather than one fork per root (lib:1040-1047) [read: scripts/lib/dev-cycle-read.sh:1033-1047]
- Doubling the roots does not lengthen the time for an adversarial file to spend the per-walk bound (about 2 s at both 25 and 49 roots in probe p4), because the per-root projection is charged to the same bound [unverified — submitted as claim]
- reader_settings is linear in the entries it parses (one associative-array dedupe per key) and adds about 4 ms per process [unverified — submitted as claim]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | One host alias halves the registry size at which walks fail closed; alias count unbounded | Low | `scripts/lib/dev-cycle-read.sh:1033-1037, 747-752` | High |
| 2 | Stale /workspace work figure in IMPORT_WORK_MAX comment | Informational | `scripts/lib/dev-cycle-read.sh:746` | High |
| 3 | docs/dev-cycle.md parsed twice per build-loop run; digest pays reader_settings | Informational | `scripts/build-loop.sh:305, 349-353`; `scripts/dev-cycle.sh:192` | High |

## Overall Assessment

The performance posture is sound for the current registry. G8 multiplies the root count by 1 + C, and the parser's work grows superlinearly in roots (2.5x for 25 to 49). Wall time is flat at about 1.4 s per walk because fixed costs dominate, and the adversarial fail-closed time is unchanged at about 2 s. The real change is headroom: with one alias the honest walks fail closed at about 285 registered worktrees beneath the main worktree instead of about 570. The comment states this only in roots, and nothing limits the number of `Reader roots:` entries. Both are fixable in place with comment edits and, optionally, a small cap. No profiling beyond the probes above is needed. The D7 memo and the single-realpath batching hold up.

## Goal-Alignment Note

The user's goal is to land U2b3b1 after a clean review-fix loop. Nothing here blocks landing: F1 is Low (cold path, measured, about 11x root headroom left at today's 49 roots), and F2 and F3 are Informational comment and micro-cost items. If addressed, F1 and F2 are comment edits in scripts/lib/dev-cycle-read.sh near :746-752. An optional cap on `Reader roots:` entries would be a small reader_settings change that fits this unit or U2b3b2. None of the findings touch U2b3b2's deferred items (H5, H2, C1, G9, outside starts).
