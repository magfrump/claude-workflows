Commit: e4b29291

# API Consistency Review — fix/q096-exit-scan-insteadof-target, iteration 2 (5f754994..e4b29291)

**Scope:** `git diff 5f754994..e4b29291 -- . ':!docs/reviews'` (cc-exit-scan.sh, guides/cc-isolated-usage.md, test/cc-isolated-functions.bats, the plan); 5f754994 as context only
**Date:** 2026-10-15
**Based on:** shared brief `shared-brief-p2.md`; iteration-1 rubric `docs/reviews/code-review-rubric-2026-10-15-q096-exit-scan-insteadof-target.md` (context)

> ⚠️ **No code fact-check report provided.** API documentation claims have not been
> independently verified against implementation. For full verification, run the
> `code-fact-check` skill first or use the code-review orchestrator.

The "public surface" of this unit is: the tunable constants `GIT_EXIT_SCAN_MAX_*` (the bats suite overrides them after sourcing), the `_snap_fail` reason strings (printed to the user at launch and exit), the exit statuses (snapshot 1, `git_exit_scan` 2, launcher refusal 1 / exit-scan 4), the guide's statements, and the bats test names (`bats -f` filters on them).

## Baseline Conventions

- **Caps:** `GIT_EXIT_SCAN_MAX_<SCOPE>_<UNIT>` assigned unconditionally at source time, overridden only by tests after sourcing (`devcontainer-config/cc-exit-scan.sh:201-202`: `GIT_EXIT_SCAN_MAX_FILE_BYTES`, `GIT_EXIT_SCAN_MAX_TOTAL_BYTES`; `test/cc-isolated-functions.bats:2573` sets `GIT_EXIT_SCAN_MAX_TOTAL_BYTES=100`). Each has a block comment above naming the checking helper.
- **Cap checkers:** one helper per cap family, a predicate named `_snap_<thing>_ok` (`_snap_size_ok`, `:203`), which adds to a counter declared in `git_exec_snapshot` (`_snap_bytes`) and calls `_snap_fail` then returns 1.
- **Cap failure messages:** `'<what> (<context>): <why>, treat the checkout as unsafe'` — `'%s is too large to hash (%s bytes, over %s): treat the checkout as unsafe'` (`:207`), `'more than %s bytes to hash (at %s): too much to hash, treat the checkout as unsafe'` (`:213`), `'%s is too large to read (%s bytes, over %s): …'` (`:228`). Every cap message names what it was at (the file, or the file at which the total tripped).
- **Exit statuses:** snapshot helpers return 1; `git_exit_scan` returns 2 when the snapshot fails (`return 2` after the failed `git_exec_snapshot`); the launcher refuses with `exit 1` (`cc-isolated.sh:867`); the guide documents the user-visible exit 4 at exit and exit 1 at launch (`guides/cc-isolated-usage.md:347`, `:422`).
- **Helper naming:** mixed nouns ("record X": `_snap_hooks`, `_snap_remote`, `_snap_url`, `_snap_rule`, `_snap_config`, `_snap_gitdir`) and verbs (`_snap_find`, `_snap_hash`, `_snap_fail`, `_snap_rewrite`).
- **Shared-locals header:** `cc-exit-scan.sh:158-163` lists every dynamically scoped local the `_snap_*` helpers share.
- **Test names:** `"exit scan <unit-tag>: <behaviour>"`, where the tag is the unit (Q-094, Q-096, N3, …) and bare `"exit scan:"` is used for generic scan behaviour (17 tests).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `GIT_EXIT_SCAN_MAX_REWRITE_PAIRS` | constant (cap) | `GIT_EXIT_SCAN_MAX_FILE_BYTES`, `GIT_EXIT_SCAN_MAX_TOTAL_BYTES`, `GIT_EXIT_SCAN_MAX_REWRITES` (5f754994) | `devcontainer-config/cc-exit-scan.sh:201-202` | Consistent — `MAX_<scope>_<unit>`; the rename from `_REWRITES` is branch-internal (never on main), so not breaking |
| `GIT_EXIT_SCAN_MAX_REWRITE_TARGETS` | constant (cap) | same | `cc-exit-scan.sh:201-202` | Consistent |
| `_snap_pairs` | function (cap checker) | `_snap_size_ok` | `cc-exit-scan.sh:203` | Minor — the one existing cap checker is an `_ok` predicate; this one is a bare noun (Finding 3) |
| `_snap_match` | function | `_snap_rewrite`, `_snap_find`, `_snap_hash` | `cc-exit-scan.sh:186,288,455` | Consistent — verb helpers exist |
| `_snap_walk_hits` | function | `_snap_rewrite`, `_snap_hooks` | `cc-exit-scan.sh:325,455` | Consistent (verb_noun is new but readable) |
| `_snap_rwt` | counter local | `_snap_rwn`, `_snap_bytes` | `cc-exit-scan.sh:781` | Informational — follows `_snap_rwn`; `_snap_bytes` is the descriptive precedent |
| `_snap_hit_t` / `_snap_hit_b` | shared array locals | `_snap_urls`/`_snap_ubases`, `_snap_rbases`/`_snap_rpfx` | `cc-exit-scan.sh:784` | Consistent naming; missing from the shared-locals header (Finding 2) |
| test `"exit scan: under a UTF-8 locale a name ending mid-character does not hide the next entry"` | test name | `"exit scan Q-096: …"` (12), `"exit scan: …"` (17) | `test/cc-isolated-functions.bats:1406-1514`, `:2213-2300` | Informational (Finding 5) |
| test `"exit scan Q-096: past either insteadOf cap, the exit scan fails as unsafe"` | test name | `"exit scan size cap: …"` | `test/cc-isolated-functions.bats` (`exit scan size cap`, 3 tests) | Consistent |

