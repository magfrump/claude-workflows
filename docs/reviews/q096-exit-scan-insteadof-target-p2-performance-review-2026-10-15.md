Commit: e4b29291

# Performance Review — fix/q096-exit-scan-insteadof-target, iteration 2 (5f754994..e4b29291)

**Scope:** `git diff 5f754994..e4b29291 -- . ':!docs/reviews'`, focused on the insteadOf pass (`_snap_pairs`, `_snap_match`, `_snap_walk_hits`, `_snap_rewrite`, the worklist in `git_exec_snapshot`) and the `LC_ALL=C IFS= read` change; 5f754994 as context
**Date:** 2026-10-15
**Based on:** shared brief `shared-brief-p2.md`; probes in `/home/node/.claude/jobs/00bcf178/tmp/q096/probe-performance-p2/` (bash 5.2, git 2.39.5, 16-core WSL2 container, `LANG=C.utf8`, every run under `timeout ≤600`, all exited on their own; no process left running)

> ⚠️ **No code fact-check report provided.** Performance claims in comments and documentation
> have not been independently verified. For full verification, run the `code-fact-check` skill
> first or use the code-review orchestrator.

## Data Flow and Hot Paths

`git_exec_snapshot` runs twice per session: at launch (the launcher waits on it before starting the container) and at exit (the user waits on it after claude exits). Neither is a request path, but the exit snapshot reads a checkout a hostile session controlled, so the data sizes are adversarial and the scan blocks the user; per the hot-path gate, findings over adversarial data are escalated as if hot, with the gate stated per finding.

The pass: every remote URL and every insteadOf/pushInsteadOf rule is queued once (`_snap_url`, `_snap_rule`, length-prefixed keys in `_snap_rwseen`). The worklist (`cc-exit-scan.sh:839-857`) first drains all URLs against the rules seen so far (zero rules initially), then each rule against all URLs: in practice one batch per rule of size *U* (URL count). Each batch charges `_snap_pairs` (cap 100,000, checked before work), then `_snap_match` (under `local LC_ALL=C`) appends every match's rewritten URL to `_snap_hit_t`, then `_snap_walk_hits` calls `_snap_rewrite` per hit, which dedupes, charges the 2,000-target cap, and walks the target with `_snap_remote` (two `realpath` forks, plus `_snap_file` records when inside the checkout).

Measured per-unit costs (all from the probes above, 2026-10-15):

| Operation | Cost |
|---|---|
| `_snap_match`, short strings, no match | 100,000 pairs in 0.735 s (≈7 µs/pair) |
| `_snap_match`, short strings, all match | 100,000 pairs in 1.349 s |
| `_snap_match`, one 1 MB URL vs 200 rules | 1.955 s (≈10 ms/pair) |
| `_snap_match`, one 4 MB URL vs 800 rules | 40.768 s (≈51 ms/pair) |
| `local LC_ALL=C` function call | 20,000 calls 0.252 s vs 0.041 s plain (≈10 µs/call) |
| `IFS= read -d ''` over 100,000 records | 0.364 s; with `LC_ALL=C` prefix 1.288 s; with `local LC_ALL=C` once in the function 0.339 s |
| End to end, 2,000 local URLs, rule matching none | 11.8 s |
| End to end, 2,000 local URLs, one rule matching all (2,000 targets walked) | 41.4 s, i.e. ≈15 ms per walked target |
| End to end, 2,500 URLs → target cap trips | 32.7 s, then fails closed |
| End to end, 20,000 `h:x<i>` URLs, one empty-value rule with a ~10 KB relative base | 188.9 s, peak RSS 297 MB, then fails closed at the target cap |

## Findings

#### 1. The 2,000-target cap is checked only after a whole batch of hits is materialized, so memory scales with batch size × base length

