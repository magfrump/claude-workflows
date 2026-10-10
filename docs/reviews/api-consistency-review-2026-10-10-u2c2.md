Commit: 3111ee9d

# API Consistency Review: feat/build-loop-u2c2 (U2c2, iteration 1)

**Scope:** `git diff main...HEAD` (one commit, 3111ee9d): `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-check.bats`
**Date:** 2026-10-10
**Based on:** `docs/reviews/code-fact-check-report.md` (Stage 1, commit 3111ee9d). Its escalated Claims 2, 9b and 23 are taken up below. Behavior it verified is not re-verified here.
**Reviewer:** api1 (API-consistency critic, k=1 loop pass)

## Baseline Conventions

The lib's public surface is shell functions, global result variables, and the deny/skip strings the two scripts print. I surveyed these conventions before reading the diff:

- **Result word plus a wording function.** A check sets or prints a short word, and a separate function turns it into a sentence for a skip line. Examples: `main_entry` prints `blob|absent|notfile|notdir PART|badform|error` and `entry_why` words it (`scripts/lib/dev-cycle-read.sh:326-375`); `BRIEF_ODD` holds `odd N WHY|unbalanced N|error` and `oddwhy` words it (`:308-318`, `:380-388`). The word may carry one argument after a space (`notdir PART`, `odd N WHY`). `entry_why` folds newlines to spaces "so the reason stays one line" (`:362`).
- **Words the caller words.** `TRUTH_WHY` (`instr|dot|cycle|settings|user|record|case`, then `walk|imported` from truthwalk) has no wording function: "Each caller words the words" (`:1795-1806`). floor, nrules (`scripts/build-loop.sh:617-625`) and check_fix (`scripts/dev-cycle.sh:182-187`) each word it inline.
- **Whole-sentence `*_WHY`.** `FLOOR_WHY`, `CHECKOUT_WHY`, `LIST_WHY`, `IMPORT_READER_WHY` and `FILE_WHY` (apart from its `absent` word) hold finished prose (`scripts/build-loop.sh:369-447`, `:696-762`).
- **Result variable naming.** A result variable is named `<THING>_WHY` beside its data (`IMPORTED_MAIN` / `IMPORTED_MAIN_DONE`). import_readers' results are `IMPORT_<PLURAL>` newline lists with no trailing newline (`IMPORT_ROOTS`, `IMPORT_HOMES`, `IMPORT_OTHER`), and contract item 9 tells callers never to set them.
- **Nameref arguments.** A function that fills a caller's array takes `NAME` first and binds it to a local `<2-letter prefix>_<x>` nameref: `pd_m`, `pb_a`, `op_o`, `wa_a`, `rc_q`, `pm_p`, `os_a`, `iw_o`, `nl_a`, `mc_e` (`:670-1549`). Its other locals are mostly unprefixed.
- **Optional arguments go last.** Examples: `entry_why WORD [PATH]`, and `prompt_dir`/`prompt_bases` taking the lowered path and then the path as spelled.
- **Root check.** Every file-reading entry point runs `need_root` first and exits when ROOT_REAL is unset, is not the cwd, or is not a top level. The header (`:18-22`) is the one statement of this.
- **Deny text.** `deny BRIEF S PATH: WHY`. The header documents the WHY by rule family, not by exact string (`scripts/build-loop.sh:157-195`). The one test-pinned fixed prefix is `WALKFAIL="the default branch's instruction files could not be walked for @ imports"` (`test/scripts/build-loop-check.bats:43`).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `IMPORTED_MAIN_WHY` | global result var | `TRUTH_WHY`, `FLOOR_WHY`, `IMPORT_READER_WHY`, `BRIEF_ODD` | `scripts/lib/dev-cycle-read.sh:388,1807,1865`; `:798` | Consistent name (`<RESULT>_WHY` beside `IMPORTED_MAIN`). Its shape, "KIND [PATH]", matches `main_entry`'s "notdir PART". Its wording is inline in floor, the TRUTH_WHY pattern, not the entry_why/oddwhy pattern (Finding 6). |
| KIND words `readers main tree link list start admit seeds copies read budget` | enum | `main_entry` words, `TRUTH_WHY` words, `oddwhy` words | `:326-375`, `:1795-1818`, `:308-318` | Mostly consistent (bare lower-case nouns). `budget` covers only one of the two budgets (Finding 3). |
| `IMPORT_CONFIGS` | import_readers result | `IMPORT_ROOTS`, `IMPORT_HOMES`, `IMPORT_OTHER` | `:1086-1095`, `:1161-1164` | Consistent shape (plural, newline list, no trailing newline). It is missing from contract item 9's never-set list (Finding 4). |
| `c1_seeds NAME` / nameref `c1_a` / local `c1_at` | function + nameref | `outside_seeds NAME` (`os_a`, `os_at`), `with_at NAME` (`wa_a`), `root_starts` | `:1263-1274`, `:1364-1402` | Consistent: NAME first, a prefixed nameref, `-A` set mirrored from `os_at`. "c1" is a label rather than initials. That is acceptable, and it is documented as outside_seeds' item (3). |
| floor `$4` (lowered path, optional) | parameter | `prompt_dir`/`prompt_bases` (lowered + spelled), `entry_why` optional `$2` | `:670-685`, `:364` | Consistent: optional, last, and backward-compatible for callers passing 3 args. |
| truthwalk PATH now lower-cased | parameter semantics | `truthrule` (lower-cased, upper-case refused as `case`), `isimported` (any case) | `:1808-1811`, `:1780-1792` | Input narrowed. The upper-case answer reuses `imported` where truthrule has `case` (Finding 2). |
| floor reason "a path below the name of an instruction or prompt file" | deny string | nrules' "a path below the name of one of the dev cycle's own files or the constraints doc" | `scripts/build-loop.sh:624` | Consistent phrasing. The `--check` header does not document it (Finding 5). |
| floor walk-failure details (`WALKFAIL: <detail>`) | deny string | the existing `WALKFAIL: the reader settings of docs/dev-cycle.md cannot be used: WHY` | `test/scripts/build-loop-check.bats:2241` | Consistent extension (`WALKFAIL` + ": " + detail). The prior readers wording is kept byte-for-byte. |