## Findings

#### 1. The target-cap message carries no context, unlike the pair-cap message beside it and the existing total-bytes message

**Severity:** Minor
**Location:** `devcontainer-config/cc-exit-scan.sh:460-463`
**Move:** 4 (error consistency)
**Confidence:** High
**Legibility-target:** a user reading the launch refusal / exit-4 warning, deciding which planted entry to look at
**Evidence:**
```
    _snap_fail 'more than %s distinct URLs rewritten by insteadOf rules to walk: too many, treat the checkout as unsafe' \
      "$GIT_EXIT_SCAN_MAX_REWRITE_TARGETS"
```
versus the sibling cap in the same commit (`:422-423`)
```
  _snap_fail 'more than %s remote URL and insteadOf rule pairs to compare (%s URLs, %s rules so far): too many, treat the checkout as unsafe' \
    "$GIT_EXIT_SCAN_MAX_REWRITE_PAIRS" "${#_snap_urls[@]}" "${#_snap_rbases[@]}"
```
and the established cap message (`:213-214`)
```
    _snap_fail 'more than %s bytes to hash (at %s): too much to hash, treat the checkout as unsafe' \
      "$GIT_EXIT_SCAN_MAX_TOTAL_BYTES" "$1"
```

Every other cap message names where it tripped (`(at %s)`, `(%s bytes, over %s)`, `(%s URLs, %s rules so far)`); the target cap's message alone gives only the number. The URL being walked (`$1`), or the URL/rule counts, are in scope at that line. The rewritten URL is container-chosen, but `_snap_fail` already reduces it to printable ASCII, as it does for every path it prints.

**Recommendation:** Add context in the established form, e.g. `'more than %s distinct URLs rewritten by insteadOf rules to walk (at %s): too many, …'` with `"$1"`, or the `(%s URLs, %s rules so far)` counts to match the pair-cap message.

#### 2. The shared-locals header lists the insteadOf queues but omits the new `_snap_hit_t` / `_snap_hit_b`

**Severity:** Minor
**Location:** `devcontainer-config/cc-exit-scan.sh:158-163` (header) vs `:784` (declaration), `:433-452` (users)
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** a maintainer adding a `_snap_*` helper (Q-097 follows on this file) who relies on the header to know which names are taken
**Evidence:**
```
# and the insteadOf pass's queues (_snap_urls/_snap_ubases, _snap_rbases/
# _snap_rpfx, _snap_rwseen, the _snap_rwn/_snap_rwt counters). Each
```
```
  local -a _snap_hit_t=() _snap_hit_b=()
```

