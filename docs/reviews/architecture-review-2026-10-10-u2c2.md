Commit: 3111ee9d

# Architecture Review — feat/build-loop-u2c2 (U2c2, the walk side)

**Scope:** `git diff main...HEAD` (one commit, 3111ee9d): `scripts/lib/dev-cycle-read.sh`, `scripts/build-loop.sh`, `test/scripts/build-loop-check.bats`
**Date:** 2026-10-10
**Based on:** `docs/reviews/code-fact-check-report.md` (Commit 3111ee9d, 36 claims); the shared brief for U2c2 iteration 1; the trust-boundary map of `docs/reviews/security-review-2026-10-10-u2c1.md` (Commit: `eddfd5f9`). That security review predates this diff, so its boundaries may be stale.

**Scope check:** in scope. The diff touches all four trigger categories:
- Module structure: a new function, `c1_seeds`, is split out of `outside_seeds`.
- Public API: floor gains an optional `$4`, and need_root moves, which changes the gate caller contract (header items 4, 8 and the need_root paragraph).
- Data model: the walk cache keys gain IMPORT_CONFIGS, and the new IMPORTED_MAIN_WHY uses a "KIND PATH" vocabulary that floor parses.
- Cross-cutting concerns: the root check (need_root) and caching (the import_readers memo key).

## Dependency Map

- `scripts/build-loop.sh` `srules` calls `floor` in the lib. The lowered path, which check_line computes with `lower_all`, now crosses that call as `$4`. This call sits on trust boundary `B2` (`[changed path, N rules passed] → [srules: floor → …]`).
- Inside the lib, `floor` calls `truthrule`, then `truthwalk main`, which calls `main_imports`. `main_imports` calls `import_readers`, which now owns IMPORT_CONFIGS, then `outside_seeds`, which calls `c1_seeds`, then `root_copies`. floor then reads `IMPORTED_MAIN_WHY` directly, a global main_imports writes. That is a new direct edge from floor to main_imports' state, which goes around truthwalk.
- `scripts/dev-cycle.sh` `check_fix` calls `truthwalk tree`, which calls `imported_names`, which follows the same import_readers → outside_seeds → c1_seeds path. The tree walk has no WHY.
- Direction:
  - The volatile wording (floor's sentences) depends on the stable walk vocabulary (IMPORTED_MAIN_WHY kinds). That direction is right.
  - The environment discovery (`import_readers`) is now the one source that both seed listing (`outside_seeds`) and the cache keys depend on. That is also right, and an improvement on main, where outside_seeds read the environment itself.
  - No cycles are introduced.

## Findings

#### 1. need_root now runs after import_readers in main_imports: the root check depends on statement order and differs between the two walks

**Severity:** Coupling
**Location:** `scripts/lib/dev-cycle-read.sh:1654-1657` (main_imports), `:1579-1582` (imported_names), `:18-22` (header contract)
**Move:** 4 (layer violations: a precondition check moved below a reader), 3 (module boundary: caller contract)
**Confidence:** High
**Legibility-target:** maintainer of the gate caller contract and of the walks' cache-check ordering; security reviewer weighing `B5`

Evidence:
```bash
# scripts/lib/dev-cycle-read.sh:1654-1657
  import_readers || { IMPORTED_MAIN_DONE=""; IMPORTED_MAIN=error; IMPORTED_MAIN_WHY=readers; return 1; }
  [[ "$IMPORTED_MAIN_DONE" == "$MAIN_SHA $MAIN_BY_NAME $IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES"$'\n\n'"$IMPORT_CONFIGS" ]] && { [[ "$IMPORTED_MAIN" != error ]]; return; }
  # Below the cache check: a hit reads nothing here, so floor's cached calls fork no root check (U2c1 final performance 1).
  need_root
```
(excerpt ends :1657; main_imports continues to :1779 — read)
```bash
# scripts/lib/dev-cycle-read.sh:1579-1580 (imported_names, unchanged order)
  need_root
  import_readers || { IMPORTED_DONE=""; IMPORTED=error; return 1; }
```
```bash
# scripts/lib/dev-cycle-read.sh:22-24 (header)
# check_brief, isimported and the import walks (main_imports on a cache miss;
# truthwalk and floor through it) exit 1 (need_root) unless
# ROOT_REAL is set, is the current directory and is a repository's top level;
```

Override row 618 asked for main_imports' need_root to move "below its cache check". The edit went one step further and also moved it below `import_readers`. import_readers is not a pure memo lookup. On a memo miss it runs `git worktree list`, getent and realpath in the current directory, and it refuses an empty ROOT_REAL with `return 1`. The fact-check (Claim 2, executed) found two consequences:
- With ROOT_REAL unset, main_imports and floor no longer exit as the header promises. floor refuses with the `readers` wording instead, which names the wrong cause.
- On an import_readers miss, the registry is read from a cwd that has not been checked.

The precondition now holds only because of where the call sits inside main_imports. The two parallel walks also order it differently, so a maintainer who copies main_imports' shape into imported_names (for the tree walk's own per-path cost, as Claim 17 shows) moves the same hazard there. This is not a correctness break: the result still fails closed. It is a contract that callers (`build-loop.sh`, and any second caller per contract item 7) can no longer read off the header.

