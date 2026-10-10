Commit: 8786f8fc

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2c2 (branch `feat/build-loop-u2c2`)
**Scope:** `git diff main...HEAD -- scripts test` (commits 3111ee9d, 07af69c0, 2be3db37), the touched functions read whole, plus the three commit messages and the rubric `docs/reviews/code-review-rubric-2026-10-10-feat-build-loop-u2c2.md` (Fixed statuses A1-A16, B1-B5). Final confirming pass, replicate r3 (agent `fcf3`).
**Checked:** 2026-10-10
**Total claims checked:** 30
**Summary:** 26 verified, 3 mostly accurate, 0 stale, 0 incorrect, 1 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`, 5 entries) read first. No claim here matches a logged pattern. The closest class, "a specific measured value quoted from an artifact set", was checked by execution for every count in the commit messages (claims 26, 28, 29). Each one reproduced.

Executed provenance. All probes ran as the brief requires: `set -eu`, a `mktemp -d .../u2c2-review/fcf3-XXXX` temp dir, a `pwd -P` guard before `git init`, and a cleanup trap. Each probe ran from the scratchpad `/tmp/claude-1000/-workspace/843b51ad-a12f-4e61-b040-53f5def15aef/scratchpad/u2c2-review/`. The captured outputs live in its `fcf3-logs/`:
- **P1-P7:** `bash fcf3-probe1.sh`, final run exit 0 at 2026-10-10T17:04:46Z, log `fcf3-logs/probe1.log`. It covers floor with ROOT_REAL unset, walk_why's words, readers_root from a wrong directory, the budget KIND, B1 on HEAD versus ac078bd7's lib, and IMPORT_CONFIGS.
- **Suites:** `bash fcf3-probe2.sh`, exit 0, 2026-10-10T17:04:57Z to about 17:06:35Z. It ran build-loop-check, build-loop-read and dev-cycle serially with `TMPDIR=$T`. Logs: `fcf3-logs/bats-build-loop-check.log` (143 ok, 0 not ok), `fcf3-logs/bats-build-loop-read.log` (20 ok), `fcf3-logs/bats-dev-cycle.log` (79 ok).
- **P8 and P9:** `bash fcf3-probe3.sh`, exit 0 at 2026-10-10T17:06:53Z, log `fcf3-logs/probe3.log`. A second run (P8 only, unique names) finished exit 0 at 17:07:14Z, log `fcf3-logs/probe3b.log`. P8 counts the walk names over this repository under HEAD's lib and main's lib. P9 times a cached floor over 400 paths.
- **Count checks:** run from the worktree. `git show <c>:test/scripts/build-loop-check.bats | grep -c '^@test'` gave main 138, 3111ee9d 142, 07af69c0 142, 2be3db37 143. `git diff --numstat main...<c> -- scripts test` summed added plus deleted lines: 266, 349, 360.

---

## Claim 1: "a path below a start file's or an imported .md file's name, ... a walk that fails refuses every path, its reason saying where, with a PATH outside pathform's characters shown as ?"

**Location:** `scripts/build-loop.sh:177-184`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** operator reading `--check` help
**Scope:** Covers the two floor rules the help adds: the below-a-name refusal (floor :1946-1949) and the walk-failure reason with `?` masking (walk_why :808-811); does not establish the rest of the help paragraph, which this diff did not change.

The floor's else arm refuses a path when an ancestor `isstart`, or is a `.md` name in main's walk list: `! isstart "$d" && { [[ "$d" != *.md ]] || ! walk_has main "$d"; } || { FLOOR_WHY="a path below the name of an instruction or prompt file, or of a .md file one imports with @"; return 0; }` (`scripts/lib/dev-cycle-read.sh:1948`). A failed walk words its reason through `walk_why "$IMPORTED_MAIN_WHY"` (`:1943`). walk_why masks a path with `[[ -z "$d" || "$d" =~ ^[$NAMECHARS]+$ ]] || d="?"` (`:811`). The build-loop-check tests at bats :677-683 and :633-675 pass (suite log, 143 ok). In probe P3, `walk_why "start a b/c.md"` printed "the checkout holds ?, ...".

**Evidence:** `scripts/build-loop.sh:177-184`, `scripts/lib/dev-cycle-read.sh:808-811`, `:1942-1950`, `fcf3-logs/probe1.log`, `fcf3-logs/bats-build-loop-check.log`

---

## Claim 2: "srules passes the lowered path to floor" (brief; floor doc "build-loop.sh passes it")

**Location:** `scripts/build-loop.sh:671`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** gate maintainer
**Scope:** Covers srules' only call to floor and the origin of its `$3`; does not establish any other floor caller, because none exists (grep: floor is called only at build-loop.sh:671).

`if [[ -z "$5" ]] && floor "$2" "$1" "$4" "$3"; then` (`scripts/build-loop.sh:671`). srules' `$3` is `"${lps[$i]}"`, passed at `:843`. That array comes from `nul_list lps lower_all "${ps[@]}"` (`:840`), and a short result refuses the brief.

**Evidence:** `scripts/build-loop.sh:671`, `:840-843`

---

## Claim 3: "a call the walk's caches answer checks only that ROOT_REAL is set"

**Location:** `scripts/lib/dev-cycle-read.sh:19-20`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** gate caller (contract reader)
**Scope:** Covers a call where import_readers' memo holds a result and the walk cache matches. It does not cover a memo miss or a memoized refusal: both run need_root, which P4 also showed. That case is claim 14.

`readers_root() { { [[ -n "${ROOT_REAL:-}" ]] && import_home && import_readers_key && [[ "$IMPORT_READERS_DONE" == "$IMPORT_READERS_KEY" && -n "$IMPORT_ROOTS" ]]; } || need_root; }` (`:833`). Both walks call it first and need_root only below their cache check (`:1627-1630`, `:1702-1706`). In probe P4, after one walk, `cd /; floor docs/z.md x M docs/z.md` printed `z from /: - (no exit)`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:833`, `:1627-1630`, `:1702-1706`, `fcf3-logs/probe1.log`

