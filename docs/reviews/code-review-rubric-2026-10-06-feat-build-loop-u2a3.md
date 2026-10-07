Commit: cc1aa864
# Code Review Rubric

## Iteration-4 gate decision: split (user, in session, 2026-10-06)

Decision: **split**. The user answered the gate in session on 2026-10-06 (relayed by the coordinator; no questions.md entry, since the user answered directly). U2a3 becomes the main-only walk on this branch (no history rewrite); the checkout-side reads move to U2a3c (`feat/build-loop-u2a3c`), built as the two-phase walk and stacked above U2a3b. U2a3's loop restarts with a fresh counter (loop 2, below); loop 1's record follows it unchanged.

Disposition of loop 1's open rows in the split commit:
- C1 (untracked start skips the parent check): removed. An untracked start fails the walk until U2a3c; U2a3c's phase 2 runs the parent check on every checkout path, starts included.
- C2 (gitlink parent): fixed. A 160000 parent fails the walk like a 120000 one.
- C3 (unsearchable checkout directory): Defer (override row). U2a3 reads no checkout content; U2a3c fails on it.
- C4 (here-string at the link-text split): fixed (`mapfile -d /` from a process substitution).
- C5 (wording): fixed. Header, block comment, return-1 comment, A5, F11 and the plan bullets rewritten for the main-only walk.
- C6: Accepted-immutable rows (unchanged).
- C7 (parent-check tests): fixed (test 15: `want ... imported` after each failure, and a one-letter link two levels up).
- C8 (O(L^2) parent loop): fixed (steps over `/` with `${c%/*}`).
- C9: Won't-Fix (override row). C10 (nul_list partial array): fixed (emptied on failure). C11 (test 9 comment): fixed. C12: taken as the split (override row).

## Loop 1 (pre-split), closed at the cap

**Scope:** full branch `main...feat/build-loop-u2a3`; iteration 3 (final confirming pass, no `--loop-pass`, k=3, full panel) at cc1aa864, iteration 2 at 34edec56, iteration 1 at 45ad17b0; 400 changed code lines by pr-prep 1a (at the cap) | **Reviewed:** 2026-10-06 | **Status: ❌ CAP REACHED: iteration 3 ended with one behavioral red (C1) and three ambers open; iteration 4 needs a written escalate / split / abandon decision (not taken here; escalated to the caller)**

## Iteration 3 of 3: final confirming pass (Commit cc1aa864, full branch, k=3, full panel)

A first start of this pass at 2a3e499f was aborted before any report, because the coordinator routed three U2a3b findings here (I2-C2, I2-C3, I2-C4); they were fixed in c42f017f and the pass re-ran at cc1aa864. It stays iteration 3.

Delivery mode: self-read. Fact-check Gate: one high-confidence behavioral Incorrect (C1); proceeded with critics (autonomous run; the terminal pass never short-circuits). Stage 2.5 not run: security routed 3 endorsement claims and performance 2, all **pending execution verification**; with the cap reached no ✅ rows are issued, so the stage was skipped to save a dispatch (deviation noted).

Reports (all `Commit: cc1aa864`): `code-fact-check-report-build-loop-u2a3-final.md` (merged k=3 from `-f-r1/-f-r2/-f-r3`: 41, 31, 31 claims; merged 51 clusters: 30 Verified, 12 Mostly accurate, 9 Incorrect; agreement 32/51, 62.7%); `security-reviewer-review-2026-10-06-final-build-loop-u2a3.md` (2 Medium, 1 Low, 1 Informational); `performance-reviewer-review-2026-10-06-final-build-loop-u2a3.md` (1 Low, 1 Informational); `api-consistency-reviewer-review-2026-10-06-final-build-loop-u2a3.md` (1 Minor, 2 Informational); `architecture-review-review-2026-10-06-final-build-loop-u2a3.md` (0 Structural, 1 Coupling, 1 Minor, 2 Informational); `test-strategy-review-2026-10-06-final-build-loop-u2a3.md` (G1-G6, 46 mutants). Fix-drift: `lite-review-fix-drift-build-loop-u2a3-i3.txt` (its one finding declined: the root and FIFO causes go through the generic not-plain arm; confirmed by all three replicates).

Tests at cc1aa864: 114/114 across the five suites (all three replicates); shellcheck clean.