**Recommendation:** Put the root check where the reading happens, on the miss paths only. need_root goes at the top of import_readers' memo-miss branch, where it already forks git, and stays below main_imports' cache check. A fork-free `[[ -n "${ROOT_REAL:-}" ]] || need_root` guard goes at main_imports' entry for the unset case. Then give imported_names the same order, so that both walks share one rule: "the root check runs whenever anything is read".
**Security implication:** none from the recommendation itself. It restores the B5 ordering the security review assumed ("checkout_gate, then floor's import walk", `B5` from `docs/reviews/security-review-2026-10-10-u2c1.md`, Commit `eddfd5f9` — security review predates this diff; boundary may be stale), and it does not relocate it.

#### 2. outside_seeds split: c1_seeds is a real unit, but the wrapper is fused with the config seeds, and row 589's nameref hazard grew

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:1396-1402`, `:1454-1461`; stale references at `:1602`, `:1704`
**Move:** 2 (responsibility boundaries), 7 (coupling: dynamic-scope nameref)
**Confidence:** High
**Legibility-target:** maintainer of outside_seeds/c1_seeds; whoever closes override rows 582, 585, 589 and 603

Evidence:
```bash
# scripts/lib/dev-cycle-read.sh:1396-1400 (doc)
# security F2). Items (1) and (2) are its own; (3) is c1_seeds' (rows 582,
# 589), and each keeps its own keep-rule. It returns 1 when a find, grep,
# realpath or lower_all fails, or a seed's path holds a newline. Run it after
# import_readers (IMPORT_ROOTS, IMPORT_CONFIGS and IMPORT_OTHER). NAME must
# not be one of its locals or c1_seeds' (a nameref to one reads that local).
```
```bash
# scripts/lib/dev-cycle-read.sh:1454-1456
  c1_seeds os_a || return 1
  for d in "${os_a[@]}"; do [[ "$d" != *$'\n'* ]] || return 1; done
}
```
Row 603: "The outside_seeds split (i1 A8, config_seeds and c1_seeds) was reverted to stay under the 400-line cap; row 582's split is still owed". Row 589: "a caller passing one of outside_seeds' or with_at's own local names gets an empty array".

What the unit delivered:
- c1_seeds has its own locals, its own keep-rule (`c1_at`) and its own doc.
- It depends only on IMPORT_OTHER and ROOT_REAL, not on outside_seeds' state.
- Row 585's phase-crossing worry (shared `lo`/`cx` arrays and the early-return newline check) is gone, because the arrays are now separate locals and the newline check scans after c1_seeds appends (fact-check Claim 15).

What is missing:
- **The wrapper is still fused with the config seeds.** outside_seeds is still config seeding plus the orchestration tail (the C1 call and the newline check). A reader cannot see the three-source structure from a short top-level function.
- **The nameref hazard is wider than before.** NAME is passed through `c1_a → os_a → NAME`, and bash resolves that chain dynamically inside c1_seeds. A caller's array name must now avoid the union of both functions' locals (`d q r c i in cr cx ir lo fl` and the rest), where before it had to avoid only one set. Row 589 asked for this hazard to shrink.

The line-cap reason does not cover the wrapper. Renaming outside_seeds' body to `config_seeds` and adding a short `outside_seeds` that runs `config_seeds os_a; c1_seeds os_a; newline check` moves no body lines: about five changed lines. It would also confine the nameref chain to the wrapper's few locals.

Two comments still call the C1 code "outside_seeds' C1 part" (`:1602`, `:1704`).

**Discharge verdict:** acceptable as a partial discharge of rows 582, 585 and 603. Row 589's nameref half is not discharged; it got worse. Row 582's "seed admission repeats across four loops" is untouched (the four `find` blocks at `:1428-1441`).

**Recommendation:** Either add the five-line wrapper now (config_seeds and c1_seeds become siblings, and the wrapper's few locals become the only names NAME must avoid), or file an override row naming the residue: the fused wrapper, the widened hazard, and the four-loop admission. Fix the two stale "C1 part" comments either way.

#### 3. The walk-failure wording is a second inline word-to-sentence table in floor, unlike the lib's own pattern (entry_why, oddwhy), and check_fix cannot share it

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:1885-1901` (floor); `scripts/dev-cycle.sh:186-187` (check_fix); prior art `scripts/lib/dev-cycle-read.sh:308-318` (oddwhy), `:364-374` (entry_why)
**Move:** 8 (extension points), 2 (responsibility)
**Confidence:** High
**Legibility-target:** whoever adds a new main_imports failure KIND, or gives the tree walk a WHY; U3 author picking up row 472

