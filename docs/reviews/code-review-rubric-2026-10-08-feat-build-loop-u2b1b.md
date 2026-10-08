Commit: a382a3f8
# Code Review Rubric

**Branch:** `feat/build-loop-u2b1b` (U2b1b: `--check`'s changed-path lines and N rules, plus U2b1a2's carried R6, R7, R9, A15, A17, A19), on main 0e4596ce.
**Status: 🟡 ITERATION 2 — no red, no behavioral amber; wording fixed in batch 2; final confirming pass next** (single-sample review; absence of findings is not an attestation)

## Iteration 2 of 3 (Commit a382a3f8, `--loop-pass`, k=1, scope `809df345..a382a3f8`, incremental)

Reports: `code-fact-check-report-build-loop-u2b1b-i2.md` (30 claims: 25 Verified, 5 Mostly accurate, 0 Incorrect; the missing-blob mutant fails R6; six merge-tree probes match a382a3f8's correction paragraph), `security-reviewer-review-2026-10-08-build-loop-u2b1b-i2.md`, `performance-reviewer-review-2026-10-08-build-loop-u2b1b-i2.md`, `api-consistency-reviewer-review-2026-10-08-build-loop-u2b1b-i2.md`, `architecture-review-review-2026-10-08-build-loop-u2b1b-i2.md`. Prior items verified: security F1, F2; performance F1 (5,000 paths 13,460 ms → about 1,340 ms); api 1-3; architecture 1, 2, 5: all resolved. No re-fire.

### 🔴 Must Fix

None.

### 🟡 Must Address

| # | Finding | Severity | Source | Status |
|---|---|---|---|---|
| B1 | Wording (Mostly accurate): A16 pinned only jointly (test comment); "which security F2 now refuses" covers blobs, not subtrees (diff-tree refuses those); own_blob "Returns 1"; "a tr per path cost 2.5 ms"; "every new file" means regular files. | Mostly accurate | fact-check i2 1-5 | Fixed in batch 2 (comments; the a382a3f8 message's subtree point is corrected in batch 2's message); the joint pin: Won't-Fix row |

### 🟢 Consider

| # | Finding | Source | Status |
|---|---|---|---|
| D1 | nrules depends on truthrule's word order (instr and dot tested before cycle); fails open if a future word shadows cycle. | architecture i2 1, security i2 2 | Fixed: the invariant is stated in nrules and in truthrule's comment, which names the N rules as a consumer; T14 pins today's families |
| D2 | Plan F12 and the `--state` line lag the code (subtrees, constraints, default_gate). | architecture i2 2, api i2 2 | Fixed in the plan |
| D3 | Help: "(a .git part included)" understates pathform; the refusal said "a file" where the help says a blob, and filed it under "could not be computed"; a wrong-typed object reads as missing. | api i2 1, 3; security i2 1 | Fixed: help and message say "names a blob the object store lacks" (absent, or not a blob), as its own case |
| D4 | default_gate printing both findings has no test. | fact-check i2, api i2 | Fixed: R7 test writes a master ref naming a tree |
| D5 | The K-of-N line names TIP, sibling refusals a branch. | api i2 4 | Won't-Fix (row) |
| D6 | Row 509's surface omits `git/refs/` and `git/HEAD`; check_line's phases and nrules' seven arguments; floor on already-denied paths. | fact-check i2, architecture i2 3, 4 | Rows 509, 512, 517 updated |
| D7 | Prices: truthrule per path, the batch-check, linear at 0.25 ms per path. | performance i2 F1, F2 | Won't-Fix (row) |

## Iteration 1 of 3 (Commit 809df345, `--loop-pass`, k=1, full branch: no prior rubric)

Delivery mode: self-read (each agent read the shared brief, its skill file and the diff from disk; a deviation from the inline prefix, chosen to keep the orchestrator's context small). Reports: `code-fact-check-report-build-loop-u2b1b.md` (43 claims: 35 Verified, 8 Mostly accurate, 0 Incorrect; executed: suites, five probes, seven mutants), `security-reviewer-review-2026-10-08-build-loop-u2b1b.md`, `performance-reviewer-review-2026-10-08-build-loop-u2b1b.md`, `api-consistency-reviewer-review-2026-10-08-build-loop-u2b1b.md`, `architecture-review-review-2026-10-08-build-loop-u2b1b.md`. No short-circuit (no behavioral red). Stage 2.5 skipped (loop pass): four security endorsement claims stay pending execution verification.

### 🔴 Must Fix

None.

### 🟡 Must Address

| # | Finding | Severity | Source | Status |
|---|---|---|---|---|
| A1 | The cycle-owned set has three definitions (`writable`, `truthrule`'s cycle/settings/user words, nrules `build-loop.sh:549-550`); the constraints reason is duplicated with floor. | Coupling (High) | architecture 1 | Fixed (fix batch 1): nrules reads truthrule's cycle, settings and user words (one source for the named files, and the floor's constraints reason wording); the briefs/ and cycles/ subtrees stay an N-only widening, named in nrules' comment |
| A2 | Lib header contract item 5 (`dev-cycle-read.sh:59-63`) says floor runs before pathform so `.github/x.yml` reads as a dotfile; nrules now refuses it as a path form first under both policies. | Coupling (High) | architecture 2 | Fixed: item 5 now says the N rules run pathform first under both policies |
| A3 | check_line is the whole per-brief pipeline and returns only printed text; U3's `--merge` needs TIP, TREE and the verdict as values. | Coupling (Medium) | architecture 3 | Deferred (override row, trigger U3 --merge) |
| A4 | Doc wording (fact-check Mostly accurate): commit cc9b69d3's "exit 0" / "fatal" probe claims (37a, 37b); override row 511 "stay with the F3 row" (6b); state_gate comment "merge and diff drivers" (16); nrules "compare lower-cased" (21); the path-form and mode deny reasons (22, also api 3); test names T14 "in any case" (26) and T12 "either side" (29). | Mostly accurate | fact-check 6b, 16, 21, 22, 26, 29, 37a, 37b; api 3 | Fixed: reasons, comments, row 511, test names (T14 adds Questions.md and CONSTRAINTS.md; T12 adds an old-side gitlink); 37a/37b corrected in the fix commit body |
| A5 | Unpinned: the NUL-count completeness check, A16 (diff-tree in the gate repo under `submodule.<name>.ignore=all`), each R6 guard alone. | Test gap | fact-check escalations | A16 pinned (T12 under ignore=all; mutant fails); NUL check and single R6 guards: Won't-Fix rows |

### 🟢 Consider

| # | Finding | Source | Status |
|---|---|---|---|
| C1 | own_blob's exit status is ignored: if its second read fails, hash-object prints the empty-blob id and a branch that empties its brief passes (hostile-loop: needs the object deleted between reads). | security F1 (Low) | Fixed (own_blob exit status checked; no race test, row) |
| C2 | A merge whose tree references a missing blob prints ok (honest-path robustness; U3 would land an uncheckable tree). | security F2 (Low), fact-check escalation | Fixed: one cat-file --batch-check over every new regular file; test (mutant fails) |
| C3 | `lower` forks per path: 2.5 ms/path, 13.5 s at 5,000 paths; one batch lower measured 1.2 s. | performance F1 (Low) | Fixed: one lower_all pass per brief |
| C4 | The refusing verdict line lacks TIP and TREE, which D4/F48's merge entry needs. | api 1 (Minor) | Fixed: "... refused in the merge of TIP (tree TREE)" |
| C5 | The R7 check sits outside state_gate: stops at the first finding, a second name for origin/HEAD, not part of the planned `--state`. | api 2, architecture 5 | Fixed: default_gate prints every finding, beside state_gate for U3b's --state |
| C6 | own_blob repeats brief_fields' Status-line awk (fails closed on drift); check_line reads the lib's NAMECHARS for its display rule. | architecture 4, 6 | Won't-Fix (row) |
| C7 | merge-base --all repeats merge-tree's walk under commitGraph=false: 50 ms at 20,000 commits, 306 ms at 100,000. | performance F2 | Priced in row 511; guard kept |
| C8 | U2b1b adds `$GATE_TMP/err` and `$GATE_TMP/diff` to R8's surface; row 494's "the gate repository closes merge-tree" holds only against state planted before the run. | security F3, architecture 9 | Rows 494 and 509 reworded; R8 residual |
| C9 | Informational: U2c's floor call will run inside check_line's subshell (walk once in the parent); gate_git's code 3 folds into failure and shares one err file; `--status` has no default-branch refusal. | architecture 7, 8; api 4 | Deferred (row, triggers U2c and U3b) |

### R8 decision

**Decided: Q-103 residual** (security and architecture concur; row 509, plan step 13): a same-uid writer racing GATE_TMP is the deliberately hostile loop the plan scopes out; no in-script measure stops the same uid, and that writer has cheaper routes (config after the state gate, row 494; the object store, row 492; moving main itself). Conditions: reword row 494, list GATE_TMP's five files in the residual, revisit at U3b `--state`, U3 `--merge`, or a move of the gate to another uid or sandbox.

## ⏭️ Skipped Core Critics

None. Contextual: test-strategy not selected (tests changed with the code; the fact-check's test-gap escalations stand in for it).

## Considered overrides

Rows 497 and 507-511 (this unit's carried rows, resolved on the branch); row 494 (F7, config planted after the state gate; R8's wording); row 492 (rewritten objects; A17's object sources); row 474 (floor covers D5 items 1-4, mode rule to the caller: now built as an N rule).

## 🧩 Composition check

- `build-loop.sh:512-521` (merge_result) + `:578-593` (check_line): fact-check 37b, security F2 → composed? No: distinct sources state the same mechanism and fix completely (missing blob passed by id prints ok); `distinct defects` by construction — one defect, already stated whole (C2).
- `build-loop.sh:527-533, :547` (own_blob): security F1, architecture 4 → distinct defects (exit status vs duplicated parser).
- `build-loop.sh:241-253` (R7): api 2, architecture 5 → one finding stated whole (C5).
- `build-loop.sh:544-551` (nrules): architecture 1, fact-check 21/22, api 3, performance F1 → distinct defects (definition duplication, wording, cost).
