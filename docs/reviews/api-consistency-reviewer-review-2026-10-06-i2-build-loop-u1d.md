Commit: cc75db98

# API Consistency Review — feat/build-loop-u1d, iteration 2 (fix commit 6c83af2a)

**Scope:** partial scope (loop pass): `83cdb005..cc75db98` limited to scripts/ and test/, which is the fix commit 6c83af2a. Public surface: `scripts/build-loop.sh --help` (the never-line rule :16-20, the `skip BRIEF: WHY` list :66-74), the help-case comment (:101), the lib's header contract (`scripts/lib/dev-cycle-read.sh:22-25`) and main_entry's `error` contract (:250-261), plus the changed test titles. The rest of the branch is context only.
**Date:** 2026-10-06
**Based on:** docs/reviews/code-fact-check-report-build-loop-u1d.md (k=1 loop pass, `Commit: cc75db98`, 23 claims: 21 Verified, 2 Mostly accurate); iteration 1's api-consistency report (`Commit: 83cdb005`) and rubric rows A3, A4, A7, C1, C7, C8.

## Baseline Conventions

These carry over from iteration 1 and were re-checked against HEAD:

- **Output grammar.** `--status` prints `ok BRIEF ...` or `skip BRIEF: WHY`. Consumers key on the first word. WHY is prose for a human, and no parser reads it. 6c83af2a changes no output string.
- **The help lists every skip cause as one closed "X, Y, ..., or Z" list.** The list is not a precedence order. status_line checks in this order: check_brief, Branch, Dispatched, the two F31 skips, check_branch, then the marker (`build-loop.sh:324-360`). Neither the old help order nor the new one follows it, and neither claims to.
- **The help's copy model is one paragraph** (`build-loop.sh:41-44`): "a line counts as one when its letters alone, case folded, start with the key's ... Markup that adds letters (a task box, a tag) can still hide a copy; only an exact line ever sets a value."
- **Output words for the never precondition.** policy's WHY says "there is no valid Self-merge never: line" (`build-loop-read.bats:114`, pinned by the suite).
- **Lib function contracts list every answer and its causes in one parenthesis.** brief_fields' `error` is "(no default branch found by name, a path pathform refuses, any main_entry answer but blob, ...)" (`lib:288-290`).
- **Help-range comment.** dev-cycle.sh puts a full-line comment above the case: `# The header: from line 2 to the first non-empty line not starting with # (no fixed range to go stale).` (`dev-cycle.sh:111`).
- **Comment width.** Every full-line comment the diff adds or rewraps is 90 columns or fewer (checked with `awk '/^[ \t]*#/ && length>90'` on both scripts; the over-90 full-line comments it reports, at lib:40, :106, :245, :467 and :478, are outside the diff). The one diff line over 90 is the help case's trailing comment (F3).

## Iteration-1 findings: resolved?

| Iter-1 finding | Rubric row | What 6c83af2a did | Verdict |
|---|---|---|---|
| F1: main_entry's `error` cause list omitted pathform | C1 | "a path pathform refuses" is now inside the parenthesis (`lib:254`), with the same words as brief_fields' list. The trailing sentence became "It runs main_by_name and pathform itself, before any read" (fact-check Claim 6 Verified, `route: code-fact-check`) | **Resolved** |
| F3: the skip list could read the marker skip as open-only | A4 | The marker clause moved before ", or, for an open brief only, ..." (`build-loop.sh:69-74`). This is iteration 1's recommended wording, and "only" ends the scope at the sentence's end (Claim 2 Verified, probed for done and open briefs) | **Resolved** |
| F4: an exact line beside a hidden list rescues self-merge only when the count misses the copy | A3 | The rule is rewritten into counted markup (bold, a list marker: a second copy, off) and missed markup (a task box, a fence: ignored) (`build-loop.sh:16-20`) | **Resolved in structure.** Its examples still have the residue in F1 below (Claim 1b Mostly accurate) |
| F5: the two help-range comments used different words | C7 | The words now match dev-cycle.sh:111 up to its parenthetical (Claim 3 Verified) | **Resolved in words.** The placement still differs, and the line grew (F3 below) |
| F6: `-h` untested | A7 | The test loops `-h --help` (mutant noh killed, Claim 14) | **Resolved** for build-loop. The dev-cycle sibling still differs (F4 below) |
| F2: `error` vs callers' "could not be read" | C2 | Deferred to U2 by the rubric | Not in this pass's scope; still deferred |

