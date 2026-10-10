Commit: 8786f8fc
# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2c2 (branch `feat/build-loop-u2c2`, HEAD 8786f8fc)
**Replication:** replicate 2 of k=3 (final confirming pass, agent `fcf2`)
**Scope:** `git diff main...HEAD -- scripts test` (code commits 3111ee9d, 07af69c0, 2be3db37), those three commit messages, and the Fixed/Defer statuses (A1-A16, B1-B5) in `docs/reviews/code-review-rubric-2026-10-10-feat-build-loop-u2c2.md`
**Checked:** 2026-10-10
**Total claims checked:** 40
**Summary:** 31 verified, 4 mostly accurate, 1 stale, 2 incorrect, 2 unverifiable

I read the hallucination-pattern log (`docs/reviews/hallucination-patterns.md`, 5 entries) first. No claim below matches a logged pattern. The two Incorrect verdicts are commit-message statements that were already reported and settled: a test count (A17) and a no-op fix (B1). Neither is a fabricated symbol. The brief allows writing only this file, so the log is not updated.

**Execution provenance (shared by every `executed` claim).** Every probe is one `set -eu` script under its own `mktemp -d .../u2c2-review/fcf2-XXXX` dir, and each removed its dir when done. The scripts are in `/tmp/claude-1000/-workspace/843b51ad-a12f-4e61-b040-53f5def15aef/scratchpad/u2c2-review/`, and their captured output is in `fcf2-logs/` and `fcf2-probe.out` there. Those paths sit outside `docs/reviews/execution-logs/` because the brief allows writing only this file.
- **E1** `bash fcf2-run.sh` (cwd `/workspace/.claude/wt-build-loop-u2c2` inside the script; 2026-10-10T10:04:52 to 10:05:58-07:00; exit 0). It ran the full `TMPDIR=$T bats test/scripts/build-loop-check.bats` serially (rc 0, 143/143 ok → `fcf2-logs/full-build-loop-check.txt`). It then ran the six new or reworked tests from a copy of the test tree against `main`'s lib (all 6 not ok → `fcf2-logs/old-main.txt`) and against `ac078bd7`'s lib (tests 2 and 4 not ok, the rest ok → `fcf2-logs/old-ac078bd7.txt`).
- **E2** `TMPDIR=$D bats -f 'sourcing the reader lib' test/scripts/dev-cycle.bats` (cwd the worktree; 10:06:21; exit 0; 1/1 ok → `fcf2-logs/dev-cycle-surface.txt`).
- **E3** `bash fcf2-probe.sh` (cwd the probe's `$T`; 10:05:21; exit 0 → `fcf2-probe.out`). It holds probes P1 (floor with ROOT_REAL unset), P2 (walk_why's words), P3 (IMPORT_CONFIGS), P4 (readers_root from a wrong directory) and P5 (floor without `$4`).
- **E4** `bash fcf2-time.sh` (cwd the worktree; 10:07:00-10:07:13; exit 0 → `fcf2-logs/timing.txt`). It timed 400 cached floor calls with each of main's and HEAD's libs and counted each main walk's unique names. Load average was 1.73 during the run.
- **E5** `bash fcf2-prefix.sh` (fixture repo under `$T`; 10:08:04; exit 0 → `fcf2-logs/prefix.txt`): a walk list's prefix names, and floor below `.md` and non-`.md` names.

---

## Claim 1: build-loop.sh --check help: "a path below a start file's or an imported .md file's name, ... a walk that fails refuses every path, its reason saying where, with a PATH outside pathform's characters shown as ?"

**Location:** `scripts/build-loop.sh:176-184`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** operator reading `--help`
**Scope:** Covers floor's below-name refusal, its walk-failure refusal with walk_why's reason, and the `?` rule as floor applies them under srules. It does not establish that every KIND's sentence names a path: readers, main, tree, list, seeds, copies and budget name a stage, not a path.

The refusal arms are in floor:
```bash
# scripts/lib/dev-cycle-read.sh:1942-1950
  elif truthwalk main "$lp"; then
    if [[ "$TRUTH_WHY" == walk ]]; then FLOOR_WHY="the default branch's instruction files could not be walked for @ imports: $(walk_why "$IMPORTED_MAIN_WHY")"
    ...
  else
    d="$lp"; while [[ "$d" == */* ]]; do
      d="${d%/*}"; ! isstart "$d" && { [[ "$d" != *.md ]] || ! walk_has main "$d"; } || { FLOOR_WHY="a path below the name of ..."; return 0; }
    done
    return 1
```
walk_why's filter is `[[ -z "$d" || "$d" =~ ^[$NAMECHARS]+$ ]] || d="?"` (`:811`), the same character class check_line uses (`build-loop.sh:839`, `shown="?"; [[ ! "$p" =~ ^[$NAMECHARS]+$ ]] || shown="$p"`). Any path floor does not refuse before truthwalk is refused there when the walk fails, so a failed walk refuses every path. In E1 the floor tests that check this pass.

**Evidence:** `scripts/build-loop.sh:176-184`, `scripts/build-loop.sh:839`, `scripts/lib/dev-cycle-read.sh:808-826`, `scripts/lib/dev-cycle-read.sh:1925-1952`, `fcf2-logs/full-build-loop-check.txt`

---

## Claim 2: srules passes floor the lowered path: "$3 its lower-cased spelling" and `floor "$2" "$1" "$4" "$3"`

**Location:** `scripts/build-loop.sh:659-671`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer of build-loop.sh
**Scope:** Covers the one srules call site and where its `$3` comes from. It does not establish that another caller of floor passes `$4`: the bats `floors` helper does not, so it exercises the lowering path.

check_line builds `lps` with one `lower_all` pass and refuses on a short result: `if ! nul_list lps lower_all "${ps[@]}" || [[ ${#lps[@]} -ne ${#ps[@]} ]]; then ...` (`build-loop.sh:836`). It then calls `srules "$stem" "$p" "${lps[$i]}" "${ss[$i]}" "$co"` (`:841`). srules forwards that value as floor's `$4`: `floor "$2" "$1" "$4" "$3"` (`:670`).

**Evidence:** `scripts/build-loop.sh:659-671`, `scripts/build-loop.sh:836-842`

---

## Claim 3: Lib header: "inrepo, dirok, skipped, check_brief, isimported and the import walks (truthwalk and floor through them; ...) exit 1 (need_root) unless ROOT_REAL is set, is the current directory and is a repository's top level"

**Location:** `scripts/lib/dev-cycle-read.sh:18-21`
**Type:** Behavioral / Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** caller of the lib (a future gate script author)
**Scope:** Covers floor and truthwalk with ROOT_REAL unset. It does not establish anything about inrepo, dirok, skipped or check_brief, whose bodies this diff does not touch.