The header was updated in this very commit to enumerate the pass's shared locals, and `_snap_hit_t`/`_snap_hit_b` are dynamically scoped arrays written by `_snap_match` and read by `_snap_walk_hits`, exactly the class the header documents. A helper that later reused either name as its own global would corrupt a batch silently.

**Recommendation:** Add "the _snap_hit_t/_snap_hit_b batch of matches" to the list.

#### 3. `_snap_pairs` is a cap checker named unlike the existing one

**Severity:** Minor
**Location:** `devcontainer-config/cc-exit-scan.sh:418-424`
**Move:** 2 (naming against the grain)
**Confidence:** Medium
**Legibility-target:** a reader of the worklist at `:843` (`_snap_pairs "$r" || { rc=1; break; }`) who must infer that this can fail the snapshot
Precedent: cap-checking predicate `_snap_size_ok` (adds to `_snap_bytes`, `_snap_fail`s past `GIT_EXIT_SCAN_MAX_*`) used in `devcontainer-config/cc-exit-scan.sh:203-218`
**Evidence:**
```
# _snap_pairs <n>: count <n> more comparisons against the pair cap.
_snap_pairs() {
  _snap_rwn=$((_snap_rwn + $1))
  [ "$_snap_rwn" -gt "$GIT_EXIT_SCAN_MAX_REWRITE_PAIRS" ] || return 0
  _snap_fail 'more than %s remote URL and insteadOf rule pairs to compare (%s URLs, %s rules so far): too many, treat the checkout as unsafe' \
    "$GIT_EXIT_SCAN_MAX_REWRITE_PAIRS" "${#_snap_urls[@]}" "${#_snap_rbases[@]}"
}
```

`_snap_size_ok` and `_snap_pairs` do the same job (charge a counter, fail closed past a `GIT_EXIT_SCAN_MAX_*`), but one reads as a predicate and the other as a noun like the record-writing helpers (`_snap_url`, `_snap_rule`, `_snap_hooks`). The target cap, by contrast, is inlined in `_snap_rewrite` rather than in a checker, so the two caps of one pass are enforced in two different shapes.

**Recommendation:** Rename to `_snap_pairs_ok` (or `_snap_pair_budget_ok`); optionally move the target check into a matching `_snap_targets_ok` so both caps share one shape.

#### 4. The guide's "A slow scan" route says nothing about the insteadOf pass, though the commit message points to it for long values

**Severity:** Minor
**Location:** `guides/cc-isolated-usage.md:413-418`; commit message e4b29291
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** a user whose exit scan takes minutes, looking for the documented cause
**Evidence:** commit body:
```
counts every distinct rewritten URL, local or not. Long values still slow
each comparison: the guide's "A slow scan" route.
```
guide (unchanged on the branch: `git diff main...HEAD -- guides/cc-isolated-usage.md` has no hunk in this bullet):
```
- **A slow scan.** The cost is forks per git dir, not I/O: about 2–4 s per
  snapshot on a ~400k-file repository, and about 29 ms more for each embedded
  repository (the tree walk itself is ~0.05 s per 100k files), paid at launch
  and again at exit. Hashing is capped (64 MiB a file, 1 GiB in all), but a
  session can still plant many files or embedded repos to make the exit scan
  take a long time. If you stop it, treat the checkout as unscanned.
```

The commit claims the long-value cost is a documented route; the bullet names files, embedded repos and hashing, not URLs, rules, or rewritten-URL walks, and says the insteadOf caps nowhere. The companion performance report (same pass) measures that the pass can still cost ~30 s at the 2,000-target cap and far more with long values inside both caps, so the route is real and undocumented.

**Recommendation:** Add a sentence to "A slow scan": the insteadOf pass is capped by count (100,000 comparisons, 2,000 rewritten URLs), not by length, so many or long remote URLs and rules can still slow it.

#### 5. A test added for this unit is not reachable by the unit's `-f 'Q-096'` filter

