Commit: c143b929

# API Consistency Review — feat/build-loop-u1c (U1c), final confirming pass

**Scope:** `git diff feat/build-loop-u1b...feat/build-loop-u1c` at c143b929. The diff adds the `--settings` constraints line and the `--status BRIEF...` output contract in `scripts/build-loop.sh`.
**Date:** 2026-10-05
**Based on:** the Stage-1 merged fact-check (docs/reviews/code-fact-check-report-build-loop-u1c.md, 32 Verified, 10 Mostly accurate), plan rev 4 (docs/working/plan-build-loop-handoff.md, Script interface `:204-205`, Brief machine lines, D1-D3, F20, F31, T44), and the iteration-1 rubric (553a50d5).

## Baseline Conventions

- **Read-mode output grammar** comes from the plan (`:196-199`) and from dev-cycle.sh's check modes (`scripts/dev-cycle.sh:22-71`). Each argument gets one line: `ok <arg> FIELDS...`, `absent <name>` (only for `--check-branch`), or `skip <arg>: <reason>`. A skip line is an answer, not an error. Read modes exit 0 when every argument was answered and exit 1 on bad usage.
- **Argument handling:** a mode followed by one or more arguments, which the mode answers in argument order. An empty list fails with `<mode> needs at least one argument` and exit 1 (`scripts/dev-cycle.sh:106-109`). The help is the header comment, printed up to the first non-comment line.
- **Settings-line grammar** (build-loop.sh `--settings`, U1b): `KEY VALUE STATUS: WHY`. Each line starts with a lowercase key, then a value and a status word, and the WHY after the colon is prose.
- **Placeholders:** build-loop.sh writes them in UPPERCASE (`WHY`, `GLOB`, `BRIEF`), as the plan does. dev-cycle.sh writes `<path>` in angle brackets. Each file is consistent with itself.
- **Inherited vocabulary:** STATE `open|done|dropped|new` comes from `check_brief`. `absent` comes from `check_branch`. LOOP `absent|working|ready|blocked|stopped` and constraints `ok|missing|none-hard|unreadable` are fixed by the plan (`:204-205`).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `--status BRIEF...` | CLI mode | `--check-brief PATH...`, `--check-branch NAME...`, `--settings` | `scripts/dev-cycle.sh:11-12,106-109`; plan `:205` | Consistent: takes one or more arguments, answers in order, and an empty list exits 1. It is a near-homonym of the planned `--state`, but the plan fixes both names. |
| `constraints ok N-hard M-soft\|missing\|none-hard\|unreadable: WHY` | output line | `policy ... set\|unset: WHY`, `never ... set\|none\|malformed: WHY` | `scripts/build-loop.sh:14-28`; plan `:204` | Consistent with the plan's vocabulary. `unreadable` covers both a file that is not read and a grammar error, where never uses `malformed` for the second. The plan fixes this, so C9's vocabulary half is settled. |
| `ok BRIEF STATE POLICY BRANCH LOOP SHA DATE DISPATCHED [REASON]` | output line | `ok <path> open\|done\|dropped <commit>`, `ok <name> <commit> <n> <date>` | `scripts/dev-cycle.sh:29-49`; plan `:205` | Consistent: the order and names follow the plan, and REASON comes last because it holds blanks. |
| `skip BRIEF: WHY` | output line | `skip <path>: <reason>` | `scripts/dev-cycle.sh:36,46` | Consistent. `check_brief`'s own skip lines pass through unchanged (`:313`). |
| `new review - absent - - 0` | placeholder row | none (dev-cycle check modes print no placeholder fields) | none — searched `scripts/dev-cycle.sh` and `scripts/lib/dev-cycle-read.sh` help and echo lines | New convention (`-` for an empty field), documented in the help. Fine. |
| `absent` (LOOP) | enum | `absent <name>` | `scripts/lib/dev-cycle-read.sh:381` | Consistent meaning: no such branch. |
| `CONSTRAINTS_LINE`, `SHARED_BRANCHES`, `marker_kind`, `shared_branches`, `status_line` | internal globals and functions | `POLICY_LINE`, `NEVER_LINE`, `check_brief`, `check_branch` | `scripts/build-loop.sh:194-198` | Consistent (`*_LINE` for display strings, snake_case functions). These names are private. |

## Iteration-1 wording fixes

