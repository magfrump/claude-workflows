Commit: 8ed86432

# API Consistency Review — feat/build-loop-u2b3b1 (U2b3b1, iteration 1)

**Scope:** `git diff main...HEAD` in /workspace/.claude/wt-build-loop-u2b3b1 (scripts/lib/dev-cycle-read.sh, scripts/build-loop.sh, scripts/dev-cycle.sh, docs/dev-cycle.md, three bats files)
**Date:** 2026-10-09
**Based on:** docs/reviews/code-fact-check-report-build-loop-u2b3b1.md (17 claims, 0 Incorrect)

## Baseline Conventions

- **--settings line grammar** (scripts/build-loop.sh:15-41): `KEYWORD VALUE STATUS: WHY` for policy/slots/never (`policy self-merge|review set|unset`, `slots N set|default`, `never GLOB... set|none|malformed`); constraints puts status first (`constraints ok N-hard M-soft|missing|...`). For a status other than set/ok the value is dropped (`never none: ...`, `never malformed: ...`). A set line's WHY names the line and file (`set: line N of docs/dev-cycle.md on the default branch`); constraints' names only the file (`ok 3-hard 2-soft: docs/constraints.md on the default branch`).
- **Explicit `none`** in `Self-merge never: none` prints `never none: line N ... lists none` (build-loop.sh:387); `none` with no line prints `never none: no line starts "Self-merge never:"`.
- **Malformed WHY wording**: `line N is not exactly "KEY ..." with single spaces`, `line N lists entry I twice`, `more than one line starts "KEY" (lines A and B)`, FILE_WHY passed through for an unread file. The never line states no consequence; the policy line states one only in its self-merge case ("so self-merge is off").
- **Settings keys** in docs/dev-cycle.md: two-word `<Subject> <attribute>:` (`Build-loop policy:`, `Build-loop slots:`, `Self-merge never:`), one exact line each, copies counted by folded letter prefix.
- **Lib names**: predicates ending `form` (`pathform` lib:203, `globform` build-loop.sh:333); noun-phrase readers that set globals (`brief_fields`, `main_entry`, `main_file`, `import_readers`, `import_home`); reason globals ending `_WHY` (`FILE_WHY`, `TRUTH_WHY`, `FLOOR_WHY`); --settings output globals `<KEY>_LINE` (`POLICY_LINE`, `NEVER_LINE`, `CONSTRAINTS_LINE`).
- **Walk-failure reporting**: the floor says `the default branch's instruction files could not be walked for @ imports` (lib:1420); --check-fix says `the instruction-file import walk failed, so an import of it cannot be ruled out; file it instead` (dev-cycle.sh:185).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `readers N-roots M-homes set\|none\|malformed: WHY` | CLI output line | `never GLOB... set\|none\|malformed`, `constraints ok N-hard M-soft`, `slots N set\|default` | `scripts/build-loop.sh:15-41` | Consistent — value-then-status like policy/slots/never, counts as `N-roots` like constraints' `N-hard`; the value is dropped for none/malformed as never's is. Explicit `none` differs (F2) |
| `Reader roots:` | settings key | `Build-loop policy:`, `Build-loop slots:`, `Self-merge never:` | `docs/dev-cycle.md:12-21`, `scripts/build-loop.sh:349-401` | Consistent — two-word subject/attribute key, one exact line, same copy rule and next-line rule as `Self-merge never:` |
| `Reader homes:` | settings key | as above | as above | Consistent. Two keys instead of the one line in the plan's parent bullet: the plan's own U2b3b1 bullet (plan:301) settles on two keys ("so a path never needs a tag"), so this is not a deviation |
| `reader_settings` | lib function | `read_settings` (build-loop.sh:349), `brief_fields`, `import_readers` | `scripts/build-loop.sh:349`, `scripts/lib/dev-cycle-read.sh:376,1015` | Minor — noun-phrase style matches, but it differs from build-loop.sh's `read_settings` by two letters while reading the same file with the same awk (F4) |
| `readerform` | lib predicate | `pathform`, `globform` | `scripts/lib/dev-cycle-read.sh:203`, `scripts/build-loop.sh:333` | Consistent — `<thing>form` predicate, same component loop |
| `main_file` (moved) | lib function | `main_entry`, `entry_why` | `scripts/lib/dev-cycle-read.sh:327,351` | Consistent — behaviour and FILE_OUT/FILE_WHY contract unchanged, only moved |
| `SETTINGS_AWK` (moved) | lib global | `FENCE_AWK`, `CONSTRAINTS_AWK` | `scripts/lib/dev-cycle-read.sh`, `scripts/build-loop.sh` | Consistent; it now has two keys build-loop.sh's read_settings ignores, which is harmless |
| `READERS_LINE` | lib global (output) | `POLICY_LINE`, `NEVER_LINE`, `CONSTRAINTS_LINE` | `scripts/build-loop.sh:347` | Consistent — `<label>_LINE` named after the line's first word (`readers`). It is the only `_LINE` global that lives in the lib, which the SC2034 comment at lib:601 notes |
| `IMPORT_READER_WHY` | lib global (input to import_readers) | `IMPORT_READER_ROOTS`, `IMPORT_READER_HOMES`, `FILE_WHY`, `TRUTH_WHY` | `scripts/lib/dev-cycle-read.sh:1005-1012` | Consistent — `IMPORT_READER_` prefix plus `_WHY` suffix; cleared on source like its siblings (lib:600) |