**Severity:** Medium
**Location:** `devcontainer-config/cc-exit-scan.sh:433-444` (`_snap_match`), `:446-452` (`_snap_walk_hits`), `:455-466` (`_snap_rewrite`), `:849-855` (rule batch)
**Move:** 4 (memory lifecycle), 3 (work moved to the wrong place)
**Confidence:** High (mechanism and linear growth measured; the multi-GB extrapolation is not run)
**Baseline:** 20,000 hits with a ~10 KB base: peak RSS 297 MB and 188.9 s before failing closed (probe `p4h.sh 20000 10000`, 2026-10-15); in isolation `_snap_match` over 5,000 hits of ~40 KB raised VmHWM from 102,508 kB to 298,788 kB (probe `p3.sh 5000 20000 1`)
**Classification:** Macro (unbounded-by-length collection) / cold path escalated (blocks the user at exit, over adversarial data)
**Legibility-target:** the author tuning the caps; a user whose host swaps at session exit
**Evidence:**
```
    if [[ "$u" == "$p"* ]]; then
      _snap_hit_t+=("${_snap_rbases[ri]}${u:${#p}}"); _snap_hit_b+=("${_snap_ubases[ui]}")
    fi
```
```
      _snap_pairs "$u" || { rc=1; break; }
      _snap_hit_t=() _snap_hit_b=()
      _snap_match 0 "$r" "$u" 1
      _snap_walk_hits || rc=1
```
```
  _snap_rwt=$((_snap_rwt + 1))
  if [ "$_snap_rwt" -gt "$GIT_EXIT_SCAN_MAX_REWRITE_TARGETS" ]; then
```

In 5f754994 each match was walked as it was found; e4b29291 batches all matches of one rule (up to *U* = 100,000 under the pair cap, since the rule batch charges exactly *U*) into `_snap_hit_t` before any is counted against the 2,000-target cap. One `url.<base>.insteadOf = ""` (empty value matches every URL; git accepts a 100 KB subsection, checked with `git config --file big.cfg -z --list`) and 100,000 short distinct `remote.*.url` entries fit in a ~3 MB config, well under the 64 MiB file cap, and make one batch build 100,000 strings of |base| + |url| bytes: ~10 GB for a 100 KB base (extrapolated from the linear measurements above, not run). The cap then trips on hit 2,001, after the allocation. The elevated RSS also plausibly makes every later `$(realpath …)` fork slower, which would explain 188.9 s for 2,000 walks against 41.4 s at short lengths (attribution not measured).

**Recommendation:** Enforce the target budget while matching: in `_snap_match`, skip a hit whose `t:` key is already in `_snap_rwseen`, and stop (fail closed) once `_snap_rwt + ${#_snap_hit_t[@]}` would pass `GIT_EXIT_SCAN_MAX_REWRITE_TARGETS`, so a batch never holds more than 2,000 strings. Pair it with Finding 2's length bound.

#### 2. The pair cap bounds comparisons, not bytes: per-pair cost is linear in URL length, so long values stall the scan for minutes within every cap

**Severity:** Medium
**Location:** `devcontainer-config/cc-exit-scan.sh:433-444` (`_snap_match`), `:411-416` (cap block)
**Move:** 9 (asymptotic behaviour), 2 (size of N)
**Confidence:** High for the per-pair cost (measured); Medium for the full-scale wall time (extrapolated)
**Baseline:** one 1 MB URL against 200 non-matching rules: 1.955 s (≈10 ms/pair); one 4 MB URL against 800 rules: 40.768 s (≈51 ms/pair) (probe `p5.sh`, 2026-10-15)
**Classification:** Macro (cost × length, length uncapped) / cold path escalated (blocks the user at exit, adversarial data)
**Legibility-target:** a user whose exit scan appears hung; the author deciding whether the caps "stop a stall" as the commit says
**Evidence:**
```
_snap_match() {
  local LC_ALL=C ui="$1" ri="$2" n="$3" k u p
  for ((k = 0; k < n; k++)); do
    u="${_snap_urls[ui]}"; p="${_snap_rpfx[ri]}"
    if [[ "$u" == "$p"* ]]; then
```
(function continues: the hit append, the index step, `done`, `}`)