---

## Claim 4: "inrepo, dirok, skipped, check_brief, isimported and the import walks (truthwalk and floor through them; ...) exit 1 (need_root) unless ROOT_REAL is set"

**Location:** `scripts/lib/dev-cycle-read.sh:18-21`
**Type:** Behavioral / Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** gate caller (contract reader)
**Scope:** Covers floor and truthwalk with ROOT_REAL unset. It does not establish anything about inrepo, dirok, skipped or check_brief, which this diff did not change.

floor no longer calls need_root itself. Its first statements are `local lp="${4-}" d`, then lowering, then `if truthrule "$lp"` (`:1926-1929`; read through :1952). A path that truthrule, GATE_CODE, docs/thoughts/, docs/working/ or docs/reviews/ refuses therefore returns before `truthwalk main` (`:1942`) and never reaches a root check.

In probe P2a, with ROOT_REAL unset, `floor CLAUDE.md x M claude.md` printed `returned 0: an instruction or prompt file, ...` and then `reached`, with exit 0. In P2b, `docs/x.md`, which reaches the walk, exited 1 with "ROOT_REAL is not set". "Through them" points the right way, but the list reads as if floor always exits.

More precise wording: "floor exits only when it reaches its walk; a path an earlier rule refuses returns a refusal without the root check". floor's own doc says this correctly (`:1919`: "whose root check runs when it walks"). The result is fail-closed either way: the early return is a refusal.

**Evidence:** `scripts/lib/dev-cycle-read.sh:18-21`, `:1919-1952`, `fcf3-logs/probe1.log`

---

## Claim 5: Contract item 4: "neither walk's cache key holds them (both hold import_readers' roots, homes and config dirs, so HOME, IMPORT_READER_*, CLAUDE_CONFIG_DIR and IMPORT_MANAGED_DIR need no reset; the worktree registry is read again after a reset or when one of those changes ...)"

**Location:** `scripts/lib/dev-cycle-read.sh:70-76`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** gate caller (contract reader)
**Scope:** Covers the key composition and the recompute on a change of CLAUDE_CONFIG_DIR or IMPORT_MANAGED_DIR with no import_reset. It does not establish that IMPORT_OUT_MAX or IMPORT_WORK_MAX are outside the key; that part is unchanged and was not re-probed.

`local f="${CLAUDE_CONFIG_DIR+x}${CLAUDE_CONFIG_DIR-}" g="$IMPORT_MANAGED_DIR"` joins the key (`:1146-1147`). The walks key on `"$IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES"$'\n\n'"$IMPORT_CONFIGS"` (`:1629`, `:1704`). The bats test at :609 ("a CLAUDE_CONFIG_DIR set after a walk walks again without import_reset") passes for both walks. Probe P7 changed IMPORT_MANAGED_DIR after a tree walk, and IMPORT_CONFIGS then ended with the new directory. HOME reaches the key through `IMPORT_HOME_DONE` (`:1145`; import_home :1091).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1087-1094`, `:1144-1148`, `:1629`, `:1704`, `fcf3-logs/probe1.log`, `fcf3-logs/bats-build-loop-check.log`

---

## Claim 6: Contract item 8: "Pass truthrule, truthwalk, ... a lower-cased path (... floor lowers first unless its caller passes the lowered path ...; truthrule refuses an upper-case letter as case, truthwalk as imported)"

**Location:** `scripts/lib/dev-cycle-read.sh:91-96`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** gate caller
**Scope:** Covers floor's `$4` path and the case words of truthrule and truthwalk. It does not establish whether a future caller of truthwalk runs truthrule first; the two current callers do (claim 22).

- truthwalk: `[[ "$2" != *[ABCDEFGHIJKLMNOPQRSTUVWXYZ]* ]] && ! walk_has "$1" "$2" || return 0` with TRUTH_WHY=imported (`:1884-1885`).
- truthrule: `if [[ "$1" == *[ABCDEFGHIJKLMNOPQRSTUVWXYZ]* ]]; then TRUTH_WHY="case"` (`:1863`).
- floor: `[[ -n "$lp" ]] || lp="$(lower "$1")"` (`:1928`).

Bats :685 calls `floor Docs/C.md x M Docs/C.md` and expects "the path could not be lower-cased". It passes.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1863`, `:1881-1887`, `:1926-1928`, `fcf3-logs/bats-build-loop-check.log`

---

