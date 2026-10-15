Commit: cb56299c
# Code Review Rubric

**Scope:** `fix/rebuild-hint-recreate`, 9660d4f6..cb56299c (iteration 1, `--loop-pass`, full unit) | **Reviewed:** 2026-10-15 | **Status: 🟡 DOES NOT PASS YET** — 0 red, 4 amber open

Iteration 1. Fact-check k=1 (loop pass, decision 031): `docs/reviews/code-fact-check-report-2026-10-15-rebuild-hint.md`. Critics: `security-review-2026-10-15-rebuild-hint.md`, `api-consistency-review-2026-10-15-rebuild-hint.md`. Delivery mode: inline-diff-only (agents read skill files and enclosing files from the worktree themselves).

---

## 🔴 Must Fix

None.

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | The copyable hint line ends in `# the supported path: ...`. Interactive zsh without `interactivecomments` passes those words as arguments, and `main()` keeps the last positional, so step 2 retargets to `./launches` (executed). Pre-existing form (old line ended `re-launches`). `devcontainer-config/cc-isolated.sh:564`, parser `:753` | Security | Medium | security-reviewer #1 | for-author | — | 🟡 Open | — |
| A2 | Three texts still say a plain launch rebuilds: the unverified-config NOTE ("the container is rebuilt from it", `cc-isolated.sh:877-878`), the header paragraph `--help` prints (`:60-62`, "rebuilds the container"), and `guides/cc-isolated-usage.md:955` ("The launch rebuilds and verifies"). False in the fail-closed state (no receipt, matching hash, container reused); the NOTE and the new hint contradict each other in one run (executed) | API / Docs | Incorrect (high), message text → 🟡 under T; Inconsistent | Fact-check claim 6 + api-consistency F1 | for-author | A4 (this unit is its follow-up) | 🟡 Open | — |
| A3 | `cc-isolated --help` says `(re)build WS from the blessed config` (`cc-isolated.sh:13`); the guide's copy (`cc-isolated-usage.md:25`) now says RECREATE | API | Inconsistent | api-consistency F2 | for-author | C5 | 🟡 Open | — |
| A4 | Commit cb56299c's Notes: the guide row quotes "Blessed config changed ... rebuilding" only up to "rebuilding" (not verbatim), and the next-launch recreate is caused by the blessed-hash change, not by init-firewall.sh being baked (fact-check claims 17, 18) | Docs (commit) | Mostly accurate | Fact-check | for-author | — | 🟡 Open | — |

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | `--bless`/`--list` "Next:" line describes `--probe-only` as "rebuilds from it" (`cc-isolated.sh:316`) | api-consistency F3 | Minor | for-author | — | 🟢 Open |
| C2 | `guides/cc-isolated-usage.md:841` "it always rebuilds first" (means recreates) | api-consistency F4, fact-check claim 10 | Minor | for-author | C5 | 🟢 Open |
| C3 | No test pins `--probe-only`'s non-zero exit on a failed probe, which the `&&` relies on | security-reviewer #2 | Informational | for-author | — | 🟢 Open |
| C4 | Hint printed by a provenance/config-identity failure during a `--probe-only` run points back at `--probe-only`; the cause is the build (e.g. a shadowing `.devcontainer/Dockerfile`), so repeating loops. Pre-existing | fact-check claim 3, security #3, api-consistency F6 | Informational | for-author | — | 🟢 Open |
| C5 | init-firewall.sh prints the recipe as two lines without `&&`; safe because the plain launch re-probes | api-consistency F5 | Informational | for-orchestrator-synthesis | — | 🟢 Open |
| C6 | Bats test name "--probe-only always rebuilds before probing" | api-consistency F7 | Informational | for-author | — | 🟢 Open |

---

## ↩️ Considered Overrides

| Override (PR ref / Date) | Prior finding | Original → Override | Reason | This run's treatment |
|---|---|---|---|---|
| `fix/doc-drift-cycle1` / 2026-10-15 (A4) | rebuild_hint's first line contradicts the guides' two-step recipe | 🟡 Must Address → Defer | brief put scripts out of scope | Resolved by this unit (cb56299c); its revisit trigger fired. |
| `fix/doc-drift-cycle1` / 2026-10-15 (C4) | init-firewall.sh "rebuilds" at :346, :349 | 🟢 Consider → Defer | script out of scope | Resolved by this unit (cb56299c). |
| `fix/doc-drift-cycle1` / 2026-10-15 (C5) | cc-isolated-usage.md :25 and "which rebuilds with both set"; comment at cc-isolated.sh:883 | 🟢 Consider → Defer | outside the brief's lines | Resolved by this unit (cb56299c); A3/C2 extend it. |
| `fix/doc-drift-cycle1` / 2026-10-15 (security i2 #2) | no refresh path for the cached CC layer | 🟢 Consider → Defer | launcher change out of scope | Inherited, not re-flagged; out of this unit's scope too. |

---

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| In the fail-closed state a plain launch reuses the container: no `--remove-existing-container`, no `claude`, exit non-zero, hint printed | ✅ Confirmed | `cc-isolated.sh:893-900` "if ! container_config_matches"; FC claim 1 (executed: stubbed launch log) | code-fact-check | for-orchestrator-synthesis |
| The three new/tightened tests fail on the 9660d4f6 scripts and pass on cb56299c | ✅ Confirmed | FC claim 19 (executed: tests 27, 102, 289 fail on old scripts; 289/289 pass on new) | code-fact-check | for-orchestrator-synthesis |
| The diff changes no non-comment, non-echo line in either script | ✅ Confirmed | FC claim 16 (executed: diff filtered to non-comment, non-echo lines is empty) | code-fact-check | for-orchestrator-synthesis |

---

## ⚠️ Unverified Findings

All findings' evidence resolved.

---

## ⏭️ Skipped Core Critics

| Critic | Reason | Signal |
|---|---|---|
| performance-reviewer | No fact-check claim or diff hunk in its domain | `git diff --stat`: echo text, comments, guide prose, bats assertions and one stub case arm; no loop, query or dependency |

---

## 🧩 Composition check

| Cluster | File / lines | Fragments | Disposition |
|---|---|---|---|
| 1 | `cc-isolated.sh:557-571` | A1, C3, FC 2/3 | distinct defects: A1 is the copyable line's trailing comment, C3 a missing test of the exit status, FC 3 a pre-existing wrong remedy for build failures |
| 2 | `cc-isolated.sh:665-687` | C4 (FC 3, security #3, api F6) | distinct defects: one pre-existing issue reported three times, already one row |
| 3 | `cc-isolated.sh:875-880` / guide `:955` | A2 (FC 6, api F1) | distinct defects: one wording defect already stated in full by both sources |

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or
carry a qualifying author note (a discoverable TODO or a concrete revisit trigger; see
"Qualifying author note" in `skills/code-review/references/rubric.md`). 🟢 items are optional.