- **A3 holds.** The skip text now reads "its Branch: line is missing or malformed or its Dispatched: line malformed" (`:63-65`). A missing `Dispatched:` gives 0 (`:60-61`, `:320`). T8 and T6 confirm this.
- **A6 holds.** "(the path must also be plain in the working tree, as --check-brief)" (`:43-44`) matches `check_brief`'s blocker check (fact-check Claim 10).
- **A7 holds.** The comment now reads "POLICY is for --status and the gate, NEVER for the gate" (`:196-197`). The gate is a planned mode (Claim 20). The comment has an odd break after "POLICY" on line 196. Both are cosmetic, so no finding.
- **C9 holds for the arm.** `dup` now has its own arm (`:264`), and `*)` gives the near-miss message (`:265`). awk's END always prints, and the pipeline runs under `pipefail`, so the `*)` arm cannot get an empty FILE_OUT in practice. The `unreadable`-vs-`malformed` half of C9 is plan vocabulary (`:204`), so it is not re-filed.
- **Override filter.** C6 (row 270, no machine CONSTRAINTS value), C8 (row 271, where the copy paragraph sits) and C10 (row 272, STATE `new` for a closed/ move) are settled. Their premises have not changed, so they are not re-filed.

## Findings

#### F1. The constraints help says "any other line" that looks like an ID makes the file unreadable. The code exempts fenced lines and non-ASCII look-alikes and still reports `constraints ok`

