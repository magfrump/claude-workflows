Commit: 03bc47c9

# Performance Review — fix/q096-exit-scan-insteadof-target, final confirming pass (main...03bc47c9)

**Scope:** `git diff main...HEAD -- . ':!docs/reviews'` at 03bc47c9 (full branch: `cc-exit-scan.sh`, `guides/cc-isolated-usage.md`, `test/cc-isolated-functions.bats`, plan, research, brief), with the whole post-change `devcontainer-config/cc-exit-scan.sh` read where a finding depends on it
**Date:** 2026-10-15
**Based on:** shared brief `shared-brief-final.md`; prior reports p1–p3 (advisory), the p3 code-fact-check report (`q096-exit-scan-insteadof-target-p3-code-fact-check-report.md`, claims 5 and 21); probes in `/home/node/.claude/jobs/00bcf178/tmp/q096/probe-performance-final/` (bash 5.2, git 2.39.5, WSL2 container; `GIT_CONFIG_GLOBAL` in the probe dir, `GIT_CONFIG_NOSYSTEM=1`; every run in the foreground under `timeout` ≤300 s, every run exited on its own, and a `ps` check afterwards found none still running)

> ⚠️ **No code fact-check report provided for this pass.** The p3 fact-check report (on 013f1b3d) is used where its claims are unchanged at 03bc47c9. Claims in comments and docs that changed in 03bc47c9 have not been independently verified beyond the probes below.

## Data Flow and Hot Paths

`git_exec_snapshot` (`cc-exit-scan.sh:779-860`) runs twice per session, at launch and at exit, and the user waits for both. It is not a request path. The exit run reads a checkout a hostile session wrote, so data sizes are adversarial. Per the hot-path gate, every finding below is **cold**, escalated only where adversarial data blocks the user at exit.

The branch adds a pass over the snapshot. `_snap_url` (`:412-418`) queues every remote URL with its working tree, deduped by a `_snap_key` key (`:401-408`, under `local LC_ALL=C`), and walks it with `_snap_remote` as main did. `_snap_rule` (`:422-427`) queues every insteadOf/pushInsteadOf rule from repo config and from your own config. The closing worklist (`:830-856`) compares each URL with each rule once. It charges `_snap_pairs_ok` per batch (cap 100,000). `_snap_match` (`:444-458`) cuts under `LC_ALL=C` and checks the 2,000-target cap before every append. `_snap_walk_hits` (`:462-471`) dedupes the hits and walks them. Every string is capped at 4,096 bytes on entry. Since p3, 03bc47c9 changed only the byte-cap message, two comments, the guide and tests. No code path changed cost.

Measured this pass (2026-10-15):

| Probe | Result |
|---|---|
| `p5.sh` N https `remote.rN.url`, no rules, main vs head (C.utf8) | 5k: 2.78 vs 3.72 s; 10k: 6.13 vs 8.52 s |
| same 10k, head with every `LC_ALL=C IFS= read` reverted to `IFS= read` (`noread/`) | 8.38 s |
| same 10k, head with `_snap_key`'s `local LC_ALL=C` removed (`nokeyloc/`) | 8.09 s |
| same 10k, head with the worklist's URL batches skipped (`nowl/`) | 7.31 s (head on the same run: 7.51 s) |
| same 10k, head with `_snap_url` reduced to its `_snap_remote` call (`nourl/`) | 6.09 s (≈ main) |
| `p8.sh` 10k, snapshot in-process, peak RSS | main 5.70 s, VmHWM 5,748 kB; head 7.80 s, VmHWM 10,476 kB |
| `forkcost.sh` 2,000 `$(printf '%q' …)` after queueing N URL-like entries | N=0: 286 µs/fork (RSS 2.9 MB); 10k: 309; 40k: 420 (16 MB); 160k: 893 (55 MB) |
| `assoc.sh` N inserts+lookups (assoc) / appends (indexed) | linear: 40k 0.19 s / 0.09 s; 80k 0.35 / 0.16 s |
| `p9.sh` your config: 3 remotes, 2 rules; checkout with E embedded repos (instrumented copy `count/`) | E=10: 33 URLs, 66 pairs, 0.27 s; E=100: 303 URLs, 606 pairs, 2.49 s |
| `p10.sh` 200 https remotes, one rule rewriting all into the checkout | no rule (`p5.sh head 200`): 0.15 s; targets absent: 0.83 s; each target a planted bare repo: 5.08 s |
| `bats test/cc-isolated-functions.bats -f 'Q-096'` (LC_ALL=C) | 11/11 ok |

