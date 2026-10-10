# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2c2 (branch `feat/build-loop-u2c2`)
**Commit:** ac078bd7
**Replication:** k=1 (loop pass, decision 031)
**Scope:** iteration-1 fix range `3111ee9d..HEAD -- scripts test` (code in 07af69c0), plus commit 07af69c0's message and the iteration-1 rubric's statuses (`docs/reviews/code-review-rubric-2026-10-10-feat-build-loop-u2c2.md`)
**Checked:** 2026-10-10
**Total claims checked:** 40
**Summary:** 30 verified, 6 mostly accurate, 0 stale, 3 incorrect, 1 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`, 5 entries). No claim below matches a logged pattern. The Incorrect verdicts are a behavior mismatch (a loop's variable left empty at EOF), not a fabricated symbol. Per the brief's write-only-this-file rule, the log is not updated.

Executed-probe provenance (all run from cwd `$T`, a fresh `mktemp -d` under `/tmp/claude-1000/-workspace/843b51ad-a12f-4e61-b040-53f5def15aef/scratchpad/u2c2-review/fc2-XXXX`, since removed; outputs are kept in that scratch directory):
- **P1-P3** `bash .../u2c2-review/fc2-probe1.sh`, 2026-10-10T16:46:35Z, exit 1 (P3's intended need_root exit ended the script under `set -e`). Output: `.../u2c2-review/fc2-probe1.out`.
- **P4-P5** `bash .../u2c2-review/fc2-probe2.sh`, 2026-10-10T16:46:54Z, exit 0 (P4's inner `bash -c` exits 1 by design). Output: `.../u2c2-review/fc2-probe2.out`.
- **Suites** `bash .../u2c2-review/fc2-tests.sh` (serial bats with `TMPDIR=$T`, then shellcheck), 2026-10-10T16:47:34Z to 16:49:50Z, exit 0. Outputs: `.../u2c2-review/fc2-bats-{build-loop-check,build-loop-read,dev-cycle,fixture-git-env,hermeticity}.out`, `.../u2c2-review/fc2-shellcheck.out`.

---

## Claim 1: build-loop.sh --check help: the floor covers "a path below a start file's or an imported .md file's name ... a walk that fails refuses every path, its reason saying where, with a PATH outside pathform's characters shown as ?"

**Location:** `scripts/build-loop.sh:177-184`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two added help clauses against floor's ancestor loop and walk_why. Does not cover the help's other, unchanged clauses.
**Legibility-target:** operator reading `--help`

floor's final arm refuses below a start or an imported `.md` name:
```bash
# scripts/lib/dev-cycle-read.sh:1945-1946
      d="${d%/*}"; ! isstart "$d" && { [[ "$d" != *.md ]] || ! walk_has main "$d"; } || { FLOOR_WHY="a path below the name of an instruction or prompt file, or of a .md file one imports with @"; return 0; }
```
A failed walk is worded by walk_why (`:1940`), which replaces a path outside NAMECHARS with `?` (Claim 7). "Saying where" holds as stage plus path, and the path appears only for the KINDs that carry one (Claim 9a).

**Evidence:** `scripts/build-loop.sh:177-184`, `scripts/lib/dev-cycle-read.sh:808-826`, `:1939-1947`

---

## Claim 2: Header: "check_brief, isimported and the import walks (truthwalk and floor through them; a call the walk's caches answer checks nothing) exit 1 (need_root) unless ROOT_REAL is set, is the current directory and is a repository's top level"

**Location:** `scripts/lib/dev-cycle-read.sh:19-21`
**Type:** Error-handling / Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the walks' entry (readers_root) and cache-hit path, and an unset ROOT_REAL with a memoized import_readers refusal. Does not establish floor's behavior on paths it refuses before the walk.
**Legibility-target:** caller of the lib (a future gate script author)

An unset ROOT_REAL now always exits, even with a memoized refusal. readers_root's first test is `[[ -n "${ROOT_REAL:-}" ]]`, and failing it falls through to need_root:
```bash
# scripts/lib/dev-cycle-read.sh:832
readers_root() { { [[ -n "${ROOT_REAL:-}" ]] && import_home && import_readers_key && [[ "$IMPORT_READERS_DONE" == "$IMPORT_READERS_KEY" ]]; } || need_root; }
```
In probe P3, `import_readers` first memoized a refusal (`IMPORT_READER_WHY=bad`). Then `unset ROOT_REAL; readers_root` printed `ROOT_REAL is not set ...` and exited (fc2-probe1.out). The suite test at `test/scripts/build-loop-check.bats:1369-1371` passes too.

The parenthetical "a call the walk's caches answer checks nothing" is slightly loose. Such a call still checks that ROOT_REAL is set (the `-n` test above), and so still exits when it is unset. What it skips is the cwd and top-level checks. P4 showed a memo hit from the wrong cwd returning without need_root. Separately, floor exits only when it reaches the walk: a path refused earlier, such as a dot path, returns 0 with no check (paraphrased — no quote available because this is the order of floor's elif arms at `:1926-1938`, not one line).

**Evidence:** `scripts/lib/dev-cycle-read.sh:19-21`, `:163-167`, `:832`, `:1922-1948`; fc2-probe1.out (P3), fc2-probe2.out (P4)

---

## Claim 3: Contract items 4 and 9: both walk keys hold "import_readers' roots, homes and config dirs"; IMPORT_CONFIGS is among the values never set by hand

**Location:** `scripts/lib/dev-cycle-read.sh:83-89`, `:100-103`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two walk keys and import_readers' assignment of IMPORT_CONFIGS. Does not establish that no caller sets it (grep found none outside the lib).
**Legibility-target:** caller of the lib

```bash
# scripts/lib/dev-cycle-read.sh:1626 (tree), :1702 (main)
  [[ "$IMPORTED_DONE" == "$IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES"$'\n\n'"$IMPORT_CONFIGS" ]] && ...
  [[ "$IMPORTED_MAIN_DONE" == "$MAIN_SHA $MAIN_BY_NAME $IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES"$'\n\n'"$IMPORT_CONFIGS" ]] && ...
