Commit: 07360526
# Code Review Rubric

**Branch:** `feat/build-loop-u3a2` (U3a2: `--merge BRIEF --expect SHA` lands a self-merge brief by compare-and-swap, or by a fast-forward in the worktree that has main checked out; check_line's verdict as values), on main 6666a5ce.
**Status: 🟢 SECOND CONFIRMING PASS CLEAN (Q-138 interim [1]: k=1 fact-check + security, scope `20de9671..2028aa89`) — no Must Fix, no Must Address; one Low planted-state regression routed to Q-103 (override row); text and stderr fixed in 07360526. Loop closed at 07360526.**

## Second confirming pass (Commit 2028aa89, k=1 fact-check + security, scope `20de9671..2028aa89`, Q-138 interim [1])

Scope: the interim batch ce38eafb (G1-G5) and 2028aa89 (G6's test: w2's `.git` names a copy of its admin dir outside worktrees/; red against a mutant without `-ef "$hd"`). Fact-check (`code-fact-check-report-u3a2-confirm2.md`): 16 claims, 14 Verified, 2 Mostly accurate, 0 Incorrect; a mutant of each new guard fails exactly its test. Security (`security-review-2026-10-10-u3a2-confirm2.md`): every earlier HEAD shape refuses (and `refs/worktree/m` to main); `.x`/`..x` admin dirs refuse; four bare layouts land; no new command execution (GIT_TRACE); no false refusal of an honest layout 20de9671 landed.

### 🟢 Consider

| # | Finding | Source | Status |
|---|---|---|---|
| H1 | `core.bare=true` planted with the main worktree's index deleted: the repository lists as bare with no index, land skips its HEAD and moves main by CAS under it (git's own `branch -f main` agrees at that moment). | security 1 (Low, regression, planted-state, executed) | Q-138 [1]: planted-state class, override row routed to Q-103. |
| H2 | An admin dir git cannot open (no commondir, a HEAD git rejects) refuses every landing; symbolic-ref's `fatal:` line (an absolute path) reached stderr; the header did not name the case. | security 2 (Informational; fails closed) | Fixed 07360526: stderr dropped, header names a HEAD git cannot read. |
| H3 | A separate-git-dir or submodule repository whose main worktree is on main refuses (git 2.39's list reports the git dir as its path). | security 3 (Informational, not a regression) | Override row; honest-path false refusal, fails closed. |
| H4 | The header's "cannot be read" parenthetical was narrower than the symbolic-ref refusal; land's "the header's refusals" includes the policy and --check refusals it does not make. | fact-check (2 Mostly accurate) | Fixed 07360526. |

Unit at 400 code lines (cap 400; the G6 test folded). Suites 7/145/20/79 green at 07360526; shellcheck clean. G6 closed.

## Confirming pass (Commit a5837597, k=1 fact-check + security, scope `6cbca87c..a5837597`)

Fact-check (`code-fact-check-report-u3a2-confirm.md`): 28 claims, 19 Verified, 3 Mostly accurate, 5 Incorrect, 1 Unverifiable; E1-E6 resolved but for E2's dot-named sub-case; honest layouts (real rebase of another branch, detached, prunable, locked, bisect from another branch, a linked W) still merge. Security (`security-review-2026-10-10-u3a2-confirm.md`): every final-pass probe re-run refuses; three new Mediums and one Low regression, executed.

### 🔴 Must Fix

| # | Finding | Source | Status |
|---|---|---|---|
| G1 | The searchability check globbed `worktrees/*/rebase-*`, skipping dot-named admin dirs: a `.x` admin dir's mode-000 rebase-merge of main merged (and `rebase --abort` would reset main). | fact-check 4, 14 (Incorrect, executed); security 3 (Medium) | Interim fix (unreviewed): the check runs per admin dir, dot names included; test. |

### 🟡 Must Address

| # | Finding | Source | Status |
|---|---|---|---|
| G2 | HEAD was read by awk: `ref:` then a CR or newline (git accepts both) was not counted, so with the gitdir file gone the counts agreed at 0 and the CAS ran under W. | security 1 (Medium, executed) | Interim fix: each admin dir's HEAD resolved by `git --git-dir=D symbolic-ref -q HEAD` (rc 2+ refuses); test. |
| G3 | A worktree on a symbolic alias of main was not counted (pre-existing at 6cbca87c). | security 2 (Medium, executed) | Interim fix: symbolic-ref follows the chain; test. |
| G4 | A bare repository with linked worktrees could not land: the bare repository's own HEAD counted as a worktree on main. | security 4 (Low, regression) | Interim fix: skipped when the list marks the repository bare; a bare-listed repository with an index refuses (a planted core.bare); test. |

### 🟢 Consider

| # | Finding | Source | Status |
|---|---|---|---|
| G5 | state_is's comment said "as git reads it" (git drops less); the CR test planted a shape git does not act on; the repository rule omitted symbolic-ref; "in its order"; "from 416". | fact-check 9, 10, 12, 19, 24, 27 | Comments and test corrected; commit messages immutable. |
| G6 | The W git-dir comparison (`-ef "$hd"`) has no test of its own; `--no-deref` likewise (row). | fact-check 22 | -ef test added 2028aa89 (second confirming pass); row for --no-deref. |
| G7 | A symlinked HEAD (core.preferSymlinkRefs) now refuses. | security 5 | Fails closed; deprecated git option. |

Unit at 398 code lines after the interim batch (tests and comments compressed). Suites 7/145/20/79/2/2; health check passed at a5837597. Mutants of the four newest guards each fail the suite.

## Iteration 3: final confirming pass (Commit 6cbca87c, k=3, scope `main...HEAD`, full panel)

Fact-check: three replicates (`code-fact-check-report-u3a2-final-r1/-r2/-r3.md`: 31/33/32 claims) merged most-severe-wins into `code-fact-check-report-u3a2-final.md` by a merge agent (42 clusters: 30 Verified, 9 Mostly accurate, 3 Incorrect; agreement 78.6%; the merge corrected report formatting so the format suite passes, adding no evidence). Critics (opus, parallel; `*-review-2026-10-10-u3a2-final.md`): security (3 Medium, executed; 2 Info), performance (none), api-consistency (1 Inconsistent, 2 Info), architecture (1 Minor, 1 Info). Stage 2.5: the routed endorsements (assume-unchanged/skip-worktree ff refusal; a genuine paused rebase refused; D4's pack-count test catching the maintenance mutant) were each executed by a fact-check replicate or this pass's mutant sweep; no separate submitted-claims agent ran (recorded as a gap, not a confirmation).

### 🔴 Must Fix

| # | Finding | Source | Status |
|---|---|---|---|
| E1 | An unsearchable `.git/worktrees` or admin dir drops W from `git worktree list` (exit 0); land moved main by CAS under W, leaving W's index at the old commit (a later commit there reverts the merge). | fact-check 8 (Incorrect, r2, executed) | Fixed: land reads every admin dir's HEAD itself, refuses any dir not searchable, and refuses when its count of main's holders differs from the list's; W's git dir must be the holder's. |
| E2 | Rebase/bisect state that is a directory, or under an unsearchable dir, read as absent; a rebase of main landed. | fact-check 9, 33 (Incorrect, r2, r3, executed) | Fixed: state that exists but is not a readable plain file in a searchable directory refuses; tests for each shape and for an unreadable BISECT_START (the surviving mutant, fact-check 37). |
| E3 | The header promised refusals the code did not make (the two above). | api-consistency F1 (Inconsistent) | Fixed with E1, E2; header lists the new refusals. |

### 🟡 Must Address

| # | Finding | Source | Status |
|---|---|---|---|
| E4 | A deleted or emptied gitdir file drops W from the list; CAS under W (widens E1 without a permission change). | security F1 (Medium, executed) | Fixed by E1's holder count; test moves w2's gitdir away. |
| E5 | head-name with a CR or blanks (git strips them) hid a paused rebase of main; `rebase --abort` then reset main, undoing the merge. | security F2 (Medium, executed) | Fixed: state_is compares as git reads (blanks and CR dropped); test. |
| E6 | A symbolic `refs/heads/main` hid the worktree on main (listed as its target's); the CAS moved the target. | security F3 (Medium, executed) | Fixed: default_gate refuses a symbolic default branch (startup and the re-run); CAS `--no-deref`; test. |

### 🟢 Consider

| # | Finding | Source | Status |
|---|---|---|---|
| E7 | An empty email from a partial config identity was accepted (`<>`). | fact-check 5, 16; api F2; security F5 | Fixed: the identity regex needs a non-empty email; test. |
| E8 | Comment wording: "before any git command runs there", the repository rule, "NEW unreachable", "No worktree may be rebasing" scope. | fact-check 13, 18, 19, 22; architecture 2 | Fixed. |
| E9 | Two worktree-set sources not compared. | architecture 1 | Fixed with E1. |
| E10 | A checkout whose git dir lies outside worktrees/ is invisible. | security F4 | Header residual. |
| E11 | Refusal after the write does not name NEW; hand-edited todo; `--no-deref` untested; commit 6cbca87c wording. | api F3; security listed, F3; fact-check 31, 34 | Rows. |

The fix batch took the unit to 416 code lines; tests and land's comment were compressed (no assertion dropped; the six new mutants re-run) to 389.

### Iteration-4 gate decision

**Decision: escalate**, resolved under Q-137's standing instruction (review adjustments go ahead on the recommendation, without a Q entry), as U3a1's was. The reds share one root (land's discovery of worktree state) and one fix in one function, so a split would move all of them together; the recommendation is a narrow confirming pass (k=1 fact-check + security over the fix range), any Must Fix there stopping the merge for a Q entry.

### 🧩 Composition check

- land :1043-1090 (fact-check 8/9/33/18, security F1/F2/F3, api F1, architecture 1): composed root, stated by architecture 1 and security's summary already: land decides "no other worktree holds or will move main" from git state it reads less carefully than git does, treating unreadable as absent. Fix: read every admin dir as git does, refuse what cannot be read, cross-check the list. Not a new composed row (each fragment's fix is the same one, stated).

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
