Commit: 722c2e10

# API Consistency Review — feat/build-loop-u4a, iteration 1

**Scope:** `git diff main...HEAD` (722c2e10): `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-orchestrator.bats`; public surface = the `--land-cycle` mode, its usage text, `--cycle-diff`'s changed refusals, the plan's "Script interface" section
**Date:** 2026-10-13
**Based on:** `docs/reviews/code-fact-check-report-2026-10-13-u4a-i1.md` (Mostly-accurate items reused: Claim 3, 9, 13, 24b)

## Baseline Conventions

Surveyed in `scripts/build-loop.sh` (header lines 6-470, argument parser 510-546, dispatch 1985-2045) and `docs/working/plan-build-loop-handoff.md` ("Script interface", lines 201-245):

- **Mode names:** read modes are nouns (`--settings`, `--status`, `--marker`, `--state`, `--main-log`, `--cycle-diff`); acting modes are verbs (`--check`, `--merge`, `--start`, `--prompt`).
- **Output lines:** a leading keyword, then space-separated fields: `ok BRIEF TIP TREE` (--check), `merged BRIEF TIP TREE NEW` (--merge), `ok BRIEF BRANCH DIR` / `dispatched N` (--start), `main MAIN N` (--main-log). Refusals are `refuse SUBJECT: WHY`, where SUBJECT is a brief, `state WHAT`, `main-log`, `HEAD`, `index` or a path. The header defines each field of a success line.
- **Exit codes:** 0 success, 2 any refusal, 1 usage error or a fatal environment error (stderr only).
- **Commit ids:** full 40- or 64-hex lower-case only, as a usage check (`--main-log`, `--expect`).
- **`--expect SHA`:** on `--check` and `--merge` it binds the brief branch's TIP ("--expect still binds the tip", header :372; ":394 --expect binds the full tip").
- **Usage messages:** `--merge`/`--check` name the specific fault (`--expect takes one commit id, given once`, `--expect takes a full 40- or 64-hex commit id`); `--cycle-diff` uses one collapsed message.
- **Plan:** each built mode has a bullet in "Script interface" (U3c added `--cycle-diff` at :209), or an "As built" note in its unit entry that supersedes it.
- **Lib predicates:** `isbrief`, `isclosed`, `anybrief` (`scripts/lib/dev-cycle-read.sh:240-242`).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `--land-cycle` | CLI mode | `--merge`, `--cycle-diff`, `--check` | `scripts/build-loop.sh:6-16` | Consistent — an acting mode, verb first; shares `cycle` with its companion `--cycle-diff` |
| `--expect SHA` (under `--land-cycle`) | CLI flag | `--check ... --expect SHA`, `--merge ... --expect SHA` | `scripts/build-loop.sh:13-14, 370-372, 394` | Inconsistent — same flag, different referent (main's commit, not the branch tip): Finding 1 |
| `--answered Q-NNN` (under `--land-cycle`) | CLI flag | `--cycle-diff --answered`, `--merge --approved Q-NNN` | `scripts/build-loop.sh:11, 520-526` | Consistent — same grammar and meaning as `--cycle-diff`'s, so the caller passes the same IDs to both |
| `landed B HEAD TREE NEW` | output line | `merged BRIEF TIP TREE NEW`, `ok BRIEF TIP TREE` | `scripts/build-loop.sh:269, 374` | Consistent shape (past-tense verb of the mode, subject, tip, tree, new); fields under-documented: Finding 4 |
| `refuse HEAD: WHY` | output line | `--cycle-diff`'s `refuse HEAD:`, `--merge`'s `refuse BRIEF: WHY` | `scripts/build-loop.sh:188-190, 1854-1856` | Consistent — HEAD is the subject `--cycle-diff` already uses for the orchestrator's branch |
| `refuse PATH: it is deleted` | refusal text | `refuse PATH: edited other than by appending`, `... a side is not a regular file` | `scripts/build-loop.sh:1891-1896` | Consistent — neutral wording fits both modes; but siblings were not reworded: Finding 2 |
| reflog `build-loop: cycle land of B` | reflog text | `build-loop: self-merge of STEM`, `build-loop: approved merge of STEM` | `scripts/build-loop.sh:376-382, 1463-1465` | Consistent shape; undocumented: Finding 4 |
| `land_cycle`, `cycle_rules`, `chore_record`, `asked` | internal functions | `cycle_diff`, `main_log`, `check_line`, `log_class` | `scripts/build-loop.sh` | Consistent — snake_case, noun or noun_noun |
| `isrecord` | lib predicate | `isbrief`, `isclosed`, `anybrief` | `scripts/lib/dev-cycle-read.sh:240-242` | Consistent — `is` + noun, regex test on a repo path |
| authority `cycle` (land's $1) | internal enum | `self-merge`, `approved` | `scripts/build-loop.sh:1463-1465, 2023` | Consistent |

## Findings

#### 1. `--expect` means main's commit under `--land-cycle` but the branch tip under `--check`/`--merge`

**Severity:** Inconsistent
**Location:** `scripts/build-loop.sh:12-14`, `:223-229`, `:520-529`, `:1954`
**Move:** 2 (naming against the grain), 7 (asymmetry)
**Confidence:** High
**Legibility-target:** for-consumer (U4b's SKILL.md author and the orchestrator that calls both modes)

Precedent: `--expect SHA` binds the brief branch's tip used in `scripts/build-loop.sh:370-372` ("--check's lines for BRIEF at --expect's tip ... --expect still binds the tip") and `:394` ("--expect binds the full tip, so the caller passes the full TIP")

Evidence (verbatim): header `:227` "and --expect the default branch's commit (the one --cycle-diff checked)"; `:1954` `[[ "$EXPECT" == "$MAIN_SHA" ]] || { echo "refuse HEAD: the default branch is at $MAIN_SHA, not the expected $EXPECT; ..."`. In `--merge` the default branch's commit is read at run time and never named by the caller, and the tip is pinned; in `--land-cycle` it is the reverse: main is pinned by `--expect` and the tip (HEAD's commit) is read at run time. The usage line prints both as `--expect SHA` with nothing to tell them apart. A caller writing `--land-cycle --expect <chore tip>` by analogy with `--merge` fails loudly ("the default branch is at X, not the expected Y"), so the slip is not unsafe, but the refusal tells the caller to "merge it into HEAD, run --cycle-diff again", which sends them the wrong way.

**Recommendation:** Name the main-binding flag after what it binds (e.g. `--main SHA` or `--expect-main SHA`), or keep `--expect` and make the usage line and the usage error say `--expect MAIN` (the header already writes `--expect MAIN_SHA` in the plan entry, `plan-build-loop-handoff.md:338`). Either way, U4b's SKILL.md should state which commit each mode's `--expect` takes.

#### 2. Under `--land-cycle`, shared `cycle_rules` refusals still name "index"

**Severity:** Minor
**Location:** `scripts/build-loop.sh:1915`, `:1931`; header `:240`
**Move:** 3 (consumer contract), 4 (error consistency)
**Confidence:** High (static: both lines are in `cycle_rules`, which `land_cycle` calls at `:1972` with RAW_* from the merge's diff-tree)
**Legibility-target:** for-author

Precedent: the commit itself rewords `--cycle-diff`'s refusal for both modes ("A deleted roadmap now reads "it is deleted" (the land judges a merge, not the index)"), used in `scripts/build-loop.sh:1893`

Evidence (verbatim): `:1915` `{ echo "refuse index: the questions files could not be listed"; return 1; }`; `:1931` `k=base; [[ "$p" == o ]] || k=index; ... echo "refuse $f: --check-answer refuses its $k copy whole ($md)"`. Under `--land-cycle` the "index copy" is the merge's copy, and the subject `index` is not a file, while the header (`:240`) says the land prints "--cycle-diff's (PATH a file)". This overlaps fact-check Claim 9. A reader of a land refusal is told to look at the index, which the land never reads (it refuses staged changes outright).

**Recommendation:** Finish the rewording the commit started: name the side neutrally (e.g. "its new copy" / "the merged copy" or a mode-set word), give the listing failure a subject that is valid in both modes, and fix the header's "(PATH a file)".

#### 3. `--land-cycle`'s header refusal list omits its read-failure refusals

**Severity:** Minor
**Location:** `scripts/build-loop.sh:240-246`
**Move:** 3 (documentation drift)
**Confidence:** High (fact-check Claim 9, static)
**Legibility-target:** for-author

Evidence (verbatim): the list reads "Not on such a branch; the default branch moved ...; staged changes; nothing the default branch lacks; a conflict; an object that does not hash or has two copies; no such record; or --merge's own refusals of the move." The code also prints "refuse HEAD: its commit could not be read" (`:1955`), "its merge into the default branch could not be computed" (`:1965`), "the paths its merge changes could not be listed" (`:1971`), plus the `refuse index:` line above. `--merge`'s and `--start`'s header lists name their read failures ("cannot be read", "could not be read, listed or created"), so this is the established level of detail.

**Recommendation:** Add "or a read that fails" (as `--marker`'s list ends, `:120-121`) and the `index` subject.

#### 4. The `landed` line's fields and the land's reflog are less documented than `merged`'s

**Severity:** Minor
**Location:** `scripts/build-loop.sh:237-239`, `:1948`, `:1463-1465`
**Move:** 2, 3
**Confidence:** High
**Legibility-target:** for-author

Precedent: `merged BRIEF TIP TREE NEW` is followed by a definition of NEW, TREE, TIP, the message, the trailer and the reflog entry, used in `scripts/build-loop.sh:374-382`

Evidence (verbatim): header `:238-239` "landed B HEAD TREE NEW / NEW: the merge commit, now the default branch's." (B, HEAD and TREE are left to inference), while the function comment `:1948` says "landed BRANCH HEAD TREE NEW". The reflog message land writes, `msg="build-loop: $what of ${VERDICT[stem]}"` with `what="cycle land"` and stem = the branch (`:1465`, `:1974`), so "build-loop: cycle land of chore/dev-cycle-..." (plus git's ": Fast-forward" in W), appears nowhere in the header, though `--merge` documents its own.

**Recommendation:** One placeholder name in both places (B), a line defining HEAD (the chore branch's commit, parent 2) and TREE (the merge's tree), and the reflog wording.

#### 5. The plan's "Script interface" section has no `--land-cycle` bullet, and U4a's planned `--check` `entry BRIEF HEADING` line is absent

**Severity:** Minor
**Location:** `docs/working/plan-build-loop-handoff.md:201-210`, `:338`
**Move:** 3 (documentation drift)
**Confidence:** Medium (the plan may be updated at merge time, as earlier units' "As built" notes were)
**Legibility-target:** for-author

Precedent: U3c added its mode to the interface list, used in `docs/working/plan-build-loop-handoff.md:209` ("`--cycle-diff [--answered Q-…]` → `ok`, or `refuse PATH: why` (exit 2); ... (U3c)")

Evidence (verbatim): the U4a entry (`:338`) promises "`--check` prints `entry BRIEF HEADING` after a verdict that path lines follow (row 674), from approval's own slug code"; `rg -n "entry BRIEF|echo \"entry" scripts/build-loop.sh` finds nothing, and neither the commit message nor the plan says it moved. D13's "Before the chore commit" (`:104`) also still describes only `--cycle-diff` before the land.

**Recommendation:** Add the `--land-cycle` bullet (output, exit 2, what `--expect` binds) or a U4a "As built" note, and either build the `entry` line or record where it moved (U4b/U4c or a later iteration).

#### 6. `--land-cycle` collapses its argument errors into one usage message

**Severity:** Informational
**Location:** `scripts/build-loop.sh:523-529`
**Move:** 4
**Confidence:** High (executed: probe `/tmp/u4a-api1-*`, removed)
**Legibility-target:** for-author

Precedent: `--merge` names each fault ("--expect takes a full 40- or 64-hex commit id", "--expect takes one commit id, given once"), used in `scripts/build-loop.sh:534-536`; `--cycle-diff` collapses its own (`:525`)

Evidence (probe): `--land-cycle --expect abc`, `--land-cycle --expect A --expect B` and `--land-cycle --expect A --answered` each print "--land-cycle takes --expect SHA (a full commit id), once, and --answered Q-NNN, one ID each", exit 1; `--merge x.md --expect abc` prints "--expect takes a full 40- or 64-hex commit id". The content is complete, and it matches `--cycle-diff`, so this follows the closer sibling.

**Recommendation:** None required; if Finding 1 renames the flag, reword this message with it.

#### 7. `--cycle-diff` gains two refusals (GATE_CODE paths, Asked: lines) for existing callers

**Severity:** Informational
**Location:** `scripts/build-loop.sh:212-220`, `:1878-1884`, `:1902-1905`
**Move:** 3, 6 (subtle narrowing of accepted input)
**Confidence:** High
**Legibility-target:** for-author

Evidence (verbatim): "but for two rules (row 745): a path of the gate's own code (GATE_CODE, compared lower-cased) refuses, and a brief whose first unfenced "Asked:" line ... refuses". This narrows what a previously-`ok` index passes. `rg -n "cycle-diff|land-cycle" skills/ workflows/ docs/dev-cycle.md` finds no caller yet; the orchestrator text arrives in U4b, so nothing breaks. Fact-check Claims 3 and 13 note the rule's free cases (no Asked: on BASE, a new brief, a brief deleted outright with no closed/ copy, and a brief brief_fields reads as malformed), which U4b's text should not describe as covered.

**Recommendation:** U4b's SKILL.md should name both rules and the free cases when it tells the orchestrator what `--cycle-diff` refuses.

## What Looks Good

- `--land-cycle` follows the script's grammar: a verb mode for an action, `landed ...` parallel to `merged ...`, `refuse SUBJECT: WHY` lines, exit 0/2/1, full-hex-only ids, gated by default (`:683`).
- `--answered` keeps exactly `--cycle-diff`'s grammar and meaning, and the land judges with the same `cycle_rules`, so one set of IDs and one set of refusal texts serves both modes.
- The land's commit message is exactly `--main-log`'s chore subject ("Merge branch 'B'"), and `chore_record` is now the one definition both modes use, so writer and reader cannot drift (the U3b2 row-662 pattern applied to chore).
- `isrecord` matches the lib's `is*` predicate family, and `writable` now uses it.
- "it is deleted" removes a mode-specific word from a shared refusal; no consumer parsed the old text (`rg` finds it only in the updated test).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `--expect` binds main under `--land-cycle`, the tip under `--check`/`--merge` | Inconsistent | `scripts/build-loop.sh:227, 520-529, 1954` | High |
| 2 | Shared refusals still say "index" under `--land-cycle`; header's "(PATH a file)" | Minor | `scripts/build-loop.sh:1915, 1931, 240` | High |
| 3 | Header refusal list omits read failures | Minor | `scripts/build-loop.sh:240-246` | High |
| 4 | `landed` fields and reflog under-documented vs `merged` | Minor | `scripts/build-loop.sh:237-239, 1948` | High |
| 5 | Plan "Script interface" lacks `--land-cycle`; planned `entry BRIEF HEADING` absent | Minor | `docs/working/plan-build-loop-handoff.md:201-210, 338` | Medium |
| 6 | One collapsed usage message (matches `--cycle-diff`, not `--merge`) | Informational | `scripts/build-loop.sh:523-529` | High |
| 7 | `--cycle-diff` narrows: two new refusals; U4b must document them | Informational | `scripts/build-loop.sh:212-220` | High |

## Overall Assessment

`--land-cycle` is consistent with the script's established surface: mode naming, output-line shape, refusal grammar, exit codes, id validation and the `--answered` grammar all match their siblings, and sharing `cycle_rules` and `chore_record` keeps the two cycle modes and `--main-log` in step. The one real inconsistency is the reuse of `--expect` for a different commit than `--check`/`--merge` bind; it fails safe but will mislead U4b's caller and should be renamed or spelled out before U4b writes the orchestrator text. The rest are wording and documentation fixes, fixable in place: finishing the "index" rewording in the shared refusals, completing the header's refusal list and `landed` field definitions, and bringing the plan's interface section (and the missing `entry` line) up to date. No existing consumer breaks.

## Goal-Alignment Note

- **Success criterion (verbatim from the brief):** "a markdown report saved at the exact path your own prompt names, structured per your skill."
- **Alignment:** saved at `docs/reviews/api-consistency-review-2026-10-13-u4a-i1.md`, first line `Commit: 722c2e10`, with the skill's sections (Baseline, Name-Pattern Audit, Findings with Severity/Location/Evidence/Confidence/Legibility-target, What Looks Good, Summary Table, Overall Assessment). One probe ran under `/tmp/u4a-api1-*` (usage parsing only, no git writes) and was removed; nothing else in /workspace or the worktree was written.
