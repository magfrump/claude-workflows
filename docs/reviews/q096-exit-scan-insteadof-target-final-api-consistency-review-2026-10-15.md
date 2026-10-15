Commit: 03bc47c9

# API Consistency Review — fix/q096-exit-scan-insteadof-target, final confirming pass (main...03bc47c9)

**Scope:** `git diff main...HEAD -- . ':!docs/reviews'` at 03bc47c9 (full branch: `devcontainer-config/cc-exit-scan.sh`, `guides/cc-isolated-usage.md`, `test/cc-isolated-functions.bats`, the plan, research doc and brief; five commits `git log main..HEAD`); `devcontainer-config/cc-isolated.sh` read for the launcher's exit statuses
**Date:** 2026-10-15
**Based on:** shared brief `shared-brief-final.md`; prior reports p1–p3 (advisory); p3 code-fact-check report (claims 20, 21); sibling report `q096-exit-scan-insteadof-target-final-performance-review-2026-10-15.md`

> ⚠️ **No code fact-check report provided for this pass.** API documentation claims changed in 03bc47c9 have not been independently verified by a fact-check stage. This review checked them against the code directly and ran `bats test/cc-isolated-functions.bats -f 'Q-096'` (LC_ALL=C): 11/11 ok.

This unit's public surface consists of:
- the tunable `GIT_EXIT_SCAN_MAX_*` constants, which the bats suite overrides after sourcing;
- the `_snap_fail` reason strings, shown to the user on a launch refusal and on exit 4;
- the exit statuses: snapshot 1, `git_exit_scan` 2, launcher 1 at launch and 4 at exit;
- the guide's statements, which are the user's contract for what a clean scan means;
- the header comments and shared-locals list, which are the contract for Q-097, the next unit on this file;
- the test names (`-f 'Q-096'`) and test helpers.

## Baseline Conventions

- **Caps:** `GIT_EXIT_SCAN_MAX_<SCOPE>_<UNIT>`, assigned at source time under a comment naming the checker (`GIT_EXIT_SCAN_MAX_FILE_BYTES`/`_TOTAL_BYTES`, `cc-exit-scan.sh:201-202`). Checkers are `_snap_<thing>_ok` predicates that charge a counter and `_snap_fail` (`_snap_size_ok`, `:203-216`).
- **Cap messages:** `'<what> (<amount/where>): <why>, treat the checkout as unsafe'`, always naming an amount or place (`:207`, `:213`, `:228`).
- **Exit statuses:** a helper failure returns 1 with one reason on stderr. `git_exit_scan` returns 2 when the snapshot fails. The launcher maps a failed launch snapshot to `exit 1` (`cc-isolated.sh:859-867`) and an exit-scan status of 2 to `exit 4` (`cc-isolated.sh:934-938`).
- **Parallel queues:** a value array with a sibling base array, `_snap_names`/`_snap_nbases` (main, `:783`).
- **Helper references in comments:** a parenthesised name is a live helper (`(_snap_size_ok)`, `(_snap_match)`).
- **Known-route bullets:** a bold lead, then the cause, then what the scan does not see (`guides/cc-isolated-usage.md:413-470`).
- **Tests:** `@test "exit scan <unit tag>: <behaviour>"`. Helpers are verb-first: `make_repo`, `scan_repo`, `plant_hook`, `fake_commit`, `std_wt` (`test/cc-isolated-functions.bats:62, 636, 1393, 1400, 2604`).

## Prior (p3) findings