## Claim 7: Contract item 9: "nor IMPORT_ROOTS, IMPORT_HOMES, IMPORT_DOTNEST, IMPORT_OTHER or IMPORT_CONFIGS: they are import_readers' results, which a cache hit does not recompute"

**Location:** `scripts/lib/dev-cycle-read.sh:101-104`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** gate caller
**Scope:** Covers IMPORT_CONFIGS being import_readers' output, cleared at source, and untouched on a memo hit. It does not establish the other four variables beyond their unchanged code.

`IMPORT_CONFIGS=""` is set at source (`:1132`). It is reset and rebuilt only after the memo test: `if [[ "$IMPORT_READERS_DONE" == "$IMPORT_READERS_KEY" ]]; then [[ -n "$IMPORT_ROOTS" ]]; return; fi`, then `... IMPORT_CONFIGS=""` (`:1155-1156`) and `:1198-1199`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1132`, `:1155-1156`, `:1198-1199`

---

## Claim 8: Walk-cache docs: "keyed on import_readers' roots (ROOT_REAL first), homes and config dirs (IMPORT_CONFIGS)"; "cached for the commit, MAIN_BY_NAME and import_readers' roots, homes and config dirs"

**Location:** `scripts/lib/dev-cycle-read.sh:698-699`, `:730-731`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** lib maintainer
**Scope:** Covers both keys' parts; does not establish that every input a walk reads is in a key (IMPORT_*_MAX are deliberately out; contract item 4).

`IMPORTED_DONE="$IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES"$'\n\n'"$IMPORT_CONFIGS"` (`:1631`). `IMPORTED_MAIN_DONE="$MAIN_SHA $MAIN_BY_NAME $IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES"$'\n\n'"$IMPORT_CONFIGS"` (`:1707`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1629-1631`, `:1704-1707`

---

## Claim 9: "a prompt's projected names, a live link's too (U2b3b2c final security F3), are read as prompts with the link's bases" (and: F3 / probe PC is covered for both walks)

**Location:** `scripts/lib/dev-cycle-read.sh:761-763`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** security reviewer / lib maintainer
**Scope:** Covers a live prompt seed whose real path lies below a reader root, in both walks (probe PC's shape). It does not establish a live link whose target is outside every root. That case is left unmarked on purpose (prompt_marks' doc, claim 16), and its projection holds no repo name.

Both walks now call prompt_marks for any absolute pdir entry: `[[ "$f" != /* || -z "${pdir[$f]+set}" ]] || prompt_marks ...` (`:1663`, `:1800`). The bats test at :590 loops `for w in tree main` over PC's layout and wants `top.md imported`: side holds older `docs/t.md` bytes and a live `.claude/commands/k.md -> ../../docs/t.md`, and main's `docs/t.md` imports `@top.md`. It passes. The security review's PC result was `top.md: -` for both walks (`docs/reviews/security-review-2026-10-09-u2b3b2c-final.md:141`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:761-763`, `:1663`, `:1800`, `test/scripts/build-loop-check.bats:590-599`, `fcf3-logs/bats-build-loop-check.log`

---

## Claim 10: IMPORTED_MAIN_WHY: "readers, main (not found by name), tree (...), link PATH (START_LINK), list (...), start PATH or admit PATH (...), seeds, copies, read PATH (...) or budget (...). ... Each stage sets its KIND before it runs ... (one with its own KIND sets it where it fails)"

**Location:** `scripts/lib/dev-cycle-read.sh:792-802`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** lib maintainer / walk_why's caller
**Scope:** Covers every `return 1` in main_imports (:1698-1828, read whole). It does not establish that the stage KIND names the failing helper within a stage. outside_proj and prompt_marks failures in the read loop report `read PATH`, by the stated inherit rule.

The KIND each `return 1` reports:
- `IMPORTED_MAIN_WHY=readers` on import_readers failure (`:1703`).
- `=main` before main_by_name (`:1708`).
- `=tree` before ls-tree, record parse, duplicate names, directory clash and the links' lower_all (`:1709-1726`).
- `="link ${links[i]}"` at the START_LINK test (`:1728`).
- `=list` before checkout_md, the newline test and the cand lower_all (`:1730-1734`).
- `="start $f"` (`:1739`).
- `=seeds` before outside_seeds and the seeds' lower (`:1745-1750`).
- `=copies` before the first root_copies (`:1755`) and at the loop's root_copies (`:1824`).
- `="read $f"` before every read arm (`:1765`).
- `="admit $p"` at both main_checkout refusals (`:1808`, `:1820`).
- `=budget` (`:1811`).

Probe P5 set IMPORT_OUT_MAX=3 and got `WHY=[read AGENTS.md]`: the parser trips first, as `:798` says. The bats floor test at :633-675 checks the start, readers, seeds, read, link, main and `?` wordings.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1698-1828`, `fcf3-logs/probe1.log`, `fcf3-logs/bats-build-loop-check.log`

---

## Claim 11: "It is empty after a walk that succeeds and kept with a cached failure."

**Location:** `scripts/lib/dev-cycle-read.sh:799-800`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** walk_why's caller
**Scope:** Covers the success reset and a cache hit, which does not touch the variable. It does not establish a readers failure: that one clears IMPORTED_MAIN_DONE, so it is re-run rather than cached and sets `readers` again.

`IMPORTED_MAIN_WHY=""` is the walk's last statement (`:1827`). The cache-hit line returns before any assignment (`:1704`). In probe P5, a walk and then a cached call each printed `WHY=[]`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1703-1704`, `:1827`, `fcf3-logs/probe1.log`