floor has no root check of its own: `local lp="${4-}" d; FLOOR_WHY=""` (`:1926-1927`). It reaches need_root only through `truthwalk main` → `main_imports` → `readers_root`. A path that truthrule, GATE_CODE, docs/thoughts/, docs/working/ or docs/reviews/ refuses returns 0 before that call. In probe P1 (E3), with ROOT_REAL unset, `floor CLAUDE.md`, `.envrc`, `docs/roadmap.md` and `scripts/lib/x.sh` each returned a refusal and the script printed `reached-end` (rc 0), with no exit. `docs/x.md`, which does reach the walk, exits 1 (test at `build-loop-check.bats:1388-1389`). The parenthetical "through them" points at this, but a reader can still take the sentence to mean that floor always exits when ROOT_REAL is unset. A precise version: floor exits through the walk only for a path that reaches the walk; an earlier rule's refusal returns 0 with no root check. That is fail-closed, so no path lands.

**Evidence:** `scripts/lib/dev-cycle-read.sh:18-21`, `:1925-1952`, `test/scripts/build-loop-check.bats:1388-1389`, `fcf2-probe.out` (P1)

---

## Claim 4: Lib header: "a call the walk's caches answer checks only that ROOT_REAL is set"

**Location:** `scripts/lib/dev-cycle-read.sh:19-20`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** caller of the lib
**Scope:** Covers both walks when import_readers' memo holds a non-empty result for the current key and the walk's own cache matches. It does not establish behavior when HOME changed since the memo: import_home then recomputes, the key differs, and need_root runs.

`readers_root() { { [[ -n "${ROOT_REAL:-}" ]] && import_home && import_readers_key && [[ "$IMPORT_READERS_DONE" == "$IMPORT_READERS_KEY" && -n "$IMPORT_ROOTS" ]]; } || need_root; }` (`:833`). Both walks then return at their cache check before need_root (`:1629-1630`, `:1704-1706`). The memo key includes ROOT_REAL's value (`:1145-1147`), so "set" in practice means "set to the memoized value". In P4 (E3), a held result from `cd /` returned without a root check (`held result: no root check (returned)`). The test "floor given the lowered path forks no lower, and a cached walk no root check" shims `pwd` and records no call (E1 ok).

**Evidence:** `scripts/lib/dev-cycle-read.sh:833`, `:1144-1148`, `:1626-1631`, `:1702-1707`, `test/scripts/build-loop-check.bats:685-694` (diff lines), `fcf2-probe.out` (P4)

---

## Claim 5: Contract item 4: "neither walk's cache key holds them (both hold import_readers' roots, homes and config dirs, so HOME, IMPORT_READER_*, CLAUDE_CONFIG_DIR and IMPORT_MANAGED_DIR need no reset; the worktree registry is read again after a reset or when one of those changes ...)"

**Location:** `scripts/lib/dev-cycle-read.sh:70-76`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** caller of the lib
**Scope:** Covers the memo key's parts and both walk-cache keys. It does not establish that IMPORT_OUT_MAX and IMPORT_WORK_MAX (still a reset duty) are absent from every key; they are absent from the three keys read.

The memo key is `IMPORT_READERS_KEY="${#a}:$a ${#b}:$b ${#c}:$c ${#d}:$d ${#e}:$e ${#f}:$f ${#g}:$g"`, where `f="${CLAUDE_CONFIG_DIR+x}${CLAUDE_CONFIG_DIR-}" g="$IMPORT_MANAGED_DIR"` (`:1146-1147`). The walk keys are `"$IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES"$'\n\n'"$IMPORT_CONFIGS"`, with main's prefixed by `$MAIN_SHA $MAIN_BY_NAME` (`:1629`, `:1704`). The test "both walks key on the config dirs ... without import_reset" passes for both walks (E1) and fails on main's lib (E1, `old-main.txt` test 3).

**Evidence:** `scripts/lib/dev-cycle-read.sh:70-76`, `:1144-1148`, `:1629`, `:1704`, `fcf2-logs/full-build-loop-check.txt`, `fcf2-logs/old-main.txt`

---

## Claim 6: Contract item 8: "Pass truthrule, truthwalk, ... a lower-cased path (...; floor lowers first unless its caller passes the lowered path, and check_fix and the walks lower first; truthrule refuses an upper-case letter as case, truthwalk as imported). ownfile folds no case: floor passes it the lowered path ..."

**Location:** `scripts/lib/dev-cycle-read.sh:91-96`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** caller of the lib
**Scope:** Covers truthwalk's case arm, floor's `$4` fallback, check_fix's lower and floor's ownfile argument. It does not establish prompt_dir's or prompt_bases' callers, which this diff does not touch.

truthwalk returns 0 with `TRUTH_WHY=imported` on an upper-case letter: `[[ "$2" != *[ABCDEFGHIJKLMNOPQRSTUVWXYZ]* ]] && ! walk_has "$1" "$2" || return 0` (`:1885`). floor: `[[ -n "$lp" ]] || lp="$(lower "$1")" || ...` (`:1928`), then `ownfile "$lp" "$2" "$3"` (`:1940-1941`). check_fix lowers before truthrule and truthwalk: `if ! lp="$(lower "$a")"; then ...` (`scripts/dev-cycle.sh:180`). The test's `floor Docs/C.md x M Docs/C.md` prints `C: the path could not be lower-cased` (truthrule's case arm; E1 ok).

**Evidence:** `scripts/lib/dev-cycle-read.sh:91-96`, `:1881-1887`, `:1925-1941`, `scripts/dev-cycle.sh:176-189`, `fcf2-logs/full-build-loop-check.txt`

---

## Claim 7: Walk cache descriptions: imported_names "keyed on import_readers' roots (ROOT_REAL first), homes and config dirs (IMPORT_CONFIGS)"; main_imports "cached for the commit, MAIN_BY_NAME and import_readers' roots, homes and config dirs"; contract item 9 lists IMPORT_CONFIGS among import_readers' results

**Location:** `scripts/lib/dev-cycle-read.sh:697-700`, `:730-734`, `:101-104`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers the two key strings and where IMPORT_CONFIGS is assigned. It does not establish that no caller sets IMPORT_CONFIGS; only `scripts/` was grepped.

The keys are as quoted in Claim 5. IMPORT_CONFIGS is assigned only in import_readers (`:1156`, `:1198-1199`) and at its declaration (`:1132`); a grep of `scripts/` finds no other writer.

**Evidence:** `scripts/lib/dev-cycle-read.sh:697-700`, `:730-734`, `:1132`, `:1156`, `:1198-1199`, `:1629`, `:1704`

---

## Claim 8: Walk doc, F3: "a prompt's projected names, a live link's too (U2b3b2c final security F3), are read as prompts with the link's bases" — and F3 (probe PC) is covered for both walks

