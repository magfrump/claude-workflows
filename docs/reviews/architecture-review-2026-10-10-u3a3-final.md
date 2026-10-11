Commit: 01a2935f

# Architecture Review — feat/build-loop-u3a3 (final confirming pass)

**Scope:** `git diff main...HEAD` (full branch, 4 commits: 18f32952, a7a4f784, e25a6e89, 01a2935f). The files reviewed are `scripts/build-loop.sh`, `scripts/dev-cycle.sh` and `scripts/lib/dev-cycle-read.sh`. The tests (`test/scripts/build-loop-merge.bats`, `build-loop-check.bats`) were read as evidence only.
**Date:** 2026-10-10
**Based on:** `docs/reviews/code-fact-check-report-u3a3-final.md` (Commit: 01a2935f, k=3). It found no behavioral Incorrect. It found 1 Incorrect test-helper comment, 1 Stale comment and 4 Mostly accurate.

**Scope check:** in scope. The diff extends a public CLI (`--merge ... --approved Q-NNN`) and adds a lib side value (`ANSWER_HEADING`). It changes a lib data contract: `FLOOR_WHY` becomes a word, `floor_why` is new, `TRUTH_WHERE` is new, and `IMPORTED_WHY` is new. It also widens a shared constant (`GATE_CODE`) and threads one authority value (`AUTH`) through check_line, approval and land.

**Settled rows not re-raised:** the rubric's C1, C6, C8, C9, C10, C12, C13, C16 and A1/A4 (override-log rows 2026-10-10 `feat/build-loop-u3a3`), plus rows 524 and 612/613 and the Q-103 residuals. I checked each of these for regression and found none.

**Trust-boundary cross-reference:** the newest security review is `docs/reviews/security-review-2026-10-10-u3a3-i2.md` (Commit: `e25a6e89`; it predates 01a2935f, so its boundaries may be stale). Its map lists B1 to B5. B1/B3 cover GATE_CODE → VERDICT[gate] → approval → land. B2 covers check_answer → ANSWER_HEADING → approval. B4 covers floor → floor_why → srules. 01a2935f changed only comments and tests on those paths, so the map still holds. No finding below recommends moving a crossing.

## Iteration-2 findings: status

