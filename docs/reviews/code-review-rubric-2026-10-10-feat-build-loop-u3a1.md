Commit: 65007bf8
# Code Review Rubric

**Branch:** `feat/build-loop-u3a1` (U3a1: --check re-hashes main's and the merge's objects; status as values; gate_start), on main d5736445.
**Status: 🔴 ITERATION 1 (`--loop-pass`, k=1, full panel, scope `main...65007bf8`) — 1 Must Fix (security F1), fixed in the commit after 65007bf8 (unreviewed at this stamp).**

## Iteration 1 (Commit 65007bf8, `--loop-pass`, k=1, scope `main...HEAD`, full panel)

Delivery mode: inline-diff-only (agents read the saved diff and a shared brief). Fact-check k=1 (`code-fact-check-report-build-loop-u3a1.md`): 22 claims, 17 Verified, 3 Mostly accurate, 2 Stale, 0 Incorrect; executed the suites (144/144, 20/20), store_check's failure paths and --status byte-identity over 14 briefs. Critics (opus, parallel): security (1 High, 1 Low, 1 Info), performance (2 Low, 1 Info), api-consistency (2 Minor, 4 Info), architecture (5 Minor, 1 Info) (`*-review-2026-10-10-build-loop-u3a1.md`). No short-circuit (no behavioral red at fact-check). Stage 2.5 skipped (loop pass).

Considered overrides: rows 492, 503 (this unit's threat model), 496, 512, 525, 625 (the refactor's triggers). No settled Won't-Fix re-fired.

### 🔴 Must Fix

| # | Finding | Source | Status |
|---|---|---|---|
| A1 | store_check verified by id through `cat-file --batch` while brief_fields read `MAIN:PATH`; with a second pack holding forged bytes under the brief's id, the two reads took different copies: the gate printed ok for a forged `Branch: feat/y` (reproduced 5/5). | security F1 (High) | Fixed: store_check refuses any checked id with a second copy (each pack index via show-index, and loose files); the state gate refuses `objects/info/alternates`. Tests: a second pack and a loose copy of main's and of the tip's blobs, in SHA-1 and SHA-256. Fixing it found A2. |
| A2 | (found while fixing A1) `awk 'NR == FNR'` over an empty checked file reads stdin as the first file, so the first store_check would have verified nothing. | orchestrator, while fixing | Fixed: `FILENAME != "-"`; perl fails when it reads no object (REV^{tree} is never skipped). |

### 🟡 Must Address
None.

### 🟢 Consider

| # | Finding | Source | Status |
|---|---|---|---|
| C1 | Objects reached only through history (tip's parent, check_branch's commits, merge bases) are not re-hashed. | security F2; fact-check 9 | Comment narrowed; row (Q-103 residual). |
| C2 | Per-brief store_check re-read main's shared objects (0.24 s per brief). | performance F1 | Fixed: ids already checked are skipped. |
| C3 | Cost scales with main's bytes; perl memory per object. | performance F2, F3 | Rows. |
| C4 | Per-brief refusal wording ("feat/x's tip") off-pattern. | api 1 | Fixed: "an object of the tip of BRANCH or of the merge ...". |
| C5 | STATUS and BRIEF value shapes; BRIEF kept a previous brief's fields on new/skip paths. | api 2, 4; architecture 3, 4 | Fixed: status_fields empties BRIEF; comment states shapes. STATUS[result] rowed. |
| C6 | Startup split by two `MODE == check` tests, one negative; no test pins store_check before the first blob read. | architecture 1 | Fixed: one GATE flag; the A15 call-log test now pins `cat-file --batch` before the first `cat-file blob`. |
| C7 | Row 512's values not done in U3a1. | architecture 2 | Moved to U3a2 (plan); row. |
| C8 | Repository rule omitted store_check; stale status_line mentions. | architecture 5; fact-check 12, 15, 16 | Fixed. |
| C9 | Names; store_check's lib placement; plan drift; git's stderr for a missing tree. | api 3, 5, 6; architecture 6 | api 5 and 6 fixed (plan as-built note; ls-tree stderr dropped, tested); rest rows. |
| C10 | Commit message's row 625 citation. | fact-check 21 | Immutable; row. |

### 🧩 Composition check

- store_check :585-610 (security F1/F2/F3, fact-check 9/15, performance F1-F3, architecture 5): distinct defects (copy divergence, history coverage, cost, comment scope), each stated.
- status_fields :499-548 (api 2/4, architecture 3/4, fact-check 12/16): one shape-documentation class plus BRIEF's stale fields; stated completely by architecture 4.

### ⏭️ Skipped Core Critics
None.
