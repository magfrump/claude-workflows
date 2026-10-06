Commit: 36b79f72

# API Consistency Review — feat/build-loop-u2a (iteration 2)

**Scope:** `git diff main...HEAD` at 36b79f72: `scripts/lib/dev-cycle-read.sh` (the sourced caller contract), `scripts/dev-cycle.sh`, `scripts/build-loop.sh`, `skills/dev-cycle/SKILL.md`, and the tests that pin their output
**Date:** 2026-10-06
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u2a.md` (written at b9ffe7a8; 36b79f72's fixes for R1 and A1-A4 were read directly, not re-verified)
**Considered overrides:** rows 218, 228, 238, 241, 306, 319 of `docs/reviews/override-log.md` (by file line). None is re-raised. Finding 6 touches row 218's subject with new evidence: a new name with the same shape.

## Baseline Conventions

Read in full: `need_root`, `rawfile`, `plaindir`, `blocker`, `inrepo`, `dirok`, `skipped`, `pathform`, `isbrief`, `writable`, `oddwhy`, `main_entry`, `brief_fields`, `check_brief`, `check_answer` (lib); `check_path`, `check_write`, `check_fix` (dev-cycle.sh); `main_file` (build-loop.sh); and the lib inventory test (dev-cycle.bats:1074-1090).

- **Function kinds.** `check_*` print one answer line per argument (`ok ...` / `skip ARG: REASON`). Predicates return a status and print nothing (`isbrief`, `writable`, `rawfile`, `plaindir`, `inrepo`, `dirok`, `pathform`). Functions that set globals have documented names (`skipped` → `SKIP_AT`/`SKIPPED`, `brief_fields` → `BRIEF`/`BRIEF_ODD`, `main_file` → `FILE_OUT`/`FILE_WHY`), and the header says to call them in the caller's shell.
- **Polarity.** A predicate returns 0 when its property holds. `skipped` returns 0 *when refused* and records why in a global, the shape `floor` now copies.
- **Parameter order.** Path first, then an optional mode word that falls back to a default: `blocker PATH file|dir`, `skipped PATH [file|dir]`, `pathform PATH [glob]`.
- **Names.** The lib uses snake_case for multi-word names (`main_entry`, `main_by_name`, `brief_fields`, `need_root`, `resolve_main`), with `oddwhy` as the one run-together exception. `main_` means "reads the default branch's commit". The `plain*`/`raw*` pair (`rawfile`, `plaindir`) is the single-realpath test, and `inrepo`/`dirok` are the need_root-plus-walk versions.
- **Result words.** `main_entry` answers lower-case words run together (`blob`, `absent`, `notfile`, `notdir PART`, `error`).
- **Reason strings.** A skip reason after `skip ARG: ` is usually a fragment with no subject (`not an allowed path form`, `reached through a symlink, or not a regular file`, `one of the cycle's own files (use --check-write)`). A reason gets a subject when it names a different path than the argument (`check_answer`'s questions file, `--settings`' `docs/dev-cycle.md`).
- **Globals.** Upper-case data constants have no type suffix except `IMPORT_RE` and `*_AWK` (`INSTRUCTION_FILE`, `NAMECHARS`, `DIGIT`, `SLUG`).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `floor PATH STEM STATUS` | function (sets global) | `skipped` (0 = refused, sets `SKIP_AT`), `main_file` (sets `FILE_WHY`) | `scripts/lib/dev-cycle-read.sh:128`, `scripts/build-loop.sh:122-127` | Consistent: same refused-means-0 polarity as `skipped`, and the global is documented |
| `FLOOR_WHY` | global | `FILE_WHY`, `SKIP_AT`, `BRIEF_ODD` | `scripts/build-loop.sh:125`, `lib:108`, `lib:305` | Consistent name. Its value has no documented grammatical shape (Finding 7) |
| `ownfile LP STEM STATUS` | predicate | `isbrief`, `writable`, `rawfile` | `lib:98`, `lib:160-165` | Consistent (adjective + noun predicate). Its argument order matches `floor`'s |
| `isimported tree\|main PATH` | predicate | `isbrief`, `isclosed`; argument order of `blocker`/`skipped`/`pathform` | `lib:109`, `lib:128`, `lib:143` | Name consistent. **Argument order inconsistent** (Finding 2) |
| `isclosed` | predicate | `isbrief` | `lib:160` | Consistent, and the closed/ rule is now spelled once |
| `plainfile` | predicate | `plaindir`, `rawfile`, `inrepo` | `lib:98-101`, `lib:123` | **Inconsistent** (Finding 1) |
| `main_imports` | function (sets global) | `imported_names`, `main_entry`, `main_by_name` | `lib:474`, `lib:250-265` | `main_` prefix consistent. The pair with `imported_names` is asymmetric (Finding 6) |
| `import_targets` | stdin filter | `lower`, `scrub` (stdout printers) | `lib:451`, `lib:50` | Consistent |
| `instruction_names` | stdin filter | `imported_names` (fills globals) | `lib:474` | Shares `_names` with a function of a different kind (Finding 6) |
| `untracked_md` | printer | `lower`, `scrub` | `lib:451` | Consistent |
| `entry_why WORD PATH` | reason mapper | `oddwhy` | `lib:234` | Consistent with the lib's snake_case majority, not with the closest neighbour `oddwhy`. Accepted; its output shape is Finding 4 |
| `GATE_CODE` | regex constant | `INSTRUCTION_FILE`, `IMPORT_RE` | `lib:438`, `lib:450` | Consistent with `INSTRUCTION_FILE` (no `_RE`) |
| `IMPORTED_MAIN`, `IMPORTED_MAIN_DONE` | globals | `IMPORTED`, `IMPORTED_DONE` | `lib:449` | Consistent: mirrors the tree walk's pair |
| `badform` | `main_entry` word | `notfile`, `notdir`, `absent`, `error` | `lib:279-281` | Consistent shape. The header's example is misleading (Finding 3) |