## Findings

#### 1. The main walk's root check now runs after import_readers, so with ROOT_REAL unset main_imports and floor return a misworded refusal instead of exiting, contrary to the header's contract and to imported_names

**Severity:** Inconsistent
**Location:** `scripts/lib/dev-cycle-read.sh:18-22` (header), `:1654-1657` (main_imports), `:1579-1580` (imported_names), `:1888` (floor's readers arm)
**Move:** 3 (consumer contract), 7 (asymmetry)
**Confidence:** High (fact-check Claim 2 executed it: fc1-floor.log section A)
**Legibility-target:** gate callers (build-loop.sh, a future second caller) reading the header's root-check contract; floor maintainers

Evidence (header, as changed by this diff):
```
# check_brief, isimported and the import walks (main_imports on a cache miss;
# truthwalk and floor through it) exit 1 (need_root) unless
# ROOT_REAL is set, is the current directory and is a repository's top level;
```
Evidence (code):
```bash
# :1654-1657 main_imports
  import_readers || { IMPORTED_MAIN_DONE=""; IMPORTED_MAIN=error; IMPORTED_MAIN_WHY=readers; return 1; }
  [[ "$IMPORTED_MAIN_DONE" == ... ]] && { [[ "$IMPORTED_MAIN" != error ]]; return; }
  # Below the cache check: ...
  need_root
# :1579-1580 imported_names (unchanged order)
  need_root
  import_readers || { IMPORTED_DONE=""; IMPORTED=error; return 1; }
```
import_readers returns 1 on an empty ROOT_REAL (`:1124`). With ROOT_REAL unset, a cache miss therefore never reaches need_root. The fact-check probe showed floor printing `the default branch's instruction files could not be walked for @ imports: the worktree registry could not be read, or a reader root or home or CLAUDE_CONFIG_DIR is not an absolute path`, where main's lib exits 1 with "ROOT_REAL is not set". Three problems follow:
- The header's "on a cache miss" qualifier promises an exit that does not happen.
- The two walks no longer share an order: tree checks the root first, main reads the registry first. On an import_readers memo miss with ROOT_REAL set but not the cwd, `git worktree list` also runs in the cwd before any root check.
- The operator-facing reason names the wrong cause. Every listed cause (registry, root, home, CLAUDE_CONFIG_DIR) is something else.

The result still fails closed, so this is not Breaking for build-loop.sh, which always sets ROOT_REAL. The contract a second caller reads is wrong, though.

**Recommendation:** Restore the exit cheaply. Put a fork-free `[[ -n "${ROOT_REAL:-}" ]] || need_root` (or a `need_root_cheap` that tests only set-ness) before main_imports' import_readers call. The cache-hit path still forks nothing, and the cwd/top-level half stays on the miss path. If the order is kept on purpose instead, reword header `:18-22` to say what happens (main_imports returns 1, `readers`, with ROOT_REAL unset). Add "ROOT_REAL is unset" to the readers wording too (fact-check Claim 21).

#### 2. truthwalk answers an upper-case path as `imported`, where truthrule has a dedicated `case` word for the same caller error

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:1824-1833` (truthwalk), `:1808-1811` (truthrule), contract item 8 at `:91-96`
**Move:** 2 (naming: enum value reuse), 3 (narrowed input)
**Confidence:** High

Precedent: a dedicated `case` TRUTH_WHY word for "a path holding an upper-case letter (a caller that did not lower it)" used in `scripts/lib/dev-cycle-read.sh:1803-1811` (truthrule)

Evidence:
```bash
# truthwalk :1830-1831
  TRUTH_WHY=imported
  [[ "$2" != *[ABCDEFGHIJKLMNOPQRSTUVWXYZ]* && "$tw_l" != *$'\n'"$2"$'\n'* ]] || return 0
# contract item 8 :94-95
#     and the walks lower first; truthrule refuses an upper-case letter as
#     case, truthwalk as imported).
```
truthwalk used to take "PATH (any case)", as isimported still does. It now takes a lower-cased path only. That narrowing is backward-compatible today: both callers pass a lowered path (floor at `:1884`, check_fix at `scripts/dev-cycle.sh:185`), and grep finds no other caller. The way it refuses a wrong caller is inconsistent with its sibling, though. TRUTH_WHY is one shared vocabulary, and truthrule already defines `case` for exactly this mistake. A caller that skips lowering gets the reason "an instruction or prompt file ... imports it with @" from floor and the import-walk message from check_fix. Both are misleading, because nothing imports it. Both current callers run truthrule first, which catches `case`, so the arm is unreachable today. A future caller that calls truthwalk alone would hit it.

**Recommendation:** Set `TRUTH_WHY=case` for the upper-case arm (floor and check_fix would need a `case` wording if they ever reach it), or keep `imported` and say in item 8 why a fold to "imported" is the intended fail-closed reading. Also fix the truthwalk doc's "as isimported WALK PATH does": isimported takes any case.

#### 3. The `budget` KIND and the `read` wording split the two walk budgets the wrong way: an IMPORT_OUT_MAX overrun normally reports `read PATH`, worded as the *work* budget

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:791-797` (IMPORTED_MAIN_WHY doc), `:1897` (read arm), `:1898` (budget arm), `:1762`, `:1719-1722`, `:892-894`
**Move:** 4 (error consistency)
**Confidence:** High (fact-check Claims 9b and 23, executed: fc1-floor.log section C gave `why=[read CLAUDE.md]` with IMPORT_OUT_MAX=3 and 12)

Evidence:
```
# :796  ... read PATH (reading or parsing PATH, its link text included) or budget (IMPORT_OUT_MAX).
      *" read") FLOOR_WHY="$d could not be read or its imports parsed within the walk's work budget, or it is a link the walk does not model" ;;
      *" budget") FLOOR_WHY="the walk printed more than its IMPORT_OUT_MAX budget" ;;
```
Every parser call gets `IMPORT_LEFT=$((IMPORT_OUT_MAX - used))`, and the parser fails first when it would print past it. So an output-budget overrun usually lands in `read`, whose wording names "the walk's work budget" (IMPORT_WORK_MAX). Consider an operator who reads the deny line and follows contract item 4 ("when IMPORT_OUT_MAX or IMPORT_WORK_MAX changes"). They would raise IMPORT_WORK_MAX and the refusal would persist. The KIND vocabulary has the same problem: `budget` reads as "a budget was spent", but it is reached only by output the parser did not bound (outside_proj's projection, a `//` entry).

**Recommendation:** Either make `read` say "within the walk's budgets (IMPORT_WORK_MAX, IMPORT_OUT_MAX)", or route an import_file/import_targets failure caused by IMPORT_LEFT to `budget`. Either way, document `budget` as "IMPORT_OUT_MAX, past the parser's own bound" (fact-check's proposed text).

#### 4. IMPORT_CONFIGS is a new import_readers result but is missing from contract item 9's "never set these yourself" list

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:101-104` (contract item 9), `:1089-1095`, `:1161-1164`
**Move:** 3 (documentation drift in the consumer contract)
**Confidence:** High (fact-check Claim 5)

Evidence:
```
#     ... Never set these yourself
#     (from the environment or after reader_settings), nor IMPORT_ROOTS,
#     IMPORT_HOMES, IMPORT_DOTNEST or IMPORT_OTHER: they are import_readers'
#     results, which a cache hit does not recompute.
```
IMPORT_CONFIGS has the same lifecycle. A cache hit does not recompute it, and both walks' keys hold it (`:1582`, `:1655`). A caller that set it directly would get seeds from one config set and a cache key from another. The contract is "the one statement" of the caller's duties (`:50-51`), so the list should be complete. Two related cache-key descriptions are stale for the same addition and should change in the same edit: imported_names' "keyed on import_readers' roots (ROOT_REAL first) and homes" (`:697-699`) and main_imports' "roots and homes" (`:729-731`) (fact-check Claims 6 and 7).

**Recommendation:** Add IMPORT_CONFIGS to item 9's list, and say "roots, homes and config dirs" at `:698` and `:730`.

#### 5. build-loop.sh's documented `--check` S-rules summary omits the floor's new "below a start file's name" refusal and its walk-failure details

**Severity:** Minor
**Location:** `scripts/build-loop.sh:177-183` (header), `scripts/lib/dev-cycle-read.sh:1904`
**Move:** 3 (documentation drift)
**Confidence:** High

Evidence (header, unchanged by the diff):
```
#                 (first match): the self-merge floor (the lib's floor:
#                 instruction and prompt files and what they import with @,
#                 dot paths, the gate's own code, the user's and the cycle's
#                 records, a working doc or review that is not the brief's
#                 own; ...
```
Evidence (new deny): `FLOOR_WHY="a path below the name of an instruction or prompt file"`.

The header enumerates the floor's rule families for users of `--check`. The N-rules paragraph just above (`:170-174`) lists its own "or a path below one of those names". The floor paragraph gets no matching clause, so the documented output is now narrower than what `--check` denies. The walk-failure line has the same gap. `:52` says a malformed settings file "fails both walks, so the floor refuses every path", but no line says that any walk failure refuses every path with a "could not be walked for @ imports: DETAIL" reason. The DETAIL suffix itself is backward-compatible: `WALKFAIL` stays the fixed prefix and the tests pin it.

**Recommendation:** Add "a path below such a file's name" after "instruction and prompt files and what they import with @". Optionally add one clause: "any walk failure refuses every path, naming where the walk failed".

#### 6. IMPORTED_MAIN_WHY's words are worded inline in floor, with no wording function, unlike the "KIND ARG" words it most resembles (main_entry/entry_why, BRIEF_ODD/oddwhy)

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1885-1901` (floor), `:791-797`
**Move:** 2 (naming/shape against the grain), 7 (asymmetry)
**Confidence:** Medium

Precedent: "word [ARG]" results worded by a dedicated function used in `scripts/lib/dev-cycle-read.sh:358-375` (entry_why) and `:308-318` (oddwhy). The competing precedent: TRUTH_WHY words worded by each caller, `:1805` and `scripts/dev-cycle.sh:182-187`.

Evidence: `case "$TRUTH_WHY ${IMPORTED_MAIN_WHY%% *}" in ... *" read") FLOOR_WHY="$d could not be read ..."` (14 arms inside floor).

The lib has both conventions. IMPORTED_MAIN_WHY takes main_entry's shape (a word plus an argument after a space) and TRUTH_WHY's wording placement (inline in the one caller). That is defensible while floor is the only reader. Contract item 7, though, already anticipates "a second caller of main_checkout", and check_fix's tree walk has no counterpart (no IMPORTED_WHY): `scripts/dev-cycle.sh:187` still says only "the instruction-file import walk failed". The two walks' failure reports are now asymmetric. Two smaller shape points:
- entry_why folds newlines so "the reason stays one line". floor's `$d` does not, though every path that reaches `start`/`admit`/`link`/`read` is refused earlier if it holds a newline, so this is latent only.
- A `//PATH` (dangling-link) queue entry that fails in phase 2 is worded with its internal `//` spelling ("//home/u/.claude/x.md could not be read ...").

**Recommendation:** No change needed for this unit. If a second reader appears, or when check_fix gains a tree-walk WHY, extract a `walk_why WORD` function as entry_why does and strip a leading `/` from a `//` path in it. Optionally add IMPORTED_MAIN_WHY to contract item 6 or item 9 as a read-only result.

#### 7. c1_seeds widens outside_seeds' NAME restriction to a second function's locals

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1396-1400`, `:1457-1461`
**Move:** 3 (consumer contract)
**Confidence:** High (fact-check Claim 13)

Evidence: `# import_readers (IMPORT_ROOTS, IMPORT_CONFIGS and IMPORT_OTHER). NAME must not be one of its locals or c1_seeds' (a nameref to one reads that local).` and `local -n c1_a="$1"; local d q r c i in cr=() cx=() ir=() lo=() fl=(); local -A c1_at=()`.

This is the first nameref-taking function in the lib that documents the shadowing hazard. The others (`with_at`, `root_copies`, `nul_list`) carry unprefixed locals with no warning. The split adds `cr`, `ir` and `c1_at` to the names a caller of outside_seeds must avoid. Today's callers pass `sd`, which is safe. Documenting the hazard is better than the siblings' silence. The cleaner convention, prefixed locals in the inner function, would remove the restriction instead of documenting it.

**Recommendation:** Optional: give c1_seeds' locals a `c1_` prefix (as `c1_at` already has). The NAME restriction then reverts to outside_seeds' own locals.

## What Looks Good

- **floor's `$4` is a textbook backward-compatible addition.** It is optional and last, floor falls back to lowering when it is empty, and build-loop.sh's srules passes check_line's `lower_all` output. Callers passing three arguments (the bats `floors` helper, any second caller) are unaffected. Its upper-case behavior, refusing as `case` via truthrule, matches contract item 8.
- **Walk-failure deny text stays prefix-stable.** Every new detail is appended as `WALKFAIL: DETAIL`. The pre-existing `WALKFAIL: the reader settings of docs/dev-cycle.md cannot be used: WHY` text is reproduced byte-for-byte by the readers arm (test at `build-loop-check.bats:2241` unchanged). A consumer matching the prefix keeps working.
- **IMPORT_CONFIGS matches its siblings.** It has the same newline-list shape and no trailing newline, it is computed once in import_readers, and it is folded into the memo key with the existing length-prefixed `${#f}:$f` part scheme. The set/unset distinction for CLAUDE_CONFIG_DIR (`${X+x}${X-}`) is careful. Moving the CLAUDE_CONFIG_DIR refusal into import_readers puts it beside the other root/home absoluteness refusals, and contract item 4 drops the reset duty accordingly.
- **The new floor refusal's phrasing matches.** It mirrors nrules' "a path below the name of ..." exactly (`scripts/build-loop.sh:624`), so the two families read as one rule.
- **c1_seeds keeps the lib's NAME-first, prefixed-nameref signature.** Its doc states what it appends, to what, and when it returns 1, like with_at and root_starts.
- **The IMPORTED_MAIN_WHY lifecycle is fully specified.** It is empty on success and kept with a cached failure, and only main_imports writes it.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | main walk's root check after import_readers: ROOT_REAL unset returns a misworded `readers` refusal, not the header's exit; walks' order now asymmetric | Inconsistent | `dev-cycle-read.sh:18-22, 1654-1657, 1888` | High |
| 2 | truthwalk words an upper-case path `imported`; truthrule's `case` is the precedent | Minor | `dev-cycle-read.sh:1824-1833, 91-96` | High |
| 3 | IMPORT_OUT_MAX overrun reports `read`, worded as the work budget; `budget` KIND under-covers | Minor | `dev-cycle-read.sh:796, 1897-1898` | High |
| 4 | IMPORT_CONFIGS missing from contract item 9; two cache-key docs stale | Minor | `dev-cycle-read.sh:101-104, 697-699, 729-731` | High |
| 5 | `--check` header omits the "below a start file's name" floor refusal and walk-failure details | Minor | `build-loop.sh:177-183` | High |
| 6 | IMPORTED_MAIN_WHY worded inline (TRUTH_WHY pattern), not by a function (entry_why pattern); tree walk has no counterpart; `//` spelling can leak | Informational | `dev-cycle-read.sh:1885-1901` | Medium |
| 7 | c1_seeds' unprefixed locals widen outside_seeds' NAME restriction | Informational | `dev-cycle-read.sh:1396-1400, 1461` | High |

## Overall Assessment

The change is largely consistent with the lib's conventions. The new names follow their nearest neighbors: `IMPORTED_MAIN_WHY` beside `IMPORTED_MAIN`, `IMPORT_CONFIGS` beside `IMPORT_HOMES`, `c1_seeds NAME` with a prefixed nameref. floor's new parameter is optional and last. The deny strings extend the pinned `WALKFAIL` prefix rather than replacing it. Finding 1 is the one contract-level issue: the reordering inside main_imports, done for performance, quietly changed the documented root-check behavior. It also made the two walks disagree on order and produced a refusal reason that names the wrong cause. It fails closed, so consumer impact is limited to misleading output and a wrong header. The fix is a single fork-free guard or a header rewording. Findings 2-5 are fixable in place in the docs and wording. None suggests the author skipped the conventions survey. They are the kind of drift a multi-site addition (a new result variable, a narrowed parameter, a moved refusal) leaves behind in neighboring doc lists.

## Goal-Alignment Note

The goal is to land U2c2 after a clean review-fix loop. On the API surface, the six items do what the brief says, and they do it in the lib's established idioms. Nothing here blocks the unit's intent. Finding 1 should be resolved before landing: it is the only place where the code and the "one statement" of the gate caller contract now disagree, and the fact-check escalated it independently. Either a cheap ROOT_REAL guard or a header rewording closes it. Findings 3 and 4 are one-line doc or wording edits worth taking in the same fix pass, because they touch text an operator or a second caller acts on (which budget to raise, which variables never to set). Finding 5 is the user-facing `--check` doc and is equally cheap. Findings 6 and 7 are informational. They can go to the override log as deliberate conventions rather than block this unit.
