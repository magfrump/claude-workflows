Commit: 013f1b3d

# Security Review — Q-096 exit scan, insteadOf targets (iteration 3)

**Scope:** `git diff e4b29291..013f1b3d -- . ':!docs/reviews'` (commits 4d7f966c, 013f1b3d) on branch `fix/q096-exit-scan-insteadof-target`. Context read: the whole post-change `devcontainer-config/cc-exit-scan.sh` up to `git_exec_snapshot`, the launcher's snapshot call (`cc-isolated.sh:859`), `git diff main...013f1b3d`
**Date:** 2026-10-15
**Based on:** shared brief p3; prior security reports p1 and p2 (advisory). The orchestrator supplied the goal preamble.

> ⚠️ **No code fact-check report provided for this pass.** Claims about security properties in comments and documentation have not been independently verified by code-fact-check. I checked the ones below myself, by experiment where marked.

Probes: `/home/node/.claude/jobs/00bcf178/tmp/q096/probe-security-p3/e1.sh`–`e5.sh`. Each ran with `GIT_CONFIG_GLOBAL` set to a file in the probe dir, `GIT_CONFIG_NOSYSTEM=1` and `HOME` set to the probe dir, under `timeout` ≤ 600. All ran in the foreground and exited; `ps` showed none left running.

## Trust Boundary Map

```
B1: [checkout .git configs, legacy remote files, embedded/target repo configs (container-writable)] → [_snap_config / _snap_gitdir → _snap_url, _snap_rule (_snap_key byte cap, dedupe)] → [insteadOf worklist queues]
B2: [your global/system config + its includes (host-owned)]                                        → [_snap_host_config → _snap_rule, _snap_url]                               → [insteadOf worklist queues]
B3: [queued URL × queued rule]                                                                      → [_snap_pairs_ok, _snap_match (LC_ALL=C prefix test, per-hit target cap)]   → [_snap_hit_t / _snap_hit_b]
B4: [rewritten target string]                                                                       → [_snap_walk_hits (t: dedupe) → _snap_remote (scheme/ssh test, base join)] → [git dir walked, records]
B5: [snapshot success or failure]                                                                   → [git_exec_snapshot rc → git_exit_scan / launcher]                          → [exit 0/1/2/4, launch refused]
```

| Label | Source | Mutability | Trust (per sink) |
|---|---|---|---|
| S1 | repo config entries (`remote.*.url`/`pushurl`, `url.*.insteadOf`/`pushInsteadOf`, names) in any config the scan reads inside the checkout | runtime-mutable (the session writes it) | UNTRUSTED for path construction and walk decisions, and for cost (stall). A change is itself a finding (C/F records), so a bypass needs a launch-time config plus a plant at a path the scan does not compute |
| S2 | your global/system config | deploy-time for the session (the container cannot write it) | trusted not to be hostile; still feeds path construction, so a rule there can point into the checkout (S1-equivalent target) |
| S3 | filesystem state at rewritten targets (planted repos, hooks) | runtime-mutable | UNTRUSTED for everything; this is what the scan must record |
| S4 | caps `GIT_EXIT_SCAN_MAX_REWRITE_*` | code-constant | trusted |