## Findings

#### 1. `plainfile` reads as the file twin of `plaindir`, but it is `inrepo` without `need_root`

**Severity:** Inconsistent
**Location:** `scripts/lib/dev-cycle-read.sh:123-124` (neighbours at `:98`, `:101`; header at `:18`)
**Evidence:**
> ```
> rawfile() { local r; [[ -n "${ROOT_REAL:-}" && -f "$1" ]] && r="$(realpath -e -- "$1" 2>/dev/null)" && [[ "$r" == "$ROOT_REAL/$1" ]]; }
> plaindir() { local r; [[ -n "${ROOT_REAL:-}" && -d "$1" ]] && r="$(realpath -e -- "$1" 2>/dev/null)" && [[ "$r" == "$ROOT_REAL/$1" ]]; }
> inrepo() { need_root; plainfile "$1"; }
> plainfile() { [[ -z "$(blocker "$1" file)" && -f "$1" ]]; }  # inrepo after need_root has run
> ```
**Move:** 2 (naming against the grain)
**Confidence:** High
**Legibility-target:** for-author

Precedent: `plaindir`/`rawfile` = one realpath test of the path itself, and `dirok`/`inrepo` = `need_root` + the top-down `blocker` walk, used in `scripts/lib/dev-cycle-read.sh:98-128`

The lib's names pair up by kind. `plaindir` is the directory twin of `rawfile`, and `dirok` is the directory twin of `inrepo`. `plainfile` takes the `plaindir` shape but has `inrepo`'s meaning: the walk, minus the guard. A reader who reaches for "the file version of `plaindir`" gets the walk. A reader who wants the walk without `need_root` must find a one-line comment to learn it exists. Line 18 of the header lists what reads nothing as plain while ROOT_REAL is unset ("rawfile, plaindir and blocker"), and `plainfile` is not on it, though it behaves the same way through `blocker`. The function is new in this diff and has three internal callers (`:479`, `:488`, `:518`), so a rename costs little now.

