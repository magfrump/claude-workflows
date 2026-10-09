Commit: f7a96eed
# Code Review Rubric

**Branch:** `feat/build-loop-u2b3b2a` (U2b3b2a: the parser's second channel and both walks following imports to files below no reader root), on main b7728cfd.
**Status: 🟡 ITERATION 2 (Commit f7a96eed) — no red; iteration 1's A1, A2, A4 verified fixed (mutants executed); iteration 2's findings are text only, fixed in its fix commit; 15 findings declined with override rows in all. Next: iteration 3, the final confirming pass (k=3, full panel, full branch).**

## Iteration 2 (Commit f7a96eed, `--loop-pass`, k=1, scope `55490d15..f7a96eed`, full panel)

Delivery mode: self-read, partial-scope label. Fact-check first, then the four critics in parallel with its results. Reports: `code-fact-check-report-build-loop-u2b3b2a-i2.md` (k=1: 30 claims, 27 Verified, 2 Mostly accurate, 1 Incorrect; 22 executed; the three fix mutants each fail a test), `security-review-2026-10-09-u2b3b2a-i2.md`, `performance-review-2026-10-09-u2b3b2a-i2.md`, `api-consistency-review-2026-10-09-u2b3b2a-i2.md`, `architecture-review-2026-10-09-u2b3b2a-i2.md`. No short-circuit: the one Incorrect is a commit-message claim (🟡 under tier policy T).

Prior Must Address: A1 resolved, A2 resolved, A4 resolved in code (its header half finished here, B1); A3 acknowledged (row).

### 🔴 Must Fix

None.

### 🟡 Must Address

| # | Finding | Severity | Source | Status |
|---|---|---|---|---|
| B1 | import_file's header did not say an absolute FILE needs IMPORT_WORK_LEFT and returns 1 without it; commit 18fba03d claims both headers say it. U2b3b2b's seeds are its first non-walk caller. | Incorrect (commit message) / Inconsistent | fact-check Claim 24; api F1; architecture N1; security F1 | Fixed: import_file's header states the duty and that 1 is a failed walk, never a skip; commit message: Accepted-immutable row. |

### 🟢 Consider

| # | Finding | Source | Status |
|---|---|---|---|
| H1 | import_outside's returns-1 list omits IMPORT_WORK_LEFT unset and an import_targets failure. | fact-check Claim 12 | Fixed (comment). |
| H2 | The newline test's title says both walks; only the tree-walk half pins A2. | fact-check Claim 20a | Fixed (title). |
| H3 | Why only IMPORT_WHOLE is cleared at source; it is a global mode a caller could set. | api F2; architecture N3 | Fixed (comment: a one-call prefix only; the walks set the two budgets per call). |
| H4 | main_imports' failure list omits an outside-file read. | architecture N4 | Fixed (comment). |
| H5 | An outside file changed during the walk is read as it then is. | security F2 | Fixed (walk header). |
| H6 | `outside_ok`'s naming. | api F3 | Won't-Fix: override row. |
| H7 | import_file's DIR is ignored for an absolute FILE. | architecture N2 | Won't-Fix: override row (documented). |
| H8 | outside_ok's call cost; import_outside's realpath -ez cost. | performance F1, F2 | Won't-Fix: override rows (measured, small). |

### 🧩 Composition check

- import_file / import_outside headers (fact-check 24, 12; api F1; architecture N1; security F1): one defect stated by every fragment (the missing IMPORT_WORK_LEFT clause), already B1; no composition.

Override rows this iteration: 5 (B1's commit message, H6, H7, H8 ×2), counts equal.

Tokens: fact-check 167k, security 110k, performance 90k, api 96k, architecture 97k ≈ 560k.

## Iteration 1 (Commit 55490d15, `--loop-pass`, k=1, scope `main...HEAD`, full panel)

Delivery mode: self-read (a shared brief in the scratchpad; each agent ran the diff). Deviation: the four critics ran in parallel with the fact-check rather than after it, so no critic saw its verdicts; each critic's report carries the no-fact-check warning. Reports: `code-fact-check-report-build-loop-u2b3b2a.md` (k=1: 25 claims, 20 Verified, 3 Mostly accurate, 1 Stale, 1 Unverifiable, 0 Incorrect), `security-review-2026-10-09-u2b3b2a.md`, `performance-review-2026-10-09-u2b3b2a.md`, `api-consistency-review-2026-10-09-u2b3b2a.md`, `architecture-review-2026-10-09-u2b3b2a.md` (auto-selected: the parser's output contract and the shared reader changed). test-strategy not selected (every source change has test changes). No short-circuit (no behavioral red at fact-check).

Considered overrides: rows 534 (the parser's second channel: closed here), 538 and 554 (import_targets' fallback and the three refusal checks: closed here, H5/A1), 539 (dotnest per process: closed here, H2), 542 (checkout-only starts in other roots: U2b3b2b), 550 (per-root seeds: U2b3b2b).

### 🔴 Must Fix

None.

### 🟡 Must Address

| # | Finding | Severity | Source | Status |
|---|---|---|---|---|
| A1 | IMPORT_WHOLE is read from the environment and never cleared, so an exported `IMPORT_WHOLE=1` makes every walk read each line as one whole name: `@docs/x.md` reads not imported (executed). A fail-open. | Coupling (false negative) | architecture A1 | Fixed: the lib clears IMPORT_WHOLE when sourced; test (the chain test under `IMPORT_WHOLE=1`); the mutant dies. |
| A2 | An outside link whose real path holds a newline is projected as two lines (`docs/a`, `//b.md`), so the tree walk misses the repo file and its imports while reporting ok (executed). | Behavioral (false negative; not a regression) | fact-check i1 (Mostly accurate, lib:1111) | Fixed: import_outside reads the real path through `realpath -ez` and nul_list and fails on a newline; test; the mutant dies. |
| A3 | A `//` name below a reader home this container cannot see is skipped as missing, though a host session loads it (executed). | Medium (not a regression) | security F1 | Acknowledged: override row (Defer to U2b3b2b, whose home seeds meet the same rule); the walk header now names it an exception rather than claiming a session cannot load it. |
| A4 | file_targets ignored DIR and DIRS for an absolute FILE, and always printed a trailer (returns 1 without IMPORT_WORK_LEFT), undocumented; U2b3b2b's outside prompt seeds would lose their session bases. | Inconsistent / Coupling | api-consistency F1, architecture A2 | Fixed: renamed import_file; DIRS reach import_outside; both headers say a walk sets IMPORT_WORK_LEFT; test for DIRS; the mutant dies. |

### 🟢 Consider

| # | Finding | Source | Status |
|---|---|---|---|
| G1 | The admission rule (`-f && -r`) written inline in both walks. | architecture A3 | Fixed: outside_ok. |
| G2 | The two-call budget of outside_targets is undocumented (each call may spend all the walk has left). | architecture A4 | Fixed (comment). |
| G3 | IMPORTED/IMPORTED_MAIN now hold `//` names. | architecture A5, api F6 | Fixed (comment in the walk header). |
| G4 | dotnest's home moved, but put's and truthrule's comments and main_imports' tq comment did not. | architecture A6 | Fixed (comments). |
| G5 | The sourcing inventory test lacks the new names. | api F2 | Fixed (import_outside, import_file, outside_ok, IMPORT_DOTNEST, IMPORT_WHOLE). |
| G6 | outside_targets/file_targets drop the block's import_ prefix. | api F3 | Fixed: import_outside, import_file. |
| G7 | IMPORT_DOTNEST described inside the path-list sentence, and kept a trailing newline. | api F4 | Fixed (own comment; newline stripped). |
| G8 | Superset statement: `U2b3b2` should read `U2b3b2b` (Stale), and the absolute-directory case is missing from "made absolute". | fact-check i1 | Fixed (comments). |
| G9 | Direct import_targets now needs a repo and refuses `/`. | api F5 | Won't-Fix: override row. |
| G10 | FIFO swap after admission stalls the read. | security F2, performance F4 | Won't-Fix: override row; named in the walk header. |
| G11 | Any readable file an `@` names is parsed. | security F3 | Won't-Fix: override row (no oracle). |
| G12 | A large outside binary a prefix names fails the walk. | performance F1 | Won't-Fix (documented): override row. |
| G13 | A very long absolute token fails the walk (L*L/2 prefix bytes). | performance F2 | Won't-Fix (documented): override row. |
| G14 | A symlinked outside file is parsed twice. | performance F3 | Won't-Fix: override row; comment. |
| G15 | dotnest O(R*R) once per reader set. | performance F5 | Won't-Fix: override row (a net win). |
| G16 | Commit 55490d15's Notes call the `\|\| true` mutant equivalent. | fact-check i1 (Mostly accurate) | Accepted-immutable: override row. |
| G17 | "a session cannot load it either" for a FIFO is untraced. | fact-check i1 (Unverifiable) | Won't-Fix: override row. |

### ⏭️ Skipped Core Critics

None.

### 🧩 Composition check

- `scripts/lib/dev-cycle-read.sh` import_outside / file_targets (api F1, architecture A2, architecture A4, fact-check newline claim): distinct defects (DIRS dropped, trailer contract, budget doc and the newline projection each state their own mechanism and fix).
- Both walks' `//` arms (security F1, F2; performance F1, F4; architecture A3): distinct defects (absent home, FIFO race, large file, duplicated rule).

Override rows written this iteration: 10 (declined findings G9-G17 and A3), counts equal.

Tokens: fact-check 152k, security 133k, performance 127k, api 105k, architecture 140k ≈ 657k.
