# Code Review Rubric

**Commit:** 9075003 (reviewed); plan fix 31baaba on this branch; code fixes in the stacked unit (7c97a6b, 95ebf9b on `q094b-exit-scan-worktree-removal`)
**Scope:** `q094-exit-scan-worktree-layout`, dfe4c0d..9075003 (docs/reviews/ artifacts excluded) | **Reviewed:** 2026-09-28 | **Status: 🟢 PASSES — conditional on merging together with the stacked unit** (0 red; every 🟡 fixed here or in the stacked unit, which carries the code fixes because this unit sits at the row-62 size cap) — single-sample review; absence of findings is not an attestation

Terminal confirming pass (pr-prep 3d): full panel, no `--loop-pass`, fact-check k=3 (opus), critics opus. Delivery mode: self-read. Critics: security, performance, api-consistency (core); tech-debt-triage (contextual: 502 changed lines > 500). Architecture, test-strategy, dependency-upgrade, ui-visual not triggered. Fact-Check Gate: one high-confidence Incorrect, on a comment only (no behavioural red), so critics proceeded without pausing.

**Size cap.** This unit has 399 changed code lines outside `docs/` (decision log row 62, cap 400). Any comment, guide or code edit here would cross it, so every non-`docs/` fix below was made in the stacked unit and is reviewed there. **Do not merge this unit without `q094b-exit-scan-worktree-removal`:** alone, it ships A1 open.

---

## 🔴 Must Fix

None.

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | A worktree made by container git has `.git` = `gitdir: /workspace/…`, which names nothing on a host checkout elsewhere, so the snapshot never walked your own relative `core.hooksPath` there; the note hid a planted hook that ran after `git worktree repair` (`cc-exit-scan.sh:878-887`, `:547`, `:700-701`; experiment-confirmed) | Security | Medium | security-reviewer | for-author | — | Fixed in stacked unit (7c97a6b) | Fix: `_snap_container_target` maps a container-form `.git` to its host twin and `_snap_host_config` walks it, at launch and exit. Test "YOUR relative hooksPath is walked in a container-form worktree too"; mutation-checked. Size cap forced the placement; tracked by plan B14 |
| A2 | Header `cc-exit-scan.sh:83-84`: "Your own config's relative hooksPath is walked in each new worktree" was false for the container form | Fact-check | Incorrect (high), comment only | Fact-check (r3; r1, r2 Mostly accurate) | for-author | — | Fixed in stacked unit (7c97a6b, 95ebf9b) | Now true after A1's fix; header reworded |
| A3 | Plan B21 cited rule 6 (in the stacked unit); plan steps 2/3 listed guide items and a removal test this unit lacks | Fact-check | Stale | Fact-check (r1, r2, r3) | for-author | — | Fixed (31baaba) | — |
| A4 | Doc drift: `scan_std_worktrees` comment and plan rule 5 omit six extra declines; header/guide "(not `.`)" misses insteadOf bases `.`/`""` and embedded-repo config; guide "tracked files are never read"; plan `:23` (`--help` text changed), B13, B15, B28 | Fact-check | Mostly accurate | Fact-check (r1, r2, r3) | for-author | — | Fixed: plan in 31baaba; comment and guide in stacked unit (7c97a6b) | — |
| A5 | Plan `:60` "447 lines" cannot be checked | Fact-check | Unverifiable | Fact-check (r2, r3) | for-author | — | Fixed (31baaba) | Now says the count was taken before the split and never committed |

