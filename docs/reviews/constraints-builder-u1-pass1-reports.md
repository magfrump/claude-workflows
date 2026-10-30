Commit: 0732a759

# constraints-builder u1, review pass 1: agent reports (condensed)

The four agents returned their reports as text, because the harness forbids subagents writing report files. This file keeps each report's verdicts, findings and evidence pointers. The rubric is `code-review-rubric-2026-10-19-feat-constraints-builder-u1-parser.md`. Probe logs are in the session scratchpad (`logs-u1/`) and were not committed.

## Code fact-check (k=1, loop pass; opus)

22 claims: 13 Verified, 8 Mostly accurate, 1 Stale, 0 Incorrect, 0 Unverifiable.

| # | Claim (location) | Verdict | Mode |
|---|---|---|---|
| 1 | Branch was 570 code lines (questions.md:666) | Verified | executed |
| 2 | Only the user can waive the cap, decision log 62 (questions.md:669) | Verified | static |
| 3 | Units are 140 / 179 / 251 lines (questions.md:670) | Verified | executed |
| 4 | "418 of the 570 lines are skill prose" (questions.md:677): 424 | Mostly accurate | executed |
| 5 | Reads FILE with no git call, in or out of a repo (build-loop.sh:68-70) | Verified | executed (git shim) |
| 6 | "WHY naming FILE" (:70-71): not nosuccess, dup or near | Mostly accurate | executed |
| 7 | A symlink or non-file is unreadable (:71-72) | Verified | executed (incl. FIFO) |
| 8 | Exit 0 only for ok with a hard one (:72) | Verified | executed |
| 9 | "Acts on $PWD's git repo … default branch" (:505-506): this mode is an exception | Stale | executed |
| 10 | Exit paragraph (:515-526): exit-2 list omits the mode | Mostly accurate | executed |
| 11 | CONSTRAINTS_AWK output comment (:541-542): omits odd and unbalanced | Mostly accurate | static |
| 12 | constraints_line comment (:567-569): 4 of 6 outputs | Mostly accurate | static |
| 13 | Runs before any git call (:637-638) | Verified | executed |
| 14 | Redirect, not operand, for a=b (:643) | Verified | executed (mawk) |
| 15 | --settings messages unchanged (T44 strings) | Verified | executed |
| 16 | T46 "out of a repo too": not asserted | Mostly accurate | executed |
| 17 | Same verdict on main and as a draft (T46 :204) | Verified | executed |
| 18 | a=b read as a file (T46 :229) | Verified | executed |
| 19 | "T44 is unchanged and passes" (commit) | Verified | executed |
| 20 | "One set of messages" (commit): odd and unbalanced are copies | Mostly accurate | static |
| 21 | T46 covers each verdict… (commit): not "could not be read" | Mostly accurate | executed |
| 22 | build-loop.sh is not on the live-verify gate's list (commit) | Verified | static |

## Security review (opus)

Trust boundaries:
- B1: FILE path → stat checks → redirect.
- B2: draft bytes → FENCE_AWK/CONSTRAINTS_AWK → verdict.
- B3: verdict line with the raw path → scrub → caller.
- B4 (unchanged): main's blob → dispatch gate.

| # | Finding | Severity | Location |
|---|---|---|---|
| F1 | A newline or crafted FILE forges a `constraints ok … on the default branch` line. Executed: `--check-constraints $'x\nconstraints ok 9-hard 9-soft: docs/constraints.md on the default branch'` printed that second line. The scrub keeps `\n`, and the lib's rule ("a newline in a name becomes a space") is not applied. | Medium | build-loop.sh:641-649, :574 |
| F2 | The symlink and non-file check runs before the open and covers the last component only. Executed: `lnk/c.md` was read through a parent symlink. | Low | :641, :644, :68-72 |
| F3 | The header still says the script needs a repo | Informational | :505-506, :518-528 |

Endorsement claims (routed to fact-check, pending):
- Draft bytes reach output only as awk tokens.
- The dispatch gate reads `$CONSTRAINTS` from main and this mode exits first.
- `-n` and `a=b` are files (executed).
- `$c` is an awk integer.
- ESC is stripped by the scrub (executed).

