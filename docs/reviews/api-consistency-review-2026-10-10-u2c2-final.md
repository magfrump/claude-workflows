Commit: 8786f8fc

# API Consistency Review: feat/build-loop-u2c2 (U2c2, final confirming pass)

**Scope:** `git diff main...HEAD -- scripts test` (3111ee9d, 07af69c0, 2be3db37), read on the final code at 8786f8fc: `scripts/lib/dev-cycle-read.sh`, `scripts/build-loop.sh`, `test/scripts/build-loop-check.bats`, `test/scripts/dev-cycle.bats`
**Date:** 2026-10-10
**Based on:** Stage-1 summary `fc-final-summary.md` (k=3: `code-fact-check-report-build-loop-u2c2-final-r{1,2,3}.md`). Behavior it verified is not re-verified here. Also read: my iteration-1 report `api-consistency-review-2026-10-10-u2c2.md`, the rubric `code-review-rubric-2026-10-10-feat-build-loop-u2c2.md`, and override-log rows 626-632.
**Reviewer:** apif (API-consistency critic, final pass)

## Baseline Conventions

The baseline is the same one iteration 1 recorded. It is unchanged on main, so here is a summary:

- **A word, and a function that words it.** `main_entry` prints a word and `entry_why` words it (`dev-cycle-read.sh:340-374`). `fence` gives a reason and `oddwhy` words it (`:308-318`). A word can carry one argument after a space (`notdir PART`). entry_why keeps its output to one line.
- **Words each caller words.** `TRUTH_WHY` is worded by each caller itself (`:1857`).
- **Result variables.** `<THING>_WHY` sits beside its data. import_readers' results are named `IMPORT_<PLURAL>` and are newline lists with no trailing newline. Contract item 9 lists the variables a caller must never set.
- **Nameref-taking functions.** These take `NAME` first and bind a local `<initials>_<x>` nameref: `pd_m`, `pb_a`, `op_o`, `wa_a`, `rc_q`, `pm_p`, `iw_o`, `nl_a`, `mc_e` (`:670-1596`).
- **Predicates and checks.** Predicates are `is*`/`*_by_name`/`ownfile`/`writable`. The one root check is `need_root` (`:163`), named verb-object.
- **Failed walks fail closed.** Contract item 6 (`:87-88`) says a walk is read only through isimported or truthwalk, because `IMPORTED_MAIN=error` reads as "not imported" to a raw membership test. isimported and truthwalk both answer 0 (imported/refuse) when the walk fails.
- **Memo keys.** A memo key may tell set-empty from unset even when the result treats the two alike. Precedent: import_home's key `x${HOME+set}:${HOME-}` (`:1088`), while its result reads "unset or empty" as the passwd entry (`:1081-1082`).
- **`--check` help vocabulary.** The help speaks of "instruction and prompt files" (`build-loop.sh:178`). It shows a PATH as `?` "unless every character is one pathform allows" (`:160-161`). Deny strings carry the pinned prefix `WALKFAIL` (`build-loop-check.bats:43`).

## Status of iteration-1 findings