Each iteration copies the URL out of the array and pattern-matches it; both are O(|u|) in bash even under `LC_ALL=C` (isolated: 200 copies of a 1 MB element 1.002 s; 200 `[[ "$u" == "$p"* ]]` on a hoisted 1 MB `u` 0.572 s; 200 `[ "${u:0:${#p}}" = "$p" ]` 0.262 s, probe `p6.sh`). In the URL batch (`step 0`) the same URL is recopied once per rule. A 1 MB `remote.x.url` plus 100,000 short rules (~3 MB) is far under the 64 MiB file cap and exactly at the pair cap (charged 100,000, which is not `> 100000`): ≈100,000 × 10 ms ≈ 17 min for one snapshot; 4 MB gives ≈1.4 h (extrapolated). The commit body acknowledges "Long values still slow each comparison" and points to the guide's "A slow scan" route, which does not mention the insteadOf pass (see the api-consistency report's Finding 4). It is the same class as override-log row 134 (cost grows with entries; deferred), but row 134 is about entry count, and this one escapes a cap the commit presents as the stall guard.

**Recommendation:** Bound bytes, not just pairs: either fail closed on a remote URL or insteadOf value longer than a fixed limit (a local push target longer than PATH_MAX, 4,096 bytes, cannot be opened by git anyway; a generous 64 KiB cap costs nothing for real configs), or charge `${#u}` per pair against a byte budget in `_snap_pairs`. Hoisting `u` out of the loop in the `step 0` batch halves the constant but does not fix the scaling. Name the residual cost in "A slow scan".

#### 3. At the 2,000-target cap the pass can still add ~30 s per snapshot; the cap's comment and the guide do not price it

**Severity:** Low
**Location:** `devcontainer-config/cc-exit-scan.sh:411-416` (cap block and comment), `:455-466` (`_snap_rewrite`); `guides/cc-isolated-usage.md:413-418`
**Move:** 1 (hidden multiplication), 10 (deployment environment)
**Confidence:** High on this host; fork cost varies by host (WSL2 here)
**Baseline:** 2,000 local URLs walked with no rule match 11.8 s vs 41.4 s with one rule matching all, so ≈29.6 s (≈15 ms per walked target) attributable to the 2,000 targets (probes `p4c.sh 2000 1000` and `p4.sh 2000 1000`, 2026-10-15)
**Classification:** Macro (bounded at 2,000 × forks) / cold path, blocking at exit
**Legibility-target:** the author who chose 2,000 ("each of which can cost a few forks"); a user waiting at exit
**Evidence:**
```
# stall the scan): URL-and-rule pairs compared, checked before each batch
# (_snap_pairs), and distinct rewritten URLs walked, each of which can cost a few
# forks (_snap_rewrite). Over either, the snapshot fails (fail closed).
GIT_EXIT_SCAN_MAX_REWRITE_PAIRS=100000
GIT_EXIT_SCAN_MAX_REWRITE_TARGETS=2000
```

The cap does what it says: past 2,000 the scan fails closed (2,500 targets: failed at 32.7 s). But the ceiling it sets is ~30 s of forks on this host, and that is on top of the existing uncapped per-URL walk (2,000 plain local URLs alone took 11.8 s, the row-134 class). The commit's own number ("10k matches took 44 s") is consistent with ≈4–15 ms per target. This is acceptable as a fail-closed bound, but neither the comment nor the guide gives the user the figure.

**Recommendation:** State the measured ceiling (≈15 ms a target here, so up to ~30 s per snapshot) in the cap comment and in "A slow scan"; consider 500 if real configs never approach it (a real checkout has a handful of rewritten remotes).

#### 4. The `LC_ALL=C` prefix on every `read` triples each read's cost; one `local LC_ALL=C` per loop costs nothing

**Severity:** Low
**Location:** `devcontainer-config/cc-exit-scan.sh:232, 335, 482, 607, 684, 719, 728, 743, 751, 821, 999`
**Move:** 3 (work moved to the wrong place: a locale switch per record instead of per loop)
**Confidence:** High
**Baseline:** 100,000 NUL-separated records: `IFS= read` 0.364 s, `LC_ALL=C IFS= read` 1.288 s (≈9 µs extra per read, two `setlocale` calls), `local LC_ALL=C` set once in the reading function then `IFS= read` 0.339 s (probes `p1.sh`, `p2.sh`, 2026-10-15)
**Classification:** Micro (per-read constant) / cold path; hot only under adversarial record counts
**Legibility-target:** the author, if row-134-style slowness is ever revisited
**Evidence:**
```
  while LC_ALL=C IFS= read -r -d '' rec; do
```
```
  while LC_ALL=C IFS= read -r -d '' origin && LC_ALL=C IFS= read -r -d '' rec; do
```

