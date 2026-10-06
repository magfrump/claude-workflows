Commit: ab71bce5

# API Consistency Review — feat/build-loop-u1d, final confirming pass

**Scope:** full branch, `git diff main...HEAD -- scripts test` (83cdb005, 6c83af2a, 07c354c5, merged with main at ab71bce5). Public surface: build-loop.sh's and dev-cycle.sh's `--help` text and output-line grammar, the help-range comments, and the lib's main_entry and brief_fields contracts with the lib header around them. The header was read as a whole, not just the changed lines.
**Date:** 2026-10-06
**Based on:** docs/reviews/code-fact-check-report-build-loop-u1d.md (k=3 merged, `Commit: ab71bce5`; 20 claims: 15 Verified, 4 Mostly accurate, 1 Incorrect, the Incorrect one history only); iteration 2's api report (`Commit: cc75db98`, F1-F5).

## Baseline Conventions

These carry over from iterations 1 and 2 and were re-checked at HEAD:

- **Output grammar.** `--status` prints `ok BRIEF ...` or `skip BRIEF: WHY`, and consumers key on the first word. WHY is prose for a human, and no parser reads it. The branch changes one WHY string: "could not be listed" loses "(git grep failed)". That is the stated, intended change (fact-check Claim 3, `route: code-fact-check`). Its sibling WHYs in status_line (`build-loop.sh:333-357`) name a cause, not a mechanism. The one parenthetical still left, "(compared ignoring case)", qualifies the cause, so the edit brings that reason into line with the others.
- **The help lists every skip cause as one closed list.** At HEAD the `skip BRIEF: WHY` paragraph (`build-loop.sh:66-76`) covers every `skip` arm in status_line: check_brief's, the Branch and Dispatched lines, the two F31 skips, check_branch's and the marker's. The list does not claim a precedence order.
- **Lib contracts list every answer and its causes in one parenthesis.** main_entry (`lib:254-261`) and brief_fields (`lib:284-290`) now both say "no default branch found by name, a path pathform refuses, ...". The lib header (`lib:22-25`) and the MAIN declaration comment (`lib:244-247`) say the same thing in the same words: main_entry and brief_fields answer error.
- **Help-range comment.** Both scripts now put the same full-line comment above the `-h|--help` case: `build-loop.sh:101`, `dev-cycle.sh:111`.
- **Help tests.** Both suites loop `-h --help` and assert the first and last header lines. The titles share one shape: "... -h and --help print the header from its first line through its last" (`build-loop-read.bats:441`, `dev-cycle.bats:1322`).
- **Width.** Every header and comment line the branch adds or rewraps is 90 columns or fewer. The over-90 lines in dev-cycle.sh's header (:19, :42, :54, :64, :68, :80, :81) predate the branch.

## Iteration-2 findings: resolved?

| Iter-2 finding | What 07c354c5 did | Verdict |
|---|---|---|
| F1: "a task box" listed as missed; "is a second copy" assumes the exact line | :18-20 now say "an unchecked task box" counts and "a checked task box" is missed, and "counts as a copy, so self-merge is off" holds with or without the exact line (fact-check Claim 1 Verified, executed, both orders, `route: code-fact-check`) | **Resolved.** A cross-paragraph residue remains at :44 (F2 below) |
| F2: "exact" vs output's "valid" | :17 says "one valid never line", which matches the WHY at `build-loop-read.bats:114` | **Resolved** |
| F3: help-range comment trailing, 152 columns | Moved to its own line above the case, in dev-cycle.sh's words (`build-loop.sh:101`) | **Resolved** |
| F4: dev-cycle.bats help test still "whole header" with `--help` only | Retitled, and now loops `-h --help` (`dev-cycle.bats:1322-1328`; fact-check Claim 4 Verified) | **Resolved** |
| F5: MAIN comment names three functions; :25 ragged | The MAIN comment now names all five and answers "(main_entry and brief_fields answer error)" (`lib:244-247`; Claim 8 Verified) | **Resolved in substance.** The wrap residue moved down one line (F1 below) |

## Name-Pattern Audit

The branch adds no flags, modes, functions, globals, output keywords or exit codes. The one output change shortens an existing WHY. The only new names are test titles.

| New / changed name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `--settings: deferred cases: ... (U1d)` | test title | `--settings: slots are 1 to 9 ...`, `--settings: docs/constraints.md from main ...` | `test/scripts/build-loop-read.bats:94-196` | Consistent: same `--MODE: ...` prefix; the `(U1d)` tag follows the `(Tn)` source-tag habit |
| `build-loop.sh -h and --help print the header from its first line through its last (U1d)` | test title | `build-loop.sh sources the lib from its own directory, ...`; dev-cycle's `-h and --help print the header ...` | `test/scripts/build-loop-read.bats:214`; `test/scripts/dev-cycle.bats:1322` | Consistent: a whole-script test prefixed with the script name, as at :214; same wording as the sibling |
| `--status: deferred cases: ... (U1d)` | test title | `--status: two open briefs naming one branch both skip ... (T28)` | `test/scripts/build-loop-read.bats:378` | Consistent |
| `-h and --help print the header from its first line through its last` | test title (renamed) | the build-loop sibling above | `test/scripts/build-loop-read.bats:441` | Consistent: it mirrors the sibling. dev-cycle.bats titles carry no script-name prefix |
| `--check-brief, --check-branch and --check-answer need a default branch found by name; the others do not` | test title (renamed) | the help sentence `--check-brief, --check-branch and --check-answer need a default branch found by name` | `scripts/dev-cycle.sh:70-71` | Consistent: the same list in the same order |
| `main_entry answers error for a path pathform refuses (U1d)` | test title | brief_fields' and main_entry's "a path pathform refuses" | `scripts/lib/dev-cycle-read.sh:254`, `:288-289` | Consistent: the contract's own phrase |

