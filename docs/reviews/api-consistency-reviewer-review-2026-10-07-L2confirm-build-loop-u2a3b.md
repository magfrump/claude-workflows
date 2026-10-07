Commit: 4828727d

# API Consistency Review: feat/build-loop-u2a3b, loop 2 confirming pass (Q-120 [1])

**Scope:** `git diff main...4828727d -- . ':!docs/reviews'`, the full unit, with the closest reading on aa379ee9. The public surface covered: the reader lib's functions and globals (`scripts/lib/dev-cycle-read.sh`), `--check-fix`'s output contract (`scripts/dev-cycle.sh`, `skills/dev-cycle/SKILL.md`), the sourcing inventory (`test/scripts/dev-cycle.bats`), and known issues A3/A5 and plan F11.
**Date:** 2026-10-07
**Based on:**
- the Stage 1 summary `u2a3b-L2confirm-stage1.md` (code-fact-check r1-r3 at 4828727d; its wording findings S1-S7 are not re-filed here)
- the rubric's "Loop 2, iteration 3 of 3" rows L2-F-A1..A5 and L2-F-C1..C15
- override-log rows from line 374
- my prior report `api-consistency-reviewer-review-2026-10-07-L2final-build-loop-u2a3b.md` (F1-F6 at e1654266)

Executed probes ran on a `git archive 4828727d` copy in `/tmp/u2a3bapic-XXXX`, each under `timeout 20`. The directory was removed afterwards and no process was left running.

## Baseline Conventions

These are unchanged from the prior pass and re-checked at 4828727d:
- **Globals** are ALL-CAPS:
  - Pattern constants are named for what they match: `INSTRUCTION_FILE` :446, `NAMECHARS`, `DIGIT`, `SLUG`.
  - Awk programs end in `_AWK`: `FENCE_AWK`, `ANSWER_AWK`, `IMPORT_AWK` :541.
  - A real path ends in `_REAL`: `ROOT_REAL`.
  - A cache key ends in `_DONE`: `IMPORTED_DONE`, `IMPORTED_MAIN_DONE` :488.
- **Functions** are lower snake_case:
  - Printing functions take noun names.
  - Predicates are bare.
  - Per-call options are positional.
  - Awk receives paths through `ENVIRON` with a short owner prefix (`IT_*`; `PQ_WANT` in `scripts/paper-queue.sh`).
- **Errors:**
  - A walk returns 1 and sets its list to `error`.
  - A cached error returns 1 again.
  - A check mode prints `skip <path>: <reason>` and exits 0.

## Name-Pattern Audit

| Name (at 4828727d) | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `IMPORT_HOME_REAL` (was `IMPORT_HOMER`) | global, real path | `ROOT_REAL` | `scripts/lib/dev-cycle-read.sh` (need_root, callers) | Consistent (prior F1 fixed) |
| `IMPORT_HOME_DONE` (was `IMPORT_HOME_KEY`) | global, cache key | `IMPORTED_DONE`, `IMPORTED_MAIN_DONE` | lib :488 | Consistent in name. Its comment's description of the value is loose (N3) |
| `UTF8_WELL_FORMED` (was `UTF8_OK`) | global, ERE | `INSTRUCTION_FILE`, `DIGIT`, `SLUG` | lib :446 | Consistent (prior F2 fixed) |
| `IT_HOME_REAL` (was `IT_HOMER`); awk `homereal` | ENVIRON name / awk var | `IT_DIR`, `IT_ROOT`, `IT_HOME`, `IT_LEFT` | lib :601, :645 | Consistent |
| `IMPORT_HOME` | global, state | `MAIN`, `MAIN_SHA` | lib :616 | Consistent |
| `IMPORT_OUT_MAX` | global, limit | `MAX_ROUNDS` (`scripts/self-improvement.sh`) | lib :495 | Unchanged since the prior pass: the suffix form is new to the lib. Not re-filed |
| `IMPORT_LEFT` | env parameter | positional options (`blocker $2`, `skipped ${2:-file}`) | lib | Now named in the header (prior F3). Residue in N1 |
| `import_home`, `tree_starts`, `import_targets`, `IMPORT_AWK` | functions / awk program | `resolve_main`, `untracked_md`, `FENCE_AWK` | lib | Unchanged since the prior pass. Consistent |
| `--check-fix` reasons ("names it after an @", "the import walk failed") | output lines | other `skip <path>: ...; file it instead` lines | `scripts/dev-cycle.sh:180-184` | Consistent |

