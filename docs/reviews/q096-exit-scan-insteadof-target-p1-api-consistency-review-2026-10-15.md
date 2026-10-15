Commit: 5f754994

# API Consistency Review — fix/q096-exit-scan-insteadof-target (Q-096, pass 1)

**Scope:** `git diff main...HEAD` (b279a2ba..5f754994): `devcontainer-config/cc-exit-scan.sh`, `guides/cc-isolated-usage.md`, `test/cc-isolated-functions.bats`, plus the Q-096 brief, plan and research docs
**Date:** 2026-10-15
**Based on:** `docs/reviews/q096-exit-scan-insteadof-target-p1-code-fact-check-report.md` (Stage 1, pass 1). Behaviour that report verified by experiment is not re-verified here.

## Baseline Conventions

The scan's consumer-facing surface, read before judging the diff:

- **Tunable caps.** Plain shell globals declared right above the function that enforces them, named `GIT_EXIT_SCAN_MAX_<SCOPE>_<UNIT>`: `GIT_EXIT_SCAN_MAX_FILE_BYTES=$((64 * 1024 * 1024))` and `GIT_EXIT_SCAN_MAX_TOTAL_BYTES=$((1024 * 1024 * 1024))` (`cc-exit-scan.sh:192-193`). Tests override them by plain assignment with a `# shellcheck disable=SC2034  # read by <fn> (sourced)` comment (`test/cc-isolated-functions.bats:2499-2500`).
- **Cap failure messages.** Written through `_snap_fail` in a fixed shape: `<what> (<context>): <why>, treat the checkout as unsafe`, e.g. `'%s is too large to hash (%s bytes, over %s): treat the checkout as unsafe'` and `'more than %s bytes to hash (at %s): too much to hash, treat the checkout as unsafe'` (`cc-exit-scan.sh:198, 204`).
- **Fail-closed contract.** Snapshot returns 1; `git_exit_scan` returns 2; the launcher exits 4 at session exit and refuses the launch (exit 1) when the baseline snapshot fails. The causes are listed in two places: the header's FAIL CLOSED paragraph (`cc-exit-scan.sh:94-99`) and the guide's fail-closed paragraph (`guides/cc-isolated-usage.md:346-349`).
- **Limits contract.** The header says every route a clean scan does not rule out is listed once, in the guide's "Known routes it does not see", and must be updated there "when a change here opens or closes a route" (`cc-exit-scan.sh:120-123`).
- **Helper naming.** Private helpers that run inside `git_exec_snapshot` use the `_snap_` prefix and share its locals by dynamic scoping. Most are named for the noun they walk (`_snap_remote`, `_snap_config`, `_snap_gitdir`, `_snap_hooks`, `_snap_file`). Parallel queue arrays pair a values array with a `*bases` array (`_snap_names` / `_snap_nbases`).
- **Records.** Tab-separated `F` / `C` / `W` records (`cc-exit-scan.sh:159-164`). Report lines look like `+ hook <path> ...` and `~ remote <path>  dir ...`.
- **Test naming.** `@test "exit scan <tag>: <behaviour>"`. Tags are either a Q-ID (`Q-094:` ×12) or a topic/plan-row label (`size cap:`, `gitdir:`, `N3:`). Test helpers are plain lower_snake (`scan_repo`, `plant_hook`, `no_ran`, `std_wt`, `warns_listing_wt`).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `GIT_EXIT_SCAN_MAX_REWRITES` | tunable (config global) | `GIT_EXIT_SCAN_MAX_FILE_BYTES`, `GIT_EXIT_SCAN_MAX_TOTAL_BYTES` | `devcontainer-config/cc-exit-scan.sh:192-193` | Mostly consistent. Prefix, placement and override style match. The unit suffix names *rewrites*, but the cap counts *comparisons* (see F3). |
| `'more than %s remote URL and insteadOf rule pairs to compare: too many, treat the checkout as unsafe'` | error message | `'more than %s bytes to hash (at %s): too much to hash, treat the checkout as unsafe'` | `cc-exit-scan.sh:204` | Consistent shape. It has no `(at …)` context (see F5). |
| `_snap_url` | internal helper | `_snap_remote`, `_snap_config`, `_snap_file` | `cc-exit-scan.sh:232-376` | Consistent: `_snap_` prefix, named for the noun it handles |
| `_snap_rule` | internal helper | `_snap_remote`, `_snap_wrel` | `cc-exit-scan.sh:300, 356` | Consistent |
| `_snap_rewrite` | internal helper | `_snap_remote`, `_snap_cond`, `_snap_logical` | `cc-exit-scan.sh:503-548` | Consistent. Verb-ish names already exist (`_snap_find`, `_snap_cond`). |
| `_snap_urls` / `_snap_ubases`, `_snap_rbases` / `_snap_rpfx` | shared locals (parallel arrays) | `_snap_names` / `_snap_nbases` | `cc-exit-scan.sh:731` (pre-change line) | Consistent: values array plus a `*bases` array. `_snap_rpfx` breaks the `*bases` suffix, but it holds prefixes, not bases, so the different name is correct. |
| `_snap_rwseen`, `_snap_rwn` | shared locals | `_snap_seen`, `_snap_bytes` | `cc-exit-scan.sh:729-730` | Consistent. The seen-set and counter idioms match the siblings. |
| `rewrite_plant` | test helper | `plant_hook`, `scan_remote`, `std_wt` | `test/cc-isolated-functions.bats:1400, 1713, 2539` | Consistent: lower_snake, a domain-noun verb |
| `exit scan Q-096: …` (×8) | test names | `exit scan Q-094: …` (×12), `exit scan size cap: …` | `test/cc-isolated-functions.bats` | Consistent. The cap test sits under the Q-ID rather than the `size cap:` topic tag. Either is precedented (see F6). |
| record kinds | report/record format | `F`, `C`, `W` | `cc-exit-scan.sh:159-164` | No new record kind. Rewritten targets reuse `F remote` / `W` and the existing `~ remote` / `+ hook` report lines. Consistent. |