## Findings

#### F1. The lib header still says build-loop.sh's suites apply "once that second caller lands", and three of its lines are left short

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:10-14`, `:25-27`
**Move:** 3 (consumer contract: documentation drift)
**Confidence:** High
**Legibility-target:** for-author

Evidence:
```
10:70:# of scripts/ with its lib/ is self-contained. A change here must pass
11:77:# test/scripts/dev-cycle.bats, and build-loop.sh's suites under test/scripts/
12:36:# once that second caller lands. The
13:76:# caller sets -euo pipefail (check_answer and brief_fields also set pipefail
14:18:# for themselves),
15:79:# cds to the repo root and sets ROOT_REAL (that root, symlinks resolved) before
...
25:79:# brief_fields answer error). check_brief, check_branch and check_answer answer
26:41:# with one printed line per argument that
27:89:# can echo repo text: print it through scrub, read it as `out="$(check_brief ...)"` under
```
(`line:width:text`; widths from `awk '{print NR":"length":"$0}'`.)
```
$ git show main:scripts/build-loop.sh | grep -n 'source "$READ_LIB"'
90:source "$READ_LIB"
$ ls test/scripts
... build-loop-read.bats  dev-cycle.bats ...
```

The "second caller" condition was true when U1a wrote it: fact-check u1a Claim 7 found that scripts/build-loop.sh did not exist yet. Since U1b, build-loop.sh is on main, sources this lib, and has `test/scripts/build-loop-read.bats`. The branch edits lines 13-14 and 24-26 of this paragraph but leaves line 12's future tense. A reader of the lib's change rule may take the build-loop suite as optional, though it is the suite that now pins main_entry's and brief_fields' callers. The paragraph also has three short lines: :12 (36 columns), :14 (18; added by 83cdb005) and :26 (41). 07c354c5's "the header paragraph is re-wrapped" moved the short line from :25 to :26 rather than closing it. That is wording only, and nothing breaks.

This has not been filed before. The u1a fact-check verified the phrase while it was still true, and no later report or override row names it.

**Recommendation:** When the lib is next touched (U2 adds main_entry's first changed-path caller), write "A change here must pass test/scripts/dev-cycle.bats and test/scripts/build-loop-read.bats." and re-flow :10-27. One override row is enough if this unit is closing.

#### F2. The copy paragraph still gives "a task box" as markup that adds letters, while the never-line rule now says an unchecked one adds none and is counted

**Severity:** Informational
**Location:** `scripts/build-loop.sh:42-45` (context, not in this diff), against `:17-21` (diff)
**Move:** 7 (asymmetry between two statements of one rule)
**Confidence:** Medium. The :44 sentence is hedged ("can still hide") and scoped by "markup that adds letters", so it is not false. The issue is that the two paragraphs read side by side.
**Legibility-target:** for-author

Evidence:
```
17: #                 also needs one valid never line. A never list in markup the
18: #                 copy count sees (bold, a list marker, an unchecked task box)
19: #                 counts as a copy, so self-merge is off; one it misses (a
20: #                 checked task box, a fence) is ignored, so self-merge rests on
21: #                 the valid line alone.
...
42: #             Copies are found best effort: a line counts as one when its
43: #             letters alone, case folded, start with the key's
44: #             ("buildlooppolicy"). Markup that adds letters (a task box, a tag)
45: #             can still hide a copy; only an exact line ever sets a value.
```

Iteration 2's F1 fixed :18-20 by splitting task boxes into unchecked (seen) and checked (missed). Fact-check Claim 1 executed both and confirmed it (`route: code-fact-check`). :44 is the paragraph that defines "the copy count" used at :18, and it still gives the unsplit example "a task box". A reader who goes back to :44 to learn what "the copy count sees" means finds "a task box" listed as hiding a copy. That is the reading 07c354c5 removed from :19. It fails closed either way: a hidden copy can only leave self-merge resting on the valid line, as :20-21 say.

**Recommendation:** Optional: change :44 to "(a checked task box, a tag)", in the same words as :20.

#### F3. The LOOP paragraph says "a branch level with main" where the skip list and the marker rule say "ahead of main"

**Severity:** Informational
**Location:** `scripts/build-loop.sh:58-65` (rewrapped by 83cdb005), against `:71`
**Move:** 7 (asymmetry in one header's terms)
**Confidence:** Medium (fact-check Claim 2 annotation, r1+r3, executed: a branch behind main also reads working)
**Legibility-target:** for-consumer (U2's --check reads LOOP)

Evidence:
```
58: #                 absent). A tip is a marker only when the branch is at least
59: #                 one commit ahead of main and the tip is an empty commit with
...
64: #                 printed last. A tip on a branch level with main, or whose
65: #                 subject does not start "handoff:", is working. DISPATCHED:
...
71: #                 on a branch ahead of main the tip's subject (its message's
```
```
build-loop.sh:352-353:  loop=working
                        if [[ "$ahead" -gt 0 ]]; then
