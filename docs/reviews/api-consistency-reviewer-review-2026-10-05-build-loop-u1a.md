Commit: 722884c7

# API Consistency Review: feat/build-loop-u1a (iteration 3, final confirming pass)

**Scope:** `git diff main...feat/build-loop-u1a -- . ':!docs/reviews'` over scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh, skills/dev-cycle/SKILL.md, test/scripts/dev-cycle.bats (HEAD 722884c7)
**Date:** 2026-10-05
**Based on:** Stage-1 merged fact-check summary (k=3; docs/reviews/code-fact-check-report-build-loop-u1a-r1/-r2/-r3.md, all Commit 722884c7)

## Baseline Conventions

These are unchanged from iteration 2, and I re-checked them at 722884c7:

- Lib functions are lower snake_case. The `main_` prefix marks helpers that work on the default branch (`main_by_name`, `main_entry`). `check_*` names are the per-argument answerers.
- Each argument gets one output line. A positive answer starts with `ok` or a state word. A refusal is `skip <arg>: <reason>`. Internal tokens are short lowercase condition words (`odd N WHY`, `unbalanced N`, `dup`, `absent`, `error`).
- Globals are UPPERCASE base/suffix pairs (`SKIPPED`/`SKIP_AT`, `BRIEF`/`BRIEF_ODD`).
- The CLI `--help` prints the script's leading comment block. Main's convention is that the `sed -n '2,Np'` range ends exactly at the last comment line: main ends at line 77 and its first non-comment line is 78. A sibling avoids the hand-kept number by stopping at the first blank line (`scripts/run-tests.sh:153`: `sed -n '2,/^$/{ ... }'`).

## Name-Pattern Audit

This iteration adds no new public names; the fix commits since 2da477b7 only change wording and behaviour. Iteration 2's audit still holds:

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `main_entry` | function | `main_by_name`, `resolve_main`, `blocker` | scripts/lib/dev-cycle-read.sh:246, :107 | Consistent |
| `blob`/`absent`/`notfile`/`notdir PART`/`error` | output tokens | `absent <name>` (check_branch), `odd N WHY`, `dup` | scripts/lib/dev-cycle-read.sh FENCE_AWK/ANSWER_AWK END | Consistent (`error` was the first token for a failed git read; brief_fields now reuses it) |
| `brief_fields` | function | `imported_names`, `check_brief` | scripts/lib/dev-cycle-read.sh | Consistent |
| `BRIEF` / `BRIEF_ODD` (`odd N WHY` / `unbalanced N` / `error`) | globals and values | `SKIPPED`/`SKIP_AT`; FENCE_AWK END tokens; main_entry `error` | scripts/lib/dev-cycle-read.sh:288, :263 | Consistent |
| `nul` → "holds a NUL byte" | oddwhy reason | `cr`, `bom` | scripts/lib/dev-cycle-read.sh oddwhy | Consistent |
| check_brief `skip …: the brief could not be read from the default branch` | skip line | check_answer `skip …: $f could not be read from the default branch` | scripts/lib/dev-cycle-read.sh:341, check_answer | Consistent: the same "could not be read from the default branch" phrase |

## Findings

#### 1. `--help` drops the end of the Exit contract (help range not moved with the header)

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:111` (header ends at :81)
**Move:** 3 (documentation drift: the CLI's published contract)
**Confidence:** High (executed)
**Legibility-target:** for-author

**Evidence:**
```
    -h|--help) sed -n '2,80p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