Run-to-run noise on the 10k probes is about ±0.5 s (head measured 7.51, 7.80 and 8.52 s).

### Prior (p3) findings

- p3 F1 (per-URL cost with no rules, Low): **still present, left by decision.** The 03bc47c9 commit Notes cite override-log row 134. Re-measured and partly attributed below as Finding 1. It is not filed as new.
- p3 F2 ("about 30 s" is a WSL2 figure): **addressed.** The guide now says "10-80 s (a WSL2 host; the most when each is a planted repository)" (`guides/cc-isolated-usage.md:418-419`). That matches p3 fact-check claim 21 (77 s added for 1,999 planted repos) and this pass's per-target cost (Finding 3).

## Findings

#### 1. The URL queue raises per-URL cost about 1.4–2.4 s per 10k remotes with no rules; part of the superlinear growth comes from queue memory making every later fork slower

**Severity:** Low
**Location:** `devcontainer-config/cc-exit-scan.sh:412-418` (`_snap_url`), `:401-408` (`_snap_key`); interacts with the pre-existing per-entry fork at `:492` (`_snap_config`'s `$(printf '%q' "$f")`)
**Move:** 1 (hidden multiplication), 4 (memory lifecycle)
**Classification:** Macro (linear queue cost, plus a coupling in which queue size scales the cost of each of the scan's O(N) forks) / cold path, escalated only for adversarial data at exit
**Confidence:** High for the measurements; Medium for the attribution (variants ±0.5 s noise)
**Baseline:** 10,000 https `remote.*.url` entries, no rules: main 5.70–6.13 s vs head 7.51–8.52 s per snapshot; peak RSS 5,748 kB vs 10,476 kB (probes `p5.sh`, `p8.sh`, 2026-10-15, this WSL2 container)
**Legibility-target:** the author weighing whether override-log row 134 ("scan cost grows with entries") covers this pass; a maintainer on Q-097, which edits the same file
**Evidence:**
```
_snap_url() {
  _snap_key "$1" "$2" check || return 1
  [ -z "${_snap_rwseen["u:$_snap_k"]:-}" ] || return 0
  _snap_rwseen["u:$_snap_k"]=1
  _snap_urls+=("$1"); _snap_ubases+=("$2")
  _snap_remote "$1" "$2"
}
```
```
    _snap+="C"$'\t'"$(printf '%q' "$f")"$'\t'"${key//$'\t'/?} ${t//$'\t'/?}"$'\n'
```
(`_snap_config` line 492, inside the `while LC_ALL=C IFS= read` loop that runs once per config entry; that loop continues through the `case "$key"` dispatch to `done < "$out"` at `:524`)

This pass ruled two suspects out. Reverting every `LC_ALL=C` read prefix (8.38 s) or `_snap_key`'s local locale (8.09 s) leaves the 10k time within noise of head (7.51–8.52 s). Reducing `_snap_url` to its `_snap_remote` call brings head back to main (6.09 s). Bash's associative and indexed arrays scale linearly here (`assoc.sh`). So the cost is the queue itself: two keys per URL, two array slots and the dedupe entry, about 4.7 MB more peak RSS at 10k. Every `$(…)` forks the shell, and fork cost grows with RSS (286 → 420 µs per fork from 3 to 16 MB, `forkcost.sh`). The scan forks at least once per config entry. Queue memory therefore makes each later fork slower, which is consistent with p3's superlinear end-to-end growth (40k: 29.7 vs 55.2 s). Main has the same coupling through its growing `_snap` string; the queue steepens it. All of it is bounded by the existing 64 MiB/1 GiB file caps and is the "A slow scan" route. Nothing here opens a route or stalls the scan unboundedly.

**Recommendation:** No change needed to land, since the commit Notes record this as accepted. If Q-097 or a later unit wants the time back, the lever is the per-entry `$(printf '%q')` fork in `_snap_config` (`printf -v` would avoid it). That fork predates this branch and costs main too. The queue itself is not the lever.

#### 2. Your own remotes are queued once per git dir, so your remotes × embedded repos × rules counts against the 100,000-pair cap

**Severity:** Informational
**Location:** `devcontainer-config/cc-exit-scan.sh:615-618` (`_snap_host_config`), called per git dir at `:814` and `:827`
**Move:** 2 (size of N)
**Classification:** Macro (pairs = H × (E+1) × R) / cold path
**Confidence:** High (measured counts)
**Baseline:** 3 remotes and 2 rules in your config: 10 embedded repos → 33 URLs, 66 pairs; 100 embedded repos → 303 URLs, 606 pairs (probe `p9.sh` with an instrumented copy, 2026-10-15)
**Legibility-target:** a user whose launch is refused by the pair cap on a checkout with many embedded repos; the author deciding whether the guide's cap sentence needs this
**Evidence:**
```
    # Your rewrite rules apply to repo URLs, and any rule to your remotes' URLs.
    case "$key" in
      url.*.insteadof|url.*.pushinsteadof) t="${key#url.}"; _snap_rule "${t%.*}" "$val" || return 1 ;;
      remote.*.url|remote.*.pushurl) _snap_url "$val" "$wt" || return 1 ;;
    esac
```
(inside the per-record loop of `_snap_host_config`, which goes on to the hooksPath/attributesFile/include cases and `done < "$out"` at `:640`)

The `u:` key includes the working tree, so each of your H remotes is queued again for every embedded repo. Every one then meets every rule. That is correct: a relative URL, or a rule rewriting into a relative path, resolves in each working tree, so the dedupe cannot drop the working tree. The consequence is that H × (E+1) × R > 100,000 fails the launch closed, for example 5 remotes × 20 rules × 1,000 embedded repos. Few users keep `remote.*` entries in their global config, so this is unlikely in practice. A session that plants embedded repos to trip the cap at exit only gets a fail-closed exit 4. Each comparison is a bash pattern test, about 7 µs at 20 bytes (p3 `p1.sh`).

**Recommendation:** None required. Optionally add "(your own remotes count once per embedded repository)" to the guide's cap sentence (`guides/cc-isolated-usage.md:347-350`).

#### 3. The cap comment prices a rewritten target at "a few forks"; a planted target costs a full git-dir walk, about 25 ms here

**Severity:** Informational
**Location:** `devcontainer-config/cc-exit-scan.sh:390-393`
**Move:** 10 (price the deployment environment)
**Classification:** Micro (a documented per-target constant, bounded by the 2,000 cap) / cold path
**Confidence:** High (measured; agrees with p3 fact-check claim 5: 4.5 ms absent, 39 ms planted)
**Baseline:** 200 rewritten targets: 0.83 s when absent vs 5.08 s when each is a planted bare repo, against 0.15 s with no rule: about 3.4 ms and 24.7 ms per target (probe `p10.sh`, 2026-10-15)
**Legibility-target:** a maintainer tuning `GIT_EXIT_SCAN_MAX_REWRITE_TARGETS` from the comment
**Evidence:**
```
# Caps on the insteadOf pass, against a session planting many or huge URLs and
# rules to stall the scan: bytes in one URL, rule base or value (_snap_key);
# pairs compared (_snap_pairs_ok); rewritten URLs to walk, each a few forks
# (_snap_match). Over any of them the snapshot fails (fail closed).
```
A planted target runs `_snap_remote` → `_snap_gitdir`. That reads its config, hooks, legacy remotes and symlinks, and searches `modules/` and `worktrees/`, at several forks each. At the cap that comes to about 7 s (absent) to about 50 s (planted) on this run, and 77–90 s in p3 under load. The guide's "10-80 s" covers that range. The comment alone understates it by roughly an order of magnitude for the case a session controls. p3 fact-check claim 5 noted this. It was not re-filed then, and 03bc47c9 fixed the guide but not the comment.

**Recommendation:** Optional: "each a walk of what it names (a planted git dir: tens of ms)". No code change.

## Endorsements

- Each (URL, rule) pair is compared exactly once, including URLs and rules found while walking hits. A URL batch meets rules `0..r-1`, a rule batch meets URLs `0..u-1`, and both indexes only grow, so total comparisons are U × R and the per-batch charge to `_snap_pairs_ok` equals the work about to run. `[read: devcontainer-config/cc-exit-scan.sh:430-458, 830-856]`
- Every URL, rule base and value passes `_snap_key … check` before it is queued, so no comparison or cut in `_snap_match` handles a string over 4,096 bytes. A batch builds at most `GIT_EXIT_SCAN_MAX_REWRITE_TARGETS − _snap_rwt` hit strings before it fails closed. `[read: devcontainer-config/cc-exit-scan.sh:401-427, 444-458]`
- `_snap_match … && _snap_walk_hits || rc=1` skips the walk when matching trips a cap, and `while [ "$rc" -eq 0 ]` then stops, so a tripped cap does no further batches. `[read: devcontainer-config/cc-exit-scan.sh:830-856, 444-471]`
- Claim: the `LC_ALL=C` prefix on every `read` and the `local LC_ALL=C` in `_snap_key` do not measurably change scan time. At 10k remote entries, reverting either leaves the snapshot within run-to-run noise (8.38 s / 8.09 s vs head 7.51–8.52 s; probes `noread/`, `nokeyloc/`). `[unverified — submitted as claim]`
- Claim: 4,096 bytes is above any legitimate remote URL or insteadOf value, so the byte cap should never refuse a real launch (carried from p3). `[unverified — submitted as claim]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | URL queue adds ~1.4–2.4 s per 10k no-rule remotes; queue memory slows each later fork (superlinear) | Low | `cc-exit-scan.sh:401-418` (with `:492`) | High (measured) / Medium (attribution) |
| 2 | Your remotes queued once per git dir: H × (E+1) × R counts against the pair cap | Informational | `cc-exit-scan.sh:615-618, 814, 827` | High |
| 3 | Cap comment says "a few forks" per target; a planted target is a git-dir walk (~25 ms) | Informational | `cc-exit-scan.sh:390-393` | High |

## Overall Assessment

The branch's performance posture is sound and bounded. Every adversarial cost the insteadOf pass adds is capped and fails closed: string length, comparisons, and rewritten targets. 03bc47c9 changed no costed code path, and the Q-096 tests pass (11/11). The one Low finding is the known, accepted per-entry cost (row 134). This pass narrows its cause to the queue's memory, which interacts with the scan's pre-existing per-entry forks. It rules out the locale prefixes. The cheapest future lever is outside this diff. The two Informational findings are a cap-arithmetic note for users with global remotes and a stale per-target price in one comment. No finding is red or an unresolved amber, and none needs a code change before merge.

## Goal-Alignment Note

Success criterion: "Two markdown reports saved under docs/reviews/ per the performance-reviewer and api-consistency-reviewer skills, first line Commit: 03bc47c9." This is the performance report, saved at `docs/reviews/q096-exit-scan-insteadof-target-final-performance-review-2026-10-15.md` with first line `Commit: 03bc47c9`, in the skill's structure. It covers the full branch at 03bc47c9 and the brief's claims 2–3 and 5 from the cost side: the worklist, the caps, and `LC_ALL=C` on reads and keys. It uses small, timeout-bounded probes that all exited. For the user goal (land Q-096 so no insteadOf rewrite escapes the scan), nothing here opens a route: every measured path completes or fails closed, and the findings are Low/Informational, consistent with a 0-red, 0-unresolved-amber merge.
