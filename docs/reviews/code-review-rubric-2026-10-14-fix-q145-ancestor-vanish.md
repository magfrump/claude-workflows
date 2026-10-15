Commit: 0d573a7b
Loop-pass short-circuit: used at 3a8164d5

# Code Review Rubric: fix/q145-ancestor-vanish

**Scope:** `main...HEAD` (full branch both passes; no earlier rubric, and iteration 2 re-reviewed the whole branch because d2dc88c9 rewrote the change) · **Delivery mode:** inline-diff-only (the lib is ~100 KB; agents read config_seeds, top_files and nul_list themselves) · **Fact-check:** k=1 per loop pass (decision 031): `code-fact-check-report-2026-10-14-q145-i1.md`, `-i2.md`
**Status:** iteration 2 fixes in the fix-batch commit; final confirming pass pending.

## Iteration 1 (3a8164d5): short-circuited at fact-check

Fact-check (18 claims: 12 Verified, 2 Mostly accurate, 4 Incorrect). Behavioral red: `-ignore_readdir_race` skips a vanished *file* but findutils 4.9.0 still reports a vanished *directory* (a session's `mktemp -d` in /tmp) with exit 1, so the flake class stayed open; the comments and ba5d2d1d's subject claimed every entry was skipped (Claims 2a, 3, 5a, 15). The affected-suites run at ba5d2d1d independently failed tests 43 and 45 with `find: '/tmp/tmp.Hblz7Uiz3O': No such file or directory`. Critics skipped: loop-pass short-circuit (behavioral red confirmed); the lib is not an enforcement file, so mechanic 7 did not apply.

| ID | Finding | Source | Status |
|---|---|---|---|
| R1 | A directory entry that vanishes between readdir and stat still fails the listing | fact-check Claims 2a, 5a, 15; suites run | Fixed in d2dc88c9: `top_files` helper, tried up to three times (first two with stderr dropped), only an error-free listing used; test gained a directory case |
| A1 | config_seeds' header omitted the -d recheck as a return-1 cause; "every ancestor is a top" (only those below no reader root); a linked top whose target vanished is listed by find 4.9 with exit 0, so only the recheck catches it | fact-check Claims 3, 4, 6a | Fixed in 0d573a7b (comments) |

## Iteration 2 (0d573a7b): full panel

Fact-check: 23 claims, 17 Verified, 6 Mostly accurate, 0 Incorrect; all iteration-1 Incorrects resolved. Critics: security (1 Medium low-confidence, 2 Informational), performance (1 Low), api-consistency (3 Minor, 2 Informational). Architecture, test-strategy, tech-debt, dependency and UI critics not triggered (tests changed; 4 files; one new internal helper). Executed evidence: affected suites 238/238 under a churner making short-lived files and directories in the bats tmp root (no `No such file` line in the log); a first churn run with TMPDIR under ~/.claude failed 4 unrelated tests because that ancestor is a real config dir and a ref name cannot hold `.claude`, and also had no vanish error.

## 🔴 Must Fix

None open (R1 fixed).

## 🟡 Must Address

| ID | Finding | Location | Source | Status |
|---|---|---|---|---|
| A2 | A file deleted and re-created during the listing (non-atomic save) is skipped when the gap spans find's stat; main failed closed there | `scripts/lib/dev-cycle-read.sh` config_seeds/top_files | security F1 (Medium, low confidence) | Acknowledged: main misses the same save when the gap spans readdir; the comment now names it as not covered; override row with revisit trigger |
| A3 | The -d recheck sat only at the call site, so top_files' contract was call-site dependent (a second caller would miss a vanished or dangling linked DIR) | top_files | api F3, fact-check Claim 10, security correction | Fixed: recheck moved into top_files (empties NAME, fails, so it is retried and fails all three tries); header says it also lists a linked DIR itself |

## 🟢 Consider

| ID | Finding | Source | Status |
|---|---|---|---|
| C1 | "any other error still fails the walk" holds only for errors that persist across the three tries; transient errors of any kind are retried away | fact-check 1b, security F2 | Fixed (walk header and listing comment) |
| C2 | config_seeds' header implied three tries only for a vanishing entry | api F2 | Fixed |
| C3 | Test knobs `T_ONCE`/`T_RMTOP` used the `T_` prefix that the file documents as imps inputs | api F1 | Fixed: `SHIM_ONCE`/`SHIM_RMTOP` |
| C4 | Test comment "after three tries" was wrong for the drop case | fact-check 15 | Moot after A3: the drop case now fails three tries (log `0 0 0`, asserted) |
| C5 | FP-173's ref named only the files-only fix | fact-check 22 | Fixed: `ref:d2dc88c9` |
| C6 | A line of the listing comment ran to ~120 characters after a hand reflow | self (fix batch) | Fixed |
| C7 | Commit-body wording in d2dc88c9 / 0d573a7b | fact-check 16, 20 | Won't-Fix (override row) |
| C8 | Directory churn by another user can still fail all three tries | security F3 | Won't-Fix: fails closed (override row) |
| C9 | Test adds ~7 s | performance F1 | Won't-Fix (override row) |
| C10 | `nl_a` nameref collision, inherited from with_at | api F4 | Won't-Fix (override row) |
| C11 | top_files wraps nul_list itself (with_at's pattern) rather than streaming (root_starts') | api F5 (Informational) | No action: both patterns are in the lib |

Mutation evidence for the test (fix batch): main's lib, no retry, no `-ignore_readdir_race`, and no -d recheck each fail it.

## Considered overrides

No prior overrides matched this diff.

## 🧩 Composition check

One qualifying cluster: top_files / the config_seeds call site (fact-check Claim 10, api F3, security's correction): one root, "the -d recheck belongs in the helper whose contract it completes", stated by api F3 itself; distinct composition not needed.

## ⏭️ Skipped Core Critics

Iteration 1: security, performance, api-consistency (loop-pass short-circuit, behavioral red confirmed). Iteration 2: none.
