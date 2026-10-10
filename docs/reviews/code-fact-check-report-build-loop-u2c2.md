# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2c2 (branch `feat/build-loop-u2c2`)
**Scope:** branch diff `main...HEAD` (one commit): `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-check.bats`, and commit 3111ee9d's message
**Commit:** 3111ee9d
**Replication:** k=1 (loop pass, decision 031)
**Checked:** 2026-10-10
**Total claims checked:** 36
**Summary:** 22 verified, 9 mostly accurate, 2 stale, 2 incorrect, 1 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`). Claim 30a matches the prior pattern "mode1-equiv 33 claimed in commit 37c5ea9's test tally", where a commit message's test tally did not match the count. The log is not updated in this pass, because the brief allows writing only this report.

Execution logs (scratchpad, outside the repo): `/tmp/claude-1000/-workspace/843b51ad-a12f-4e61-b040-53f5def15aef/scratchpad/u2c2-review/fc1-bats.log` (probe `fc1-probe-bats.sh`, run 2026-10-10T16:20:07Z, exit 0), `.../fc1-floor.log` (probe `fc1-probe-floor.sh`, run 2026-10-10T16:20:38Z, exit 0), `.../fc1-tw.log` (probe `fc1-probe-tw.sh`, run 2026-10-10T16:22:03Z, exit 0). Each probe ran from `/workspace/.claude/wt-build-loop-u2c2` as cwd and used `bash <probe>`. Each built a throwaway repo in its own `fc1-XXXX` temp dir and removed it afterwards. "main's lib" means `git show main:scripts/lib/dev-cycle-read.sh`.

---

## Claim 1: "$3 its lower-cased spelling" (srules passes it to floor as $4)

**Location:** `scripts/build-loop.sh:655-668`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that srules' fourth floor argument is check_line's `lower_all` output for the same path. Does not establish that every other floor caller passes a lowered `$4` (the bats `floors` helper passes none, so floor lowers there).
**Legibility-target:** maintainer of srules / floor's argument order

```bash
# scripts/build-loop.sh:668
  if [[ -z "$5" ]] && floor "$2" "$1" "$4" "$3"; then DENY="$FLOOR_WHY"; return 0; fi