## Findings

#### F1. A malformed reader setting reaches the floor and --check-fix as a generic walk failure that does not name its cause

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:1420`, `scripts/dev-cycle.sh:185` (cause set at `scripts/lib/dev-cycle-read.sh:634-636`)
**Move:** 4 (error consistency)
**Confidence:** High
**Legibility-target:** the operator reading a floor refusal or a --check-fix skip line

Evidence: `if [[ "$TRUTH_WHY" == walk ]]; then FLOOR_WHY="the default branch's instruction files could not be walked for @ imports"` (lib:1420) and `echo "skip $a: the instruction-file import walk failed, so an import of it cannot be ruled out; file it instead"` (dev-cycle.sh:185). IMPORT_READER_WHY is read only by import_readers (`[[ -n "${ROOT_REAL:-}" && -z "$IMPORT_READER_WHY" ]] || return 1`, lib:1025) and printed only by `build-loop.sh --settings`.

Before this unit a walk failure meant a registry, parser or size-bound failure inside the walk. Now a settings line someone edits in docs/dev-cycle.md makes the floor refuse every path and --check-fix skip every file, with the same text as those internal failures. dev-cycle.sh has no --settings mode, so a dev-cycle run sees only "the import walk failed". Elsewhere a settings failure names its cause where it takes effect: the policy line says "there is no valid Self-merge never: line ..., so self-merge is off" (build-loop.sh:395), and main_file's FILE_WHY reaches the skip lines.

**Recommendation:** When IMPORT_READER_WHY is set, add it, or a pointer to `build-loop.sh --settings`'s readers line, to the walk-failure text in both places. For example, "... could not be walked for @ imports (the reader settings are malformed: WHY)".

#### F2. An explicit `none` prints `set` on the readers line but `none` on the never line

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:639-640`; header `scripts/build-loop.sh:50-51`
**Move:** 7 (asymmetry)
**Confidence:** High
**Legibility-target:** the orchestrator or user reading --settings output

Precedent: `never none: line N of docs/dev-cycle.md on the default branch lists none` for an explicit `Self-merge never: none`, used in `scripts/build-loop.sh:387`

Evidence (probe, `Reader roots: none` and `Reader homes: none` on main): `readers 0-roots 0-homes set: docs/dev-cycle.md on the default branch`. The header says `none: no file or no such line.` In the never line, `none` covers both no line and an explicit `none`. In the readers line it covers only no line, so `...: none`, which the header and dev-cycle.md:30 offer as a valid form, prints `set` with zero counts. The behaviour matches the header, so nothing breaks. But one status word now means different things on adjacent lines.