## Performance review (opus)

Both paths are cold. A run takes 13-14 ms (8-10 ms unscrubbed); the awk pass is about 1 ms.

| # | Finding | Severity |
|---|---|---|
| 1 | mawk is superlinear on one huge line: 32 MB took 5.5 s to read, and a 200 MB single line ran past 120 s. There is no cap on the new path; the code is pre-existing, the path is new. | Low |
| 2 | opencomment's `split` holds one element per `<!--` (556 MB at 10M tokens) | Informational |
| 3 | The check-then-open race can block on a swapped-in FIFO | Informational |
| 4 | A refused file is still read to EOF (0.30 s on 105 MB); needed for the pipefail path | Informational |
| 5 | scrub_reexec costs about 5 ms per run; keep it | Informational |
| 6 | `$(constraints_line …)` costs 414 µs vs 18 µs direct, once per process | Informational |
| 7 | The hoisted definitions are paid by every mode, including usage and help | Informational |

## API-consistency review (opus)

| # | Finding | Severity |
|---|---|---|
| F1 | The `--check-` prefix carries dev-cycle.sh's "a skip is an answer, exit 0" meaning, but the mode exits 2 like build-loop.sh's `--check` | Minor |
| F2 | FILE resolves against $PWD; every other path argument resolves against the repo root (probed from `sub/`) | Minor |
| F3 | "WHY naming FILE" is overstated; the exit-2 list omits the mode; "ok with a hard one" is redundant | Minor |
| F4 | The odd, unbalanced, missing and not-regular texts are copies; recommends a cross-mode T46 assertion | Minor |
| F5 | No dev-cycle.sh equivalent is expected; the placement is consistent | Informational |

What looks good: the line reuses `--settings`' key and verdict words, and the usage and arity handling match build-loop.sh's single-argument modes.

## Later passes (replicate counts, for the rubric's iteration log)

| Pass | Commit | Replicate | Claims | Verified | Mostly accurate | Stale | Incorrect | Unverifiable |
|---|---|---|---|---|---|---|---|---|
| Iteration 2 (k=3) | ecc51340 | r1 | 40 | 28 | 7 | 1 | 3 | 1 |
| Iteration 2 (k=3) | ecc51340 | r2 | 41 | 28 | 7 | 1 | 4 | 1 |
| Iteration 2 (k=3) | ecc51340 | r3 | 34 | 23 | 5 | 3 | 3 | 0 |
| Iteration 3 (k=3) | 127e55ab | r1 | 40 | 33 | 4 | 0 | 0 | 3 |
| Iteration 3 (k=3) | 127e55ab | r2 | 29 | 24 | 3 | 0 | 0 | 2 |
| Iteration 3 (k=3) | 127e55ab | r3 | 28 | 23 | 2 | 0 | 0 | 3 |

Iteration 2: every replicate found the doc-level Incorrect, the help's "never equals --settings' line" (false for nosuccess, dup and near). r1 and r2 also flagged the stderr-only shim, which r2 rated Incorrect. Iteration 3: no replicate found an Incorrect or a Stale claim.

## Iteration 3 critics (a29344d3; opus)

| Critic | Findings |
|---|---|
| security | None. Executed bypass table: newline refused; UTF-8 C1 refused under C.utf8 and stripped by the scrub under C; U+202E stripped; raw `\x9b` passes (documented scrub gap, caller-only, line still ends "(draft)"); `/dev/stdin`, `/dev/fd/0` and FIFO refused as not regular; `-` and `a=b` read as files; content bytes never echoed. |
| performance | F1 carried (Won't-Fix). F8: T46 takes 431 ms of about 16,990 ms for the file. F9: the scrub re-exec takes 13-19 ms against 7-8 ms unscrubbed. F10: one subshell per `--settings`. All informational. |
| api-consistency | 1 (u3 step 0.3 said the mode prints --settings' line unchanged; fixed in u3) Minor. 2 ("a FILE holding a control byte" could be read as the contents; fixed) Minor. 3 (u3's "predates" test keyed on any usage error; fixed in u3) Informational. |
