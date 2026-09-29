# Code Review Rubric

**Commit:** 2eebdf8 reviewed (full panel); fix commits 7c97a6b and 95ebf9b re-reviewed (security + fact-check k=1). After rebasing onto unit A's review-artifact commit these are 6d48b15, 7babd8e and 2e64be6, with the same trees apart from A's `docs/reviews/` files.
**Scope:** `q094b-exit-scan-worktree-removal`, 9075003..2eebdf8 (stacked on `q094-exit-scan-worktree-layout`), then the fix range | **Reviewed:** 2026-09-28 | **Status: 🟢 PASSES** — 0 red; every 🟡 fixed or carrying a qualifying author note — single-sample review; absence of findings is not an attestation

Terminal confirming pass (pr-prep 3d): full panel, no `--loop-pass`, fact-check k=3 (opus), critics opus: security, performance, api-consistency. No contextual critic triggered (174 lines, tests changed, no manifest/UI/module change). Delivery mode: self-read, partial-scope label on every prompt. The fix commit 7c97a6b also carries unit A's code, comment and guide fixes (unit A is at the row-62 cap), so it was re-reviewed by security and a k=1 fact-check. The last commit (95ebf9b), comment and guide text only, is covered by the test run but has not been re-reviewed.

---

## 🔴 Must Fix

None.

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | `scan_std_worktrees` comment "Paths are compared as the %q strings … nothing is unquoted" and plan B18 "never unquoted" were stale once the removal branch decoded with `_snap_unq` | Fact-check | Stale | Fact-check (r1, r2, r3); api-consistency 2 | for-author | — | Fixed (7c97a6b; B18 wording 95ebf9b) | — |
| A2 | Note "Removed ones left no git dir behind" claimed more than the check did: a repo at the old `.git` path behind a symlinked parent got the note (executed probe) | Fact-check + Security | Mostly accurate / Low | Fact-check r1; security F1 | for-author | — | Fixed (7c97a6b) | Removal also requires nothing at the old `.git` path; note now "Removed ones' git dir and .git file are gone". Test: symlinked parent to an outside repo warns, the same link without the repo is a note. Mutation-checked |
| A3 | A `$'…'` path (tab, non-ASCII in C locale) is a note when added but warns when removed | API consistency | Inconsistent | api-consistency 1; fact-check escalation (r1, r3); security F4 | for-author | — | Acknowledged, documented | Fails closed. The guide states the asymmetry (7c97a6b, newline corrected in 95ebf9b). Revisit trigger: agent worktree paths with such bytes appear in practice (removals would warn every time); then decode `$'…'` or decline those paths on add too |
| A4 | A symlink in the working tree to a repo outside the checkout is not walked (pre-existing; not new capability from B) | Security | Medium (skill floor; confidence Low) | security F2 | for-author | row 133 (a related documented limit) | Documented | Known routes bullet added (7c97a6b). Revisit trigger: the container gains write access to a host path outside the checkout that the host user's git would run in (e.g. rootless-Docker volumes) |
| A5 | Fix re-review: `_snap_container_target` maps `/workspace/<rel>` → `<checkout>/<rel>`, but `git worktree repair` picks the git dir by worktree name, and a mapped git dir outside `.git/` is never walked; reachable only from a non-standard container-form `.git` present at launch (executed) | Security | Medium (pre-existing to the fix; the note path is covered) | security re-review F1 | for-author | — | Documented | Known routes bullet (95ebf9b). Revisit trigger: a finding or report of a container-form `.git` left by an earlier session; the fix then is to walk every unresolved `.git`'s inferred git dir with all includeIf conditions treated as matching |
| A6 | Fix re-review, fact-check: header "in any config the scan reads" wrong for your own config's remotes; guide listed a newline among note-on-add paths; `_snap_bytes` note implied all three helpers need it; B18 "from the parsed name" | Fact-check | Incorrect (comment/doc only) ×2, Mostly accurate ×2 | fact-check k=1 on 7c97a6b | for-author | — | Fixed (95ebf9b) | — |
| A7 | Fix re-review, fact-check: plan links `code-review-rubric-2026-09-28-q094-final-A.md`, which did not exist yet | Fact-check | Incorrect (doc) | fact-check k=1 | for-author | — | Fixed (9e8105f adds it) | — |

**Immutable history (not tiered).** 2eebdf8 (now 6d48b15) Notes: "the added side already declines such paths (its back-pointer read is one line)" is true only for a newline (fact-check Incorrect, r1+r2+r3; the guide now states the asymmetry): override-log `Accepted-immutable` row appended. 1f31b18's "89 changed code lines" counts 9 guide lines (80 code). 7c97a6b's Notes cite "2eebdf8", renamed by the rebase.

