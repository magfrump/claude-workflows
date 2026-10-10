Commit: c69f352f
Loop-pass short-circuit: used at c69f352f
# Code Review Rubric

**Branch:** `feat/build-loop-u2b3b2c` (U2b3b2c: both import walks read other reader roots' copies of the names they reach; dangling-link seeds projected), on main 8e550626.
**Status: 🔴→fixed ITERATION 2 (`--loop-pass`, k=1, scope `f7e1bea2..c69f352f`, short-circuited at fact-check) — one behavioural red (B1) and one Must Address (B2), fixed in the commit after c69f352f with tests; critics deferred to the final confirming pass. Single-sample review; absence of findings is not an attestation.**

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
