Commit: c10b972a
# Code Review Rubric

**Branch:** `feat/build-loop-u2b2` (U2b2: the gate's checkout, caller-contract items 2-4), on main 45ca46c3.
**Status: 🟡 ITERATION 1 — no red; nine ambers, all being fixed in iteration 1's fix commit**

## Iteration 1 (Commit c10b972a, `--loop-pass`, k=1, scope `main...HEAD`, full panel)

Delivery mode: self-read (diff saved to the scratchpad; agents read the files). Reports: `code-fact-check-report-build-loop-u2b2.md` (k=1: 20 claims, 12 Verified, 8 Mostly accurate), `security-reviewer-review-2026-10-08-build-loop-u2b2.md`, `performance-reviewer-review-2026-10-08-build-loop-u2b2.md`, `api-consistency-reviewer-review-2026-10-08-build-loop-u2b2.md`, `architecture-review-review-2026-10-08-build-loop-u2b2.md`. Architecture auto-selected (the lib's caller contract and `--check`'s grammar change); test-strategy not selected (tests in the diff). Stage 2.5 skipped (loop pass): security's two routed endorsements stay pending execution verification. No short-circuit (no behavioral red).

### 🔴 Must Fix

None.

### 🟡 Must Address

| # | Finding | Severity | Source | Considered overrides | Status |
|---|---|---|---|---|---|
| A1 | ls-tree records that miss the regex are skipped (`|| continue`); under a UTF-8 locale `.` does not match an invalid byte, so a file with a non-UTF-8 name escapes the byte check (executed: ok under C.utf8, refused under C). | Medium | security 2 | row 399 (LC_ALL=C for the walk) | Fixing: `local LC_ALL=C`, mode 120000 skipped by name, any other unmatched record refuses |
| A2 | `hash-object --stdin-paths` unquotes a name starting with `"` and drops a trailing CR, so that file's own bytes are never compared (executed with an ident expansion, status clean). | Medium | security 1; fact-check claim 4 | — | Fixing: refuse such names as newline names are |
| A3 | A gitlink path `ls -A` cannot list reads as empty (`chmod 111 sub`; the file inside is still readable by name). | Medium | security 3 | rows 366, 373 | Fixing: refuse a gitlink path that exists and cannot be listed, or is a symlink |
| A4 | The checkout refusal comes before merge_result and the N rules, so a loop's advisory `--check` of a self-merge brief (HEAD is its branch) never sees a conflict or deny line, against plan D1's advisory dry run. | Inconsistent / Coupling | api F1; architecture F2 | — | Fixing: the checkout is judged after the N rules; path and deny lines still follow the refusal |
| A5 | The checkout is checked once per run in the parent shell, while the walk (U2c) runs per brief: "final before the walk" (item 2) has no owner. | Coupling | architecture F1 | rows 439, 459 | Fixing: checkout_gate runs inside check_line, per self-merge brief, at the point U2c's floor will run |
| A6 | Empty CHECKOUT_WHY means both "passed" and "never ran"; producer and consumer use different predicates. | Minor (fail-open shape) | architecture F3; performance (out of domain note) | — | Fixing with A5 (computed where it is read) |
| A7 | The trusted GIT_* rule is written twice (gate_repo, checkout_gate) and the copies differ; both let GIT_CONFIG (a file redirect `git config` follows) through, which can switch off the core.* refusals. | Minor / Mostly accurate | architecture F5; fact-check claim 6 | row 314 (inherited GIT_DIR) | Fixing: one `callervar` predicate; GIT_CONFIG is not a caller config pair |
| A8 | Help text omits refusals (unreadable core.*, listing failures, newline names, exemptions); lib item-3 note claims all of item 2 (fsmonitor and replace refs are harden's and the state gate's; stderr is the walk's); A5's not-covered list is stale; test comment "Each index flag hides a change" (only assume-unchanged does); commit's "each refusal" tested. | Mostly accurate | fact-check claims 1, 3a, 10, 11, 18; api F2, F5; architecture F4, F6 | rows 459, 465 | Fixing (docs, comment, tests for the untested refusals) |
| A9 | Reason wording: "its HEAD/index" names the checkout where every other `refuse BRIEF` reason's "its" is the brief; "X or unreadable" folds a read failure into a refusal (the state gate keeps them apart). | Minor | api F3, F4, F6 | — | Fixing: the checkout as subject; read failures worded apart; the HEAD reason prints the actual HEAD |

### 🟢 Consider

| # | Finding | Source | Status |
|---|---|---|---|
| G1 | Hashing cost grows with tracked bytes (a 200 MB binary: ~1.1 s); ran even when every brief was review. | performance 1 (Low) | Addressed by A5 (runs only for a self-merge brief) |
| G2 | The bash read loop costs ~29 µs per tree record (1.4 s at 50k files); `ls-files --others` walks ignored trees (0.06 s at 100k). | performance 2, 3 (Informational) | Won't-Fix: under a second at this repo's scale; `--directory` would hide nested repositories |
| G3 | checkout_gate lives in the calling script, apart from the lib contract it enforces. | architecture F7 | Defer: revisit when a second floor caller appears |
| G4 | Untested bypass candidates: a FIFO at a tracked path (row 440), a dangling symlink at a gitlink path, and three more listed in the security report. | security (not tested) | Gitlink symlink folded into A3; the rest carried to iteration 2's security brief |
| G5 | Export LC_ALL=C for the whole script (contract item 1) rather than per function. | security open question | Defer to U2c, which runs the walk (row 399) |

### Considered overrides

Rows 366, 373 (nested repositories: now refused), 387 (GIT_INDEX_FILE, sparse, case-insensitive bypasses: now refused), 388 (the gate's checkout is U2b's), 391, 392, 397 (conversions, core.symlinks: this unit's target), 399 (LC_ALL=C), 439 (cache cleared per decision), 440 (FIFO start: still open), 459/465 (one numbered contract), 314 (inherited GIT_DIR), 425/431/432/437/477 (reader model: U2b3's).

### Tokens

fc 1×150k; critics 4× (security 136k, performance 82k, api 103k, architecture 130k) ≈ 600k total.