Evidence:
```bash
# scripts/lib/dev-cycle-read.sh:1886-1889, 1899-1901 (floor; arms elided between)
    case "$TRUTH_WHY ${IMPORTED_MAIN_WHY%% *}" in
      imported*) FLOOR_WHY="an instruction or prompt file (on the default branch, or only in the checkout) imports it with @ (directly or through another import)" ;;
      *" readers") FLOOR_WHY="the worktree registry could not be read, or a reader root or home or CLAUDE_CONFIG_DIR is not an absolute path"
        [[ -z "$IMPORT_READER_WHY" ]] || FLOOR_WHY="the reader settings of docs/dev-cycle.md cannot be used: $IMPORT_READER_WHY" ;;
      ...
      *) FLOOR_WHY="" ;;
    esac
    [[ "$TRUTH_WHY" != walk ]] || FLOOR_WHY="the default branch's instruction files could not be walked for @ imports${FLOOR_WHY:+: $FLOOR_WHY}"
```
```bash
# scripts/dev-cycle.sh:186-187 (check_fix, unchanged)
    if [[ "$TRUTH_WHY" == walk && -n "$IMPORT_READER_WHY" ]]; then echo "skip $a: the instruction-file import walk failed, so an import of it cannot be ruled out: the reader settings of docs/dev-cycle.md cannot be used: $IMPORT_READER_WHY; file it instead"
    elif [[ "$TRUTH_WHY" == walk ]]; then echo "skip $a: the instruction-file import walk failed, so an import of it cannot be ruled out; file it instead"
```
The KIND vocabulary is now written in three places:
- defined in the IMPORTED_MAIN_WHY comment (`:791-797`);
- produced across main_imports;
- worded by an 11-arm case statement inside floor.

floor now holds two such tables: truthrule's words at `:1872-1879`, and this one. Each new KIND means an edit in floor, and the `*) FLOOR_WHY=""` fallback hides a missed edit: the refusal still prints, but with no "where". The lib already turns a word into a sentence in a named function (`entry_why`, `oddwhy`), next to the code that defines the words. check_fix already copies floor's `IMPORT_READER_WHY` sentence, and it would copy the whole table if the tree walk gained a WHY.

This does not preempt row 472, which U3 owns. That row is about FLOOR_WHY itself being words. A walk-WHY wording function is the narrower move, and it makes U3's job smaller.

**Recommendation:** Extract `walk_why WHY` (KIND → sentence, including the IMPORT_READER_WHY sub-case) beside the IMPORTED_MAIN_WHY comment, so floor's arm becomes one call. When the tree walk gets a WHY, check_fix calls the same function. While there, apply fact-check Claims 21 and 23-25's wording fixes in one place.