Realistic configs and find lists are tens to hundreds of records, so the cost is under 10 ms per snapshot. Adversarially, a 64 MiB config of ~2 M short records adds ≈18 s to the `_snap_config` loop (extrapolated). The fix is correct; only its placement pays a locale switch per record.

**Recommendation:** Optional. If kept per-read, fine. If changed, wrap each reading loop in a function or subshell with `local LC_ALL=C` and check that nothing else in the loop body forks a locale-sensitive child or relies on `printf %q` output in the caller's locale (records must stay byte-identical between the launch and exit snapshots, which both run the same code, so this is a consistency check, not a blocker).

## Endorsements

- The pair cap is now charged per batch before any comparison runs, so a too-large batch fails before its O(*U*) or O(*R*) loop starts. `[read: devcontainer-config/cc-exit-scan.sh:418-424, 839-857]`
- Moving the comparison into one `_snap_match` call per batch keeps the `local LC_ALL=C` switch to one per batch (≈10 µs each, measured) rather than one per pair, and keeps `_snap_remote`'s forks outside the C-locale scope. `[read: devcontainer-config/cc-exit-scan.sh:433-466]`
- Claim: with short strings, the full 100,000-pair budget costs ≈0.7–1.4 s of `_snap_match` time on this host, so the pair cap itself bounds the comparison loop at short lengths. `[unverified — submitted as claim]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Target cap checked after a whole batch of hits is built; memory = batch × base length | Medium | `cc-exit-scan.sh:433-466, 849-855` | High |
| 2 | Pair cap bounds comparisons, not bytes; long URL × many rules stalls for minutes within caps | Medium | `cc-exit-scan.sh:433-444` | High / Medium (extrapolation) |
| 3 | 2,000-target ceiling is ~30 s of forks per snapshot, unpriced in comment and guide | Low | `cc-exit-scan.sh:411-416`; guide 413-418 | High |
| 4 | `LC_ALL=C` prefix triples per-read cost; per-loop `local` is free | Low | `cc-exit-scan.sh` reads (11 sites) | High |

## Overall Assessment

The iteration-1 restructure fixes what iteration 1 asked for: comparisons are charged before work, the locale switch is per batch, and a target cap now exists and fails closed (measured). Every outcome found here still fails closed or finishes; none is a bypass. The remaining performance gap is that both caps count items while cost scales with item length. The batching moved the target check after materialization (Finding 1), and long values make each counted pair cost milliseconds (Finding 2). Both are fixable in place with a length bound on URL/rule values plus counting distinct targets inside `_snap_match`. Neither needs a redesign. Findings 3–4 are documentation and constant-factor notes. The multi-GB and multi-minute full-scale figures are extrapolations from linear measurements at smaller sizes, kept small under the probe rules. Confirming them would need a host-sized run, which this pass did not do.

## Goal-Alignment Note

Success criterion: "Two markdown reports saved under docs/reviews/ per the performance-reviewer and api-consistency-reviewer skills, first line Commit: e4b29291." This is the performance report, saved under `docs/reviews/` with first line `Commit: e4b29291`, in the skill's structure (data flow, findings with Baseline, Move, Classification, Severity, Location, Evidence, Confidence, Legibility-target, evidence-tagged endorsements, summary, assessment). It checks the iteration-1 insteadOf fixes the brief named (per-batch pair cap, 2,000-target cap, `_snap_match` under `local LC_ALL=C`, `_snap_walk_hits`, `LC_ALL=C` on every read) at realistic and adversarial sizes using small, timeout-bounded probes, all of which exited on their own. For the user goal (land Q-096 without a rewrite route the scan ignores), none of these findings opens a route: every one fails closed or completes. Findings 1–2 are stall and memory hardening the loop can take in place or defer under row 134 with the guide updated.
