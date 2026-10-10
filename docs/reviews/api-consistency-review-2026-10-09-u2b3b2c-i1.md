Commit: f7e1bea2

# API Consistency Review — feat/build-loop-u2b3b2c (iteration 1)

**Scope:** `git diff main...HEAD` (main 8e550626, HEAD f7e1bea2): scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-check.bats; plus the sourcing inventory in test/scripts/dev-cycle.bats
**Date:** 2026-10-09
**Based on:** docs/reviews/code-fact-check-report-build-loop-u2b3b2c-i1.md (via the orchestrator's shared brief)

## Baseline Conventions

The public surface is the sourced lib's functions and globals, plus the numbered caller contract in its header (lib:47-98). Conventions observed in the siblings (with_at :1231, outside_seeds :1308, outside_proj :1211, main_checkout :1453, prompt_bases :667, nul_list :1414, import_readers :1082):

- **Signatures:** output name-ref first, then inputs (`with_at NAME PATH...`, `outside_proj OUT TOTAL`, `prompt_bases NAME LP PATH`, `main_checkout ENT MEMO PATH`); name-refs are bound with `local -n xx_a="$1"`, a two-letter function prefix on the local.
- **Array outputs reset:** every function documented as "array NAME gets ..." clears it first (`wa_a=()`, `os_a=()`, `pb_a=("")`, `nl_a=()` on failure). Appending is used only for a scalar in/out (`outside_proj`'s `op_o+=`), and its doc says "appended to OUT".
- **Return codes:** 0/1, documented as "It returns 1 when ...", a walk treating any 1 as a failed walk with `IMPORTED[_MAIN]=error` already set.
- **Lists:** NUL lists from tools via `nul_list`; newline-separated scalar globals for root sets (IMPORT_ROOTS, IMPORT_HOMES, IMPORT_DOTNEST), trailing newline stripped.
- **Globals:** `IMPORT_*`, cleared at source time and at the top of the producing function, memoized under `IMPORT_READERS_DONE`; contract item 9 names the ones a caller must never set.
- **Doc style:** a `# name ARGS: what it does (unit; finding ref)` block above each function, ending in "It returns 1 when ..." and, for import_readers' consumers, "Run it after import_readers".
- **Inventory test:** test/scripts/dev-cycle.bats:1106-1119 lists the lib's import-walk helpers and globals; units have added their names as they landed (`with_at` in 8f99fcaf, `IMPORT_DOTNEST`/`IMPORT_WHOLE` in 18fba03d).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `root_copies Q CMP PDIR NAME...` | function | `root_starts ROOT`, `with_at NAME PATH...`, `outside_seeds NAME` | `scripts/lib/dev-cycle-read.sh:1222-1234,1308` | Consistent in shape (output name-ref first, variadic inputs, `rc_` local prefix). Its output semantics differ (appends, not resets): F3. `root_` reads as "below ROOT" in `root_starts` but "other roots'" here; acceptable, the doc says which. |
| `IMPORT_OTHER` | global | `IMPORT_ROOTS`, `IMPORT_DOTNEST`, `IMPORT_READER_ROOTS` | `scripts/lib/dev-cycle-read.sh:1065,1088,1134` | Consistent in format, reset and memoization. Missing from contract item 9 (F2) and the inventory (F1). Name lacks the noun that its siblings carry (F6). |
| queue entry `//PATH` | data convention | parser output `//PATH` (a name below no root), the `seen` keys | `scripts/lib/dev-cycle-read.sh:1523,1648` (parser-output handlers) | Consistent: a `//PATH` queue entry is exactly a parser-output line, so `outside_proj` serves it unchanged. Docs drift (F4). |

Local names (`cq`, `nm`, `cmp`, `rc_q`, `rc_c`, `rc_p`) are private and follow the per-function prefix convention.

## Findings

#### F1. The sourcing inventory omits root_copies and IMPORT_OTHER

**Severity:** Minor
**Location:** `test/scripts/dev-cycle.bats:1111,1115`
**Move:** 3 (test drift)
**Confidence:** High
**Legibility target:** for-automated-gate

Precedent: earlier units' helpers and globals are listed in `test/scripts/dev-cycle.bats:1111,1115` (`with_at` added in 8f99fcaf, `IMPORT_DOTNEST IMPORT_WHOLE` in 18fba03d)

**Evidence:**
```
                 isclosed entry_why isimported inrepo_here main_imports nul_list import_targets instruction_names untracked_md tree_starts md_ls checkout_md main_checkout lower_all capped_read import_work import_readers import_readers_key import_outside import_file outside_ok outside_proj outside_seeds root_starts with_at; do
```
```
        for v in SKIPPED SKIP_AT MAIN MAIN_SHA MAIN_BY_NAME IMPORTED IMPORTED_DONE IMPORTED_MAIN IMPORTED_MAIN_DONE IMPORT_ROOTS IMPORT_HOMES IMPORT_READERS_DONE IMPORT_READERS_KEY IMPORT_READER_ROOTS IMPORT_READER_HOMES IMPORT_DOTNEST IMPORT_WHOLE IMPORT_MANAGED_DIR BRIEF BRIEF_ODD; do declare -p "$v" >/dev/null 2>&1 || echo "unset $v"; done
```

Every import-walk helper since U2b3a was added to this list when it landed; `root_copies` and `IMPORT_OTHER` are the only new ones not. (The list is not complete for older functions, e.g. `floor`, `truthrule`, `import_home`, so this is drift from the recent convention rather than a broken invariant.) A rename or a lost global declaration would then not fail the sourcing test. Probe: sourcing the lib defines `root_copies` and declares `IMPORT_OTHER=""`, so adding both names passes. This is the fact-check's escalation, confirmed.

**Recommendation:** Add `root_copies` to the function list at :1111 and `IMPORT_OTHER` to the variable list at :1115.

#### F2. Contract item 9 does not name IMPORT_OTHER among import_readers' results; root_copies' doc lacks the "Run it after import_readers" line

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:96-97`, `:1238-1251`
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility target:** for-author

**Evidence:**
```
#     which fails both walks; both scripts call it. Never set these yourself
#     (from the environment or after reader_settings), nor
#     IMPORT_ROOTS or IMPORT_HOMES: they are import_readers' results.
```
```
# CLAUDE_CONFIG_DIR is set but not absolute. Run it after import_readers
# (IMPORT_ROOTS, IMPORT_HOMES and IMPORT_OTHER).
```

IMPORT_OTHER now decides which roots' trees and copies both walks read (root_copies, outside_seeds' C1). On an `IMPORT_READERS_DONE` memo hit, import_readers returns before resetting it (:1088), so a caller that assigns IMPORT_OTHER between decisions changes which roots the next walk reads; that is the same hazard item 9 already names for IMPORT_ROOTS and IMPORT_HOMES. (IMPORT_DOTNEST has the same omission from item 9, already on main.) The diff also gave outside_seeds' doc an explicit "Run it after import_readers (... IMPORT_OTHER)" line, while root_copies, the new reader of IMPORT_OTHER, says only "each IMPORT_OTHER root".

**Recommendation:** Extend item 9's last sentence to "nor IMPORT_ROOTS, IMPORT_HOMES, IMPORT_DOTNEST or IMPORT_OTHER". Add "Run it after import_readers (IMPORT_OTHER)." to root_copies' doc block.

#### F3. root_copies appends to its output array, while every sibling that "gets" an array resets it

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:1240-1243` (doc), `:1252-1273` (body), call sites `:1514,1529,1597,1655`
**Move:** 7 (asymmetry), 3 (consumer contract)
**Confidence:** High
**Legibility target:** for-author

Precedent: "array NAME gets ..." means the function clears it first, in `with_at` (`scripts/lib/dev-cycle-read.sh:1226-1234`, `wa_a=()`), `outside_seeds` (`:1310`, `os_a=()`), `prompt_bases` (`:667-670`, `pb_a=("")`)

**Evidence:**
```
# key of the associative array CMP (it then is one) and each IMPORT_OTHER
# root, the array Q gets ROOT/NAME when outside_ok admits it, unless it is
```
```
  local -n rc_q="$1" rc_c="$2" rc_p="$3"; local p r i rs=() ps=() cs=() rl=() hs=() sp=(); shift 3
  [[ -n "$IMPORT_OTHER" ]] || return 0
```
(body continues to :1273; it only ever does `rc_q+=(...)` and never clears rc_q)
```
    cq=(); root_copies cq cmp pdir "${nm[@]}" || { IMPORTED=error; return 1; }
```

The doc uses the same verb ("the array Q gets") as with_at and outside_seeds, whose callers rely on a fresh array. root_copies appends instead, and its two in-loop callers compensate with `cq=()`. The code is correct today. A future caller that reads the doc the sibling way and reuses an array (as the walks reuse `sd`, `fl` and `lo`) would re-enqueue stale copies. Re-enqueueing is harmless here only because `seen` absorbs duplicates. Also, CMP and PDIR are in/out parameters, and only the doc's prose signals that.

**Recommendation:** Pick one form. (a) Clear `rc_q=()` at the top, as with_at does, and drop the two `cq=()` at the call sites. Every caller already wants a fresh array. (b) Keep appending and say "appends to the array Q", as outside_proj says "appended to OUT". (a) matches the larger precedent set.

#### F4. Docs still credit outside_seeds with the other-root reads and sha1sum; main_imports' doc misses //PATH queue entries and root_copies failures

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:42-45`, `:759-760`, `:1303-1304`, `:1545-1547`
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility target:** for-author

**Evidence:**
```
# Both walks also read the repository's worktree registry (import_readers)
# and, through outside_seeds, the config dirs (each reader home's .claude,
# CLAUDE_CONFIG_DIR, IMPORT_MANAGED_DIR), the roots' ancestors and the other
# roots' file trees (find, grep, sha1sum, python3 on installed_plugins.json);
```
```
# security F2). It returns 1 when a find, grep, sha1sum,
# realpath or lower_all fails, a seed's path holds a newline, or
```
```
# Phase 2 begins when queue empties: tq's checkout files and outside files
# (absolute paths, never main's) then join it, and a path main lacks reads the checkout.
```

These build on the fact-check's Stale verdicts (:45, :759-760, :1304). From the API side, the header's Inputs paragraph is the contract's statement of what the walks read. It still sends other-root reads (and sha1sum) through outside_seeds, which no longer calls sha1sum. root_copies, which now reads other roots' copies of every reached name, is not named there. main_imports' phase-2 comment says tq holds "absolute paths", but it now also holds `//PATH` entries and root_copies' `ROOT/NAME` copies. Its failure list (:1533-1544) does not add root_copies' realpath/sha1sum failure (outside_seeds' failures are already missing there, so that part is older drift).

**Recommendation:** In the Inputs paragraph, say other roots' trees are read by outside_seeds (find, grep) and their copies of reached names by root_copies (realpath, sha1sum). Drop sha1sum from :760 and :1304. In main_imports' phase-2 comment, mention `//PATH` (a dangling link, projected) and other roots' copies.

#### F5. IMPORT_OTHER is filled incrementally, so a refusal can leave it partly set, unlike its siblings

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1115-1118`, `:1127-1135`
**Move:** 8 (nullability / validity contract)
**Confidence:** High
**Legibility target:** for-author

**Evidence:**
```
  for i in "${!rs_x[@]}"; do
    [[ -n "${rs_real[i]//\//}" && "${rs_real[i]}" != *$'\n'* ]] || return 1
    if [[ $i -lt $n ]]; then t=r; else t=h; fi
    p="${rs_real[i]}"; [[ $t == h || "$p" == "$ROOT_REAL" || -n "${rs_seen[o$p]+set}" || ! -d "$p" ]] || { rs_seen[o$p]=1; IMPORT_OTHER+="$p"$'\n'; }
```
(loop continues to :1122; IMPORT_ROOTS and IMPORT_HOMES are assigned only after it, at :1127-1128)

IMPORT_ROOTS, IMPORT_HOMES and IMPORT_DOTNEST are all assigned after every `return 1` point, so a refusal leaves them empty, and the doc's "A refusal is memoized too, as an empty IMPORT_ROOTS" holds. IMPORT_OTHER is appended inside the checking loop, so a later root's `return 1` leaves earlier roots in it, with a trailing newline. The fact-check verified that no caller reads it after a refusal, so nothing is wrong today. The doc ("holds every root's real path but ROOT_REAL's") does not say it is valid only on success.

**Recommendation:** Collect into a local array and `printf -v IMPORT_OTHER` next to IMPORT_ROOTS at :1127, or add "(valid only when import_readers returns 0)" to its doc.

#### F6. IMPORT_OTHER lacks the noun its sibling globals carry

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1060-1062,1065`
**Move:** 2 (naming)
**Confidence:** Medium
**Legibility target:** for-author

Precedent: `IMPORT_<qualifier>_<NOUN>` for root/home lists, as in `IMPORT_READER_ROOTS`, `IMPORT_READER_HOMES` (`scripts/lib/dev-cycle-read.sh:1065`)

**Evidence:**
```
# IMPORT_OTHER holds every root's real path but ROOT_REAL's that is a
# directory here, once each, newline-separated: the roots whose copies
# root_copies and outside_seeds read.
```

Every other root/home list names what it holds (`IMPORT_ROOTS`, `IMPORT_HOMES`, `IMPORT_READER_ROOTS`). `IMPORT_OTHER` makes a reader go to the doc to learn it is a root list, and that it holds real paths only (its siblings hold both spellings). This is a naming nit with low consumer impact; the global is lib-internal in practice.

**Recommendation:** Optional: rename to `IMPORT_OTHER_ROOTS`. If renamed, do it in this unit, before F1 adds the name to the inventory.

## What Looks Good

- **`//PATH` queue entries reuse an existing convention.** A dangling-link queue entry is byte-for-byte a parser-output `//` line, so both walks set `out="$f"` and `outside_proj` projects it unchanged. root_copies (`"/$r/$p"`) and the seed loops (`p="/$p"`) produce the same spelling, so `seen` dedups the two sources.
- **The two walks are symmetric:** identical seed handling, the same root_copies call pattern before the loop and once per file, and the same `IMPORTED[_MAIN]=error` discipline (the pre-loop `|| return 1` runs after `IMPORTED=error` is already set, as for outside_seeds).
- **root_copies' signature fits the lib:** output name-ref first, `rc_` local prefix, batched `realpath -mz` and `xargs sha1sum -z` through `nul_list` with count checks, the same pattern as outside_proj and the removed outside_seeds code.
- **IMPORT_OTHER's lifecycle matches its siblings:** cleared at source time and at the top of import_readers, newline-separated with the trailing newline stripped, and memoized under the same key. outside_seeds now consumes it instead of recomputing `realpath` over IMPORT_ROOTS, so the two readers share one root set per decision.
- **The comparison rule is stated once:** root_copies' doc says it compares with rawfile's test, and outside_seeds' C1 now defers to it ("root_copies reads this copy when its bytes differ") instead of keeping its own sha1sum copy.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | Sourcing inventory omits root_copies, IMPORT_OTHER | Minor | `test/scripts/dev-cycle.bats:1111,1115` | High |
| F2 | Contract item 9 omits IMPORT_OTHER; root_copies' doc lacks "Run it after import_readers" | Minor | `scripts/lib/dev-cycle-read.sh:96-97,1238-1251` | High |
| F3 | root_copies appends to Q; siblings that "get" an array reset it | Minor | `scripts/lib/dev-cycle-read.sh:1240-1273` | High |
| F4 | Inputs paragraph and outside_seeds/main_imports docs drift (sha1sum, //PATH, root_copies) | Minor | `scripts/lib/dev-cycle-read.sh:42-45,759-760,1303-1304,1545-1547` | High |
| F5 | IMPORT_OTHER partly filled on refusal | Informational | `scripts/lib/dev-cycle-read.sh:1115-1118` | High |
| F6 | IMPORT_OTHER lacks a noun | Informational | `scripts/lib/dev-cycle-read.sh:1065` | Medium |

## Overall Assessment

The change follows the lib's conventions. The new function and global match their neighbors in argument order, name-ref binding, NUL-list batching, return codes, reset and memoization, and the `//PATH` queue entry reuses the parser's own convention rather than inventing one. Nothing breaks a consumer: the walks' signatures, globals and return semantics are unchanged for build-loop.sh and dev-cycle.sh. The findings are all fixable in place and small. Two are drift in the contract text and the inventory test, which recent units kept current (F1, F2, F4). One is a doc/semantics mismatch: "array Q gets" means reset elsewhere but append here (F3). F1 and F3 are the ones worth fixing before merge, because a later caller or test would read them the sibling way.

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown report saved to /workspace/.claude/wt-build-loop-u2b3b2c/docs/reviews/api-consistency-review-2026-10-09-u2b3b2c-i1.md, structured per the api-consistency-reviewer skill, with `Commit: f7e1bea2` as its first line."
- **Answered:** Iteration 1 API-consistency review of the full branch diff. It covers root_copies vs siblings, IMPORT_OTHER vs the IMPORT_* globals and contract items 4/9, the `//PATH` convention in both places, the sourcing inventory and doc consistency. 4 Minor, 2 Informational, no Breaking or Inconsistent.
- **Out of scope:** Security and fail-open analysis of the copy comparison (security critic); performance of the per-file root_copies calls (performance critic); the untested dangling and byte-equal branches the fact-check found (test/fact-check scope). Considered-override rows 580-589 were not re-filed.
- **Escalate:** None beyond F1, which confirms the fact-check's orchestrator escalation.
- **Decisions:** For F3 the review recommends option (a), resetting Q in root_copies, to match the larger precedent set.