#### 4. IMPORTED_MAIN_WHY as stage markers: every new `return 1` silently inherits the current stage, and floor reads the main walk's global around truthwalk's abstraction

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:1659-1716` (markers), `:1885` (floor reads it), `:1819-1833` (truthwalk)
**Move:** 7 (coupling surface), 3 (module boundary)
**Confidence:** Medium
**Legibility-target:** maintainer adding a failure path to main_imports; maintainer of truthwalk's caller-facing contract (row 418)

Evidence:
```bash
# scripts/lib/dev-cycle-read.sh:1659-1660, 1681, 1696, 1706, 1716
  IMPORTED_MAIN_WHY=main; main_by_name || return 1
  IMPORTED_MAIN_WHY=tree
  IMPORTED_MAIN_WHY=list
  IMPORTED_MAIN_WHY=seeds
  IMPORTED_MAIN_WHY=copies
    IMPORTED_MAIN_WHY="read $f"
```
```bash
# scripts/lib/dev-cycle-read.sh:1819-1823 (truthwalk doc)
# truthwalk WALK PATH: runs the import walk WALK (tree for --check-fix, main
# for floor), then asks it about PATH, lower-cased (contract item 8), as
# isimported WALK PATH does but with no fork (isimported's lower and root
# check cost floor ~1 ms a path: U2c1 final performance 1), so a caller
# words a failed walk without knowing the order (override row 418).
```

Setting a marker at each stage plus an override at a few named failures (`link`, `start`, `admit`, `budget`) is a pragmatic shape. It cost about a dozen lines against roughly 35 return sites, and fact-check Claim 9a mapped every return. The cost is that attribution is implicit, and the fact-check already found four drifts: a parser output overrun reports `read` (9b, 23), a newline name reports `list`, and a failed seed `lower` reports `seeds` (25). Each new `|| return 1` added later inherits whatever marker is current, and nothing in main_imports' doc says so.

There is a second, separate problem. Row 418 made truthwalk the thing a caller asks so that it can "word a failed walk without knowing the order". floor now also has to know that `truthwalk main` means `main_imports`, and that main_imports' where is in `IMPORTED_MAIN_WHY`. The abstraction leaks for main, and the tree walk has no equivalent.

**Recommendation:** Keep the stage markers, but add one line to the IMPORTED_MAIN_WHY doc: "a return without its own assignment reports the current stage". Have truthwalk copy the walk's where into its own output (for example `TRUTH_WHERE`, empty for the tree walk until it records one), so floor and check_fix read one truthwalk result rather than a walk's internal global.

#### 5. truthwalk copies isimported's membership predicate: two definitions of "the walk reached this path"

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:1785-1794` (isimported), `:1827-1833` (truthwalk)
**Move:** 2 (responsibility), 7 (coupling)
**Confidence:** High
**Legibility-target:** whoever acts on rows 470/611 (an associative membership set), or changes the walk list's format

Evidence:
```bash
# scripts/lib/dev-cycle-read.sh:1790-1791 (isimported)
    main) main_imports || return 0; [[ "$IMPORTED_MAIN" == *$'\n'"$lp"$'\n'* ]] ;;
    tree) imported_names || return 0; [[ "$IMPORTED" == *$'\n'"$lp"$'\n'* ]] ;;
```
```bash
# scripts/lib/dev-cycle-read.sh:1829-1831 (truthwalk)
  case "$1" in main) main_imports || return 0; local -n tw_l=IMPORTED_MAIN ;; tree) imported_names || return 0; local -n tw_l=IMPORTED ;; *) return 0 ;; esac
  TRUTH_WHY=imported
  [[ "$2" != *[ABCDEFGHIJKLMNOPQRSTUVWXYZ]* && "$tw_l" != *$'\n'"$2"$'\n'* ]] || return 0
```

Before this diff, truthwalk delegated to isimported, so the lib had one definition of membership and the walk dispatch. Now the walk-name dispatch (`main`/`tree`/other) and the newline-delimited glob test each exist twice, and their case contracts differ: isimported lowers, while truthwalk refuses upper case as imported. Rows 470 and 611 keep an associative per-walk set open "if a walk list near the cap is ever measured". That change, or any change to the list format (the `//` second-channel names already share it), now needs two matching edits. A missed one would make floor and isimported disagree about the same path. The reason for the copy was the cost of isimported's `lower` fork and need_root, and that is valid; but the cost lives in isimported's preamble, not in the predicate.

