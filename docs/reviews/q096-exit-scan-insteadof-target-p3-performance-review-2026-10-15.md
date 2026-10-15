Commit: 013f1b3d

# Performance Review — fix/q096-exit-scan-insteadof-target, iteration 3 (e4b29291..013f1b3d)

**Scope:** `git diff e4b29291..013f1b3d -- . ':!docs/reviews'` (4d7f966c iteration-2 fixes, 013f1b3d early split): `GIT_EXIT_SCAN_MAX_REWRITE_BYTES`, `_snap_key` (under `local LC_ALL=C`, per call), the per-hit target check in `_snap_match`, `_snap_walk_hits`, the `&&` worklist wiring; 5f754994 and e4b29291 as context only
**Date:** 2026-10-15
**Based on:** shared brief `shared-brief-p3.md`; prior report `q096-exit-scan-insteadof-target-p2-performance-review-2026-10-15.md`; probes in `/home/node/.claude/jobs/00bcf178/tmp/q096/probe-performance-p3/` (bash 5.2, git 2.39.5, 16-core WSL2 container, `LC_ALL=LANG=C.utf8`, `GIT_CONFIG_GLOBAL` in the probe dir, `GIT_CONFIG_NOSYSTEM=1`; every run foreground under `timeout ≤600`, all exited on their own; `ps` afterwards showed none left)

> ⚠️ **No code fact-check report provided.** Performance claims in comments and documentation
> have not been independently verified. For full verification, run the `code-fact-check` skill
> first or use the code-review orchestrator.

## Data Flow and Hot Paths

`git_exec_snapshot` runs twice per session (launch, exit), both blocking the user. Not a request path, but the exit snapshot reads a checkout a hostile session wrote, so sizes are adversarial; per the hot-path gate each finding states the temperature as "cold, escalated only for adversarial data that blocks the user".

At 013f1b3d every URL (`_snap_url`), rule (`_snap_rule`) and rewritten target (`_snap_walk_hits`) gets a key from `_snap_key` (`cc-exit-scan.sh:401-408`), which sets `local LC_ALL=C` on every call; `_snap_url`/`_snap_rule` pass `check`, which fails closed when either string is over 4,096 bytes. The worklist (`:829-857`) charges `_snap_pairs_ok` per batch, then `_snap_match` (`:444-458`) compares and, per hit, fails closed once `_snap_rwt + ${#_snap_hit_t[@]}` reaches 2,000, so a batch never holds more than 2,000 strings; only if it succeeds does `_snap_walk_hits` (`:462-471`) count, dedupe (`t:` key) and walk each hit.

Measured on this host (2026-10-15):

| Probe | Result |
|---|---|
| `p1.sh 20 100 1000 nomatch`: 100,000 pairs, 20-byte strings, no match | 0.73 s |
| `p1.sh 4096 100 1000 nomatch`: 100,000 pairs, 4,096-byte URL vs 4,096-byte value differing in the last byte | 5.29 s, VmHWM 8.7 MB |
| `p1.sh 4096 100 1000 match`: same, all match (hits reset per batch) | 6.50 s |
| `p4.sh 2000` / `p4.sh 3000`: one empty-value rule with a 4,096-byte base against 4,096-byte URLs | 2,000 hits in 0.12 s, VmHWM 12.3 → 28.7 MB; at 3,000 fails closed at hit 2,001, VmHWM 32.8 MB |
| `p2.sh 100000`: 100,000 key builds, old inline `k="u:${#1}:$1$2"` vs `_snap_key … check` | 0.387 s vs 1.988 s (≈16 µs extra per call) |
| `p6.sh 40000`: in-process `_snap_url` × 40,000 https URLs, then the worklist with zero rules | queue 1.74 s, worklist 1.26 s |
| `p5.sh` end to end, N https `remote.rN.url`, no rules, main vs branch | 5k: 2.61 vs 3.63 s; 10k: 5.53 vs 8.08 s; 20k: 12.04 vs 17.07 s; 40k: 29.69 vs 55.24 s |
| `p7.sh` A: 3 URLs × 3 matching rules, cap 2 | one failure message, rc 1 (the `while [ "$rc" -eq 0 ]` loop stops after the batch) |
| `p7.sh` B: one URL `abc`, rules `url.Z.insteadOf=a` and `url.Zb.insteadOf=ab` (same target `Zbc`), cap 1 | fails closed: the two hits count as two targets |

`bats test/cc-isolated-functions.bats -f 'Q-096'` (LC_ALL=C): 13/13 ok.

### Prior (p2) findings

