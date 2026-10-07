Commit: 21b35ebf
# Code Review Rubric

**Branch:** `feat/build-loop-u2a3c` (U2a3c, main_imports' checkout phase), rebuilt on main 2026-10-07 above U2a3b (old tip `backup/u2a3c-pre-rebase-2b1399ab`; iteration 1's rubric is `code-review-rubric-2026-10-06-feat-build-loop-u2a3c.md`).
**Status: ⚠️ ITERATION 2 FIXED in 2fbd929b — final confirming pass pending** (no Must Fix; Must Address fixed; single-sample review; absence of findings is not an attestation)

## Iteration 2 of 3 (Commit 21b35ebf, `--loop-pass`, k=1)

Scope: full branch `main...HEAD`. Iteration 1's stamp (cebfed35) is not an ancestor after the rebase, so the loop-pass default fell back to full scope. Delivery mode: self-read (a shared brief file, then each agent ran `git diff main...HEAD`). The first-red short-circuit did not fire because the fact-check found no Incorrect. Full panel: security, performance, api-consistency, architecture (auto-selected: lib function contracts changed), and test-strategy (included, as in iteration 1).

Reports (all `Commit: 21b35ebf`):
- `code-fact-check-report-build-loop-u2a3c.md`: k=1, 34 claims. 25 Verified, 2 Mostly accurate, 5 Stale, 0 Incorrect, 2 Unverifiable.
- `security-reviewer-review-2026-10-07-build-loop-u2a3c.md`: 1 Medium (docs), 1 Informational. No fail-open.
- `performance-reviewer-review-2026-10-07-build-loop-u2a3c.md`: 2 Medium, 1 Low, 2 Informational.
- `api-consistency-reviewer-review-2026-10-07-build-loop-u2a3c.md`: 1 Inconsistent, 4 Minor, 2 Informational. Nothing Breaking.
- `architecture-review-review-2026-10-07-build-loop-u2a3c.md`: 1 Coupling, 2 Minor, 3 Informational. Nothing Structural.
- `test-strategy-review-2026-10-07-build-loop-u2a3c.md`: G1-G12; 47 mutants, 16 surviving (3 equivalent). T1-T5 applied.

Stage 2.5 skipped (loop pass); the routed security endorsements stay pending execution verification for the final pass.

Tests after fixes (2fbd929b): build-loop-check 63/63, dev-cycle 78/78, build-loop-read 19/19, fixture-hermeticity 2/2; shellcheck -S warning clean. The health check at 61e2e734 failed only on shellcheck SC2034 (`pok`), fixed in 2fbd929b.

### 🔴 Must Fix

None.

### 🟡 Must Address

| # | Finding | Severity | Source | Status | Author note |
|---|---|---|---|---|---|
| B1 | The rebase resolution (3e58eb9c) dropped U2a3c's caller contract: A5's cache-clear rule, its FIFO and snapshot items, and the U2b bullet's three caller duties (a final checkout or a cleared `IMPORTED_MAIN_DONE`, empty `ls-files` stderr, the git environment). Override rows 439-441 cite that text as their mitigation. | Inconsistent / Coupling / Medium | fact-check stale 439-441; api-consistency 1; architecture F1; security F1 | Fixed (2fbd929b) | Restored from the pre-rebase text, with a pointer to the lib comment; correction row appended. |
| B2 | `main_checkout`'s top-down ancestor loop rescanned every absent ancestor per prefix candidate: O(D³) in token depth (D=1950: 64 s; main 2.1 s), a regression from the L2-C6 change. | Medium | performance F1, F5 | Fixed (2fbd929b) | Bottom up to the nearest decided ancestor, memoizing every result (d or 2) and a searchable PATH directory. D=1000: 0.62 s (main 0.50, 21b35ebf 10.67). Test with a 6 s timeout fails at 21b35ebf. |
| B3 | The symlink arm reads a 120000 blob whole, twice, uncapped (256 MiB: 58 s, 2 GiB, as on main); override row 449 said capped_read covered main's blobs. | Medium | performance F2; architecture F5; fact-check escalation | Fixed (2fbd929b) | Link text over 4096 bytes fails before it is read; test; row 449 corrected. |
| B4 | One survivor fails open: a link main stores two levels below a directory the checkout lacks (M13, `continue` → `break`) passed every test; five more main_checkout rules were pinned only through walks that mask them (M14, M16, M18-M20, M23). | test-strategy high | test-strategy G1-G6 | Fixed (2fbd929b) | T1 (the shape table, direct calls) and T2 (walk level) applied. HEAD was correct; the gap was the tests. |