**Recommendation:** Print `readers none: line N ... lists none` when no path is set and at least one line exists. Otherwise, say in the header that an explicit `none` prints `0-roots 0-homes set`.

#### F3. A file that is not read gives a WHY with two "so" clauses in a row

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:609,636`
**Move:** 4 (error message consistency and tone)
**Confidence:** High
**Legibility-target:** the user reading the readers line

Evidence (probe, and test/scripts/build-loop-read.bats:526): `readers malformed: the code fence opened at line 3 of docs/dev-cycle.md is never closed, so the file is not read, so both import walks fail`. FILE_WHY already ends in a consequence clause (`..., so the file is not read`, lib:551-552), and reader_settings adds a second one. The never line passes FILE_WHY through with no suffix (`never malformed: $why`, build-loop.sh:358). The consequence suffix appears on every malformed readers line, which is fine on its own, but it reads badly after FILE_WHY.

**Recommendation:** Join with "; " or "(both import walks fail)", or skip the suffix when FILE_WHY is the cause.

#### F4. `reader_settings` (lib) and `read_settings` (build-loop.sh) differ by two letters and read the same file

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:602`, `scripts/build-loop.sh:349,305,736-737`
**Move:** 2 (naming)
**Confidence:** Medium
**Legibility-target:** a maintainer of build-loop.sh

Precedent: noun-phrase setters that name what they produce (`brief_fields`, `main_entry`, `import_readers`, `import_home`) used in `scripts/lib/dev-cycle-read.sh:327,376,971,1015`; and `read_settings` already used in `scripts/build-loop.sh:349`

Evidence: build-loop.sh calls `reader_settings` at line 305 and `read_settings` at line 737 (`read_settings` then `printf '%s\n' ... "$READERS_LINE"`). Both run `main_file docs/dev-cycle.md "$SETTINGS_AWK"`. The name follows the lib's noun-phrase style, but a reader skimming build-loop.sh sees two near-identical calls and cannot tell which one sets READERS_LINE. Someone who drops the line-305 call as a duplicate of line 737 would leave the walks with no host readers, and nothing would fail.

**Recommendation:** Rename to something distinct from read_settings, such as `reader_lists` or `import_reader_settings` (the second matches the `IMPORT_READER_*` globals it sets). Or keep the name and add a one-line comment at build-loop.sh:737 that READERS_LINE comes from the earlier reader_settings call.

#### F5. Two docs drifted from the new behaviour: the plan's --settings summary and dev-cycle.md's "followed by a blank line"

**Severity:** Informational
**Location:** `docs/working/plan-build-loop-handoff.md:204` (not in the diff); `docs/dev-cycle.md:32-33`
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** a reader of the plan or of docs/dev-cycle.md

Evidence: plan:204 still lists four lines: `` `--settings` → from main's commit: `policy ...`, `slots ...`, `never ...` ..., and `constraints ...` ``, with no readers line. Plan:297 still says "A `Reader roots:` settings line ... supplies the host alias and the host HOME" (one key), and plan:301 supersedes it. docs/dev-cycle.md:32-33 says "Each is one line of absolute paths separated by single spaces (or `none`), followed by a blank line". The code also accepts the end of the file, and also fails both walks on a file FENCE_AWK refuses, which this paragraph does not mention (the fact-check rated it Mostly accurate). The build-loop.sh header (lines 43-52) is accurate.

**Recommendation:** Add the readers line to plan:204 at the next plan edit, and change dev-cycle.md:33 to "followed by a blank line or the end of the file".