```
```bash
# scripts/build-loop.sh:836,841
  if ! nul_list lps lower_all "${ps[@]}" || [[ ${#lps[@]} -ne ${#ps[@]} ]]; then echo "refuse $a: ..."; return; fi
    [[ -n "$DENY" || "$pol" != self-merge || "$p" == "$a" ]] || srules "$stem" "$p" "${lps[$i]}" "${ss[$i]}" "$co"
```
(excerpt ends :841; check_line continues to :845 — read)

**Evidence:** `scripts/build-loop.sh:655-668`, `scripts/build-loop.sh:836-841`

---

## Claim 2: "inrepo, dirok, skipped, check_brief, isimported and the import walks (main_imports on a cache miss; truthwalk and floor through it) exit 1 (need_root) unless ROOT_REAL is set, is the current directory and is a repository's top level"

**Location:** `scripts/lib/dev-cycle-read.sh:18-22`
**Type:** Behavioral / Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers main_imports and floor when ROOT_REAL is unset (no cached walk), compared with main's lib. Does not establish behavior for inrepo/dirok/skipped/check_brief/isimported/imported_names, which are unchanged and still run need_root first.
**Legibility-target:** callers of the gate contract (build-loop.sh, future second callers); api-consistency critic

main_imports now calls import_readers before need_root. import_readers refuses an empty ROOT_REAL with `return 1`, so the walk returns before need_root can run:

```bash
# scripts/lib/dev-cycle-read.sh:1654-1657
  import_readers || { IMPORTED_MAIN_DONE=""; IMPORTED_MAIN=error; IMPORTED_MAIN_WHY=readers; return 1; }
  [[ "$IMPORTED_MAIN_DONE" == "$MAIN_SHA $MAIN_BY_NAME $IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES"$'\n\n'"$IMPORT_CONFIGS" ]] && { [[ "$IMPORTED_MAIN" != error ]]; return; }
  # Below the cache check: a hit reads nothing here, so floor's cached calls fork no root check (U2c1 final performance 1).
  need_root
```
(excerpt ends :1657; main_imports continues to :1779 — read)
```bash
# scripts/lib/dev-cycle-read.sh:1124
  [[ -n "${ROOT_REAL:-}" && -z "$IMPORT_READER_WHY" ]] || return 1
```

Probe A (fc1-floor.log) gave these results with ROOT_REAL unset:
- New lib: `floor` → `rc=0 out=refused: the default branch's instruction files could not be walked for @ imports: the worktree registry could not be read, or a reader root or home or CLAUDE_CONFIG_DIR is not an absolute path`.
- New lib: `main_imports` → `rc=0 out=ret1 why=[readers]`.
- main's lib: both → `rc=1 ... ROOT_REAL is not set`.

So with ROOT_REAL unset, the main walk and floor return 1 and fail closed. They do not exit through need_root, and floor gives a reason that misnames the cause. The cwd sub-claim is also partly affected. When ROOT_REAL is set but is not the cwd, and import_readers' memo misses, `git worktree list` runs in the cwd before the root check (`:1126`). need_root exits only if main_imports' cache then misses as well.

**Evidence:** `scripts/lib/dev-cycle-read.sh:18-22`, `:1114-1126`, `:1650-1658`; fc1-floor.log (sections A, A2)

---

## Claim 3: Contract item 4: "neither walk's cache key holds them (both hold import_readers' roots, homes and config dirs, so HOME, IMPORT_READER_*, CLAUDE_CONFIG_DIR and IMPORT_MANAGED_DIR need no reset ...)"

**Location:** `scripts/lib/dev-cycle-read.sh:70-76`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that both walk keys hold IMPORT_CONFIGS and that the import_readers key holds CLAUDE_CONFIG_DIR (set-ness and value) and IMPORT_MANAGED_DIR. CLAUDE_CONFIG_DIR is exercised by a test. Does not establish the IMPORT_MANAGED_DIR change at runtime (static only), or that IMPORT_OUT_MAX/IMPORT_WORK_MAX changes are caught (they are not, as the item says).
**Legibility-target:** gate caller-contract readers

```bash
# scripts/lib/dev-cycle-read.sh:1111-1112
  local f="${CLAUDE_CONFIG_DIR+x}${CLAUDE_CONFIG_DIR-}" g="$IMPORT_MANAGED_DIR"
  IMPORT_READERS_KEY="${#a}:$a ${#b}:$b ${#c}:$c ${#d}:$d ${#e}:$e ${#f}:$f ${#g}:$g"
```
```bash
# scripts/lib/dev-cycle-read.sh:1582, 1655
  [[ "$IMPORTED_DONE" == "$IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES"$'\n\n'"$IMPORT_CONFIGS" ]] && ...
  [[ "$IMPORTED_MAIN_DONE" == "$MAIN_SHA $MAIN_BY_NAME $IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES"$'\n\n'"$IMPORT_CONFIGS" ]] && ...
```
The new bats test "both walks key on the config dirs" passes on this lib and fails on main's (fc1-bats.log).

**Evidence:** `scripts/lib/dev-cycle-read.sh:70-76`, `:1109-1113`, `:1582-1583`, `:1655-1658`; `test/scripts/build-loop-check.bats:482-496`; fc1-bats.log

---

## Claim 4: Contract item 8: "Pass truthrule, truthwalk, isstart, prompt_dir and prompt_bases a lower-cased path (... floor lowers first unless its caller passes the lowered path, and check_fix and the walks lower first; truthrule refuses an upper-case letter as case, truthwalk as imported)"

**Location:** `scripts/lib/dev-cycle-read.sh:91-96`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers floor's `$4` path, check_fix's lowering before `truthwalk tree`, and truthwalk's upper-case answer. Does not establish that a caller's `$4` actually equals `lower($1)`, since floor trusts it.
**Legibility-target:** gate caller-contract readers

```bash
# scripts/dev-cycle.sh:181,185
  if ! lp="$(lower "$a")"; then echo "skip $a: the path could not be lower-cased; file it instead"; return; fi
  elif truthwalk tree "$lp"; then
```
```bash
# scripts/lib/dev-cycle-read.sh:1831
  [[ "$2" != *[ABCDEFGHIJKLMNOPQRSTUVWXYZ]* && "$tw_l" != *$'\n'"$2"$'\n'* ]] || return 0
```
In fc1-tw.log, `truthwalk tree Docs/A.md` and `truthwalk main Docs/A.md` each answer `0 [imported]`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:91-96`, `:1827-1833`, `:1867-1870`; `scripts/dev-cycle.sh:176-191`; fc1-tw.log

---

## Claim 5: Contract item 9: "Never set ... IMPORT_ROOTS, IMPORT_HOMES, IMPORT_DOTNEST or IMPORT_OTHER: they are import_readers' results, which a cache hit does not recompute"

**Location:** `scripts/lib/dev-cycle-read.sh:101-104`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the list of import_readers' results. Does not establish anything beyond that list.
**Legibility-target:** gate caller-contract readers

IMPORT_CONFIGS is now an import_readers result too, but the list leaves it out:
```bash
# scripts/lib/dev-cycle-read.sh:1163-1164
  for p in "${rs_h[@]}"; do [[ "$p" != /* ]] || IMPORT_CONFIGS+="${p%/}/.claude"$'\n'; done
  IMPORT_CONFIGS+="${CLAUDE_CONFIG_DIR:+$CLAUDE_CONFIG_DIR$'\n'}$IMPORT_MANAGED_DIR"
```
A precise version would read "IMPORT_ROOTS, IMPORT_HOMES, IMPORT_DOTNEST, IMPORT_OTHER or IMPORT_CONFIGS".

**Evidence:** `scripts/lib/dev-cycle-read.sh:101-104`, `:1121`, `:1163-1164`

---

## Claim 6: imported_names doc: "One result is cached, for the root in IMPORTED_DONE, keyed on import_readers' roots (ROOT_REAL first) and homes"

**Location:** `scripts/lib/dev-cycle-read.sh:697-699`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the key's parts. Does not establish anything else in that paragraph.
**Legibility-target:** maintainer of the tree walk's cache

The key now also holds the config dirs (`:1582-1583`, quoted in Claim 3: `"$IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES"$'\n\n'"$IMPORT_CONFIGS"`). This paragraph was not updated. It should say "roots, homes and config dirs (IMPORT_CONFIGS)".

**Evidence:** `scripts/lib/dev-cycle-read.sh:697-699`, `:1582-1583`

---

## Claim 7: main_imports doc: "the result is cached for the commit, MAIN_BY_NAME and import_readers' roots and homes in IMPORTED_MAIN_DONE"

**Location:** `scripts/lib/dev-cycle-read.sh:729-731`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the key's parts. Does not establish the "never the checkout" half, which still holds.
**Legibility-target:** maintainer of the main walk's cache

The main walk's key (`:1658`) now ends `$'\n\n'"$IMPORT_CONFIGS"`, so the key also holds the config dirs. This doc does not mention them.

**Evidence:** `scripts/lib/dev-cycle-read.sh:729-733`, `:1655-1658`

---

## Claim 8: Walk doc: "a prompt's projected names, a live link's too (U2b3b2c final security F3), are read as prompts with the link's bases", and F3 is removed from the "Named exceptions" list

**Location:** `scripts/lib/dev-cycle-read.sh:761-775`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the probe-PC scenario (a live `.claude/commands/k.md` link in another worktree, pointing at an older `docs/t.md`) for both walks. Does not establish a live link whose real path lies in the same root, or a live link to a target under no reader root.
**Legibility-target:** security reviewer confirming F3 closed

Both walks now call prompt_marks for any absolute prompt entry, not only `//` entries:
```bash
# scripts/lib/dev-cycle-read.sh:1615 (tree), :1751 (main)
    rq=(); outside_proj out work && { [[ "$f" != /* || -z "${pdir[$f]+set}" ]] || prompt_marks pdir pext out "$f" rq; } || { IMPORTED=error; return 1; }
```
The new test reproduces probe PC from `docs/reviews/security-review-2026-10-09-u2b3b2c-final.md:141` (side's `docs/t.md` = `old` with a live `k.md -> ../../docs/t.md`, and main's `docs/t.md` holding `@top.md`). It asserts `top.md imported` on both walks. It passes on this lib and fails on main's (fc1-bats.log, test 1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:761-775`, `:1352-1363`, `:1615`, `:1751`; `test/scripts/build-loop-check.bats:471-480`; fc1-bats.log

---

## Claim 9a: IMPORTED_MAIN_WHY doc: each KIND (readers, main, tree, link PATH, list, start PATH, admit PATH, seeds, copies, read PATH) is set at the stage named

**Location:** `scripts/lib/dev-cycle-read.sh:791-797`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every `return 1` in main_imports. Residues: lower_all failures in the link and candidate lists report `tree` and `list` (tool failures, not model refusals). A newline in a checkout `.md` name reports `list`. A failed `lower` of a prompt seed reports `seeds`. outside_proj, prompt_marks and `lower "$out"` failures report `read $f`. Does not establish floor's wording (Claims 21-25).
**Legibility-target:** maintainer adding a new failure path to main_imports

Every `return 1` maps to a KIND as follows:
- `:1654` → `readers`.
- `:1659` → `main`.
- `:1661`, `:1663`, `:1665`, `:1670`, `:1676`, `:1677` → `tree` (set at `:1660`).
- `:1679` → `link ${links[i]}`.
- `:1682-1685` → `list` (set at `:1681`).
- `:1690` → `start $f`.
- `:1697`, `:1701` → `seeds`.
- `:1707` → `copies`.
- Every loop-body return from `:1716` to `:1764` (import_file, import_work, the blob read, every 120000 arm, `*)`, outside_proj/prompt_marks, `lower`) → `read $f`.
- `:1759` and `:1771` → `admit $p`.
- `:1762` → `budget`.
- `:1775` → `copies`.

Quoted examples:
```bash
# scripts/lib/dev-cycle-read.sh:1659-1660, 1716
  IMPORTED_MAIN_WHY=main; main_by_name || return 1
  IMPORTED_MAIN_WHY=tree
    IMPORTED_MAIN_WHY="read $f"
```

**Evidence:** `scripts/lib/dev-cycle-read.sh:1650-1779`

---

## Claim 9b: IMPORTED_MAIN_WHY doc: "budget (IMPORT_OUT_MAX)"

**Location:** `scripts/lib/dev-cycle-read.sh:796`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which KIND an IMPORT_OUT_MAX overrun reports. Does not establish IMPORT_WORK_MAX overruns, which report `read PATH` as the doc implies.
**Legibility-target:** operator reading a floor refusal; api-consistency critic

`budget` is set only by the bash-side check:
```bash
# scripts/lib/dev-cycle-read.sh:1762
    (( (used += ${#out}) <= IMPORT_OUT_MAX )) || { IMPORTED_MAIN=error; IMPORTED_MAIN_WHY=budget; return 1; }
```
However, each parser call already gets `IMPORT_LEFT=$((IMPORT_OUT_MAX - used))` (`:1719`, `:1721`), and the parser fails when it would "print past IMPORT_LEFT" (`:892-894`). That failure trips first and reports `read PATH`. Probe C (fc1-floor.log), with IMPORT_OUT_MAX=3 and 12, gave `why=[read CLAUDE.md]` in both runs. `budget` is reached only by output the parser did not bound, such as outside_proj's appended projection or a `//` entry. A precise version: "budget (IMPORT_OUT_MAX, past the parser's own bound; the parser's overrun reports read PATH)".

**Evidence:** `scripts/lib/dev-cycle-read.sh:791-797`, `:892-894`, `:1719-1722`, `:1762`; fc1-floor.log (section C)

---

## Claim 9c: IMPORTED_MAIN_WHY doc: "It is empty after a walk that succeeds and kept with a cached failure"

**Location:** `scripts/lib/dev-cycle-read.sh:796-797`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers main_imports' writes. Only main_imports writes the variable (grep). Does not establish behavior if a caller assigns it.
**Legibility-target:** floor maintainer

`:1778` is `IMPORTED_MAIN_WHY=""` at the end of a successful walk. A cache hit (`:1655`) returns before any write. A readers refusal clears `IMPORTED_MAIN_DONE` (`:1654`), so no stale cache survives it.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1654-1659`, `:1778`; grep of `IMPORTED_MAIN_WHY` across `scripts/`

---

## Claim 10: import_readers doc on IMPORT_CONFIGS: "each absolute home's .claude, then CLAUDE_CONFIG_DIR when set and IMPORT_MANAGED_DIR; the key holds both, so the walks, keyed on IMPORT_CONFIGS too, see a change without import_reset (override row 581). A CLAUDE_CONFIG_DIR that is not absolute or holds a newline returns 1."

**Location:** `scripts/lib/dev-cycle-read.sh:1089-1094`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the order, contents, key and refusal. "When set" means set and non-empty (`:+`). Does not establish a newline in IMPORT_MANAGED_DIR (test-only; it would split into two config dirs).
**Legibility-target:** maintainer of outside_seeds / import_readers

```bash
# scripts/lib/dev-cycle-read.sh:1125
  [[ -z "${CLAUDE_CONFIG_DIR:-}" || ( "$CLAUDE_CONFIG_DIR" == /* && "$CLAUDE_CONFIG_DIR" != *$'\n'* ) ]] || return 1
```
The order is shown in Claim 5's quote (`:1163-1164`). The config-dirs test (`newline: refused` on both walks) and the reworked floor test (`CLAUDE_CONFIG_DIR=rel` → readers wording) pass (fc1-bats.log).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1089-1094`, `:1109-1113`, `:1121-1125`, `:1157-1164`; `test/scripts/build-loop-check.bats:482-496`, `:515-516`; fc1-bats.log

---

## Claim 11: outside_seeds reading IMPORT_CONFIGS gives the same config dirs as main's code

**Location:** `scripts/lib/dev-cycle-read.sh:1404`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers equivalence for every HOME/CLAUDE_CONFIG_DIR value main accepted. One difference is intended: a newline-holding CLAUDE_CONFIG_DIR is now refused. Does not establish the "same 1593 names" run in the brief (not re-run).
**Legibility-target:** reviewer of the move

Main's code (removed hunk):
```bash
-  mapfile -t rs <<<"$IMPORT_ROOTS"; mapfile -t fl <<<"$IMPORT_HOMES"
-  for d in "${fl[@]}"; do [[ "$d" != /* ]] || cf+=("${d%/}/.claude"); done
-  [[ -z "${CLAUDE_CONFIG_DIR:-}" ]] || cf+=("$CLAUDE_CONFIG_DIR"); cf+=("$IMPORT_MANAGED_DIR")
```
New code: `IMPORT_HOMES` is printed from `rs_h` (`:1162`), and IMPORT_CONFIGS iterates the same `rs_h` with the same `/*` test and suffix, then the same two tails (`:1163-1164`). outside_seeds then runs `mapfile -t cf <<<"$IMPORT_CONFIGS"` (`:1404`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1157-1164`, `:1404`; diff hunk at `outside_seeds`

---

## Claim 12: prompt_marks doc: "F is an absolute queue entry ... a // one (a dangling prompt link), or a live one, when its real path differs ...; a plain one returns 0 unmarked" and "It returns 1 when lower or realpath fails"

**Location:** `scripts/lib/dev-cycle-read.sh:1338-1351`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the `//` versus live spelling handling and the return codes. prompt_bases takes `lp` and `l` with equal leading slashes (both stripped for `//`, both single-`/` for live), so its index arithmetic lines up. Does not establish the over-read's cost.
**Legibility-target:** maintainer of prompt_marks

```bash
# scripts/lib/dev-cycle-read.sh:1353-1355
  local -n pm_p="$1" pm_x="$2" pm_o="$3" pm_r="$5"; local p l="$4" lp="${pm_p[$4]}" b pm_b=()
  if [[ "$l" == //* ]]; then l="${l#/}"; lp="${lp#/}"; else b="$(realpath -e -- "$l")" || return 1; [[ "$b" != "$l" ]] || return 0; fi
  prompt_bases pm_b "$lp" "$l"
```
(excerpt ends :1355; prompt_marks continues to :1363 — read; the remaining failure is `pm_p[$p]="$(lower "$p")" || return 1` at :1360)

**Evidence:** `scripts/lib/dev-cycle-read.sh:1338-1363`, `:676-685`

---

## Claim 13: outside_seeds doc: "Items (1) and (2) are its own; (3) is c1_seeds' (rows 582, 589), and each keeps its own keep-rule. It returns 1 when a find, grep, realpath or lower_all fails, or a seed's path holds a newline. ... NAME must not be one of its locals or c1_seeds' (a nameref to one reads that local)."

**Location:** `scripts/lib/dev-cycle-read.sh:1396-1400`
**Type:** Architectural / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the split, the keep-rules, the failure list and the nameref hazard. The hazard holds because bash resolves the `c1_a → os_a → NAME` chain dynamically inside c1_seeds, where c1_seeds' own locals (`cr`, `ir`, `c1_at`) shadow the caller's. Does not establish that the two callers' names (`sd`) avoid every local; they do (`sd` is in neither list).
**Legibility-target:** maintainer of outside_seeds / c1_seeds

The keep-rules: config keeps `os_at` or a real path below a root (`:1450-1452`), and C1 keeps `c1_at` or `-L` plus the rawfile skip (`:1479-1484`).
```bash
# scripts/lib/dev-cycle-read.sh:1454-1455
  c1_seeds os_a || return 1
  for d in "${os_a[@]}"; do [[ "$d" != *$'\n'* ]] || return 1; done
```

**Evidence:** `scripts/lib/dev-cycle-read.sh:1364-1456`, `:1460-1486`, `:1595`, `:1697`

---

## Claim 14: c1_seeds doc: "appends outside_seeds' item (3), C1 ... It returns 1 when a find, grep or lower_all fails."

**Location:** `scripts/lib/dev-cycle-read.sh:1457-1459`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every `return 1` in c1_seeds. root_starts is find plus grep, with_at is grep, and the lower_all count check counts as a lower_all failure. Does not establish anything about root_starts' coverage (A5).
**Legibility-target:** maintainer of c1_seeds

c1_seeds has three `return 1` lines:
```bash
# scripts/lib/dev-cycle-read.sh:1467, 1475, 1476
    nul_list fl root_starts "$r" || return 1
  if [[ ${#cx[@]} -gt 0 ]]; then nul_list lo lower_all "${cx[@]}" && [[ ${#lo[@]} -eq ${#cx[@]} ]] || return 1; fi
  with_at fl "${cx[@]}" || return 1
```

**Evidence:** `scripts/lib/dev-cycle-read.sh:1460-1486`, `:1262`, `:1268-1274`

---

## Claim 15: the newline check still covers C1 seeds

**Location:** `scripts/lib/dev-cycle-read.sh:1454-1455`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the order: c1_seeds appends to `os_a`, then the newline loop scans all of `os_a`. Does not establish that a direct caller of c1_seeds gets the check (it does not, and no such caller exists).
**Legibility-target:** security reviewer (row 585's phase-crossing note)

The quote is in Claim 13 (`:1454-1455`). c1_seeds writes through the nameref `c1_a+=("$c${cx[i]}")` (`:1484`), so its seeds are in `os_a` before the scan.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1454-1455`, `:1484`

---

## Claim 16: main_imports: "Below the cache check: a hit reads nothing here, so floor's cached calls fork no root check"

**Location:** `scripts/lib/dev-cycle-read.sh:1656`
**Type:** Performance / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers main_imports' own body on a cache hit: no need_root, so no `pwd` fork. Does not establish that the import_readers call before the check forks nothing. On an import_readers memo miss (for example HOME unset to the same passwd home) it forks `getent`, `git worktree list` and `realpath` in the cwd, and main's cache can still hit (see Claim 20).
**Legibility-target:** performance critic

The quote is in Claim 2 (`:1654-1657`). Test 5 ("forks no lower, and a cached walk no root check") passes (fc1-bats.log). fc1-tw.log shows 0 `pwd` calls for a cached `truthwalk main`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1654-1658`; fc1-bats.log; fc1-tw.log

---

## Claim 17: truthwalk doc: "asks it about PATH, lower-cased (contract item 8), as isimported WALK PATH does but with no fork ... For tree or main it exits through need_root when it walks."

**Location:** `scripts/lib/dev-cycle-read.sh:1819-1826`
**Type:** Performance / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fork count of a cached truthwalk for each walk name. Does not establish the cost of a walk itself.
**Legibility-target:** check_fix / floor maintainers

truthwalk's own body forks nothing, and a cached `main` call forks nothing. For `tree`, imported_names runs need_root (which runs `$(pwd -P)`) before its cache check on every call:
```bash
# scripts/lib/dev-cycle-read.sh:1579-1582
  need_root
  import_readers || { IMPORTED_DONE=""; IMPORTED=error; return 1; }
  # The roots never hold an empty line, so the blank line ends them.
  [[ "$IMPORTED_DONE" == ... ]] && { [[ "$IMPORTED" != error ]]; return; }
```
(excerpt ends :1582; imported_names continues to :1632 — read)

fc1-tw.log logged one `pwd` call across the two cached truthwalks (tree and main) after the shim was installed, and that call is the tree's. So "no fork" and "exits through need_root when it walks" hold for `main` only. A precise version: for tree, the root check runs on every call, cached or not.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1576-1583`, `:1819-1833`; fc1-tw.log

---

## Claim 18: truthwalk: "Returns 0 when the walk fails (TRUTH_WHY=walk) or reaches PATH or PATH holds an upper-case letter (TRUTH_WHY=imported), else 1 with TRUTH_WHY empty"; the nameref works for both walks and does not clobber IMPORTED/IMPORTED_MAIN

**Location:** `scripts/lib/dev-cycle-read.sh:1824-1833`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both walk names on a passing walk, an upper-case path, an absent path, and whether `tw_l` leaks or the lists change. Does not establish the walk-failure arm by execution; that is static: `main_imports || return 0` with TRUTH_WHY=walk.
**Legibility-target:** floor / check_fix maintainers

```bash
# scripts/lib/dev-cycle-read.sh:1829
  case "$1" in main) main_imports || return 0; local -n tw_l=IMPORTED_MAIN ;; tree) imported_names || return 0; local -n tw_l=IMPORTED ;; *) return 0 ;; esac
```
fc1-tw.log results:
- `tree docs/a.md: 0 [imported]` and `tree docs/b.md: 1 []`.
- The same answers for `main`.
- `lists intact`.
- `tw_l not global`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1827-1833`; fc1-tw.log

---

## Claim 19: floor doc: "$4, optional, the path lower-cased (build-loop.sh passes it, so floor forks no lower ...; an upper-case letter in it refuses as case)"

**Location:** `scripts/lib/dev-cycle-read.sh:1854-1856`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `tr` fork and the upper-case refusal. Does not establish what happens when `$4` is lower-case but differs from `lower($1)`: floor trusts `$4`.
**Legibility-target:** srules maintainer

```bash
# scripts/lib/dev-cycle-read.sh:1868-1870
  local lp="${4-}" d
  FLOOR_WHY=""
  [[ -n "$lp" ]] || lp="$(lower "$1")" || { FLOOR_WHY="the path could not be lower-cased"; return 0; }
```
(excerpt ends :1870; floor continues to :1907 — read)

Test 5 runs with a failing `tr` shim. It gives `b: -` with no shim call, and `C: the path could not be lower-cased` for `Docs/C.md`. It passes (fc1-bats.log).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1850-1907`; `test/scripts/build-loop-check.bats:548-557`; fc1-bats.log

---

## Claim 20: floor doc: "It reads nothing but through main_imports, whose root check runs when it walks, so a call its cache answers forks nothing."

**Location:** `scripts/lib/dev-cycle-read.sh:1863-1864`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers floor's own helpers: truthrule, isstart, writable/anybrief, ownfile and the GATE_CODE regex are all `[[ ]]` tests that fork nothing. It also covers a fully cached call. Does not establish the zero-fork property when import_readers' memo misses but main's cache hits.
**Legibility-target:** performance critic

floor's own helpers are fork-free (`:666`, `:233-239`, `:1808-1818`, `:1841-1846`), and on a full cache hit floor forks nothing (test 5 passes). But main_imports runs import_readers before its cache check (`:1654`). When import_readers' key changes while IMPORT_ROOTS/HOMES/CONFIGS end up the same, it re-lists the registry and main's cache still answers. Probe E (fc1-floor.log) unset HOME when the passwd home already equalled HOME. After one cached walk, the next floor call forked `getent` 1, `git` 1 (worktree list) and `realpath` 2, and main did not walk again. A precise version: "a call that both import_readers' memo and main_imports' cache answer forks nothing".

**Evidence:** `scripts/lib/dev-cycle-read.sh:1052-1058`, `:1114-1126`, `:1654-1657`, `:1863-1907`; fc1-floor.log (section E)

---

## Claim 21: floor's `readers` arm: "the worktree registry could not be read, or a reader root or home or CLAUDE_CONFIG_DIR is not an absolute path"

**Location:** `scripts/lib/dev-cycle-read.sh:1888-1889`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers import_readers' refusal causes against this wording. Does not establish the IMPORT_READER_WHY sub-arm (correct by reading).
**Legibility-target:** operator reading a floor refusal

import_readers also refuses for reasons the wording does not name:
- an empty ROOT_REAL (`:1124`);
- a CLAUDE_CONFIG_DIR holding a newline (`:1125`);
- a root or home holding a newline or equal to `/` (`:1142`, `:1149`);
- an import_home realpath failure (`:1116`);
- a realpath count mismatch (`:1147`).

Probe A shows the ROOT_REAL-unset case reported as "the worktree registry could not be read, or a reader root or home or CLAUDE_CONFIG_DIR is not an absolute path" (see Claim 2).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1114-1149`, `:1888-1889`; fc1-floor.log (section A)

---

## Claim 22: floor's `start`/`admit` arm: "the checkout holds $d, which the walk reads, as other than a readable plain file below plain directories"

**Location:** `scripts/lib/dev-cycle-read.sh:1894`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers main_checkout's 1 answers for a PATH main lacks: a non-plain or unreadable file, or a non-plain or unsearchable ancestor. The wording folds "searchable" into "plain". An ancestor main stores as a link or gitlink is also a 1. In a clean checkout (contract item 2) the checkout holds that link too, so the wording fits. Does not establish the ENT/MEMO-not-associative 1 (a programming error).
**Legibility-target:** operator reading a floor refusal

```bash
# scripts/lib/dev-cycle-read.sh:1562-1565
    [[ ! "${mc_e[$c]:-}" =~ ^1[26]0000$ ]] || return 1
    if [[ "$st" == d ]]; then
      if [[ ! -e "$c" && ! -L "$c" ]] || rawfile "$c"; then st=2
      elif ! plaindir "$c" || [[ ! -x "$c" ]]; then return 1; fi
```
(excerpt ends :1565; main_checkout continues to :1575 — read)

The reworked floor test checks both the symlinked-start case and the 644-directory case, and it passes (fc1-bats.log).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1531-1575`, `:1894`; `test/scripts/build-loop-check.bats:510-514`; fc1-bats.log

---

## Claim 23: floor's `read` arm: "$d could not be read or its imports parsed within the walk's work budget, or it is a link the walk does not model"

**Location:** `scripts/lib/dev-cycle-read.sh:1897`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the causes that reach `read $f`: import_file/blob read, import_work (IMPORT_WORK_MAX), the 120000 arms, other modes, outside_proj, prompt_marks, `lower`. Does not establish the parser's other refusals by execution.
**Legibility-target:** operator reading a floor refusal; api-consistency critic

The parser's output bound (IMPORT_LEFT, derived from IMPORT_OUT_MAX) also lands here. Probe C reports it as "CLAUDE.md could not be read or its imports parsed within the walk's work budget". That names IMPORT_WORK_MAX's budget when IMPORT_OUT_MAX was the one spent, so an operator raising IMPORT_WORK_MAX would not fix it. A precise version would name both budgets.

**Evidence:** `scripts/lib/dev-cycle-read.sh:892-894`, `:1716-1764`, `:1897`; fc1-floor.log (section C)

---

## Claim 24: floor's `link` arm: "the default branch stores a link or gitlink at or below a .claude/ start directory, at $d"

**Location:** `scripts/lib/dev-cycle-read.sh:1892`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers START_LINK's matches. Does not establish anything about the symlinked-start exemption.
**Legibility-target:** operator reading a floor refusal

START_LINK also matches `.claude` itself, which is not a start directory:
```bash
# scripts/lib/dev-cycle-read.sh:665
START_LINK='/\.claude(/(rules|commands|agents|output-styles|skills)(/.*)?)?$'
```
A `.claude` link on main is therefore worded as "at or below a .claude/ start directory". A precise version adds "or at .claude". The test case (`.claude/rules` link) is covered and passes.

**Evidence:** `scripts/lib/dev-cycle-read.sh:663-665`, `:1676-1680`, `:1892`; `test/scripts/build-loop-check.bats:531-534`

---

## Claim 25: floor's `list` and `seeds` arms: "the checkout's .md files could not be listed" / "the instruction files outside the checkout ... could not be listed"

**Location:** `scripts/lib/dev-cycle-read.sh:1893`, `:1895`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the causes that set `list` and `seeds`. The `main`, `tree`, `copies` and `budget` arms' wording matches their causes (`budget`'s reach is in Claim 9b). Does not establish them by execution beyond the tests.
**Legibility-target:** operator reading a floor refusal

Under `list`, a model refusal is also worded as a listing failure. A checkout `.md` name holding a newline (`:1683`) and a short lower_all over main's and the checkout's candidates (`:1684-1685`) both report `list`:
```bash
# scripts/lib/dev-cycle-read.sh:1683
  for f in "${recs[@]}"; do [[ "$f" != *$'\n'* ]] || return 1; [[ -n "${ent[$f]+set}" ]] || cand+=("t:$f"); done
```
Under `seeds`, a failed `lower` of a prompt seed (`:1701`) also reports `seeds`. Both are minor.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1681-1702`, `:1893-1898`

---

## Claim 26: floor doc: "a path below a start file's name is refused too (a directory there keeps the file from being created)"

**Location:** `scripts/lib/dev-cycle-read.sh:1859-1860`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers isstart on each proper ancestor of the lowered path, on the not-imported branch only. Does not establish the import-name half, which is deliberately not done (Claim 31).
**Legibility-target:** security reviewer (row 608)

```bash
# scripts/lib/dev-cycle-read.sh:1904
    d="$lp"; while [[ "$d" == */* ]]; do d="${d%/*}"; ! isstart "$d" || { FLOOR_WHY="a path below the name of an instruction or prompt file"; return 0; }; done
```
Test 4 (`src/CLAUDE.md/n.txt`, `docs/Agents.local.md/a/b`, `skills/x/skill.md/y` refused; `src/claude.mdx/n.txt` passes) passes on this lib and fails on main's.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1902-1906`; `test/scripts/build-loop-check.bats:542-546`; fc1-bats.log

---

## Claim 27: comment "Not an import's name: the parser's prefixes make every directory an import passes through one (override row)."

**Location:** `scripts/lib/dev-cycle-read.sh:1903`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence of the cited override row. Does not establish the reasoning, which is Claim 31.
**Legibility-target:** later reader following the reference

`grep -n u2c2 docs/reviews/override-log.md` finds no row. The commit's Notes say "an override row follows with the review docs". To verify, the row must be written and the comment should cite its number.

**Evidence:** `docs/reviews/override-log.md` (625 lines, no u2c2 row); `scripts/lib/dev-cycle-read.sh:1903`

---

## Claim 28: commit 3111ee9d: "Measured: a cached floor call 6.5 ms -> 0.61 ms per path (400 paths about 2.6 s -> 0.25 s)"

**Location:** commit 3111ee9d message
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the order of magnitude on this machine (400 cached calls, fixture repo, `$4` passed). Does not establish the exact figures, which depend on load and repository.
**Legibility-target:** performance critic

Probe D (fc1-floor.log) gave `dev-cycle-read.sh 0.409 ms/path` and `old-lib.sh 6.100 ms/path`.

**Evidence:** fc1-floor.log (section D); `scripts/lib/dev-cycle-read.sh:1867-1907`

---

## Claim 29: commit 3111ee9d: "the new tests fail against main's lib"

**Location:** commit 3111ee9d message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 4 new tests and the reworked one, run with the lib swapped for main's copy. Does not establish the full suites' pass counts (not re-run).
**Legibility-target:** reviewer of the commit's verification

The command was `TMPDIR="$T" bats -f '<5 names>' {new,old}/test/scripts/build-loop-check.bats`. On this lib all 5 report `ok`. On main's lib (old) all 5 report `not ok` (fc1-bats.log).

**Evidence:** fc1-bats.log

---

## Claim 30a: commit 3111ee9d: "Tests: build-loop-check 142 (5 new, 1 reworked)"

**Location:** commit 3111ee9d message
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test tally. Does not establish whether all 142 pass (not re-run).
**Legibility-target:** reviewer of the commit's verification

main's file holds 138 `@test` blocks and this branch's holds 142 (`bats --count`). The diff adds 4 `@test` blocks (`:471`, `:482`, `:542`, `:548`) and renames one (`:505` → `:506`). The tally is 4 new and 1 reworked (5 changed), not 5 new. This matches the prior pattern "mode1-equiv 33 claimed in commit 37c5ea9's test tally".

**Evidence:** fc1-bats.log (`count new: 142`, `count main: 138`); `test/scripts/build-loop-check.bats:471-557`

---

## Claim 30b: commit 3111ee9d: "read 20, dev-cycle 79, git-env 2, hermeticity 2"

**Location:** commit 3111ee9d message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts (`bats --count`); "hermeticity" is `test/fixture-hermeticity.bats` (2), not `hermeticity-lint.bats` (53). Does not establish that they pass.
**Legibility-target:** reviewer of the commit's verification

fc1-tw.log gives `build-loop-read: 20`, `dev-cycle: 79`, `fixture-git-env.bats: 2` and `fixture-hermeticity.bats: 2`.

**Evidence:** fc1-tw.log

---

## Claim 30c: commit 3111ee9d: "266 changed code lines"

**Location:** commit 3111ee9d message
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the line count. Does not establish anything about a line cap's own counting rule.
**Legibility-target:** reviewer applying the line cap

`git diff main...HEAD --numstat` gives 1+1, 127+71 and 62+4, which total 266. That counts all changed lines, comments and tests included. Changed non-comment lines under `scripts/` total 111. "266 changed lines" would be precise.

**Evidence:** `git -C /workspace/.claude/wt-build-loop-u2c2 diff main...HEAD --numstat` (run 2026-10-10, exit 0; output quoted above)

---

## Claim 31: commit 3111ee9d: "The import-name half is not taken: the parser's prefix candidates make every directory an import passes through an import name (docs/ for @docs/a.md)"

**Location:** commit 3111ee9d message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the parser's documented prefix rule. Does not establish by execution that `docs` appears in IMPORTED_MAIN.
**Legibility-target:** security reviewer weighing row 608's residue

The parser documents its prefix rule:
```bash
# scripts/lib/dev-cycle-read.sh:859-860
# fences too; each prefix of the run after it, up to the first blank (a NUL or
# a UNI_SPACES space counts as one), is a candidate name, with a
```
It also says "a prefix that is itself a file counts as imported" (`:888-889`). Any prefix (`docs`) is therefore printed. An "ancestor is an import name" check would then refuse every path below `docs/`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:854-894`

---

## Claim 32: commit 3111ee9d cites override rows 470, 610, 611, 618 (cost), 376, 467 (WHY), 608 (below a start), 602 (F3), 581 (config dirs), 582, 585, 589, 603 (split)

**Location:** commit 3111ee9d message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that each cited line of `docs/reviews/override-log.md` is the row on the named topic. Does not establish that each row's full ask is met.
**Legibility-target:** reviewer cross-checking the override log

Each cited line is a row on that topic. Examples: line 376 reads "`main_imports` collapses its ~15 refusal causes into IMPORTED_MAIN=error"; line 581 reads "CLAUDE_CONFIG_DIR and IMPORT_MANAGED_DIR are read per walk outside both walk cache keys"; line 602 reads "A live prompt link in another root whose target there holds other bytes"; line 618 reads "one cached floor call runs need_root 4 times".

**Evidence:** `docs/reviews/override-log.md:376,467,470,581,582,585,589,602,603,608,610,611,618`

---

## Claims Requiring Attention

### Incorrect
- **Claim 2** (`scripts/lib/dev-cycle-read.sh:18-22`): with ROOT_REAL unset, main_imports and floor now return 1 (WHY=readers, with a misleading registry/absolute-path reason) instead of exiting through need_root. The cause is that import_readers runs before need_root. Fix the code order or the header.
- **Claim 30a** (commit 3111ee9d): "142 (5 new, 1 reworked)" should be 4 new and 1 reworked (main has 138).

### Stale
- **Claim 6** (`scripts/lib/dev-cycle-read.sh:697-699`): the tree walk's cache key now also holds IMPORT_CONFIGS.
- **Claim 7** (`scripts/lib/dev-cycle-read.sh:729-731`): the main walk's cache key now also holds IMPORT_CONFIGS.

### Mostly Accurate
- **Claim 5** (`:101-104`): contract item 9's list of import_readers results leaves out IMPORT_CONFIGS.
- **Claim 9b** (`:796`): an IMPORT_OUT_MAX overrun normally trips the parser's IMPORT_LEFT first and reports `read PATH`, not `budget`.
- **Claim 17** (`:1819-1826`): the tree arm's imported_names runs need_root (a `pwd` fork) on every call, cached or not. "No fork" and "when it walks" hold for main only.
- **Claim 20** (`:1863-1864`): "forks nothing" holds only when import_readers' memo also hits. A HOME change can fork getent, git worktree list and realpath while main's cache answers.
- **Claim 21** (`:1888`): the readers wording omits an empty ROOT_REAL, a newline, a `/` root and a realpath failure.
- **Claim 23** (`:1897`): the read wording names the work budget when the parser's output budget (IMPORT_OUT_MAX) was the one spent.
- **Claim 24** (`:1892`): START_LINK also matches `.claude` itself; the wording should add "or at .claude".
- **Claim 25** (`:1893`, `:1895`): `list` also covers a newline-holding name and a lower_all count, and `seeds` covers a failed seed `lower`; both are worded as listing failures.
- **Claim 30c** (commit): 266 is the count of all changed lines, comments and tests included; non-comment script lines are 111.

### Unverifiable
- **Claim 27** (`:1903`): "(override row)" cites a row not yet written. Cite its number once it lands.

---

## Goal-Alignment Note

The goal is to land U2c2 after a clean review-fix loop. The unit's six items do what they claim. The tests fail on main's lib and pass here, F3 (probe PC) is closed, the config-dir key works without import_reset, and the per-path cost drop reproduces (6.1 → 0.41 ms).

One change is not documentation drift. Moving need_root below import_readers changed a contract behavior: the main walk and floor no longer exit when ROOT_REAL is unset, and import_readers can run `git worktree list` in the cwd before the root check. The result still fails closed (every path refused), but under a misleading reason, and the header still promises an exit.

The other findings are doc tightenings:
- two stale cache-key descriptions;
- one wrong test tally;
- floor wordings that misname a budget or omit a cause.

## Escalations

- **api-consistency / security:** Claim 2. need_root moved below import_readers, so with ROOT_REAL unset main_imports and floor return instead of exiting, and the cwd (not ROOT_REAL) is read by `git worktree list` on an import_readers memo miss. It is fail-closed, but the caller contract changed and the floor reason misattributes it. Decide: put a cheap `${ROOT_REAL:-}` test (no fork) ahead of import_readers, or reword the header.
- **api-consistency:** Claims 9b and 23. IMPORT_OUT_MAX overruns surface as `read PATH` with "work budget" wording, so an operator would tune the wrong knob.
- **performance:** Claim 20. A floor call can still fork (getent, git, realpath) when import_readers' memo misses but main's cache hits, for example on a mid-decision HOME change. This is a rare path, and the steady-state measurement holds.
- **architecture:** none beyond Claim 5 (contract item 9's results list).