**Recommendation:** Rename it to say what it is relative to `inrepo`. `inrepo_noroot` or `walkfile` would avoid the `plain*` collision. At minimum, add it to the header's line-18 list and say in its comment that it is the walk, not `plaindir`'s file twin.

#### 2. `isimported` puts the mode word before the path, against the lib's path-first order

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:538-546`; callers `scripts/dev-cycle.sh:183`, `scripts/lib/dev-cycle-read.sh:580`
**Evidence:**
> ```
> # Whether path $2 (any case) is imported, by the walk $1 names (tree or main).
> ```
> ```
>   if [[ "$1" == main ]]; then main_imports || return 0; [[ "$IMPORTED_MAIN" == *$'\n'"$lp"$'\n'* ]]
> ```
**Move:** 2 (parameter ordering)
**Confidence:** Medium
**Legibility-target:** for-author

Precedent: path first, mode word second, used in `scripts/lib/dev-cycle-read.sh:109` (`blocker  # $1 path, $2 "file" or "dir"`), `:128` (`skipped "$1" "${2:-file}"`), `:143` (`pathform  # $1 path, $2 "glob"`)

Every other lib function that takes a path and a selector word takes the path first. `isimported` reverses this. Any value of `$1` other than `main` silently selects the tree walk. For `floor`, a swapped call (`isimported "$lp" main`) would run the working-tree walk, which reads a checkout the build loop can write. That fails open, the direction the floor exists to prevent. There are only two callers today, and the mode word is required rather than optional, so the impact is small. A future caller in U2b/U2c that writes it the lib's usual way would not be caught by any test.

**Recommendation:** Either take the path first (`isimported PATH tree|main`) or reject a mode that is neither word (`*) return 0` for "imported", which fails closed). The second fix is worth having whichever order is chosen.

#### 3. The header's `badform` example says "a dotfile", but pathform refuses only `.git*` parts among dot names

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:255-256`
**Evidence:**
> ```
> # (PART, a directory above the path, is stored as something else), "badform"
> # (a path pathform refuses: a dotfile such as .gitattributes, say) or "error"
> ```
**Move:** 3 (consumer contract / documentation drift)
**Confidence:** High
**Legibility-target:** for-author

Run at 36b79f72: `pathform .env`, `pathform .claude/settings.json` and `pathform docs/.x.md` all pass, and only `.gitattributes` is refused (the "no component starting .git" rule, `:133`, `:150`). So `main_entry .env` answers `absent`/`blob`, not `badform`. A U2b caller that reads this header could treat `badform` as its dotfile rule and skip the separate check. Today `floor` does its own dot test (`:578`), which covers the gap. The row-306 example (`.gitattributes`, `.github/x.yml`) is correct. Only the generalization to "a dotfile" is wrong.

**Recommendation:** Change it to "(a path pathform refuses: a `.git`-prefixed part such as `.gitattributes` or `.github/`, a `..` part, a character outside NAMECHARS)", or just "(a path pathform refuses)".

#### 4. `entry_why` always names the path, so the new skip lines repeat it

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:284-290`, used at `:353` (check_brief), `:685` (check_answer), `scripts/build-loop.sh:133` (main_file)
**Evidence:**
> ```
>     notfile) echo "$2 is not a regular file on the default branch" ;;
>     badform) echo "$2 is not an allowed path form" ;;
>     *) echo "the tree of the default branch could not be read" ;;
> ```
> ```
>       *) echo "skip $a: $(entry_why "$e" "$f"), so $f is not read"; return ;;
> ```
**Move:** 4 (error-message consistency)
**Confidence:** High
**Legibility-target:** for-author

Precedent: a skip reason after `skip ARG: ` carries no subject when it is about ARG itself, used in `scripts/lib/dev-cycle-read.sh:342`, `:346` and `scripts/dev-cycle.sh:146-175` (`skip $a: not an allowed path form`, `skip $a: reached through a symlink, or not a regular file`)