## Findings

#### F1. The guide drops the "rewritten by insteadOf" known route, but part of it is still open

**Severity:** Inconsistent
**Location:** `guides/cc-isolated-usage.md:410-416` (removed bullet); `devcontainer-config/cc-exit-scan.sh:563-584` (`_snap_host_config`)
**Move:** 3 (consumer contract: documentation drift)
**Confidence:** Medium-High. Based on the code reading below and the Stage-1 fact-check, whose probe ran the hook and found no record. Not re-probed here.
**Legibility-target:** the operator reading "Known routes it does not see" to decide whether host git is safe after a session

Evidence (removed from the guide):
```
-- **A URL rewritten by `url.<base>.insteadOf`.** The base is walked, never the
-  rewritten URL, so a remote rewritten to a local path the session plants runs
-  that repository's hooks on push.
```
Evidence (`_snap_host_config`, full function read, lines 549-590): host-config entries are now queued as rules,
```
    case "$key" in
      url.*.insteadof|url.*.pushinsteadof) t="${key#url.}"; _snap_rule "${t%.*}" "$val" ;;
    esac
```
but the `case` that follows handles only `core.hookspath`, `core.attributesfile` and `include.path|includeif.*.path`. No `remote.*.url|remote.*.pushurl` arm calls `_snap_url`, so a remote defined in your own global or system config is never queued as a URL.

The header's limits contract (`cc-exit-scan.sh:120-123`: "update it there when a change here opens or closes a route") treats the guide's list as the single source of what a clean scan does not rule out. The fact-check found two variants of the removed route still open: a remote in YOUR config rewritten by a launch-time rule to a target the session plants, and a URL typed on the command line. The guide now lists neither. A consumer who reads the shorter list will conclude the insteadOf family is closed.

**Recommendation:** Keep a narrowed bullet, for example: "A remote defined only in your own global/system config, or a URL typed on the command line, rewritten by `insteadOf` to a path the session plants: not walked." Alternatively, queue host `remote.*.url`/`pushurl` with `_snap_url` and leave only the command-line case in the bullet.

#### F2. The new cap is missing from both canonical fail-closed lists

