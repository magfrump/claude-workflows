Commit: f56ba3f5

# API Consistency Review — feat/build-loop-u2b3b1 (U2b3b1, final confirming pass)

**Scope:** `git diff main...HEAD` in /workspace/.claude/wt-build-loop-u2b3b1 (scripts/lib/dev-cycle-read.sh, scripts/build-loop.sh, scripts/dev-cycle.sh, docs/dev-cycle.md, three bats files), with a focus on what changed after iteration 1 (1ece139d)
**Date:** 2026-10-09
**Based on:** the merged Stage 1 fact-check (k=3, docs/reviews/code-fact-check-report-build-loop-u2b3b1-final-r{1,2,3}.md); iteration 1's report docs/reviews/api-consistency-review-2026-10-09-u2b3b1.md

## Baseline Conventions

These are unchanged from iteration 1 (see that report). The parts this pass relies on:

- **--settings line grammar** (scripts/build-loop.sh:15-53): `KEYWORD VALUE STATUS: WHY`, with the `set|none|malformed` vocabulary of the never line. A malformed readers WHY now ends `; both import walks fail`, and the header says so (build-loop.sh:52-53).
- **Walk-failure texts (siblings on main):** the floor's `the default branch's instruction files could not be walked for @ imports` (lib:1417) and --check-fix's `the instruction-file import walk failed, so an import of it cannot be ruled out; file it instead` (dev-cycle.sh:187). Each says which tree was walked (floor) or why the path is skipped (--check-fix).
- **"No default branch" texts:** `build-loop.sh needs a default branch found by name (origin/HEAD, main or master); found none` (build-loop.sh:302), and `$CHECK needs a default branch (origin/HEAD, main or master); found none` (dev-cycle.sh:200). Both name the three places a branch is looked for.
- **Caller contract** (lib header, items 1-9): each item tells a caller what to call or set, and what never to set.

## Name-Pattern Audit

No new public names since iteration 1. The 1ece139d fix added two output texts (below) and no function, global, key or flag. The iteration 1 audit table still holds: `readers` line, `Reader roots:`, `Reader homes:`, `reader_settings`, `readerform`, `main_file`/`SETTINGS_AWK` (moved), `READERS_LINE`, `IMPORT_READER_WHY`: all Consistent. The one Minor row there, `reader_settings` vs `read_settings` (iteration 1 F4), is addressed by the comment at scripts/build-loop.sh:305-306 rather than a rename. That is one of the two remedies iteration 1 offered.

| New text | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `the reader settings of docs/dev-cycle.md cannot be used (WHY), so the instruction files could not be walked for @ imports` | floor reason | `the default branch's instruction files could not be walked for @ imports` | `scripts/lib/dev-cycle-read.sh:1417` | Mostly consistent. It drops "the default branch's" (F1) |
| `skip PATH: the reader settings of docs/dev-cycle.md cannot be used (WHY), so the instruction-file import walk failed; file it instead` | --check-fix skip line | `skip PATH: the instruction-file import walk failed, so an import of it cannot be ruled out; file it instead` | `scripts/dev-cycle.sh:187` | Mostly consistent: `skip PATH: ...; file it instead` frame kept. It drops the "cannot be ruled out" clause (F1) |
| `no default branch was found by name, so its reader settings cannot be read` | IMPORT_READER_WHY | `needs a default branch found by name (origin/HEAD, main or master); found none` | `scripts/build-loop.sh:302`, `scripts/dev-cycle.sh:200` | It leaves out the three places looked, and it is redundant inside the --check-fix frame (F2) |

## Findings

