Commit: fa2dcfc8
# Code Review Rubric

**Scope:** feat/out-of-loop-landings, `git diff 977c3f70...fa2dcfc8` (ded4a73d, fa2dcfc8) | **Reviewed:** 2026-11-20 | **Status:** iteration 1: 🔴 DOES NOT PASS (1 red); fixed in 14f0e543; iteration 2 (narrow re-review of 14f0e543) held R1 and A1-A12 and added A13, C20, C21

Pipeline: code-fact-check k=3 (opus) → security, performance, api-consistency, architecture (opus, parallel) → submitted-claims fact-check (8 routed endorsements) → executable-defect runs X1–X3 (fixture repos in the review's scratch dir). Delivery mode: inline-diff-only. Run by a read-only review subagent; the author saved this file and filled Status and Author note.

## 🔴 Must Fix

| ID | Finding | Domain | Severity | Source | Location | Status | Author note |
|---|---|---|---|---|---|---|---|
| R1 | The endorsement "honest local git config leaves 6b unchanged" is refuted for `i18n.logOutputEncoding`, which `HARDEN` does not pin (`scripts/lib/dev-cycle-read.sh:335`). The digest's `gate_git` runs in the checkout (`scripts/lib/landings.sh:16-21`). Executed with `UTF-16`: NUL warnings in 6b, a subject cut short, a merge's `stale` line gone with no `unread` line (H2). | Security / Reliability (H2) | Incorrect (high), behavioral | security endorsement, refuted by fact-check (executed) | `landings.sh:16-21,66`; `rubric-check.sh:283` | Fixed | `gate_git` runs `git -c i18n.logOutputEncoding=UTF-8`; bats "a repo-local log output encoding changes nothing in the section" fails without the pin (checked) and passes with it. FP-188. |

## 🟡 Must Address

| ID | Finding | Domain | Severity | Source | Status | Author note |
|---|---|---|---|---|---|---|
| A1 | `landings.sh:56` says a root commit's rubric fix count is taken "with itself"; it never is: `rev-list -1 C ^C` is empty, so it always prints `unread ... could not be listed`. `rubric-check.sh:233` has the same gap. | Docs / Correctness | Incorrect (high), comment-only | Fact-check | Fixed | Both comments now say a root commit's stale count prints unread (H2-safe). |
| A2 | `landings.sh:39-42` says each landing prints "open and unread rows, or why none was read"; every `rubric_lines` line prints, `clean`, `stale` and `superseded` too. | Docs | Mostly accurate | Fact-check | Fixed | Header lists every line kind. |
| A3 | `SKILL.md:579`'s "(open rows, `unread` or `none`)" omits `stale`, `clean` and `superseded`; a cycle could drop a `stale` line. | Docs / Skill contract | Mostly accurate | Fact-check + api-consistency F3 | Fixed | Step 4 lists all six kinds and says to quote every line. |
| A4 | Test name and research doc claim a subject naming the trailer is listed; a subject *starting* `Build-loop-gate: x` was skipped (executed X1). | Docs / Tests | Mostly accurate (executed) | Fact-check + X1 | Fixed | The match is now line 3 after a blank line 2 (gate_msg's position); bats case covers subject start, mid-subject and quoted body. |
| A5 | `rubric-check.sh:8-9` credits landings.sh with MAIN_SHA and check_answer, which come from the reader lib. | Docs | Mostly accurate | Fact-check + api F10 | Fixed | Comment names which lib gives which name. |
| A6 | Research doc's "adds about 3 s" is the whole digest; the section adds about 0.5 to 1.6 s. | Docs | Mostly accurate | Fact-check + performance F1 | Fixed | Corrected in the research doc's Cost section. |
| A7 | A code commit dated before the window and fast-forwarded onto main is never listed: the window keys on each commit's own `%cs` (executed X3). | Security (detection gap) | Medium | security B1 + X3 | Deferred | Revisit trigger in the research doc: if `--main-log`'s `other` lines show a code commit dated before the window, key 6b on reachability from the last `Main at:`. Main is never fast-forwarded with code by pr-prep's rule, and the four fast-forwards since 21097afa were docs-only. |
| A8 | Any `Build-loop-gate: X` line in a merge message dropped the merge, including a quoted one in the body (executed X2). | Security (detection gap) | Medium | security B1 + X2 | Fixed | As A4: only line 3 after a blank line 2 counts; bats case. |
| A9 | `fp_blob` and `showpath` in landings.sh are copies of build-loop.sh's. | Architecture | Coupling | architecture 1 | Fixed | Bats case "fp_blob and showpath are the same as build-loop.sh's" holds them equal; moving them to one lib is a TODO in the research doc for a build-loop unit (it edits build-loop.sh, out of this brief's scope). |
| A10 | landings.sh is a third reader of the trailer, and `gate_msg`'s comment names only `log_class`. | Architecture | Coupling | architecture 2 | Deferred | TODO in landings.sh's header (name this reader in gate_msg's comment: build-loop.sh is out of scope here); the header also states that a `--land-cycle` merge never reaches the check. |
| A11 | Step 4 has no record form for **Out-of-loop landings were NOT checked**, so it would be recorded as 0 and count toward removal. | API / Skill contract | Inconsistent | api F1 | Fixed | Step 4: such a section records `not checked: why`, never a 0. |
| A12 | The ten-zero removal rule cannot be evaluated: step 4 may not read old records, and the count was of items filed after the SHA dedupe. | API / Skill contract | Inconsistent | api F2 | Fixed | The `4.` line records `N listed, K filed`; the rule reads `0 listed` over the last ten days' records, and the record rules now let step 4 read them. |
| A13 | Iteration 2: the removal rule (`SKILL.md:586-588`) could fire on one block, or vacuously when no block carries the field. | API / Skill contract | Soundness | iteration 2 re-review | Fixed | The rule now needs at least ten full blocks that carry the field, on ten different days, all `0 listed`; with fewer it keeps the step. Fixed in 41542cf0; 020cb6c8 then made it read the latest block of each of the last ten days, since "every block ever" could never fire again after one landing (author check). |

## 🟢 Consider

| ID | Finding | Source | Severity | Status |
|---|---|---|---|---|
| C1 | One `diff-tree` per commit in the window; a single `git log --name-status -z` pass would be faster. | performance 1 | Low | Open |
| C2 | `$(showpath ...)` forks per code path. | performance 3 | Informational | Open |
| C3 | `qdone` cache is per `rubric_lines` call. | performance 4 | Informational | Open |
| C4 | `dev-cycle.sh` restates the section-3 EXIT trap body. | architecture 3 | Minor | Open |
| C5 | Three rules for "code" in one digest (6b's four dirs, rubric_lines' outside-docs, section 6's). | architecture 5 + api F5 | Minor | Open |
| C6 | The parser's documented over-report now lands in filed items. | api F4 | Minor | Fixed (step 4 tells the review to read the row) |
| C7 | The `4.` line field had no `;` separator. | api F6 | Minor | Fixed |
| C8 | Filed item did not use the `**Agent: TITLE**` form. | api F7 | Minor | Fixed |
| C9 | 12-character SHAs where other sections print `%h`. | api F8 | Informational | Open |
| C10 | `Not read` lines are uncapped. | api F9 | Informational | Open |
| C11 | `gate_git` keeps build-loop's name, not its isolation. | api F12 + security 3 | Informational | Fixed (comment says so) |
| C12 | Subjects and Status cells go into roadmap items. | security 4 | Informational | Fixed (step 4: quoted as data) |
| C13 | A hand merge whose subject starts `fix` counts itself and reads `stale`. | security 5 | Informational | Open |
| C14 | With no default branch by name, qref rows stay open. | security 6 | Informational | Open |
| C15 | `rubric_lines`' BRIEF/BRANCH names assume a build-loop branch. | architecture 6 | Informational | Open |
| C16 | `dev-cycle.sh` grew 746 → 765 lines; the lib check is written three times. | architecture 7 | Informational | Open |
| C17 | Research doc's "(found by the tests)" has no trace in history. | Fact-check | Unverifiable | Fixed (reworded) |
| C18 | The message guard covers octopus merges too. | Fact-check | Mostly accurate | Open |
| C19 | Brief Status line still to flip. | architecture | Informational | Open (the final commit flips it) |
| C20 | A7 and A10 are Deferred but have no override-log row. | iteration 2 | Informational | Open (each Author note carries its reason and a trigger or TODO, which rubric.md accepts where the log is not edited; the log is not in this brief's scope) |
| C21 | A CRLF build-loop merge message would be listed. It only over-lists, and gate_msg never writes CR. | iteration 2 | Informational | Open |