**Severity:** Inconsistent
**Location:** `scripts/build-loop.sh:35-37` (help), `:161-175` (CONSTRAINTS_AWK: `fence($0) { next }` at `:163`, ASCII-only folding at `:172`)
**Move:** 3 (consumer contract; documentation drift)
**Confidence:** High
**Legibility-target:** whoever writes `docs/constraints.md` (U5's process), and the U3 `--start` author who decides what `ok` guarantees

Evidence (probe in my scratch repo; three-line files after `- H1: a` / `  success: b`):
```
== fenced hard constraint        ('```' 'H2: never touch prod' '```')
constraints ok 1-hard 0-soft: docs/constraints.md on the default branch
== cyrillic                      ($'\xd0\x9d2: never touch prod', i.e. "Н2:")
constraints ok 1-hard 0-soft: docs/constraints.md on the default branch
== fullwidth                     ($'\xef\xbc\xa82: never touch prod', i.e. "Ｈ2:")
constraints ok 1-hard 0-soft: docs/constraints.md on the default branch
```
Help text:
```
#                 constraint or heading, and no ID may repeat. Any other line
#                 whose letters and digits, from its first letter, start like
#                 "h1" or "s1" makes the file unreadable. Only "ok" lets the orchestrator dispatch.
```

Q-112 [1] asks for a report in exactly this case: the help misdescribes the rule, and a hard-constraint-looking line is dropped from the count while the line reads `constraints ok`. Plan `:204` says the file is read "under FENCE_AWK", so skipping fenced lines is the intended grammar. The divergence is in the help: "Any other line" includes fenced lines, and "letters and digits" reads as including Н and Ｈ. The awk code strips everything outside `[a-zA-Z0-9]` in the C locale, so these lines fall through. The gap runs in the fail-open direction. A reader who trusts the help believes a stray or fenced `H2:` refuses the file, but `--settings` counts 1 hard constraint and dispatch would proceed (once U3 exists). The loop prompt still quotes the whole file, so the text is not lost. Only the orchestrator's count and its "ok" guarantee are affected. This confirms the fact-check's Claim 8 escalation for this critic.

**Recommendation:** Keep the code. Change the help to "Any other line outside a code fence whose ASCII letters and digits, from its first ASCII letter, start like "h1" or "s1" makes the file unreadable". Add one T44 case that pins the fenced-`H2` → `ok` behaviour, so the contract is tested rather than left implicit.

#### F2. The `--status` help contradicts itself on a `handoff:` tip that is not a marker, and the skip rule as worded predicts a skip where the code prints `working`

**Severity:** Minor
**Location:** `scripts/build-loop.sh:54-60` and `:67-69` (help), `:336-344` (code)
**Move:** 3 (consumer contract)
**Confidence:** High
**Legibility-target:** the U4 skill author, who maps LOOP and skip lines to actions

Evidence (branch `feat/a` at main's tip, with main's tip subject `handoff: garbage`, so 0 commits ahead):
```
ok docs/working/briefs/2026-10-01-a.md open review feat/a working 8a55de60b95ff054095b619991dd3cdb0bd838e9 2026-10-05 0
```
Help:
```
#                 on its first line; REASON is printed last. Any other tip is
#                 working. ...
#                 ... or the tip's subject (its
#                 message's first line) starts "handoff:" but it is not a
#                 marker.
```

The two sentences overlap. A tip at 1 or more ahead whose subject starts `handoff:` but fails the marker rules is "any other tip" (so working) and also "starts handoff: but not a marker" (so skip). The code gives skip. A tip at 0 ahead with a `handoff:` subject is "not a marker" by the help's own definition, so the skip sentence predicts skip. The code gives working, and T7 asserts that (`build-loop-read.bats`, "A marker at main's tip with the branch 0 commits ahead is main's"). Fact-check Claim 14 found the same omission. The behaviour is right and fails closed in both cases. Only the precedence is unstated, and that is the text U4 will be written against.

**Recommendation:** Reword to "Any other tip is working, except that on a branch at least one commit ahead a tip whose subject starts "handoff:" but is not a marker is a skip". Make the skip clause say "(the branch at least one commit ahead)".

#### F3. The shared-branch skip applies only when the queried brief is open. The help's wording also covers done and dropped briefs

**Severity:** Minor
**Location:** `scripts/build-loop.sh:66-67` (help), `:327` (`[[ "$st" == open && ... ]]`)
**Move:** 3 (consumer contract)
**Confidence:** High
**Legibility-target:** the U4 skill author

Evidence (briefs b and c open with `Branch: feat/s`, brief d `Status: done` with `Branch: feat/s`):
```
ok docs/working/briefs/2026-10-01-d.md done review feat/s absent - - 0
```
Help:
```
#                 malformed, its branch name is refused (as --check-branch),
#                 another open brief on main, in briefs/ or closed/, names the
#                 same branch (ignoring case), or the tip's subject (its
```

As worded ("another open brief ... names the same branch"), brief d should be a skip. The code gates the check on the queried brief's own state being open (Claim 16b, all three replicates). This is the right behaviour, because F31 is about two loops racing on one branch, and a done brief has no loop. The text does not say so.

**Recommendation:** Change the clause to "for an open brief, another open brief on main ... names the same branch".

#### F4. "heading" means only a column-0 `#` line. Setext and indented ATX headings do not end a pending hard constraint

**Severity:** Minor
**Location:** `scripts/build-loop.sh:33-35` (help), `:174` (`/^#/`)
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** the author of `docs/constraints.md`

Evidence:
```
== setext heading ends?   ('- H1: a' 'Other' '-----' '  success: b')
constraints ok 1-hard 0-soft: docs/constraints.md on the default branch
== indented atx           ('- H1: a' '  ## Other' '  success: b')
constraints ok 1-hard 0-soft: docs/constraints.md on the default branch
```

In both files, H1's `success:` line sits under a different (Markdown) heading, and the file still reads `ok 1-hard`. This is the same as fact-check Claim 6 / 36b. The help's "before the next constraint or heading" reads as a Markdown heading. A `success:` line can therefore attach across a section boundary that a reader of the rendered doc would see. This fails open only on how a success line is paired with its constraint, not on the count, so the severity is Minor.

**Recommendation:** Change the help to "a line starting "#" (an ATX heading at column 0)". Alternatively, treat a line after the constraint that matches `^ {0,3}#` or `^(-+|=+)[ \t]*$` as a heading too.

#### F5. A whitespace-only second line makes a real marker a skip, though git reads its subject as the bare marker

**Severity:** Informational
**Location:** `scripts/build-loop.sh:57-59` (help "alone on its first line"), `:283-284`
**Move:** 7 (asymmetry: git's subject vs the script's subject)
**Confidence:** High
**Legibility-target:** the loop prompt author (U3), who writes the marker instructions

Evidence (message `handoff: ready\n   \nbody` at 1 ahead):
```
skip docs/working/briefs/2026-10-01-a.md: the tip of feat/a starts "handoff:" but is not a marker: its subject runs onto a second line
git subject=[handoff: ready]
```

The script's "first line" check refuses a blank-looking second line, while `git log --format=%s` reports the subject as exactly `handoff: ready`. This fails closed and is a skip with a reason. It is filed only so the U3 prompt tells loops to put a truly empty line between subject and body. Fact-check Claim 14 noted the same omission from the help.

**Recommendation:** None in U1c beyond optionally adding "(the second line, if any, empty)" to the help. Carry the empty-line rule into the D3 marker text in U3's prompt.

#### F6. Small grammar in the none-hard WHY: "has 1 soft constraints"

**Severity:** Informational
**Location:** `scripts/build-loop.sh:262`
**Move:** 4 (message consistency)
**Confidence:** High
**Legibility-target:** the human who reads the `you: judgment` entry the orchestrator files from this line

Evidence:
```
constraints none-hard: docs/constraints.md on the default branch has 1 soft constraints and no hard one (H1: with a success: line)
```

This is WHY prose, not a parsed field, so the severity stays at the floor.

**Recommendation:** Write "soft constraint(s)", or leave it.

## What Looks Good

- `--status` matches the plan's field order exactly (`:205`). It takes and answers arguments the way dev-cycle.sh's check modes do: in argument order, `skip` as an answer with exit 0, and an empty list exiting 1 with a usage line. A probe confirmed `--status --settings` prints `skip --settings: not an allowed path form`, exit 0, which is the same as dev-cycle.sh `--check-brief --settings`.
- `check_brief`'s skip lines pass through unchanged, and `check_branch`'s refusals are re-prefixed as `skip BRIEF: Branch: <reason>` without echoing the raw name. A consumer therefore sees one skip grammar keyed on the brief path.
- The fields that can hold blanks (REASON) come last. Every other field is blank-free by construction (pathform, NAMECHARS, hex SHA, `%cs` date, 0-99). U4 can split on single spaces into 9 fields and take the rest as REASON.
- The constraints line follows the U1b `KEY VALUE STATUS: WHY` shape, and its status words are exactly the plan's.
- The iteration-1 wording fixes A3, A6, A7 and C9 hold (see above).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | The near-miss help says "any other line"; fenced and non-ASCII look-alike IDs still give `constraints ok` (Claim 8 escalation) | Inconsistent | `scripts/build-loop.sh:35-37`, `:163`, `:172` | High |
| 2 | The help's "Any other tip is working" and the handoff:-skip clause overlap; a 0-ahead `handoff:` tip reads working, not skip | Minor | `scripts/build-loop.sh:54-60`, `:67-69` | High |
| 3 | The shared-branch skip applies only to an open queried brief; the help omits this | Minor | `scripts/build-loop.sh:66-67`, `:327` | High |
| 4 | "heading" means only a column-0 `#`; Setext and indented ATX headings do not end a pending H | Minor | `scripts/build-loop.sh:33-35`, `:174` | High |
| 5 | A whitespace-only second line refuses a marker that git reads as bare | Informational | `scripts/build-loop.sh:57-59`, `:283-284` | High |
| 6 | "has 1 soft constraints" | Informational | `scripts/build-loop.sh:262` | High |

## Overall Assessment

The `--status` and constraints contracts are consistent with plan rev 4 and with the dev-cycle.sh sibling modes: field order, vocabulary, the skip grammar, argument handling and exit codes. The iteration-1 wording fixes hold. Every finding is help text that is out of step with correct, fail-closed or plan-intended code, and each can be fixed in place with a clause. F1 is the one to fix before merge. It is the case Q-112 [1] asks to be reported: the help promises a refusal that the code does not make, and the result is `constraints ok` with a hard-looking line uncounted. F2 and F3 matter because U4's skill will be written against this help.

## Goal-Alignment Note
- Success criterion (restated verbatim): "A markdown report saved at the output path your task names, structured per your skill, with a `Commit: c143b929` first line."
- Answered: yes. This report is at docs/reviews/api-consistency-reviewer-review-2026-10-05-final-build-loop-u1c.md with that first line. It covers the --settings constraints line and the --status contract against plan rev 4 and the dev-cycle.sh siblings, re-checks A3/A6/A7/C9, weighs Claims 6, 8, 14, 16b and 20, answers the Claim 8 escalation (F1), and applies the override filter (C6, C8, C10 not re-filed). Every finding was verified by running probes in my scratch dir. bats build-loop-read.bats passes 16/16 at HEAD.
- Out of scope: security exploitability of the look-alike gap (security-reviewer), and performance of shared_branches (rows 266-267). Claims about U3/U4 behaviour (row 275).
- Escalate: F1. The orchestrator should confirm that fence-skipping stays the grammar (plan `:204` says it does) and that a help-text fix, not a code change, is the response Q-112 [1] wants.