---

## Claim 12: "A PATH shows only when every character is one pathform allows (check_line's rule for repo text, so a crafted name prints as ?) ... a // entry as its absolute path."

**Location:** `scripts/lib/dev-cycle-read.sh:805-807`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** security reviewer / operator
**Scope:** Covers the character test and the `//` strip. It does not establish pathform's component rules (no `..`, no leading `/`). Those are not applied, so an absolute host path whose characters pass is shown, as rubric B6 records.

`[[ "$1" != *" "* ]] || d="${1#* }"; [[ "$d" != //* ]] || d="${d#/}"` and `[[ -z "$d" || "$d" =~ ^[$NAMECHARS]+$ ]] || d="?"` (`:810-811`). check_line uses the same test: `shown="?"; [[ ! "$p" =~ ^[$NAMECHARS]+$ ]] || shown="$p"` (`scripts/build-loop.sh:842`). In probe P3, `read //abs/x.md` became `/abs/x.md ...`, and `start a b/c.md` and `read docs/$(x).md` became `?`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:808-827`, `scripts/build-loop.sh:842`, `fcf3-logs/probe1.log`

---

## Claim 13: walk_why's sentences match the failures their KIND covers

**Location:** `scripts/lib/dev-cycle-read.sh:812-825`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** operator reading a deny row
**Scope:** Covers each sentence against the returns under its KIND (claim 10); does not establish wording for KINDs never set (the `*` arm, worded generically: P3 `weird`).

Most sentences match. Two are narrower than what their KIND covers:
- **list:** the sentence says "the checkout's .md files could not be listed or lower-cased" (`:818`). The `list` stage's lower_all, however, runs over `cand`, which also holds main's `m:` names added at `:1716` (`[[ ${#cand[@]} -eq 0 ]] || nul_list low lower_all "${cand[@]}" || return 1`, `:1733`). A tr failure there is a failure on main's names too.
- **copies:** the sentence says "another worktree's copy of an imported name" (`:821`). The first root_copies, however, runs over the starts: `root_copies cq cmp pdir "${queue[@]}" "${tq[@]}"` (`:1756`).

Both are imprecisions, not wrong mechanisms. readers, main, link, start/admit (main_checkout's refusals, including an ancestor main stores as a link, which a contract-clean checkout holds as one), seeds, read and budget match their returns.

**Evidence:** `scripts/lib/dev-cycle-read.sh:812-825`, `:1714-1734`, `:1755-1756`

---

## Claim 14: readers_root: "need_root, unless ROOT_REAL is set and import_readers' memo already holds a result for its key (a hit reads nothing; a memoized refusal checks the root too), so a walk never lists the registry from an unchecked directory; each walk calls it first and need_root again below its own cache check, so a call both caches answer forks no root check"

**Location:** `scripts/lib/dev-cycle-read.sh:827-833`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** lib maintainer
**Scope:** Covers both walks' call order, the memoized-refusal path and the cache-hit path. It does not establish need_root's own checks, which are unchanged.

The `-n "$IMPORT_ROOTS"` term sends a memoized refusal (empty roots) to need_root (`:833`). import_readers lists the registry only after its memo test fails (`:1155-1161`), and readers_root has already run need_root in that case. In probe P4, after `CLAUDE_CONFIG_DIR=rel` (a memoized refusal), `cd /; floor ...` exited with "ROOT_REAL is not the current directory". A cache hit from `/` did not exit (claim 3). Both walks call `readers_root` first (`:1626`, `:1701`), with need_root below their cache check (`:1630`, `:1706`). Bats :685 shims `tr` and `pwd` and finds no call on cached floors.

**Evidence:** `scripts/lib/dev-cycle-read.sh:833`, `:1149-1161`, `:1623-1631`, `:1698-1707`, `fcf3-logs/probe1.log`, `fcf3-logs/bats-build-loop-check.log`

---

## Claim 15: "IMPORT_CONFIGS holds outside_seeds' config dirs, newline-separated: each absolute home's .claude, then CLAUDE_CONFIG_DIR when set and IMPORT_MANAGED_DIR; the key holds both, so the walks, keyed on IMPORT_CONFIGS too, see a change without import_reset (override row 581). A CLAUDE_CONFIG_DIR that is not absolute or holds a newline returns 1."

**Location:** `scripts/lib/dev-cycle-read.sh:1124-1129`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** lib maintainer / gate caller
**Scope:** Covers the contents, order, key and refusal. "When set" means set and non-empty: `${CLAUDE_CONFIG_DIR:+...}` treats empty as unset, as the old outside_seeds did. The refusal is memoized like any import_readers refusal.

- **Contents and order:** `for p in "${rs_h[@]}"; do [[ "$p" != /* ]] || IMPORT_CONFIGS+="${p%/}/.claude"$'\n'; done`, then `IMPORT_CONFIGS+="${CLAUDE_CONFIG_DIR:+$CLAUDE_CONFIG_DIR$'\n'}$IMPORT_MANAGED_DIR"` (`:1198-1199`). This is the same list and order the old outside_seeds built from IMPORT_HOMES (diff lines 299-301). config_seeds reads it: `mapfile -t cf <<<"$IMPORT_CONFIGS"` (`:1453`).
- **Refusal:** `[[ -z "${CLAUDE_CONFIG_DIR:-}" || ( "$CLAUDE_CONFIG_DIR" == /* && "$CLAUDE_CONFIG_DIR" != *$'\n'* ) ]] || return 1` (`:1160`).

In probe P4, IMPORT_CONFIGS read `<home>/.claude|/home/node/.claude|/nonexistent`: the session's CLAUDE_CONFIG_DIR is in the second slot. `CLAUDE_CONFIG_DIR=rel` gave the readers reason. Bats :609 checks the newline refusal for both walks.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1144-1160`, `:1198-1199`, `:1453`, `fcf3-logs/probe1.log`, `fcf3-logs/bats-build-loop-check.log`

---

## Claim 16: prompt_marks: "a // one (a dangling prompt link), or a live one, when its real path differs and lies below a reader root ...; any other returns 0 unmarked ... It returns 1 when lower or realpath fails."

**Location:** `scripts/lib/dev-cycle-read.sh:1373-1389`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** security / performance reviewer
**Scope:** Covers the live-entry test (out-of-root versus into-root) and the return codes. It does not establish how much the target's own names are over-read; the doc calls that over-read accepted.

`b="$(realpath -e -- "$l")" || return 1; [[ "$b" != "$l" ]] || return 0` and `while IFS= read -r p; do [[ "$b" != "$p"/* ]] || in=1; done <<<"$IMPORT_ROOTS"; [[ -n "$in" ]] || return 0` (`:1394-1395`). A `//` entry strips one `/` from both spellings (`:1392`).

In probe P6 under HEAD's lib, `out.md: none` and `in.md: docs/a.md`. Under ac078bd7's lib, `out.md: docs/a.md` (B1's defect). That confirms the 2be3db37 test separates the two. The function was read to its end at :1403.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1390-1403`, `fcf3-logs/probe1.log`

---

## Claim 17: outside_seeds: "Items (1) and (2) are config_seeds', (3) is c1_seeds' ..., and each keeps its own keep-rule. It returns 1 when either does, or a seed's path holds a newline. Run it after import_readers (IMPORT_ROOTS, IMPORT_CONFIGS and IMPORT_OTHER). NAME must not be one of the three functions' locals"

**Location:** `scripts/lib/dev-cycle-read.sh:1438-1447`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** lib maintainer / caller of outside_seeds
**Scope:** Covers the wrapper's three steps, the inputs it reads and the NAME warning. It does not establish that the split keeps the seed set identical over /workspace; P8's matching name counts are indirect evidence only.

The wrapper is `config_seeds "$1" || return 1; c1_seeds "$1" || return 1` followed by the newline loop (`:1445-1446`). config_seeds empties NAME (`os_a=()`, `:1452`), and c1_seeds appends (`c1_a+=`, `:1531`). The keep-rules differ: config_seeds keeps an `@` file or a link whose real path is below a root (`:1497-1501`), and c1_seeds keeps an `@` file or any link (`:1526`). Both callers pass `sd`, which is a local of none of the three functions (`:1624`, `:1699`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1443-1530`

---

## Claim 18: "config_seeds NAME: array NAME gets outside_seeds' items (1) and (2). It returns 1 when a find, grep, realpath or lower_all fails."

**Location:** `scripts/lib/dev-cycle-read.sh:1448-1449`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** lib maintainer
**Scope:** Covers every `return 1` in config_seeds (:1450-1503). It does not establish a python3 failure on installed_plugins.json, which falls back to the cache directory rather than failing; this is consistent with the doc, which does not list python3.

The returns are three find calls (`:1478-1483`), the top-level find and lower_all (`:1487-1488`), with_at's grep (`:1494`) and the xargs realpath (`:1497`). The python3 branch is `if nul_list fl python3 ... ; then ... else ... cache; fi` (`:1467-1474`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1450-1503`

---

## Claim 19: "c1_seeds NAME: appends outside_seeds' item (3), C1, to array NAME: each other root's start files (IMPORT_OTHER) that hold an @ byte or are links, but the ones its skip names. It returns 1 when a find, grep or lower_all fails."

**Location:** `scripts/lib/dev-cycle-read.sh:1504-1506`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** lib maintainer
**Scope:** Covers the append, the filter and the returns; does not establish the C1 skip's soundness outside contract item 2 (security review endorsement, out of this claim).

The filter is `isstart "${lo[i]}" && [[ -n "${c1_at[${cx[i]}]+set}" || -L "${cx[i]}" ]] || continue` (`:1526`), and the append is `|| c1_a+=("$c${cx[i]}")` (`:1531`). The returns are root_starts (find and grep, `:1514`), lower_all (`:1522`) and with_at (`:1523`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1507-1533`

---

## Claim 20: "Below the cache check: a hit reads nothing here, so floor's cached calls fork no root check" / "need_root  # below the cache check, as in main_imports"

**Location:** `scripts/lib/dev-cycle-read.sh:1705-1706`, `:1630`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** performance reviewer
**Scope:** Covers the cached path of both walks. It does not establish a memo miss, for example a HOME change, which forks need_root and the registry listing.

The cache check returns at `:1704` (main) and `:1629` (tree) before need_root. Bats :685 (`[ ! -e "$BATS_TEST_TMPDIR/calls" ]` with `pwd` and `tr` shimmed and `enable -n pwd`) passes. Probe P9 measured a cached floor with `$4` at 679 µs per path, against 6579 µs under main's lib.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1623-1631`, `:1698-1707`, `fcf3-logs/probe3.log`, `fcf3-logs/bats-build-loop-check.log`

---

## Claim 21: walk_has: "whether the list of the walk WALK names ..., as its last call left it, holds LP, a lower-cased path: no fork. Ask it only after that walk succeeded (contract item 6: an error list holds nothing)." Every caller complies.

**Location:** `scripts/lib/dev-cycle-read.sh:1841-1847`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** lib maintainer
**Scope:** Covers all three callers. It does not establish case folding: there is none, and the callers lower first.

The body is a nameref plus a glob test: `if [[ "$1" == main ]]; then local -n wh_l=IMPORTED_MAIN; else local -n wh_l=IMPORTED; fi; [[ "$wh_l" == *$'\n'"$2"$'\n'* ]]`. There is no `$(...)` and no external command. Each caller reaches walk_has only after its walk returned 0:
- isimported: `main_imports || return 0` precedes `walk_has` (`:1838-1839`).
- truthwalk: same order (`:1883-1885`).
- floor's directory loop: in the else arm, reached only when `truthwalk main` returned 1 (`:1942`, `:1946-1949`), which requires a walk that succeeded.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1834-1847`, `:1881-1887`, `:1942-1950`

---

## Claim 22: truthwalk: "asks it about PATH, lower-cased (contract item 8), through walk_has as isimported does, but with no lower ...; Returns 0 when the walk fails (TRUTH_WHY=walk) or reaches PATH or PATH holds an upper-case letter (TRUTH_WHY=imported; both callers run truthrule's case word first), else 1 with TRUTH_WHY empty; an unknown WALK answers walk without running one. For tree or main it exits through need_root when it walks."

**Location:** `scripts/lib/dev-cycle-read.sh:1872-1880`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** truthwalk's callers
**Scope:** Covers truthwalk's body and both callers' order. It does not establish the "~1 ms a path" figure cited from U2c1 final performance 1, which was not re-measured on its own. Claim 20 measures the combined saving.

The body is at `:1881-1887`. The callers:
- check_fix: `if truthrule "$lp" && [[ "$TRUTH_WHY" == cycle ]] ... elif [[ -n "$TRUTH_WHY" || ...` skips on any truthrule word, case included, before `elif truthwalk tree "$lp"` (`scripts/dev-cycle.sh:181-185`).
- floor: `if truthrule "$lp"` precedes `elif truthwalk main "$lp"` (`:1929`, `:1942`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1881-1887`, `scripts/dev-cycle.sh:176-189`, `scripts/lib/dev-cycle-read.sh:1929-1942`

---

## Claim 23: floor: "$4, optional, $1 lower-cased (build-loop.sh passes it, so floor forks no lower ...; floor then reads only $4, so the two must agree; an upper-case letter in it refuses as case)"

**Location:** `scripts/lib/dev-cycle-read.sh:1908-1911`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** floor's caller
**Scope:** Covers the `$4`/`$1` relation. It does not establish what happens when `$4` is passed empty: floor then lowers `$1`, the same as when `$4` is omitted.

`local lp="${4-}"` then `[[ -n "$lp" ]] || lp="$(lower "$1")"` (`:1926-1928`). After that, every test in floor reads `lp` (or `$2`/`$3`), never `$1`. Bats :685's `C:` case passes.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1925-1952`, `fcf3-logs/bats-build-loop-check.log`

---

## Claim 24: "a path below a start file's name or an imported .md name is refused too (a directory there keeps the file from being created ...)"

**Location:** `scripts/lib/dev-cycle-read.sh:1914-1916`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** gate operator / security reviewer
**Scope:** Covers a path that reaches floor's last arm. It does not establish a path below an imported name without `.md`; that case is not refused, by design and by a settled override row dated 2026-10-10.

The loop at `:1946-1949` (quoted in claim 1). Bats :677-683 checks five paths that are refused (`src/CLAUDE.md/n.txt`, `docs/Agents.local.md/a/b`, `skills/x/skill.md/y`, `docs/new.md/n.txt`) and three that pass (`src/claude.mdx/n.txt`, `docs/x.txt`, `docs/ne/x.txt`). It passes.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1944-1950`, `test/scripts/build-loop-check.bats:677-683`, `fcf3-logs/bats-build-loop-check.log`

---

## Claim 25: "It reads nothing but through main_imports, whose root check runs when it walks, so a call both of main_imports' caches answer ... forks nothing but walk_why's subshell after a failed walk; neither changes within a gate decision."

**Location:** `scripts/lib/dev-cycle-read.sh:1919-1922`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** performance reviewer
**Scope:** Covers floor's body under both caches. It does not establish "neither changes within a gate decision" beyond check_line's import_reset per brief, which was not traced here.

The claim holds when `$4` is given, which is the only caller's case (claim 2). Without `$4`, `lp="$(lower "$1")"` (`:1928`) forks a subshell and `tr` on every call, cached or not. The sentence conditions only on the caches. More precise wording: "... a call both caches answer, given `$4`, forks nothing but ...".

The rest checks out. truthrule, writable/anybrief (regex only, `:236-239`), ownfile, isstart and walk_has fork nothing. The cached main_imports path forks nothing (claim 20). `$(walk_why ...)` runs only in the `walk` arm (`:1943`). P9 measured 679 µs per cached path with `$4`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1919-1952`, `:236-239`, `fcf3-logs/probe3.log`

---

## Claim 26: Commit 3111ee9d: "Measured: a cached floor call 6.5 ms -> 0.61 ms per path (400 paths about 2.6 s -> 0.25 s)." Its other items: floor takes `$4`; it has no root check of its own; truthwalk tests the list itself; need_root sits below the cache check; prompt_marks takes live entries; IMPORT_CONFIGS is checked in import_readers; c1_seeds is called at outside_seeds' end.

**Location:** commit 3111ee9d message
**Type:** Performance / Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** reviewer reading history
**Scope:** Covers the timing ratio on a one-root fixture and the structural items at 3111ee9d. It does not establish exact milliseconds, which depend on load and root count. Its "5 new" test count is excluded: it is settled as Accepted-immutable (rubric A17, override row).

P9 measured main's lib at 6579 µs per path and HEAD's lib with `$4` at 679 µs per path, over 400 cached calls, which matches 6.5 to 0.61 ms within noise.

At 3111ee9d, `git show 3111ee9d:scripts/lib/dev-cycle-read.sh` has `c1_seeds os_a || return 1` at the end of outside_seeds (`:1454`), and floor's loop is start-name only. That matches the message's "import-name half is not taken". 07af69c0 later added the `.md` half (A8).

**Evidence:** `fcf3-logs/probe3.log`, `git show 3111ee9d:scripts/lib/dev-cycle-read.sh` (:1454, :1904)

---

## Claim 27: Commit 3111ee9d: "the new tests fail against main's lib"

**Location:** commit 3111ee9d message
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** reviewer reading history
**Scope:** Covers nothing beyond noting the claim. It does not establish that the four new tests or the reworked one fail on main's lib, which was not re-run in this pass.

Execution required. Re-running the suite against main's lib means swapping the lib under REPO_ROOT, which the brief's no-edit rule forbids in the worktree. A copy of `scripts/` with a test harness was out of this pass's budget. The iteration-1 rubric records that fact-check executed this ("the five changed tests fail on main's lib and pass here"). This pass did verify by execution that the 2be3db37 test separates ac078bd7's lib from HEAD's (claim 16).

**Evidence:** `docs/reviews/code-review-rubric-2026-10-10-feat-build-loop-u2c2.md` (Iteration 1, Confirmed Good)

---

## Claim 28: Commit 07af69c0: "build-loop-check 142 ... both walks over this repository give main's 1593 names. 349 changed code lines against main." Also: "readers_root runs need_root unless ... so an unset ROOT_REAL exits again (tested), the registry is never listed from an unchecked directory, and a cached tree walk forks no root check either"

**Location:** commit 07af69c0 message
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** reviewer reading history
**Scope:** Covers the counts and the readers_root behavior as it stands at HEAD. It does not establish the A9 bullet: at 07af69c0 that fix did nothing, which iteration 2 found as rubric B1 and 2be3db37 fixed (claims 16 and 29). It is settled and not re-filed here.

- `grep -c '^@test'` at 07af69c0 gives 142.
- numstat over `scripts test` gives 349.
- P8 over this repository gives main=1593 and tree=1593 unique names, under both HEAD's lib and main's lib. Counting raw lines gives 1811, so 1593 is the unique-name count.
- The unset-ROOT_REAL exit is P2b and bats :673. The registry and tree-walk parts are claims 14 and 20.

**Evidence:** `fcf3-logs/probe3b.log`, `fcf3-logs/probe3.log`, `fcf3-logs/probe1.log`

---

## Claim 29: Commit 2be3db37: "B1 ...: read empties its variable at EOF, so the A9 test passed every absolute path; a flag now records a root match. New test ... fails on ac078bd7. B3: readers_root skips need_root only on a held result, so a memoized refusal from a wrong directory exits. Tests: build-loop-check 143, read 20, dev-cycle 79 ...; 360 changed code lines."

**Location:** commit 2be3db37 message
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** reviewer reading history
**Scope:** Covers B1's mechanism, the test's discrimination, B3's behavior, the three suite counts with their pass status, and the line count. It does not establish the git-env and hermeticity counts, which were not run here.

07af69c0's code was `while IFS= read -r p; do [[ "$b" != "$p"/* ]] || break; done <<<"$IMPORT_ROOTS"; [[ "$b" == "$p"/* ]] || return 0` (`git show 07af69c0:scripts/lib/dev-cycle-read.sh`, prompt_marks). With no match, `p` is empty at EOF, so `"$b" == /*` holds for any absolute `b`. In P6, ac078bd7's lib marks `out.md`, and HEAD's does not. B3 is P4: the memoized refusal from `/` exits. The suites ran 143, 20 and 79 tests, all ok. numstat gives 360.

**Evidence:** `fcf3-logs/probe1.log`, `fcf3-logs/bats-build-loop-check.log`, `fcf3-logs/bats-build-loop-read.log`, `fcf3-logs/bats-dev-cycle.log`

---

## Claim 30: Rubric Fixed/Defer statuses A1-A16, B1-B5

**Location:** `docs/reviews/code-review-rubric-2026-10-10-feat-build-loop-u2c2.md` (Iteration 1 and 2 tables)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** loop orchestrator / merge reviewer
**Scope:** Covers each status against HEAD 8786f8fc's code and text; does not re-judge the Defer/Won't-Fix reasoning (settled override rows).

**Fixed rows:**
- **A1:** readers_root (claims 3, 14; P2b, P4).
- **A2:** `?` masking (claim 12).
- **A3:** the read text names both budgets (`:822`).
- **A4:** IMPORT_CONFIGS appears in both cache descriptions and contract item 9, and the dev-cycle.bats inventory lists the new functions and globals (diff :706, :711; the suite passes).
- **A5:** walk_why exists, with a generic `*` arm.
- **A6:** walk_has is shared (claim 21).
- **A7:** the wrapper (claim 17).
- **A8:** the `.md` rule (claim 24).
- **A9:** as fixed by B1 (claim 16).
- **A11:** floor's cost text names both caches (`:1920-1921`).
- **A12:** the inherit rule is stated (`:800-802`).
- **A13:** `$4` text (claim 23).
- **A14:** help text (claim 1).
- **A15:** the readers text names CLAUDE_CONFIG_DIR, link ".claude", and list/seeds newline and lower (`:813-820`).
- **B1:** flag plus test (P6).
- **B2:** prompt_marks' text (`:1379-1380`).
- **B3:** `-n "$IMPORT_ROOTS"` (`:833`).
- **B4:** floor's subshell clause (`:1921`).
- **B5:** seeds text (`:820`).

**Defer rows:** A10 and A16. Both have 2026-10-10 `feat/build-loop-u2c2` rows in `docs/reviews/override-log.md` (tail).

Claims 13 and 25 note residual imprecision in A15's and B4's text. Each fix was made as described; what remains is a different nuance.

**Evidence:** `scripts/lib/dev-cycle-read.sh:800-833`, `:1919-1922`, `:1946-1949`, `docs/reviews/override-log.md` (last rows), `fcf3-logs/*`

---

## Claims Requiring Attention

### Incorrect
None.

### Stale
None.

### Mostly Accurate
- **Claim 4** (`scripts/lib/dev-cycle-read.sh:18-21`): floor exits on an unset ROOT_REAL only when it reaches its walk. A path an earlier rule refuses returns a refusal without the root check (P2a). It is fail-closed, but the header's list reads as unconditional.
- **Claim 13** (`scripts/lib/dev-cycle-read.sh:818`, `:821`): the `list` sentence omits that the stage's lower_all also covers main's `.md` names, and the `copies` sentence omits that the first root_copies runs over the starts, not only imported names.
- **Claim 25** (`scripts/lib/dev-cycle-read.sh:1919-1922`): "forks nothing" holds only when `$4` is passed. Without it, floor forks `lower` on every call.

### Unverifiable
- **Claim 27** (commit 3111ee9d): re-running the new tests against main's lib needs a lib swap that this pass's no-edit rule kept out of scope. The iteration-1 fact-check executed it.

## Goal-Alignment Note

The goal is to land U2c2 after a clean review-fix loop, and this pass bears on it directly. Every executable claim was run: the three suites at HEAD (143, 20, 79, all passing), the B1 discrimination test against ac078bd7, the cache and root-check behavior from a wrong directory, the budget KIND, the walk name counts and the floor timing. No Incorrect or Stale claim was found.

The three Mostly-accurate items are text precision only, and all three are fail-closed or cost-only. None changes a gate verdict. Claim 4 is the one with a behavioral shade: floor no longer exits on an unset ROOT_REAL for an early-refused path. It still refuses, and its own doc states this correctly; only the header list is loose.

The settled items were not re-filed: A17 (3111ee9d's "5 new") and B1 (07af69c0's A9 claim).

## Escalations

- **security-reviewer:** floor's early arms (truthrule, GATE_CODE, docs/thoughts/, docs/working/, docs/reviews/) no longer run need_root (P2a). They only ever refuse, so there is no fail-open. Confirm that no caller treats floor's exit, rather than its return, as the unset-ROOT_REAL signal. build-loop.sh's comment at :867 relies on "the floor's need_root exit ends the run" for a misconfigured root.
- **security-reviewer:** walk_why shows any absolute path made of NAMECHARS, such as host paths (claim 12, rubric B6, settled). Noted only.
- **performance-reviewer:** floor without `$4` forks `lower` per path (claim 25). Today the only caller passes it. A future caller (U3) inherits the old cost silently.
- **api-consistency-reviewer:** the header's need_root list (claim 4) and walk_why's `list`/`copies` sentences (claim 13) are slightly narrower than the behavior. Decide whether the contract wording should name floor's conditional exit.
- **architecture-review:** none new. floor reads IMPORTED_MAIN_WHY directly rather than through truthwalk; that is a settled Defer row (TRUTH_WHERE, U3).
