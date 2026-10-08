Commit: cebfed35
# Code Review Rubric

**Branch:** `feat/build-loop-u2a3c` (U2a3c, main_imports' checkout phase), stacked on U2a3 (5e51b58b, merged as 97aa2d35; to be rebased above U2a3b)
**Status: ⚠️ ITERATION 1 FIXED — re-review pending** (no Must Fix; Must Address fixed or acknowledged with revisit triggers)

## Iteration 1 of 3 (Commit cebfed35, `--loop-pass --range 5e51b58b..HEAD`, k=1)

Scope: `5e51b58b..HEAD` (commit cebfed35), given by the coordinator. The scope is partial: U2a3's code is context only, and U2a3b, the sibling parser unit, is labelled. Delivery mode: self-read. The first-red short-circuit did not fire because the fact-check found no behavioral Incorrect. The full panel ran: security, performance, api-consistency, architecture (structural, auto-selected because the commit adds lib functions and the two-phase walk), and test-strategy (included because this is a fail-closed walk). Stage 2.5 was skipped on this loop pass, so the routed endorsements are *pending execution verification*.

Reports (all `Commit: cebfed35`):
- `code-fact-check-report-build-loop-u2a3c.md`: k=1, 33 claims. 24 Verified, 3 Mostly accurate, 2 Stale, 4 Incorrect, 0 Unverifiable. All four Incorrects concern a test, wording or the commit message.
- `security-reviewer-review-2026-10-06-build-loop-u2a3c.md`: 2 Medium, 1 Low, 1 Informational. No fail-open in the shipped code across about 25 probes.
- `performance-reviewer-review-2026-10-06-build-loop-u2a3c.md`: 1 Low, 2 Informational.
- `api-consistency-reviewer-review-2026-10-06-build-loop-u2a3c.md`: 1 Inconsistent, 6 Minor, 1 Informational.
- `architecture-review-review-2026-10-06-build-loop-u2a3c.md`: 1 Coupling, 3 Minor, 3 Informational. Nothing Structural.
- `test-strategy-review-2026-10-06-build-loop-u2a3c.md`: G1-G5, 32 mutants, and a checked patch, which was applied.

Tests after fixes: 116/116 across build-loop-check (18), build-loop-read, fixture-git-env, hermeticity and dev-cycle (75). Changed code lines against 5e51b58b: 176 (lib 96, tests 80), within the 400 cap. Against main the count is the same, since main's tree equals 5e51b58b.

### 🔴 Must Fix

None.

### 🟡 Must Address

| # | Finding | Severity | Source | Status | Author note |
|---|---|---|---|---|---|
| A1 | `main_checkout` read `main_imports`' local `ent` through dynamic scope. Called with no associative `ent` in scope, the link/gitlink half passes silently, which is fail-open. An indexed `ent` also evaluates path text as arithmetic: `a[$(touch PWNED)]/f.md` ran the command (executed). | Inconsistent / Coupling | api-consistency 1; architecture F1 | Fixed | Now `main_checkout ENT PATH` with `local -n`. It refuses (1) unless ENT is an associative array. |
| A2 | The C1 start-only parent check was unpinned: a start-only mutant survived all 18 tests. The gitlink half for starts (E6) and the `r--` ancestor check for starts (M2s) were unpinned too. | Incorrect (test coverage, high) / test-strategy high | fact-check 22a; test-strategy G1-G3; security F4 | Fixed | Applied the test-strategy patch: an import-free `.claude/rules` start, `pv/` (r--) and `sm/` (gitlink). The start-admission mutant now fails tests 3, 9 and 18 (re-executed). |
| A3 | The plan bullet and commit say "admitted before any checkout path is marked seen", but imports were marked seen first. Starts and imports used different admission orders. | Incorrect (wording) / Minor | fact-check 4, 17b; architecture F2 | Fixed | Imports are now admitted before `seen` is set. The plan bullet names `main_checkout` and every checkout path. The commit message is an Accepted-immutable row. |
| A4 | The cache key ignores the checkout, and the walk now reads checkout contents, so a later edit to a checkout file gets a stale answer (executed P16). | Medium | security F1; architecture F6 | Acknowledged (override row, Defer) | The comment, A5 and the U2b bullet say the caller clears `IMPORTED_MAIN_DONE`. Trigger: the first caller (U2a4/U2b). |
| A5 | A FIFO start is unlisted by git, so it is never admitted or refused: walk ok, and its import answers `-` (executed P6). | Medium (Low confidence) | security F2 | Acknowledged (override row, Defer) | Added to A5 and the block comment's not-covered list. Trigger: the A5 host probe or U2b. |
| A6 | Stale/inert comments and test lines: test 10's "no index-only start masks…" and the `git rm` lines at :92, :191, :244; header :29-35 grouped `main_imports` with "never the working tree"; `checkout_md` said "warns" (it fails on any stderr or a nonzero exit); `main_checkout` said "parent" (it means any ancestor). | Incorrect / Stale / Mostly accurate | fact-check 6, 10b, 11, 26, 30; api-consistency 5; test-strategy G5 | Fixed | |
| A7 | The U2b bullet no longer names the checkout, and it omitted what the caller owes the walk. | Minor | api-consistency 6 | Fixed | The bullet now lists: a final checkout or a cleared cache, git with no `ls-files` stderr, and the caller-owned git environment. |

### 🟢 Consider

| # | Finding | Source | Status |
|---|---|---|---|
| C1 | A missing path still forked `realpath` per ancestor through `blocker` (200 missing imports at depth 30: 0.5 s → 7.6-10 s) | performance F1 (Low) | Fixed: `[[ -e \|\| -L ]] \|\| return 2` after the ancestor loop |
| C2 | The `.md` pathspec was written twice (the override-row trigger "U2a3c's phase-2 seed listing" fired) | api-consistency 4; architecture F5 | Fixed: `md_ls` holds the one pathspec |
| C3 | `dev-cycle.bats`'s lib-function list lacked the new functions | api-consistency 7 | Fixed (`md_ls`, `checkout_md`, `main_checkout` added) |
| C4 | The gate depends on `blocker`, the digest's skip rule | architecture F4 | Fixed: named in `main_checkout`'s comment |
| C5 | An index-only start deleted from the checkout is skipped, untested | test-strategy G4 | Fixed (test 3), pinned as intended: absent loads nothing |
| C6 | TOCTOU between admission and read (snapshot assumption) | security F3; performance F3 | Won't-Fix (override row); assumption written in the comment and A5; directory half routed to U2a3b, where it is already fixed |
| C7 | Per-start walk cost for ignored trees | performance F2 | Defer (override row, B6 trigger) |
| C8 | Three-valued return; naming; per-path answers; read arm by `ent` absence | api-consistency 2, 3, 8; architecture F7 | Won't-Fix (override rows) |
| C9 | A main import of a path that is also an untracked start is recorded only by line order; untested | architecture F3 | Defer (override row); ordering commented |
| C10 | Mutants M3/M18 (the `-r` check and the read failure arm back each other up) and M13 (phase order) survive | test-strategy | No action: each cannot change the answer, and dropping both is caught by test 9 |

### ↩️ Considered Overrides

Matched rows from `docs/reviews/override-log.md`:
- `feat/build-loop-u2a3` cache-key row (Defer, "no caller yet"). Re-fired as A4 with a wider premise, so a new row supersedes its scope.
- C3 row (Defer to U2a3c). Closed here: test 18 covers `r--` and 000 directories, and `checkout_md` fails on stderr.
- Two-phase row (C12). Realised by this unit.
- Pathspec-twice row (:402). Its trigger fired and it is fixed (C2).
- Bypass-candidates row (GIT_INDEX_FILE, fsmonitor, sparse checkout, `core.ignoreCase`). Security reproduced `core.ignoreCase=true` and `GIT_WORK_TREE` fail-opens and did not re-file them. They stay with the caller, now named in the U2b bullet.
- A5's settled not-covered shapes. Not re-filed.

### Re-flagged settled decisions

None. No finding matched a Won't-Fix or Accepted-immutable row.

### Routed to U2a3b

- The checkout read of a path swapped for a directory reads as no imports, because this branch's `import_targets` swallows grep's read error. U2a3b's parser returns 1 there (security F3). No action here.

### ⏭️ Skipped Core Critics

None.

### 🧩 Composition check

- `scripts/lib/dev-cycle-read.sh` main_checkout and the import site (:531-545, :634-640). Fragments: fact-check 4/17b, architecture F1/F2, api-consistency 1. Disposition: distinct defects. The admission order and the `ent` coupling each name their own mechanism and fix.
- Test 18 (build-loop-check.bats :317-333). Fragments: fact-check 22a, test-strategy G1-G3, security F4. Disposition: distinct defects (three different unpinned arms). The fact-check and security agree on G1.
