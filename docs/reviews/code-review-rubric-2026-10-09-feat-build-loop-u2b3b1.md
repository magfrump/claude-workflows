Commit: 8ed86432
# Code Review Rubric

**Branch:** `feat/build-loop-u2b3b1` (U2b3b1: the reader settings, `Reader roots:` and `Reader homes:`, for both import walks), on main f8d003c7.
**Status: 🟡 ITERATION 1 — no red; two ambers (architecture F1, the settings rule written twice; security F1, `--check-fix` able to model no host reader) acknowledged with revisit triggers after the fixable half of security F1 was fixed in 1ece139d (unreviewed). Single-sample review; absence of findings is not an attestation.**

## Iteration 1 (Commit 8ed86432, `--loop-pass`, k=1, scope `main...HEAD`, full panel)

Delivery mode: self-read (a shared brief in the scratchpad; each agent ran the diff). Reports: `code-fact-check-report-build-loop-u2b3b1.md` (k=1: 17 claims, 13 Verified, 3 Mostly accurate, 1 Stale, 0 Incorrect), `security-review-2026-10-09-u2b3b1.md`, `performance-review-2026-10-09-u2b3b1.md`, `api-consistency-review-2026-10-09-u2b3b1.md`, `architecture-review-2026-10-09-u2b3b1.md` (auto-selected: the lib's public functions and the settings contract changed). test-strategy not selected (every source change has test changes). No short-circuit (no behavioral red).

Considered overrides: rows 533, 537, 538, 539, 540, 542, 544, 545 (U2a3a's items routed here; H5, H2, C1 belong to U2b3b2 by the plan split).

### 🔴 Must Fix

None.

### 🟡 Must Address

| # | Finding | Severity | Source | Considered overrides | Status |
|---|---|---|---|---|---|
| A1 | Two parsers for one settings file: the lib's SETTINGS_AWK knows build-loop.sh's keys, the record decoding is copied in `read_settings` and `reader_settings`, and the list-line rule is written twice. Correct today; a change must be made in both. | Coupling | architecture F1 | none | Acknowledged: override row (revisit: the next settings key, or U2c's `Paths:` parsing); a shared helper would move ~40 lines already on main past the cap. |
| A2 | `--check-fix` can model no host reader: dev-cycle.sh runs no default_gate, so a loop that points origin/HEAD at its own branch has reader_settings read that branch's copy; with no main by name the lists stayed empty (executed). Not a regression. | Medium | security F1 | none | No-main half fixed in 1ece139d (reader_settings sets IMPORT_READER_WHY; test in dev-cycle.bats); redirect half acknowledged: Q-103 residual (override row; revisit: U3b's `--state` or Q-103). |

### 🟢 Consider

| # | Finding | Source | Status |
|---|---|---|---|
| G1 | import_targets' comment says it falls back to ROOT_REAL alone without a current memo; a memoized refusal now makes it fail. | fact-check (Stale, lib:771); architecture F3 | Fixed in 1ece139d (comment). |
| G2 | import_targets' fallback ignores IMPORT_READER_WHY, so a refused settings file would not stop a caller outside a walk (U2b3b2's outside seeds). | security F2 (Low) | Fixed in 1ece139d: refuses while IMPORT_READER_WHY is set; test. |
| G3 | "a refusal included" is untrue for an import_home failure; docs/dev-cycle.md's next-line wording omits end of file and a refused file; the H4 test name says "every path" but passed one. | fact-check (Mostly accurate) | Fixed in 1ece139d. |
| G4 | A missing reader_settings call fails open (empty lists read as no host reader). | architecture F2 | Deferred: override row (a sentinel needs ~30 test call sites; revisit: a third walking script or U2c). |
| G5 | Malformed settings fail the walks with generic text that does not name the cause. | api F1 | Fixed in 1ece139d: the floor and --check-fix name the reader settings and their WHY; tests. |
| G6 | `readers malformed: ..., so the file is not read, so both import walks fail` (double "so"). | api F3 | Fixed in 1ece139d: WHY ends "; both import walks fail". |
| G7 | `reader_settings` and `read_settings` differ by two letters; dropping one call as a duplicate would silently drop the host readers. | api F4 | Fixed in 1ece139d (comment at the call). |
| G8 | Plan line 204 lists four `--settings` lines. | api F5 | Fixed in 1ece139d. |
| G9 | Roots are about (1 + C) x worktrees for C aliases; the bound comment stated roots, the remedy worktrees; no cap on aliases. | performance F1; security F3 | Comment fixed and re-measured in 1ece139d; cap deferred: override row (revisit: a second alias or 100 worktrees). |
| G10 | The 330,600-per-walk figure goes stale with the alias (868,530 at 49 roots). | performance F2 | Fixed in 1ece139d. |
| G11 | reader_settings runs in every dev-cycle.sh mode; build-loop.sh parses the file twice. | architecture F4; performance F3 | Won't-Fix: override row (~4 ms). |
| G12 | U2b3b2's per-root seeds will multiply with the re-spelled roots. | architecture F5 | Deferred to U2b3b2: override row. |
| G13 | Both lists `none` print `readers 0-roots 0-homes set`; the readers line prints counts, not paths. | api F2, F6 | Won't-Fix: override rows. |

### ✅ Confirmed Good

None asserted on a loop pass (routed endorsements stay pending execution verification until the final pass).

### 🧩 Composition check

- lib reader_settings / build-loop.sh read_settings (architecture F1, api F4): distinct defects (one is duplicated logic, the other a naming hazard at the call).
- lib import_targets 771-773 / 1068-1069 (fact-check Stale, architecture F3, security F2): composed root already stated by security F2 (the fallback reads no refusal); fixed together in 1ece139d.

### ⏭️ Skipped Core Critics

None.

Tokens: fc 152k, critics 109k + 105k + 108k + 107k ≈ 581k.