The old spellings are gone from the tree. `git grep -E 'IMPORT_HOMER|IMPORT_HOME_KEY|UTF8_OK|IT_HOMER|\bhomer\b' 4828727d -- . ':!docs/reviews'` returns nothing. **Executed:** after sourcing, none of the old names is defined and all of the new ones are.

## Findings

#### N1. import_targets' input sentence still omits its global side effect and the empty/non-numeric IMPORT_LEFT readings

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:503-507` (header), `:626` and `:646` (body)
**Move:** 3 (consumer contract)
**Confidence:** High

Evidence:
```
# the top level): one repo-relative path per line, case kept, each once. It
# also reads ROOT_REAL, HOME (through import_home) and IMPORT_LEFT (what may
# still be printed; IMPORT_OUT_MAX when unset). Every import walk shares these
...
  import_home || return 1
...
    IT_LEFT="${IMPORT_LEFT:-$IMPORT_OUT_MAX}" awk "$IMPORT_AWK" || return 1
```

The fix for L2-F-C5 holds for the inputs: ROOT_REAL, HOME and IMPORT_LEFT are now named in one place. Two parts of my prior F3 remain:
- **The global side effect is not stated.** A direct call writes `IMPORT_HOME`, `IMPORT_HOME_REAL` and `IMPORT_HOME_DONE` in the caller's shell. Executed: after a pipeline call, `DONE=[]`. After a direct call (`import_targets "" < <(...)`), `DONE=[xset:/home/node] REAL=[/home/node]`.
- **"When unset" is narrower than the code.** `:-` also defaults an empty `IMPORT_LEFT` (executed: `IMPORT_LEFT=""` prints the names, rc=0). A non-numeric value reads as 0 and fails (executed: `IMPORT_LEFT=abc` gives rc=1).

Both readings are fail-closed or harmless. The only callers are the two walks, which run it inside `$(...)`. The plan already routes the internal `import_home` call to U2b, so this is Informational.

**Recommendation:** If the header is touched again, write "IMPORT_OUT_MAX when unset or empty" and add "called outside a subshell, it sets the IMPORT_HOME* globals". Otherwise, let U2b's change (the home passed in by the caller) remove the side effect.
Executed vs reasoned: executed. Legibility-target: for-author.

#### N2. main_imports' header does not say a cached error returns 1 again; imported_names' does

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:480-483` (main walk cache paragraph) against `:457-459` (tree walk) and `:712` (code)
**Move:** 7 (asymmetry between sibling interfaces)
**Confidence:** High

Evidence:
```
# inrepo_here that fails skips its path. One result is cached, for the root in
# IMPORTED_DONE; a call for another ROOT_REAL recomputes it, and a cached error
# returns 1 again.
...
# IMPORTED_MAIN reads "error" until a walk succeeds; the result is cached for
# the commit, MAIN_BY_NAME and root in IMPORTED_MAIN_DONE, so a caller whose
...
  [[ "$IMPORTED_MAIN_DONE" == "$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL" ]] && { [[ "$IMPORTED_MAIN" != error ]]; return; }
```

**What the code does:** both walks return 1 again on a cached error. Executed: `IMPORT_OUT_MAX=1; main_imports` fails. Raising the limit back and calling again still fails, because the cached error answers. Clearing `IMPORTED_MAIN_DONE` lets the next call pass.

**The header gap:** only the tree walk's header says so. After aa379ee9 this is the one remaining gap between the two walks' failure contracts; the failure-arm lists now match (L2-F-C6 holds, see below).

**Why it matters for U2a4:** a caller that retries after changing `IMPORT_OUT_MAX` or HOME has to clear the cache. The retry rule is half-stated already: `:483` covers HOME and `:493-494` covers IMPORT_OUT_MAX.

