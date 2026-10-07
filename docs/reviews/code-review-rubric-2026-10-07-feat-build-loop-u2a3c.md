Commit: 3a35c8b9
# Code Review Rubric

**Branch:** `feat/build-loop-u2a3c` (U2a3c, main_imports' checkout phase), rebuilt on main 2026-10-07 above U2a3b (old tip `backup/u2a3c-pre-rebase-2b1399ab`; iteration 1's rubric is `code-review-rubric-2026-10-06-feat-build-loop-u2a3c.md`).
**Status: ⚠️ FINAL PASS NOT CLEAN — findings fixed in 4b7f2357, unreviewed by a further pass; landing is the user's call (Q entry)** (no Must Fix open; single-sample review; absence of findings is not an attestation)

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


## Iteration 3 of 3: final confirming pass (Commit 3a35c8b9, full branch, k=3, full panel, Stage 2.5)

Scope: `main...HEAD` at 3a35c8b9. Delivery mode: self-read. No `--loop-pass`, so no short-circuit. The Fact-Check Gate (a high-confidence Incorrect) was not paused: critics were dispatched in parallel with the replicate merge, in away mode (override row).

Reports (Commit 3a35c8b9 unless noted):
- `code-fact-check-report-build-loop-u2a3c.md` (merged, k=3; replicates `-r1/-r2/-r3.md`): 64 clusters, 41 Verified, 14 Mostly accurate, 2 Stale, 1 Incorrect, 6 Unverifiable. Agreement 78.1% (50/64), so k stays at 3.
- `security-reviewer-review-2026-10-07-build-loop-u2a3c-final.md`: 2 Low. No fail-open reachable through main_imports.
- `performance-reviewer-review-2026-10-07-build-loop-u2a3c-final.md`: 1 High, 1 Low, 1 Informational.
- `api-consistency-reviewer-review-2026-10-07-build-loop-u2a3c-final.md`: 1 Inconsistent, 1 Minor, 2 Informational. Nothing Breaking.
- `architecture-review-review-2026-10-07-build-loop-u2a3c-final.md`: 1 Coupling, 1 Minor. Nothing Structural.
- `test-strategy-review-2026-10-07-build-loop-u2a3c-final.md`: G1-G7; 30 mutants; 4 equivalent survivors (A01, A13, A14, A16).
- `code-fact-check-submitted-claims-build-loop-u2a3c.md` (Stage 2.5, Commit 4b7f2357): 10 submitted claims, 10 Verified plus 1 Incorrect (67a, the orchestrator's own restatement of S3: at a PATH main stores as a link or gitlink, 4b7f2357 answers 1 by design, where 21b35ebf answered 0 or 2).

Tests after fixes (4b7f2357): build-loop-check 66/66 under a 17- and a 74-character TMPDIR, dev-cycle 78/78, build-loop-read 19/19, fixture-hermeticity 2/2; shellcheck clean; `scripts/health-check.sh` passed at 3a35c8b9 and at 4b7f2357.

### 🔴 Must Fix

None open. (D1 below was a performance High with a quadratic stall, not a correctness red.)

### 🟡 Must Address

| # | Finding | Severity | Source | Status | Author note |
|---|---|---|---|---|---|
| D1 | `${x@a}` costs time linear in the array, and 2fbd929b's MEMO grows per token, so the walk went quadratic (4,000 deep absent tokens: 44.6 s here, 85 s in the critic's run; a 50k-entry main tree with 1,000 tokens: 33 s against 3 s on main) | High | performance F1 | Fixed (4b7f2357) | `${x[0]@a}` is O(1) and gives the same answers (empty, large, indexed, scalar, unset checked). 2.5 s now, main 0.9 s. A 20 s-timeout test fails at 3a35c8b9 (it catches on hosts up to ~2x faster). |
| D2 | main_checkout memoized a checkout directory at PATH as d without checking ENT[PATH], so a caller passing a PATH main stores as a link or gitlink opens every later path below it (and `x.md` main stores as a gitlink answered 0). Unreachable from main_imports | Incorrect (comment) / Coupling / Inconsistent / Low | fact-check claim 34 (r1, r2); architecture F1; api-consistency 1; security F1 | Fixed (4b7f2357) | Guard: main's link or gitlink at PATH answers 1 (test-strategy's form; a broad "any ENT path" guard would break T1's blob row). Precondition test added; comment and U2b bullet state it. |
| D3 | Test 59 (T3) fixed IMPORT_WORK_MAX=1000 while w grows with the fixture root's length: red under a TMPDIR over ~27 characters | test bug / Medium | fact-check r1 claim 1; test-strategy G1 | Fixed (4b7f2357) | Caps derived from w; verified under 17- and 74-character TMPDIRs. |
| D4 | The U2b bullet dropped "a clean worktree at MAIN_SHA": the walk reads main's blob for every path main stores, so an edited tracked instruction file's imports go unread (test 77 pins this as intended) | Low | security F2 | Fixed (4b7f2357) | Restored as the first of four caller duties. |

