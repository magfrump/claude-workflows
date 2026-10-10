Commit: 007e867f
Loop closed at 007e867f
# Code Review Rubric

**Branch:** `feat/build-loop-u2b3b2c` (U2b3b2c: both import walks read other reader roots' copies of the names they reach; dangling-link seeds projected), on main 8e550626.
**Status: ✅ ITERATION 3 (final confirming pass over 007e867f, no `--loop-pass`, k=3, full panel) — no Must Fix; the loop converged in 3 iterations. Must Address: C1-C3, C5 fixed in the commit after 007e867f (unreviewed at this stamp; a confirming pass follows), C4 (final security F3, not a regression) routed to U2c with an override row. Single-sample review; absence of findings is not an attestation.**

## Iteration 3: final confirming pass (Commit 007e867f, no `--loop-pass`, k=3, scope `main...HEAD`, full panel)

Delivery mode: self-read. Fact-check: three replicates (`code-fact-check-report-build-loop-u2b3b2c-final-r1/-r2/-r3.md`: 34/40/34 claims) merged most-severe-wins into `code-fact-check-report-build-loop-u2b3b2c-final.md` (44 clusters: 35 Verified, 4 Mostly accurate, 3 Stale, 1 Incorrect (test comment), 1 Unverifiable; agreement 38/44; every count, name set, seed set and red-on-prior-lib claim re-run and held). Critics with the merged results: `security-review-2026-10-09-u2b3b2c-final.md`, `performance-review-…-final.md`, `api-consistency-review-…-final.md`, `architecture-review-…-final.md`. Stage 2.5: security's routed endorsements (i1 F2 fix, i1 F1 fix in its covered order, an equal-bytes copy's .. import still followed, the C1 skip under contract item 2) match executed Verified claims in the merged report (claims on root_copies' skip and the C1 sentence; r1-r3 probes) or were superseded by C1 below; not dispatched separately.

### 🔴 Must Fix

None.

### 🟡 Must Address

| # | Finding | Severity | Source | Status |
|---|---|---|---|---|
| C1 | A name a dangling prompt link projects is never read again once the walk has read it: plain first (PA, main walk), as a start (PB, both walks), or as a prompt without the link's bases (PG, both walks); the override row's "named exception" was reachable by a plain layout. | Medium (fail-open) | fact-check r1 escalation; security F1; api N1; architecture 1; performance F2 | Fixed: prompt_marks appends each name whose marks changed (newly a prompt, or a base pext lacked) to RQ, and both walks re-read those already seen (the main walk only those main has or main_checkout admits, on phase 2's queue; charged to the budgets); test "a name a dangling prompt link projects is read again…" (PA, PB, PG), red on 007e867f; row 595 struck. Copies keep the mark taken at first comparison (documented: a session in another root loads them through its own links). |
| C2 | root_copies dropped a copy missing below a linked directory in another root (live or dangling), projecting nothing (PD). | Medium (fail-open) | fact-check r2 escalation; security F2 | Fixed: missing copies join the batched realpath -m, and one whose real path differs is queued as //ROOT/NAME; the linked-directory test gained the case, red on 007e867f. |
| C3 | Every other root's prompt copy was read even with equal bytes (B2): 6 s vs 2.7 s at 4 worktrees, 20 s vs 5.7 s at 16, on 50 prompt files, adding no name. | Medium (cost) | performance F1 | Fixed: an equal-bytes prompt copy is skipped unless its root lies below a .claude/ component whose parent is no reader root (the only source of extra prompt bases; computed per root). The i2 fact-check-16 test still passes. |
| C4 | A live prompt link in another root whose target there holds other bytes than its projected repo path: the name is read plain from this checkout (PC). Not a regression. | Medium | security F3 | Deferred to U2c (override row): the fix would pass the 400-line cap; named in the walk header. |
| C5 | Stale or loose text: import_outside's and outside_ok's lists omit root_copies' copies; the walk block and c1_seeds' "when its bytes differ"; the C1 test title; the `:767` reason (Incorrect); the `:777` comment (non-prompt); prompt_marks "gets"; root_copies' "run after import_readers". | Low (text) | fact-check 8, 13, 14, 16, 22, 30, 32, 34; api N2-N4 | Fixed. |

### 🟢 Consider

| # | Finding | Source | Status |
|---|---|---|---|
| D1 | The outside_seeds split (i1 A8) took the fix batch to 417 lines. | size gate | Reverted (356 lines); row 582's split re-keyed in a new override row. |
| D2 | Prompt-base merge written twice; each mechanism once per walk. | architecture 2, 3 | Deferred with D1 (row). |
| D3 | pext growth per link. | performance F3 | Won't-Fix (row). |
| D4 | Commit f7e1bea2's +0.05 s timing. | fact-check 41 | Accepted-immutable (row); the header now says about 0.2 s, measured interleaved. |

### 🧩 Composition check

- prompt_marks / walk read order (security F1, api N1, architecture 1, performance F2, fact-check r1): one root defect — prompt marks set after a name's read never reached a re-read — composed as C1.
- root_copies admission (security F2, performance F1, fact-check r2, 16): distinct — a missing-copy projection (C2) and a cost rule (C3).

### Considered overrides

The u2b3b2b rows 580, 581, 583, 586, 588 stand; this branch's earlier rows stand except 595 (struck: C1).

### After the pass

Suites 288/288 (serial); both walks over /workspace give main's 242 names; interleaved against main's lib the branch adds about 0.2 s per walk (load ~3). 356 changed code lines.


## Iteration 2 (Commit c69f352f, `--loop-pass`, k=1, scope `f7e1bea2..c69f352f`, short-circuited)

Delivery mode: self-read; partial-scope label applied. Fact-check `code-fact-check-report-build-loop-u2b3b2c-i2.md` (21 claims: 18 Verified, 1 Mostly accurate, 2 Incorrect). Every iteration-1 fix verified as claimed (A8: identical outside_seeds output under f7e1bea2's and c69f352f's libs, on /workspace and on a fixture where one path is both a config and a C1 seed). Loop-pass short-circuit: behavioural 🔴 confirmed at fact-check (claim 9b) — the four critics skipped this pass; the final confirming pass runs the full panel.

### 🔴 Must Fix

| # | Finding | Severity | Source | Status |
|---|---|---|---|---|
| B1 | prompt_marks read a dangling prompt link's target with the target's prompt bases, not the link's: under a nested `.claude/` (`side/sub/.claude/commands/k.md`) names resolved against `side/sub` were missed (executed: `sub/top.md -`; live link: imported). | Behavioural (fail-open, narrow) | fact-check 9b | Fixed: prompt_marks also records the link's directory and prompt bases (pext), which both walks add to the target's DIRS; the dangling-prompt test gained the nested case, red on c69f352f. |

### 🟡 Must Address

| # | Finding | Severity | Source | Status |
|---|---|---|---|---|
| B2 | The equal-bytes skip dropped a prompt copy in a root nested under a `.claude/` whose parent is no root: its absolute path adds prompt bases ROOT_REAL's copy lacks (executed fixture; not on /workspace). The test comment claiming equal copies add nothing was wrong for prompts. | Medium | fact-check 16 | Fixed: a prompt copy is always read (no equal-bytes skip); test "a prompt copy with this checkout's bytes is still read…", red on c69f352f; root_copies' comment says why. |
| B3 | c69f352f's comment said a copy reached through a link "is no walk start"; true only of the tree walk. | Low (text) | fact-check 13 | Fixed ("no tree walk start"). |

### 🟢 Consider

| # | Finding | Source | Status |
|---|---|---|---|
| B4 | No test drives root_copies' `//` form of a prompt copy (C1 seeds every link in another root first, so the seed route covers it). | fact-check gap | Acknowledged (override row). |
| B5 | The brief's "357 lines" was 359 at c69f352f. | fact-check 7 | Noted; 377 after B1-B3. |

**Iteration 1 status (below):**

## Iteration 1 (Commit f7e1bea2, `--loop-pass`, k=1, scope `main...HEAD` (full: no prior rubric), full panel)

Delivery mode: self-read. Fact-check `code-fact-check-report-build-loop-u2b3b2c-i1.md` (26 claims: 18 Verified, 3 Mostly accurate, 3 Stale, 2 Incorrect, all comment or test text; executed: 242 names per walk identical to main's lib, +0.05 s, 284 tests, health check). No behavioural red, so no short-circuit. Critics: `security-review-2026-10-09-u2b3b2c-i1.md`, `performance-review-2026-10-09-u2b3b2c-i1.md`, `api-consistency-review-2026-10-09-u2b3b2c-i1.md`, `architecture-review-2026-10-09-u2b3b2c-i1.md`. Stage 2.5 skipped (loop pass); performance's endorsement (the tree walk's string seen is not a hot spot) is pending execution verification.

### 🔴 Must Fix

None.

### 🟡 Must Address

| # | Finding | Severity | Source | Status |
|---|---|---|---|---|
| A1 | A dangling prompt link (a C1 or config `p` seed, or a copy of a prompt name) was queued as `//PATH` without its prompt mark, so its target was read as a plain import and names it resolves against the session's top level were missed (executed P3: `top.md -` in both walks). | Medium | security F1 | Fixed: the `//` entry keeps its pdir mark (seed loops, root_copies), and prompt_marks marks the projected repo names as prompts before they are queued; test "a dangling prompt link…" red on f7e1bea2. Residual (a name already read plain; a symlink on main fails closed): named, override row. |
| A2 | A byte-equal copy under a linked directory in another root was skipped (only the leaf was `-L`-tested), losing its real-path projection (executed P2). | Medium | security F2 | Fixed: rawfile's test now runs on both sides (one batched realpath over ROOT_REAL's names and the copies); test "a copy with this checkout's bytes under a linked directory…" red on f7e1bea2. |
| A3 | Tests: the `//ROOT/NAME` dangling-copy branch was never exercised (the fixture's link was live; a mutant deleting it passed), and the byte-equal check could not fail. | Medium (test) | fact-check 12, 14; security F4 | Fixed: side lacks `docs/gone.md`; the deleting mutant now fails. The equal-bytes skip is a cost only (the parser already resolves this checkout's relative names against every root), so its check was replaced by the linked-directory test, with a note. |
| A4 | Stale text: file header (outside_seeds runs sha1sum), the walk header ("seed listing … sha1sum"), outside_seeds' return list; "one realpath and one sha1sum per call"; tq "absolute paths"; walk failure lists without root_copies. | Low (text) | fact-check 1, 4, 9, 6d; api F4 | Fixed. |
| A5 | The C1 skip is safe only because both walks pass every start to root_copies with pdir set; neither call site said so. | Coupling | architecture 1 | Fixed: a comment at each start-pass call. |
| A6 | Contract item 9 did not name IMPORT_OTHER (or IMPORT_DOTNEST) as import_readers' results a caller must not set. | Minor | api F2 | Fixed. |
| A7 | root_copies appended to Q where its siblings clear it. | Minor | api F3 | Fixed (`rc_q=()`; the call sites' `cq=()` dropped). |
| A8 | Override row 582's trigger fired: outside_seeds mixed three seed sources. | Minor | architecture 3 | Fixed: split into config_seeds and c1_seeds behind the outside_seeds wrapper (same seeds; also settles row 589's two keep-rules, one per function). |
| A9 | A copy is read in every root holding it with other bytes, uncapped (13 s over 8 stale worktrees, 50 differing files). | Medium | performance F1 | Deferred (override row): the suggested per-bytes dedupe would miss a copy's own-directory names; priced in root_copies' comment and the walk header; revisit over a 5 s walk. |

### 🟢 Consider

| # | Finding | Source | Status |
|---|---|---|---|
| M1 | Sourcing inventory lacked root_copies and IMPORT_OTHER. | api F1; fact-check escalation | Fixed (with prompt_marks, config_seeds, c1_seeds). |
| M2 | rawfile's test written twice. | architecture 2 | Fixed: a cross-reference at each. |
| M3 | root_copies' realpath not batched through xargs. | architecture 6; security F3 | Fixed. |
| M4 | lower forked before the byte check; ROOT_REAL hashed once per root. | performance F3 | First half fixed (lower only for queued copies); second Won't-Fix (row). |
| M5 | IMPORT_OTHER partly filled on refusal; no noun. | api F5, F6 | Won't-Fix (rows). |
| M6 | Enqueue loop four times; `//PATH` told apart by prefix. | architecture 4, 5 | 4: tq comment names it; 5: Won't-Fix (row). |
| M7 | Budgets do not fail closed before wall time; header did not price root_copies. | performance F2 | Fixed (price in the header). |
| M8 | Commit f7e1bea2: dangling config seeds kept only below a root. | fact-check 7, 21 | Accepted-immutable (row). |

### 🧩 Composition check

- root_copies admission (security F2, fact-check 6d/14, architecture 2, 6, performance F3): one function, distinct defects — the leaf-only link test (A2), text (A4), duplicated rule (M2), batching (M3), cost (M4).
- Seed `//` handling (security F1, fact-check 12, architecture 4): distinct — a missing prompt mark (A1) and an untested branch (A3).

### Considered overrides

Rows 579 and 587 (addressed by this unit), 580 (A5, unchanged), 581, 583, 586, 588 stand; 582 and 589 settled by A8.

### After the fixes

Suites 286/286 in two `-j 8` runs; one earlier `-j 8` run failed a U2b3a reader-roots test on a vanished bats temp file listed by the ancestor seeds' find (a parallel-run race, U2b3b2b's listing; passes alone). Both walks over /workspace still give main's 242 names (tree 1.74 s, main 1.96 s, 7 other roots). 357 changed code lines.