**Severity:** Informational
**Location:** `test/cc-isolated-functions.bats` (test "exit scan: under a UTF-8 locale a name ending mid-character does not hide the next entry")
**Move:** 2 (naming against the grain)
**Confidence:** Medium
**Legibility-target:** a reviewer or later loop running `bats test/cc-isolated-functions.bats -f 'Q-096'` (the filter the review brief names for the unit's tests)
Precedent: unit-tagged test names `"exit scan Q-096: …"` used in `test/cc-isolated-functions.bats:2213-2300`; generic `"exit scan: …"` used in `test/cc-isolated-functions.bats:1406-1514`
**Evidence:**
```
@test "exit scan: under a UTF-8 locale a name ending mid-character does not hide the next entry" {
```

The read fix (B25) is pre-existing scan behaviour, so the generic `"exit scan:"` tag is defensible on the precedent; the cost is that the unit's filtered run silently skips the test that guards the commit's largest change (every `read` in the file). The other new tests all carry `Q-096`.

**Recommendation:** Either tag it (`"exit scan Q-096 (B25): …"`) or note in the plan's verification line that the Q-096 filter excludes it.

## What Looks Good

- Both caps follow `GIT_EXIT_SCAN_MAX_<SCOPE>_<UNIT>` and sit in one commented block naming their checkers, like the hashing caps. The rename from `GIT_EXIT_SCAN_MAX_REWRITES` never reached main (`git diff main...5f754994` introduced it), so nothing outside the branch breaks.
- Both messages end `: too many, treat the checkout as unsafe`, matching the house ending, and go through `_snap_fail` (printable-ASCII reduction).
- Exit statuses are consistent end to end: the cap test now goes through `git_exit_scan` and asserts `status 2`, the launcher's existing `exit 1` path covers a snapshot failure, and the guide's new sentence ("At launch any of these refuses the launch instead, exit 1") matches `cc-isolated.sh:859-867` for every cap it lists.
- The guide moved the cap statement out of the routes paragraph into the fail-closed list beside the hashing caps, where a reader looks for limits.
- The new "A URL you type" known-route bullet follows the existing bullet shape (bold lead, cause, what the scan sees).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Target-cap message has no context, unlike the pair-cap and total-bytes messages | Minor | `cc-exit-scan.sh:460-463` | High |
| 2 | Shared-locals header omits `_snap_hit_t`/`_snap_hit_b` | Minor | `cc-exit-scan.sh:158-163` | High |
| 3 | `_snap_pairs` cap checker named unlike `_snap_size_ok`; target cap inlined instead | Minor | `cc-exit-scan.sh:418-424` | Medium |
| 4 | "A slow scan" guide route does not mention the insteadOf pass, though the commit points there | Minor | `guides/cc-isolated-usage.md:413-418` | High |
| 5 | UTF-8 read test is outside the `-f 'Q-096'` filter | Informational | `test/cc-isolated-functions.bats` | Medium |

## Overall Assessment

The iteration-1 fixes are consistent with the file's conventions where it matters most: cap names, message endings, exit statuses and the guide's fail-closed list all line up, and no consumer outside the branch is affected by the rename. The five findings are small, fixable in place, and all about legibility: one cap message without context, one header list missing two names, one checker shape that differs from `_snap_size_ok`, a guide route the commit message cites but the guide does not hold, and one test outside the unit's filter. Finding 4 is the one a user would actually hit.

## Goal-Alignment Note

Success criterion: "Two markdown reports saved under docs/reviews/ per the performance-reviewer and api-consistency-reviewer skills, first line Commit: e4b29291." This is the api-consistency report, saved under `docs/reviews/` with first line `Commit: e4b29291`, following the skill's structure (baseline, required name-pattern audit, findings with precedent lines for naming findings, What Looks Good, summary, assessment). The review stays inside the partial scope (5f754994..e4b29291), using 5f754994 and main only to establish that the cap rename is branch-internal. For the user goal (land Q-096), nothing here blocks: findings are Minor/Informational legibility fixes; Finding 4 links to the performance report's measured cost so the guide can state it.