| i2 finding | Rubric row | Status at 01a2935f | Evidence |
|---|---|---|---|
| F1: GATE_CODE carries two policies; the first comment line gave only the D5/D6 reason; the floor side was unpinned | C14 | **Resolved** | `scripts/lib/dev-cycle-read.sh:1918-1924`: "The scripts because main's copy runs the next merge (plan D6, D5 item 3); skills/dev-cycle/ because it carries the D6 snippet that copies and runs the gate (plan D4, F52), though sessions load the skill only from a release, so here the floor is stricter than D5. One list for floor and build-loop.sh's --approved ... build-loop.sh's header repeats it." The commit message reports that T10 now refuses `skills/dev-cycle/references/x.md` and `Skills/Dev-Cycle/x.sh` and passes `skills/dev-cycle-x/a.md`. The plan D5 note is still due at merge (C11). |
| F2: the header's gate list was a hand-kept copy | C15 | **Resolved** | `scripts/build-loop.sh:232`: "is the gate's own code (the lib's GATE_CODE:". Now each copy points at the other. |

## Dependency Map

- `scripts/build-loop.sh` → `scripts/lib/dev-cycle-read.sh`, and `scripts/dev-cycle.sh` → the same lib. The direction is unchanged and correct, and no lib function reads a build-loop or dev-cycle global. The new lib outputs are the words `FLOOR_WHY` and `IMPORTED_WHY` and the sentences `TRUTH_WHERE` and `ANSWER_HEADING`. The lib produces all four, and the scripts only consume them.
- **Authority:** it has one assignment (`build-loop.sh:1216`, `AUTH=self-merge; [[ -z "$APPROVED" ]] || AUTH=approved`). check_line reads it as a global to choose the rules (`sm`). The merge arm reads it to choose policy refusal or approval. land receives it as `$1`, and that one key drives the message, the reflog and the trailer.
- **Gate bit:** `GATE_CODE` (lib) → check_line (`build-loop.sh:1049`, every run) → `VERDICT[gate]` → approval's slug. The same constant feeds the lib's floor (`dev-cycle-read.sh:1957`, self-merge S rules only, through srules).
- **Answer:** the lib's check_answer → `ANSWER_AWK` (now prints a heading line in the single-entry case) → `ANSWER_HEADING` → build-loop's approval only. `dev-cycle.sh --check-answer` prints check_answer's stdout, and its shape is unchanged (`echo "$hit $a"`).
- **Walk wording:** truthwalk sets `TRUTH_WHERE` through walk_why for both walks. floor_why (`walk`) and dev-cycle.sh check_fix both read it, so check_fix no longer composes the reader-settings sentence itself.

## Findings

#### F1. ANSWER_AWK's output contract changed, but only its consumer documents the new shape

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1991-1994` (producer comment), `:2066` (END block), `:2105` (consumer split)
**Move:** 3 (module boundary), 7 (coupling surface)
**Confidence:** High
**Legibility-target:** for-author

Evidence (the producer's comment, unchanged):
```
# The keep-or-drop answer rule, for one entry of a questions file. Prints keep,
# drop, done, open, unrecognized, dup (the heading appears more than once),
# "odd N WHY", "unbalanced N" or "quoted N" (the file cannot be trusted; N is
# the line, WHY the oddwhy reason), or nothing when the file has no such entry.
```
The code it describes now prints more than that:
```
+  else if (count) { print (!answered ? "open" : done ? result : "unrecognized"); print head }
...
+    hit="${r%%$'\n'*}"; head="${r#*$'\n'}"; where="$f"
```
ANSWER_AWK is a lib-level constant, and `test/scripts/dev-cycle.bats:1114` names it as part of the lib's surface. Its output used to be one word. It is now a word plus, in the result cases only, a second line holding the heading. That shape is documented at check_answer, the only consumer, and not at the producer. Fact-check Claim 2 rates the comment Stale, and this finding takes that verdict as given. The structural cost is small but real. A second reader of ANSWER_AWK would trust the producer comment and compare `r` against one word. A future edit to the result cases (for example, a new answer word) could drop or misplace the second line without any comment flagging the coupling to check_answer's `${r%%$'\n'*}` split. This is the same kind of problem as i1's A2 (the lib header's capture rule against a side value), one level down.

**Recommendation:** Add one clause to the producer comment: "...; after a result word (open, keep, drop, done, unrecognized) a second line holds the entry's heading after `### `, which check_answer splits off." No code change.

#### F2. check_fix's tree-walk refusal now gets its wording from the lib, and the new no-reader-reason branch is unpinned

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:186`; `scripts/lib/dev-cycle-read.sh:1637`, `:1898`, `:820-821`
**Move:** 2 (responsibility boundaries)
**Confidence:** Medium
**Legibility-target:** for-author

Evidence:
```
-    if [[ "$TRUTH_WHY" == walk && -n "$IMPORT_READER_WHY" ]]; then echo "skip $a: ... the reader settings of docs/dev-cycle.md cannot be used: $IMPORT_READER_WHY; file it instead"
-    elif [[ "$TRUTH_WHY" == walk ]]; then echo "skip $a: the instruction-file import walk failed, so an import of it cannot be ruled out; file it instead"
+    if [[ "$TRUTH_WHY" == walk ]]; then echo "skip $a: the instruction-file import walk failed, so an import of it cannot be ruled out${TRUTH_WHERE:+: $TRUTH_WHERE}; file it instead"
```
```
    readers) [[ -n "$IMPORT_READER_WHY" ]] && echo "the reader settings of docs/dev-cycle.md cannot be used: $IMPORT_READER_WHY" \
      || echo "the worktree registry could not be read, or a reader root, home or CLAUDE_CONFIG_DIR is not a usable absolute path" ;;
