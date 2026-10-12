Commit: 1d829fee

# Code Review Rubric: feat/build-loop-u3b2 (U3b2, --main-log)

**Iteration 1 of 3** · scope: full branch `main...1d829fee` (no prior rubric for this loop) · delivery mode: self-read (shared brief plus the saved diff) · fact-check k=1 (loop pass, decision 031), opus · report `docs/reviews/code-fact-check-report-2026-10-12-u3b2-i1.md` (31 claims: 24 Verified, 7 Mostly Accurate, 0 Incorrect) · critics (opus, parallel): security, performance, api-consistency, architecture (`*-2026-10-12-u3b2-i1.md`). test-strategy not selected (tests changed with the code).

Status (iteration 1): no 🔴 · 🟡 3 · 🟢 9. D1-D5 and D9 fixed in the iteration-1 fix commit; the rest carry override rows dated 2026-10-12. No short-circuit: fact-check found no behavioural Incorrect.

## 🔴 Must Fix

None.

## 🟡 Must Address

| ID | Finding | Source | Evidence | Status |
|---|---|---|---|---|
| D1 | An amended gate or chore merge keeps its class: git keeps both parents and the message, so a slip's files land as gate/chore (executed: exit 0) | security F1 (Medium) | `scripts/build-loop.sh` log_class, two-parent branches read only the message / record | Fixed (tree must equal merge-tree's clean merge of the parents; test; mutant killed) |
| D2 | answers passes a commit that adds no answer: a Status flip alone, a deleted answer, a revert (executed) | security F2 (Medium) | ANSWERS_AWK `n++` counted any non-blank line | Fixed (at least one added answer line; tests; mutant killed) |
| D3 | The U4 hand-off text omitted the subject tail rule, mode 100644 (not "regular"), and that a short SINCE is usage (exit 1) | api-consistency 2; fact-check claims 2, 6, 8, 11b, 12 (Mostly Accurate) | header, plan note, row 719 | Fixed (text) |

## 🟢 Consider

| ID | Finding | Source | Status |
|---|---|---|---|
| D4 | No main SHA printed before a refusal (row 700 relies on --main-log for it) | api-consistency 1 | Fixed (`main MAIN -` first) |
| D5 | "only main's tip tree is re-hashed"; "its objects are not re-hashed" (MAIN itself is) | fact-check claims 4, 16 | Fixed (row and header text) |
| D6 | Answer labels copied from the lib's ANSWER_AWK with no back-pointer | architecture 1 | Fixed (comments both ways); shared fragment deferred with D8 |
| D7 | gate_msg's shape parsed a second time by the reader | architecture 4 | Fixed (comment on gate_msg) |
| D8 | Three diff-tree --raw readers | architecture 2 | Defer (row; U3c) |
| D9 | Empty subject printed as a trailing space | api-consistency 3 | Fixed (`-`) |
| D10 | Record name pattern wider than the lib's; one record per day gathers several Branch: lines | architecture 3, api-consistency 4 | Defer (row; U4) + hand-off text |
| D11 | Chore merge's other paths unread | security F3 (Low) | Defer (row; U3c/U4) |
| D12 | Caller git -c pairs unchecked in --main-log | security F4 | Won't-Fix (row; U3b1's design) |
| D13 | This repo's practice reads all other; per-commit cost; double state_start | architecture 5, performance 1-2 | Defer (row; U4) |

Considered overrides: rows 662 (discharged here), 690 (startup size; state_start reused whole), 700 (--main-log names main's SHA: now also before a refusal).

Single-sample review; absence of findings is not an attestation.
