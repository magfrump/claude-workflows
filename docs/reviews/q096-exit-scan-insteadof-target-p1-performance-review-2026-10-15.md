Commit: 5f754994

# Performance Review — fix/q096-exit-scan-insteadof-target (pass 1)

**Scope:** `git diff main...HEAD` (b279a2ba..5f754994); focus `devcontainer-config/cc-exit-scan.sh` (`_snap_url`, `_snap_rule`, `_snap_rewrite`, the closing worklist in `git_exec_snapshot`, the `_snap_host_config` rule collection) and the guide's cap sentence
**Date:** 2026-10-15
**Based on:** docs/reviews/q096-exit-scan-insteadof-target-p1-code-fact-check-report.md (Stage-1 summary in the shared brief), plus timeout-bounded measurements in `/home/node/.claude/jobs/00bcf178/tmp/q096/probe-performance/` (bash 5.2.15, git 2.39.5, 16-core WSL2 host)

## Data Flow and Hot Paths

`git_exec_snapshot` runs on the host twice per cc-isolated session: once at launch (the user waits for the container to start) and once inside `git_exit_scan` after the session ends (the user waits for the verdict). It is a cold path by call frequency, but it runs over the whole checkout and both runs block an interactive user, so the hot-path gate's "blocks a latency-sensitive operation" exception applies to adversarial sizes.

What the diff adds: every remote URL the scan meets is queued once per (URL, working tree) (`_snap_url`); every insteadOf/pushInsteadOf rule is queued once per (base, value) (`_snap_rule`, from repo configs and from `_snap_host_config`). The closing worklist compares every URL with every rule once (U × R comparisons, `_snap_rewrite`), and each match calls `_snap_remote` on the rewritten URL, deduplicated by (target, working tree). The cap `GIT_EXIT_SCAN_MAX_REWRITES=100000` counts comparisons, not matches.

Sizes:
- **Realistic.** U is the remotes of the checkout plus each embedded repo (usually 1-2 each). R is the user's own rules (usually 0-3, for example `url."git@github.com:".insteadOf https://github.com/`) plus any rules in repo configs. Even 500 embedded repos × 3 rules is 1,500 comparisons. The typical match rewrites to `host:path` or `scheme://`, and `_snap_remote` returns on those before any fork. Cost: milliseconds.
- **Adversarial.** The session writes the checkout's config, so it picks U and R freely: about 316 × 316 pairs stays under the cap. It also picks whether pairs match (one prefix shared by every URL) and whether targets are local paths (the base is a path), which is where the forks are.

Measured (one `git_exec_snapshot`, every remote `https://h.invalid/uN`):

| Scenario | U × R | Pairs matching | Time (diff) | Time (main) |
|---|---|---|---|---|
| no rule matches | 316 × 316 (99,856 cmp) | 0 | 1.62 s | 0.30 s |
| every pair matches, non-local target (`https://bN.invalid/`) | 316 × 316 | 99,856 | 4.01 s | 0.30 s |
| every pair matches, absolute target outside the checkout (`/var/empty/bN/`) | 100 × 100 | 10,000 | 23.4 s | — |
| every pair matches, absolute target inside the checkout | 100 × 100 | 10,000 | 44.2 s | — |
| every pair matches, relative target (`bN/`) | 100 × 100 | 10,000 | 46.9 s | — |
| every pair matches, inside the checkout | 316 × 316 | 99,856 | **killed by `timeout 590` (> 590 s), no output** | — |

Standalone micro-measurements: 99,856 comparisons as a function call cost 1.08 s, and 0.22 s when the comparison is inlined in the loop. A 10,000-character URL against a 10,001-character prefix costs about 70 µs per comparison under LC_ALL=C and 117 µs under C.UTF-8 (2.3 µs at length 10). 100,000 `_snap+=` appends of ~85-byte records cost 6.15 s (25k: 0.34 s, 50k: 1.44 s), which is quadratic.

## Findings

#### The cap bounds comparisons, but the cost is in matched walks: a plant under the cap stalls each scan for more than 10 minutes, and a plant over the cap does the same work before it fails

**Severity:** Low
**Location:** `devcontainer-config/cc-exit-scan.sh:401-420` (`_snap_rewrite`), `:781-797` (worklist); `guides/cc-isolated-usage.md:326-327`
**Move:** Count the hidden multiplications; check the asymptotic behavior (cliff)
**Classification:** Macro (U × R walks with forks, chosen by the session) / Cold path that blocks the interactive launch and exit (escalated from the Macro × Cold default only to keep it visible; adversarial-only)
**Confidence:** High
**Baseline:** 44.2 s for 10,000 matched in-checkout rewrites (one `git_exec_snapshot`, measured 2026-10-15, probe-performance/bench.sh `inside 100 100`); 99,856 matched rewrites exceeded a 590 s timeout
**Legibility-target:** for-author

