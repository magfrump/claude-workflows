Commit: d10cfba8
# Code Review Rubric

**Branch:** `feat/build-loop-u3a1` (U3a1: --check re-hashes main's and the merge's objects; status as values; gate_start), on main d5736445.
**Status: 🔴 ITERATION 3 = final confirming pass (no `--loop-pass`, k=3, full panel, Stage 2.5, scope `main...d10cfba8`) — 1 Must Fix (security F1, reproduced), fixed in the commit after d10cfba8 (unreviewed at this stamp). Iteration-4 gate decision below.**

## Iteration 3: final confirming pass (Commit d10cfba8, k=3, scope `main...HEAD`, full panel)

Delivery mode: inline-diff-only. Fact-check: three replicates (`code-fact-check-report-build-loop-u3a1-final-r1/-r2/-r3.md`: 26/38/38 claims) merged most-severe-wins into `code-fact-check-report-build-loop-u3a1-final.md` (56 clusters: 48 Verified, 5 Mostly accurate, 1 Stale, 1 Incorrect, 1 Unverifiable; agreement 82.1%). The Incorrect is a test title (doc-class, 🟡 under policy T: no behavioral red). Critics (opus, parallel; `*-review-2026-10-10-build-loop-u3a1-final.md`): security (1 High, 1 Info), architecture (1 Minor, 1 Info), api (2 Info), performance (1 Info). Stage 2.5 (`code-fact-check-submitted-claims-build-loop-u3a1.md`, appended to the merged report as claims 57-59): 57 Verified (executed: the midx pin reaches all 57 git calls, gate_git's included, and closes the swapped-offset midx route; this also answers fact-check 10b's Unverifiable), 58 Verified (executed), 59 Mostly accurate (the brief is still read twice in status_fields; the saving is one check_branch per brief).

### 🔴 Must Fix

| # | Finding | Source | Status |
|---|---|---|---|
| E1 | The pack listing was newline-separated: a pack named `x<LF>y.idx`, with valid decoy indexes at `pack/x` and `objects/y.idx`, kept the forged pack's index out of the second-copy scan; the gate printed ok for a forged `Branch: feat/y` (reproduced end to end). | security F1 (High) | Fixed: `find -print0` / `read -d ''`; test with the newline pack and decoys, which fails on d10cfba8. |

### 🟢 Consider

| # | Finding | Source | Status |
|---|---|---|---|
| F1 | store_check's skip set chosen by a file's existence: a second main call would skip main silently. | architecture 1 | Fixed: an explicit `--main`; any other call fails without main's list. |
| F2 | check_line's carry list omitted `$GATE_TMP/main`. | architecture 2 | Fixed. |
| F3 | The help's per-brief gloss omits that a mid-run second copy of main's object refuses there; the state paragraph lacked "(gitlinks aside)". | api 1, 2 | Fixed. |
| F4 | Plan note "skipping ids already checked"; the Not-checked lists omit check_brief's `git log -G` walk; gate_start's comment omits mktemp's exit 1; a test title named a multi-pack-index case it lacks. | fact-check 2b, 4b, 20, 25a, 34b | Fixed. |
| F5 | Commit 65007bf8 cites row 512 and says the brief is read once. | fact-check 36c, 36d; Stage 2.5 59 | Immutable; row; merge message corrected. |
| F6 | The midx pin's lookup cost. | performance F1 | Row (Won't-Fix). |

### Iteration-4 gate decision

**Decision: escalate**, resolved under Q-137's standing instruction (review adjustments go ahead on the recommendation, without a Q entry), as U2b3b2c's was: E1 is a contained fix (two lines and a test) of the same listing iteration 2 built, so the recommendation is a narrow confirming pass (k=1 fact-check + security over the fix range), not a split or another full loop. Any Must Fix there stops the unit and goes to a Q entry.

### 🧩 Composition check

- store_check :614-660 (security F1, architecture 1/2, api 1, fact-check 20/21, Stage 2.5 57/58): distinct defects (listing framing, skip-set selection, carry list, help gloss, comment omissions), each stated.

## Iteration 2 (Commit 83f75281, `--loop-pass`, k=1, scope `65007bf8..83f75281`, full panel)

Incremental scope (the fix batch; docs/reviews excluded). Fact-check k=1 (`code-fact-check-report-build-loop-u3a1-i2.md`): 30 claims, 26 Verified, 2 Mostly accurate, 2 Stale, 0 Incorrect; executed the duplicate refusal (two packs, loose+packed, SHA-1/256) and its fail-closed paths. Critics (opus, parallel; `*-review-2026-10-10-build-loop-u3a1-i2.md`): security (2 Medium, 1 Info; read-static), architecture (1 Coupling, 2 Info), api (1 Minor, 2 Info), performance (1 Low). Prior Must Fix A1/A2: verified resolved (fact-check executed; security read). No re-fire of a fixed finding (the carry-over is new, introduced by the C2 skip).

### 🟡 Must Address

| # | Finding | Source | Status |
|---|---|---|---|
| B1 | `$GATE_TMP/checked` was both the skip cache and the duplicate scan's set, so one brief's second copy refused every later brief in the run under its own name (reproduced by two critics). | architecture 1 (Coupling); api 1; performance (escalation) | Fixed: store_check skips main's ids ($GATE_TMP/main, kept by gate_start) and judges main's plus this call's ids only; a two-brief test in both orders. |
| B2 | The scan listed packs by glob (no dot names) and loose files without following links; the repo's core.multiPackIndex gave real-repo reads a second route. | security F1 (Medium, read-static) | Fixed: find -L inside the store for both; harden pins core.multiPackIndex=false (the config-pairs test lists it); tests for a dot-named pack and a linked fan-out dir. |
| B3 | Main's objects are re-hashed once per run: a rewrite in place after startup reaches later briefs. | security F2 (Medium) | Deferred with a row (R8 family, Q-103); stated in the comment and plan note. |

### 🟢 Consider

| # | Finding | Source | Status |
|---|---|---|---|
| D1 | Plan's U3a2 bullet cited the removed re-read; state_gate's header omitted alternates. | fact-check i2 5, 10; api 2 | Fixed. |
| D2 | Test comments: "with no path line" unpinned; "the settings" was the brief. | fact-check i2 26, 27 | Fixed (full line pinned; comment says any blob read). |
| D3 | "With one copy every read gets the bytes checked here" overclaims. | security F3 | Comment reworded. |
| D4 | GATE flag shares the gate repository's GATE_ prefix. | architecture 3 | Renamed GATED. |
| D5 | Scan cost grows with the store; store_check's lib move needs the scratch dir; `refuse state objects` vs `objects/info/alternates`. | performance F1; architecture 2; api 3 | Rows. |

### 🧩 Composition check

- store_check :614-641 (architecture 1, api 1, performance escalation, security F1/F2): architecture 1 states the root (two jobs on one file) completely; security F1/F2 are distinct (listing gaps, race window).

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
