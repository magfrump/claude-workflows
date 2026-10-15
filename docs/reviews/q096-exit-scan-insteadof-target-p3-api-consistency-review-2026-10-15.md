Commit: 013f1b3d

# API Consistency Review — fix/q096-exit-scan-insteadof-target, iteration 3 (e4b29291..013f1b3d)

**Scope:** `git diff e4b29291..013f1b3d -- . ':!docs/reviews'` (cc-exit-scan.sh, guides/cc-isolated-usage.md, test/cc-isolated-functions.bats, the plan; commits 4d7f966c and 013f1b3d); 5f754994, e4b29291 and main as context only
**Date:** 2026-10-15
**Based on:** shared brief `shared-brief-p3.md`; prior report `q096-exit-scan-insteadof-target-p2-api-consistency-review-2026-10-15.md`; sibling report `q096-exit-scan-insteadof-target-p3-performance-review-2026-10-15.md` (probes `p7.sh` in `probe-performance-p3/`)

> ⚠️ **No code fact-check report provided.** API documentation claims have not been
> independently verified against implementation. For full verification, run the
> `code-fact-check` skill first or use the code-review orchestrator.

This unit's public surface: the tunable `GIT_EXIT_SCAN_MAX_*` constants (overridden by the bats suite after sourcing), the `_snap_fail` reason strings (shown to the user at launch refusal and at exit 4), the exit statuses (snapshot 1, `git_exit_scan` 2, launcher 1, exit scan 4), the guide's statements (the user's contract for what a clean scan means), helper names and the shared-locals header (the contract for Q-097, which follows on this file), and bats test names (`-f 'Q-096'`).

## Baseline Conventions

- **Caps:** `GIT_EXIT_SCAN_MAX_<SCOPE>_<UNIT>`, assigned at source time, with a comment block naming the checker. Per-item caps name the item (`GIT_EXIT_SCAN_MAX_FILE_BYTES`, one file); aggregates say so (`GIT_EXIT_SCAN_MAX_TOTAL_BYTES`) (`devcontainer-config/cc-exit-scan.sh:201-202`). The insteadOf pass's existing caps `GIT_EXIT_SCAN_MAX_REWRITE_PAIRS` / `_TARGETS` are pass-wide totals (`:395-396`).
- **Cap checkers:** a predicate `_snap_<thing>_ok` that charges a counter and `_snap_fail`s (`_snap_size_ok`, `:203`; now `_snap_pairs_ok`, `:430`).
- **Cap messages:** `'<what> (<where/how much>): <why>, treat the checkout as unsafe'`; every existing cap message names where it tripped or by how much: `'%s is too large to hash (%s bytes, over %s): …'` (`:207`), `'more than %s bytes to hash (at %s): …'` (`:213`), `'%s is too large to read (%s bytes, over %s): …'` (`:228`), and since p2's fix both insteadOf count caps carry `(%s URLs, %s rules so far)` (`:433`, `:450`).
- **Exit statuses:** snapshot helpers return 1; `git_exit_scan` 2; launcher refusal exit 1; guide documents exit 4 at exit and 1 at launch.
- **Comments name live helpers:** the file cross-references helpers by name in parentheses (`(_snap_key, _snap_pairs_ok, _snap_match)`, `:98-99`; `(_snap_match)`, `:411`).
- **Known-route bullets** in the guide: bold lead naming the route, then cause, then what the scan does or does not see (`guides/cc-isolated-usage.md:413-461`, e.g. "**`~` forms.**", "**A URL you type.**").
- **Test names:** `"exit scan <unit tag>: <behaviour>"`.

## Prior (p2) findings

- p2 F1 (target-cap message without context): **addressed** — `(%s URLs, %s rules so far)` at `:450`.
- p2 F2 (header omits `_snap_hit_t`/`_snap_hit_b`): **addressed** — `:162`, plus `_snap_k`.
- p2 F3 (`_snap_pairs` named unlike `_snap_size_ok`): **addressed** — renamed `_snap_pairs_ok`; the target check moved into `_snap_match`, named in the cap comment (`:390-393`).
- p2 F4 ("A slow scan" silent on the pass): **addressed** — `guides/cc-isolated-usage.md:418-419`.
- p2 F5 (UTF-8 read test outside `-f 'Q-096'`): **addressed** — renamed; `bats -f 'Q-096'` runs 13/13 ok, including it.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `GIT_EXIT_SCAN_MAX_REWRITE_BYTES` | constant (cap) | `GIT_EXIT_SCAN_MAX_FILE_BYTES` (per item), `GIT_EXIT_SCAN_MAX_TOTAL_BYTES` (aggregate), `GIT_EXIT_SCAN_MAX_REWRITE_PAIRS` (pass total) | `devcontainer-config/cc-exit-scan.sh:201-202, 395-396` | Minor — per-string cap whose name reads like a pass total beside its two siblings (Finding 5) |
| `_snap_key` | function | `_snap_hash`, `_snap_path`, `_snap_size_ok` | `cc-exit-scan.sh:186, 297, 203` | Consistent as a noun-named builder; it also carries the byte-cap check via a `check` flag, which no other helper does by flag (noted under What Looks Good) |
| `_snap_k` | shared out-variable | `_snap_linkdir` (out-variable set by `_snap_file`) | `cc-exit-scan.sh:238-239, 780` | Consistent; listed in the shared-locals header |
| `_snap_pairs_ok` (rename of `_snap_pairs`) | function (cap checker) | `_snap_size_ok` | `cc-exit-scan.sh:203` | Consistent; branch-internal rename, no consumer outside the branch |
| message `'a remote URL or insteadOf rule over %s bytes: too long to compare, …'` | error string | the five cap messages above | `cc-exit-scan.sh:207, 213, 228, 433, 450` | Minor — only cap message with no location or amount (Finding 2) |
| test `"exit scan Q-096: under a UTF-8 locale rules whose characters, not bytes, line up are kept apart"` | test name | `"exit scan Q-096: the prefix match is byte-wise, as git's, under a UTF-8 locale"` | `test/cc-isolated-functions.bats:2213-2300` | Consistent |
| test `"exit scan Q-096: under a UTF-8 locale a name ending mid-character …"` (retag) | test name | Q-096 tests | same | Consistent |
| guide bullet "**Remote names and legacy remote files, read loosely.**" | doc (known route) | "**`~` forms.**", "**A URL you type.**", "**One unlistable directory blocks the scan.**" | `guides/cc-isolated-usage.md:413-461` | Consistent shape; one clarity note (Finding 7) |

## Findings

#### 1. Two comments still name `_snap_rewrite`, which 4d7f966c deleted

**Severity:** Minor
**Location:** `devcontainer-config/cc-exit-scan.sh:518`, `:831`
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** a maintainer (Q-097 next, on this file) following the parenthesised helper names to the code
**Evidence:**
```
        # url.<base>.insteadOf rewrites matching URLs to <base>: the base alone
        # here, every URL it rewrites in git_exec_snapshot (_snap_rewrite).
```
```
  # Remote names that no remote defines are URLs or paths to git (remote.c), and
  # every URL meets every insteadOf rule (_snap_rewrite). Walking one can reach
```
`grep -rn _snap_rewrite devcontainer-config/ guides/ test/` returns only these two lines; the diff removes the function (`-_snap_rewrite() {`). The file's convention is that a parenthesised name is a live helper (`:98-99`, `:411`); these now point at nothing. The worklist comment's mechanism is now `_snap_match`/`_snap_walk_hits`.

**Recommendation:** Replace both with `(_snap_match, _snap_walk_hits)`.

#### 2. The byte-cap message gives neither the amount nor the place, unlike every other cap message

**Severity:** Minor
**Location:** `devcontainer-config/cc-exit-scan.sh:406-407`
**Move:** 4 (error consistency)
**Confidence:** High
**Legibility-target:** a user whose launch is refused by an over-long value in their OWN global config (`_snap_host_config:617-618` applies the same check), who must find the entry
**Evidence:**
```
  _snap_fail 'a remote URL or insteadOf rule over %s bytes: too long to compare, treat the checkout as unsafe' \
    "$GIT_EXIT_SCAN_MAX_REWRITE_BYTES"
```
versus
```
    _snap_fail '%s is too large to hash (%s bytes, over %s): treat the checkout as unsafe' \
      "$1" "$s" "$GIT_EXIT_SCAN_MAX_FILE_BYTES"
```
and the sibling caps of the same pass, which p2 F1 aligned on `(%s URLs, %s rules so far)` (`:433`, `:450`). This message alone has no length, no counts, and no hint of which config. The value itself is container-chosen and up to 64 MiB, so printing it whole is wrong. A length and a short prefix, both reduced to printable ASCII by `_snap_fail`, are not. At launch this check also runs on the user's own global and system rules and remotes, where the user is the one who has to act.

**Recommendation:** Add the amount in the house form, e.g. `'a remote URL or insteadOf rule over %s bytes (%s bytes, starting %s): …'` with `${#1}`/`${#2}` and the first ~40 bytes, or at least the counts `(%s URLs, %s rules so far)` like its siblings.

#### 3. The guide and commit say the 2,000 cap counts one per URL and working tree; the code counts every match, duplicates included

**Severity:** Minor
**Location:** `guides/cc-isolated-usage.md:349-350`; `devcontainer-config/cc-exit-scan.sh:449`, `:462-471`; commit 4d7f966c body
**Move:** 3 (documentation drift)
**Confidence:** High (probe `p7.sh` B)
**Legibility-target:** a user reading the cap's meaning; the author or a reviewer reasoning about the budget
**Evidence:** guide:
```
4,096 bytes, more than 100,000 URL-and-rule comparisons, or more than 2,000
rewritten URLs to walk (one per URL and working tree). (At launch any of these
```
commit 4d7f966c: `the 2,000 cap counts URL-and-working-tree targets`. Code:
```
  for ((h = 0; h < ${#_snap_hit_t[@]}; h++)); do
    _snap_rwt=$((_snap_rwt + 1))
    _snap_key "${_snap_hit_t[h]}" "${_snap_hit_b[h]}"
    [ -z "${_snap_rwseen["t:$_snap_k"]:-}" ] || continue
```
(loop continues: mark seen, `_snap_remote`, `done`, `}`)

`_snap_rwt` is incremented before the `t:` dedupe, and `_snap_match` (`:449`) checks `_snap_rwt + ${#_snap_hit_t[@]}`, i.e. hits, not distinct (target, working tree) pairs. Probe: URL `abc`, `url.Z.insteadOf=a`, `url.Zb.insteadOf=ab`: one distinct target `Zbc`, but with the cap at 1 the snapshot fails with "more than 1 URLs rewritten by insteadOf rules to walk (1 URLs, 2 rules so far)". The behaviour is safe (it can only fail closed sooner), and the message (which dropped "distinct" in this scope) is accurate. The guide and the commit body describe a different unit.

**Recommendation:** Change the guide's parenthesis to "(one per matching URL and rule)" or drop it. Alternatively move the increment after the dedupe and count distinct targets in `_snap_match` too, though that costs a lookup per hit. The doc change is the cheaper fix.

#### 4. The cap test's name says "either", but it now covers three caps

**Severity:** Informational
**Location:** `test/cc-isolated-functions.bats:2277`
**Move:** 2 (naming against the grain)
**Confidence:** High
**Legibility-target:** someone running `bats -f 'byte'` or `-f 'cap'`, or scanning test names for the byte cap's coverage
Precedent: test names state the behaviour they assert, e.g. `"exit scan size cap: past the total to hash, the scan fails as unsafe"` used in `test/cc-isolated-functions.bats:2556-2568`
**Evidence:**
```
@test "exit scan Q-096: past either insteadOf cap, the exit scan fails as unsafe" {
```
The test's third block (`GIT_EXIT_SCAN_MAX_REWRITE_BYTES=10`, asserting "a remote URL or insteadOf rule over 10 bytes") was added in this scope. "Either" now undercounts, and the name gives no hint that the length cap is tested.

**Recommendation:** "past any insteadOf cap (pairs, targets, bytes), the exit scan fails as unsafe".

#### 5. `GIT_EXIT_SCAN_MAX_REWRITE_BYTES` is a per-string cap whose name matches its pass-total siblings

**Severity:** Minor
**Location:** `devcontainer-config/cc-exit-scan.sh:394-396`
**Move:** 2 (naming against the grain)
**Confidence:** Medium
**Legibility-target:** a maintainer or test author tuning caps by name
Precedent: per-item cap names the item, aggregate says TOTAL: `GIT_EXIT_SCAN_MAX_FILE_BYTES` / `GIT_EXIT_SCAN_MAX_TOTAL_BYTES` used in `devcontainer-config/cc-exit-scan.sh:201-202`
**Evidence:**
```
GIT_EXIT_SCAN_MAX_REWRITE_BYTES=4096
GIT_EXIT_SCAN_MAX_REWRITE_PAIRS=100000
GIT_EXIT_SCAN_MAX_REWRITE_TARGETS=2000
```
`REWRITE_PAIRS` and `REWRITE_TARGETS` count across the whole pass. Read beside them, and beside `TOTAL_BYTES`, `REWRITE_BYTES` suggests total bytes the pass may handle. It is in fact the limit for one URL, rule base or value. The comment above (`:391`, "bytes in one URL, rule base or value") is correct, so this is a naming nit, not a doc error. The name is new on the branch and has no consumers outside it.

**Recommendation:** Optional: `GIT_EXIT_SCAN_MAX_REWRITE_VALUE_BYTES` (or `_URL_BYTES`), matching the `FILE_BYTES` per-item shape. Rename now, before anything outside the branch depends on it.

#### 6. The byte-cap message blames a URL or rule when the over-long string is a working-tree path

**Severity:** Informational
**Location:** `devcontainer-config/cc-exit-scan.sh:401-408`, `:412-413`
**Move:** 4 (error consistency)
**Confidence:** Medium (read from code; not probed)
**Legibility-target:** a user or maintainer diagnosing an exit 4 from an embedded repo deep in the tree
**Evidence:**
```
_snap_url() {
  _snap_key "$1" "$2" check || return 1
```
(function continues: dedupe, queue, `_snap_remote`, `}`)
```
  [ "${#1}" -gt "$GIT_EXIT_SCAN_MAX_REWRITE_BYTES" ] || [ "${#2}" -gt "$GIT_EXIT_SCAN_MAX_REWRITE_BYTES" ] || return 0
```
For `_snap_url`, `$2` is the working tree (from `_snap_worktree_of`, which can come from an embedded repo's `core.worktree`, or a deep embedded-repo path). A string over 4,096 bytes there trips the check with a message naming "a remote URL or insteadOf rule". Failing closed is right; the attribution is not. The `_snap_key` comment says "<a> or <b>", which covers this, but the user-facing text does not.

**Recommendation:** Either check only `$1` for `_snap_url` (the working tree is bounded in practice by the find walk), or reword to "a remote URL, its working tree, or an insteadOf rule over %s bytes".

#### 7. The new known-route bullet's "(if present at launch)" is easy to misread

**Severity:** Informational
**Location:** `guides/cc-isolated-usage.md:420-425`
**Move:** 3 (documentation drift / contract clarity)
**Confidence:** Medium
**Legibility-target:** a user deciding whether a remote they see after a session is covered
**Evidence:**
```
- **Remote names and legacy remote files, read loosely.** The scan resolves a
  remote name and a legacy `.git/remotes`/`.git/branches` URL more simply than
  git does: a remote with no `url` (git pushes to its name), an empty
  `branches` file, a name defined in another repo of the checkout, untrimmed
  spaces or a CR in a legacy URL, and `file://host/` or percent-encoded
  `file://` URLs can each name a path the scan does not walk (if present at launch).
```
The bullet's content matches the code at 013f1b3d: `_snap_rnames` marks a name for any `remote.<name>.*` key and for any legacy file (`:512`, `:724`), in one table across repos. Only leading whitespace is trimmed from a `URL:` line, and `_snap_remote` strips `file://` without decoding or dropping a host (`:369-370`). The parenthesis carries the important qualifier: one added during the session is itself a finding (a changed `C` record or a new hashed legacy file). As written it trails the last list item and reads like a condition on `file://` URLs only.

**Recommendation:** Move the qualifier to the front: "When already there at launch (adding one is itself a finding), each of these can name a path the scan does not walk: …".

## What Looks Good

- 013f1b3d restores main's `_snap_rnames` rule exactly: `git diff main...013f1b3d` shows the `remote.*.*` marking line and the legacy-file `_snap_rnames["$name"]=1` as unchanged context, with only `_snap_remote`→`_snap_url` changed around them. The no-url test and guide phrase left with it, and the plan row B24 says where the fix went.
- Both remaining p2 naming points landed: `_snap_pairs_ok` now matches `_snap_size_ok`, and the cap comment (`:390-393`) names each cap's checker (`_snap_key`, `_snap_pairs_ok`, `_snap_match`). The FAIL CLOSED header (`:98-99`) names the same three.
- `_snap_rule` failures now propagate (`_snap_rule … || return 1` at both call sites), matching `_snap_url`'s existing `|| return 1`, so the byte cap fails closed from repo and host config alike.
- The guide's cap sentence lists all three caps with the same numbers as the code (4,096 / 100,000 / 2,000) and keeps "(At launch any of these refuses the launch instead, exit 1.)". The cap test asserts `status 2` for each and the exact message text.
- The header and guide sentence ("Those, your `insteadOf` rules and your remote URLs are the only entries of your own config it follows; none is recorded") now match `_snap_host_config` (`:614-618`), which queues exactly those and writes no `C` records. The commit's "Unit size … 400" checks out: `git diff --shortstat main...013f1b3d -- . ':!docs'` gives 356 insertions, 44 deletions.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Two comments name the deleted `_snap_rewrite` | Minor | `cc-exit-scan.sh:518, 831` | High |
| 2 | Byte-cap message has no amount or place, unlike every other cap message | Minor | `cc-exit-scan.sh:406-407` | High |
| 3 | Guide/commit say the 2,000 cap is one per URL and working tree; code counts every match, duplicates included | Minor | `guides/cc-isolated-usage.md:349-350`; `cc-exit-scan.sh:449, 462-471` | High |
| 4 | Cap test named "either" now covers three caps | Informational | `test/cc-isolated-functions.bats:2277` | High |
| 5 | `GIT_EXIT_SCAN_MAX_REWRITE_BYTES` per-string, named like pass totals | Minor | `cc-exit-scan.sh:394-396` | Medium |
| 6 | Byte-cap message blames URL/rule when the long string is a working-tree path | Informational | `cc-exit-scan.sh:401-413` | Medium |
| 7 | Known-route bullet's "(if present at launch)" trails and is easy to misread | Informational | `guides/cc-isolated-usage.md:420-425` | Medium |

## Overall Assessment

The iteration-2 changes fit the file's conventions. All five p2 findings are addressed, the early split cleanly restores main's remote-name behaviour, and the new guide bullet describes the split-out family accurately. What remains is small and fixable in place. Two comments point at a function this scope deleted (Finding 1). The new cap's message breaks the "say where it tripped" convention that p2 just established for its siblings (Finding 2), and that matters most when the user's own config trips it at launch. The guide misstates what the target cap counts (Finding 3). Findings 4–7 are naming and wording nits. None affects a consumer outside the branch, and none bears on whether the scan sees an insteadOf route.

## Goal-Alignment Note

Success criterion: "Two markdown reports saved under docs/reviews/ per the performance-reviewer and api-consistency-reviewer skills, first line Commit: 013f1b3d." This is the api-consistency report, saved at `docs/reviews/q096-exit-scan-insteadof-target-p3-api-consistency-review-2026-10-15.md` with first line `Commit: 013f1b3d`, in the skill's structure: baseline, required name-pattern audit, findings (each with Severity, Location, Evidence, Confidence, Legibility-target, and precedent lines on the naming findings), What Looks Good, summary, assessment. It covers what the brief named: the new byte cap against the existing caps, messages, helper names, guide text including the new known-route bullet, and tests. It also checks that the p2 findings were addressed. For the user goal (land Q-096), nothing here blocks: every finding is Minor or Informational legibility work the loop can fix in place.