```
IMPORT_CONFIGS is computed inside import_readers (`:1191-1192`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1155`, `:1191-1192`, `:1626`, `:1702`

---

## Claim 4: Walk docs: the tree walk's cache is "keyed on import_readers' roots (ROOT_REAL first), homes and config dirs (IMPORT_CONFIGS)"; main's is "cached for the commit, MAIN_BY_NAME and import_readers' roots, homes and config dirs"

**Location:** `scripts/lib/dev-cycle-read.sh:697-699`, `:730-731`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the key strings. Does not cover IMPORT_OUT_MAX/IMPORT_WORK_MAX, which are not in the key (contract item 4 says so).
**Legibility-target:** performance critic / caller

The keys are the same lines quoted in Claim 3 (`:1626`, `:1702`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1626`, `:1629`, `:1702`, `:1705`

---

## Claim 5: IMPORTED_MAIN_WHY doc: "read PATH (... within IMPORT_WORK_MAX and the parser's share of IMPORT_OUT_MAX, which trips first) or budget (the rest of IMPORT_OUT_MAX)"

**Location:** `scripts/lib/dev-cycle-read.sh:796-799`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers a parsed read (blob or checkout file) under contract item 1's LC_ALL=C. Does not establish by execution which bound trips for import_outside's two summed parts, outside_proj's appended names or a symlink's text. Those are the outputs the parser's per-call bound does not cap, and they reach the `budget` check.
**Legibility-target:** operator reading a floor refusal

The parser receives what is left of the budget and stops once it has printed past that:
```bash
# scripts/lib/dev-cycle-read.sh:994
  seen[out] = 1; printed += length(out) + 1; if (printed - 1 > left) exit 3
```
The value comes from `IT_LEFT="${IMPORT_LEFT:-$IMPORT_OUT_MAX}"` (`:1233`), and each walk sets `IMPORT_LEFT=$((IMPORT_OUT_MAX - used))` (`:1786-1789`). The bash-side check counts the same characters, so for a parsed read the parser trips at the same total, first:
```bash
# scripts/lib/dev-cycle-read.sh:1810
    (( (used += ${#out}) <= IMPORT_OUT_MAX )) || { IMPORTED_MAIN=error; IMPORTED_MAIN_WHY=budget; return 1; }
```

**Evidence:** `scripts/lib/dev-cycle-read.sh:994`, `:1058`, `:1233`, `:1253-1260`, `:1282-1292`, `:1786-1810`

---

## Claim 6: "Each stage sets its KIND before it runs, so a failure a stage adds reports that stage (one with its own KIND sets it where it fails)."

**Location:** `scripts/lib/dev-cycle-read.sh:800-802`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every `return 1` in main_imports (read whole). Does not establish the wording's accuracy per KIND (Claims 9a/9b).
**Legibility-target:** maintainer adding a return to main_imports

The stage markers are `IMPORTED_MAIN_WHY=main` (`:1706`), `=tree` (`:1707`), `=list` (`:1728`), `=seeds` (`:1743`), `=copies` (`:1753`) and `="read $f"` per pop (`:1763`). The arms that set their own KIND where they fail are `readers` (`:1701`), `link ...` (`:1727`), `start $f` (`:1737`), `admit $p` (`:1800`, `:1818`), `budget` (`:1810`) and the in-loop `copies` (`:1821`). The walk ends with `IMPORTED_MAIN_WHY=""` (`:1825`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1696-1826`

---

## Claim 7: walk_why: "A PATH shows only when every character is one pathform allows (check_line's rule for repo text, so a crafted name prints as ?)"

**Location:** `scripts/lib/dev-cycle-read.sh:805-807`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the character test only, which is what the claim states. Does not establish that a shown path passes pathform's form rules. `-x` and `../x` are shown (P2), and an outside file's absolute host path (`/home/...`) is shown whenever its characters pass.
**Legibility-target:** security reviewer (A2)

```bash
# scripts/lib/dev-cycle-read.sh:810
  [[ -z "$d" || "$d" =~ ^[$NAMECHARS]+$ ]] || d="?"
```
This is the same set as pathform's `set="^[$NAMECHARS]+\$"` (`:217`) and check_line's `[[ ! "$p" =~ ^[$NAMECHARS]+$ ]] || shown="$p"` (`scripts/build-loop.sh:842`). In P2, `read a b/CLAUDE.md` gave `? could not be read, ...` and `start d$x` gave `the checkout holds ?, ...` (fc2-probe1.out).

**Evidence:** `scripts/lib/dev-cycle-read.sh:215-217`, `:808-826`; `scripts/build-loop.sh:842`; fc2-probe1.out (P2)

---

## Claim 8: walk_why: "a // entry as its absolute path"

**Location:** `scripts/lib/dev-cycle-read.sh:807`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `//` strip. Does not cover whether showing a host path is desirable (escalated).
**Legibility-target:** operator reading a floor refusal

```bash
# scripts/lib/dev-cycle-read.sh:809
  [[ "$1" != *" "* ]] || d="${1#* }"; [[ "$d" != //* ]] || d="${d#/}"
```
In P2, `read //abs/x.md` gave `/abs/x.md could not be read, ...`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:809`; fc2-probe1.out (P2)

---

## Claim 9a: walk_why's sentences match their causes (readers "not a usable absolute path", link "at .claude or at or below a .claude/ start directory", list "listed or lower-cased, or one's name holds a newline", read "within the walk's budgets (IMPORT_WORK_MAX, IMPORT_OUT_MAX)"), and "an unknown KIND is worded, not dropped"

**Location:** `scripts/lib/dev-cycle-read.sh:812-824`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the readers, main, tree, link, list, start/admit, copies, read, budget and default arms against main_imports' and import_readers' failure points. Seeds is Claim 9b. Does not establish that the unknown arm's raw KIND is scrubbed (it prints `k` unfiltered; every KIND is lib-internal today).
**Legibility-target:** operator reading a floor refusal

The readers sentence covers import_readers' refusals: an empty, newline or `/` root, a non-absolute or newline CLAUDE_CONFIG_DIR, a failed listing or realpath (`:1158-1176`). The link sentence matches `START_LINK='/\.claude(/(rules|commands|agents|output-styles|skills)(/.*)?)?$'` (`:665`). The list sentence covers `:1729-1734`. The unknown arm is `*) echo "the walk failed (${k:-no reason recorded})" ;;` (`:824`). P2 printed `the walk failed (zzz)` and `(no reason recorded)` for an empty word.

**Evidence:** `scripts/lib/dev-cycle-read.sh:665`, `:812-824`, `:1148-1176`, `:1700-1826`; fc2-probe1.out (P2)

---

## Claim 9b: walk_why's seeds sentence: "the instruction files outside the checkout (config dirs, ancestors, other worktrees) could not be listed" (rubric A15 lists seeds among the texts fixed)

**Location:** `scripts/lib/dev-cycle-read.sh:819`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the seeds stage's failure points. Does not cover the other arms (9a).
**Legibility-target:** operator reading a floor refusal

The seeds stage also fails when a seed's path holds a newline (outside_seeds' own check), and when a prompt seed's `lower` fails:
```bash
# scripts/lib/dev-cycle-read.sh:1444
  for ow_d in "${ow_a[@]}"; do [[ "$ow_d" != *$'\n'* ]] || return 1; done
# scripts/lib/dev-cycle-read.sh:1748
    seen[$p]=1; tq+=("$p"); [[ "$f" != p* ]] || pdir[$p]="$(lower "$p")" || return 1
```
"Could not be listed" omits both. The iteration-1 report's Claim 25 named these, and the text was not changed. The precise version would add "or one's path holds a newline".

**Evidence:** `scripts/lib/dev-cycle-read.sh:819`, `:1441-1445`, `:1743-1749`

---

## Claim 10: readers_root: "need_root, unless ROOT_REAL is set and import_readers' memo already answers for its key (a hit reads nothing), so a walk never lists the registry from an unchecked directory"

**Location:** `scripts/lib/dev-cycle-read.sh:827-829`
**Type:** Invariant / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both walks' entry. The only call sites of import_readers are the two walks and import_targets, and import_targets runs only inside a walk. Does not establish forks. On a first call, or after HOME changes, import_home forks `realpath -m` of HOME (and `getent` when HOME is empty) before need_root runs; that reads no registry. A memoized refusal returns `readers` from an unchecked cwd without listing anything.
**Legibility-target:** security / architecture critic (A1)

The condition is quoted in Claim 2 (`:832`). import_readers lists the registry (`nul_list rs_l git worktree list --porcelain -z`, `:1160`) only on a memo miss, and a miss means readers_root has already run need_root. In P4, a first call from the right cwd passed. After `import_reset`, a call from the wrong cwd exited with `ROOT_REAL is not the current directory` before any listing (fc2-probe2.out). P5 showed `IMPORT_HOME_DONE` set by the first readers_root call.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1086-1092`, `:1143-1160`, `:1211`, `:832`, `:1624-1628`, `:1700-1704`; fc2-probe2.out (P4, P5)

---

## Claim 11: readers_root: "each walk calls it first and need_root again below its own cache check, so a call both caches answer forks no root check"; main_imports :1703 "a hit reads nothing here, so floor's cached calls fork no root check"

**Location:** `scripts/lib/dev-cycle-read.sh:829-831`, `:1703`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both walks' entry and cache-hit return. Does not cover isimported, which keeps its own need_root (`:1834`).
**Legibility-target:** performance critic

```bash
# scripts/lib/dev-cycle-read.sh:1624-1628 (tree; main at :1700-1704 is the same shape)
  readers_root
  import_readers || { IMPORTED_DONE=""; IMPORTED=error; return 1; }
  [[ "$IMPORTED_DONE" == ... ]] && { [[ "$IMPORTED" != error ]]; return; }
  need_root  # below the cache check, as in main_imports
```
In P4, a memo hit from the wrong cwd returned from readers_root without exiting (fc2-probe2.out).

**Evidence:** `scripts/lib/dev-cycle-read.sh:832`, `:1624-1628`, `:1700-1704`; fc2-probe2.out (P4)

---

## Claim 12a: prompt_marks: a live entry is marked "when its real path differs and lies below a reader root ...; any other returns 0 unmarked"

**Location:** `scripts/lib/dev-cycle-read.sh:1374-1378`, code `:1393`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a live absolute link entry whose real path lies below no reader root. Does not establish any security effect: the behavior equals main's pre-fix marking, an over-read only.
**Legibility-target:** performance critic (A9) / maintainer

The below-a-root test never refuses:
```bash
# scripts/lib/dev-cycle-read.sh:1393
    while IFS= read -r p; do [[ "$b" != "$p"/* ]] || break; done <<<"$IMPORT_ROOTS"; [[ "$b" == "$p"/* ]] || return 0
```
When no root matches, the loop ends because `read` hits EOF, and bash's `read` sets `p` to the empty string at EOF. The final test then becomes `[[ "$b" == /* ]]`, which every absolute real path passes, so the function goes on to mark. Probe P1 linked `$T/home/.claude/skills/s/SKILL.md` to `$T/opt/s/SKILL.md` with `IMPORT_ROOTS="$T/repo"`. prompt_marks returned `rc=0 rq=(docs/a.md)` and set `pext[docs/a.md]`, the same as for the into-root control. A one-line repro outside the lib printed `p=[]` then `MARKED`. The suite has no out-of-root case, so all 142 tests pass. Only a link with an unchanged real path, or a `//` entry, behaves as documented.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1388-1403`; fc2-probe1.out (P1)

---

## Claim 12b: prompt_marks: "a link out of every root, as ~/.claude/skills into /opt, projects no repo name"

**Location:** `scripts/lib/dev-cycle-read.sh:1377-1379`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers import_outside's whole-path projection of the real path. Does not establish what the target's own text yields.
**Legibility-target:** security reviewer (row 602 / F3)

The projection of a real path below no root gives only a `//` name:
```bash
# scripts/lib/dev-cycle-read.sh:1259
  if [[ "$r" != "$1" ]]; then b="$(printf '%s\n' "$r" | IMPORT_WHOLE=1 import_targets /)" && import_work b w || return 1; fi
```
OUT also holds part `a`, the target's own imports, read against the link's directory and the reader homes (`:1258`). The target's text can therefore still put repo names in OUT through an absolute `@/<root>/...` import or a `~/` name that lands below a root (paraphrased — no quote available because this follows the parser's root projection, spread across IMPORT_AWK and import_targets). The precise version: the link's own projection yields no repo name, and OUT can still hold repo names from the target's imports. With 12a's defect those names are marked as prompts.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1253-1261`, `:1206-1234`

---

## Claim 13: outside_seeds: "Items (1) and (2) are config_seeds', (3) is c1_seeds' ... It returns 1 when either does, or a seed's path holds a newline."

**Location:** `scripts/lib/dev-cycle-read.sh:1436-1440`
**Type:** Architectural / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the wrapper and both helpers' entry and return paths. Does not cover the keep-rules' content (unchanged from 3111ee9d).
**Legibility-target:** maintainer

```bash
# scripts/lib/dev-cycle-read.sh:1441-1445
outside_seeds() {
  local -n ow_a="$1"; local ow_d
  config_seeds "$1" || return 1; c1_seeds "$1" || return 1
  for ow_d in "${ow_a[@]}"; do [[ "$ow_d" != *$'\n'* ]] || return 1; done
}
```
config_seeds starts with `os_a=()` (`:1450`), and c1_seeds only appends (`c1_a+=`, `:1530`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1441-1531`

---

## Claim 14: "NAME must not be one of the three functions' locals (a nameref to one reads that local)"

**Location:** `scripts/lib/dev-cycle-read.sh:1439-1440`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two callers' argument (`sd`) against all three functions' locals. Does not cover future callers.
**Legibility-target:** maintainer adding a caller

outside_seeds passes the caller's NAME to both helpers, and each binds it with its own `local -n`. A NAME equal to a local of any of the three therefore resolves to that local (paraphrased — no quote available because this is bash's dynamic scoping across three function bodies). Both walks call `outside_seeds sd` (`:1641`, `:1744`), and `sd` is not among `ow_a ow_d`, config_seeds' locals (`:1449`) or c1_seeds' (`:1506`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1441-1449`, `:1505-1507`, `:1641`, `:1744`

---

## Claim 15: config_seeds "returns 1 when a find, grep, realpath or lower_all fails"

**Location:** `scripts/lib/dev-cycle-read.sh:1446-1447`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each `return 1` in config_seeds. A python3 failure on installed_plugins.json falls back to the cache directory and does not fail, which the claim's list correctly leaves out.
**Legibility-target:** maintainer

The returns are the three `find -L` lists (`:1473-1478`), `find -H` (`:1483`), `lower_all` (`:1484`), `with_at` (grep, `:1490`) and `xargs ... realpath` (`:1493`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1448-1499`

---

## Claim 16: Walk comments: "c1_seeds skips another root's start that has the same kind here only because every start passes through here, pdir already set"

**Location:** `scripts/lib/dev-cycle-read.sh:1652-1653`, `:1751-1752`
**Type:** Staleness / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the renamed reference and the skip it describes. No "C1 part" text remains in scripts/ or test/ (grep).
**Legibility-target:** maintainer

```bash
# scripts/lib/dev-cycle-read.sh:1529
    [[ ! -L "${cx[i]}" && "$q" == "$c" ]] && isstart "$d" && rawfile "${ir[i]}" || c1_a+=("$c${cx[i]}")
```

**Evidence:** `scripts/lib/dev-cycle-read.sh:1505-1531`, `:1652`, `:1751`

---

## Claim 17: walk_has: "no fork. Ask it only after that walk succeeded (contract item 6: an error list holds nothing)"

**Location:** `scripts/lib/dev-cycle-read.sh:1839-1845`
**Type:** Performance / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers walk_has and its three call sites. Does not cover the glob's per-call cost (override row, A10).
**Legibility-target:** caller of the lib

```bash
# scripts/lib/dev-cycle-read.sh:1842-1845
walk_has() {
  if [[ "$1" == main ]]; then local -n wh_l=IMPORTED_MAIN; else local -n wh_l=IMPORTED; fi
  [[ "$wh_l" == *$'\n'"$2"$'\n'* ]]
}
```
isimported (`:1836-1837`) and truthwalk (`:1881-1883`) call it only after `main_imports || return 0` or `imported_names || return 0`. floor calls it in its final arm (`:1946`), which is reached only when `truthwalk main` returned 1, meaning the walk succeeded.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1832-1845`, `:1879-1885`, `:1939-1947`

---

## Claim 18: truthwalk: "through walk_has as isimported does, but with no lower"; "an upper-case letter (TRUTH_WHY=imported; both callers run truthrule's case word first)"

**Location:** `scripts/lib/dev-cycle-read.sh:1871-1877`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers both callers, dev-cycle.sh check_fix and floor. Does not cover any third caller (grep found none).
**Legibility-target:** maintainer / api-consistency critic

```bash
# scripts/dev-cycle.sh:182,185
  if truthrule "$lp" && [[ "$TRUTH_WHY" == cycle ]]; then ...
  elif truthwalk tree "$lp"; then
# scripts/lib/dev-cycle-read.sh:1926 (floor)
  if truthrule "$lp"; then
```
In check_fix, a non-empty TRUTH_WHY skips at `:183` before truthwalk runs. In floor, `case` is an arm of the first test.

**Evidence:** `scripts/dev-cycle.sh:176-190`; `scripts/lib/dev-cycle-read.sh:1879-1885`, `:1922-1938`

---

## Claim 19: floor: "$4, optional, $1 lower-cased (build-loop.sh passes it ...; floor then reads only $4, so the two must agree ...)"

**Location:** `scripts/lib/dev-cycle-read.sh:1907-1909`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers floor's body and srules/check_line's argument. Does not cover callers other than build-loop.sh (dev-cycle.sh does not call floor).
**Legibility-target:** caller of floor

```bash
# scripts/lib/dev-cycle-read.sh:1923-1925
  local lp="${4-}" d
  FLOOR_WHY=""
  [[ -n "$lp" ]] || lp="$(lower "$1")" || ...
# scripts/build-loop.sh:671
  if [[ -z "$5" ]] && floor "$2" "$1" "$4" "$3"; then DENY="$FLOOR_WHY"; return 0; fi
```
`$1` is not read again after `:1925`. srules' `$3` comes from check_line's `lower_all` over every path (`scripts/build-loop.sh:840`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1922-1948`; `scripts/build-loop.sh:671`, `:840-845`

---

## Claim 20: floor: "a path below a start file's name or an imported .md name is refused too"

**Location:** `scripts/lib/dev-cycle-read.sh:1912-1914`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the not-imported branch with a successful walk. A failed walk refuses everything anyway. Does not cover a non-.md import name (Won't-Fix row).
**Legibility-target:** security reviewer (row 608, A8)

The code is quoted in Claim 1 (`:1946`). The suite test at `test/scripts/build-loop-check.bats:1374-1380` (`see @docs/new.md`) refuses `docs/new.md/n.txt` and passes `docs/x.txt` and `docs/ne/x.txt`. It passed in the serial run (build-loop-check 142 ok).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1943-1947`; `test/scripts/build-loop-check.bats:1374-1380`; fc2-bats-build-loop-check.out

---

## Claim 21: floor: "so a call both of main_imports' caches answer (import_readers' memo and the walk's) forks nothing; neither changes within a gate decision"

**Location:** `scripts/lib/dev-cycle-read.sh:1917-1919`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers floor's body with `$4` given, on both a successful and a failed cached walk, plus check_line's reset. Does not measure the fork's cost.
**Legibility-target:** performance critic (A11)

This holds when the cached walk succeeded: truthrule, isstart, ownfile and walk_has are all `[[ ]]` tests. When the cached walk failed, floor builds its reason with a command substitution, and that forks a subshell on every call:
```bash
# scripts/lib/dev-cycle-read.sh:1940
    if [[ "$TRUTH_WHY" == walk ]]; then FLOOR_WHY="the default branch's instruction files could not be walked for @ imports: $(walk_why "$IMPORTED_MAIN_WHY")"
```
The fix range introduced this fork; the 11-arm `case` it replaced ran in-shell. "Neither changes within a gate decision" holds. check_line calls `import_reset` once per brief (`scripts/build-loop.sh:784`), and the key inputs (ROOT_REAL, HOME, CLAUDE_CONFIG_DIR, the reader lists, MAIN_SHA) are not changed between paths. The precise version would say "on a walk that succeeded", or note the walk_why fork per refused path.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1922-1948`; `scripts/build-loop.sh:780-784`, `:840-845`

---

## Claim 22: Commit 07af69c0, A1: "readers_root runs need_root unless ROOT_REAL is set and import_readers' memo answers for its key; both walks call it first and need_root again below their cache check, so an unset ROOT_REAL exits again (tested), the registry is never listed from an unchecked directory, and a cached tree walk forks no root check either"

**Location:** commit `07af69c0` message
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the same mechanism as Claims 2, 10 and 11, plus the test. "A cached tree walk forks no root check" holds for imported_names and truthwalk tree. isimported tree still runs its own need_root (`:1834`).
**Legibility-target:** reviewer reading the commit

See Claims 10 and 11 for the quotes. The test at `test/scripts/build-loop-check.bats:1369-1371` passes.

**Evidence:** `scripts/lib/dev-cycle-read.sh:832`, `:1624-1628`, `:1700-1704`; fc2-probe1.out (P3), fc2-probe2.out (P4), fc2-bats-build-loop-check.out

---

## Claim 23: Commit, A2: "walk_why shows a path only when every character is one pathform allows, else ? (tested); a // entry as its absolute path"

**Location:** commit `07af69c0` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claims 7 and 8: characters only. Host absolute paths still show (escalated).
**Legibility-target:** security reviewer

The test at `test/scripts/build-loop-check.bats:1360-1364` (`'a b/CLAUDE.md'` gives `?`) passes, and P2 confirms.

**Evidence:** `scripts/lib/dev-cycle-read.sh:808-811`; fc2-probe1.out (P2)

---

## Claim 24: Commit, A5/A15: "floor's wording moved to walk_why (word to sentence, as entry_why); readers, link, list texts made exact; an unknown KIND is worded, not dropped"

**Location:** commit `07af69c0` message
**Type:** Architectural / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three named texts and the default arm (Claim 9a). The seeds text, which the bullet does not name, is Claim 9b.
**Legibility-target:** reviewer reading the commit

See Claim 9a. floor now calls `$(walk_why "$IMPORTED_MAIN_WHY")` (`:1940`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:808-826`, `:1939-1941`

---

## Claim 25: Commit, A3: "read's wording names both budgets"

**Location:** commit `07af69c0` message
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the read arm's text.
**Legibility-target:** reviewer reading the commit

`read) echo "$d could not be read, or its imports parsed within the walk's budgets (IMPORT_WORK_MAX, IMPORT_OUT_MAX), ..."` (`:822`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:822`

---

## Claim 26: Commit, A6: "walk_has, the one membership test isimported and truthwalk share"

**Location:** commit `07af69c0` message
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the lib. floor's ancestor loop is a third caller, which the bullet does not name.
**Legibility-target:** reviewer

See Claim 17.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1837`, `:1883`, `:1946`

---

## Claim 27: Commit, A7: "config_seeds plus a three-call outside_seeds wrapper; comments name c1_seeds"

**Location:** commit `07af69c0` message
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the wrapper shape. Reading "three-call" as config_seeds, c1_seeds and the newline loop is an interpretation.
**Legibility-target:** reviewer

See Claims 13 and 16.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1441-1445`, `:1652`, `:1751`

---

## Claim 28: Commit, A8: "floor refuses a path below an imported .md name too (tested: docs/new.md/n.txt refuses, docs/ne/x.txt passes)"

**Location:** commit `07af69c0` message
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** See Claim 20.
**Legibility-target:** reviewer

The test passes in the serial run.

**Evidence:** `test/scripts/build-loop-check.bats:1374-1380`; fc2-bats-build-loop-check.out

---

## Claim 29: Commit, A9: "prompt_marks marks a live entry only when its real path lies below a reader root (the user's skills link into /opt)"

**Location:** commit `07af69c0` message
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Same defect as Claim 12a.
**Legibility-target:** reviewer / performance critic

A live link into `/opt`, which is outside every root, is still marked, because `p` is empty after `read` hits EOF (`:1393`; P1 `rq=(docs/a.md)`). No test covers the out-of-root case.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1393`; fc2-probe1.out (P1)

---

## Claim 30: Commit, "A4, A11-A14: docs (cache keys, contract item 9, floor's $4 and cache wording, the stage-marker rule, --check help); dev-cycle.bats' surface inventory lists the new functions and globals"

**Location:** commit `07af69c0` message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that each named doc changed and that the inventory lists config_seeds, c1_seeds, walk_why, walk_has, readers_root, IMPORT_CONFIGS and IMPORTED_MAIN_WHY. The accuracy of the cache wording itself is Claim 21.
**Legibility-target:** reviewer

The inventory is at `test/scripts/dev-cycle.bats:1111`, `:1115`. The docs are Claims 3, 4, 6, 19, 21 and 1.

**Evidence:** `test/scripts/dev-cycle.bats:1109-1116`; diff `3111ee9d..07af69c0`

---

## Claim 31: Commit: "Commit 3111ee9d's counts, corrected: build-loop-check gained 4 new tests and 1 reworked (142 total); 266 was the size gate's count"

**Location:** commit `07af69c0` message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `@test` counts and the `+@test`/`-@test` lines of `main..3111ee9d`. 266 is taken from 3111ee9d's own message (not recomputed).
**Legibility-target:** reviewer

`grep -c '^@test'` gives main 138, 3111ee9d 142, 07af69c0 142. The diff shows 4 added `@test` lines and 1 renamed.

**Evidence:** `test/scripts/build-loop-check.bats` at main, 3111ee9d and 07af69c0

---

## Claim 32: Commit: "Tests: build-loop-check 142, read 20, dev-cycle 79, git-env 2, hermeticity 2 (serial); shellcheck clean"

**Location:** commit `07af69c0` message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the five suites at HEAD (ac078bd7; scripts/ and test/ are unchanged since 07af69c0) and shellcheck at the health-check's severity. Does not cover the shellcheck default severity: info and style findings are reported (SC2016, SC2004, SC2015, all pre-existing; main's lib has 14 too).
**Legibility-target:** reviewer

The run printed `build-loop-check rc=0 142 ok, 0 not ok`, `build-loop-read rc=0 20 ok`, `dev-cycle rc=0 79 ok`, `fixture-git-env rc=0 2 ok` and `fixture-hermeticity rc=0 2 ok`. `shellcheck -S warning scripts/lib/dev-cycle-read.sh scripts/build-loop.sh scripts/dev-cycle.sh` exited 0; that is the health check's `-S warning` (`scripts/health-check.sh:480`).

**Evidence:** fc2-bats-*.out, fc2-shellcheck.out; command `bash fc2-tests.sh` (cwd `$T`, exit 0, 2026-10-10T16:47:34Z-16:49:50Z)

---

## Claim 33: Commit: "both walks over this repository give main's 1593 names"

**Location:** commit `07af69c0` message
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Not run. Would need both walks run over /workspace (a shared checkout, and the registry is time-varying), compared against main's lib.
**Legibility-target:** reviewer

Not executed (paraphrased — no quote available because the claim concerns a run against the shared /workspace checkout, whose registry and files change between sessions, and this pass reads only the worktree). Blocker: a time-varying shared state, plus 2-3.5 s per walk per lib.

**Evidence:** commit `07af69c0` message

---

## Claim 34: Commit: "349 changed code lines against main"

**Location:** commit `07af69c0` message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the size gate's command (`workflows/pr-prep.md:86-92`), which counts comments and tests.
**Legibility-target:** reviewer (size gate)

`git diff --numstat main...HEAD -- . ':!docs'` gives 7+4, 178+80, 72+4 and 2+2, which sum to 349. The result is the same at 07af69c0 and at HEAD.

**Evidence:** `workflows/pr-prep.md:86-92`; command run in `/workspace/.claude/wt-build-loop-u2c2`, exit 0

---

## Claim 35: Rubric: A1, A2, A3, A4, A5, A6, A7, A8, A12, A13, A14 "Fixed" (or "Doc fixed" / "Fixed in text")

**Location:** `docs/reviews/code-review-rubric-2026-10-10-feat-build-loop-u2c2.md` (Must Address and Consider tables)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each status against the code: A1 (Claims 10, 11, 22), A2 (7, 8), A3 (5, 25), A4 (3, 4, 30), A5 (9a), A6 (17, 18), A7 (13, 16), A8 (20), A12 (6), A13 (19), A14 (1). A2 filters characters only and does not remove host paths.
**Legibility-target:** orchestrator synthesizing the iteration-2 rubric

See the cited claims.

**Evidence:** as cited per item

---

## Claim 36: Rubric A9: "Fixed: prompt_marks marks a live entry only when its real path lies below a reader root."

**Location:** `docs/reviews/code-review-rubric-2026-10-10-feat-build-loop-u2c2.md` (A9 row)
**Type:** Reference / Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 12a.
**Legibility-target:** orchestrator

The fix is a no-op (`:1393`, P1). A9's over-read is unchanged.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1393`; fc2-probe1.out (P1)

---

## Claim 37: Rubric A11: "floor's cached call still forks when import_readers' memo misses ... Fixed in text."

**Location:** `docs/reviews/code-review-rubric-2026-10-10-feat-build-loop-u2c2.md` (A11 row)
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the new floor text (Claim 21).
**Legibility-target:** orchestrator

The text now names both caches, but it overstates "forks nothing" for a cached failed walk, where `$(walk_why ...)` forks once per path (`:1940`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1917-1919`, `:1940`

---

## Claim 38: Rubric A15: "Wording nits: readers ..., link ..., list/seeds (a newline name, a short lower_all). Fixed in walk_why's text."

**Location:** `docs/reviews/code-review-rubric-2026-10-10-feat-build-loop-u2c2.md` (A15 row)
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the four named texts.
**Legibility-target:** orchestrator

The readers, link and list texts are fixed (Claim 9a). The seeds text is unchanged (Claim 9b).

**Evidence:** `scripts/lib/dev-cycle-read.sh:812-819`

---

## Claims Requiring Attention

### Incorrect
- **Claim 12a** (`scripts/lib/dev-cycle-read.sh:1374-1378`, `:1393`): prompt_marks' below-a-root test never refuses. After the loop ends at EOF, `read` has left `p` empty, so `[[ "$b" == "$p"/* ]]` matches every absolute path. A live link out of every root is still marked (P1).
- **Claim 29** (commit 07af69c0, A9 bullet): same defect. The claimed fix is a no-op, and no test covers it.
- **Claim 36** (rubric A9 "Fixed"): same defect.

### Stale
- None.

### Mostly Accurate
- **Claim 2** (`scripts/lib/dev-cycle-read.sh:19-21`): "a call the walk's caches answer checks nothing". Such a call still exits on an unset ROOT_REAL; it skips only the cwd and top-level checks.
- **Claim 9b** (`scripts/lib/dev-cycle-read.sh:819`): the seeds sentence omits a newline seed path and a failed prompt-seed lower.
- **Claim 12b** (`scripts/lib/dev-cycle-read.sh:1377-1379`): "projects no repo name" holds for the link's projection, but OUT can still hold repo names from the target's own imports.
- **Claim 21** (`scripts/lib/dev-cycle-read.sh:1917-1919`): "forks nothing" fails on a cached failed walk, since `$(walk_why ...)` at `:1940` forks per path. The fix range added this fork.
- **Claim 37** (rubric A11): "Fixed in text" carries Claim 21's overstatement.
- **Claim 38** (rubric A15): the seeds text was not changed.

### Unverifiable
- **Claim 33** (commit 07af69c0): "both walks give main's 1593 names" would need both libs' walks run over the shared /workspace checkout, whose state is time-varying.

## Goal-Alignment Note

The fix range's purpose was to close iteration 1's A1-A15 without new defects. Most of the fixes match their claims, and the suites pass serially. The exception is A9: prompt_marks' root test is a no-op, so the performance fix it claims does not exist. It is not a security regression, because behavior equals the pre-fix marking. The fix also added one per-path fork on a failed cached walk (walk_why via `$(...)`). That contradicts floor's own "forks nothing" doc but costs only on a decision that already refuses every path. Both are small text or code corrections, and neither blocks the unit's goal once A9 is either fixed (for example, testing the match inside the loop, or using a flag variable) or re-filed.

## Escalations

- **performance-reviewer:** prompt_marks' A9 fix is a no-op (Claim 12a, P1). The ~109-name over-read per main walk from `~/.claude/skills` links into `/opt` remains. Also, floor forks `$(walk_why ...)` on every path when the cached walk failed (Claim 21).
- **security-reviewer:** walk_why filters characters only. An outside file's absolute host path (`/home/<user>/...`, a reader root's host spelling) still prints into deny rows whenever its characters pass NAMECHARS (Claims 7 and 8; P2 `/abs/x.md`). Separately, with the A9 fix repaired as intended, an out-of-root live link's target text could still add repo names to OUT through absolute or `~/` imports, and those would then be read unmarked (Claim 12b). Confirm that is only the documented over-read and not an F3 regression. The unknown-KIND arm prints its raw word unfiltered (`:824`; lib-internal today).
- **api-consistency-reviewer:** walk_why's seeds sentence diverges from its cause set, while readers, link and list were made exact (Claim 9b). The header's "checks nothing" parenthetical (Claim 2).
- **architecture-review:** a memoized import_readers refusal skips need_root, so a wrong-cwd call returns a `readers` reason instead of exiting (Claim 10's scope). This is consistent with the "cache answers checks nothing" design, but it is the one case where the cause reported is not the root check.