**Immutable history (not tiered).** Commit 5a6d689's "The rest of the scan checks -f before every read" was false at that commit (fact-check Incorrect, r2+r3; true at the tip since c32a734, whose body says so) — override-log `Accepted-immutable` row appended. Commit b4de821's "added or removed" is Stale for the same reason (c32a734 moved removal out).

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | ~24 forks per added worktree (`$(printf %q)`, hash pipelines, stat/sha256sum); 37–41 ms per worktree, 7.9 s at 200 | performance-reviewer | Low | for-author | row 134 (scan cost, deferred) | Deferred: revisit if sessions routinely add >20 worktrees |
| C2 | A FIFO swapped in after the regular-file check hangs the scan (Ctrl-C → exit 4, fails closed) | performance-reviewer | Informational | for-orchestrator-synthesis | prior I1 | Accepted (the "After the scan" route) |
| C3 | Guide lists fewer note-blockers than the code (insteadOf `.`/`""`, embedded repos, your own hooksPath) | api-consistency-reviewer | Minor | for-author | — | Fixed in stacked unit (7c97a6b) |
| C4 | `_snap_hash_str`/`_snap_file_is` break the `_snap_*` "runs inside git_exec_snapshot" header | api-consistency-reviewer | Minor | for-author | — | Fixed in stacked unit (header note) |
| C5 | Exit 0 now also means "only standard worktrees changed"; no test of a non-zero claude status on the note path | api-consistency-reviewer | Informational | for-author | — | 🟢 Open |
| C6 | The note has no leading blank line; W record fields are mixed | api-consistency-reviewer | Informational | for-author | prior C1 (lower-case `note:` won't-fix) | Won't-Fix (cosmetic; W fields are unread) |
| C7 | The pipefail test's 40k-iteration loop takes ~17 s of the suite | tech-debt-triage | Low | for-author | — | Fixed in stacked unit (one printf, 66 ms) |
| C8 | Override-log row 135 said "fold commondir reading into cc-gitdir.sh at the next scan change"; this change did neither the fold nor a recorded deferral, and adds a third caller | tech-debt-triage | Medium (contextual) | for-author | row 135 | Deferred: fold as its own unit; the new caller compares the result against the snapshot's own record, so correctness holds. Revisit at the next change to `scan_git_dirs` |
| C9 | `scan_std_worktrees` is 91 lines, 26 locals, reused variables | tech-debt-triage | Low | for-author | — | Deferred: extract the per-worktree block at the next accepted shape (e.g. plan B25) |
| C10 | Record formats rebuilt by hand; the `_snap_bytes=0` local was uncommented | tech-debt-triage | Low | for-author | — | Comment added in stacked unit; rest carried (drift fails closed) |
| C11 | The acceptance rule is written in four places that drift | tech-debt-triage | Low | for-author | — | 🟢 Open (the function comment is now the full statement) |
| C12 | Unverifiable: the image's git version (`FROM node:22` unpinned); git ≥ 2.48 `worktree.useRelativePaths` | Fact-check | Unverifiable | for-author | — | 🟢 Open (no network; a relative-path worktree warns, never passes) |

---

## ↩️ Considered Overrides

| Override (PR ref / Date) | Prior finding | Original → Override | Reason | This run's treatment |
|---|---|---|---|---|
| `integrate/q076` / 2026-09-27 (row 133) | Bare-layout repo in a dir not named `.git` not walked | 🟢 → Defer | Documented limit | Inherited; not re-raised |
| `integrate/q076` / 2026-09-27 (row 134) | Scan cost grows with embedded repos/hooks | 🟢 → Defer | Fail-closed; numbers in guide | Inherited; C1 recorded under it |
| `integrate/q076` / 2026-09-27 (row 135) | `commondir` first line read outside cc-gitdir.sh | 🟡 → Acknowledged ("fold at the next scan change") | Only matters for a launch-time state | Surfaced as C8: the trigger fired and was not acted on; deferred again with a new trigger |

---

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| The `invalid` check in `git_exit_scan` holds under `pipefail` with a large snapshot | ✅ Confirmed | `cc-exit-scan.sh:927-929` — `$'(^|\n)F\tgitdir-valid\t[^\t\n]*\tinvalid'`; FC submitted claim S1 (executed): 40k padding records, invalid `.git` → status 1, valid → 0; the pre-fix pipeline reads "nomatch" | security-reviewer, verified by fact-check | for-orchestrator-synthesis |
| `_snap_worktree_of` does not open a FIFO (or a link to one) | ✅ Confirmed | `cc-exit-scan.sh:328` — `[ -f "$1" ] &&`; FC S2 (executed): returns at once; guard removed → timeout 124 | security-reviewer, verified by fact-check | for-orchestrator-synthesis |
| Any record other than `+F dotgit/commondir-file/hooksdir`, or any W record in the exit snapshot, declines the note | ✅ Confirmed | `cc-exit-scan.sh:813-835`; FC S3 (executed): hook, C entry, link, config, removed record, W in exit only, W in both → status 1 each | security-reviewer, verified by fact-check | for-orchestrator-synthesis |
| The per-worktree `find -P "$p" -type l -quit` costs no more than the snapshot's own walk of P | ✅ Confirmed | `cc-exit-scan.sh:~858`; FC S4 (executed): 60,000 entries, 0.029 s vs the snapshot's 0.028 s | performance-reviewer, verified by fact-check | for-orchestrator-synthesis |

---

## ⚠️ Unverified Findings

All findings' evidence resolved.

---

## ⏭️ Skipped Core Critics

All core critics ran; no skips applied.

---

## 🧩 Composition check

| Cluster | File / lines | Fragments | Disposition |
|---|---|---|---|
| 1 | `cc-exit-scan.sh:80-84` + `:878-887` | A1 (security), A2 (fact-check) | distinct defects: A2 is the doc statement of the gap A1 exploits; A1's fix makes A2 true, and both rows state their mechanism |
| 2 | `cc-exit-scan.sh:793-805` | A4 (fact-check), C11 (tech-debt) | distinct defects: C11 is the cause (four copies), A4 the instance |

---

**Fact-check:** 57 merged claims (k=3): 36 Verified, 12 Mostly accurate, 4 Stale, 2 Incorrect, 3 Unverifiable; verdict agreement 41/57 (71.9%). Reports: `q094-final-A-code-fact-check-report.md` (merged), `-r1/-r2/-r3`, `q094-final-A-code-fact-check-submitted-claims.md`. Critic reports: `security-review-2026-09-28-q094-final-A.md`, `performance-review-2026-09-28-q094-final-A.md`, `api-consistency-review-2026-09-28-q094-final-A.md`, `tech-debt-triage-review-2026-09-28-q094-final-A.md`.

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or carry a qualifying author note (a discoverable TODO or a concrete revisit trigger; see "Qualifying author note" in `skills/code-review/references/rubric.md`). 🟢 items are optional.