### 🟢 Consider

| # | Finding | Source | Status |
|---|---|---|---|
| E1 | The deep-token test's `timeout 6` catches its regression only on hosts under ~1.8x faster; the link-text test could not observe read order; T1's title; the stale "(18)" | test-strategy G2-G4, G6, G7; fact-check | Fixed: an xtrace-count test (host-independent), a cat-file shim, the PATH memo pinned, T1 prints the whole MEMO |
| E2 | A deep token through directories the checkout holds still costs about D³ in realpath (D=1000: 14 s; 21b35ebf 34 s; main over 120 s) | performance F2 | Defer (override row) |
| E3 | The caller contract lives in two places | architecture F2; api-consistency 2 | Defer to U2a4 (override row); A5 says which part lives where |
| E4 | Comment precision: the work unit also charges resolved spellings (ROOT_REAL's length); IMPORT_LEFT/IMPORT_WORK_LEFT read a leading number; F11 omitted the unreadable file; rows 449/453 | fact-check 9, 13, 18, 25, 28; api-consistency 3, 4 | Fixed (comments, docs, a correction row) |
| E5 | A non-numeric `git cat-file -s` output would abort the caller under set -u rather than return 1 (no real git does this) | Stage 2.5 claim 68 note | No action |
| E6 | Unverifiable here: Claude Code's gitfile reading (Q-126 host probe), /proc dependence of `-p /dev/stdin` (moot since 2fbd929b; Q-127), "Claude Code skips a file over 4 MiB" (carried from main), 3e58eb9c's "same final tree" | fact-check | Routed: Q-126 / Q-127 |

### ✅ Confirmed Good (executed, Stage 2.5 at 4b7f2357)

| Claim | Evidence |
|---|---|
| For PATHs ENT lacks, main_checkout returns 21b35ebf's code under any call order on one MEMO | claim 65: 6,602 random-order calls, depth ≤ 4, 0 differences (not covered: deeper paths, case-insensitive names) |
| main_imports calls main_checkout only for paths main lacks | claim 66 (static; both call sites) |
| Link text over 4096 bytes fails before either whole read | claims 68, 71 (shim confirms the blob is never read) |
| Every capped_read failure fails the walk, with or without the caller's pipefail | claim 69: five failure modes, each with a control |
| Deep-absent, link-cap, drain, memo and import_work costs as stated | claims 70-74 |

### ↩️ Considered Overrides

Rows 439-456 (this unit) and U2a3b's routed rows. Row 451's narrowing re-surfaced as fact-check claim 25 (the work unit), which was fixed in the comment; row 456's deferral was re-confirmed unchanged by architecture. No Won't-Fix row was re-flagged.

### 🧩 Composition check

- `dev-cycle-read.sh` main_checkout PATH memo (:720-753): fact-check 34, architecture F1, api-consistency 1, security F1, test-strategy G5. Composed → D2 (one root: the PATH arm memoizes without PATH's own mode check).
- main_checkout type check (:736): performance F1 alone. D1.
- Test 59: fact-check r1 claim 1, test-strategy G1. Same defect → D3.

## Next

Q entry for the user: land 4b7f2357 as is (its fixes reviewed only by tests, Stage 2.5 and the health check), or run one more confirming pass first.

tokens (final pass): fc 3 × ~230k, merge 212k, critics 158k + 152k + 121k + 114k + 153k, Stage 2.5 ~150k ≈ 1.8M

tokens: fc 215k, critics 137k + 135k + 191k + 164k + 140k ≈ 1.0M total