#### F1. The two new walk-failure texts each drop a clause their sibling text carries

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:1416` (sibling 1417); `scripts/dev-cycle.sh:186` (sibling 187)
**Move:** 4 (error message consistency)
**Confidence:** High
**Legibility-target:** the operator reading a floor refusal or a --check-fix skip line

Evidence (floor, lib:1416-1417): `FLOOR_WHY="the reader settings of docs/dev-cycle.md cannot be used ($IMPORT_READER_WHY), so the instruction files could not be walked for @ imports"` / `FLOOR_WHY="the default branch's instruction files could not be walked for @ imports"`. Evidence (--check-fix, dev-cycle.sh:186-187): `echo "skip $a: the reader settings of docs/dev-cycle.md cannot be used ($IMPORT_READER_WHY), so the instruction-file import walk failed; file it instead"` / `echo "skip $a: the instruction-file import walk failed, so an import of it cannot be ruled out; file it instead"`.

Naming the cause fixes iteration 1's F1 as intended. But each new text loses a clause from its sibling:
- The floor's new text says "the instruction files", not "the default branch's instruction files". The floor walks main (`truthwalk main`), and the sibling names that tree.
- --check-fix's new text ends at "the import walk failed". It no longer says why that makes the path a skip ("so an import of it cannot be ruled out"), which is the clause that connects a walk failure to this path.

The WHY is also wrapped in parentheses. As a result, the build-loop-check.bats:1879 case reads `(more than one line starts "Reader roots:" (lines 1 and 3)), so ...` with nested parentheses. A file the fence reader refuses reads `(..., so the file is not read), so the ...`, which brings back iteration 1 F3's "so ... so" chain inside the parentheses.

**Recommendation:** This can be done at no line cost by editing the two strings: floor `"the default branch's instruction files could not be walked for @ imports: its reader settings in docs/dev-cycle.md cannot be used ($IMPORT_READER_WHY)"`, and --check-fix `"... cannot be used ($IMPORT_READER_WHY), so the import walk failed and an import of it cannot be ruled out; file it instead"`. Update the two test assertions (build-loop-check.bats:1879, dev-cycle.bats:1418-1423) to match. A colon or `: ` join instead of parentheses also avoids the nesting. If you leave the texts as they are, an override row covers it.

#### F2. The no-main --check-fix line repeats itself and does not say where a default branch is looked for

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:598`, rendered through `scripts/dev-cycle.sh:186`
**Move:** 4 (error message consistency)
**Confidence:** High (composed from lib:598 and dev-cycle.sh:186; dev-cycle.bats:1423 asserts the prefix)
**Legibility-target:** a dev-cycle user running --check-fix in a repo whose default branch is not main/master/origin-HEAD

Precedent: `needs a default branch found by name (origin/HEAD, main or master); found none` used in `scripts/build-loop.sh:302` and `scripts/dev-cycle.sh:200`

Evidence: lib:598 `IMPORT_READER_WHY="no default branch was found by name, so its reader settings cannot be read"`. In dev-cycle.sh:186's frame the full line is `skip docs/notes.md: the reader settings of docs/dev-cycle.md cannot be used (no default branch was found by name, so its reader settings cannot be read), so the instruction-file import walk failed; file it instead`. "Reader settings" appears twice, and "by name" is never explained. Both sibling "no default branch" texts list `(origin/HEAD, main or master)`. That list is the only fix hint a user on a `trunk` repo gets, and the dev-cycle.bats:1407 case is exactly that case (`git branch -m main trunk`). This case is reachable only through dev-cycle.sh. build-loop.sh exits at line 302 before reader_settings, so its `readers malformed: no default branch ...` line never prints, and its header's list of malformed causes (build-loop.sh:50-52), which leaves out this case, is accurate for that script.

**Recommendation:** Change lib:598 to `no default branch was found by name (origin/HEAD, main or master)`, which costs no lines and matches both siblings. The redundant "so its reader settings cannot be read" goes, since the frame already says so.