## Name-Pattern Audit

6c83af2a adds no flags, modes, functions, globals, output keywords or output strings. Its public changes are help prose and comment prose. The only new names are two test titles.

| New / changed name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `build-loop.sh -h and --help print the header from its first line through its last (U1d)` | test title | `--help prints the whole header, through its last line`; `--help prints the whole header, exit codes included` | `test/scripts/dev-cycle.bats:1322`; `test/cc-push.bats:438` | Accurate, but no longer mirrors its dev-cycle sibling (F4) |
| `--status: deferred cases: no open brief, F31's open-only filter, CRLF, an unanchored closed, BRIEF kept, a caller's config pair, a NUL in a brief (U1d)` | test title | `--status: deferred cases: NUL, F31's open-only filter, ...` (the 83cdb005 title it replaces) | `test/scripts/build-loop-read.bats:444` | Consistent: the cases are named in step order (Claim 15) |
| `main_entry answers error for a path pathform refuses (U1d)` | test title | brief_fields' contract wording "a path pathform refuses" | `scripts/lib/dev-cycle-read.sh:288-290` | Consistent: same phrase as the lib's contracts |
| help: "the copy count" | help term | "Copies are found best effort: a line counts as one when ..." | `scripts/build-loop.sh:41-44` | Consistent in meaning. It is used three paragraphs before the paragraph that defines it (noted under F1) |

## Findings

#### F1. The never-line rule's "missed" examples include markup the copy count sees, and "a second copy" assumes the exact line

**Severity:** Minor
**Location:** `scripts/build-loop.sh:17-20`
**Move:** 3 (consumer contract: documentation drift)
**Confidence:** High (fact-check Claim 1b, executed: `[ ]`, `[x]`, `[X]`, and both fence kinds probed)
**Legibility-target:** for-author

Evidence:
```
16: #                 exactly (one trailing CR dropped); else review. Self-merge
17: #                 also needs one exact never line. A never list in markup the
18: #                 copy count sees (bold, a list marker) is a second copy and
19: #                 turns self-merge off; one it misses (a task box, a fence) is
20: #                 ignored, so self-merge rests on the exact line alone.
...
41: #             Copies are found best effort: a line counts as one when its
42: #             letters alone, case folded, start with the key's
43: #             ("buildlooppolicy"). Markup that adds letters (a task box, a tag)
44: #             can still hide a copy; only an exact line ever sets a value.
```

The structure now matches the copy model at :41-44 and the Q-answer it implements ("A hidden extra copy next to an exact line is ignored; the exact line you can see governs", `docs/working/questions-archive.md:1867`). Two precision gaps remain:

- "a task box" is listed as missed. Only a *checked* box (`- [x]`) adds a letter. The fact-check probe of `- [ ] Self-merge never: b/` beside an exact line printed `never malformed: more than one line starts "Self-merge never:" (lines 3 and 5)` and `policy review unset`. An unchecked box therefore behaves like the bold case the same sentence lists as counted. The :43 paragraph is right, because it scopes the claim with "markup that adds letters". The :19 example has no such scope. The error fails closed: an operator gets review, not an unexpected self-merge.
- "is a second copy" is true only when the exact line is present. With the markup copy alone, the never line reads `never malformed: line 3 is not exactly ...` (Claim 1a probe). Self-merge is still off, so the behavior claim holds, but an operator who matches the help's words against the WHY will look for a "more than one line" message that does not come.

"The copy count" is also used here before the paragraph that defines it (:41). That costs a reader little, because the parenthetical examples carry the meaning.

**Recommendation:** Change ":19" to "one it misses (a checked task box, a fence)". Optionally change "is a second copy and turns self-merge off" to "counts as a copy and turns self-merge off". That wording holds with or without the exact line.

#### F2. The help now says "exact never line" where the output's WHY says "valid", and "exact" is the weaker condition

**Severity:** Informational
**Location:** `scripts/build-loop.sh:17`; output pinned at `test/scripts/build-loop-read.bats:114`
**Move:** 7 (asymmetry between help and output wording)
**Confidence:** Medium (the meaning is complete across the help, so this is wording only)
**Legibility-target:** for-author

