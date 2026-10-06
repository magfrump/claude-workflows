Commit: 83cdb005

# API Consistency Review — feat/build-loop-u1d (commit 83cdb005)

**Scope:** `git diff main...HEAD` (one commit). The public surface is `scripts/build-loop.sh --help` (:1-78) and its `--status` output-line grammar (the changed "could not be listed" skip reason), `scripts/dev-cycle.sh --help`'s `--check-answer` paragraph (:56-66) and its help-range comment (:111), and the lib's `main_entry` contract (`scripts/lib/dev-cycle-read.sh:248-276`: the comment's list of `error` causes and the new pathform precondition).
**Date:** 2026-10-06
**Based on:** docs/reviews/code-fact-check-report-build-loop-u1d.md (Stage 1, merged k=3)

## Baseline Conventions

- **Output line shape.** `--status` prints `ok BRIEF ...` or `skip BRIEF: WHY`. The plan (docs/working/plan-build-loop-handoff.md:194-199) makes `skip` mean "unreadable", and consumers key on the first word and the `BRIEF:` prefix. WHY is prose for a human. No consumer parses WHY: `rg 'could not be listed|git grep failed'` outside docs/reviews/ finds only build-loop.sh:70, :338 and build-loop-read.bats:388. U4's skill is not written yet.
- **Skip reasons say what, not how.** Sibling reasons name the condition. A trailing parenthesis adds meaning or advice, never the mechanism: `(compared ignoring case)` (build-loop.sh:340), `(narrow the glob)` (dev-cycle.sh:151), `(use --check-write)` (dev-cycle.sh:180).
- **Help enumerates every skip cause** as a closed "X, Y, ..., or Z" list (build-loop.sh:64-72). The lib's reasons are summarised the same way in dev-cycle.sh's help.
- **Lib function contracts list every answer and its causes in one parenthesis.** brief_fields' `error` is "(no default branch found by name, a path pathform refuses, any main_entry answer but blob, its error included, or the blob could not be read)" (lib:286-288).
- **Callers translate `main_entry`'s `error` as "could not be read".** main_file: "the default branch's tree could not be read for $f" (build-loop.sh:129). check_answer: "the tree of the default branch could not be read, so $f is not read" (lib:559).
- **Path-form refusals have their own reason.** "not an allowed path form" (lib:327 check_brief; dev-cycle.sh:146, :162, :175).
- **Help shorthand.** Help prose says "main" where output says "the default branch" (build-loop.sh:61, :68-71 vs :338, :340). This predates the diff and is used consistently.

## Deferred wording rows: do they land as asked?

| Row item | Asked | Landed | Verdict |
|---|---|---|---|
| U1a A19 | dev-cycle.bats:767 title includes --check-answer | title and loop (dev-cycle.bats:813-816) | Lands; the test fails without the gate (fact-check Claim 20) |
| U1a A20 | "until it lands on the default branch", not "until committed" | "it reads what main's copy says until it lands there" (dev-cycle.sh:59) | Lands (Claim 9 Verified, `route: code-fact-check`) |
| U1a A21 | help-range comment: the first non-empty line | dev-cycle.sh:111 | Lands (Claim 10 Verified, `route: code-fact-check`); see F5 for sibling wording |
| U1a A22 | main_entry checks main_by_name itself | lib:257-259 | Lands, but the earlier cause list is not updated; see F1 |
| U1a C16 | main_entry runs pathform | lib:263 | Lands (Claim 12 Verified, `route: code-fact-check`); see F2 for U2 |
| U1a C19 | lib header names functions that set pipefail | lib:13-14 | Lands; list complete (Claim 11, `route: code-fact-check`) |
| U1b A25 | "with no exact line beside it" | "with no exact never line beside it" (build-loop.sh:17-18) | Lands as asked, but the asked wording is imprecise; see F4 |
| U1b A26 | SETTINGS_AWK: next line outside a fence, 1 at EOF | build-loop.sh:143-145 | Lands (Claim 5 Verified, `route: code-fact-check`) |
| U1b A27 | help-range comment skips empty lines | build-loop.sh:99 | Lands (Claim 4 Verified, `route: code-fact-check`) |
| U1c A24 | "of a branch ahead of main"; re-wrap line 62 (115 cols) | build-loop.sh:61-72; every build-loop.sh comment line is now 90 columns or fewer | Lands; the clause scope is still ambiguous, see F3 |
| U1c A25 | F31 comment: "any exit status above 1" | "an exit above 1 fails closed" (build-loop.sh:307-308) | Lands in meaning (Claim 6 Verified, `route: code-fact-check`) |
| U1c C37 | help skip list names "could not be listed" | build-loop.sh:69-70 | Lands |
| U1c C38 | drop "(git grep failed)" | build-loop.sh:338, bats:388 | Lands (Claim 8 Verified, `route: code-fact-check`) |

## Name-Pattern Audit

The diff adds no flags, modes, lib functions, globals or output keywords. Its public changes are one changed skip reason, help prose, and a new precondition on an existing function.

| New / changed string | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `skip BRIEF: the open briefs on the default branch could not be listed` | skip reason | `the tree of the default branch could not be read`; `another open brief on the default branch names the same branch (compared ignoring case)`; `no tracked file ... matches` | `scripts/lib/dev-cycle-read.sh:559`; `scripts/build-loop.sh:340`; `scripts/dev-cycle.sh:158` | Consistent: "could not be ...", "the default branch", and no mechanism parenthesis. Non-breaking: no parser reads WHY |
| help: "or the open briefs on main could not be listed" | help clause | "another open brief on main ... names the same branch" | `scripts/build-loop.sh:68-69` | Consistent with the help's "main" shorthand and its output line |
| `main_entry` → `error` for a pathform-refused path | function contract | brief_fields `error` "(..., a path pathform refuses, ...)" | `scripts/lib/dev-cycle-read.sh:286-288` | Consistent in substance. The cause is documented outside the cause list (F1) |
| test titles `... (U1d)` | test names | `--help prints the whole header, through its last line` | `test/scripts/dev-cycle.bats:1322` | Consistent: the build-loop --help title mirrors dev-cycle's word for word |

## Findings

#### F1. main_entry's list of `error` causes still names three; the fourth (pathform) is a separate trailing sentence

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:251-259`
**Move:** 3 (consumer contract: documentation drift)
**Confidence:** High
**Legibility-target:** for-author

Evidence:
```
251: # "absent", "notfile" (the path is some other kind of entry), "notdir PART"
252: # (PART, a directory above the path, is stored as something else) or "error"
253: # (no default branch found by name, ls-tree failed, or the tree lists a name
254: # twice; git's own reads would take the first copy, which may not be the one a
255: # check saw, so this answers error instead; never read as absent). One ls-tree
256: # call lists the path and every directory above it (-t: trees too; --full-tree:
257: # paths from the top level, whatever the current directory). It checks
258: # main_by_name and the path's form itself (pathform, so ls-tree prints it
259: # unquoted): either failing is error.
```
(excerpt ends :259; enclosing main_entry() runs :260-276, read)

The parenthesis after `"error"` reads as the closed list of causes. Its first item, "no default branch found by name", is main_by_name failing. A reader taking the list at face value would not expect `error` for a malformed path. The new sentence adds the cause two sentences later, after the ls-tree aside, and repeats main_by_name. The sibling contract (brief_fields, lib:286-288) puts "a path pathform refuses" inside its cause list. The fact-check found the same split (Claim 12, r1+r2 annotation).

**Recommendation:** Add "a path pathform refuses (so ls-tree would print it quoted)" to the parenthesis at :253. Cut the last sentence to "It checks both itself." or drop it.

#### F2. `error` now covers a refused path form, but the callers' translations say "could not be read"

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:263`; `scripts/build-loop.sh:129`; `scripts/lib/dev-cycle-read.sh:559`
**Move:** 3 (consumer contract), 4 (error consistency)
**Confidence:** Medium (no current caller can reach it; this concerns U2's use)
**Legibility-target:** for-orchestrator-synthesis

Evidence:
```
lib:263:  if ! main_by_name || ! pathform "$1"; then echo error; return; fi
build-loop.sh:129:    error) FILE_WHY="the default branch's tree could not be read for $f"; return 1 ;;
lib:559:      error) echo "skip $a: the tree of the default branch could not be read, so $f is not read"; return ;;
```

Today nothing observable changes. brief_fields and check_brief run pathform first, and main_file and check_answer pass fixed names (fact-check Claim 12, `route: code-fact-check`). The commit gives U2's floor as the motive: the floor calls main_entry on arbitrary changed paths. A changed path with, say, a `"` in it would answer `error`. If U2 copies the existing `error)` arm, the operator reads "the default branch's tree could not be read", which is a different failure with a different fix. The established reason for this case is "not an allowed path form" (lib:327, dev-cycle.sh:146).

**Recommendation:** Do nothing in U1d. Carry a note into U2's brief: the floor should run pathform before main_entry and give the "not an allowed path form" reason (check_brief's order), so `error` keeps its "could not be read" meaning.

#### F3. The help's skip list can be read as limiting the marker skip to open briefs

**Severity:** Minor
**Location:** `scripts/build-loop.sh:64-72` (help); `:349-352` (code)
**Move:** 7 (asymmetry between documented and actual contract)
**Confidence:** High (fact-check Claim 3: r3 probed a done brief that hits the marker skip)
**Legibility-target:** for-author

Evidence:
```
64: #             skip BRIEF: WHY
65: #                 The brief cannot be read (as --check-brief), its Branch:
66: #                 line is missing or malformed or its Dispatched: line
67: #                 malformed, its branch name is refused (as --check-branch),
68: #                 for an open brief, another open brief on main (in briefs/ or
69: #                 closed/) names the same branch (ignoring case) or the open
70: #                 briefs on main could not be listed, or on a branch ahead of
71: #                 main the tip's subject (its message's first line) starts
72: #                 "handoff:" but it is not a marker.
...
349:  if [[ "$ahead" -gt 0 ]]; then
350:    kind="$(marker_kind "$sha")"
352:      bad\ *) echo "skip $a: the tip of $br starts \"handoff:\" but is not a marker: ${kind#bad }"; return ;;
```
(excerpt ends :352; enclosing status_line() continues to :357, read)

C37 added a second "or" inside the "for an open brief" clause. The list's final ", or" now follows a clause that already contains "or", so "for an open brief" can be read as scoping the last item as well. The code applies the marker skip to any state. U4's skill author reads this help to decide which briefs can skip. Misreading it would mean not handling a done brief's marker skip. This is the closed-list precedent the U1c review set: every skip cause stated accurately.

**Recommendation:** Put the open-only clause last so its scope ends with the sentence: "... its branch name is refused (as --check-branch), on a branch ahead of main the tip's subject ... starts "handoff:" but it is not a marker, or, for an open brief only, another open brief on main ... names the same branch (ignoring case) or the open briefs on main could not be listed."

#### F4. The never-line help says an exact line beside a hidden list rescues self-merge; that holds only when the markup hides the copy from the count

**Severity:** Minor
**Location:** `scripts/build-loop.sh:16-18`
**Move:** 3 (documentation drift)
**Confidence:** High (fact-check Claim 1, all three replicates probed)
**Legibility-target:** for-author

Evidence:
```
16: #                 exactly (one trailing CR dropped); else review. Self-merge
17: #                 also needs a valid never line, so a never list hidden in
18: #                 markup, with no exact never line beside it, turns it off.
```

U1b A25 asked for "with no exact line beside it", and that landed. The fact-check shows the condition is incomplete. With `**Self-merge never:** a/` plus an exact line, the copy count sees two copies, `never malformed`, and self-merge stays off. The sentence implies self-merge stays on. This fails closed, so the only cost is surprise: an operator who adds an exact line expecting self-merge gets review and a "more than one line" WHY. The help's own copy paragraph (:38-41) states the right model ("Markup that adds letters ... can still hide a copy"), so the two paragraphs disagree.

**Recommendation:** Use fact-check r2's wording: "a never list in markup turns it off, unless the markup hides it from the copy count and an exact never line stands beside it". Or point to the copy paragraph: "a never list hidden in markup (see Copies below) turns it off".

#### F5. The two scripts' help-range comments describe the same sed range in different words

**Severity:** Informational
**Location:** `scripts/build-loop.sh:99`; `scripts/dev-cycle.sh:111`
**Move:** 2 (consistency between siblings; wording, not a name)
**Confidence:** High
**Legibility-target:** for-author

Evidence:
```
build-loop.sh:99:  -h|--help) sed -n '2,/^[^#]/{/^#/p}' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;  # the header, to the first non-empty line not starting with #
dev-cycle.sh:111:    # The header: from line 2 to the first non-empty line not starting with # (no fixed range to go stale).
```

Both are accurate (Claims 4 and 10, `route: code-fact-check`). The code is the same in both scripts, and the comments now differ: trailing versus preceding, "to" versus "from line 2 to", one with the rationale and one without. A later edit to one will likely miss the other. This is very low cost.

**Recommendation:** Optional: give build-loop.sh the same full-line comment as dev-cycle.sh:111.

#### F6. The `-h` alias row 246 named is still unasserted; the new test uses `--help`

**Severity:** Informational
**Location:** `test/scripts/build-loop-read.bats:428-432`
**Move:** 3 (contract coverage)
**Confidence:** High (fact-check Claims 15 and 24, `route: code-fact-check`)
**Legibility-target:** for-orchestrator-synthesis

Evidence:
```
428: @test "build-loop.sh --help prints the whole header, through its last line (U1d)" {
429:     run --separate-stderr bash "$BL" --help
```

Override row 246 lists "-h" among the gaps, and the commit's Tests bullet counts C26 as resolved. The test matches dev-cycle.bats:1322, which also tests only `--help`, so it is consistent with its sibling. But the public `-h` alias stays untested in both suites.

**Recommendation:** Loop the test over `-h --help`, or record in the override log that `-h` stays deferred.

## What Looks Good

- **The skip reason now matches its siblings.** It names the condition ("could not be listed"), not the mechanism. The code, the help (:69-70) and the one test assertion (bats:388) change together. No parser depends on WHY, so the change does not break consumers (Claim 8, `route: code-fact-check`).
- **The help's skip list is closed again** (C37). It covers every `skip` arm in status_line (:328-352).
- **The main_entry guard is non-breaking** for every current caller (Claim 12, `route: code-fact-check`). It moves the precondition into the callee before U2 adds a caller that cannot be trusted to run it. That is the right order.
- **The `--check-answer` help** now says what a consumer needs ("until it lands there"), not git mechanics (Claim 9, `route: code-fact-check`).
- **The lib header's pipefail note** names exactly the two functions that set it (Claim 11, `route: code-fact-check`).
- **The U1d test titles** follow sibling patterns. The build-loop `--help` title copies dev-cycle.bats:1322 word for word.
- **The build-loop.sh header** is re-wrapped: no comment line is over 90 columns, which closes A24's 115-column line.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | main_entry's `error` cause list omits pathform | Minor | `scripts/lib/dev-cycle-read.sh:251-259` | High |
| F3 | Skip list can read the marker skip as open-only | Minor | `scripts/build-loop.sh:64-72` | High |
| F4 | Never-line rescue holds only when markup hides the copy | Minor | `scripts/build-loop.sh:16-18` | High |
| F2 | `error` now covers a refused form; callers say "could not be read" (U2 note) | Informational | `scripts/lib/dev-cycle-read.sh:263`, `scripts/build-loop.sh:129` | Medium |
| F5 | Sibling help-range comments worded differently | Informational | `scripts/build-loop.sh:99`, `scripts/dev-cycle.sh:111` | High |
| F6 | `-h` alias still untested | Informational | `test/scripts/build-loop-read.bats:428` | High |

## Overall Assessment

U1d is consistent with the scripts' API conventions and breaks no consumer. The only output change is the skip reason's text. The plan's grammar reads it by its first word, and nothing outside the test reads it. main_entry's new precondition changes no current caller's output. Every deferred wording row lands as asked. Three Minor findings remain, all help or comment prose that can be fixed in place:
- F1: the cause list was not updated alongside the new sentence.
- F3: C37's insertion made the clause scoping ambiguous.
- F4: A25's asked wording was itself imprecise.

None blocks landing on API grounds. F2 is the one with a future consumer impact, and it belongs in U2's brief, not in this unit.

## Goal-Alignment Note

- Success criterion (restated verbatim): A markdown report saved to docs/reviews/api-consistency-reviewer-review-2026-10-06-build-loop-u1d.md (first line `Commit: 83cdb005`), structured per the api-consistency-reviewer skill.
- Answered: yes. Every deferred wording row is checked (table above), the help is checked for self-consistency and against dev-cycle.sh's conventions, and the main_entry contract is reviewed.
- Out of scope: the security escalation in fact-check (an empty ahead count under a broken config) belongs to security-reviewer. The test-strength gaps in Claims 14-18 and 21 belong to test-strategy.
- Escalate: F2 to the orchestrator, as a note for U2's brief.