**Location:** `scripts/lib/dev-cycle-read.sh:762-765`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** security critic / maintainer
**Scope:** Covers a live prompt entry whose real path differs and lies below a reader root, in both walks, for the probe-PC shape (a live `.claude/commands/k.md -> ../../docs/t.md` in another worktree). It does not establish a live link whose target lies outside every root: by design that one is not marked (Claim 16).

Both walks call prompt_marks for any absolute pdir entry: `[[ "$f" != /* || -z "${pdir[$f]+set}" ]] || prompt_marks pdir pext out "$f" rq` (`:1663`, `:1800`). The new test (diff `build-loop-check.bats:590-599`) reproduces probe PC from `security-review-2026-10-09-u2b3b2c-final.md:141`: main's `docs/t.md` holds `@top.md`, and side's `docs/t.md` is `old` behind a live k.md link. The test loops `for w in tree main` and asserts `top.md imported`. It passes at HEAD and fails on main's lib (E1: `old-main.txt` test 1), so both walks are covered.

**Evidence:** `scripts/lib/dev-cycle-read.sh:762-765`, `:1663`, `:1800`, `docs/reviews/security-review-2026-10-09-u2b3b2c-final.md:141`, `fcf2-logs/full-build-loop-check.txt`, `fcf2-logs/old-main.txt`

---

## Claim 9: IMPORTED_MAIN_WHY doc: the KIND list and "Each stage sets its KIND before it runs, so a failure a stage adds reports that stage (one with its own KIND sets it where it fails)"; each `return 1` of main_imports reports the right KIND

**Location:** `scripts/lib/dev-cycle-read.sh:792-802`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer adding a return to main_imports
**Scope:** Covers every `return 1` in main_imports (`:1698-1828`) against the KIND in force. It does not establish that the sentence walk_why gives each KIND names every cause in that stage (see Claims 10 and 12).

The stage markers are `IMPORTED_MAIN_WHY=readers` (`:1703`), `=main` (`:1708`), `=tree` (`:1709`), `="link ${links[i]}"` (`:1728`), `=list` (`:1730`), `="start $f"` (`:1739`), `=seeds` (`:1745`), `=copies` (`:1755`), `="read $f"` per pop (`:1765`), `="admit $p"` (`:1808`, `:1820`), `=budget` (`:1811`), `=copies` in-loop (`:1824`), and `""` at the end (`:1827`). Each other `return 1` falls under the marker last set: the tree-parse, dup, dir and link-lower returns under tree; checkout_md, a newline and the cand lower_all under list; the seed `lower` under seeds; and the arm, outside_proj/prompt_marks and output-lower returns under read. The `readers` failure also empties IMPORTED_MAIN_DONE, while every later failure leaves the walk key cached with its KIND, which is what "kept with a cached failure" requires (`:1704` returns before any marker is reset). In E1 the floor test's KIND cases pass: start (an untracked link start), start (an unsearchable directory), readers (`CLAUDE_CONFIG_DIR=rel`), seeds (`chmod 000`), read (a missing blob), link (`.claude/rules` as a link), `?` (`a b/CLAUDE.md`) and main.

**Evidence:** `scripts/lib/dev-cycle-read.sh:792-803`, `:1698-1828`, diff `build-loop-check.bats:632-675`, `fcf2-logs/full-build-loop-check.txt`

---

## Claim 10: IMPORTED_MAIN_WHY "list (the checkout's .md list)" and walk_why's list sentence "the checkout's .md files could not be listed or lower-cased, or one's name holds a newline"

**Location:** `scripts/lib/dev-cycle-read.sh:794-795`, `:818`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** operator reading a floor refusal
**Scope:** Covers the list stage's three returns. It does not establish the cost of the imprecision, which needs a failing `tr` and is cosmetic.

The lower_all in the list stage lower-cases `cand`, which holds main's own `.md` names (`cand+=("m:$f")`, `:1716`) as well as the checkout-only ones (`cand+=("t:$f")`, `:1732`). So "the checkout's .md files could not be ... lower-cased" also covers main's tree names: `[[ ${#cand[@]} -eq 0 ]] || nul_list low lower_all "${cand[@]}" || return 1` (`:1733`). A precise version: "the checkout's .md files could not be listed, or main's and the checkout's .md names lower-cased, or one's name holds a newline".

**Evidence:** `scripts/lib/dev-cycle-read.sh:1716`, `:1730-1734`, `:818`

---

## Claim 11: walk_why: "A PATH shows only when every character is one pathform allows (check_line's rule for repo text, so a crafted name prints as ?), a // entry as its absolute path"; an unknown KIND is worded

**Location:** `scripts/lib/dev-cycle-read.sh:804-811`, `:824`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** operator reading a floor refusal / security critic
**Scope:** Covers the character filter, the `//` strip and the generic arm. It does not establish pathform's other rules (a leading `/`, `..`, `.git`), which walk_why does not apply: absolute host paths with clean characters print, as settled in B6.

```bash
# scripts/lib/dev-cycle-read.sh:809-811
  local k="${1%% *}" d=""
  [[ "$1" != *" "* ]] || d="${1#* }"; [[ "$d" != //* ]] || d="${d#/}"
  [[ -z "$d" || "$d" =~ ^[$NAMECHARS]+$ ]] || d="?"
```
P2 (E3) gives these results: `read //home/u/x.md` → `/home/u/x.md could not be read...`, `admit a b.md` → `the checkout holds ?...`, `read docs/$(x).md` → `? could not be read...`, `weird` → `the walk failed (weird)`, and the empty word → `the walk failed (no reason recorded)`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:804-826`, `fcf2-probe.out` (P2)

---

## Claim 12: walk_why's sentences match their failures (readers, main, tree, link, start/admit, seeds, copies, read, budget)

**Location:** `scripts/lib/dev-cycle-read.sh:813-823`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** operator reading a floor refusal
**Scope:** Covers each sentence against the returns under its KIND. Under contract item 2, start/admit's "the checkout holds PATH ... as other than a readable plain file below plain directories" also covers main_checkout's refusal of an ancestor main stores as a link (`:1609`). It does not establish the wording for main_checkout's internal refusal when ENT or MEMO is not an associative array (`:1601`), which no walk input can trigger.

Each sentence was checked against its returns. readers: import_readers' refusals are a registry listing, a root or home that is not absolute, holds a newline or is `/`, a CLAUDE_CONFIG_DIR that is relative or holds a newline (`:1159-1184`), or IMPORT_READER_WHY, which gets its own sentence (`:813`). link: `START_LINK='/\.claude(/(rules|commands|agents|output-styles|skills)(/.*)?)?$'` (`:665`) matches ".claude or at or below a .claude/ start directory". seeds: config_seeds, c1_seeds, the newline check and the seed `lower` (`:1443-1447`, `:1750`). read: the three arms plus outside_proj and prompt_marks (realpath) (`:1766-1800`), which the sentence covers as "could not be read, or its imports parsed". budget: the bash-side `used` overrun (`:1811`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:813-823`, `:1149-1206`, `:1595-1622`, `:1698-1828`