Sharing one mapping (rows 228, 306) is right, but the shared shape always has a subject. The tests now pin user-visible lines that say the same path twice. `test/scripts/dev-cycle.bats:1039` pins `skip docs/working/briefs/2026-01-01-s.md: docs/working/briefs/2026-01-01-s.md is not a regular file on the default branch`, and `:1195` pins `skip Q-1: docs/working/questions.md is not a regular file on the default branch, so docs/working/questions.md is not read`. The old check_answer wording ("so no entry in it is read") said something new. The new one restates the subject. In the other direction, `--settings`' error arm lost its file: it used to read "the default branch's tree could not be read for $f" (removed in build-loop.sh:134), and it is now the same generic sentence for both `docs/dev-cycle.md` and `docs/constraints.md`. The line's key (`policy`/`constraints`) still says which file, so nothing is lost there. The `badform` arm is unreachable from all three callers today, since each runs pathform first or passes a fixed path. No doc quotes the old or new wording: a repo-wide grep outside `docs/reviews/` and `archive/` finds only the tests, which were updated.

**Recommendation:** Keep the mapping and drop the duplication at the call site. `check_brief` could print `skip $a: $(entry_why "$e" "$a")` with a subject-less `notfile` (for example, pass `""` and have the mapping write "not a regular file on the default branch"). `check_answer` could keep "so no entry in it is read". This is cosmetic. Merging as-is costs only the wording in two pinned tests.

#### 5. The lib inventory test does not list the new helpers, globals or constant

**Severity:** Minor
**Location:** `test/scripts/dev-cycle.bats:1080-1085`
**Evidence:**
> ```
>                  oddwhy check_brief check_branch resolve_main main_by_name main_entry brief_fields lower imported_names check_answer \
>                  isclosed entry_why isimported ownfile floor; do
> ```
> ```
>         for v in FENCE_AWK ANSWER_AWK INSTRUCTION_FILE IMPORT_RE; do [[ -n "${!v}" ]] || echo "no $v"; done
>         for v in SKIPPED SKIP_AT MAIN MAIN_SHA MAIN_BY_NAME IMPORTED IMPORTED_DONE BRIEF BRIEF_ODD; do declare -p "$v" >/dev/null 2>&1 || echo "unset $v"; done
> ```
**Move:** 3 (test drift)
**Confidence:** High
**Legibility-target:** for-author

The test titled "sourcing the reader lib defines its functions and calls neither git nor perl" was extended for five of the new functions. It still omits `plainfile`, `main_imports`, `import_targets`, `instruction_names` and `untracked_md`, the constant `GATE_CODE`, and the globals `IMPORTED_MAIN`, `IMPORTED_MAIN_DONE` and `FLOOR_WHY`. `floor`'s comment names `FLOOR_WHY` as read by U2c's `--check`, so it is part of the caller contract. If someone later moved its initialisation into a function, the test would not catch it.

**Recommendation:** Add the five functions to the `declare -F` list, `GATE_CODE` to the non-empty list, and the three globals to the `declare -p` list.