- F1 (stale `_snap_rewrite` references): **addressed.** Both comments now name `_snap_match` (`:518`, `:831`), and `grep _snap_rewrite` over `devcontainer-config/ guides/ test/` finds nothing.
- F2 (byte-cap message without amount): **addressed.** It now prints both lengths (`:406-407`); see Finding 3 on labelling.
- F3 (target cap described as one per URL and working tree): **addressed** in the guide ("one per URL-and-rule match", `guides/cc-isolated-usage.md:350`). The 4d7f966c commit body still says "counts URL-and-working-tree targets". 03bc47c9's body records that the old text is wrong, and correcting the old body itself would need a history rewrite. Not re-filed.
- F4 (test name "either"): **addressed** ("past any insteadOf cap", `test/cc-isolated-functions.bats:2270`).
- F5 (`GIT_EXIT_SCAN_MAX_REWRITE_BYTES` named like a pass total): **left by decision.** The 03bc47c9 Notes say "kept its name … the comment says per string". Not re-filed.
- F6 (message blames URL/rule for a long working tree): **addressed.** The message now reads "a remote URL, its working tree or an insteadOf rule".
- F7 ("if present at launch" trailing): **addressed.** It now leads the bullet (`guides/cc-isolated-usage.md:421`).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `GIT_EXIT_SCAN_MAX_REWRITE_PAIRS` | constant (cap) | `GIT_EXIT_SCAN_MAX_FILE_BYTES`, `GIT_EXIT_SCAN_MAX_TOTAL_BYTES` | `devcontainer-config/cc-exit-scan.sh:201-202` | Consistent: `MAX_<scope>_<unit>` |
| `GIT_EXIT_SCAN_MAX_REWRITE_TARGETS` | constant (cap) | same | same | Consistent |
| `GIT_EXIT_SCAN_MAX_REWRITE_BYTES` | constant (cap) | `GIT_EXIT_SCAN_MAX_FILE_BYTES` (per item), `_TOTAL_BYTES` (aggregate) | same | Per-string cap whose name reads like a total; left by decision (p3 F5), comment correct |
| `_snap_url`, `_snap_rule` | function (queue + walk) | `_snap_remote`, `_snap_file`, `_snap_config` | `cc-exit-scan.sh:241, 365, 474` | Consistent: `_snap_<noun>` acts on one item of that kind |
| `_snap_key` | function (key builder, optional `check`) | `_snap_hash`, `_snap_path` | `cc-exit-scan.sh:186, 297` | Consistent noun builder; the positional `check` word matches the file's optional-positional style (`_snap_remote <url> [<wt>]`) |
| `_snap_pairs_ok` | function (cap checker) | `_snap_size_ok` | `cc-exit-scan.sh:203` | Consistent |
| `_snap_match`, `_snap_walk_hits` | function (worklist) | `_snap_nested`, `_snap_hooks` | `cc-exit-scan.sh:325, 678` | Consistent |
| `_snap_urls`/`_snap_ubases`, `_snap_rbases`/`_snap_rpfx`, `_snap_hit_t`/`_snap_hit_b` | shared locals (parallel queues) | `_snap_names`/`_snap_nbases` | `cc-exit-scan.sh:783` | `_snap_ubases` matches `_snap_nbases`; `_snap_rpfx` and the `_t`/`_b` suffixes depart slightly, but all are listed in the shared-locals header (`:160-162`); acceptable |
| `_snap_rwseen`, `_snap_k`, `_snap_rwn`, `_snap_rwt` | shared locals | `_snap_seen`, `_snap_linkdir`, `_snap_bytes` | `cc-exit-scan.sh:780-781` | Consistent; all listed in the header |
| three cap messages (`:406`, `:433`, `:450`) | error string | the size and read cap messages | `cc-exit-scan.sh:207, 213, 228` | Consistent shape; see Finding 3 on unlabelled lengths |
| `rewrite_plant` | test helper | `plant_hook`, `scan_repo`, `make_repo` | `test/cc-isolated-functions.bats:62, 1393, 1400` | Informational: object-first, where neighbours are verb-first (Finding 4) |
| 11 `"exit scan Q-096: …"` tests | test name | `"exit scan N3: …"`, `"exit scan size cap: …"` | `test/cc-isolated-functions.bats` | Consistent |
| guide bullets "**Remote names and legacy remote files, read loosely.**", "**A URL you type.**" | doc (known route) | "**`~` forms.**", "**A slow scan.**" | `guides/cc-isolated-usage.md:413-470` | Consistent |

## Findings

#### 1. The plan's test specification names a cap that no longer exists and a check the test does not make

**Severity:** Minor
**Location:** `docs/working/plan-q096-exit-scan-insteadof-target.md:77`
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** a reviewer or Q-097 author checking the plan against the suite; anyone grepping the repo for the cap's name
Precedent: the caps are `GIT_EXIT_SCAN_MAX_REWRITE_PAIRS` / `_TARGETS` / `_BYTES` used in `devcontainer-config/cc-exit-scan.sh:394-396`
**Evidence:**
```
The cap case sets `GIT_EXIT_SCAN_MAX_REWRITES` low and expects the snapshot to fail with "too many".
```
versus the test at HEAD:
```
@test "exit scan Q-096: past any insteadOf cap, the exit scan fails as unsafe" {
```
```
  GIT_EXIT_SCAN_MAX_REWRITE_PAIRS=1
  run git_exit_scan "$SCAN_WS" "$before"
  [ "$status" -eq 2 ]
```
(The test continues with the `_TARGETS=1` and `_BYTES=10` blocks, each asserting status 2 and its message, and ends at line 2291.) `GIT_EXIT_SCAN_MAX_REWRITES` was 5f754994's single cap, renamed in e4b29291. A whole-repo search outside `docs/reviews/` finds it only on this line of the plan. The plan's B14 row was updated to the split caps, but the test specification was not. The test drives `git_exit_scan` (status 2) across three caps, not a snapshot failure on one. The plan's status says "complete", so a reader takes it as describing the landed state.

**Recommendation:** Reword to: "The cap case lowers each of `GIT_EXIT_SCAN_MAX_REWRITE_PAIRS`, `_TARGETS` and `_BYTES` in turn and expects `git_exit_scan` status 2 with that cap's message."

