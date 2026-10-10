Commit: f782d9ee
# Code Review Rubric

**Branch:** `feat/build-loop-u3a2` (U3a2: `--merge BRIEF --expect SHA` lands a self-merge brief by compare-and-swap, or by a fast-forward in the worktree that has main checked out; check_line's verdict as values), on main 6666a5ce.
**Status: 🟡 ITERATION 2 (`--loop-pass`, k=1, scope `7d78e6d0..f782d9ee`, full panel) — no Must Fix; 1 Must Address (B1), fixed in the iteration-2 fix batch (unreviewed); iteration 1's A1-A3 confirmed resolved.**

## Iteration 2 (Commit f782d9ee, `--loop-pass`, k=1, scope `7d78e6d0..f782d9ee`, full panel)

Partial scope (the iteration-1 fix batch; the rest of the branch labelled context). Fact-check k=1 (`code-fact-check-report-u3a2-i2.md`): 28 claims, 22 Verified, 6 Mostly accurate, 0 Incorrect; A1-A3 confirmed resolved by execution; 9 mutants on a copy, 7 caught (maintenance.auto and the CHANGED fill survived). Critics (opus, parallel; `*-review-2026-10-10-u3a2-i2.md`): security (1 Medium, executed; 1 Info), performance (1 Info), api-consistency (2 Minor, 1 Info), architecture (4 Info). No re-fire of an iteration-1 finding; no override row re-flagged. Lite fix-drift check over the i1 fix commit: 2 findings, both refuted (land does run git status in W; GIT_CONFIG_NOSYSTEM is exported at the top).

### 🟡 Must Address

| # | Finding | Source | Status |
|---|---|---|---|
| B1 | With main checked out in a linked worktree W other than the gate's checkout, W's config.worktree was first state-gated after `git -C W status` had run, so a clean filter it names ran inside the gate (and one that deleted its config afterwards let the run print merged). Pre-existing since 7d78e6d0, kept by the fix batch. | security F1 (Medium, executed) | Fixed: state_gate in W as soon as W is known, before any git command there; test with a filter marker (fails without the fix). |

### 🟢 Consider

| # | Finding | Source | Status |
|---|---|---|---|
| D1 | A paused `rebase --update-refs` that will move main went unseen; an unreadable rebase or bisect file read as empty. | security F2; security listed | Fixed: update-refs read; unreadable state refuses; tests. |
| D2 | Header: reflog text exact only for update-ref; "from the environment" too broad (EMAIL refused); path-line wording; "Sets NEW, or MERGE_WHY". | api N1-N3; fact-check 3, 4a, 13, 15c | Fixed. |
| D3 | land writes "self-merge" while the caller holds the check; verdict_ok wrote check_line's `i`. | architecture 1, 4 | Fixed: `land AUTHORITY`; `local i`. |
| D4 | Nothing tests maintenance.auto=false. | performance F1; fact-check 26 (M7) | Fixed: loose-objects maintenance on in the fixture, pack count unchanged (fails without the flag). |
| D5 | The trailer is one literal; land not split; CHANGED placement mutant; C9 commit wording; listed-not-tested candidates. | architecture 2, 3; fact-check 25, 26 (M8); security listed | Rows (Defer / Defer / Won't-Fix / Won't-Fix / Defer). |

## Iteration 1 (Commit 7d78e6d0, `--loop-pass`, k=1, scope `main...HEAD`, full panel)

Delivery mode: self-read (agents read their skill files and ran `git diff main...HEAD` in the worktree). Fact-check k=1 (`code-fact-check-report-u3a2-i1.md`): 21 claims, 14 Verified, 5 Mostly accurate, 1 Incorrect (2b, doc/contract class: 🟡 under policy T, no short-circuit), 1 Unverifiable. Critics (opus, parallel; `*-review-2026-10-10-u3a2-i1.md`): security (1 Medium, 1 Low, 2 Info, reproduced), performance (1 Low, 1 Info), api-consistency (4 Minor, 3 Info), architecture (3 Minor, 3 Info). Stage 2.5 skipped (loop pass): security's four routed endorsements (commit tree and parents are the judged values; the no-W path moves main only by CAS; harden outranks W's config during the ff; the identity regex blocks header injection) stay pending execution verification.

Considered overrides: rows 215, 494 (now re-run before the move), 501, 509, 512 (built here), 524, 613, 625 (its re-read is gone), 639, 642, 646. None re-fired.

### 🟡 Must Address