| i1 # | Status at 8786f8fc |
|---|---|
| 1 (root check after import_readers) | Fixed. `readers_root` (`:833`) runs before import_readers in both walks. The bats test at `build-loop-check.bats:673-674` pins the unset-ROOT_REAL exit for a walked path. |
| 2 (truthwalk upper case as `imported`) | Doc-resolved. Item 8 and the truthwalk doc state it (rubric A6). Not re-filed. |
| 3 (read/budget wording) | Fixed (`:797-799`, `:822`). |
| 4 (IMPORT_CONFIGS in item 9, cache-key docs) | Fixed (`:103`, `:698-699`, `:731`). |
| 5 (`--check` help) | Fixed (`build-loop.sh:179-184`). Finding 6 below covers one vocabulary point. |
| 6 (inline wording) | Fixed: `walk_why` follows the entry_why pattern. The tree-walk asymmetry is settled by row 630. |
| 7 (c1_seeds locals) | Deferred by row 628 (settled). Finding 5 below covers a different naming point. |

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `walk_why WHY` | function (word → sentence) | `entry_why WORD [PATH]`, `oddwhy WORD` | `dev-cycle-read.sh:308-318, 364-374` | Consistent. It is a `<noun>_why` wording function over a "KIND [ARG]" word and prints one line (a newline path becomes `?`). Three sentences under-describe their KIND (Finding 2). |
| `walk_has WALK LP` | predicate | `isimported WALK PATH`, `isstart`, `main_by_name` | `:1834-1840, 666, 324` | Name and argument order are consistent (WALK first, like isimported). Its failure semantics differ from its siblings, and contract item 6 does not admit it (Finding 1). |
| `readers_root` | check (may exit) | `need_root`, `import_reset`, `import_home` | `:163, 835, 1087` | Inconsistent. It is a noun phrase for a function that may exit (Finding 3). |
| `config_seeds NAME`, `c1_seeds NAME` | nameref function | `outside_seeds NAME`, `with_at NAME`, `root_copies` | `:1303-1447` | Consistent signatures: NAME first, and "array NAME gets" or "appends ... to array NAME" says which one clears. Nameref prefixes are the subject of Finding 5. |
| `ow_a`, `ow_d` (outside_seeds), `os_a`/`os_s`/`os_at` (config_seeds), `c1_a`/`c1_at`, `wh_l` | nameref / prefixed local | `pm_p`, `rc_q`, `wa_a`, `nl_a` | `:670-1596` | `c1_` and `wh_` follow the initials rule. config_seeds keeps the old wrapper's `os_` and the wrapper takes `ow_`, which inverts it (Finding 5). |
| `IMPORTED_MAIN_WHY` | global result var | `TRUTH_WHY`, `FLOOR_WHY`, `BRIEF_ODD` | `:803, 1860, 1923` | Consistent: `<RESULT>_WHY` beside `IMPORTED_MAIN`, in the surface inventory (`dev-cycle.bats:1111`). |
| KIND words `readers main tree link list start admit seeds copies read budget` | enum | main_entry's words, TRUTH_WHY's words | `:328-330, 1852-1856` | Consistent: bare lower-case nouns. Every value set in main_imports has a walk_why arm, and the `*` arm catches the rest. |
| `IMPORT_CONFIGS` | import_readers result | `IMPORT_ROOTS`, `IMPORT_HOMES`, `IMPORT_OTHER` | `:1132, 1196-1205` | Consistent shape and lifecycle, and it is in item 9's list. Its doc under-describes it (Finding 4). |
| floor `$4` | optional parameter | `entry_why [PATH]`, prompt_dir's lowered + spelled pair | `:364, 670` | Consistent: optional and last. srules passes it (`build-loop.sh:671`). |
| deny "a path below the name of an instruction or prompt file, or of a .md file one imports with @" | deny string | nrules' "a path below one of those names" | `build-loop.sh:173-174` | Consistent phrasing. |
| deny `WALKFAIL: <walk_why sentence>` | deny string | `WALKFAIL: the reader settings of docs/dev-cycle.md cannot be used: WHY` | `build-loop-check.bats:43` | Consistent. The prefix is stable, and the readers wording is kept byte-for-byte. |
| help "a path below a start file's or an imported .md file's name" | CLI help | the help's "instruction and prompt files", the deny string's "instruction or prompt file" | `build-loop.sh:178`, `dev-cycle-read.sh:1948` | Introduces lib jargon into the help (Finding 6). |

## Findings