---

## Claim 13: readers_root doc: need_root is skipped only when "ROOT_REAL is set and import_readers' memo already holds a result for its key (a hit reads nothing; a memoized refusal checks the root too), so a walk never lists the registry from an unchecked directory; each walk calls it first and need_root again below its own cache check, so a call both caches answer forks no root check"

**Location:** `scripts/lib/dev-cycle-read.sh:827-833`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer / architecture critic
**Scope:** Covers both walks' call order and the memoized-refusal path. It does not establish that a held result from a wrong cwd is safe when the walk cache misses: need_root below the cache check then exits, which is correct but was not probed separately.

The skip needs `DONE == KEY && -n IMPORT_ROOTS`. import_readers sets DONE before any refusal (`IMPORT_READERS_DONE="$IMPORT_READERS_KEY"; IMPORT_ROOTS=""; ...`, `:1156`), so a memoized refusal reaches need_root. When the skip happens, import_readers' own memo returns before `nul_list rs_l git worktree list` (`:1155`, `:1161`), so no listing runs from an unchecked directory. Both walks run `readers_root`, then `import_readers`, then the cache check, then `need_root` (`:1626-1630`, `:1702-1706`). In P4 (E3), a refusal memoized by `CLAUDE_CONFIG_DIR=rel` followed by `cd /` exits with "ROOT_REAL is not the current directory" (rc 1), while a held result returns.

**Evidence:** `scripts/lib/dev-cycle-read.sh:827-833`, `:1149-1161`, `:1623-1631`, `:1698-1707`, `fcf2-probe.out` (P4)

---

## Claim 14: import_readers memo: "keyed on ROOT_REAL, HOME, the caller's two lists, IMPORT_READER_WHY and the two config dirs"

**Location:** `scripts/lib/dev-cycle-read.sh:1116-1121`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers import_readers_key's seven parts. It does not establish that an import_home failure is memoized; the doc says it is not, and the code returns before the key (`:1151`).

`local a="${ROOT_REAL:-}" b="$IMPORT_HOME_DONE" c="$IMPORT_READER_ROOTS" d="$IMPORT_READER_HOMES" e="$IMPORT_READER_WHY"` and `local f="${CLAUDE_CONFIG_DIR+x}${CLAUDE_CONFIG_DIR-}" g="$IMPORT_MANAGED_DIR"` (`:1145-1146`). `IMPORT_HOME_DONE` is HOME's key (`:1088`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1088`, `:1144-1156`

---

## Claim 15: IMPORT_CONFIGS doc: "outside_seeds' config dirs, newline-separated: each absolute home's .claude, then CLAUDE_CONFIG_DIR when set and IMPORT_MANAGED_DIR; the key holds both, so the walks ... see a change without import_reset (override row 581). A CLAUDE_CONFIG_DIR that is not absolute or holds a newline returns 1."

**Location:** `scripts/lib/dev-cycle-read.sh:1124-1129`
**Type:** Configuration / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** caller of the lib
**Scope:** Covers the contents, order, key and refusal of IMPORT_CONFIGS. It does not establish Claude Code's own treatment of an empty CLAUDE_CONFIG_DIR.

`for p in "${rs_h[@]}"; do [[ "$p" != /* ]] || IMPORT_CONFIGS+="${p%/}/.claude"$'\n'; done` and then `IMPORT_CONFIGS+="${CLAUDE_CONFIG_DIR:+$CLAUDE_CONFIG_DIR$'\n'}$IMPORT_MANAGED_DIR"` (`:1198-1199`). The `:+` takes CLAUDE_CONFIG_DIR only when it is set and non-empty, but the key's `${CLAUDE_CONFIG_DIR+x}` distinguishes set-empty from unset. In P3 (E3), `empty:` gave the same list as `unset:` (`<home>/.claude|/m`), `abs:` gave `<home>/.claude|/cfg|/m`, `rel:` was refused with `roots=[]`, and a relative HOME gave `/cfg|/m`. The refusal is `[[ -z "${CLAUDE_CONFIG_DIR:-}" || ( "$CLAUDE_CONFIG_DIR" == /* && "$CLAUDE_CONFIG_DIR" != *$'\n'* ) ]] || return 1` (`:1160`), and the newline case is tested (E1). A precise version: "CLAUDE_CONFIG_DIR when set and non-empty". The order matches main's former `cf` construction in outside_seeds, which also tested `-z`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1124-1129`, `:1160`, `:1192-1199`, `fcf2-probe.out` (P3)

---

## Claim 16: prompt_marks doc: "F is an absolute queue entry ...: a // one (a dangling prompt link), or a live one, when its real path differs and lies below a reader root (...); any other returns 0 unmarked"

**Location:** `scripts/lib/dev-cycle-read.sh:1373-1381`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer / performance critic
**Scope:** Covers the `//` arm, the same-path return, and the below-a-root test, which now uses a flag set inside the loop. It does not establish the cost of the extra realpath per live entry (override row, i1 performance 5).