**Pre-existing on main** (main's lib :472 has the same paragraph). Override row "Closes this unit's three 'Defer (routed to U2a3)' rows (... I2-C2 main_imports' header ...)", marked Fixed (on main), closed iteration 2's I2-C2. That finding listed "nor that a cached error returns 1 again" as one of its parts. Neither main nor this branch states it, so that row's "Fixed" still does not hold for this one clause. This is new evidence against the row's scope, not a re-raise. The other clauses now hold.

**Recommendation:** Append "a cached error returns 1 again" to the IMPORTED_MAIN sentence, or route the clause to U2a4 with the shared predicate (override row "To word a failed walk a caller must run the walk ..."), which owns retry semantics.
Executed vs reasoned: executed. Legibility-target: for-author.

#### N3. import_home's comment describes IMPORT_HOME_DONE as holding HOME; it holds a set-flag key

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:613-615, 618-619`
**Move:** 3 (contract wording)
**Confidence:** Medium

Evidence:
```
# when HOME itself changes (IMPORT_HOME_DONE holds the HOME it was computed
# for). A relative home is kept, and the parser fails on a ~/ name then.
...
  local h hr="" key="x${HOME+set}:${HOME-}"
  [[ "$IMPORT_HOME_DONE" != "$key" ]] || return 0
```

The value is `x<set|"">:<HOME>`; executed, it reads `xset:/home/node`. It is not HOME itself. The sibling `*_DONE` globals hold their key parts literally:
- `IMPORTED_DONE` holds `$ROOT_REAL`
- `IMPORTED_MAIN_DONE` holds `"$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL"`

So a reader of this comment could test `[[ $IMPORT_HOME_DONE == $HOME ]]`, which is always false. The encoding is right: it tells unset from empty, and the `x` keeps it non-empty, so `IMPORT_HOME_DONE=""` forces a recompute like its siblings. Only the description is loose.

**Recommendation:** Write "IMPORT_HOME_DONE holds a key for the HOME it was computed for (set or unset, and its value); clear it to recompute".
Executed vs reasoned: executed (value printed). Legibility-target: for-author.

## Prior findings rechecked (my L2-final F1-F6; rubric L2-F-C4, C5, C6, C7, C12)

- **F1 / L2-F-C4 (names):** holds. The old names are gone tree-wide and the new names follow `_REAL` / `_DONE`. `import_home` keeps its noun name; that was optional in the prior report and is not re-raised.
- **F2 / L2-F-C4 (`UTF8_WELL_FORMED`):** holds. It is used at :636 only.
- **F3 / L2-F-C5:** holds for the inputs; the residue is N1.
- **F4 / L2-F-C6 (failure lists):** holds. imported_names (:454-456) now lists "import_home or the parser (its comment lists why) fails, the IMPORT_OUT_MAX budget is spent". main_imports (:703-707) lists "import_home, the parser (its comment lists why) or a lower fails, the IMPORT_OUT_MAX budget is spent". Reading both functions whole (:662-693, :708-785), every `return 1` arm is covered by its list:
  - imported_names' `import_home || return 1` at :676 and budget arm at :685
  - main_imports' `import_home` at :736, parser at :742, budget at :764 and lower at :766

  The two lists word the shared arms the same way. The added "(the top-level .git is skipped)" sits inside main_imports' failure sentence. It reads as an exception to the plain-directory arm, which is what :778 does.
- **F5 / L2-F-C7 (A3):** holds. A3 now reads "Imports through a symlinked file or directory print `ok`. ... (Absolute-path imports into the repo are refused since U2a3b.)"
- **F6 / L2-F-C12 (python3):** holds as dispositioned. The lib header says "a file they read" and "(every path is refused)". dev-cycle.sh's dependency paragraph is deliberately left (rubric: "no cause printed: left"), so it is not re-raised.
- **`--check-fix` and SKILL.md wording:** consistent with each other and with the code.
  - The help says "names after an @, read broadly ... and for every path when the import walk fails" (`scripts/dev-cycle.sh:54-55`).
  - The skill says "names after an `@`, read broadly ... refuses every path when the import walk fails" (`skills/dev-cycle/SKILL.md:75-76`).
  - The two reasons are `skip $a: the instruction-file import walk failed, ...; file it instead` and `skip $a: an instruction file names it after an @ ..., so it may be read as instructions; file it instead` (:181-184). The tests match the new prefix (`test/scripts/dev-cycle.bats:1027,1056,1063,1070,1083,1097`).
  - "For every path" is true of the outcome, but non-doc paths keep their own earlier reason. The skill's "refuses every path" states the same outcome.
- **Sourcing inventory** (`test/scripts/dev-cycle.bats:1108-1114`): it gains `tree_starts` and `IMPORT_AWK` and drops the removed `IMPORT_RE`. It still omits `import_home`, `IMPORT_OUT_MAX`, `UTF8_WELL_FORMED` and the `IMPORT_HOME*` globals. That list was never exhaustive (`NAMECHARS`, `DIGIT`, `SLUG` were never in it), so, as in the prior pass, no finding is filed.

## What Looks Good

- The aa379ee9 renames are mechanical and complete. They touch the lib's global, the awk ENVIRON name and the awk variable together, and leave no stale reference in the tests or docs. [unverified — submitted as claim] Location: `scripts/lib/dev-cycle-read.sh:552,601,609,616-623,636,645`.
- The two walks' failure lists now share one phrasing for the arms they share ("import_home ... the parser (its comment lists why) ... the IMPORT_OUT_MAX budget is spent"), and both point to the parser's own return list rather than repeating it. [unverified — submitted as claim] Location: `scripts/lib/dev-cycle-read.sh:454-456,703-707,533-536`.
- `IMPORT_HOME_DONE`'s key distinguishes unset from empty HOME and is never empty, so clearing it to `""` forces a recompute like the sibling `*_DONE` caches. [unverified — submitted as claim] Location: `scripts/lib/dev-cycle-read.sh:618-619`.
- `--check-fix` keeps its `ok` / `skip <path>: <reason>; file it instead` grammar and exit 0 for skips, and help, skill and tests use the same reason prefixes. [unverified — submitted as claim] Location: `scripts/dev-cycle.sh:51-55,180-185`; `skills/dev-cycle/SKILL.md:72-77`.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---|---|---|---|
| N1 | import_targets' header omits its IMPORT_HOME* side effect and the empty/non-numeric IMPORT_LEFT readings (prior F3 residue) | Informational | `scripts/lib/dev-cycle-read.sh:503-507,626,646` | High |
| N2 | main_imports' header omits "a cached error returns 1 again" (pre-existing; the I2-C2 closing row's "Fixed (on main)" does not hold for this clause) | Informational | `scripts/lib/dev-cycle-read.sh:480-483,712` | High |
| N3 | import_home's comment says IMPORT_HOME_DONE holds HOME; it holds a set-flag key | Informational | `scripts/lib/dev-cycle-read.sh:613-615,618` | Medium |

## Overall Assessment

aa379ee9's API fixes hold:
- The three renames bring `IMPORT_HOME_REAL`, `IMPORT_HOME_DONE`, `UTF8_WELL_FORMED` and `IT_HOME_REAL` in line with the lib's `_REAL` / `_DONE` / pattern-noun conventions, with no stale references left.
- import_targets now names its inputs.
- Both walks' failure lists cover every `return 1` arm in the same words.
- A3 no longer overstates the gap.

`--check-fix`'s contract is unchanged in shape and stated the same way in the help, the skill and the tests. The three findings are Informational comment-wording items: two are residue of earlier findings and one is pre-existing on main. None affects a consumer at runtime, since every reading they describe fails closed or is harmless. From an API-consistency standpoint the unit is clean to merge. N2 is the only one U2a4's floor might lean on, and it can be routed there.

## Goal-Alignment Note

- **Success criterion (restated verbatim):** A markdown report saved at the output path named in your role section, structured per your skill, with a `Commit: 4828727d` line at the top.
- **Answered:**
  - naming and contracts of the renamed globals and functions (audit table, N1, N3)
  - the two walks' headers and failure lists (F4 recheck, N2)
  - `--check-fix` and SKILL.md wording (prior-findings recheck)
  - whether the prior F1-F6 fixes hold (all hold; F3 has the N1 residue)
- **Out of scope:**
  - Stage 1's S1-S7 (not re-filed). S2, the walk caches and HOME, is adjacent to N2 but distinct: S2 is about which cache to clear, N2 about the cached-error return.
  - security and performance behaviour of the new charge and the .git rule
  - override-routed items (reader model to U2b, capped blob read to U2a3c, the python3 cause wording left by L2-F-C12)
- **Escalate:** none.
- **Decisions I made:**
  - Filed N2 as new evidence against the I2-C2 closing row's scope rather than as a re-raise, because one named clause of that row is still false on main and on the branch.
  - Rated all three Informational: nothing consumes these comments mechanically, and each reading fails closed.
  - Did not re-file the sourcing inventory's omissions (never exhaustive) or `import_home`'s noun name (optional before).