#### F6. The readers line prints counts, not paths, unlike the never line

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:640`
**Move:** 7 (asymmetry)
**Confidence:** Medium
**Legibility-target:** the user checking which host paths are modeled

Precedent: `never $v set: line N ...` prints the validated glob list, used in `scripts/build-loop.sh:388`

Evidence: `READERS_LINE="readers $nr-roots $nh-homes set: $f on the default branch"`. The test name at build-loop-read.bats:493 ("any other form is malformed and never echoed") shows that leaving malformed values out is deliberate, and it matches never's malformed lines. Values that passed readerform are NAMECHARS-only, though, so echoing them is as safe as echoing never's globs. With counts only, `--settings` cannot confirm which host path is modeled. The set WHY also leaves out the line numbers that policy/slots/never give, as constraints' does.

**Recommendation:** Optional: no change, or print the validated paths after the counts. Either way, record it so the convention is chosen on purpose.

## What Looks Good

- The fifth line keeps the established `KEYWORD VALUE STATUS: WHY` shape and the `set|none|malformed` vocabulary of the never line. Its counts use constraints' `N-hard` form (`N-roots M-homes`).
- The keys reuse `Self-merge never:`'s full grammar: exact line, single spaces, next-line rule, letter-prefix copy counting through the shared SETTINGS_AWK. The malformed WHY phrases are word for word the never line's ("is not exactly \"KEY PATH ...\" with single spaces", "lists entry I twice", "more than one line starts ...", "is followed by a non-blank line outside a fence (it may continue the list)").
- `readerform` copies `globform`'s component loop and is documented next to it. `IMPORT_READER_WHY` follows both the `IMPORT_READER_*` input family and the `*_WHY` reason convention, and it is cleared on source like its siblings, so contract item 9's "never from the environment" also covers it.
- Contract item 9 was rewritten from "set these globals" to "call reader_settings", and both callers follow it (build-loop.sh:305, dev-cycle.sh:192). No other consumer parses `--settings` (rg over skills/, workflows/ and docs/ found none), so the added fifth line breaks nothing.
- `main_file`'s move keeps its FILE_OUT/FILE_WHY contract.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | Malformed readers reach the floor/--check-fix as a generic walk failure | Minor | `scripts/lib/dev-cycle-read.sh:1420`, `scripts/dev-cycle.sh:185` | High |
| F2 | Explicit `none` prints `set` (readers) vs `none` (never) | Minor | `scripts/lib/dev-cycle-read.sh:639-640` | High |
| F3 | ", so the file is not read, so both import walks fail" | Minor | `scripts/lib/dev-cycle-read.sh:609,636` | High |
| F4 | `reader_settings` vs `read_settings` near-homonym on the same file | Minor | `scripts/lib/dev-cycle-read.sh:602`, `scripts/build-loop.sh:305,349` | Medium |
| F5 | Plan:204 lists four --settings lines; dev-cycle.md:33 omits "or the end" | Informational | `docs/working/plan-build-loop-handoff.md:204`, `docs/dev-cycle.md:32-33` | High |
| F6 | Readers line prints counts, never line prints values | Informational | `scripts/lib/dev-cycle-read.sh:640` | Medium |

## Overall Assessment

The new surface fits the codebase's conventions. The fifth --settings line, the two keys, and the new lib names and globals follow the never line's grammar and the lib's naming. The two-key choice is the plan's own (plan:301). Nothing breaks: no consumer parses --settings by line count, and contract item 9's change is applied at both callers. Every finding is fixable in place. The one with real consumer impact is F1: a settings typo now looks the same as an internal walk failure wherever it takes effect, and dev-cycle.sh offers no way to see the cause. F2 and F3 are wording and symmetry nits, and F4 is a maintainability nit.

## Goal-Alignment Note

The user goal is to land U2b3b1 after a clean review-fix loop. None of these findings is red or blocks landing. F1-F4 are text or naming fixes of a few lines each, with no change to fail-closed behaviour. F5 and F6 can go to the override log or be left for a later plan edit. The review stayed in its brief: no item deferred to U2b3b2 (H5, H2, C1, G9, outside starts) is filed here.
