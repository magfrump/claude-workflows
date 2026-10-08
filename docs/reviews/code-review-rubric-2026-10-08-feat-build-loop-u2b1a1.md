Commit: ae08688c
Loop closed at ae08688c
# Code Review Rubric

**Branch:** `feat/build-loop-u2b1a1` (U2b1a1, the reader half of U2b1a: brief enumeration in the lib, reads that fail under a broken config, check_brief's git log hardened), on main 5d39307a.
**Status: ✅ CLEAN AT THE FINAL CONFIRMING PASS — no 🔴; ambers fixed after the pass (unreviewed except the lite fix-drift check) or deferred with rows** (single-sample review; absence of findings is not an attestation)

This unit's code was split out of `feat/build-loop-u2b1a` at review iteration 2 for size (plan step 5's U2b1a split note). Its earlier review is in `code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md` (iterations 1-2, which reviewed this code with U2b1a2's). This loop ran one pass: the full confirming pass.

## Final confirming pass (Commit ae08688c, k=3, full panel, Stage 2.5 skipped: see below)

Scope: `git diff main...HEAD` (115 code lines). Delivery mode: inline-diff-only, as a file.

Reports: `code-fact-check-report-build-loop-u2b1a1.md` (merged from r1-r3: 32 clusters, 29 Verified, 2 Mostly accurate, 1 Stale, 0 Incorrect; agreement 30/32), `security-reviewer-review-2026-10-08-build-loop-u2b1a1.md` (2 Medium, 1 Low, 2 Informational, all pre-existing or design-level; nothing a regression), `performance-reviewer-review-2026-10-08-build-loop-u2b1a1.md` (1 Informational), `api-consistency-reviewer-review-2026-10-08-build-loop-u2b1a1.md` (4 Minor, 2 Informational), `architecture-review-review-2026-10-08-build-loop-u2b1a1.md` (2 Minor, 2 Informational).

Stage 2.5: the routed endorsements (security's DATE-regex and --no-textconv probes, performance's once-per-process claims) were already executed by the fact-check replicates (open_shared output-identical to main's shared_branches on five brief shapes; --no-textconv stops the driver and finds the same commits); no ✅ row is published from them.

### 🔴 Must Fix

None.

### 🟡 Must Address

| # | Finding | Severity | Source | Status | Author note |
|---|---|---|---|---|---|
| A1 | A planted `log.showSignature` + `gpg.program` runs inside check_brief's two `git log` calls and check_branch's; `dev-cycle.sh --check-brief` printed the program's text in its commit field (the dev cycle copies that field into Done). Pre-existing; this unit already reduced it (marker_kind, check_branch's DATE regex). | Medium | security F1 | Fixed (after the pass) | `--no-show-signature` on all three, `--no-follow` on check_brief's two (security F3, Low: log.follow changed the commit named for a moved brief), and check_brief refuses a non-empty commit that is not a full id. Test: a signed brief commit with a marking gpg.program, through --status and --check-brief (mutant without --no-show-signature fails). An empty field stays as on main (build-loop-read.bats' grep.patternType case). |
| A2 | The dev-cycle skill reads any `--check-branch` skip as "shows no work", so a broken config would raise a keep-or-drop question per open brief. | Minor (Medium confidence) | architecture F2 | Fixed (after the pass) | SKILL.md's "shows no work" excludes the new read-failure skip ("a broken git config to record, never idleness"). |
| A3 | Rewriting an object's bytes behind its id reaches open_shared, Status, Branch, Policy, settings and answers through --status and --check-brief. | Medium (design) | security F2 | Deferred | Same class as U2b1a's security F3 row (rewritten loose objects; trigger U3's `--merge`); a revisit row names these readers. |
| A4 | Wording: the plan's U2b1a bullet (merge-tree "against the common git dir", the older state-gate list) is Stale; dev-cycle.sh's "(a broken log.* config)" was too narrow; the `show` helper printed no history under `log.date bogus`; the --status skip clause ran to 120 columns. | Stale / Mostly accurate / Minor | fact-check Claims 5, 13, 25; api F4, F5 | Fixed (after the pass) | Plan bullet updated with U2b1a2's design; "a broken config"; `git -c log.date=default log` in `show`; the clause rewrapped and naming the unreadable tip. |

### 🟢 Consider

| # | Finding | Source | Status |
|---|---|---|---|
| C1 | open_shared's cache is keyed on nothing, and the lib header's contract does not name it. | architecture F1, api F2, F3 | Deferred: U2b1a's row (keyed cache; trigger a second resolve_main) and a new row for the header sentence (trigger U2b2's contract items). |
| C2 | marker_kind's failed-read answer is printed as "starts handoff: but is not a marker". | api F1, fact-check E2 | Fixed with A4 (the help names it); the line's wording stays (near-unreachable: check_branch has read that commit). |
| C3 | Under `log.date bogus` `dev-cycle.sh --check-brief` exits 128 with no line. | fact-check E1 | Deferred (row): pre-existing; the U3b `git_harden` row covers dev-cycle.sh's reads. |
| C4 | Grafts: marker_kind's parents come from rev-list (follows grafts), its message from the raw object. | architecture F4, security F4 | Covered by row 273 (grafts are U3b's `--state`; U2b1a2's state gate refuses them for --check). |
| C5 | One broken config now makes every brief's --status line skip. | security F5 | Intended (row 307): fails closed with a fixed reason. |
| C6 | marker_kind's cat-file pipe costs about +0.3 ms per branch ahead. | performance F1 | Won't-Fix (under 2% of the settled per-brief cost). |

## Considered overrides

Rows 298, 323 (closed by this unit), 307 (closed), 293 (open_shared keeps it), 273 (grafts), and U2b1a's rows dated 2026-10-08 (carried here, since this unit lands first).

## 🧩 Composition check

One cluster qualified: check_brief's `git log` lines (`scripts/lib/dev-cycle-read.sh:421-423`), cited by security F1/F3, fact-check E1 and architecture F3. Disposition: distinct defects (a command run, a different commit named, a failed read), each with its own mechanism and fix, all applied in A1 or deferred in C3.

## Fixes after the final pass

Commit 4a7e021d (after ae08688c): A1, A2, A4, C2. Suites 82/19/78/2/2.

Lite fix-drift (`scripts/lite-review.py --mode fix-drift`, run over a scratch commit holding only 4a7e021d's code and plan changes, since the carried review reports put the real range over the script's 192 KB limit): one finding, "check_branch's comment says log.* or grep.*; grep.* does not affect git log". Refuted: fact-check Claim 13 executed it, and a re-run (`grep.patternType bogus`, `dev-cycle.sh --check-branch`) printed "skip feat/x: its commit count or date could not be read". No change.