Iteration-2 verification: B1 (path main lacks under a main directory link) is fixed for imports but not for starts (C1, a different producer of the same shape, not a re-fire of the same location). B2's MAIN_BY_NAME half fixed. Routed I2-C2/C3/C4 fixed (C4's second here-string at :596 remains, C4 below).

### 🔴 Must Fix

| # | Finding | Severity | Source | Status | Author note |
|---|---|---|---|---|---|
| C1 | An untracked start file is marked seen before the walk (lib :571-572), and the parent-link refusal (:613-614) runs only after the seen test (:610), so a start at a path main lacks under a directory main stores as a symlink skips it. Main with `ld -> deep` and `@ld/CLAUDE.md`, checkout with `ld` a plain directory holding untracked `ld/CLAUDE.md`: walk ok, `deep/CLAUDE.md: -`; with `.claude/rules -> ../docs` on main, non-start targets (`docs/foo.md`) also answer `-`. Breaks the header's "the checkout can only add imports or fail it" | Incorrect (behavioral) / Medium / Coupling | fact-check Claims 19, 20, 24 (r2, executed); security F1 (executed, wider exposure); architecture F1; api 1; test-strategy G3. Convergence | Open (cap) | Tested fix, net 0 lines: move the parent loop into the `t:` arm on `$f` before `inrepo_here` (architecture; 16/16 in a scratch copy), or run it before the seen test guarded by `[[ -z "${ent[$p]+set}" ]]` (security). Needs a test, which does not fit the 400 cap. |

### 🟡 Must Address

| # | Finding | Severity | Source | Status | Author note |
|---|---|---|---|---|---|
| C2 | An import into a gitlink path reads the checkout's submodule; uninitialised (the default after `git worktree add`), `@sub/x.md` whose x.md imports `../docs/y.md` gives walk ok, `docs/y.md: -` | Medium | security F2 (executed) | Open (cap) | One-line fix: treat a 160000 parent like 120000 in the parent check (probed, suite not run). Distinct from rows 366/373 (starts inside a submodule). |
| C3 | A target main lacks under a mode-000 checkout directory reads as absent (walk ok, imports dropped); `git ls-files --others` exits 0 with only a warning on an unreadable directory, so "listed whole" is unenforced; comments say "a checkout file it cannot read" fails | Incorrect (comment) / Low / Minor | fact-check Claim 26 (r2); security F3; architecture F2; test-strategy G4 | Open (cap) | Contract decision: fail on an unsearchable ancestor and on ls-files stderr, or narrow the claims (header, block comment, A5, F11). Only untracked checkout content is affected. |
| C4 | A second here-string at :596 (`IFS=/ read -ra parts <<<"$out"`); link text past 64 KiB with a silently failing temp write skips the `..` check | Incorrect / Informational | fact-check Claim 34 (r1, r2; r3 too); security F4; architecture F3 | Open (cap) | Unreachable through a real symlink (4095-byte cap, executed). Fix: mapfile split or reject text over 4095 bytes. |
| C5 | Wording: block comment, A5, F11 and the U2a3 bullet omit the root/FIFO refusal; header's checkout-input list narrower than the code; override rows :374 (lower is not the only unguarded command) and :379 (blob+tree fails only when an import reaches below it) | Mostly accurate | fact-check (r1, r3), api 3 | Open (cap) | |
| C6 | Commit messages: e7b5d7ed ("makes the header's ... true", the isimported sentence), c42f017f (`ulimit -f 0` "read as no imports": default SIGXFSZ kills the shell) | Incorrect (commit message) | fact-check Claims 45, 46, 49 | Accepted-immutable (override rows) | 34edec56 already at row :380. |

### 🟢 Consider

| # | Finding | Source | Status |
|---|---|---|---|
| C7 | Parent-link check only tested at the immediate parent; dropping its error reset is unpinned (mutants N33, N34, N37 survive); Appendix A (+3 lines) kills them | test-strategy G1, G2 | Open (needs 3 lines over the cap) |
| C8 | Parent loop is O(L^2) in path length: one 64 KB `@` token costs 6-20 s (slow gate, not fail-open) | performance F1 | Open |
| C9 | Process substitution adds ~0.3-0.6 ms per queued file | performance F2 | Fold into row 355's batching |
| C10 | nul_list leaves partial output plus `rc=1` in the array on failure | api 2 | Open (document or clear before U2a3b reuses it) |
| C11 | Test 9's first sub-case now trips the parent check, not the checkout-symlink arm its comment names | test-strategy G6, fact-check r1 | Open |
| C12 | Convergence: main's side converged; every live i3 shape comes from checkout input. A two-phase walk (main alone to a fixpoint, then the checkout appending) makes "checkout only adds or fails" hold by construction, ~10-15 lines | architecture F4 | Recommendation |

