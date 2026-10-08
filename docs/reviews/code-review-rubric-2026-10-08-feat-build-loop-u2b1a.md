Commit: 63ea50e7
Loop-pass short-circuit: used at 93655b47
# Code Review Rubric

**Branch:** `feat/build-loop-u2b1a` (U2b1a, `--check`'s frame: hardened git, state gate, `--expect`, brief and branch checks, merge-tree), on main 5d39307a.
**Status: ⛔ ITERATION 3 (U2b1a2) AT THE CAP — four reds open (R6-R9); decision: escalate (Q-133); U2b1a1 split off and clean** (single-sample review; absence of findings is not an attestation)

## Iteration 3 of 3: final confirming pass on U2b1a2 (Commit 63ea50e7, k=3, full panel, scope `feat/build-loop-u2b1a1...HEAD`)

U2b1a split at iteration 2 for size (U2b1a1 below it, its own loop, clean); this loop's counter continued on U2b1a2. Delivery mode: inline-diff-only, as a file. Reports: `code-fact-check-report-build-loop-u2b1a2-final.md` (merged r1-r3: 56 clusters, 43 Verified, 5 Mostly accurate, 3 Stale, 5 Incorrect; agreement 50/56), `security-reviewer-review-2026-10-08-build-loop-u2b1a2-final.md` (2 High, 1 Low; the first security agent damaged the worktree with a probe whose temp-dir variable was unset and wrote no report: restored by update-ref with CAS, junk branch `feat/x` left for the user), `performance-reviewer-review-2026-10-08-build-loop-u2b1a2-final.md` (2 Low), `api-consistency-reviewer-review-2026-10-08-build-loop-u2b1a2-final.md` (5 Minor, 3 Informational), `architecture-review-review-2026-10-08-build-loop-u2b1a2-final.md` (3 Coupling, 3 Minor, 2 Informational).

### 🔴 Must Fix (iteration 3)

| # | Finding | Severity | Source | Status |
|---|---|---|---|---|
| R6 | merge_result trusts merge-tree's exit status and drops its stderr: with the tip's tree object missing, merge-tree prints `error: Could not read <tree>`, exits 0, and `--check` prints `ok BRIEF TIP TREE` for a tree that treats the branch side as empty (P2 deleted the brief). | Incorrect (high), behavioral | fact-check Claim 42 (r3, executed); architecture 5 | Open (cap) |
| R7 | origin/HEAD fix bypass: a loop creates a local `master` at any commit and points origin/HEAD at origin/master; the state gate accepts it, resolve_main takes `master`, and a brief `done` on the real main prints ok (P1). In a master-only repo a loop-made `main` wins without touching origin/HEAD (P1b). | High | security F1 (executed) | Open (cap) |
| R8 | A same-uid process can write the gate's own `GATE_TMP` (merge driver in `git/config`, `* merge=X` in `info/attributes` or `work/.gitattributes`) between gate_repo and merge-tree (~40 ms); the driver ran and a conflicting merge printed ok with the planted tree, 3 of 3 (P2). Row 494's "the gate repository closes merge-tree" is false against a racing writer. | High | security F2 (executed) | Open (cap) |
| R9 | The submodule test is vacuous (`commit_all` drops the base gitlink; no merge base); it passes with merge-tree in the real repo. Nothing pins gate_repo's submodule isolation; the rubric's R2 and mutant notes are false. | Incorrect (all 3 replicates) | fact-check Claims 2, 3, 51 | Open (cap) |

### 🟡 Must Address (iteration 3)

| # | Finding | Source | Status |
|---|---|---|---|
| A15 | No test pins "state gate before any object read" (GIT_ALLOW_PROTOCOL hides the order); R1's "both mutants let upload-pack run" is Stale. | fact-check Claims 16, 49 | Open (cap) |
| A16 | U2b1b's `diff-tree` in the real repo hides a moved gitlink under `submodule.<name>.ignore=all` (repo config) or an uncommitted `.gitmodules` with `ignore = all`; plan F8's `-c diff.ignoreSubmodules=none` does not fix it, `--ignore-submodules=none` or the gate repo does (probed). | architecture 1 | Open: plan F8 to correct before U2b1b |
| A17 | System config reaches every gate call (`merge.directoryRenames` flipped a conflict); root-owned here. Alternates, packs and the multi-pack-index are object sources F3's row does not name; a planted pack may shadow a loose object (untested). | fact-check Claims 15, 31, 39; security lead (c) | Open (cap) |
| A18 | `core.commitGraph=false` costs 8-48 ms per history walk, three walks per brief; check_line's re-read repeats one (row 500's price is stale). | performance F1, F2 | Open (cap) |
| A19 | Doc drift: --check help's state-gate list omits shallow and origin/HEAD; state_gate comment's key list; "present and not empty" for a symlink or directory; "every line ok" exit wording would force U2b1b's path lines to start with ok; `refuse state gate:` is not a state line. | fact-check Claims 21, 34, 35; api 1-5 | Open (cap) |