#### 6. The two import walks are named asymmetrically, and `instruction_names` borrows `imported_names`' suffix for a different kind of function

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:470`, `:474`, `:496`
**Evidence:**
> ```
> instruction_names() { env LC_ALL=C grep -zaiE '(^|/|'$'\t'')((claude|agents?|gemini)(\.[a-z0-9_-]+)?|skill)\.md$' || true; }
> ```
> ```
> imported_names() {
> ```
> ```
> main_imports() {
> ```
**Move:** 2 / 7 (asymmetry)
**Confidence:** Medium
**Legibility-target:** for-author

Precedent: the walks' globals mirror each other as `IMPORTED`/`IMPORTED_DONE` and `IMPORTED_MAIN`/`IMPORTED_MAIN_DONE` in `scripts/lib/dev-cycle-read.sh:449`

The globals mirror each other, but the functions that fill them do not (`imported_names` vs `main_imports`). Meanwhile `instruction_names`, a stdin filter, shares `imported_names`' suffix even though `imported_names` fills globals and prints nothing. Row 218 deferred `imported_names`' getter-like name to "a verb name ... with U2's isimported". `isimported` is now the verb that callers use, so the remaining cost falls on lib maintainers rather than callers. That is why this is Informational and not a re-raise of row 218. The new evidence is that this diff adds a second `_names` function of a different kind beside it.

**Recommendation:** Optional: rename `main_imports` → `main_imported_names` (or both walks to `tree_imports`/`main_imports`), and `instruction_names` → `filter_instruction_files`. Callers use only `isimported`, so the rename is internal.

#### 7. `FLOOR_WHY`'s values mix two grammatical shapes, and the contract does not say which one a caller composes with

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:566`, `:577-588`
**Evidence:**
> ```
>   if [[ "$low" =~ $INSTRUCTION_FILE ]]; then FLOOR_WHY="an instruction file, which sessions load from the checkout"
> ```
> ```
>     if [[ "$IMPORTED_MAIN" == error ]]; then FLOOR_WHY="the default branch's instruction files could not be walked for @ imports"
> ```
**Move:** 4 (reason-string consistency)
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

Eight of the nine values are noun phrases that complete "PATH is …". The walk-failure value is a full clause with its own subject. Both read correctly after a colon, which is how the tests compose them (`build-loop-check.bats:18`, `"$p: $FLOOR_WHY"`). The contract says only "Returns 0 with FLOOR_WHY set", so U2c's `--check` could reasonably write `PATH is $FLOOR_WHY` and get "... is the default branch's instruction files could not be walked". No caller exists yet, so this is for U2c to settle deliberately.

**Recommendation:** Add one clause to floor's comment, such as "FLOOR_WHY follows `PATH: `", or make the failure value a noun phrase too ("a path the default branch's @ import walk could not clear").

#### 8. The two walk caches use different keys, though both read ROOT_REAL's working tree

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:477`, `:499`
**Evidence:**
> ```
>   [[ "$IMPORTED_DONE" == "$ROOT_REAL" ]] && return; IMPORTED_DONE="$ROOT_REAL"; IMPORTED=$'\n'
> ```
> ```
>   [[ -n "$IMPORTED_MAIN_DONE" && "$IMPORTED_MAIN_DONE" == "$MAIN_SHA" ]] && { [[ "$IMPORTED_MAIN" != error ]]; return; }
> ```
**Move:** 7 (asymmetry)
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

The tree walk's cache is keyed on the root ("a call for another ROOT_REAL recomputes it"). The main walk's cache is keyed only on the commit, yet it also starts from ROOT_REAL's untracked instruction files (`:517-519`). A process that switched roots between two clones at the same main commit would reuse the first clone's untracked imports. Both of today's callers act on one root per process, so this cannot happen now. Recording it keeps the cache contract explicit for U2b's hardened wrapper.

**Recommendation:** Key the cache on `$MAIN_SHA $ROOT_REAL`, or note in the comment at `:448` that it assumes one root per process.

## What Looks Good

- **Shared reason mapping (rows 228, 306).** `entry_why` replaces three copied `case` blocks, and `badform` gives a form refusal its own word. That ends the U1d mismatch where a refused form read as "the tree could not be read". `main_entry`'s new sentence "Only blob reads the file, and only absent means there is none: every other word is a refusal" states the rule every caller depends on. All existing `main_entry` callers handle the new word safely: `check_brief` and `brief_fields` run pathform first, `check_answer` and `main_file` pass fixed paths, and `main_imports` lists the target without following it, as documented.
- **`floor`'s polarity and global** match `skipped` (0 = refused, why in a global), and `FLOOR_WHY` follows `FILE_WHY`'s naming. Its arguments are `PATH STEM STATUS`, the same order as `ownfile`.
- **Reason strings agree with their existing neighbours.** These match: `floor`'s "one of the dev cycle's own files" and `check_write`'s; `floor`'s import reason and `check_fix`'s ("imports it with @ (directly or through another import)"); the constraints wording and `--settings`' header ("which every loop prompt carries").
- **`isclosed`** removes two copies of the closed/ regex (`writable`, `check_brief`) and the path rewrite in `shared_branches`. Behaviour is unchanged, because `SLUG` excludes `/`.
- **Docs follow output.** The `--check-fix` list adds `constraints.md` in all three places: the dev-cycle.sh header (:52), the in-code comment (:169), the skip message (:182) and `skills/dev-cycle/SKILL.md:74`. The changed `--check-brief`/`--check-answer`/`--settings` wordings are quoted only in tests, and those were updated. The headers describe the reasons generically, and the descriptions still hold.
- **Header contract (rows 319, A1).** `floor` now runs `need_root`, which matches line 16. The stale "once that second caller lands" is gone. `GATE_CODE` follows `INSTRUCTION_FILE`'s naming.
- shellcheck is clean on all three scripts at 36b79f72.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `plainfile` named like `plaindir`'s file twin, but is `inrepo` minus `need_root`; missing from header line 18 | Inconsistent | `scripts/lib/dev-cycle-read.sh:123-124` | High |
| 2 | `isimported MODE PATH` reverses the lib's path-first order; an unknown mode selects the working-tree walk (fails open for floor) | Minor | `scripts/lib/dev-cycle-read.sh:538-546` | Medium |
| 3 | `badform` header example generalizes to "a dotfile"; `.env`, `.claude/x` pass pathform | Minor | `scripts/lib/dev-cycle-read.sh:255-256` | High |
| 4 | `entry_why` always has a subject: check_brief/check_answer skip lines repeat the path; `--settings` error loses its file | Minor | `scripts/lib/dev-cycle-read.sh:284-290`, `:353`, `:685` | High |
| 5 | Lib inventory test omits five new functions, `GATE_CODE`, `IMPORTED_MAIN(_DONE)`, `FLOOR_WHY` | Minor | `test/scripts/dev-cycle.bats:1080-1085` | High |
| 6 | `imported_names`/`main_imports` asymmetric; `instruction_names` shares the `_names` suffix with a global-filler | Informational | `scripts/lib/dev-cycle-read.sh:470-496` | Medium |
| 7 | `FLOOR_WHY` values mix noun phrases and a clause; composition shape undocumented | Informational | `scripts/lib/dev-cycle-read.sh:566-588` | Medium |
| 8 | Main-walk cache keyed on MAIN_SHA only, though it reads ROOT_REAL's untracked files | Informational | `scripts/lib/dev-cycle-read.sh:499` | Medium |

## Overall Assessment

The new lib surface follows the lib's conventions on the points callers depend on. `floor` copies `skipped`'s refuse-is-0-plus-global shape, `badform` fits `main_entry`'s word set, the closed/ rule and the refusal wording each now live in one place, and every doc that lists `--check-fix`'s refusals was updated together with its tests. Nothing breaks an existing consumer. The only user-visible changes are skip wordings, and the tests that pin them were updated. The findings can all be fixed in place without redesign. The one worth doing before U2b builds on the lib is Finding 2's fail-closed default for an unknown `isimported` mode, a one-line change, because `floor` is a fail-closed gate and a swapped call currently selects the writable-tree walk. Finding 1, the rename, is cheapest now, while `plainfile` has three internal callers. Findings 3-5 are wording and inventory fixes, and 6-8 are notes for U2b/U2c.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to docs/reviews/api-consistency-reviewer-review-2026-10-06-build-loop-u2a.md (first line `Commit: 36b79f72`), structured per the api-consistency-reviewer skill.
- Answered: yes. Covered naming against the lib's conventions, the header contract's accuracy, return codes, consistency of the reason strings, and doc updates for changed output.
- Out of scope: whether floor's rules match plan D5 (fact-check Claim 21 covers this), exploitability of the walk (security), and performance of the walk.
- Escalate: Finding 2's unknown-mode default fails open for `floor`. If the orchestrator weighs the floor as a security boundary, route it to security-reviewer as well.
- Decisions I made: the override rows were read by file line number (the rubric's "rows 203-320" uses that numbering). The fact-check report at b9ffe7a8 was used as the base, and 36b79f72's diff was read directly.