Evidence:
```
_snap_rewrite() {
  local u="${_snap_urls[$1]}" p="${_snap_rpfx[$2]}" t k
  _snap_rwn=$((_snap_rwn + 1))
  if [ "$_snap_rwn" -gt "$GIT_EXIT_SCAN_MAX_REWRITES" ]; then
  ...
  [[ "$u" == "$p"* ]] || return 0
  t="${_snap_rbases[$2]}${u:${#p}}"
  ...
  _snap_remote "$t" "${_snap_ubases[$1]}"
}
```
(the elided lines are the `_snap_fail` call, `return 1`, `fi`, and the `t:` dedup key check; the function ends at the `}` shown)

and the guide: "More than 100,000 URL-and-rule comparisons fails the scan (exit 4) rather than stalling it."

A no-match comparison costs about 13 µs, so the cap is a sensible bound on comparison work alone (1.3 s at the cap). But each match whose target is a local path calls `_snap_remote`. That forks `realpath` twice (`_snap_inside_ws` for `<p>` and `<p>.git`), and for an in-checkout target it also forks `$(printf '%q')` in `_snap_file`, `stat`, and for a relative target `$(printf '%q')` in `_snap_wrel`. Measured: 2.3-4.7 ms per match, 470× the comparison cost. Each distinct target also appends one or two records to `_snap`, and that `+=` is quadratic (6 s per 100k appends). A session needs only one shared prefix and about 316 local-path bases to get about 100k distinct matched targets under the cap. That is more than 590 s per scan (measured), at both launch and exit. Over the cap is no faster: the counter goes up per comparison while matches are walked along the way, so a 400 × 300 plant does about 100k matched walks before `_snap_fail` fires. The guide's "rather than stalling it" is therefore not true for matching pairs. This belongs to the family override-log row 134 deferred ("scan cost grows with embedded repos/hooks; fail-closed by design — documented limit"). The new part is that the cap's wording promises a bound the code does not give, and the "take a long time" known-route bullet (guide :413-416) names only files and embedded repos.

**Recommendation:** Add a second, much smaller cap on matched rewrites that reach `_snap_remote` (for example 1,000-5,000 distinct `t:` targets, so worst-case forks stay at seconds), failing closed the same way. Or count a match as many comparisons. Either way, fix the guide sentence: either make it true, or say the cap bounds comparisons and add rewrite plants to the "take a long time" bullet.

#### Per-comparison function-call overhead is 5× the comparison itself, and the cap is checked after the work rather than before

**Severity:** Informational
**Location:** `devcontainer-config/cc-exit-scan.sh:788-793`
**Move:** Check the asymptotic behavior, not just the constant (constant factor at the cap)
**Classification:** Micro (bash function call per pair) / Cold path
**Confidence:** High
**Baseline:** 99,856 no-match comparisons: 1.62 s through `git_exec_snapshot` vs 0.30 s on main for the same config; standalone 1.08 s as a function call vs 0.22 s inlined (probe-performance/inline.sh, 2026-10-15)
**Legibility-target:** for-author

Evidence:
```
    elif [ "$u" -lt "${#_snap_urls[@]}" ]; then
      for ((j = 0; j < r; j++)); do _snap_rewrite "$u" "$j" || { rc=1; break; }; done
      u=$((u + 1))
    elif [ "$r" -lt "${#_snap_rbases[@]}" ]; then
      for ((j = 0; j < u; j++)); do _snap_rewrite "$j" "$r" || { rc=1; break; }; done
      r=$((r + 1))
```
(the `while` loop goes on to `else break; fi; done` at :795-797)

Every pair pays a bash function call, two `local` array dereferences, and an arithmetic increment before the one `[[ == "$p"* ]]` test. At the cap this adds about 1.3 s per scan (2.6 s per session) when nothing matches. Each outer step knows its batch size (`r` or `u`) before the inner loop runs. Adding the batch to `_snap_rwn` and checking the cap first would make an over-cap plant fail before doing any work, which also removes the over-cap half of the finding above. Inlining the prefix test and calling `_snap_rewrite` only on a match would cut the no-match cost about 5×. This is not worth doing on its own for realistic sizes (milliseconds).

**Recommendation:** Optional. Do the per-batch cap check (cheap, and it makes the over-cap case fail fast), and inline the prefix test if `_snap_rewrite` is touched again.

#### Comparison cost scales with URL and prefix length, which the pair-count cap does not account for