### Iteration-4 gate decision

## Iterations (3 completed)
Iteration 1 (k=1, short-circuit): R1 partial-clone lazy fetch, fixed. Iteration 2 (k=1, full panel): R2 submodule lazy fetch, security F1/F2/F4-F8, fixed; split at 439 lines. Iteration 3 (k=3, full panel, on U2b1a2): R6-R9 above.
## Remaining Must Fix
R6 (missing object read as an empty side), R7 (local master + origin/HEAD), R8 (race on GATE_TMP), R9 (vacuous test).
## Remaining Must Address
A15-A19.
## Convergence diagnosis (one sentence)
Each pass closes the git read paths the last one found and the security critic finds the next one a same-uid hostile loop can use (planted config, objects, refs, now a race on the gate's own temp directory), so the loop is converging on the honest-path defects (R6, R9) but not on a threat model the plan itself scopes out ("What the gate can and cannot do": a loop with a shell is not contained; its residuals go to Q-103).
## Recommended action (ship-with-issues / split-PR / pause for redesign)
Pause for a threat-model ruling, then one more iteration: fix R6 (refuse on any merge-tree stderr and check the tip, main and base trees exist), R7 (refuse when the default branch is ambiguous: both main and master, or origin/HEAD naming a branch whose local ref is not the one resolve_main picks), R9 and A15 (real fixtures), A16-A19's wording and F8; record R8 and A17's object sources with F3 as hostile-loop residuals in Q-103.

Decision: **escalate** (Q-133). A split would not converge either: the open reds sit in both halves and the architecture critic found the halves' output contract is not separable (a lower half would print ok for a conflict).

## Iteration 2 of 3 (Commit 9e5d92df, `--loop-pass`, k=1, `--full`: the critics had not yet seen the branch)

The short-circuit was already used (iteration 1), so the full panel ran despite the fact-check's red (mechanic 6). Delivery mode: inline-diff-only, as a file. Reports: `code-fact-check-report-build-loop-u2b1a-i2.md` (24 claims: 20 Verified, 3 Incorrect, 1 Unverifiable), `security-reviewer-review-2026-10-08-build-loop-u2b1a.md` (3 High, 4 Medium, 1 Low, 2 Informational, nearly all probed), `performance-reviewer-review-2026-10-08-build-loop-u2b1a.md` (1 Low, 3 Informational), `api-consistency-reviewer-review-2026-10-08-build-loop-u2b1a.md` (2 Inconsistent, 3 Minor, 3 Informational), `architecture-review-review-2026-10-08-build-loop-u2b1a.md` (2 Coupling, 4 Minor, 1 Informational). Stage 2.5 skipped (loop pass): routed endorsements stay pending execution verification.

### 🔴 Must Fix (iteration 2)

| # | Finding | Severity | Source | Status | Author note |
|---|---|---|---|---|---|
| R2 | When both sides moved a gitlink, merge-tree opened the submodule repository under `.git/modules/<name>` and lazily fetched through that repository's promisor config: `remote.origin.uploadpack` ran a command (P1). The state gate reads only the superproject's config. | Incorrect (high), behavioral | fact-check Claims 5, 7 (executed) | Fixed | merge_result runs in a gate-owned repository (`gate_repo`, once per run): a git dir with no config but the repo's object format, no modules/, info/ or shallow, run from an empty directory, with GIT_OBJECT_DIRECTORY the real store and the repo-local variables unset. The moved gitlink is now a conflict. Test: the P1 plant (mutant running merge-tree in the real repo fetches). |
| R3 | `origin/HEAD` symref'd to a branch a loop wrote makes resolve_main take that branch as main: a `done` brief and a review policy read as open and self-merge, and `--check` printed ok (F1, probed). | High | security F1 | Fixed for --check | The state gate refuses an origin/HEAD naming anything but origin/main or origin/master (tested). `--settings` and `--status` still follow it: they decide nothing; U3b's `--state` (C18/R5) covers the orchestrator's reads (override row). |
| R4 | Global git config (`~/.gitconfig`, writable by any same-uid loop) is outside the state gate and the pairs: `log.showSignature` + `gpg.program` ran a command; `merge.directoryRenames` turned a conflict into ok (F2, probed). | High | security F2 | Fixed | `GIT_CONFIG_GLOBAL=/dev/null` for every call (shim test). |
| R5 | Rewriting the loose object behind main's brief blob (same id, new bytes) turned a refusal into ok; only fsck notices. The same write can flip the policy or forge an answer (F3, probed). | High | security F3 | Deferred | Plan-level: git never re-hashes what it reads, so any same-uid writer can do this to any object the gate reads (trees, commits, blobs). Override row (trigger: U3's `--merge`, before anything moves main: re-hash the blobs each decision reads, and list the residual in Q-103). Raised with the U2b1a merge entry. |