```
This is the consolidation that rows 630/634 asked for: the lib now owns all walk wording, and the caller keeps only its own frame. That is the right direction. One consequence is a behavior change at the boundary. When import_readers fails with `IMPORT_READER_WHY` empty, check_fix used to print the bare sentence. It now appends walk_why's registry/root sentence. That is still fail-closed, and the fact-check escalated it (r1) as untested. The tests pin the reader-settings branch (`dev-cycle.bats:1417`) and the bare prefix (`:1057`), but not the new branch. If the lib's `readers` wording or IMPORTED_WHY's rule changes, check_fix's output changes with no dev-cycle test noticing. That cost is acceptable now that the wording is shared, but it should be pinned once.

**Recommendation:** Optional: add one dev-cycle.bats case where import_readers fails without a reader-settings reason (for example, an unreadable worktree registry) and assert the `: the worktree registry could not be read` suffix. Or record the gap as a row with trigger U4.

## What Looks Good

- **One authority, three consumers, no disagreement possible.** `AUTH` is assigned once, from parsed arguments, before gate_start. check_line's `sm`, the merge arm's refusal choice and land's message, reflog and trailer all derive from it. Row 653 is discharged cleanly, and `--check` (AUTH empty) keeps its old behavior, because `sm` is set exactly when `pol == self-merge` there.
- **The rules are chosen by authority, not by policy.** `--approved` drops the S rules and the checkout rule by clearing `sm`. It adds no parallel code path, so the N rules, the verdict lines and the landing machinery are shared unchanged between the two authorities.
- **The gate bit is computed in check_line and not borrowed from floor.** GATE_CODE is tested independently of the floor's rule order. The floor comment points callers to GATE_CODE rather than to `FLOOR_WHY == gate` (i1 F4), which avoids a coupling to floor internals that would have been wrong for `skills/dev-cycle/SKILL.md` (floor answers `instr` there).
- **FLOOR_WHY as a word plus floor_why.** This separates decision from wording, as walk_why and entry_why already did, so the lib's three reason families now follow one pattern. The `*)` fallback in floor_why keeps an unknown word from producing an empty DENY.
- **TRUTH_WHERE.** The lib now owns the walk-failure sentence for both walks, so floor_why and check_fix no longer each rebuild it. The temporal coupling (word it before the next truthwalk) is documented at floor_why, and the only caller (srules) words it immediately.
- **The ANSWER_HEADING side channel is part of the lib's documented caller contract.** The header carries the exception to the `$(...)` rule, and approval follows it. check_answer resets the value on entry, so a stale heading cannot outlive a call.
- **One GATE_CODE list.** Both its reasons are stated, and the header points at it. This is the fail-safe choice, and it keeps B1/B3 and B4 aligned.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | ANSWER_AWK's producer comment still describes one-word output; the two-line shape is documented only at check_answer | Informational | `scripts/lib/dev-cycle-read.sh:1991-1994` | High |
| 2 | check_fix's walk refusal now uses lib wording; the new no-reader-reason suffix is untested | Informational | `scripts/dev-cycle.sh:186` | Medium |

No Structural, Coupling or Minor findings.

## Overall Assessment

The branch keeps the system's structure sound and improves it in places. One authority value replaces policy-keyed branching across check_line, the merge arm and land. The floor's reasons follow the lib's existing word-plus-wording pattern. The walk-failure wording moves into the lib that owns the walks. The dependency direction (scripts → lib) is unchanged, and the lib still reads no caller global. Both iteration-2 findings are resolved at 01a2935f, and no settled row has regressed. The two remaining notes are documentation and test-pinning at the lib/caller boundary, and neither blocks the merge. The most useful of the two is F1, because ANSWER_AWK's producer comment is the one place a future reader would look for its output shape. The plan D5 note (rubric C11) remains due in the merge message.

## Goal-Alignment Note

Success criterion (verbatim): "a report saved to /workspace/.claude/wt-build-loop-u3a3/docs/reviews/architecture-review-2026-10-10-u3a3-final.md, structured per the architecture-review skill (Structural / Coupling / Minor / Informational), with `Commit: 01a2935f` at the top."

This report is saved at that path and opens with `Commit: 01a2935f`. It follows the skill's structure: header, Dependency Map, Findings with severity tiers, What Looks Good, Summary Table and Overall Assessment, plus an iteration-2 status table. It reviews the full branch. Settled rubric and override rows were checked for regression and not re-raised. No probes were run: this is a static review on top of the k=3 fact-check's executed evidence. Nothing was committed.