```bash
# scripts/lib/dev-cycle-read.sh:1392-1396
  if [[ "$l" == //* ]]; then l="${l#/}"; lp="${lp#/}"
  else
    b="$(realpath -e -- "$l")" || return 1; [[ "$b" != "$l" ]] || return 0
    while IFS= read -r p; do [[ "$b" != "$p"/* ]] || in=1; done <<<"$IMPORT_ROOTS"; [[ -n "$in" ]] || return 0
  fi
```
The test "prompt_marks marks a live prompt link's names only when its real path lies below a reader root" prints `out.md: none` and `in.md: docs/a.md`. It passes at HEAD and fails on ac078bd7's and main's libs (E1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1373-1405`, diff `build-loop-check.bats:601-607`, `fcf2-logs/old-ac078bd7.txt`, `fcf2-logs/old-main.txt`

---

## Claim 17: prompt_marks: "It returns 1 when lower or realpath fails."

**Location:** `scripts/lib/dev-cycle-read.sh:1389`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers prompt_marks' two failing commands and how the walks receive them. It does not establish any probe of a vanished target.

Its failures are `b="$(realpath -e -- "$l")" || return 1` (`:1394`) and `pm_p[$p]="$(lower "$p")" || return 1` (`:1402`); there are no other `return 1`s. Both walks fail on it: `... || { IMPORTED=error; return 1; }` (`:1663`, `:1800`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1390-1405`, `:1663`, `:1800`

---

## Claim 18: outside_seeds doc: "Items (1) and (2) are config_seeds', (3) is c1_seeds' ..., and each keeps its own keep-rule. It returns 1 when either does, or a seed's path holds a newline. Run it after import_readers (IMPORT_ROOTS, IMPORT_CONFIGS and IMPORT_OTHER). NAME must not be one of the three functions' locals"

**Location:** `scripts/lib/dev-cycle-read.sh:1438-1447`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** caller of the lib
**Scope:** Covers the wrapper's call order, the newline check, the keep-rules and the callers' array name (`sd`). It does not establish seed-set equality before and after the split on another machine; here both libs' main walks give 1593 unique names (E4).

`config_seeds "$1" || return 1; c1_seeds "$1" || return 1` and then `for ow_d in "${ow_a[@]}"; do [[ "$ow_d" != *$'\n'* ]] || return 1; done` (`:1445-1446`). config_seeds empties the array (`os_a=()`, `:1452`) and c1_seeds appends to it (`c1_a+=(...)`, `:1531`). The keep-rules are config's "@ or a real path below a root" (`:1498-1501`) and C1's "@ or a link" (`:1526`). The inputs read are `IMPORT_ROOTS`, `IMPORT_CONFIGS` (`:1453`), `IMPORT_OTHER` and ROOT_REAL (`:1509`, `:1512`). Both callers pass `sd` (`:1643`, `:1746`), which is not among `ow_a ow_d`, config_seeds' locals (`:1451`) or c1_seeds' locals (`:1508`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1438-1533`, `:1643`, `:1746`, `fcf2-logs/timing.txt`

---

## Claim 19: config_seeds: "array NAME gets outside_seeds' items (1) and (2). It returns 1 when a find, grep, realpath or lower_all fails." / c1_seeds: "appends ... C1 ...: each other root's start files (IMPORT_OTHER) that hold an @ byte or are links, but the ones its skip names. It returns 1 when a find, grep or lower_all fails."

**Location:** `scripts/lib/dev-cycle-read.sh:1448-1449`, `:1504-1506`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers each function's `return 1`s. A python3 failure is not one: config_seeds falls back to the plugin cache (`:1474`), and the doc does not claim it fails. It does not establish xargs batching limits.

config_seeds' failures are `find -L`/`find -H` (`:1477-1487`), lower_all (`:1488`), with_at's grep (`:1494`) and xargs realpath (`:1497`). c1_seeds' failures are root_starts (find plus the grep in instruction_names, `:1514`), lower_all (`:1522`) and with_at (`:1523`). c1_seeds' rawfile is a test inside the skip, not a failure (`:1531`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1448-1533`, `:1297`, `:1303-1309`

---

## Claim 20: main_imports comment: "Below the cache check: a hit reads nothing here, so floor's cached calls fork no root check"

**Location:** `scripts/lib/dev-cycle-read.sh:1705`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** performance critic
**Scope:** Covers a cache hit whose import_readers memo holds a result. It does not establish behavior on a memo miss (Claim 13 covers that).

`[[ "$IMPORTED_MAIN_DONE" == ... ]] && { [[ "$IMPORTED_MAIN" != error ]]; return; }` comes before `need_root` (`:1704-1706`). The pwd-shim test records no `pwd` call (E1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1702-1706`, `fcf2-logs/full-build-loop-check.txt`

---

## Claim 21: isimported doc and code: "A failed walk, a failed lower of $2, or a walk name that is neither answers imported (0)"; it lowers $2 and asks walk_has

**Location:** `scripts/lib/dev-cycle-read.sh:1829-1840`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** caller of the lib
**Scope:** Covers isimported's three 0-arms and its case handling. It does not establish callers outside `scripts/` and the bats tests.

`need_root; lp="$(lower "$2")" || return 0; case "$1" in main) main_imports || return 0 ;; tree) imported_names || return 0 ;; *) return 0 ;; esac; walk_has "$1" "$lp"` (`:1836-1839`). walk_has is reached only after its walk returned 0.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1834-1840`

---

## Claim 22: walk_has doc: "whether the list ... holds LP, a lower-cased path: no fork. Ask it only after that walk succeeded" — and every caller complies

**Location:** `scripts/lib/dev-cycle-read.sh:1841-1847`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer adding a caller
**Scope:** Covers walk_has' body and its three callers (isimported, truthwalk, floor's ancestor loop). It does not establish the glob's cost on a large list (override row, A10).

The body is `if [[ "$1" == main ]]; then local -n wh_l=IMPORTED_MAIN; else local -n wh_l=IMPORTED; fi; [[ "$wh_l" == *$'\n'"$2"$'\n'* ]]`, with no command substitution and no external command. Its callers are isimported (after `main_imports || return 0`, `:1838-1839`), truthwalk (after `main_imports || return 0`, `:1883-1885`) and floor's loop. floor's loop sits in the `else` of `elif truthwalk main "$lp"`, which truthwalk reaches only by `return 1`, and that needs a successful walk (`:1942-1948`). Each caller passes a lower-cased LP: isimported's `lp`, truthwalk's PATH after its case test, and floor's `d`, cut from `lp` after truthrule refused upper case.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1834-1887`, `:1925-1952`, `grep -n walk_has scripts/` (three call sites)

---

## Claim 23: truthwalk doc: "asks it about PATH, lower-cased (contract item 8), through walk_has as isimported does, but with no lower ... Returns 0 when the walk fails (TRUTH_WHY=walk) or reaches PATH or PATH holds an upper-case letter (TRUTH_WHY=imported; both callers run truthrule's case word first), else 1 with TRUTH_WHY empty; an unknown WALK answers walk without running one. For tree or main it exits through need_root when it walks."

**Location:** `scripts/lib/dev-cycle-read.sh:1872-1880`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** caller of truthwalk (check_fix, floor)
**Scope:** Covers truthwalk's body and both callers' order. It does not establish the cost figure in the parenthetical (Claim 24).

The body is `TRUTH_WHY=walk; case ... *) return 0 ;; esac; TRUTH_WHY=imported; [[ "$2" != *[A-Z...]* ]] && ! walk_has "$1" "$2" || return 0; TRUTH_WHY=""; return 1` (`:1882-1886`). Both callers run truthrule first: floor at `:1929` and check_fix at `scripts/dev-cycle.sh:181-183`. check_fix's `[[ -n "$TRUTH_WHY" ...` arm skips any truthrule word, `case` included, before `truthwalk tree`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1872-1887`, `:1925-1944`, `scripts/dev-cycle.sh:176-189`

---

## Claim 24: truthwalk doc: "isimported's lower and root check cost floor ~1 ms a path: U2c1 final performance 1"