- p2 F1 (target cap checked after the whole batch was built): **addressed.** `_snap_match:449-453` checks before every append; measured peak with maximal strings is ~16 MB over baseline, then fail closed.
- p2 F2 (pair cap bounds comparisons, not bytes): **addressed.** The byte cap bounds the full 100,000-pair budget at ≈5–6.5 s on this host (p2 extrapolated ≈17 min for a 1 MB URL).
- p2 F3 (~30 s at the target cap, unpriced): **addressed** in the guide's "A slow scan" (`guides/cc-isolated-usage.md:418-419`); see Finding 2 on the figure's host-dependence. The cap comment (`:390-393`) says "each a few forks" without the number, acceptable.
- p2 F4 (`LC_ALL=C` prefix per read): **left by decision** (commit 4d7f966c Notes: "under 10 ms on real configs"); not re-filed.

## Findings

#### 1. Per-URL cost of the insteadOf pass roughly doubles the scan for many remote URLs with no rule; `_snap_key`'s per-call locale switch is the in-scope part

**Severity:** Low
**Location:** `devcontainer-config/cc-exit-scan.sh:401-408` (`_snap_key`), `:412-418` (`_snap_url`), `:837-842` (URL batch of the worklist, context: e4b29291)
**Move:** 1 (hidden multiplication), 2 (size of N)
**Classification:** Macro (cost linear in planted entries, entries bounded only by the 64 MiB file / 1 GiB total caps) / cold path, escalated only for adversarial data at exit
**Confidence:** High for the measurements; Low for attributing the end-to-end delta beyond the in-process 3 s (not measured)
**Baseline:** 40,000 https `remote.*.url` entries, no rules: 29.69 s on main vs 55.24 s on the branch (probe `p5.sh`, 2026-10-15); `_snap_key … check` 1.988 s vs 0.387 s inline per 100,000 calls (probe `p2.sh`)
**Legibility-target:** the author weighing whether "A slow scan" covers the pass; a user whose exit scan stalls on a checkout with many planted remotes
**Evidence:**
```
_snap_key() {
  local LC_ALL=C
  _snap_k="${#1}:$1$2"
  [ -n "${3:-}" ] || return 0
  [ "${#1}" -gt "$GIT_EXIT_SCAN_MAX_REWRITE_BYTES" ] || [ "${#2}" -gt "$GIT_EXIT_SCAN_MAX_REWRITE_BYTES" ] || return 0
  _snap_fail 'a remote URL or insteadOf rule over %s bytes: too long to compare, treat the checkout as unsafe' \
    "$GIT_EXIT_SCAN_MAX_REWRITE_BYTES"
}
```
```
    elif [ "$u" -lt "${#_snap_urls[@]}" ]; then
      # URL u against rules 0..r-1.
      _snap_pairs_ok "$r" || { rc=1; break; }
      _snap_hit_t=() _snap_hit_b=()
      _snap_match "$u" 0 "$r" 0 && _snap_walk_hits || rc=1
      u=$((u + 1))
```
(worklist continues: the rule batch, `else break`, `done`)