| # | Finding | Source | Status |
|---|---|---|---|
| A1 | `branch.<main>.mergeOptions` (not state-gated) turns the fast-forward in W into a `--squash`: main stays, but W is left with the merge staged, SQUASH_MSG and ORIG_HEAD, and a later commit there lands it without the trailer (reproduced). | security F1 (Medium) | Fixed: `-c branch.$MAIN.mergeOptions=` on the merge; test sets `--squash` and lands clean (fails without the fix). |
| A2 | "it never guesses one from the host name" / "none known refuses" is false: git var guesses from the passwd name and the domain; test 3 passed only because this host has no domain. | fact-check 2b (Incorrect); api F1; security F2 (Low) | Fixed: `git -c user.useConfigOnly=true var`; test with names in env and the email only in EMAIL refuses (fails without the fix). |
| A3 | The header omitted refusals land produces (two worktrees, W missing, commit not written, worktrees/git dir unreadable, git status failing), the reflog and W's writes, that --merge can stop part way, and that path lines follow land's refusal. | fact-check 3, 4, 5; api F4 | Fixed (header rewritten from land's MERGE_WHY list). |

### 🟢 Consider

| # | Finding | Source | Status |
|---|---|---|---|
| C1 | The fast-forward starts `git maintenance run --auto`; repo `maintenance.*` tasks repack the store store_check read; the gc.auto comment overclaimed. | performance F1 (Low); security F3; fact-check 13 | Fixed: `-c maintenance.auto=false`; comment reworded. |
| C2 | The two moves write different reflog messages. | api F3 | Fixed: GIT_REFLOG_ACTION; both asserted. |
| C3 | land wrote the merge commit before deciding; the message write was unchecked. | architecture 2; security F4 | Fixed: decide, write (checked), re-gate, move. |
| C4 | Policy decided in check_line and land. | architecture 1 | Partly fixed (refusal moved to the merge arm); authority value deferred to U3a3 (row). |
| C5 | Output still by line position. | architecture 3 | Row (trigger U3b / U3a3). |
| C6 | CHANGED filled before the verdict; the verdict_ok comment was wrong about bash scope. | architecture 4 | Fixed: filled in verdict_ok; comment corrected. |
| C7 | The repository rule listed reads only; the rebase scan's direct file reads were unexplained. | architecture 5, 6 | Fixed (comments). |
| C8 | One `cat` per possible rebase/bisect file. | performance F2 | Fixed: `[[ -f ]]` and `$(<f)`. |
| C9 | `--merge` with no brief printed "--merge needs at least one brief path". | api F2 | Fixed: every malformed --merge prints the --merge usage; three shapes tested. |
| C10 | `merged BRIEF NEW TIP TREE` shifted TIP and TREE against `ok BRIEF TIP TREE`. | api F5 | Fixed: `merged BRIEF TIP TREE NEW`. |
| C11 | `merged` is a new verdict word; the policy refusal wording will go stale with --approved. | api F6, F7 | Rows (Won't-Fix; Defer to U3a3). The checkout refusal still naming --check is noted in the header. |
| C12 | A dot-named admin dir under worktrees/ escaped the rebase scan; a W whose core.worktree points elsewhere would be checked in one place and written in another. | security untested 1, 2 | Fixed: dot globs; W must be its own top level; tests (each fails without its fix). |
| C13 | Case-insensitive ref store; main as an annotated tag id; W's own sparse/ignoreCase/symlinks. | security untested 3, 4, 5 | Rows (Defer / Defer / Won't-Fix). |
| C14 | Two full store passes per landing across processes. | performance area 4 | Row (row 639's trigger per landing). |
| C15 | The commit message's mutant count cannot be checked. | fact-check 17 (Unverifiable) | Row (Won't-Fix). Fix batch: 4 new mutants (mergeOptions, useConfigOnly, dot glob, top level), each caught by the suite. |
| C16 | "as git would take them" omitted that the system config stays off. | fact-check 2a | Fixed (comment and header). |

### 🧩 Composition check

- land :1018-1075 (security F1/F3/F4, performance F1/F2, architecture 2/4/6, api F3, fact-check 3/13): distinct defects (mergeOptions, maintenance, message write, ordering, reflog text, scan cost), each with its own mechanism and fix.
- merge_ident :990-1001 (fact-check 2a/2b, api F1, security F2): one root, already stated by each fragment (git var guesses without useConfigOnly): distinct statements of one defect, not a composition.

## Goal-alignment and coverage

All five agents answered `yes`. Escalations: performance F1 flagged the repack for security (covered by C1); architecture 1 is a U3a3 planning input (row). No critic failed.

tokens: fc 156k, security 146k, performance 96k, api 115k, architecture 105k ≈ 620k total.