**Location:** `scripts/lib/dev-cycle-read.sh:1874-1875`
**Type:** Performance / Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** performance critic
**Scope:** Covers the before/after per-call cost of a cached floor call. It does not isolate the share due to isimported's lower and need_root alone.

E4 timed 400 cached floor calls (with `$4`) at 15.0 ms per call with main's lib and 1.05 ms per call with HEAD's, under load average 1.73. main's floor also forks its own lower and need_root, so the ~1 ms attributed to isimported's two forks cannot be separated from these totals. Verifying it needs a per-fork microbenchmark on an idle machine.

**Evidence:** `fcf2-logs/timing.txt`

---

## Claim 25: floor doc: "$4, optional, $1 lower-cased (build-loop.sh passes it, so floor forks no lower ...; floor then reads only $4, so the two must agree; an upper-case letter in it refuses as case)"

**Location:** `scripts/lib/dev-cycle-read.sh:1908-1911`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** caller of floor
**Scope:** Covers floor's use of `$4` and the case refusal. It does not establish behavior when `$4` is an empty string: floor then lowers `$1`, a fallback the doc does not mention but that matches "optional".

After `[[ -n "$lp" ]] || lp="$(lower "$1")"` (`:1928`), every test reads `lp`. `$1` itself is never read again; ownfile also gets `lp`. The test's `floor Docs/C.md x M Docs/C.md` gives `C: the path could not be lower-cased`, and the `tr` shim records no call for `floor docs/b.md x M docs/b.md` (E1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1925-1952`, diff `build-loop-check.bats:685-694`, `fcf2-logs/full-build-loop-check.txt`

---

## Claim 26: floor doc: "a path below a start file's name or an imported .md name is refused too (a directory there keeps the file from being created ...)" and the code comment "(not any import's: the parser's prefixes make every directory an import passes through one; override row)"

**Location:** `scripts/lib/dev-cycle-read.sh:1914-1916`, `:1946`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** operator reading a floor refusal / security critic
**Scope:** Covers the ancestor loop and the prefix rationale. It does not establish refusal of a path below an imported non-`.md` name, which is Won't-Fix by override row (2026-10-10, row 608's import-name half).

E5 printed the walk list for `see @docs/new.md`. It holds `do doc docs docs/n docs/ne docs/new docs/new. docs/new.m docs/new.md`, so every directory of the import is in the list. floor gave `docs/x: -`, `docs/ne/x: -`, and for `docs/new.md/x` and `docs/new.md/n.txt/x` the reason "a path below the name of an instruction or prompt file, or of a .md file one imports with @". The bats test refuses `src/CLAUDE.md/n.txt`, `docs/Agents.local.md/a/b`, `skills/x/skill.md/y` and `docs/new.md/n.txt` and passes `src/claude.mdx/n.txt`, `docs/x.txt` and `docs/ne/x.txt` (E1). Paths refused by an earlier floor rule are refused anyway. A brief's own files can lie only directly in `docs/working/` or `docs/reviews/`, whose names are not `.md` names, so no exception lets a path below such a name through.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1895-1900`, `:1945-1951`, `fcf2-logs/prefix.txt`, `fcf2-logs/full-build-loop-check.txt`

---

## Claim 27: floor doc: "It reads nothing but through main_imports, whose root check runs when it walks, so a call both of main_imports' caches answer (import_readers' memo and the walk's) forks nothing but walk_why's subshell after a failed walk; neither changes within a gate decision."

**Location:** `scripts/lib/dev-cycle-read.sh:1919-1922`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** caller of floor / performance critic
**Scope:** Covers floor's forks on a doubly cached call with and without `$4`. It does not establish whether HOME or the config dirs change within a gate decision; check_line does not change them.

With `$4` given, the cached call forks nothing but `$(walk_why ...)` (`:1943`), as the pwd/tr-shim test shows (E1). Without `$4`, floor forks `lower` (`:1928`) on every call. In P5 (E3), `floor docs/b.md x M` after a warm walk recorded one `tr` call through the shim. The sentence states the zero-fork result unconditionally, while `$4` is introduced as optional two sentences earlier. A precise version: "a call given `$4` that both caches answer forks nothing ...". build-loop.sh, the only production caller, passes `$4`, so the gate is unaffected.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1908-1928`, `:1943`, `fcf2-probe.out` (P5)

---

## Claim 28: Commit 3111ee9d: "floor takes the lowered path as an optional $4 (srules passes it), has no root check of its own, truthwalk tests the walk's list itself (no isimported lower or root check), and main_imports runs need_root below its cache check"

**Location:** commit `3111ee9d` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** orchestrator
**Scope:** Covers the four statements as true at HEAD. It does not establish the state at 3111ee9d alone; 07af69c0 then added readers_root before the cache check (Claim 13).

The code is quoted in Claims 2, 13, 23 and 25.

**Evidence:** `scripts/build-loop.sh:670`, `scripts/lib/dev-cycle-read.sh:1702-1706`, `:1881-1887`, `:1925-1928`

---

## Claim 29: Commit 3111ee9d: "Measured: a cached floor call 6.5 ms -> 0.61 ms per path (400 paths about 2.6 s -> 0.25 s)"

**Location:** commit `3111ee9d` message
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** orchestrator / performance critic
**Scope:** Covers the before/after per-path cost under this run's load. It does not reproduce the absolute figures, which depend on machine load and on the walk list's size.

E4 measured 15.0 ms (main's lib) and 1.05 ms (HEAD's lib) per cached floor call over 400 paths at load average 1.73. That is a 14x reduction, against the 10.7x claimed. The direction and order of magnitude reproduce; the absolute numbers do not. Re-measuring on an idle machine would settle them.

**Evidence:** `fcf2-logs/timing.txt`

---

## Claim 30: Commit 3111ee9d: "Tests: build-loop-check 142 (5 new, 1 reworked)"

**Location:** commit `3111ee9d` message
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Legibility-target:** orchestrator
**Scope:** Covers the count of `@test` lines in build-loop-check.bats at main and at 3111ee9d. It is already settled: rubric A17, Accepted-immutable, with the correction stated in 07af69c0. It is recorded here and not re-filed for action.

`git show main:test/scripts/build-loop-check.bats | grep -c '^@test'` gives 138, and the same count at `3111ee9d` gives 142: 4 new tests plus 1 reworked, not 5 new.

**Evidence:** paraphrased — no quote available because the claim covers a count over two revisions (`git show <rev>:test/scripts/build-loop-check.bats | grep -c '^@test'`: main 138, 3111ee9d 142, 07af69c0 142, 2be3db37 143)

---

## Claim 31: Commit 3111ee9d: "The import-name half is not taken: the parser's prefix candidates make every directory an import passes through an import name"

**Location:** commit `3111ee9d` message
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Legibility-target:** orchestrator
**Scope:** Covers the statement against HEAD. It was true at 3111ee9d. The prefix rationale itself is verified in Claim 26.

07af69c0 (A8) took the `.md` part of the import-name half: floor now refuses below an imported `.md` name, `{ [[ "$d" != *.md ]] || ! walk_has main "$d"; }` (`:1948`). Only the non-`.md` part is left undone, by override row. A commit message cannot be amended, so there is nothing to do.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1946-1948`, commit `07af69c0` message (A8)