### 🟡 Must Address (iteration 2)

| # | Finding | Severity | Source | Status | Author note |
|---|---|---|---|---|---|
| A6 | A planted `.git/shallow` silently changed the merge (undid a revert on main) and the state gate did not check it. | Medium | security F4, architecture 5 | Fixed | The state gate refuses a non-empty shallow file (tested); the gate repository has none either. |
| A7 | A forged commit-graph changed the merge. | Medium | security F5 | Fixed | `core.commitGraph=false` pair (shim test). |
| A8 | From a linked worktree, the main worktree's config.worktree reached merge-tree but not the gate. | Medium | security F6 | Fixed | The gate repository reads no repo config. |
| A9 | The state gate checks once; config planted after it applies to later calls. | Medium | security F7 | Partly fixed | `GIT_ALLOW_PROTOCOL=none` stops any lazy fetch race-free; merge-tree reads no repo config. A key planted mid-run still reaches the other reads (log.showSignature for check_branch's `git log`): override row, trigger U3b's `--state` snapshot. |
| A10 | Comments and commit 9e5d92df claim no gate call fetches without a promisor remote; the submodule path contradicts it. | Incorrect | fact-check Claims 7, 18 | Fixed (comments); Accepted-immutable (commit) | Comments rewritten; override row for the commit message. |
| A11 | Hardening lives in three places, and dev-cycle.sh calls the same lib functions unhardened (row 387's trigger met). | Coupling | architecture 1 | Deferred | Override row: one `git_harden` in the lib when dev-cycle.sh's digest runs through the D6 snippet (U3b). |
| A12 | check_line parses status_line's printed line and check_branch's by field position. | Coupling | architecture 2 | Deferred | Override row: a `status_fields` array when U3's `--merge` becomes the second consumer. |
| A13 | The case block tests only the first line of a brief's output; U2b1b's per-path lines need "every line ok". | Inconsistent | api-consistency F4, architecture 6 | Deferred | Plan's `--check` interface line now states the duty for U2b1b. |
| A14 | The plan's `--state` grammar (`refuse KEY`) and D7's "install.sh" differ from the code. | Inconsistent | api-consistency F2, architecture 7 | Fixed | Plan amended. |

### 🟢 Consider (iteration 2)

| # | Finding | Source | Status |
|---|---|---|---|
| C4 | `refuse state : its path could not be read` printed no WHAT. | api-consistency F1, security F10 | Fixed (a separate variable). |
| C5 | A config subsection can put `: ` inside WHAT. | api-consistency F3 | Won't-Fix (row): state lines are read by a person; the exit status decides. |
| C6 | `anybrief` drops the `is` prefix. | api-consistency F5 | Won't-Fix (row): the name row 323 proposed. |
| C7 | The open_shared cache is keyed on nothing. | architecture 3 | Deferred (row): trigger a caller that runs resolve_main twice. |
| C8 | The state gate's extension point is a key regex; U2b2's rules are value tests (core.symlinks). | architecture 4 | Deferred to U2b2. |
| C9 | check_line's full check_branch re-read costs about 9.8 ms per brief; four --git-path calls; merge-tree objects written even on conflict. | performance F1-F4 | Won't-Fix (row): the re-read is deliberate (the tip may move), the rest is under 3 ms. |
| C10 | `-G` honours `diff.<driver>.binary` and `-diff`, falling back to the last commit touching the brief. | fact-check Claim 13 | Deferred (row): pre-existing, no command runs. |
| C11 | Global and system config apply to the gate repository; an inherited GIT_COMMON_DIR undoes it. | architecture 5, security F8 | Fixed: GIT_CONFIG_GLOBAL for all calls; GATE_ENV unsets the repo-local variables. |

Tests and mutants: the submodule plant, a SHA-256 repository (TIP and TREE 64-hex), shallow and origin/HEAD in the state test, GIT_CONFIG_GLOBAL, GIT_ALLOW_PROTOCOL and core.commitGraph in the shim test. Mutants: merge-tree in the real repo (submodule and union tests fail), no objectformat (SHA-256 test), no GIT_ALLOW_PROTOCOL (shim), no shallow (state test). Suites 91/19/78/2/2.

## Iteration 1 of 3 (Commit 93655b47, `--loop-pass`, k=1, full branch: no prior rubric)

Scope: the full branch (no canonical rubric existed). The fact-check found a behavioral Incorrect at high confidence, reproduced end to end, so the first-red short-circuit fired (the first in this loop). The critics were skipped. Security is not forced: the diff touches no enforcement file (`hooks/live-verify-gate.sh`'s regex). Delivery mode: inline-diff-only, as a file the agent read (`git diff main...HEAD`, 37 KB).

Report: `code-fact-check-report-build-loop-u2b1a.md`: k=1, 33 claims. 23 Verified, 6 Mostly accurate, 1 Stale, 3 Incorrect, 0 Unverifiable. Suites re-run by the agent: 188/188.

### 🔴 Must Fix (iteration 1)

| # | Finding | Severity | Source | Status | Author note |
|---|---|---|---|---|---|
| R1 | The state gate misses a partial clone: with `extensions.partialClone` and `remote.origin.promisor` set and an object missing, the gate's own `ls-tree` read lazily fetched through `remote.origin.uploadpack`, which ran a command after the gate passed (probe P5). harden's "what these pairs cannot switch off, --check's state gate refuses" was false. | Incorrect (high), behavioral | fact-check (executed, P5) | Fixed | Fixed: STATE_KEYS_RE refuses `extensions.partialclone` and `remote.*.promisor`, and --check runs the state gate before resolve_main (its first object read). Test: a promisor remote whose upload-pack leaves a mark, main's tip commit deleted; mutants without the keys, or with the gate after resolve_main, both let upload-pack run. |

### 🟡 Must Address (iteration 1)

| # | Finding | Severity | Source | Status | Author note |
|---|---|---|---|---|---|
| A1 | "diff.ignoreSubmodules can hide a gitlink" (state_gate comment): `diff-tree -r` on git 2.39.5 still shows the gitlink with `diff.ignoreSubmodules=all`; only porcelain diff hides it (P3). The plan's F8 row makes the same assumption. | Incorrect, comment | fact-check | Fixed | Fixed: the comment says diff and merge drivers name commands. The plan's F8 wording is U2b1b's (its diff-tree parse). |
| A2 | `scripts/dev-cycle.sh`'s `--check-branch` help does not list check_branch's new "commit count or date could not be read" skip. | Stale | fact-check | Fixed | Fixed (`scripts/dev-cycle.sh` --check-branch help). |
| A3 | The `--check` help's refuse list omits "moved or could not be read again" and "could not be computed"; "writes nothing but merge objects" omits merged blobs and the temp directory; GIT_ATTR_NOSYSTEM, not a config pair, turns off the system attributes file; merge_result's "no work tree" is really an empty one. | Mostly accurate (4), comment | fact-check | Fixed | Fixed: the refuse list, the objects-and-temp-dir sentence, harden's attributes sentence, merge_result's empty-work-tree wording. |
| A4 | The "runs no hook" test passes with `harden` removed (mutant m3): no `--check` call fires those hooks, so nothing pins the config pairs. | test gap | fact-check escalation 2 | Fixed | Fixed: a PATH shim logs every git call's config pairs; each call carries all four (mutant without `harden` fails). The weak hooks test is dropped (the shim pins core.hooksPath=/dev/null), which also keeps the unit at 396 lines. |
| A5 | A tip commit holding a NUL byte now makes bash warn on stderr ("ignored null byte"), since marker_kind reads cat-file through `$(...)`. | regression (stderr) | fact-check escalation 3 | Fixed | Fixed: `tr -d '\000'` in the pipe (pipefail keeps cat-file's failure); not pinned by a test, since the NUL marker test lives in build-loop-read.bats (rows 317-319's suite). |

### 🟢 Consider (iteration 1)

| # | Finding | Source | Status |
|---|---|---|---|
| C1 | "before reading any brief" is checked only as the brief path being absent from the output. | fact-check (Mostly accurate) | Fixed: one output line asserted. |
| C2 | d0199be6's Notes call the split "an interim in docs/working/questions.md"; the record is a Q-119 update in 93655b47, not marked interim. | fact-check (Mostly accurate, commit message) | Accepted-immutable (override-log row, 2026-10-08). |
| C3 | `--status` has no state gate: a repo-local `diff.x.textconv` with a checkout `*.md diff=x` runs a command through check_brief's `git log -G` (P7). Pre-existing on main. | fact-check escalation 4 | Fixed: `--no-textconv` on check_brief's `git log -G`; tested through --status (mutant fails). |

## ⏭️ Skipped Core Critics

| Critic | Reason |
|---|---|
| security-reviewer, performance-reviewer, api-consistency-reviewer, architecture-review | loop-pass short-circuit (behavioral red confirmed at fact-check, R1) |

## Considered overrides

Rows routed to U2b and matched by this diff: 223 (failure helper prints the graph: done, `show`), 298 and 323 (brief enumeration into the lib, `anybrief`: done), 307 (check_branch and marker_kind under a broken config: done), 310 (per-path ls-tree cost: U2b1b), 314 (bl_setup's GIT_DIR: already unset there), 317-319 (build-loop-read.bats chains and wording: this unit does not edit that suite, so the trigger has not fired), 351, 387, 391-393, 397 (the gate's checkout and conversions: U2b2), 466 (import_reset before each decision: U2b2).

## 🧩 Composition check

No multi-source co-located clusters qualified (one source this pass).