Evidence:
```
build-loop.sh:17:   #                 also needs one exact never line. A never list in markup the
build-loop-read.bats:114:    no='policy review unset: line 1 reads self-merge, but there is no valid Self-merge never: line ("Self-merge never: none" for an empty list), so self-merge is off'
83cdb005 build-loop.sh:17: #                 also needs a valid never line, so a never list hidden in
```

The help's copy paragraph defines "exact" as the key form (:44, "only an exact line ever sets a value"). A line can be exact in that sense and still malformed, for example when a non-blank line follows it (the `$' \t '` and `'x'` steps at `build-loop-read.bats:420-424`). The old word "valid" matched the WHY and covered both conditions. "Needs" states only a necessary condition, so the sentence is not wrong, and the never paragraph's "Malformed ... turns self-merge off" (:29-30) fills the gap. Only the help-to-output word match is lost.

**Recommendation:** Optional: write "one exact, valid never line", or keep "exact". If you keep it, no other change is needed.

#### F3. The help-range comment now uses dev-cycle.sh's words but stays a trailing comment, and its line grows from 140 to 152 columns

**Severity:** Informational
**Location:** `scripts/build-loop.sh:101`; `scripts/dev-cycle.sh:111-112`
**Move:** 2 (sibling consistency; wording, not a name)
**Confidence:** High
**Legibility-target:** for-author

Evidence:
```
build-loop.sh:101:  -h|--help) sed -n '2,/^[^#]/{/^#/p}' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;  # the header: from line 2 to the first non-empty line not starting with #
dev-cycle.sh:111:    # The header: from line 2 to the first non-empty line not starting with # (no fixed range to go stale).
dev-cycle.sh:112:    -h|--help) sed -n '2,/^[^#]/{/^#/p}' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
```

C7 asked for the same words, and the words now match (Claim 3). This is the only line in the diff over 90 columns: 152, up from 140 at 83cdb005. It is a code line with a trailing comment. Other build-loop.sh code lines already exceed 90 (for example :114 and :138), and no repo rule outside docs/reviews/ states a 90-column limit (`rg -i '90 col|columns or fewer'` finds none). So this is a sibling-shape note, not a width violation. As a full-line comment above the case, like dev-cycle.sh's, it would be 75 columns.

**Recommendation:** Optional: move it to its own line above the case, matching dev-cycle.sh:111 (with or without the parenthetical).

#### F4. The --help test titles have diverged: the build-loop test was corrected, and the dev-cycle sibling still says "the whole header" and runs only `--help`

**Severity:** Informational
**Location:** `test/scripts/dev-cycle.bats:1322-1326` (context, not in this diff); `test/scripts/build-loop-read.bats:436-442`
**Move:** 2 (sibling consistency of test names)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Precedent: `--help prints the whole header, ...` title shape used in `test/scripts/dev-cycle.bats:1322`, `test/cc-push.bats:438`

Evidence:
```
dev-cycle.bats:1322:@test "--help prints the whole header, through its last line" {
dev-cycle.bats:1323:    run --separate-stderr bash "$DC" --help
build-loop-read.bats:436:@test "build-loop.sh -h and --help print the header from its first line through its last (U1d)" {
build-loop-read.bats:437:    for h in -h --help; do
```

Iteration 1 praised the two titles for mirroring each other word for word. A7 then corrected the build-loop title, because "the whole header" overclaims a first-and-last-line check, and added `-h`. The dev-cycle test makes the same first-and-last-line check under the same "whole header" title and still never runs `-h`. The mismatch is now between siblings rather than within one test. Nothing breaks. A reader comparing the two suites will see two shapes for one contract.

**Recommendation:** When dev-cycle.bats is next touched, give its test the same loop and title shape. A one-line override-log note is enough for now; it does not belong in this loop pass.