---

## Claim 32: Commit 3111ee9d / 07af69c0 / 2be3db37: "266" / "349" / "360 changed code lines"

**Location:** commit messages `3111ee9d`, `07af69c0`, `2be3db37`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** orchestrator
**Scope:** Covers added plus deleted lines under `scripts` and `test` against main at each commit (the size gate's count). It does not mean non-comment lines; A17 settled that.

`git diff --numstat main...<c> -- scripts test` sums to 266 (190+76), 349 (259+90) and 360 (270+90).

**Evidence:** paraphrased — no quote available because the figures are numstat sums over three revisions

---

## Claim 33: Commit 3111ee9d: "the new tests fail against main's lib"; commit 2be3db37: "New test (out-of-root link unmarked, into-root marked) fails on ac078bd7"

**Location:** commit messages `3111ee9d`, `2be3db37`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** orchestrator
**Scope:** Covers the six new or reworked tests at HEAD, run against main's and ac078bd7's libs. It does not run 3111ee9d's own versions of the tests.

E1: against main's lib all six are `not ok`. Against ac078bd7's lib, test 2 (prompt_marks below a root) is `not ok`. So is test 4, the floor-fails-closed test, but only on the seeds sentence that 2be3db37 (B5) changed: `old-ac078bd7.txt` shows the want line for the seeds text.

**Evidence:** `fcf2-logs/old-main.txt`, `fcf2-logs/old-ac078bd7.txt`

---

## Claim 34: Commit 07af69c0: "A1 ...: readers_root runs need_root unless ROOT_REAL is set and import_readers' memo answers for its key; both walks call it first and need_root again below their cache check, so an unset ROOT_REAL exits again (tested), the registry is never listed from an unchecked directory, and a cached tree walk forks no root check either"

**Location:** commit `07af69c0` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** orchestrator
**Scope:** Covers the statements at HEAD, where 2be3db37 (B3) also requires a non-empty memo. At 07af69c0 a memoized refusal skipped need_root, as B3 records.

See Claims 4 and 13. The unset-ROOT_REAL test (`build-loop-check.bats:1388-1389` in the diff) passes (E1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:833`, `:1626-1631`, `fcf2-logs/full-build-loop-check.txt`

---

## Claim 35: Commit 07af69c0: "A9 (performance 1): prompt_marks marks a live entry only when its real path lies below a reader root."

**Location:** commit `07af69c0` message
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** orchestrator
**Scope:** Covers the statement as of 07af69c0 (unchanged at ac078bd7). It is already settled: iteration-2 fact-check 12a/29, rubric B1, fixed in 2be3db37. It is recorded here and not re-filed.

At ac078bd7 the loop was `while IFS= read -r p; do [[ "$b" != "$p"/* ]] || break; done <<<"$IMPORT_ROOTS"; [[ "$b" == "$p"/* ]] || return 0`. When no root matches, `read` empties `p` at EOF, and `"$b" == /*` holds for every absolute `b`. The new test fails on that lib (E1, `old-ac078bd7.txt` test 2) and passes at HEAD.

**Evidence:** `git show ac078bd7:scripts/lib/dev-cycle-read.sh` lines 1388-1393, `fcf2-logs/old-ac078bd7.txt`

---

## Claim 36: Commit 2be3db37: "B1 ...: read empties its variable at EOF, so the A9 test passed every absolute path; a flag now records a root match"; "B3: readers_root skips need_root only on a held result, so a memoized refusal from a wrong directory exits"

**Location:** commit `2be3db37` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** orchestrator
**Scope:** Covers the mechanism and both fixes. It does not establish the "A9 test passed every absolute path" wording for 07af69c0's test itself, which was not re-run; the mechanism is shown in Claim 35.

The flag is `in=1` inside the loop (`:1395`). The held-result test is `-n "$IMPORT_ROOTS"` (`:833`). P4 (E3) exits for the memoized refusal from `/`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:833`, `:1395`, `fcf2-probe.out` (P4)

---

## Claim 37: Commits 07af69c0 / 2be3db37: "build-loop-check 142" / "143", "both walks over this repository give main's 1593 names", "dev-cycle.bats' surface inventory lists the new functions and globals"

**Location:** commit messages `07af69c0`, `2be3db37`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** orchestrator
**Scope:** Covers the HEAD suite, the 1593 unique names of the main walk with each of main's and HEAD's libs in this worktree, and the tree walk's total. It does not establish read 20, dev-cycle 79, git-env 2 or hermeticity 2, which were not re-run (only the surface test was). The count holds while the registry stays at 11 worktrees.

E1 gives 143/143 ok. E2 shows the surface test ok; it lists `config_seeds c1_seeds ... walk_why walk_has readers_root` and `IMPORT_CONFIGS IMPORTED_MAIN_WHY` (diff `dev-cycle.bats:1108-1111`). E4 gives `main-lib.sh names: 1593` and `dev-cycle-read.sh names: 1593`, counted as unique non-empty lines of IMPORTED_MAIN. A separate run in this worktree gave the tree walk 1811 lines, the same total as main's walk before deduplication. The tree walk's unique count was not taken.

**Evidence:** `fcf2-logs/full-build-loop-check.txt`, `fcf2-logs/dev-cycle-surface.txt`, `fcf2-logs/timing.txt`

---

## Claim 38: Rubric A1-A16 statuses (Fixed / Doc fixed / Fixed in text / Defer (row))

**Location:** `docs/reviews/code-review-rubric-2026-10-10-feat-build-loop-u2c2.md` (iteration 1 tables)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** orchestrator
**Scope:** Covers each status at HEAD. A9's "Fixed" holds only at HEAD, through B1 (Claim 35). A17 is Claim 30.

A1 is verified in Claims 13 and 34, A2 in Claim 11, and A3 in walk_why's read sentence (both budgets, `:822`) and the doc's "which trips first" (`:798`). A4 is verified in Claims 7 and 37, A5 by walk_why with its generic arm (`:824`), and A6 by walk_has in both callers (Claim 22). A7 is verified in Claim 18; its doc comments now name c1_seeds (`:1650`, `:1753`), and no "outside_seeds' C1 part" remains (grep). A8 is verified in Claim 26, A9 in Claim 16 (at HEAD), A11 in floor's "both of main_imports' caches" text (`:1920-1921`), and A12 in the inherit rule (`:800-802`). A13's text is at `:1910-1911`, A14's in Claim 1, and A15's in walk_why's readers, link, list and seeds texts. A10, A12's TRUTH_WHERE half and A16 have override rows dated 2026-10-10 for `feat/build-loop-u2c2` (`docs/reviews/override-log.md`, last rows).

**Evidence:** `scripts/lib/dev-cycle-read.sh:792-833`, `:1438-1533`, `:1841-1952`, `docs/reviews/override-log.md` (tail), `fcf2-logs/full-build-loop-check.txt`

---

## Claim 39: Rubric B1-B5 "Fixed" / "Fixed in text"

**Location:** `docs/reviews/code-review-rubric-2026-10-10-feat-build-loop-u2c2.md` (iteration 2 tables)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** orchestrator
**Scope:** Covers B1-B5 at HEAD. Rows B4 and B5 are text; B4's wording is itself Mostly accurate in its no-`$4` case (Claim 27).

B1 is verified in Claims 16 and 35. B2: the doc now says an out-of-root link's "target's own names are read plain" (`:1380`). B3 is verified in Claim 13. B4: floor says "forks nothing but walk_why's subshell after a failed walk" (`:1921`). B5: the seeds sentence names a newline path and a failed lower-case (`:820`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:820`, `:833`, `:1373-1396`, `:1919-1922`, `fcf2-logs/old-ac078bd7.txt`

---

## Claim 40: Rubric lite fix-drift refutation: "import_readers sets IMPORT_READERS_DONE before any refusal (a refusal is memoized as an empty IMPORT_ROOTS), so a memoized refusal has DONE == KEY and reaches the `-n "$IMPORT_ROOTS"` test"

**Location:** `docs/reviews/code-review-rubric-2026-10-10-feat-build-loop-u2c2.md` (iteration 2, last paragraph)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** orchestrator
**Scope:** Covers import_readers' refusals after the key is computed. An import_home failure returns before DONE is set and is not memoized; readers_root's `import_home &&` then falls to need_root.

`IMPORT_READERS_DONE="$IMPORT_READERS_KEY"; IMPORT_ROOTS=""; ...` (`:1156`) precedes every refusal (`:1159-1184`). P4 shows the memoized refusal reaching need_root (E3).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1149-1161`, `fcf2-probe.out` (P4)

---

## Claims Requiring Attention

### Incorrect
- **Claim 30** (commit 3111ee9d): "5 new, 1 reworked" is 4 new and 1 reworked (138 → 142). Settled (A17, Accepted-immutable); no action.
- **Claim 35** (commit 07af69c0): the A9 below-a-root test was a no-op at that commit. Settled (B1, fixed in 2be3db37 with a test); no action.

### Stale
- **Claim 31** (commit 3111ee9d): "the import-name half is not taken" was superseded by 07af69c0's `.md` half (A8). A commit message cannot change; no action.

### Mostly Accurate
- **Claim 3** (`dev-cycle-read.sh:18-21`): floor exits on an unset ROOT_REAL only for a path that reaches the walk. A path an earlier rule refuses returns 0 with no root check (P1). This is fail-closed; the text could say "floor, for a path that reaches the walk".
- **Claim 10** (`dev-cycle-read.sh:794-795`, `:818`): the list stage's lower_all also lower-cases main's own `.md` names, not only the checkout's.
- **Claim 15** (`dev-cycle-read.sh:1124-1129`): "CLAUDE_CONFIG_DIR when set" means set and non-empty (`:+`). A set-empty value adds no config dir (P3).
- **Claim 27** (`dev-cycle-read.sh:1919-1922`): "forks nothing but walk_why's subshell" holds only when `$4` is given. Without it floor forks `lower` on every call (P5). build-loop.sh passes `$4`.

### Unverifiable
- **Claim 24** (`dev-cycle-read.sh:1874-1875`): "~1 ms a path" for isimported's lower and root check cannot be isolated from the per-call totals (15.0 → 1.05 ms); verifying it needs a per-fork microbenchmark on an idle machine.
- **Claim 29** (commit 3111ee9d): "6.5 ms -> 0.61 ms" reproduces as 15.0 → 1.05 ms under load 1.73. The direction and size reproduce, the absolute figures do not.

## Goal-Alignment Note

- **Success criterion (verbatim):** "a markdown report at the path your task names, structured per your skill, every finding with Severity, Location, verbatim Evidence, Confidence and Legibility-target, ending with the Goal-Alignment Note."
- **Answered:** U2c2's six walk-side items were checked against the code that runs them, by calls, callers, tests and probes. None of these checks found a behavioral mismatch at HEAD.
  - floor's cost holds for build-loop.sh's call, which passes `$4`.
  - IMPORTED_MAIN_WHY's KINDs match every `return 1`, and walk_why's `?` rule is check_line's.
  - The below-a-start or imported-`.md` refusal holds.
  - F3 is fixed and tested for both walks, and the below-a-root test now works.
  - The config dirs are in the memo key and both walk keys.
  - The c1_seeds/config_seeds split keeps main's 1593 names.
- **Verdict counts:** 31 Verified, 4 Mostly accurate, 1 Stale, 2 Incorrect, 2 Unverifiable. Both Incorrects and the Stale are commit-message claims already settled in the rubric or the override log. The four Mostly-accurate items are text imprecisions that fail closed or change nothing at the gate.
- **Severity:** none blocks the unit's goal. The Mostly-accurate items are Low; the settled Incorrects are informational.
- **Not run:** the read, git-env and hermeticity suites, and dev-cycle.bats beyond its surface test.

## Escalations

- **security-reviewer:** an unset ROOT_REAL does not stop floor from answering a path refused before the walk (Claim 3, P1). The answer is a refusal, so this is fail-closed; confirm no caller treats floor's return as proof that the root check ran. Separately, walk_why still prints absolute host paths whose characters pass NAMECHARS (B6, settled).
- **performance-reviewer:** a caller that omits floor's `$4` pays one `lower` fork per path (Claim 27, P5). build-loop.sh passes it, and the bats `floors` helper does not. A cached floor call measured 1.05 ms here against 15.0 ms on main's lib (E4). The walk_has glob over the larger list is A10's deferred row.
- **api-consistency-reviewer:** IMPORT_CONFIGS treats a set-empty CLAUDE_CONFIG_DIR as unset, but the memo key does not (Claim 15). This is harmless (same list, one extra registry read) but asymmetric. The list KIND's sentence names only the checkout's names (Claim 10).
- **architecture-review:** none beyond the settled rows (A12's TRUTH_WHERE through truthwalk deferred to U3; A16's unprefixed seed locals, documented by outside_seeds' NAME warning, Claim 18).