**Severity:** Minor
**Location:** `devcontainer-config/cc-exit-scan.sh:94-97`; `guides/cc-isolated-usage.md:346-349` and `:414-416`
**Move:** 3 (documentation drift) / 7 (asymmetry with the sibling caps)
**Confidence:** High
**Legibility-target:** the maintainer adding the next cap, and the operator diagnosing an exit-4

Evidence (header, unchanged by the diff):
```
# FAIL CLOSED. A directory that cannot be listed, a file that cannot be read, a
# config git cannot parse, or a file too large to hash (over 64 MiB, or past 1 GiB
# in all: _snap_size_ok) makes the snapshot fail: at launch the launcher refuses
```
Evidence (guide fail-closed paragraph, unchanged):
```
it would hash that is over 64 MiB (a sparse file counts at its apparent size),
or more than 1 GiB to hash in all, fails the scan (exit 4: treat the checkout as
unsafe) rather than stalling it; so does a `.git` file or `commondir` over 64 MiB,
```
The new cap's only guide mention is in the scope paragraph (`:326-327`, "More than 100,000 URL-and-rule comparisons fails the scan (exit 4) rather than stalling it."). Both places that enumerate fail-closed causes still list only the byte caps. The "A slow scan" known route (`:414`, "Hashing is capped (64 MiB a file, 1 GiB in all)") also leaves out the new stall guard.

**Recommendation:** Add "or more than `GIT_EXIT_SCAN_MAX_REWRITES` URL-and-rule comparisons (`_snap_rewrite`)" to the header FAIL CLOSED sentence. Move or duplicate the 100,000 sentence into the guide's fail-closed paragraph next to the 64 MiB / 1 GiB caps.

#### F3. `GIT_EXIT_SCAN_MAX_REWRITES` is named for rewrites but counts comparisons

**Severity:** Minor
**Location:** `devcontainer-config/cc-exit-scan.sh:403-412`
**Move:** 2 (naming against the grain)
**Confidence:** High
**Legibility-target:** whoever tunes or overrides the cap (tests, a future env override)

Precedent: cap names end in the unit the counter measures (`GIT_EXIT_SCAN_MAX_FILE_BYTES`, `GIT_EXIT_SCAN_MAX_TOTAL_BYTES`, both compared against byte counts) used in `devcontainer-config/cc-exit-scan.sh:192-205`

Evidence:
```
GIT_EXIT_SCAN_MAX_REWRITES=100000
_snap_rewrite() {
  local u="${_snap_urls[$1]}" p="${_snap_rpfx[$2]}" t k
  _snap_rwn=$((_snap_rwn + 1))
  if [ "$_snap_rwn" -gt "$GIT_EXIT_SCAN_MAX_REWRITES" ]; then
```
(The function continues to line 420: the counter goes up *before* the prefix test `[[ "$u" == "$p"* ]] || return 0`, so non-matching pairs count too.) The message ("remote URL and insteadOf rule pairs to compare"), the header comment ("Past GIT_EXIT_SCAN_MAX_REWRITES comparisons") and the guide ("URL-and-rule comparisons") all call the unit a comparison. Only the variable name says "rewrites", which suggests the count is of matches. Someone tuning it could misjudge the headroom by orders of magnitude (100 URLs × 1,000 rules is 100,000 comparisons with zero rewrites). The rename is cheap: the variable has one consumer, `test/cc-isolated-functions.bats:2222`.

**Recommendation:** Rename to `GIT_EXIT_SCAN_MAX_REWRITE_PAIRS` (or `_MAX_REWRITE_COMPARISONS`). This keeps the `MAX_<SCOPE>_<UNIT>` grain.

#### F4. "(exit 4)" states only the exit half of the contract, as its nearest sibling does

**Severity:** Informational
**Location:** `guides/cc-isolated-usage.md:326-327`
**Move:** 4 (error consistency)
**Confidence:** High (fact-check verified snapshot 1 / `git_exit_scan` 2 / launcher 4 at exit, launcher 1 at launch)
**Legibility-target:** the operator whose launch is refused