The diff changes how untrusted strings from S1/S2 are keyed, capped and batched before they become walked paths (B1→B3→B4). It does not change `_snap_remote` (B4's path resolution) or the remote-name table.

## Iteration-2 fixes: verification

| Claim | Result |
|---|---|
| 1. `_snap_key` gives collision-free byte keys in any locale; the length check fails closed | **Holds.** e2 under `LC_ALL=C.utf8`: `("a\xc3","\xa9b")` and `("a\xc3\xa9","b")` get different keys; ten keys made of subscript metacharacters (`]`, `\`, `*`, `@`, `$(…)`, backticks, quotes) take ten distinct slots; the caller's locale is back to UTF-8 after the call. Boundary: 4,096 ASCII bytes pass, 4,097 fail, and 2,049 two-byte characters (4,098 bytes) fail as the first or the second argument, so the cap counts bytes. The key is `${#a}:$a$b`, and knowing a's byte length splits the key back into a and b, so it is injective; the `u:`/`r:`/`t:` prefixes keep the namespaces apart and stop any key being exactly `@` or `*`. Fail-closed path: `_snap_url`/`_snap_rule` return 1, and every caller now propagates it (`_snap_config:514,521`, `_snap_host_config:616-617`, legacy lines `731,734`, names loop `840`). The launcher refuses on snapshot failure (`cc-isolated.sh:859`). Bats test 13 checks exit 2. **Is 4,096 safe for real configs?** Yes: the longest real URLs (https with an embedded token, around 200 bytes) are far below it. Note that the check also applies to `<b>`, the working-tree path, so an embedded repo whose path is longer than 4,096 bytes fails the scan. That direction is fail-closed. |
| 2. Per-hit target cap bounds memory; `_snap_walk_hits` dedupes and walks; `&& … || rc=1` fails closed; each pair compared once | **Holds.** The cap check (`:449`) runs before each append, so at most `MAX_REWRITE_TARGETS` strings of at most about 8 KiB each (base and rest are each ≤ 4,096 bytes) exist at once. `_snap_match` returns non-zero only through the cap branch. In every other case its last command is the index-step `if`, which returns 0. A failure in either function sets `rc=1` and ends the loop (`:845,851`). Pair accounting is unchanged from e4b29291: each URL meets rules `0..r-1` and each rule meets URLs `0..u-1`. e3 measured the worst-case comparison pass at the pair cap (100,000 pairs, all strings 4,096 bytes sharing 4,095): **5 s**. That is bounded (it was ~20 min with 1 MiB URLs before the byte cap). The target cap counts matched pairs, not distinct targets: Finding 3. |
| 3. 013f1b3d restores main's `_snap_rnames` behaviour exactly | **Holds.** In `git diff main...013f1b3d` the `_snap_rnames` lines (`:512`, `:724`) match main. The only change around them is that names and legacy URLs now go through `_snap_url` instead of `_snap_remote`, which adds the `u:` dedupe, the byte cap and queueing for the rules. It adds no new skip: `_snap_url` calls `_snap_remote` on every first sighting of a (URL, working tree) pair. |
| 4. Guide/header/plan/commit text matches the code | **Mostly.** Findings 1–4 below. The caps sentence (guide `:348-351`) and the header's FAIL CLOSED paragraph (`:96-99`) match the code. |
| 5. Remaining push-to-a-controlled-repo route inside the insteadOf pass | **None found.** Candidates are below. Every candidate I tested is either covered or matches git. |

## Findings

#### 1. Guide's "about 30 s" at the insteadOf caps understates the planted-target case about threefold on this container

**Severity:** Low
**Location:** `guides/cc-isolated-usage.md:418-419`
**Boundary:** B3, B4
**Move:** 8 (a million of these)
**Confidence:** High (timed, e4). The absolute figures depend on the host's fork cost.
**Legibility-target:** the guide's "A slow scan" bullet (the user decides whether to wait or abort from it)

Evidence:
```
  take a long time; at the `insteadOf` caps, rewritten URLs alone add about
  30 s. If you stop it, treat the checkout as unscanned.
```
e4 used one URL and 1,999 launch-time rules, each rewriting to a distinct target in the checkout:
```
N=1999, nothing planted: 17 s
N=1999, every target a planted bare repo: 90 s, records 20003
```
The session controls whether the targets exist at exit, so the attack case is the planted one: about 36 ms per target git dir, consistent with the guide's own "about 29 ms more for each embedded repository". 1,999 × 29 ms ≈ 58 s, plus the base and target walks. Bounded behaviour is not affected. The scan still finishes or fails. Only the user-facing estimate is off.

**Recommendation:** State the attack-case figure ("up to about 1–2 min when the session plants a repository at each rewritten URL"), or tie it to the per-repository figure the bullet already gives.

#### 2. Two comments still name the removed `_snap_rewrite`

**Severity:** Informational
**Location:** `devcontainer-config/cc-exit-scan.sh:518`, `:831`
**Boundary:** Internal — no boundary (comment drift in an enforcement file; a maintainer following the name finds no function)
**Move:** 2 (implicit assumption, via stale pointers)
**Confidence:** High (grep)
**Legibility-target:** code comments for the next maintainer of the scan

Evidence:
```
        # here, every URL it rewrites in git_exec_snapshot (_snap_rewrite).
  # every URL meets every insteadOf rule (_snap_rewrite). Walking one can reach
```
4d7f966c deleted `_snap_rewrite`. Its work is now split between `_snap_match` and `_snap_walk_hits`.

**Recommendation:** Point both comments at `_snap_match` / `_snap_walk_hits`.

#### 3. The target cap counts matched (URL, rule) pairs, not distinct "URL and working tree" targets as the guide and commit say

**Severity:** Informational (fail-closed direction)
**Location:** `devcontainer-config/cc-exit-scan.sh:449,465`; `guides/cc-isolated-usage.md:349-350`
**Boundary:** B3
**Move:** 3 (error path) / doc accuracy
**Confidence:** High (experiment e5)
**Legibility-target:** the guide's caps sentence, so the user can tell when a benign config hits the cap

Evidence:
```
      if [ $((_snap_rwt + ${#_snap_hit_t[@]})) -ge "$GIT_EXIT_SCAN_MAX_REWRITE_TARGETS" ]; then
    _snap_rwt=$((_snap_rwt + 1))
    _snap_key "${_snap_hit_t[h]}" "${_snap_hit_b[h]}"
    [ -z "${_snap_rwseen["t:$_snap_k"]:-}" ] || continue
```
Guide: "more than 2,000 rewritten URLs to walk (one per URL and working tree)". e5 used one URL and two rules that rewrite it to the same target `Bx`, with the cap set to 1:
```
more than 1 URLs rewritten by insteadOf rules to walk (1 URLs, 2 rules so far): too many, treat the checkout as unsafe
_snap_match rc=1 hits=Bx
```
The count is taken before the `t:` dedupe, so duplicate targets count. This errs toward refusing, which is safe, but the documented unit is wrong.

**Recommendation:** Say "2,000 URL-and-rule matches" in the guide and in the message, or count only after the `t:` dedupe. Counting after the dedupe would bound the walks rather than the strings, and the per-hit check that bounds memory would then need its own count.

#### 4. The new known-route bullet omits two members of the split-out family

**Severity:** Informational
**Location:** `guides/cc-isolated-usage.md:420-425`
**Boundary:** B1, B4
**Move:** 5 (what does it not cover)
**Confidence:** Medium. Both shapes were confirmed in the p2 security report (Findings 2 and 6). I did not re-run them here.
**Legibility-target:** the guide's "Known routes it does not see" list, which is the one place LIMITS points to

Evidence:
```
  git does: a remote with no `url` (git pushes to its name), an empty
  `branches` file, a name defined in another repo of the checkout, untrimmed
  spaces or a CR in a legacy URL, and `file://host/` or percent-encoded
  `file://` URLs can each name a path the scan does not walk (if present at launch).
```
013f1b3d's own message lists "a '/' in a legacy name" as part of the family, and the guide does not. Also missing is the opposite trim case from p2 Finding 6: the `[:space:]` strip on `:734` runs in the caller's locale, so under UTF-8 it removes leading non-ASCII spaces that git keeps. The bullet presents its list as the family's members, so a reader takes the two missing shapes as covered.

**Recommendation:** Add "a legacy file whose name holds a `/`" and "leading spaces trimmed differently" (or just "spaces or a CR trimmed differently from git"), or make the list explicitly non-exhaustive.

## Untested bypass candidates

- **`file://<host>/…` as a rewrite base** (for example `url.file://h/<ws>/.insteadOf`). Git takes the path from the first `/` after the host, and `_snap_remote` strips `file://` literally. Not re-tested because it is the split-out family, which is listed in the guide and was confirmed in p2 Finding 5. This diff does not make it worse than main: main walked no rewritten target at all.
- **A name defined in a rewritten target's config, hiding the checkout's push to that name as a path.** Rewritten targets are new configs feeding the shared `_snap_rnames` table, so they are one more instance of the "name defined in another repo of the checkout" known route. Not tested: it needs launch-time state, and an embedded repo already gives the same effect on main, so the diff does not materially widen it.
- **Fork stall from many rule bases with zero URLs** (pairs = 0, so the pair cap never trips; each base is walked by `_snap_remote`, 2 `realpath` forks). Pre-existing: main walks every base the same way. Override-log row 134 already defers this ("scan cost grows with entries; fail-closed by design"). Not timed.

## Tested bypass candidates (no finding)

| Candidate | How | Result |
|---|---|---|
| Rewritten target holding `://` after a non-scheme character (`sub/a:` + `//example.invalid/x`), which the scan skips via `*://*` | e1a, plus e1b with the URL literally `sub/b://y`; real `git push` against a bare repo planted at the local reading | Scan: no finding. But git 2.39.5 refuses it too: `fatal: protocol 'sub/a' is not supported` (connect.c takes everything before `://` as the protocol whatever its characters), and the hook did not run. The scan's test matches git, so this is not a route. |
| Byte-split UTF-8 dedupe collision (iteration-2 Finding 1) | e2, plus bats test 12 | Closed |
| Huge URL or value stalling each comparison | e2 boundary, e3 timing | 4,096-byte cap; worst-case comparison pass 5 s |
| Memory blow-up in one batch | read `:449` | Bounded per hit |
| Assoc-array subscript metacharacters aliasing two keys (`]`, `\`, `*`, `@`, `$(…)`) | e2 | 10 keys, 10 slots |
| `_snap_match` failing silently (non-zero with no reason, or zero on cap) | read whole function | Only the cap branch returns 1, and it prints a reason first |
| Rule shapes: empty value (matches all), value-less boolean `insteadOf`, `.insteadof` inside the base, legacy `[url.X]` syntax | read `:516-522,616`, `git config --list` semantics | Superset of git's: an empty value matches everything, the last `.` segment is stripped correctly, and git lowercases the legacy subsection before `--list` |
| pushInsteadOf vs insteadOf precedence, longest-match | read | The scan walks every match, a superset of git's choice (bats test 3) |

## Endorsement Claims

- **Claim:** `_snap_key` keys are injective byte strings under `LC_ALL=C.utf8`, and the 4,096 check counts bytes for both arguments.
  **Location:** `devcontainer-config/cc-exit-scan.sh:401-408`
  **Evidence:** executed
  **Verified:** e2: the split-UTF-8 pair, 10 metacharacter keys, the 4,096/4,097 ASCII boundary, and 4,098 bytes in 2,049 characters as either argument.
  **Not verified:** a host bash other than 5.2 (the container's).
  **route: code-fact-check**
- **Claim:** At the pair cap with maximum-length strings, the comparison pass takes about 5 s in this container.
  **Location:** `devcontainer-config/cc-exit-scan.sh:444-458`
  **Evidence:** executed
  **Verified:** e3, `_snap_pairs_ok`/`_snap_match` called directly on the worst-case arrays.
  **Not verified:** the full `git_exec_snapshot` path, where parsing a config holding 4,000 rules of 4 KiB each comes on top.
- **Claim:** 013f1b3d leaves `_snap_rnames` marking exactly as on main.
  **Location:** `devcontainer-config/cc-exit-scan.sh:510-512,723-724`
  **Evidence:** read-static
  **Verified:** `git diff main...013f1b3d` shows no change on those lines.
  **Not verified:** the stacked branch `fix/q096b-exit-scan-remote-names`.
  **route: code-fact-check**

## Primitive sweep

Primitive: path construction from container strings → `_snap_remote` walk (filesystem traversal decision)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `cc-exit-scan.sh:417` `_snap_url` → `_snap_remote` | S1, S2 | `u:` key, byte cap | cleared for keying. The `file://host` resolution is the split family (listed) |
| `cc-exit-scan.sh:469` `_snap_walk_hits` → `_snap_remote` | S1, S2 | `t:` key, per-hit target cap | cleared. `://` matches git (e1). Cost: Finding 1 |
| `cc-exit-scan.sh:522` rule base → `_snap_remote` | S1 | byte cap (via `_snap_rule` before it) | cleared. Base-count stall is pre-existing (untested list) |
| `cc-exit-scan.sh:840` undefined name → `_snap_url` | S1 | `_snap_rnames` (main's rule) | split family, unchanged from main |
| `cc-exit-scan.sh:731,734` legacy URL → `_snap_url` | S1 | byte cap | split family. Guide wording: Finding 4 |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Guide's "about 30 s" at the caps understates the planted-target case (~90 s measured) | Low | B3, B4 | guide `:418-419` | High (timed) |
| 2 | Comments still name the removed `_snap_rewrite` | Informational | Internal | `cc-exit-scan.sh:518,831` | High |
| 3 | Target cap counts matched pairs, not distinct targets as documented (fail-closed) | Informational | B3 | `cc-exit-scan.sh:449,465`; guide `:349-350` | High (exp.) |
| 4 | Known-route bullet omits the `/`-in-legacy-name and trim-differently members | Informational | B1, B4 | guide `:420-425` | Medium |

## Overall Assessment

The iteration-2 fixes hold. Keys are counted in bytes and are injective in any locale. The 4,096-byte cap fails closed, and every caller propagates the failure up to the launcher's refusal. The per-hit target check bounds memory. `_snap_match && _snap_walk_hits || rc=1` fails closed on either failure. Measured with the caps in place, the worst-case insteadOf comparison pass is 5 s and the worst-case target walk about 90 s, both bounded. 013f1b3d restores main's remote-name rule exactly and makes no part of the split-out family worse than main. I found no remaining way within the insteadOf pass for a session to make host git push to a repository it controls without a finding: the one new candidate (`://` in a local-looking target) is refused by git as well. All four findings are about documentation and comments; the code stands as is. The most useful fix is the guide's timing figure (Finding 1), which is what a user reads when deciding whether to wait for the scan. Finding 4 keeps the known-route list complete while the remote-name family is fixed on its own branch.

## Goal-Alignment Note

The user's goal is to land Q-096: the exit scan must walk the URL an insteadOf/pushInsteadOf rule rewrites a remote to, so a session cannot repoint a push through an ignored rewrite. This pass found the mechanism intact and its iteration-2 hardening effective, and no finding blocks the goal. The four findings are wording fixes, small enough to fold into the next commit without another code round. The split-out remote-name family stays a listed known route until `fix/q096b-exit-scan-remote-names` lands. The guide entry for it should list every member (Finding 4) until then.