```

The code has two cases: ahead > 0, or not. :58-59 and :71 use those terms ("ahead of main"). :64 says "level with main", which names only one of the zero-ahead cases. A branch behind main, such as a stale branch after main moved on, also has ahead = 0 and reads working. Fact-check Claim 2 records this as a scope note on a Verified claim. The header gives a consumer no rule for that case, except by inferring it from :58's "only when". This predates the branch: 83cdb005 only rewrapped :64. It is new here only as a terminology mismatch, in a paragraph the branch edited.

**Recommendation:** Optional: "A tip on a branch not ahead of main, or whose subject ...". This matches :58 and :71 and covers the behind case.

## What Looks Good

- **Iteration 2's five findings are all closed** in the recommended words: an unchecked or checked task box, "valid", the comment on its own line, the dev-cycle test loop and title, and the five-function MAIN comment.
- **main_entry's contract now matches its guard and brief_fields' wording exactly.** "a path pathform refuses" is in both cause lists, and "It runs main_by_name and pathform itself, before any read" is backed by Claim 9 (8 refused forms, no ls-tree; `route: code-fact-check`). The test title uses the contract's own phrase. brief_fields' redundant pathform check is a Won't-Fix, so it is not re-filed here.
- **The skip list reads as one sentence with one scope.** The marker clause carries its own condition ("on a branch ahead of main"). Then ", or, for an open brief only," scopes the two F31 causes to the end of the sentence. Claim 3 probed open, done and dropped briefs.
- **The one output change makes the reasons consistent.** "could not be listed" now names a cause like its siblings, and the new `--status` step pins the exact string, with a caller's config pair reaching git.
- **dev-cycle.sh's --check-answer gate list, help sentence and test title** use the same three modes in the same order (`dev-cycle.sh:70-71`, `dev-cycle.bats:813`).
- **The help-range comments and help tests are now word-for-word siblings** across the two scripts. Both start at line 2 and stop at the first non-empty line not starting with #, and both test `-h` and `--help`.
- No flag, mode, exit code or output keyword changes, so no consumer breaks.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | Lib header: "once that second caller lands" is stale; three short lines remain | Informational | `scripts/lib/dev-cycle-read.sh:10-14, 25-27` | High |
| F2 | Copy paragraph's "a task box" vs the never rule's unchecked/checked split | Informational | `scripts/build-loop.sh:44` vs `:17-21` | Medium |
| F3 | "level with main" vs "ahead of main"; a branch behind main is unnamed | Informational | `scripts/build-loop.sh:64` vs `:58-59, :71` | Medium |

## Overall Assessment

After three rounds of edits, the header now reads as one consistent document on the points this unit set out to fix. The never-line rule, the skip list, both help-range comments, main_entry's and brief_fields' error contracts and the lib's by-name rule all use the same words where they state the same thing. The fact-check verifies each of them. The one output change, the shorter "could not be listed" WHY, was intended and is pinned. No flag, keyword or exit code changed. The three findings are Informational: two cross-paragraph wording residues in build-loop.sh's help (F2, F3) and stale and ragged prose in the lib header (F1). Each is a one-line edit, none affects behavior, and none blocks landing on API-consistency grounds. If the loop is closing, they fit an override row pointing at U2, which touches both the lib and the LOOP consumer.

## Goal-Alignment Note

- Success criterion (restated verbatim): A markdown report saved to docs/reviews/api-consistency-reviewer-review-2026-10-06-final-build-loop-u1d.md (first line `Commit: ab71bce5`), structured per the api-consistency-reviewer skill.
- Answered: yes. The report covers:
  - the --help text of both scripts, read whole (F2, F3; the iteration-2 table);
  - the output-line grammar (Baseline; What Looks Good);
  - main_entry's and brief_fields' contracts and the lib header (F1; What Looks Good);
  - the test titles (Name-Pattern Audit).
- Not re-filed: the deferred items (badform, git log under a broken config, U2's error-as-refusal, ls-tree cost, GIT_NO_REPLACE_OBJECTS, the local BRIEF alone, bl_setup's GIT_DIR) and the Won't-Fix items. Fact-check's Claim 13 (T7 comment), Claim 18 (`&&` fixture chains), Claim 19 (shellcheck note) and Claim 15 (history) are test or commit-message accuracy matters, not API surface, and are left to that report.
- Out of scope: test strength and mutant coverage.
- Escalate: nothing. F1-F3 are optional and suit one override row with trigger U2.
