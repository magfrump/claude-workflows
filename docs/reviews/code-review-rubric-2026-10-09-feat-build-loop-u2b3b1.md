Commit: 3908e37e
Loop closed at 3908e37e
# Code Review Rubric

**Branch:** `feat/build-loop-u2b3b1` (U2b3b1: the reader settings, `Reader roots:` and `Reader homes:`, for both import walks), on main f8d003c7.
**Status: ✅ ITERATION 3 (confirming pass over 3908e37e) — no red, no amber; the loop converged in 3 iterations: 0 Must Fix; Must Address: 3 fixed (B1, B2, A2's no-main half), 2 acknowledged with revisit triggers (A1, A2's redirect half). Comment-only follow-ups in the commit after 3908e37e. Single-sample review; absence of findings is not an attestation.**

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

## Iteration 2 (Commit f56ba3f5, final confirming pass: no `--loop-pass`, k=3, scope `main...HEAD`, full panel)

Reports: `code-fact-check-report-build-loop-u2b3b1-final.md` (merged from `-final-r1/-r2/-r3`: 1 Incorrect and 2 Stale on plan line 301 and an unchanged comment, 6 Mostly accurate, 2 Unverifiable, the rest Verified, most by execution), `security-review-2026-10-09-u2b3b1-final.md`, `performance-review-2026-10-09-u2b3b1-final.md`, `api-consistency-review-2026-10-09-u2b3b1-final.md`, `architecture-review-2026-10-09-u2b3b1-final.md`. Considered overrides: iteration 1's eight rows (not re-filed by any critic).

### 🔴 Must Fix

None.

### 🟡 Must Address

| # | Finding | Severity | Source | Considered overrides | Status |
|---|---|---|---|---|---|
| B1 | Main's settings named only the host spelling, so a walk run on the host never had `/workspace` as a root and dropped `@/workspace/docs/x.md` (executed: `ok` vs `skip`). | Medium | security final F1 | none | Fixed in 3908e37e: docs/dev-cycle.md names `/home/magfrump/claude-workflows /workspace` and `/home/magfrump /home/node`. |
| B2 | Plan line 301 says import_readers refuses a control byte (readerform does) and that without main the lists stay empty (both walks fail). | Incorrect + Stale (doc) | fact-check final | none | Fixed in 3908e37e. |

### 🟢 Consider

| # | Finding | Source | Status |
|---|---|---|---|
| H1 | G8 re-spelled only worktrees under the main record; one a host session registered beneath a caller root was not spelled beneath main's (executed). | security final F2 (Low) | Fixed in 3908e37e: every spelling re-spells the others; test fails on the one-way lib. |
| H2 | The superset comment's root list omits the re-spelled worktrees. | fact-check (Stale); architecture final A2 | Fixed in 3908e37e. |
| H3 | Walk-failure texts drop their siblings' clauses and nest parentheses; the no-main WHY omits "(origin/HEAD, main or master)"; item 9 lost "never from the environment". | api final F1-F3 | Fixed in 3908e37e. |
| H4 | --check-fix header omits "the file is not read"; "1.5 s per walk" (tree walk 1.7 s); docs path rule; H4 test's no-main step passed one path. | fact-check (Mostly accurate); performance final F1 | Fixed in 3908e37e. |
| H5 | Refused settings detected in three places. | architecture final A1 | Deferred to U2b3b2: override row. |
| H6 | floor and check_fix derive the settings cause alike. | architecture final A3 | Deferred to U2c: override row. |
| H7 | "870,000 over 49" measured 899,730 / 868,530. | fact-check (Mostly accurate) | Won't-Fix: override row. |
| H8 | 8ed86432's "(was 1.3 s)" did not reproduce; 1ece139d's "~30 call sites" unverifiable. | fact-check (Unverifiable) | Commit messages, immutable; noted here. |

### ✅ Confirmed Good

- Every reader_settings and `--settings` readers rule, executed in a 32-case probe (fact-check final r1; r2, r3 alike). Evidence: `scripts/lib/dev-cycle-read.sh` reader_settings; backing: executed Verified.
- A refused reader set is memoized, an import_home failure is not; import_targets fails on refused settings with and without a current memo (executed, all three replicates).

### 🧩 Composition check

- lib import_readers G8 loop / docs/dev-cycle.md settings (security final F1, F2): distinct defects (one is a missing spelling in the data, the other a one-way mapping in the code); fixed together in 3908e37e.

### ⏭️ Skipped Core Critics

None.

Tokens: fc 3 x ~190k, critics 120k + 99k + 104k + 102k ≈ 990k.

## Iteration 3 (Commit 3908e37e, confirming pass, k=1, scope `f56ba3f5..3908e37e`: fact-check + security)

Reports: `code-fact-check-report-build-loop-u2b3b1-confirm.md` (22 claims: 20 Verified, 2 Mostly accurate), `security-review-2026-10-09-u2b3b1-confirm.md` (no Critical to Low; 2 Informational). Lite fix-drift over a code-only scratch commit of the range: no findings. B1 and H1 confirmed by execution (the two-way test fails on f56ba3f5's lib); edge cases of the two-way loop (a caller root equal to the main record, blank entries, `/`, nested roots) fail closed or add only roots.

| # | Finding | Source | Status |
|---|---|---|---|
| I1 | Nested reader roots make the two-way loop add unused roots. | security confirm I1; fact-check confirm observation | Won't-Fix: override row. |
| I2 | Contract item 9's "after it" is unclear. | security confirm I2 | Fixed (comment) after 3908e37e. |
| I3 | "1.5-1.7 s per walk" (1.34 s at low load); a test comment still said "the host alias and HOME". | fact-check confirm (Mostly accurate) | Fixed (comments) after 3908e37e. |