### Re-flagged settled decisions

None re-raised by critics; security cites rows 366 and 373 as related to C2 (a distinct shape).

### 🧩 Composition check (iteration 3)

- lib :571-572 + :610-614 (fact-check 19/20/24, security F1, architecture F1, api 1, test-strategy G3): one defect, stated whole by each; no composed row (C1).
- lib :580-583 + :517 (fact-check 26, security F3, architecture F2, test-strategy G4): one defect (checkout "cannot tell" read as absent), stated whole; no composed row (C3).
- lib :614 (test-strategy G1/G2, performance F1): distinct defects (test coverage vs cost).

## Iterations (3 completed)
1. 45ad17b0: fact-check only (short-circuit): link text `..` after a directory link read lexically. Fixed.
2. 34edec56: full panel: a path main lacks under a main directory link dropped when the checkout lacks the link; cache key; test gaps. Fixed or override rows.
3. cc1aa864 (final, after the routed U2a3b fixes): C1-C12 above.

## Remaining Must Fix
C1.

## Remaining Must Address
C2, C3, C4, C5 (C6 is Accepted-immutable).

## Convergence diagnosis (one sentence)
The main-commit side converged after iteration 1, but each pass finds a new shape where checkout input (untracked starts, targets main lacks, unreadable or uninitialised checkout directories) slips past a check placed at one producer, and the unit sits at the 400-line cap so neither the tests nor the structural fix fit.

## Recommended action (ship-with-issues / split-PR / pause for redesign)
split-PR (recommended, pending the user's or coordinator's written decision): land the two net-zero fixes for C1 and C2 plus the C3-C5 wording here only if a waiver or split makes room for C1's test; otherwise split the checkout-side reads (untracked starts, targets main lacks) into their own stacked unit built as the architecture critic's two-phase walk, leaving U2a3 as a main-only walk. Iteration-4 gate: no option selected here (the caller asked to stop and report).

## Iteration 2 of 3 (Commit 34edec56, full branch, --loop-pass --full, k=1, full panel)

Scope: `--full` explicitly, since iteration 1 short-circuited before any critic ran; the short-circuit was already used, so Stage 2 ran in full with amber collected. Delivery mode: self-read. Critics: security, performance, api-consistency, architecture (new lib function and cache), test-strategy (--include). Stage 2.5 skipped (loop pass); the performance endorsement on `ls-files --others` and nested worktrees stays pending execution verification.

Iteration-1 verification: A1 (the `..` after a symlink) resolved — fact-check i2 Claim 1 executed every listed shape, security confirmed, and the checkout half is now pinned (test-strategy G5). A2-A4 resolved. No re-fires of iteration-1 fixed findings (B1 is a different shape: no `..`, flagged against the iteration-1 fix-drift comment).