#### 1. walk_has is a raw membership test that contract item 6 forbids callers to use, and it fails open on an error list, unlike isimported and truthwalk

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:87-88` (contract item 6), `:1841-1847` (walk_has), `:1948` (floor's call)
**Move:** 3 (consumer contract: documentation drift), 4 (error consistency: failure semantics)
**Confidence:** High (probe P1: with `IMPORTED_MAIN=error`, `walk_has main docs/a.md` returns 1, "not has")
**Legibility-target:** a second gate caller reading the contract (item 6), and lib maintainers adding a walk_has call

Evidence:
```
#  6. Read a walk only through isimported or truthwalk: IMPORTED_MAIN=error
#     reads as "not imported" to a raw membership test (row 419).
```
```bash
# walk_has WALK LP: whether the list of the walk WALK names (main or tree), as
# its last call left it, holds LP, a lower-cased path: no fork. Ask it only
# after that walk succeeded (contract item 6: an error list holds nothing).
walk_has() {
  if [[ "$1" == main ]]; then local -n wh_l=IMPORTED_MAIN; else local -n wh_l=IMPORTED; fi
  [[ "$wh_l" == *$'\n'"$2"$'\n'* ]]
}
```
```bash
# floor :1942-1948 (excerpt; floor ends :1952, read whole)
  elif truthwalk main "$lp"; then
  ...
  else
    d="$lp"; while [[ "$d" == */* ]]; do
      d="${d%/*}"; ! isstart "$d" && { [[ "$d" != *.md ]] || ! walk_has main "$d"; } || { FLOOR_WHY="..."; return 0; }
```

walk_has is the raw membership test item 6 forbids. It now ships as a named, inventoried lib function (`dev-cycle.bats:1105`), and the lib's own floor calls it. floor's use is safe: the else arm runs only when truthwalk answered 1, which needs `main_imports` to have returned 0 in that call. The two documents disagree, though. Item 6, "the one statement" of the caller's duties (`:50`), still says "only through isimported or truthwalk". walk_has's doc cites item 6 for a rule item 6 does not state ("ask only after the walk succeeded"). Its siblings fail closed: isimported answers 0 and truthwalk answers 0 with `walk` on a failed walk. walk_has answers 1 on `error`, which is the fail-open item 6 exists to prevent. A future caller that reads walk_has's one-line doc rather than the contract inherits that hazard. This is the Stage-1 escalation, confirmed.

**Recommendation:** Make walk_has fail closed at no cost, for example `[[ "$wh_l" != error ]] || return 0` (no current caller changes, since all of them call it only after a success). Then amend item 6: "Read a walk only through isimported, truthwalk, or walk_has after that walk returned 0 (floor's below-a-name loop does)".

#### 2. Three walk_why sentences name a narrower cause than their KIND covers (list, copies, start|admit)

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:818, 819, 821` (walk_why), with the stages at `:1730-1739`, `:1755-1756`, and main_checkout `:1595-1622`
**Move:** 4 (error consistency: the reason must name what to look at)
**Confidence:** High (fact-check r1, r2 and r3 each verdicted these Mostly accurate. I re-read the stages.)
**Legibility-target:** the operator reading a `deny ... WALKFAIL: ...` line and deciding what to fix

Evidence:
```
    list) echo "the checkout's .md files could not be listed or lower-cased, or one's name holds a newline" ;;
    start|admit) echo "the checkout holds $d, which the walk reads, as other than a readable plain file below plain directories" ;;
    copies) echo "another worktree's copy of an imported name could not be compared with this checkout's" ;;
```
```bash
  IMPORTED_MAIN_WHY=list
  ...
  [[ ${#cand[@]} -eq 0 ]] || nul_list low lower_all "${cand[@]}" || return 1   # cand holds main's m: names too (:1716)
  ...
  IMPORTED_MAIN_WHY=copies
  root_copies cq cmp pdir "${queue[@]}" "${tq[@]}" || return 1                 # the starts and outside seeds, not imports
```
```bash
# main_checkout :1603, :1609-1612 (excerpt; it ends :1622, read whole)
  [[ ! "${mc_e[$3]:-}" =~ ^1[26]0000$ ]] || return 1
    [[ ! "${mc_e[$c]:-}" =~ ^1[26]0000$ ]] || return 1
      elif ! plaindir "$c" || [[ ! -x "$c" ]]; then return 1; fi
```

- **`list`.** The stage's lower_all runs over main's `.md` names as well as the checkout's (`cand` gets `m:` entries at `:1716`), so "the checkout's .md files could not be ... lower-cased" can point at the wrong tree.
- **`copies`.** The first root_copies call covers the starts and outside seeds, not only imported names.
- **`start`/`admit`.** These report every `main_checkout` return 1. That includes main storing a link or gitlink at the path or at an ancestor (`:1603`, `:1609`), which is the default branch's doing, not the checkout's. It also includes a plain directory that is not searchable (`:1612`, the case the bats test at `:640` exercises). The sentence says "the checkout holds ... as other than ... below plain directories". An operator who finds plain files and plain directories in the checkout has nowhere to go. This sits beside the entry_why precedent, whose `notdir` names the exact part and whose wording never blames the wrong side.

Each still fails closed, and the deny line is advisory text, so this is Minor.

**Recommendation:** Widen each sentence by a clause:
- `list`: "the .md names (main's and the checkout's) could not be listed or lower-cased ...".
- `copies`: "a start's or imported name's copy in another worktree ...".
- `start|admit`: "... as other than a readable plain file below plain searchable directories, or the default branch stores a link or gitlink at it or above it".

The last one keeps the bats string at `:639` and `:641` matchable if they use a prefix match.

#### 3. `readers_root` is a noun phrase for a function whose job is to maybe exit; the lib names its root check verb-object (`need_root`)

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:827-833`
**Move:** 2 (naming against the grain)
**Confidence:** Medium
**Legibility-target:** lib maintainers and a second caller scanning the surface inventory for what can exit

Precedent: verb-first names for actions and checks, `need_root` used in `scripts/lib/dev-cycle-read.sh:163` (and `import_reset` :835, `import_home` :1087); `is*`/`*_by_name` for predicates (`:324, 666, 1834`)

Evidence:
```bash
readers_root() { { [[ -n "${ROOT_REAL:-}" ]] && import_home && import_readers_key && [[ "$IMPORT_READERS_DONE" == "$IMPORT_READERS_KEY" && -n "$IMPORT_ROOTS" ]]; } || need_root; }
```
Read as a name, `readers_root` says "the readers' root", a value or getter, like `IMPORT_ROOTS`. What it does is "need_root, unless import_readers' memo already answers". It is now a public, inventoried lib function (`dev-cycle.bats:1105`), and its behavior on a miss is the lib's most consequential side effect: exit 1. Contract readers learn from the header (`:19-21`) that the exit-1 checks are need_root and the functions that call it. A name built around `need_root` (`need_root_unless_cached`, `walk_need_root`) would let a reader grep that family.

**Recommendation:** Optional rename to a `need_root`-family name. If the name stays, start its comment "need_root's cached form: ..." so a grep for need_root finds it.

#### 4. IMPORT_CONFIGS' doc calls it "outside_seeds' config dirs" and "CLAUDE_CONFIG_DIR when set", but it holds only item (1)'s dirs, and an empty CLAUDE_CONFIG_DIR counts as unset

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1124-1129`, `:1146`, `:1160`, `:1198-1199`; outside_seeds' item (2) at `:1418-1420`, `:1459`
**Move:** 8 (nullability: set-empty vs unset), 3 (doc drift)
**Confidence:** High (probe P3: unset → empty CLAUDE_CONFIG_DIR changes IMPORT_READERS_KEY, leaves IMPORT_CONFIGS and IMPORTED_MAIN_DONE equal, so the walk is a cache hit)
**Legibility-target:** a maintainer adding a config source or reading the walk keys

Evidence:
```
# root_copies and outside_seeds read. IMPORT_CONFIGS holds outside_seeds'
# config dirs, newline-separated: each absolute home's .claude, then
# CLAUDE_CONFIG_DIR when set and IMPORT_MANAGED_DIR; the key holds both, ...
  local f="${CLAUDE_CONFIG_DIR+x}${CLAUDE_CONFIG_DIR-}" g="$IMPORT_MANAGED_DIR"
  IMPORT_CONFIGS+="${CLAUDE_CONFIG_DIR:+$CLAUDE_CONFIG_DIR$'\n'}$IMPORT_MANAGED_DIR"
      [[ -n "$in" || -n "${os_s[a$d]+set}" ]] || { os_s[a$d]=1; [[ ! -d "$d" ]] || tops+=("$d"); cf+=("${d%/}/.claude"); }
```
There are two small doc gaps. Neither is a defect:
- **Which config dirs.** outside_seeds' config dirs also include each root ancestor's `.claude` (item (2), `:1459`), which IMPORT_CONFIGS does not hold. Those derive from IMPORT_ROOTS, which the walks' keys already hold, so the keys are complete. Only the description "outside_seeds' config dirs" overstates.
- **Empty CLAUDE_CONFIG_DIR.** "When set" means set and non-empty in all three code sites (`:1160`, `:1199`, and outside_seeds before). The memo key tells set-empty from unset. That follows the import_home precedent (`:1088`, a key finer than the result: safe over-keying, costing one registry re-read). import_home's doc spells its rule as "unset or empty". This doc does not.

**Recommendation:** Say "item (1)'s config dirs (outside_seeds; item (2)'s ancestor dirs follow from IMPORT_ROOTS)" and "CLAUDE_CONFIG_DIR when set and not empty (the key, like import_home's, also tells empty from unset)".

#### 5. The split inverts outside_seeds' nameref prefix: config_seeds keeps `os_`, and the wrapper outside_seeds takes `ow_`

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1444`, `:1451`
**Move:** 2 (naming against the grain)
**Confidence:** High
**Legibility-target:** maintainers following a nameref to its function

Precedent: the nameref and prefixed locals take the function's initials (`pd_m` prompt_dir, `pb_a` prompt_bases, `wa_a` with_at, `rc_q` root_copies, `pm_p` prompt_marks, `nl_a` nul_list, `mc_e` main_checkout, `c1_a` c1_seeds, `wh_l` walk_has) used in `scripts/lib/dev-cycle-read.sh:670-1845`

Evidence:
```bash
outside_seeds() {
  local -n ow_a="$1"; local ow_d
config_seeds() {
  local -n os_a="$1"; local d q r c i in rs=() ... ; local -A os_s=() os_at=()
```
After the split, `os_*` names in config_seeds read as outside_seeds' own, and outside_seeds' own `ow_*` matches neither name. The cost is small: a reader following a `os_a` nameref looks in the wrong function. There is no behavioral effect. The outside_seeds doc (`:1441-1442`) already lists all three functions' locals as off-limits. This is distinct from override row 628, which is about the width of that off-limits set, not the prefixes. It can ride with that row's revisit trigger.

**Recommendation:** When row 628's trigger fires, rename config_seeds' `os_a`/`os_s`/`os_at` to `cs_*` and the wrapper's `ow_*` to `os_*`, and prefix c1_seeds' and config_seeds' remaining locals in the same edit.

#### 6. The `--check` help says "a start file's ... name", a lib-internal term, where the help and the deny string say "instruction or prompt file"

**Severity:** Informational
**Location:** `scripts/build-loop.sh:178-180`
**Move:** 2 (naming: vocabulary)
**Confidence:** High
**Legibility-target:** `--check` users reading the help to interpret a deny line

Precedent: "instruction and prompt files" used in `scripts/build-loop.sh:178`. The deny string "a path below the name of an instruction or prompt file, or of a .md file one imports with @" is in `scripts/lib/dev-cycle-read.sh:1948`.

Evidence:
```
#                 (first match): the self-merge floor (the lib's floor:
#                 instruction and prompt files and what they import with @,
#                 a path below a start file's or an imported .md file's
#                 name, dot paths, ...
```
`start file` occurs nowhere else in build-loop.sh (grep), and the help defines it nowhere. Its meaning (isstart: an instruction or prompt file) has to be imported from the lib. The deny line the operator then sees uses the help's other phrasing. This is minor, because the help line just above gives the meaning.

**Recommendation:** "a path below such a file's name or an imported .md file's name".

#### 7. The header's root-check sentence implies that floor always exits on an unset ROOT_REAL; since the diff it does so only for a path that reaches the walk

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:18-21` (header), `:1925-1952` (floor), `scripts/build-loop.sh:867`
**Move:** 3 (consumer contract: subtle semantics change)
**Confidence:** High (probe P2: with ROOT_REAL unset, `floor CLAUDE.md` returns 0 with the instr reason and no exit, and `floor docs/x.txt` exits 1 "ROOT_REAL is not set". On main, floor ran need_root first and exited for both.)
**Legibility-target:** a second gate caller relying on the exit to stop a misconfigured run

Evidence:
```
# check_brief, isimported and the import walks (truthwalk and floor through
# them; a call the walk's caches answer checks only that ROOT_REAL is set) exit 1 (need_root) unless
# ROOT_REAL is set, is the current directory and is a repository's top level;
```
```bash
# main's floor
  local lp
  need_root
# HEAD's floor :1926-1929 (excerpt; read whole)
  local lp="${4-}" d
  FLOOR_WHY=""
  [[ -n "$lp" ]] || lp="$(lower "$1")" || { ...; return 0; }
  if truthrule "$lp"; then
```
"Floor through them" is literally true: floor exits when it walks. A reader of the contract will still likely take floor to be an exiting check. Its first five rules are now pure string tests that refuse without a root check. Nothing fails open. Every early rule refuses, and build-loop.sh sets ROOT_REAL at `:329`, so its `:867` comment ("the floor's need_root exit ends the run") still holds whenever an exit happens. The behavior change is deliberate (no fork per path) and fact-check r1-r3 rated the sentence Mostly accurate. A caller's view of floor did change from main, though: it moved from "always checks the root" to "checks it when it walks", and the one statement of the contract should say which.

**Recommendation:** Add a clause: "(floor only for a path its earlier rules pass: those refuse with no root check)".

## What Looks Good

- **walk_why** brings the walk's failure words into the lib's word→sentence convention (entry_why/oddwhy). It is fork-free apart from floor's `$(...)`, it prints one line, and it applies check_line's `?` rule exactly. The `--check` help documents that rule in the same terms as the path lines (`build-loop.sh:160-161` and `:183-184`).
- **Every IMPORTED_MAIN_WHY value set in main_imports has an arm.** The doc's "each stage sets its KIND before it runs" rule makes attribution predictable, and the value is cleared on success (`:1827`) and kept with a cached failure.
- **The WALKFAIL prefix is stable** across every new detail. The readers sentence keeps the earlier text byte-for-byte when IMPORT_READER_WHY is set. Tests pin both the prefix and the new sentences.
- **floor's `$4`** is optional and last, falls back to lowering, and is documented as "must be $1 lower-cased". srules passes check_line's `lower_all` output.
- **IMPORT_CONFIGS** matches its siblings' shape. It is reset with them on a memo miss (`:1156`), keyed in both walks with the existing blank-line separator, added to contract item 9 and to the surface inventory, and its addition retires contract item 4's reset duty for CLAUDE_CONFIG_DIR and IMPORT_MANAGED_DIR, with the doc updated.
- **readers_root closes iteration 1's Finding 1** without giving up the fork-free cached path. The two walks now order their root checks identically (`:1626-1630`, `:1702-1706`).
- **config_seeds and c1_seeds** keep the NAME-first signature. Their docs distinguish "gets" (clears) from "appends", which is what makes outside_seeds' call order correct.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | walk_has is the raw membership test contract item 6 forbids; it fails open on `error`, unlike isimported/truthwalk; item 6 does not admit it | Minor | `dev-cycle-read.sh:87-88, 1841-1847, 1948` | High |
| 2 | walk_why's list/copies/start\|admit sentences name a narrower cause than their KIND covers | Minor | `dev-cycle-read.sh:818-821` | High |
| 3 | `readers_root` is a noun phrase for a maybe-exiting check (precedent `need_root`) | Minor | `dev-cycle-read.sh:827-833` | Medium |
| 4 | IMPORT_CONFIGS doc: "outside_seeds' config dirs" (only item 1's); "when set" means non-empty while the key tells empty from unset | Informational | `dev-cycle-read.sh:1124-1129, 1146` | High |
| 5 | config_seeds keeps the `os_` prefix, the wrapper takes `ow_` (inverted initials) | Informational | `dev-cycle-read.sh:1444, 1451` | High |
| 6 | `--check` help says "start file", where the help and deny string say "instruction or prompt file" | Informational | `build-loop.sh:179` | High |
| 7 | Header implies floor always exits on an unset ROOT_REAL; it exits only when it walks | Informational | `dev-cycle-read.sh:18-21` | High |

## Overall Assessment

The final code is consistent with the lib's conventions. The iteration-1 issues that touched the contract (the root-check order, the IMPORT_CONFIGS omissions, the budget wording, the `--check` help, the inline wording) are all fixed in the lib's own idioms. The new names sit beside their nearest neighbors: walk_why beside entry_why, IMPORT_CONFIGS beside IMPORT_HOMES, and the `c1_`/`wh_` prefixes. What remains is doc and wording drift, which a multi-site change leaves behind. The most useful item is Finding 1. A one-token fail-closed guard in walk_has, plus a clause in contract item 6, would make the contract's "one statement" match how the lib itself reads the walk. Without it, the next caller to find walk_has in the inventory gets a fail-open primitive. Nothing here affects build-loop.sh's behavior today: every path fails closed, and the deny prefix consumers match is unchanged.

## Goal-Alignment Note

The goal is to land U2c2 after a clean review-fix loop. On the API surface, nothing blocks landing. The six items deliver what the brief describes, consistently with existing conventions, and none of the findings is Breaking or Inconsistent.
- **Finding 1** is worth taking before merge if a fix commit happens anyway. It is a one-line guard and a one-clause contract edit, it changes no current behavior, and it closes the Stage-1 escalation about contract item 6. Otherwise it is a clean Defer with the trigger "a walk_has caller outside floor".
- **Finding 2** is operator-facing wording. It is cheap, but it touches strings the bats tests pin, so it fits the same fix commit or a later unit.
- **Findings 3-7** are Informational or naming points that can go to the override log. Finding 5 can ride with row 628.

None of this concerns the security or performance properties the unit was built to deliver: F3's live-link marking, the config-dir key, and the forkless cached floor.