**Recommendation:** Extract the fork-free core, for example `walk_has WALK LP` (dispatch, run the walk, glob test), and use it in both functions. isimported keeps `need_root` and `lower`, then calls the core. truthwalk keeps its upper-case refusal and TRUTH_WHY, then calls the core.

#### 6. floor's optional `$4` replaces `$1` rather than adding to it: the signature carries two forms of one datum, and floor trusts that they agree

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1854-1856`, `:1868-1870`; `scripts/build-loop.sh:668`
**Move:** 3 (module boundary), 5 (interface shape)
**Confidence:** Medium
**Legibility-target:** srules maintainer; any second floor caller

Evidence:
```bash
# scripts/lib/dev-cycle-read.sh:1868-1870
  local lp="${4-}" d
  FLOOR_WHY=""
  [[ -n "$lp" ]] || lp="$(lower "$1")" || { FLOOR_WHY="the path could not be lower-cased"; return 0; }
```
(excerpt ends :1870; floor continues to :1907 — read)

When `$4` is given, floor never reads `$1`. Override row 610 asked for "a floor entry that takes check_line's lowered path", and an optional trailing positional that replaces the first is the loosest form of that. Nothing ties the two forms together: fact-check Claim 19 notes that floor trusts `$4`. The call sits on `B2` (`[changed path, N rules passed] → [srules: floor → …]`, from `docs/reviews/security-review-2026-10-10-u2c1.md`, Commit `eddfd5f9` — security review predates this diff; boundary may be stale). There is only one caller, and check_line computes `$4` with `lower_all` over the same list, so there is no present harm.

**Recommendation:** State in floor's doc that `$4` must equal `lower $1` and that `$1` is then unused. Or, when a second caller appears, split floor into `floor_lp STEM STATUS LP` with a thin `floor` that lowers. No change to the boundary is implied.

#### 7. New lib state is missing from the contract's results list and from the lib's surface inventory; the walk cache key is hand-assembled in four places

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:101-104` (contract item 9), `:1582-1583`, `:1655`, `:1658`; `test/scripts/dev-cycle.bats:1110-1113`
**Move:** 3 (public surface)
**Confidence:** High
**Legibility-target:** gate caller-contract readers; maintainer of the lib's sourcing test

Evidence:
```bash
# scripts/lib/dev-cycle-read.sh:1582 and :1655 (the same three-part key, built separately, in each walk's check and again in its set)
  [[ "$IMPORTED_DONE" == "$IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES"$'\n\n'"$IMPORT_CONFIGS" ]] && ...
  [[ "$IMPORTED_MAIN_DONE" == "$MAIN_SHA $MAIN_BY_NAME $IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES"$'\n\n'"$IMPORT_CONFIGS" ]] && ...
```
```bash
# test/scripts/dev-cycle.bats:1112 (function inventory; no c1_seeds, no truthwalk)
                 isclosed entry_why isimported inrepo_here main_imports ... outside_proj outside_seeds root_starts with_at root_copies prompt_marks; do
```

- IMPORT_CONFIGS is a new import_readers result, but contract item 9's "never set" list omits it (fact-check Claim 5).
- The walk-cache doc paragraphs are stale (Claims 6 and 7).
- The sourcing test's function and global inventories lack `c1_seeds`, `IMPORT_CONFIGS` and `IMPORTED_MAIN_WHY`.
- Each walk key grew a part by editing four strings. A fourth reader-set result would need the same four edits.

**Recommendation:** Add IMPORT_CONFIGS to item 9, and the new names to the inventory test. Optionally, have import_readers publish one result signature (for example `IMPORT_READERS_SIG`, built once beside IMPORT_CONFIGS), which both walks key on.

## What Looks Good

- **IMPORT_CONFIGS in import_readers is the right layer (row 581).** import_readers is the lib's environment-discovery step: roots, homes, other roots, dotnest. The config-dir list is derived from the same homes plus two environment values, so it belongs there. Moving it there:
  - gives one memo key that holds all of its inputs (CLAUDE_CONFIG_DIR set-ness and value, IMPORT_MANAGED_DIR);
  - lets both walk caches key on the result;
  - removes a reset duty from contract item 4, so the caller contract gets smaller.

  outside_seeds is now a pure consumer of the reader set. That completes the direction H5/A1 started, where import_targets stopped falling back on its own reader logic. The CLAUDE_CONFIG_DIR validation moved with it, so a refusal is decided once per reader set. Equivalence with main's computation is verified (fact-check Claim 11).
