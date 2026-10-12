Commit: 4afdd68b
Loop closed at 4afdd68b

# Code Review Rubric: feat/build-loop-u3b2 (U3b2, --main-log)

**Iteration 1 of 3** · scope: full branch `main...1d829fee` (no prior rubric for this loop) · delivery mode: self-read (shared brief plus the saved diff) · fact-check k=1 (loop pass, decision 031), opus · report `docs/reviews/code-fact-check-report-2026-10-12-u3b2-i1.md` (31 claims: 24 Verified, 7 Mostly Accurate, 0 Incorrect) · critics (opus, parallel): security, performance, api-consistency, architecture (`*-2026-10-12-u3b2-i1.md`). test-strategy not selected (tests changed with the code).

Status (iteration 1): no 🔴 · 🟡 3 · 🟢 10. D1-D7 and D9 fixed in the iteration-1 fix commit (cca66dc2); D8 and D10-D13 carry override rows dated 2026-10-12. No short-circuit: fact-check found no behavioural Incorrect.

## 🔴 Must Fix

None.

## 🟡 Must Address

| ID | Finding | Source | Evidence | Status |
|---|---|---|---|---|
| D1 | An amended gate or chore merge keeps its class: git keeps both parents and the message, so a slip's files land as gate/chore (executed: exit 0) | security F1 (Medium) | `scripts/build-loop.sh` log_class, two-parent branches read only the message / record | Fixed (tree must equal merge-tree's clean merge of the parents; test; mutant killed) |
| D2 | answers passes a commit that adds no answer: a Status flip alone, a deleted answer, a revert (executed) | security F2 (Medium) | ANSWERS_AWK `n++` counted any non-blank line | Fixed (at least one added answer line; the deleted-answer test killed the mutant; the Status-flip test was empty until E1; a revert that restores an answer adds one: E2) |
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

## Iteration 2 (scope `1d829fee..cca66dc2`, loop pass, k=1)

Fact-check `docs/reviews/code-fact-check-report-2026-10-12-u3b2-i2.md`: 36 claims, 29 Verified, 5 Mostly Accurate, 2 Incorrect (rubric text; a test fixture), none behavioural, no short-circuit. Critics: security, performance, api-consistency (`*-2026-10-12-u3b2-i2.md`); architecture not rerun (no structural change in the range). Prior D1, D3-D7, D9 resolved; D2 resolved for its stated cases.

| ID | Finding | Tier | Source | Status |
|---|---|---|---|---|
| E1 | The "Status flip alone" test committed an empty diff (the flip had already happened), so it pinned nothing | 🟡 | fact-check claim (Incorrect, test) | Fixed (flip before the route change; the four answers near-miss commits asserted non-empty) |
| E2 | Any added answer label counts: a loop answering an agent entry, a revert, an answer moved between entries read answers | 🟡 (Medium) | security i2 F1 | Won't-Fix (row: F19; U4 lists answers commits); comment corrected |
| E3 | Rubric status line miscounted | 🟢 | fact-check (Incorrect, text) | Fixed |
| E4 | merge-tree ran on every merge before the subject could match (+1.5 s on this repo's history; all its store writes) | 🟢 (Low) | performance i2 1 | Fixed (clean_merge after the subject) |
| E5 | Store writes undocumented; large-rename cost | 🟢 | performance i2 2, 3; security i2 F2 | Fixed (header) + Defer (row) |
| E6 | Default-merge qualifier missing from the hand-off and header | 🟢 | api i2 2; fact-check 20 | Fixed (text, row 719) |
| E7 | No bootstrap SINCE for U4's first iteration | 🟢 | api i2 1 | Fixed (plan note, row 726) |
| E8 | `-` subject ambiguity; a failed read printed an empty subject; "objects below MAIN" wording; timing ~8 s | 🟢 | api i2 3, 4; fact-check | Fixed (header caveat, SUBJ=- first, text, row) |

## Final confirming pass (full branch `main...4afdd68b`, k=3, full panel, Stage 2.5)

Fact-check merged `docs/reviews/code-fact-check-report-2026-10-12-u3b2-final.md` (replicates r1-r3): 52 claims, 43 Verified, 7 Mostly Accurate, 2 Incorrect (both override-row text), 82.7% agreement; no behavioural Incorrect. Critics (opus, parallel): security (no finding), performance (1 Informational), api-consistency (1 Minor, 1 Informational), architecture (1 Minor, 2 Informational). Stage 2.5 (`code-fact-check-submitted-claims-2026-10-12-u3b2-final.md`, appended to the merged report): 4 routed claims → 3 Verified (chore-subject non-clean merges and NUL/VT/100755 answers-shaped commits read other; E4 restored the pre-D1 time with 0 store writes), 1 Mostly Accurate (a 10-commit window ~0.38 s), 1 Incorrect (security's octopus citation: the parent count rejects it, not clean_merge; outcome right, no code change). Prior D/E rows: resolved or ruled; none reopened.

| ID | Finding | Tier | Source | Status |
|---|---|---|---|---|
| G1 | Row 726 "every commit reads other" (dfe4c0df reads answers); row 728 "87 objects" was the pre-E4 figure | 🟡 (text) | fact-check claims 19a, 21b (Incorrect) | Fixed (rows) |
| G2 | The per-hunk header-match rule was unpinned: the route-change near miss lacked an answer line | 🟡 (test) | fact-check claim 43; escalation 1 | Fixed (it adds one; a mutant skipping header lines is killed) |
| G3 | clean_merge's comment: only conflicting or hand-resolved merges add objects (also -s/-X/config); rename-cost row wording; row 728's trigger fires on any root-SINCE run | 🟢 | fact-check 21a, 21c, 38; performance final 1 | Fixed (comment, row, trigger: one clean_merge over 1 s) |
| G4 | A failed tac would print the main line, no class lines, and exit 0 | 🟢 | security final (untested candidate) | Fixed (tac to a file, refused on failure) |
| G5 | clean_merge and merge_result derive the tree twice; clean_merge read log_class's locals | 🟢 (Minor) | architecture final 1, 2 | Fixed (arguments, comments both ways) + Defer (row: unify at the next merge_result change) |
| G6 | The D6 labels-fragment deferral had no row | 🟢 | architecture final 3 | Fixed (row) |
| G7 | Which Main at: line is SINCE; Main at: reused after decision row 68; plan typo | 🟢 (Minor) | api-consistency final 1, 2 | Fixed (plan text) + Defer (row; U4) |
| G8 | Commit messages 1d829fee (blank lines omitted), 4afdd68b ("every near-miss", ~1.5 s) | 🟢 | fact-check 45, 47 | Corrected in the merge message |
| G9 | The "git's defaults" list is not proven complete | 🟢 | escalation 2 | Accepted: any divergence makes an honest merge read other (fails closed; row 719 names the defaults) |

Status (final): no 🔴; the 🟡 items G1 and G2 were fixed after the pass (text and one test line), with a lite check over the fix batch.

Single-sample review; absence of findings is not an attestation.