**Informational (security re-review F2).** With a relative `core.hooksPath` in your own config, container-form removals now warn (as host-form ones already did); the guide says so (95ebf9b).

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | The removal loop over `dot[]` is O(N²) in removed worktrees (loop alone 3.2 s at N=500, 55 s at N=2000) | performance-reviewer | Low | for-author | row 134 | Deferred: index removed dotgit records by content if N > 100 becomes real; keep pairing by content |
| C2 | ~5 subshells and 2 sha256sum per removal; `_snap_unq` is quadratic in path length (80 ms at ~PATH_MAX) | performance-reviewer | Informational | for-orchestrator-synthesis | — | Accepted |
| C3 | `_snap_unq` returned through a caller-named variable, unlike its stdout siblings | api-consistency-reviewer | Minor | for-author | — | Fixed (7c97a6b: stdout) |
| C4 | The guide showed only the `added:` note form and framed removals as "left behind" | api-consistency-reviewer | Minor | for-author | — | Fixed (7c97a6b: all three forms listed); heading kept |
| C5 | The `_snap_*` header said every helper runs inside `git_exec_snapshot` | api-consistency-reviewer | Informational | for-author | — | Fixed (7c97a6b) |
| C6 | A bare repo in a subdirectory of a removed tree, or a parent dir turned into a bare repo, still gets the note | fact-check r3; security re-review | Informational | for-author | row 133 | Accepted: the documented "repository in a directory not named `.git`" route |
| C7 | Stage 2.5: the performance endorsement's "14.5 s at N=100" for the added path measured 7.3–11.4 s (removal path 1.3–1.4 s confirmed) | fact-check submitted claims (S3b) | Mostly accurate | for-author | — | Noted; the ratio is 5–8×, not ~10× |

---

## ↩️ Considered Overrides

| Override (PR ref / Date) | Prior finding | Original → Override | Reason | This run's treatment |
|---|---|---|---|---|
| `integrate/q076` / 2026-09-27 (row 133) | Bare-layout repo in a dir not named `.git` not walked | 🟢 → Defer | Documented limit | Inherited; C6 falls under it |
| `integrate/q076` / 2026-09-27 (row 134) | Scan cost grows with embedded repos/hooks | 🟢 → Defer | Fail-closed; numbers in guide | Inherited; C1 recorded under it |
| `integrate/q076` / 2026-09-27 (row 135) | `commondir` first line read outside cc-gitdir.sh | 🟡 → Acknowledged | Launch-time state only | Not touched by B; see unit A rubric C8 |

---

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| `_snap_unq` returns only a string whose `printf %q` equals its input; a differing decode declines | ✅ Confirmed | `cc-exit-scan.sh` `_snap_unq` — `[ "$(printf '%q' "$s")" = "$q" ] \|\| return 1` before output; FC submitted S1 (executed): 3,017 round-trip paths, 3,014 exact, 3 declines, 0 wrong; Stage-1 fuzz 20,000 per locale, 0 wrong | security-reviewer, verified by fact-check | for-orchestrator-synthesis |
| A removed `dotgit` record pairs only with the removed `commondir-file` of the same `<n>` when its content is exactly `gitdir: P\n` (either form), each record consumed once | ✅ Confirmed | removal branch of `scan_std_worktrees` — `re="^file [0-7]+ ($h${g:+\|$g})\$"`; FC submitted S2 (executed): five wrong-content variants, link form, other `<n>`, two records for one P, duplicate content → declined; container form same `<n>` → accepted | security-reviewer, verified by fact-check | for-orchestrator-synthesis |
| The removal path returns the note in ~1.4 s at N=100 removed worktrees on this host | ✅ Confirmed | FC submitted S3a (executed): 1.40, 1.38, 1.34 s | performance-reviewer, verified by fact-check | for-orchestrator-synthesis |

---

## ⚠️ Unverified Findings

All findings' evidence resolved.

---

## ⏭️ Skipped Core Critics

All core critics ran; no skips applied. (The fix-commit re-review ran security and fact-check only; performance and api-consistency were not re-run on 7c97a6b/95ebf9b.)

---

## 🧩 Composition check

| Cluster | File / lines | Fragments | Disposition |
|---|---|---|---|
| 1 | `cc-exit-scan.sh` removal branch + note (`:884-890`, `:939-940`) | A2 (fact-check 7b), security F1, api 6 | composed → A2: one root (the note's claim vs. a check that skipped the old `.git` path), one fix; recorded as a single row |
| 2 | `cc-exit-scan.sh:788` + `:913-921` | A3 (api 1), security F4, fact-check escalation | distinct defects: none; one finding reported three times, recorded once |

---

**Fact-check:** 23 merged claims (k=3): 18 Verified, 2 Mostly accurate, 2 Stale, 1 Incorrect; verdict agreement 22/23 (95.7%). Fix re-review (k=1): 47 claims, 40 Verified, 3 Mostly accurate, 3 Incorrect, 1 Unverifiable, all doc/comment, fixed in 95ebf9b or 9e8105f. Reports: `q094-final-B-code-fact-check-report.md` (merged; also the canonical `code-fact-check-report.md`), `-r1/-r2/-r3`, `q094-final-B-code-fact-check-submitted-claims.md`, `q094-final-B-code-fact-check-report-fix.md`. Critics: `security-review-2026-09-28-q094-final-B.md`, `security-review-2026-09-28-q094-final-B-fix.md`, `performance-review-2026-09-28-q094-final-B.md`, `api-consistency-review-2026-09-28-q094-final-B.md`.

**Tests at the fix commit:** `test/cc-isolated-functions.bats` 173/173; `scripts/run-tests.sh` 1465 ok, 0 failed, exit 0.

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or carry a qualifying author note (a discoverable TODO or a concrete revisit trigger; see "Qualifying author note" in `skills/code-review/references/rubric.md`). 🟢 items are optional.