- **c1_seeds is independent.** Its only inputs are IMPORT_OTHER and ROOT_REAL. It has its own keep-rule and its own `c1_at` set, so the phase-crossing state row 585 found cannot recur between the two seed sources.
- **The below-a-start-name check is floor-only, not in truthrule.** It is an availability rule (a directory blocks the file), not a read-as-truth rule, so keeping it out of the rule check_fix shares preserves rows 204/322/348's shared-rule boundary. Declining the import-name half for the documented reason (parser prefixes, Claim 31) avoids a rule that would refuse every path under `docs/`.
- **main_imports' failure state follows its cache.** IMPORTED_MAIN_WHY is empty after a success and kept with a cached failure (Claim 9c), so one floor decision sees one consistent reason.
- **prompt_marks is extended, not forked, for F3.** One function now covers both dangling (`//`) and live absolute prompt entries, and both walks changed the same guard in the same way.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | need_root moved below import_readers: root check is order-dependent and differs between walks; header contract broken | Coupling | `dev-cycle-read.sh:1654-1657`, `:1579-1582`, `:18-22` | High |
| 2 | outside_seeds split partial: wrapper fused with config seeds; row 589's nameref hazard widened; stale "C1 part" comments | Minor | `dev-cycle-read.sh:1396-1402`, `:1454-1461`, `:1602`, `:1704` | High |
| 3 | walk-failure wording is an inline case statement in floor, not a word-to-sentence function like entry_why/oddwhy; check_fix copies part of it | Minor | `dev-cycle-read.sh:1885-1901`; `dev-cycle.sh:186-187` | High |
| 4 | IMPORTED_MAIN_WHY stage markers attribute new returns implicitly; floor reads the main walk's global around truthwalk | Minor | `dev-cycle-read.sh:1659-1716`, `:1885` | Medium |
| 5 | truthwalk copies isimported's walk dispatch and membership predicate | Minor | `dev-cycle-read.sh:1790-1791`, `:1829-1831` | High |
| 6 | floor's `$4` replaces `$1`; two forms of one datum, trusted to agree (on B2) | Informational | `dev-cycle-read.sh:1868-1870` | Medium |
| 7 | IMPORT_CONFIGS missing from contract item 9 and the inventory test (with c1_seeds, IMPORTED_MAIN_WHY); key built in four places | Informational | `dev-cycle-read.sh:101-104`, `:1582`, `:1655`; `dev-cycle.bats:1112` | High |

## Overall Assessment

The unit improves the lib's structure on balance:
- the reader environment now has one owner and one key;
- the C1 seeds are an independent unit;
- the main walk reports where it failed.

The one structural concern worth fixing in this loop is Finding 1. To keep cached floor calls fork-free, need_root moved below a call that reads the repository on a miss, so the header's "exits through need_root" promise no longer holds and the two walks now disagree on the order. It is fixable in place with a few lines (a root check on import_readers' miss path and a fork-free unset guard), and it fails closed meanwhile.

The rest are fixable in place, and cheap. Findings 2 and 5 each take about five lines (a wrapper; a shared membership core). Finding 3 is a function extraction that also gives U3 and check_fix a shared vocabulary.

I have no disagreement with the security review's boundary placement. Findings 1 and 6 sit on `B5` and `B2` respectively, and neither recommendation relocates a crossing.

## Goal-Alignment Note

The goal is to land U2c2 after a clean review-fix loop. Five of the six plan items are structurally sound as built:
- floor's cost;
- IMPORTED_MAIN_WHY;
- the below-a-start check;
- F3;
- IMPORT_CONFIGS.

The sixth, the outside_seeds split, is a partial discharge of rows 582/585/589/603. It is acceptable if the residue is named in an override row, though the wrapper is cheap enough to finish (Finding 2).

Before merge, the loop should resolve Finding 1 (Coupling, the 🟡 Must Address tier): either restore the root check ahead of anything import_readers reads on a miss, or rewrite the header contract to match. Findings 2-7 are 🟢 Consider items that can be fixed now or recorded as override rows. Finding 3 is the one that most reduces U3's work.
