Commit: 8ed86432

# Architecture Review — feat/build-loop-u2b3b1 (iteration 1)

**Scope:** `git diff main...HEAD` (scripts/lib/dev-cycle-read.sh, scripts/build-loop.sh, scripts/dev-cycle.sh, docs/dev-cycle.md; tests read for context only)
**Date:** 2026-10-09
**Based on:** docs/reviews/code-fact-check-report-build-loop-u2b3b1.md (17 claims, 0 Incorrect; Stale: lib:771-773)

Scope check: in scope. Module structure (main_file and SETTINGS_AWK move from build-loop.sh into the lib), public API (new lib function `reader_settings`, new global `READERS_LINE` and `IMPORT_READER_WHY`, caller contract item 9 rewritten), data model (two new keys in docs/dev-cycle.md; a fifth `--settings` line; import_readers' memo now encodes a refusal).

Trust-boundary cross-reference: no-op. `ls docs/reviews/security-review-*.md` matches nothing (this repo's security outputs are named `security-reviewer-review-*`), so no Trust Boundary Map was consumed.

## Dependency Map

- `scripts/lib/dev-cycle-read.sh` (the lib) is the stable core; it is sourced by `scripts/build-loop.sh` (line 193) and `scripts/dev-cycle.sh` (line 98). Nothing in the lib depends on either caller. The dependency direction is unchanged and correct.
- New inside the lib: `reader_settings` (602-641) -> `main_by_name`, `main_file` (536-550) -> `main_entry`/`entry_why`/`FENCE_AWK`/`oddwhy`, plus `SETTINGS_AWK` (559-577) and `readerform`. Its outputs (`IMPORT_READER_ROOTS`, `IMPORT_READER_HOMES`, `IMPORT_READER_WHY`) feed `import_readers` (1013-1063), which both walks call before their cache check; `import_targets` (1064-1090) reads `import_readers`' memo state directly.
- build-loop.sh: top level calls `reader_settings` (305) once main is found by name; `read_settings` (349-417) still lives in build-loop.sh and calls the lib's `main_file` with the lib's `SETTINGS_AWK`; `--settings` prints `READERS_LINE` (739) next to the four lines read_settings set.
- dev-cycle.sh: calls `reader_settings` at top level (192) for every mode; only `--check-fix` (via `truthwalk tree`) consumes the lists.
- docs/dev-cycle.md on the default branch is now read twice per build-loop.sh settings/check run, by two parsers in two files over the one SETTINGS_AWK output format.

## Findings

#### F1. One settings file, one awk output format, two parsers in two modules

**Severity:** Coupling
**Location:** `scripts/lib/dev-cycle-read.sh:559-577`, `scripts/lib/dev-cycle-read.sh:610-631`; `scripts/build-loop.sh:359-388`
**Move:** 2 (responsibility boundaries), 7 (coupling surface)
**Confidence:** Medium
**Legibility-target:** a reader changing the "Self-merge never:"-style list-line rule should find it in one place.

**Evidence:**
lib (SETTINGS_AWK, now holding build-loop.sh's keys too):
```
  if (index(s, "buildlooppolicy") == 1) k = "policy"
  else if (index(s, "buildloopslots") == 1) k = "slots"
  else if (index(s, "selfmergenever") == 1) k = "never"
  else if (index(s, "readerroots") == 1) k = "roots"
  else if (index(s, "readerhomes") == 1) k = "homes"
```
lib reader_settings:613, 620-621, 623, 627:
```
      read -r k c l1 l2 nx <<<"${l%%$'\t'*}"
...
      elif [[ "$t" != "$key "* || ! "$v" =~ ^[^\ ]+(\ [^\ ]+)*$ ]]; then why="line ${first[$k]} is not exactly \"$key PATH ...\" with single spaces"
      elif [[ "${next[$k]}" != 1 ]]; then why="line ${first[$k]} is followed by a non-blank line outside a fence (it may continue the list)"
...
        IFS=' ' read -ra ps <<<"$v"; i=0; rd_seen=()  # not a bare $v: the shell would expand * and ?
...
          if [[ -n "${rd_seen[$p]-}" ]]; then why="line ${first[$k]} lists entry $i twice"; break; fi
```
build-loop.sh read_settings:362, 372-374, 378, 382:
```
      read -r k c l1 l2 nx <<<"${l%%$'\t'*}"
...
      if [[ "$t" != "Self-merge never: "* || ! "$v" =~ ^[^\ ]+(\ [^\ ]+)*$ ]]; then
        why='is not exactly "Self-merge never: GLOB ..." with single spaces'
      elif [[ "${next[never]}" != 1 ]]; then why="is followed by a non-blank line outside a fence (it may continue the list)"
...
        IFS=' ' read -ra parts <<<"$v"  # not a bare $v: the shell would expand * and ? against files
...
          if [[ -n "${seen[${g%/}]-}" ]]; then why="lists entry $i twice"; break; fi
```

The plan moved main_file and SETTINGS_AWK into the lib so reader_settings could use them, but stopped at the reader: the lib now owns the awk program that recognises build-loop.sh's three keys (policy, slots, never) while build-loop.sh owns their interpretation, and the "KEY COUNT FIRST SECOND NEXT<TAB>LINE" record format is decoded by two copy-identical loops in two files. The list-line rule (exact key, single spaces, next line blank, entries checked by a form function, listed once) is now implemented twice, once for `Self-merge never:` and once for the reader keys, with near-identical refusal wording. A change to that rule (or to SETTINGS_AWK's record layout, e.g. a sixth field) must be made in both files and both test suites, and the lib's SETTINGS_AWK comment has to name build-loop.sh's read_settings as a consumer, which is a lib-to-caller knowledge edge the lib otherwise avoids. Both copies are correct today; the cost is change propagation. U2b3b2 does not add a key, so nothing forces the fix now, but the next settings key (any U3 policy line) would make it a third copy.

**Recommendation:** Add one lib helper that decodes FILE_OUT into the caller's associative arrays (`settings_records CNT FIRST SECOND NEXT TEXT`, namerefs) and one for the list-line rule (`settings_list KEY FORMFN` -> entries array or WHY), and have both read_settings' never branch and reader_settings call them. If that is deferred, at least record the twin in both comments so an editor of one finds the other.

#### F2. Contract item 9 is still an unenforced call-order precondition, and forgetting it fails open

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:86-92` (item 9), `scripts/lib/dev-cycle-read.sh:1013-1024` (import_readers)
**Move:** 3 (module boundary), 7 (coupling: temporal)
**Confidence:** Medium
**Legibility-target:** a future floor caller (U2c, U3) should not be able to under-model the readers by omission.

**Evidence:**
```
#  9. Call reader_settings after sourcing the lib (which clears the reader
#     lists) and resolve_main, and before a decision's first walk: it sets
#     IMPORT_READER_ROOTS and IMPORT_READER_HOMES from the default branch's
#     docs/dev-cycle.md, never from the environment (the host spellings of the
#     main worktree and the host HOME: import_readers), or IMPORT_READER_WHY,
#     which fails both walks. build-loop.sh and dev-cycle.sh both call it. Never set
#     IMPORT_ROOTS or IMPORT_HOMES: they are import_readers' results.
```
import_readers (1024):
```
  [[ -n "${ROOT_REAL:-}" && -z "$IMPORT_READER_WHY" ]] || return 1
```

Turning item 9 from "set two globals" into "call reader_settings" is a clear improvement and closes override row 537 for both current callers. But reader_settings remains a side-effecting function whose effect the walks cannot observe: a caller that sources the lib and walks without calling it gets empty lists (the lib clears them on source), which is indistinguishable from "settings say none", so the floor models fewer readers than docs/dev-cycle.md names and passes a path a host session imports. The malformed and unreadable cases fail closed (IMPORT_READER_WHY), so the only fail-open path is omission, which is exactly what a precondition in a comment cannot prevent. The globals-in-caller's-shell style itself is consistent with the lib (FILE_OUT, TRUTH_WHY, IMPORT_HOME*), so the side effect is not the problem; the missing "was it called" bit is.

**Recommendation:** Have reader_settings set a sentinel (e.g. `IMPORT_READER_SRC=settings|none-by-name`) cleared on source, and have import_readers return 1 when it is empty, so omission fails closed like a malformed line. Test helpers (imps, T_READER_*) set the sentinel alongside the lists.

#### F3. import_targets reads import_readers' memo internals, and a refusal is encoded as an empty IMPORT_ROOTS (stale comment)

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:771-773`, `scripts/lib/dev-cycle-read.sh:1019-1021`, `scripts/lib/dev-cycle-read.sh:1067-1069`
**Move:** 7 (content coupling)
**Confidence:** High (builds on the fact-check's Stale verdict for lib:771-773)
**Legibility-target:** U2b3b2's outside-seed caller (override row 538) needs to know what import_targets does after a refusal without reading import_readers' body.

**Evidence:**
comment (771-773):
```
# also reads ROOT_REAL, HOME (through import_home, which sets the IMPORT_HOME*
# globals in the caller's shell unless called in a subshell), import_readers'
# IMPORT_ROOTS and IMPORT_HOMES when its memo key is current (else ROOT_REAL
# alone and import_home's home: a call outside a walk), and IMPORT_LEFT
```
import_readers (1019-1021):
```
  # A refusal is memoized too, as an empty IMPORT_ROOTS (a result never is:
  # ROOT_REAL leads it), so a refusing decision lists the registry once (U2b3a final performance F1).
  if [[ "$IMPORT_READERS_DONE" == "$IMPORT_READERS_KEY" ]]; then [[ -n "$IMPORT_ROOTS" ]]; return; fi
```
import_targets (1068-1069):
```
  import_readers_key
  [[ -z "$IMPORT_READERS_DONE" || "$IMPORT_READERS_DONE" != "$IMPORT_READERS_KEY" ]] || { roots="$IMPORT_ROOTS"; homes="$IMPORT_HOMES"; }
```

D7's memoized refusal changes the meaning of import_readers' state without a named representation: "memo current and IMPORT_ROOTS empty" now means refused, and import_targets, which recomputes import_readers' key and compares it to IMPORT_READERS_DONE itself, picks up the empty roots and fails in IMPORT_AWK's BEGIN (`if (nr == 0 || roots[1] == "") exit 2`, line 940). The outcome is fail-closed and correct, but it is reached through two functions sharing an implicit sentinel, and the comment still describes the pre-D7 behaviour (ROOT_REAL alone). U2b3b2 is planned to add the first caller of import_targets outside a walk (outside seeds), which is precisely where a reader would rely on that comment.

**Recommendation:** Update the comment to the three cases (current result, memoized refusal -> fails, no current memo -> ROOT_REAL alone). Optionally give import_readers a named state (e.g. `IMPORT_READERS_OK=0|1`) that import_targets reads instead of re-deriving the key, so the refusal encoding is owned by one function. The comment fix fits this unit; the state variable can ride U2b3b2 (row 538).

#### F4. dev-cycle.sh reads the reader settings in every mode, though only --check-fix walks

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:189-192`
**Move:** 2 (responsibility boundaries)
**Confidence:** Medium
**Legibility-target:** a reader of dev-cycle.sh's top level should see which modes depend on main's docs/dev-cycle.md.

**Evidence:**
```
resolve_main || [[ -n "$CHECK" ]] || { echo "Could not resolve a default branch (tried origin/HEAD, main, master, the current branch)" >&2; exit 1; }
# The reader lists the import walk takes, from main's settings (the lib's caller
# contract item 9); without main found by name they stay empty.
reader_settings
```

The call precedes the check-mode dispatch and the summary run, so --check-path, --check-write, --check-brief, --check-branch, --check-answer and the default summary each read and parse docs/dev-cycle.md from main and discard the result. It is harmless (reader_settings never exits and only sets globals), and placing it once at top level is the simplest way to satisfy item 9, so this is not worth restructuring now. Two observations for later: (a) "no default branch by name" and "settings say none" collapse to the same empty lists, so `--check-fix` without main by name walks with no host readers while an unreadable settings file fails it (the plan chose this; it is an asymmetry, not a bug); (b) if F2's sentinel is adopted, the "none-by-name" source becomes visible to the walk instead of silent.

**Recommendation:** No change needed this unit. If dev-cycle.sh grows a second walking mode, keep the call at top level; if it stays one, consider moving it into the --check-fix branch so the dependency is local to its consumer.

#### F5. "Caller root" now means a host spelling of the main worktree; the semantics are consistent across the touched docs

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:585-590`, `scripts/lib/dev-cycle-read.sh:1028-1037`; `docs/dev-cycle.md:28-31`
**Move:** 3 (module boundary: contract semantics)
**Confidence:** Medium
**Legibility-target:** U2b3b2 seeds "each root's ancestor directories" and "other roots' checkout-only starts"; it must treat re-spelled worktree roots and caller roots alike.

**Evidence:**
```
  # The first record is the main worktree, which each caller root spells on a
  # host, so the worktrees registered beneath it are spelled beneath each
  # caller root there too (U2b3a i1 architecture F4).
  [[ ${#rs_w[@]} -eq 0 ]] || rs_m="${rs_w[0]}"
```

Item 9's older "host spellings of this checkout" was replaced by "the host spellings of the main worktree" in item 9, in reader_settings' comment, in import_readers' comment and in docs/dev-cycle.md; I found no remaining copy of the old wording in the touched files. The G8 re-spelling is the right place for this (inside import_readers, the one owner of the root set), and it means the settings key names one fact (where the host sees the main worktree) rather than enumerating every worktree, which keeps the data model small. One consequence to carry into U2b3b2: the root set is now a product (caller roots x worktrees beneath main), so anything U2b3b2 does per root (ancestor seeds, C1 checkout-only starts) multiplies with it; the IMPORT_WORK_MAX comment at 751-752 already records the doubling. A registered worktree outside the main worktree (e.g. /home/magfrump/cw-egress-verify) is not re-spelled, which matches the semantics.

**Recommendation:** None for this unit. U2b3b2's plan should state whether its per-root seeds iterate IMPORT_ROOTS (the product) or the caller's roots plus the registry.

## What Looks Good

- The lib stays the single owner of the reader model: settings parsing (reader_settings), root-set construction (import_readers) and the refusal (IMPORT_READER_WHY) all live in it, and both callers reach it through one call, which closes override row 537's two-caller divergence.
- Dependency direction is preserved: moving main_file into the lib pulls a function down to the shared core that both callers already depended on (main_entry, FENCE_AWK), with no new lib-to-caller call.
- Malformed, duplicate and unreadable settings fail both walks closed through one variable that import_readers checks and keys its memo on, so a refusal cannot be served from a stale success.
- readerform reuses NAMECHARS rather than inventing a new character rule, which keeps D6 aligned with the lib's other path forms.
- `--settings`' fifth line gives the user a single place to see what the walks model, consistent with the existing four lines' "VALUE STATE: WHY" shape.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | One settings file, two parsers in two modules (SETTINGS_AWK record decode and list-line rule duplicated; lib holds build-loop's keys) | Coupling | `scripts/lib/dev-cycle-read.sh:559-577,610-631`; `scripts/build-loop.sh:359-388` | Medium |
| 2 | Item 9 call-order precondition unenforced; omission fails open | Minor | `scripts/lib/dev-cycle-read.sh:86-92,1024` | Medium |
| 3 | import_targets reads import_readers' memo internals; refusal encoded as empty IMPORT_ROOTS; comment stale | Minor | `scripts/lib/dev-cycle-read.sh:771-773,1021,1069` | High |
| 4 | dev-cycle.sh reads reader settings in every mode | Informational | `scripts/dev-cycle.sh:192` | Medium |
| 5 | "Caller root" = host spelling of the main worktree; consistent; root set is now a product U2b3b2 inherits | Informational | `scripts/lib/dev-cycle-read.sh:1028-1037` | Medium |

## Overall Assessment

The change maintains the system's structure: the lib remains the stable core, the reader model gains its settings source without any new upward dependency, and the two-caller divergence from U2b3a is closed. No Structural finding. The one amber item is F1: the split between lib and build-loop.sh was drawn by "what reader_settings needs" rather than by responsibility, so docs/dev-cycle.md now has one tokenizer in the lib and two decoders/validators across two files; it is fixable in place with two small lib helpers and does not block U2b3b2. F3's stale comment is the cheapest fix with the most direct payoff for U2b3b2's outside-seed caller. The single most important structural concern going forward is F2: the reader model's correctness still rests on every gate caller remembering one call, and a sentinel would make omission fail closed.

## Goal-Alignment Note

The user goal is to land U2b3b1 after a clean review-fix loop. Nothing here is Structural (red). F1 (amber) is a change-propagation cost, not a defect: the two copies agree today, and the fix is a refactor of build-loop.sh's read_settings that could equally ride U2b3b2 or the next settings key if the fixer prefers to keep this unit's diff narrow; deferring it with a revisit trigger ("the next docs/dev-cycle.md key, or any change to the list-line rule") would be a defensible override. F3's comment correction is in this unit's scope (the fact-check flagged it) and small. F2, F4 and F5 are green and inform U2b3b2/U2c rather than gate this merge.