Reports (all `Commit: 34edec56`): `code-fact-check-report-build-loop-u2a3-i2.md` (k=1, 26 claims: 20 Verified, 2 Mostly accurate, 2 Incorrect, 2 Unverifiable); `security-reviewer-review-2026-10-06-build-loop-u2a3.md` (4 Medium, 1 Informational; Claude Code's side not executed); `performance-reviewer-review-2026-10-06-build-loop-u2a3.md` (1 Low, 1 Informational); `api-consistency-reviewer-review-2026-10-06-build-loop-u2a3.md` (2 Minor, 2 Informational); `architecture-review-review-2026-10-06-build-loop-u2a3.md` (0 Structural, 0 Coupling, 3 Minor, 3 Informational); `test-strategy-review-2026-10-06-build-loop-u2a3.md` (G1-G10, 49 mutants, patch). Iteration-1 fix-drift output: `lite-review-fix-drift-build-loop-u2a3-i1.txt`.

### 🔴 Must Fix

| # | Finding | Severity | Source | Status | Author note |
|---|---|---|---|---|---|
| B1 | A path main lacks under a directory main stores as a symlink (`ld -> deep`) was read from the checkout; a checkout without `ld` dropped it, so link text `CLAUDE.md -> ld/evil.md`, a chain, or an `@ld/x.md` token answered ok with `deep/secret.md: -`. Breaks the header's "the checkout can only add imports"; 34edec56's comment "(link text is checked above)" was false | Incorrect (contract) / Medium | fact-check i2 Claims 3, 19 (Q10, Q11); security F1 (executed); api 2; test-strategy G8. Convergence | ✅ Fixed | Before queueing a path main lacks, the walk fails if any parent is a symlink on main; comments, A5, F11 say so. Test: the "...under a link main stores" test (link and token forms); mutant killed. |

### 🟡 Must Address

| # | Finding | Severity | Source | Status | Author note |
|---|---|---|---|---|---|
| B2 | Cache key ignores checkout state (untracked start added later unseen; executed) and MAIN_BY_NAME (G9) | Medium (Low conf.) / Minor | security F4, architecture F1, api 4, test-strategy G7, G9; fact-check escalation | MAIN_BY_NAME ✅ fixed; checkout: Defer (override row) | Comment states the reset contract; trigger U2a4/U2b calling it twice per process. Cache tested (G6). |
| B3 | Symlinked instruction file's imports resolved from the target's directory only | Medium (Low conf.) | security F2 | Defer (override row) | A5 lists it untraced; trigger: a host probe of Claude Code. |
| B4 | `.claude/commands/` `@` references are not starts (B14 candidate) | Medium | security F3 | Defer (override row) | Same trigger; needs a root base. |
| B5 | Lib header listed two checkout inputs; the not-covered list three copies disagree | Minor | api 2, architecture F5 | ✅ Fixed (header names three; lib, A5, F11 agree) | |
| B6 | Commit messages 4f087967 ("resolves") and 34edec56 (subject) | Mostly accurate / Incorrect (commit message) | fact-check i2 Claims 11, 3, 19 | Accepted-immutable (override row) | |
| B7 | D8 row's stated reason (`*) continue`) and its missed exposure | Mostly accurate / Informational | fact-check i2 Claim 22b, security F5 | Superseding row | |

### 🟢 Consider

| # | Finding | Source | Status |
|---|---|---|---|
| B8 | Untested: 100755 arm, main blob not checkout, untracked `.claude/rules` starts, link chain, `-L` half, cache (G1-G6) | test-strategy | ✅ Fixed (tests folded into existing ones for the 400 cap; 4 named mutants killed) |
| B9 | Start files answer `-` unless imported | architecture F2 | ✅ Fixed (comment) |
| B10 | errexit off under `isimported main`; IMPORTED_MAIN set before the walk ends | architecture F3 | Defer (override row) |
| B11 | No reason word in IMPORTED_MAIN=error | api 1, 3 | Defer to U2a4 (override row) |
| B12 | Ignored .md files price the walk (~4 s at 100k) | performance F1 | Defer (override row) |
| B13 | ~12 ms per followed symlink | performance F2 | Won't-Fix (override row) |
| B14 | `@ld/../q.md` token lexical vs kernel; "Node's path.resolve" claim | security P15, fact-check i2 Claim 12b | Defer (override row) |
| B15 | link_target helper; three copies; row 351 trigger | architecture F4-F6 | Won't-Fix (override row) |
| B16 | blob+tree name prints git's fatal line | test-strategy G10 | Won't-Fix (override row) |
| B17 | fix-drift artifact missing from the branch | fact-check i2 Claim 20 | ✅ Fixed (committed) |

### Re-flagged settled decisions

- Backslash-escaped space in a token (`@docs/my\ file.md`; fact-check i2 escalation): matches the `feat/build-loop-u2a` "backslash or trailing-`_` token form" row (Defer). No action — see override-log.
- Per-record bash cost (performance, measured 0.46-0.67 s): the B6 row. No action — see override-log.

### 🧩 Composition check (iteration 2)

- lib main_imports' queueing (:612) and link-text arm (:583-603): fact-check Claims 3/19, security F1, api 2, test-strategy G8 — distinct statements of one defect, each complete; no composed row (B1).
- lib cache key (:549-550): architecture F1, api 4, security F4, test-strategy G7/G9 — one defect, stated whole by each; no composed row (B2).

---

## Iteration 1 detail (45ad17b0)

## Iteration 1 of 3 (Commit 45ad17b0, full branch, --loop-pass, k=1)

Delivery mode: self-read (a shared context file, then each agent runs `git diff main...HEAD`; U2a2 precedent). Loop-pass short-circuit: behavioral 🔴 confirmed at fact-check (Claim 11b, P4), so the critics were skipped and the pass returned to the loop for the fix. No enforcement file in the diff (`hooks/live-verify-gate.sh` regex), so mechanic 7 does not force security.

Reports: `code-fact-check-report-build-loop-u2a3.md` (k=1, 32 claims: 24 Verified, 4 Mostly accurate, 3 Incorrect (one defect in three places), 1 Unverifiable; probes in /tmp/u2a3-cfc-i1-S05k/).

Override-log scan: the `feat/build-loop-u2a2` rows dated 2026-10-06 matched: D8 (nested repo / submodule starts, Defer, trigger "U2a3's review") is the same claim as P5; the B6 row (`feat/build-loop-u2a3`, per-record cost) was not re-filed.

## 🔴 Must Fix

| # | Finding | Severity | Source | Status | Author note |
|---|---|---|---|---|---|
| A1 | Symlink text on main is resolved with `realpath -ms` (lib main_imports' 120000 arm), which collapses `ld/..` without reading `ld`; the kernel follows `ld` first. Main with `ld -> deep/inner` and `CLAUDE.md -> ld/../evil.md`: Claude Code loads `deep/evil.md`, the walk read `evil.md` and was ok with `deep/secret.md: -`, with or without `ld` in the checkout. The "Not covered" list's "when the checkout does not have that link" is wrong for link text (executed) | Incorrect (behavioral; fail-open) | fact-check Claim 11b (P4), 2b, 3b | ✅ Fixed (iteration-1 fix commit) | Link text is resolved a component at a time; a `..` after a symlink on main or in the checkout fails the walk. Import tokens stay lexical, as Node's path.resolve is. Test: "main walk fails on symlink text with a .. after a symlink..."; mutant killed. |

## 🟡 Must Address

| # | Finding | Severity | Source | Status | Author note |
|---|---|---|---|---|---|
| A2 | The "Not covered" list, known issue A5 and plan F11 omit start files in a submodule or an untracked nested repo (walk ok, `docs/n.md: -`; executed) | Incorrect (comment/doc omission) | fact-check Claims 11b (P5), 2b, 3b; carries the U2a2 D8 row | ✅ Fixed (docs); code: Defer (override row) | Listed as not covered in all three places; U2b names the checkout. |
| A3 | The return-1 comment omits the short lower-cased start list (`[[ ${#low[@]} -eq ${#cand[@]} ]] \|\| return 1`) | Mostly accurate | fact-check Claim 13 | ✅ Fixed | |
| A4 | Plan's U2a3 bullet omits the leaves-the-repo and unreadable-checkout-file refusals | Mostly accurate | fact-check Claim 4 | ✅ Fixed | |
| A5 | fbeae280's B5 test numbering and its .claude/rules symlink note | Mostly accurate (commit message) | fact-check Claims 22, 27 | Accepted-immutable (override row) | |

## 🟢 Consider

| # | Finding | Severity | Source | Status | Author note |
|---|---|---|---|---|---|
| A6 | "a checkout keeps the last" copy of a doubled name, not executed | Unverifiable | fact-check Claim 14b | Won't-Fix (override row) | The refusal does not depend on it. |

## Escalations carried to iteration 2's critics

- security: P4 (fixed; check the fix) and P5 (documented) — fact-check E-list.
- architecture, security: the cache key (`IMPORTED_MAIN_DONE="$MAIN_SHA $ROOT_REAL"`) ignores checkout state, so an untracked start file added after a successful walk is not seen by a second call in the same shell; it also ignores MAIN_BY_NAME (fails closed only).
- test-strategy: no test of an untracked `.claude/rules` start, a symlink chain on main, or the cache.

## ↩️ Considered Overrides

`feat/build-loop-u2a2` D8 (nested repo / submodule starts): matched P5; its trigger fired here; resolved as documentation plus a new Defer row. `feat/build-loop-u2a3` B6 (per-record cost): not re-filed.

## ⏭️ Skipped Core Critics

| Critic | Reason |
|---|---|
| security-reviewer, performance-reviewer, api-consistency-reviewer, architecture-review, test-strategy | loop-pass short-circuit (behavioral red confirmed) |

## 🧩 Composition check

No multi-source co-located clusters qualified (one source this pass).