**Severity:** Informational
**Location:** `devcontainer-config/cc-exit-scan.sh:414`
**Move:** What's the size of N (string length as a hidden N)
**Classification:** Micro (per-comparison cost proportional to string length) / Cold path, adversarial only
**Confidence:** Medium (micro-benchmark of the same test expression, not a full scan)
**Baseline:** 10,000 comparisons of a 10,018-byte URL against a 10,019-byte prefix: 0.70 s (LC_ALL=C), 1.17 s (C.UTF-8); 0.023 s at length 10 (probe-performance/match.sh, 2026-10-15)
**Legibility-target:** for-author

Evidence:
```
  [[ "$u" == "$p"* ]] || return 0
```

A session can make every URL and rule value long (a few MB of config stays far below the 64 MiB per-file hash cap). At 10 KB each, the 100,000-pair cap allows about 7-12 s of pure comparison per scan. The cost grows linearly with length, so 64 KB values give roughly a minute. This is the same unbounded-stall family as the first finding, and a smaller effect.

**Recommendation:** No change needed if the first finding's stall is accepted as a documented limit. Otherwise, a total-bytes bound on queued URLs and rule values (like `GIT_EXIT_SCAN_MAX_TOTAL_BYTES` for hashing) would close it.

## Endorsements

- The no-match path adds no forks. `_snap_url` replaces the direct `_snap_remote` calls one-for-one, and `_snap_rule` and the `_snap_host_config` rule collection use only builtins and associative-array writes. A realistic checkout's extra cost is the U × R builtin comparisons, so the measured overhead equals the comparison loop. [read: devcontainer-config/cc-exit-scan.sh:383-399, 461-471, 563-566]
- Realistic matches (a user rule rewriting `https://github.com/` to `git@github.com:`) end in `_snap_remote` at the `host:path` / `scheme://` checks before any fork. Measured: 99,856 non-local matches in 4.0 s total. [read: devcontainer-config/cc-exit-scan.sh:356-364]
- Each (URL, rule) pair is compared exactly once, including pairs found inside rewritten targets, so the worklist is not doing duplicate work. [fact-check: Stage-1 "each (URL, rule) pair compared exactly once incl. those found inside rewritten targets" — Verified (executed)]
- Re-reading your host config for each embedded repo does not grow R: `_snap_rule` dedupes on `r:<base>\t<value>`, so U × R is not multiplied by the number of embedded repos. [read: devcontainer-config/cc-exit-scan.sh:393-399]
- The cap fails closed rather than truncating. [fact-check: Stage-1 "cap fails closed (snapshot 1, git_exit_scan 2, launcher 4)" — Verified (executed)]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | The cap bounds comparisons, not matched walks (2.3-4.7 ms each, with forks); a plant under the cap takes more than 590 s per scan, and an over-cap plant does the same work before failing; the guide's "rather than stalling it" overstates | Low | `cc-exit-scan.sh:401-420, 781-797`; `guides/cc-isolated-usage.md:326-327` | High |
| 2 | A function call per pair costs 5× the comparison; the cap is checked per pair after the work, not per batch before it | Informational | `cc-exit-scan.sh:788-793` | High |
| 3 | Comparison cost is proportional to string length, which the pair-count cap does not bound | Informational | `cc-exit-scan.sh:414` | Medium |

## Overall Assessment

For realistic checkouts the change costs almost nothing: a few thousand builtin comparisons, no new forks, and matches that end before any process starts. Every finding is about adversarial sizes, which the session controls, so they belong to the documented "a session can make the exit scan take a long time" limit (override row 134, deferred). The one thing worth acting on in this unit is that the new cap is described as preventing a stall, and it does not. The expensive unit is a matched local-path walk, not a comparison. A small second cap on matched targets, plus a per-batch check before the work, would make the guide sentence true for a few lines of code. Alternatively, reword the sentence and extend the known-route bullet. No further profiling is needed: the measurements above already cover the cap boundary.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-q096/docs/reviews/q096-exit-scan-insteadof-target-p1-performance-review-2026-10-15.md, structured per the performance-reviewer skill, first line `Commit: 5f754994`.
- Answered: yes. Realistic and adversarial sizes, the cap value, per-comparison bash cost, and extra forks are all measured with timeout-bounded runs.
- Out of scope: the correctness of rewrite semantics and the security of the still-open routes (other critics and the fact-check own those); the pre-existing `_snap+=` quadratic append was measured only as a contributor to finding 1.
- Escalate: finding 1's guide sentence ("rather than stalling it") is a doc-accuracy issue as well as a performance one; the orchestrator may want to merge it with the fact-check's "Mostly accurate" on the same sentence (guide :326-327).
- Decisions I made: rated finding 1 Low (adversarial-only, row-134 family) rather than Medium for blocking the interactive launch and exit; treated "Legibility-target" as the orchestrated-review audience tag (for-author) rather than a target file.