Evidence:
```
matching rule, the scan walks every match. More than 100,000 URL-and-rule
comparisons fails the scan (exit 4) rather than stalling it.
```
This matches the size-cap wording at `:347` ("fails the scan (exit 4: treat the checkout as unsafe)"). The two siblings use the dual form instead: `:418-420` ("refuses the launch (exit 1) or, at exit, reports exit 4") and the header's `cc-exit-scan.sh:96` ("at launch the launcher refuses to start, at exit it returns 4"). The guide is mixed, and the new text copied the less complete form. The fact-check rated it Mostly accurate.

**Recommendation:** If F2 moves this sentence into the fail-closed paragraph, have that paragraph state the launch/exit split once for every cap.

#### F5. The cap failure message gives no location context, unlike the total-bytes message

**Severity:** Informational
**Location:** `devcontainer-config/cc-exit-scan.sh:410-411`
**Move:** 4 (error consistency)
**Confidence:** Medium. This is a usefulness point. The shape is otherwise consistent.
**Legibility-target:** the operator deciding whether an exit-4 is a plant or a legitimately large config

Evidence:
```
    _snap_fail 'more than %s remote URL and insteadOf rule pairs to compare: too many, treat the checkout as unsafe' \
      "$GIT_EXIT_SCAN_MAX_REWRITES"
```
versus the sibling `'more than %s bytes to hash (at %s): too much to hash, treat the checkout as unsafe'` (`:204`), which names the file it was hashing when it tripped. The new message does not show how many URLs and rules were queued, so the operator cannot tell "50 URLs × 2,001 rules" (likely a plant) from a shape a large monorepo could legitimately hit.

**Recommendation:** Optionally add `(%s URLs, %s rules)` from `${#_snap_urls[@]}` / `${#_snap_rbases[@]}`. These are counts, not container-chosen strings, so `_snap_fail`'s ASCII reduction is not a concern.

#### F6. The cap test asserts at the snapshot layer, while its sibling cap tests assert at the scan's exit status

**Severity:** Informational
**Location:** `test/cc-isolated-functions.bats:2216-2227`
**Move:** 7 (asymmetry)
**Confidence:** High
**Legibility-target:** the maintainer relying on the suite to pin the exit-4 contract

Evidence:
```
  GIT_EXIT_SCAN_MAX_REWRITES=1
  run git_exec_snapshot "$SCAN_WS"
  [ "$status" -eq 1 ]
```
versus the `size cap:` tests (`:2496-2504`):
```
  GIT_EXIT_SCAN_MAX_TOTAL_BYTES=100
  run git_exit_scan "$SCAN_WS" "$before"
  [ "$status" -eq 2 ]
```
The status-2 path that the guide's "exit 4" depends on is covered for the byte caps but not for this cap. The fact-check verified it by experiment, so no current bug, but the suite does not pin it. The test name's `Q-096:` tag is precedented (`Q-094:`), even though the `size cap:` topic tag would group it with its siblings.

**Recommendation:** Add the `git_exit_scan … [ "$status" -eq 2 ]` form (snapshot with the default cap, lower it, run the exit scan) alongside or in place of the snapshot-level assert.

#### F7. The shared-locals comment does not list the six new dynamic-scoped locals

**Severity:** Informational
**Location:** `devcontainer-config/cc-exit-scan.sh:153-158`
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** a maintainer calling a `_snap_*` helper from outside `git_exec_snapshot`

Evidence:
```
# The _snap_* helpers below run inside git_exec_snapshot and share its locals
# (bash dynamic scoping): _snap (the records), _snap_seen (walked dirs), _snap_ws,
# _snap_gd, _snap_common, _snap_tmp, _snap_names/_snap_rnames (remote names). Each
```
`_snap_url`, `_snap_rule` and `_snap_rewrite` depend on `_snap_rwseen` (an associative array), `_snap_urls`, `_snap_ubases`, `_snap_rbases`, `_snap_rpfx` and `_snap_rwn`. If `_snap_config` or `_snap_gitdir` were ever called outside `git_exec_snapshot`, `_snap_rwseen["u:…"]` would land in an undeclared array, which bash creates as an *indexed* array, and the string subscript would be evaluated arithmetically. Today every caller is inside `git_exec_snapshot` (grep of the file, lines 376-787), so this is a contract-legibility point, not a bug. The list was already incomplete before this diff (`_snap_nbases`, `_snap_lws` are missing).