### 🟢 Consider

| # | Finding | Source | Status |
|---|---|---|---|
| C1 | `[[ -p /dev/stdin ]]` needs /proc; without it the drain is skipped and a blob over 4 MiB fails the walk closed | security escalation | Fixed: `capped_read drain` names the pipe site |
| C2 | IMPORT_WORK_LEFT unset or non-numeric behaviour undocumented; MEMO scope (a hit skips the mode check) unstated; "plain" should be "readable plain" | api-consistency 2, 3; architecture F4; fact-check mostly-accurate | Fixed (comments) |
| C3 | Work-bound caps and the checkout arm's charge unpinned (M29, M39, M41-M43) | test-strategy G7-G9 | Fixed: T3 (replaces the work-bound test), T4 |
| C4 | Inventory lacks `import_work`; stale "until U2a3c" comment at :69; main import of an untracked start untested | test-strategy G10-G12; api-consistency 4; fact-check stale | Fixed (patches, T5) |
| C5 | A5 said "warns about" (the code fails on any stderr); plan bullet's "only a non-plain node fails" | api-consistency 5, 6; fact-check | Fixed |
| C6 | The drain and the @-less scan are uncharged work; two walks cost two bounds | performance F3, F4 | Defer (override row; comment states it) |
| C7 | The reader → parser → trailer → budget chain is written three times; main_checkout is a second traversal beside blocker | architecture F2, F3 | Defer (override row); the comment says why it differs |
| C8 | The absent-under-checkout-dir-link shape changed 2 → 1 (stricter); visible through a link main stores | security F2 (corrects fact-check Claim 32) | Pinned by T1 (`sd/nx.md 1`) |
| C9 | Gitfile "as Claude Code does" unverifiable here (binary read blocked); `.git/` internals now feed the answer | fact-check unverifiable; security escalation | No action: reads only add names or fail; the host probe (Q-126) can confirm |

### ↩️ Considered Overrides

Matched rows from `docs/reviews/override-log.md`: U2a3c iteration 1's rows 439-447 (cache key, FIFO start, TOCTOU, per-start cost, three-valued return, name, read arm, record order, commit message) and U2a3b's routed rows 420, 426-427, 436 (closed by 21b35ebf's rows 448-451). Rows 439-441 re-fired with a changed premise (B1) and were corrected, not overridden. Row 446's premise changed (corrected). Rows 449 and 451 overstated (corrected and narrowed).

### Re-flagged settled decisions

None beyond B1, whose premise changed.

### ⏭️ Skipped Core Critics

None.

### 🧩 Composition check

- `docs/working/known-issues-dev-cycle.md:18`, `plan-build-loop-handoff.md:279`, `override-log.md:439-441`: fact-check, security, api-consistency and architecture. Composed → B1 (one root: the 3e58eb9c resolution kept main's text and replaced only the "until U2a3c" sentences, using cebfed35's wording instead of 1fb62779's).
- `dev-cycle-read.sh` main_checkout: performance F1/F5, test-strategy G1-G6, security F2, api-consistency 3. Distinct defects: cost (B2), test coverage (B4), shape (C8) and comment (C2) each name their own mechanism.
- Symlink arm: performance F2, architecture F5, fact-check escalation. Same defect, stated by each (B3).

## Next

Final confirming pass over 2fbd929b and later: full branch, k=3 fact-check, full panel, Stage 2.5, no `--loop-pass`.

tokens: fc 215k, critics 137k + 135k + 191k + 164k + 140k ≈ 1.0M total