With zero rules no pairs are charged, so neither count cap limits the number of URLs; every URL pays `_snap_key` (a `setlocale` pair, ≈16 µs measured) plus one worklist step that calls `_snap_pairs_ok`, `_snap_match` (another `local LC_ALL=C`) and `_snap_walk_hits`. In process that is ≈75 µs a URL, linear (3.0 s at 40,000, `p6.sh`). End to end the branch adds 1.0 s at 5k, 2.5 s at 10k, 5.0 s at 20k and 25.5 s at 40k, faster than linear; the remaining ~22 s at 40k is not attributed (a plausible but unmeasured cause is slower `$(…)` forks in a larger process, as main's own time is also superlinear). Only the `_snap_key` share (≈0.64 s at 40k) is new in this scope; the worklist step is e4b29291. Realistic checkouts have a handful of remotes: under 10 ms. The cost is the override-log row 134 class (scan cost grows with entries; fail-closed; deferred) and never opens a route.

**Recommendation:** Defer under row 134. If revisited: skip the `_snap_match`/`_snap_walk_hits` calls when the batch size is 0 (`r` or `u` is 0), and build the key inline in `_snap_url`/`_snap_rule` under one `local LC_ALL=C` there, not a function call each. Optionally say in "A slow scan" that many remote URLs slow the pass too, not only rewritten ones.

#### 2. The guide's "about 30 s" at the caps is one host's fork cost, stated without a host

**Severity:** Informational
**Location:** `guides/cc-isolated-usage.md:418-419`
**Move:** 10 (price the deployment environment)
**Classification:** Micro (documentation of a bounded constant) / cold path
**Confidence:** Medium (the figure matches p2's measurement; other hosts not measured)
**Baseline:** 2,000 walked targets ≈29.6 s (≈15 ms each) on this WSL2 container, p2 probes `p4.sh`/`p4c.sh` 2026-10-15 (not re-run this pass)
**Legibility-target:** a user on native Linux or macOS reading the guide
**Evidence:**
```
  take a long time; at the `insteadOf` caps, rewritten URLs alone add about
  30 s. If you stop it, treat the checkout as unscanned.
```

The figure is the p2 measurement on WSL2, where a fork costs several ms; native Linux forks are typically far cheaper, so the real ceiling may be a few seconds. The bullet's other figures ("about 2–4 s per snapshot on a ~400k-file repository") likewise carry no host, so this follows the bullet's convention; it is flagged only so nobody tunes the cap on this number alone. The figure also excludes Finding 1's per-URL cost.

**Recommendation:** Optional: "about 30 s on a WSL2 host". No code change.

## Endorsements

- Every URL, rule base and value is length-checked before it is queued, so each `_snap_match` comparison and cut works on strings of at most 4,096 bytes; measured, the whole 100,000-pair budget at that length costs 5.3–6.5 s here (probe `p1.sh`), against p2's ≈17 min extrapolation for a 1 MB URL. `[read: devcontainer-config/cc-exit-scan.sh:401-427, 444-458]`
- A batch never holds more than `GIT_EXIT_SCAN_MAX_REWRITE_TARGETS − _snap_rwt` rewritten strings, each at most 8,192 bytes (base + URL), before `_snap_match` fails closed: ≈16 MB at the defaults (measured: VmHWM +16 MB at 2,000 maximal hits, fail closed at 2,001, probe `p4.sh`). `[read: devcontainer-config/cc-exit-scan.sh:444-458, 829-857]`
- `_snap_match … && _snap_walk_hits || rc=1` skips the walk when matching fails and sets `rc=1` on either failure; the `while [ "$rc" -eq 0 ]` loop then ends, so a tripped cap prints one message and does no further batches (probe `p7.sh` A: one message). `[read: devcontainer-config/cc-exit-scan.sh:829-857]`
- Counting the target budget per hit, before the `t:` dedupe in `_snap_walk_hits`, makes the cap conservative: duplicate targets spend budget (probe `p7.sh` B), which can only fail closed sooner, never let more walks through. The documentation side of that is in the api-consistency report. `[read: devcontainer-config/cc-exit-scan.sh:449, 462-471]`
- Claim: 4,096 bytes is above any legitimate remote URL or insteadOf value (hosted https URLs, including embedded tokens, run to a few hundred bytes; a local path past PATH_MAX cannot be opened), so the byte cap should never refuse a real launch. `[unverified — submitted as claim]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Many no-rule remote URLs: the pass ~doubles scan time at 40k (55.2 vs 29.7 s); `_snap_key`'s per-call locale switch is the in-scope ≈16 µs/call | Low | `cc-exit-scan.sh:401-418, 837-842` | High (measured) / Low (attribution) |
| 2 | "About 30 s" at the caps is a WSL2 fork figure without a host | Informational | `guides/cc-isolated-usage.md:418-419` | Medium |

## Overall Assessment

Iteration 2's performance fixes work as claimed and were measured: the byte cap turns the worst comparison budget from minutes-to-hours into ≈6 s, and the per-hit target check caps a batch's memory at ≈16 MB, failing closed one hit past the cap. Both p2 Medium findings are closed. What remains is the known row-134 class: per-entry cost with no count cap when there are no rules (Finding 1, mostly from the e4b29291 worklist, with `_snap_key` adding a small in-scope share) and a host-specific number in the guide (Finding 2). Neither needs a code change to land Q-096. The end-to-end superlinearity at 40k URLs is measured but not attributed. Explaining it would need a fork-count profile, which this pass did not do.

## Goal-Alignment Note

Success criterion: "Two markdown reports saved under docs/reviews/ per the performance-reviewer and api-consistency-reviewer skills, first line Commit: 013f1b3d." This is the performance report, saved at `docs/reviews/q096-exit-scan-insteadof-target-p3-performance-review-2026-10-15.md` with first line `Commit: 013f1b3d`, in the skill's structure (data flow, findings with Baseline, Move, Classification, Severity, Location, Evidence, Confidence, Legibility-target, evidence-tagged endorsements, summary, assessment). It covers the brief's named items (byte cap, per-hit target cap, `_snap_key` under `LC_ALL=C` per call, `_snap_walk_hits`), checks the p2 findings were addressed, and uses only small, timeout-bounded probes that all exited. For the user goal (land Q-096 with no insteadOf route the scan ignores), nothing here opens a route or blocks landing: every path measured either completes or fails closed.