**Recommendation:** Append `_snap_urls/_snap_ubases/_snap_rbases/_snap_rpfx/_snap_rwseen/_snap_rwn (insteadOf worklist)` to the list.

## What Looks Good

- **Cap mechanics match the precedent exactly:** a global declared above its enforcer, compared with `-gt`, failing through `_snap_fail` with the `… : treat the checkout as unsafe` tail, overridden in tests by plain assignment with the same `SC2034 # read by … (sourced)` comment.
- **No new record kinds or report lines.** Rewritten targets go through the existing `_snap_remote`, so consumers of `scan_diff` output and `scan_std_worktrees`'s W-record reading are unaffected. Existing callers see no break: `git_exec_snapshot`'s and `git_exit_scan`'s signatures and exit statuses are unchanged.
- **Queue naming follows `_snap_names`/`_snap_nbases`**, and `_snap_rwseen` follows `_snap_seen`. Routing all four URL sources (`remote.*.url/pushurl`, `branches`, `remotes`, path-valued remote names) through one `_snap_url` entry point makes the surface symmetric. Every URL source now gets the same treatment.
- **The header and guide were updated together**, in parallel wording (the "git takes only the longest, the scan walks them all" / "git uses only the longest matching rule, the scan walks every match" pair; the relative-target W-record clause in both).
- **Test names and helper** follow the `exit scan Q-0NN:` and lower_snake helper conventions. `rewrite_plant` reads like `plant_hook`.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Known-route bullet removed while host-config remote / command-line URL variants stay open | Inconsistent | `guides/cc-isolated-usage.md:410-416`; `cc-exit-scan.sh:563-584` | Medium-High |
| 2 | New cap missing from header FAIL CLOSED list and guide fail-closed paragraph / slow-scan bullet | Minor | `cc-exit-scan.sh:94-97`; `guides/cc-isolated-usage.md:346-349, 414` | High |
| 3 | `GIT_EXIT_SCAN_MAX_REWRITES` named for rewrites, counts comparisons | Minor | `cc-exit-scan.sh:403-412` | High |
| 4 | "(exit 4)" omits launch refusal (matches size-cap wording; guide mixed) | Informational | `guides/cc-isolated-usage.md:326-327` | High |
| 5 | Cap message has no context counts, unlike `(at %s)` sibling | Informational | `cc-exit-scan.sh:410-411` | Medium |
| 6 | Cap test asserts snapshot status 1, siblings assert `git_exit_scan` status 2 | Informational | `test/cc-isolated-functions.bats:2216-2227` | High |
| 7 | Shared-locals comment not updated with the six new locals | Informational | `cc-exit-scan.sh:153-158` | High |

## Overall Assessment

The diff follows the scan's established surface closely. The new cap, helpers, queues, failure message and tests each have a clear sibling and match it. No record format, report line, function signature or exit status changes, so existing consumers see nothing break. The one finding that matters to consumers is F1. The guide's "Known routes" list is the documented single source of residual risk, and it now reads as if the whole insteadOf family is closed, while a remote in your own global/system config (and a command-line URL) rewritten to a planted target is still unwalked. F2 and F3 are small documentation and naming fixes that keep the caps easy to find and correctly understood. F4-F7 are optional polish. Everything can be fixed in place; nothing suggests the author skipped the existing conventions.

## Goal-Alignment Note

The PR's goal is that a session cannot repoint a push through an insteadOf rewrite the scan ignores. The consistency work supports that goal: rewritten targets reuse the existing walk, records and fail-closed cap pattern, so they show up in the existing report format. The documentation half of the goal falls short. By removing the known-route bullet outright, the guide claims more closure than the code delivers (F1). Since the guide is the operator's decision surface, that gap works against the goal even though the code change itself is sound. Restoring a narrowed bullet, or extending `_snap_host_config` to queue host remote URLs, would make the guide match the code. F2-F7 do not affect whether the goal is met.