#### F5. Two sibling comments in the lib still lag the C8 edit: the MAIN declaration names three functions, and the header line is left ragged

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:22-26`; `:244-246` (context, not in this diff)
**Move:** 3 (documentation drift between two statements of one contract)
**Confidence:** High
**Legibility-target:** for-author

Evidence:
```
22: # and SKIP_AT. The caller runs resolve_main once per process (a second call
23: # re-reads main); check_brief, check_branch and check_answer skip every
24: # argument unless it returned 0 with main found by name (main_entry and
25: # brief_fields answer error). check_brief,
26: # check_branch and check_answer answer with one printed line per argument that
...
244: # The default branch, set by resolve_main (below). check_brief, check_branch
245: # and check_answer read its commit, so they answer only when it was found by name, never for the
246: # current branch's fallback or before resolve_main has succeeded.
```

C8 added main_entry and brief_fields to the header sentence, and Claim 5 verified that both answer error without a by-name resolve_main. The comment on the globals that this rule is about (:244-246) still names only the three check_* functions. Its :245 is also 96 columns, which predates this diff. :25 was left at 42 columns because the edit was not re-flowed. The paragraph reads fine, but it no longer looks like the wrap around it.

**Recommendation:** Optional: add "main_entry and brief_fields answer error" to :244-246 in the same words, and re-flow :24-26.

## What Looks Good

- **The skip list (A4) is fixed with the recommended wording.** "for an open brief only" now comes last, so its scope ends with the sentence. Fact-check Claim 2 probed both halves: a done brief hits the marker skip, and only open briefs hit the F31 skips (`route: code-fact-check`). The list still covers every `skip` arm in status_line (:328-357).
- **main_entry's contract (C1) now follows brief_fields' pattern.** Every `error` cause sits in one parenthesis, and "a path pathform refuses" uses the same words as `lib:288-290`. "Before any read" is backed by a GIT_TRACE probe that shows zero git calls for refused paths (Claim 6).
- **The lib header (C8)** states the rule for all five readers of main's commit, consistent with the "Inputs:" line at :31-32.
- **The F31 comment (A5)** now separates the two object failures by their actual exits: corrupt fails closed, missing is not counted (Claim 4, probed).
- **The test titles name what they assert.** The `--status` deferred-cases title lists its cases in step order. The main_entry title drops "before any read", which the test did not check.
- **No output string, flag or exit code changed**, so no consumer can break. The new `--status` step pins the existing "could not be listed" WHY exactly.
- **Width.** Every rewrapped header and comment line is 90 columns or fewer, keeping the U1c re-wrap.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | Never-line rule: "a task box" listed as missed (only a checked box is); "a second copy" assumes the exact line | Minor | `scripts/build-loop.sh:17-20` | High |
| F2 | Help says "exact never line"; output WHY says "valid" | Informational | `scripts/build-loop.sh:17` | Medium |
| F3 | Help-range comment: words match dev-cycle.sh, placement does not; the line grows to 152 columns | Informational | `scripts/build-loop.sh:101` | High |
| F4 | dev-cycle.bats --help sibling keeps "whole header" and no `-h` | Informational | `test/scripts/dev-cycle.bats:1322` | High |
| F5 | Lib MAIN-declaration comment still names three functions; :25 ragged | Informational | `scripts/lib/dev-cycle-read.sh:22-26, 244-246` | High |

## Overall Assessment

6c83af2a resolves iteration 1's F1 (C1), F3 (A4) and F6 (A7) fully. It resolves F4 (A3) and F5 (C7) in substance. It changes no output string, flag or exit code, so it breaks no consumer. One residue rises above Informational. The never-line rule's "missed" examples name "a task box", which is right only for a checked box. That is the fact-check's Claim 1b, confirmed here as a help-to-behavior inconsistency. It fails closed and is a one-word fix in place. The rest are optional sibling-shape and wording notes. None blocks landing on API grounds.

## Goal-Alignment Note

- Success criterion (restated verbatim): A markdown report saved to docs/reviews/api-consistency-reviewer-review-2026-10-06-i2-build-loop-u1d.md (first line `Commit: cc75db98`), structured per the api-consistency-reviewer skill.
- Answered: yes. The focus items are covered:
  - the rewritten never-line rule (F1, F2);
  - the skip-list order (resolved; precedence noted under Baseline);
  - iteration 1's F1, F3, F4 and F5 (resolution table);
  - consistency with the rest of the header and with dev-cycle.sh (F1, F3, F4);
  - comment widths (all rewrapped lines are 90 columns or fewer; the one over-90 diff line is F3).
- Out of scope: the test-strength questions (exit-1 mutant survival, Claim 16's "never consults" wording, brieflocal) belong to test-strategy and fact-check. C2/F2 from iteration 1 stays deferred to U2.
- Escalate: F4 to the orchestrator, as an optional override-log note for the dev-cycle sibling test.