#### F3. Contract item 9 no longer tells callers never to set the reader lists themselves

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:86-91`
**Move:** 3 (consumer contract)
**Confidence:** Medium
**Legibility-target:** the author of the next lib caller (U2c's floor caller)

Evidence: on main, item 9 read `Set IMPORT_READER_ROOTS and IMPORT_READER_HOMES ... from the default branch's settings (U2b3b), never from the environment`. Now it reads `Call reader_settings after sourcing the lib (which clears the reader lists) and resolve_main, before a decision's first walk: it sets IMPORT_READER_ROOTS and IMPORT_READER_HOMES from main's docs/dev-cycle.md ..., or IMPORT_READER_WHY, which fails both walks; both scripts call it. Never set IMPORT_ROOTS or IMPORT_HOMES: they are import_readers' results.` The "never" sentence still covers import_readers' outputs, but no longer the three reader_settings outputs. A caller could set or clear `IMPORT_READER_WHY` or the lists after the call, for example to "retry" a walk, without breaking a written rule. Clearing WHY after a refusal would turn a fail-closed walk into an unmodelled one. Both current callers are correct. No consumer breaks, and the environment path is closed in code (cleared on source and reset at the top of reader_settings).

**Recommendation:** At the next touch, extend the last sentence: "Never set IMPORT_READER_* (reader_settings' results) or IMPORT_ROOTS/IMPORT_HOMES (import_readers')". This rewords the existing line and adds none.

## What Looks Good

- **Iteration 1 F1 resolved:** both walks now name a settings cause where it takes effect (lib:1416, dev-cycle.sh:186), and both are tested (build-loop-check.bats:1879, dev-cycle.bats:1418-1423). route: code-fact-check
- **Iteration 1 F3 resolved:** the readers WHY now joins with `; both import walks fail` (lib:599, 630), the header documents the suffix (build-loop.sh:52-53), and build-loop-read.bats:506-526 pins every malformed form. route: code-fact-check
- **Iteration 1 F4 addressed** by the comment at build-loop.sh:305-306 ("Not read_settings below: without this call the walks model no host reader").
- **Iteration 1 F5 resolved:** plan:204 lists the fifth `readers` line in the never line's grammar, and docs/dev-cycle.md:32-34 says "a blank line (outside a code block) or the end of the file" and names a refused file as a cause.
- Iteration 1's F2 (explicit `none` prints `set`) and F6 (counts, not paths) are settled Won't-Fix rows. Not re-filed.
- The `readers` line keeps the `KEYWORD VALUE STATUS: WHY` shape. The keys still share SETTINGS_AWK's copy rule and the never line's malformed phrasing word for word. `IMPORT_READER_WHY` follows both the `IMPORT_READER_*` and `*_WHY` conventions. No consumer parses `--settings` by line count.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | New walk-failure texts drop "the default branch's" / "cannot be ruled out"; nested parentheses | Minor | `scripts/lib/dev-cycle-read.sh:1416`, `scripts/dev-cycle.sh:186` | High |
| F2 | No-main WHY repeats "reader settings" and leaves out "(origin/HEAD, main or master)" | Minor | `scripts/lib/dev-cycle-read.sh:598` | High |
| F3 | Contract item 9 no longer forbids setting IMPORT_READER_* directly | Informational | `scripts/lib/dev-cycle-read.sh:86-91` | Medium |

## Overall Assessment

The branch's public surface is consistent with the codebase. The fifth --settings line, the two keys and the lib names follow existing grammar. Iteration 1's actionable findings (F1, F3, F4, F5) are fixed or addressed, and the rest are settled override rows. What remains is wording in the two texts 1ece139d added. They name the cause, which was the point, but each drops a clause its sibling has, and the no-main variant leaves out the fix hint both sibling "no default branch" texts give. All three findings are string or comment edits that add no lines, so they fit the 397/400 cap. Nothing breaks a consumer.

## Goal-Alignment Note

The user goal is to land U2b3b1 after a clean review-fix loop. This pass finds no red and nothing Breaking or Inconsistent: two Minor findings and one Informational. F1 and F2 are string-only edits plus their test assertions, at zero net code lines. F3 is a one-line comment rewording. Any of them can go to the override log instead without risk, since every path stays fail-closed whatever the wording. The review stayed in its brief: nothing deferred to U2b3b2 (H5, H2, C1, G9, outside starts), and no settled 2026-10-09 override row, is re-filed.