#### 2. The header and the guide say "each of those" URLs is rewritten, which takes in insteadOf bases (never rewritten) and, in the header, leaves out non-local URLs (always rewritten)

**Severity:** Minor
**Location:** `devcontainer-config/cc-exit-scan.sh:56-65`; `guides/cc-isolated-usage.md:318-327`
**Move:** 3 (documentation drift / contract clarity)
**Confidence:** High (read from code; consistent with p3 fact-check claim 20's scope)
**Legibility-target:** the Q-097 author reading the header as the contract for which URLs enter the queue; a user reading the guide's follow list
**Evidence:** header:
```
# local path inside the checkout (remote.*.url/pushurl, remote.pushDefault,
# branch.*.remote/pushRemote naming a path, url.<base>.insteadOf bases, legacy
# remotes files; a relative path resolved in the working tree of the repo whose
# config names it), walked as a git dir: a push to it runs its hooks. Each of those
# URLs, and every remote.*.url/pushurl in your own config, is also rewritten by
```
guide:
```
`url.<base>.insteadOf`, `file://localhost/`, relative paths such as `sub/a:b`,
resolved in the working tree of the repo whose config names them). Each of
those remote URLs, local or not, and each `remote.*.url`/`pushurl` in your own
```
code (`_snap_config`, insteadOf case):
```
        _snap_rule "$t" "$val" || return 1
        _snap_remote "$t" "$base" || return 1 ;;
```
A base goes to `_snap_remote`, not `_snap_url`, so it is never queued for rewriting. That is correct, since git does not chain rewrites. But "those" in both texts includes the bases. In the header, "those" is also the list of remotes that are *local paths inside the checkout*. Read literally, it says an `https://` remote is not rewritten. Queuing non-local URLs is the core of Q-096: `_snap_url` queues every `remote.*.url`/`pushurl`, every unresolved remote name and every legacy URL, local or not. The guide adds "local or not" but still counts the base, and its list omits legacy remote URLs, which the code also rewrites. The comment and the guide only mis-describe coverage. The code is correct, and no route opens.

**Recommendation:** In both places, name the queued set directly: "Every remote URL — `remote.*.url`/`pushurl`, an unresolved `remote.pushDefault`/`branch.*.remote`/`pushRemote` name, a legacy remotes URL, local or not, and your own `remote.*.url`/`pushurl` — is also rewritten …; insteadOf bases are walked but not rewritten (git does not chain)."

#### 3. The byte-cap message prints two unlabelled lengths, and the guide's cap sentence omits the working-tree case the message names

**Severity:** Informational
**Location:** `devcontainer-config/cc-exit-scan.sh:401-408`; `guides/cc-isolated-usage.md:348-349`
**Move:** 4 (error consistency), 7 (asymmetry between message and guide)
**Confidence:** High
**Legibility-target:** a user whose launch is refused by an over-long entry in their own global config, who must find which string is too long
**Evidence:**
```
_snap_key() {
  local LC_ALL=C
  _snap_k="${#1}:$1$2"
  [ -n "${3:-}" ] || return 0
  [ "${#1}" -gt "$GIT_EXIT_SCAN_MAX_REWRITE_BYTES" ] || [ "${#2}" -gt "$GIT_EXIT_SCAN_MAX_REWRITE_BYTES" ] || return 0
  _snap_fail 'a remote URL, its working tree or an insteadOf rule over %s bytes (%s and %s): too long to compare, treat the checkout as unsafe' \
    "$GIT_EXIT_SCAN_MAX_REWRITE_BYTES" "${#1}" "${#2}"
}
```
guide:
```
before its first line is read, and so do a remote URL or `insteadOf` rule over
4,096 bytes, more than 100,000 URL-and-rule comparisons, or more than 2,000
```
"(%s and %s)" means URL and working tree when `_snap_url` calls it, and rule base and value when `_snap_rule` calls it. The message does not say which, and neither length is labelled. Sibling messages label their numbers: "(%s bytes, over %s)", "(%s URLs, %s rules so far)". The guide's sentence leaves out the working-tree case that the message (and p3 F6's fix) now names. A working tree over 4,096 bytes is near PATH_MAX and unlikely, so the impact is small.

**Recommendation:** Optional: pass a label from each caller, for example `(URL %s bytes, working tree %s)` vs `(base %s bytes, value %s)`, and add "(or its working tree)" to the guide sentence.

#### 4. Test helper `rewrite_plant` is object-first, where the suite's helpers are verb-first