```
```
# skip is an answer, not an error); 1 bad usage, not a git repo, no perl or lib/dev-cycle-read.sh, or no
# default branch (for the digest, --check-brief, --check-branch and --check-answer); a failed step exits non-zero mid-digest. Printed repo text is data.
```
(the second excerpt is lines :80-:81; :82 is the first non-comment line)

78703f22 fixed iteration-2 F2 by adding a line to the --check-answer help, but `2,80p` was not changed to match. Run at 722884c7, `bash scripts/dev-cycle.sh --help` ends with "…no perl or lib/dev-cycle-read.sh, or no". The output loses the no-default-branch exit clause, which is the clause this branch extended to `--check-answer` and is the new exit-1 contract consumers read. It also loses "Printed repo text is data." On main (`2,77p`, first code line 78) and at 2da477b7 (`2,80p`, first code line 81) the range covered the whole header, so this is a regression in the CLI's help surface. All three Stage-1 replicates found the same thing (Incorrect, high). No bats test covers `--help`.

**Recommendation:** Change the range to `2,81p`. To stop it drifting again, end the range at the first non-comment line, as `scripts/run-tests.sh:153` ends its help at the first blank line.

## Iteration-2 findings: status at 722884c7

- **F1, brief_fields gave no signal on a failed read: fixed (executed).** In a scratch repo under `set -euo pipefail`, I moved the brief's blob out of the object store and ran `if ! brief_fields "$b"`. It printed `rc=1 keys=0 odd=[error]`. An absent path, a pathform-refused path and `MAIN_BY_NAME=` each also give `BRIEF_ODD=error` with return 1, and the header comment at :282-286 documents this. A caller that needs to tell "absent" from "unreadable" calls main_entry first, as check_brief does at :330-337. The lib's caller contract requires pipefail, and the Stage-1 caveat (under `set -eu` alone the failure is lost) falls under that contract (lib header).
- **F2, the --check-answer help omitted the tree-read error: fixed.** Lines :70-71 now read "…or a default branch whose tree or file could not be read)". But the fix moved the header end to :81, which the help range does not reach. That is Finding 1 above.
- **F3, awk `"\0"` portability: settled.** The override-log row at :224 is Won't-Fix ("Fails closed; mawk … and gawk both read "\0" as one NUL byte"). I have no new evidence, so I am not re-raising it.

## What Looks Good

- brief_fields now uses main_entry's `error` vocabulary for every failure it can't judge, and check_brief maps it to a skip line worded like check_answer's ("could not be read from the default branch"). Route: code-fact-check (R2/A13 resolved, unanimous).
- All four places a consumer reads the `--check-answer` default-branch gate are consistent with each other: help :72-73, the Exit text :80-81 (in the file, though `--help` currently cuts it, Finding 1), the code at :187-193, and SKILL.md :292-295.
- `bats test/scripts/dev-cycle.bats`: 66/67 pass. Test 21 fails only because of the TMPDIR '.'-component artefact the orchestrator noted, so it is not a finding.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `--help` range `2,80p` cuts the header's last line (the Exit clause for a missing default branch, and "Printed repo text is data.") | Minor | `scripts/dev-cycle.sh:111` | High |

## Overall Assessment

The lib contracts that U1b/U1c will consume are now consistent: main_entry's five words, brief_fields' BRIEF/BRIEF_ODD and its return codes with a fail-closed `error`, and check_answer's output lines. Iteration 2's two open contract findings are fixed and the third is settled. One regression remains on the CLI surface: the help range was not moved when the help text grew by a line, so `--help` stops mid-sentence and drops the exit-1 clause this branch extended. It is a one-character fix with no runtime impact on the check modes. It is still a regression in a published contract, so it should be fixed before merge.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-build-loop-u1a/docs/reviews/api-consistency-reviewer-review-2026-10-05-build-loop-u1a.md (overwrite the iteration-2 one), first line `Commit: 722884c7`, structured per the api-consistency-reviewer skill, every finding with Severity, Location, verbatim Evidence, Confidence and Legibility-target, ending with the canonical Goal-Alignment Note.
- Answered: the API-consistency review at 722884c7. The status of iteration-2 F1/F2/F3 was confirmed by execution (F1 and F2 fixed, F3 settled by row :224). One new Minor finding (the `--help` truncation), which agrees with Stage 1's Incorrect claim.
- Out of scope: U1b/U1c consumers; override-log rows :220-231, which were not re-raised; security and performance aspects; the bats test 21 TMPDIR artefact.
- Escalate: Finding 1 is a regression in a published contract (Minor, one-line fix). The orchestrator decides whether it holds the merge.