**Severity:** Informational
**Location:** `test/cc-isolated-functions.bats:2127-2139`
**Move:** 2 (naming against the grain)
**Confidence:** Medium
**Legibility-target:** a test author looking for the "plant targets, then scan" helper next to `plant_hook`
Precedent: verb-first helper names (`plant_hook`, `scan_repo`, `make_repo`, `fake_commit`) used in `test/cc-isolated-functions.bats:62, 636, 1393, 1400`
**Evidence:**
```
# rewrite_plant <target...>: a bare repo at each target before the launch
# snapshot (BEFORE), a pre-receive hook in each after it, then the exit scan,
# which must name every hook.
rewrite_plant() {
```
(the function continues: init each target, snapshot, plant hooks, `run git_exit_scan`, assert status 1, each hook named, `no_ran`, `}` at line 2139)

A test-only nit with no consumer outside this file. A verb-first name such as `plant_rewrite_targets` would sit next to `plant_hook` in a sorted list.

**Recommendation:** Optional rename; not needed for merge.

## What Looks Good

- **Exit statuses match their documentation end to end.** Every new cap fails through `_snap_fail` and `return 1`, and both callers propagate it: `_snap_rule … || return 1` in `_snap_config` and `_snap_host_config`, and `|| rc=1` / `break` in the worklist. `git_exit_scan` turns that into 2, and the launcher into `exit 4` at exit or `exit 1` at launch (`cc-isolated.sh:859-867`, `934-938`). The guide's "(At launch any of these refuses the launch instead, exit 1.)" and the plan's B14 "(exit 4 at exit, exit 1 at launch)" agree, and the cap test asserts status 2 and each message.
- **The guide's cap numbers match the code.** 4,096 / 100,000 / 2,000 in both places, and "one per URL-and-rule match" now describes what `_snap_rwt` and `_snap_match` count, which is hits before dedupe.
- **The own-config contract is stated identically** in the header ("Only those three kinds of entry, your insteadOf rules and your remote URLs are followed in your own config; its entries are not recorded") and the guide ("Those, your `insteadOf` rules and your remote URLs are the only entries of your own config it follows; none is recorded"). `_snap_host_config:615-618` queues exactly those and writes no `C` record.
- **The shared-locals header (`:157-162`) lists every new dynamically scoped variable** that `git_exec_snapshot` declares (`:780-784`), so Q-097 gets an accurate contract. The FAIL CLOSED header (`:97-99`) names the three cap checkers (`_snap_key`, `_snap_pairs_ok`, `_snap_match`), matching the cap comment (`:390-393`).
- **Test names follow `"exit scan Q-096: <behaviour>"`.** `bats -f 'Q-096'` selects all 11, including the UTF-8 read test with its restored legacy-URL half.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Plan's test spec names the removed `GIT_EXIT_SCAN_MAX_REWRITES` and a snapshot check the test does not make | Minor | `docs/working/plan-q096-exit-scan-insteadof-target.md:77` | High |
| 2 | Header/guide "each of those" includes insteadOf bases (never rewritten); header omits non-local URLs (always rewritten) | Minor | `cc-exit-scan.sh:56-65`; `guides/cc-isolated-usage.md:318-327` | High |
| 3 | Byte-cap message's two lengths unlabelled; guide omits the working-tree case | Informational | `cc-exit-scan.sh:401-408`; guide `:348-349` | High |
| 4 | Test helper `rewrite_plant` object-first among verb-first helpers | Informational | `test/cc-isolated-functions.bats:2127-2139` | Medium |

## Overall Assessment

The full branch is consistent with the file's conventions. Cap names, checker names, message shapes and exit statuses all follow established patterns, and every p3 finding was either fixed or left by a recorded decision. Two Minor documentation drifts remain, both fixable in place without code changes. The plan's test specification still names the pre-split cap (Finding 1). The header's and guide's "each of those" sentence describes the queued URL set imprecisely, and the header's version reads as excluding the non-local URLs that are the point of Q-096 (Finding 2). This matters most for the Q-097 author, who edits this file next. Findings 3–4 are optional polish. Nothing affects a consumer outside the branch or bears on whether the scan sees an insteadOf route, which fits a 0-red, 0-unresolved-amber merge if the two Minors are fixed or explicitly deferred.

## Goal-Alignment Note

Success criterion: "Two markdown reports saved under docs/reviews/ per the performance-reviewer and api-consistency-reviewer skills, first line Commit: 03bc47c9." This is the api-consistency report, saved at `docs/reviews/q096-exit-scan-insteadof-target-final-api-consistency-review-2026-10-15.md` with first line `Commit: 03bc47c9`, in the skill's structure. Precedent lines appear on the naming-shaped findings (1, 4). It covers the full branch at 03bc47c9, including brief claims 3, 4 and 6 from the contract side: cap names, messages, statuses, guide, header, plan and commit text. It records the disposition of every p3 finding. For the user goal (land Q-096), no finding opens a route or blocks merge. The two Minor findings are wording fixes to the plan and the comment/guide sentence.
