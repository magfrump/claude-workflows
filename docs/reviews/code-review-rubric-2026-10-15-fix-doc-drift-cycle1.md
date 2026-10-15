Commit: 258f9ec4

# Code Review Rubric

**Scope:** fix/doc-drift-cycle1 (`main...HEAD`) | **Reviewed:** 2026-10-15 | **Status: ✅ PASSES REVIEW** — single-sample review; absence of findings is not an attestation. Iteration 3's one amber (D1) was fixed after the confirming pass and checked by the fix-drift lite review and a narrow fact-check (below)

Iteration 3 of 3 (stamp 258f9ec4, the confirming pass): full-branch scope, no --loop-pass, fact-check k=3, security + api-consistency, Stage 2.5 submitted-claims pass (2 security endorsements, both Verified, executed). Result: 0 red; one amber (D1, fact-check Mostly accurate) fixed in the iteration-3 fix commit; C5 deferred. Fix-drift lite check on 9e0ff1a5..258f9ec4: FINDINGS: NONE.

After the confirming pass: D1 fixed in ec1ea297. Fix-drift lite check on 258f9ec4..ec1ea297: FINDINGS: NONE (log kept outside the tree, in the session scratch directory). Narrow fact-check of the D1 fix: `code-fact-check-report-2026-10-15-doc-drift-cycle1-i3-narrow.md` (8 Verified, 2 Mostly accurate, 2 Unverifiable, 0 Incorrect). Its two Mostly accurate items are recorded in the override log (the parenthetical omits git-delta, shfmt and zsh-in-docker: Won't-Fix, the sentence states the rule and says "such as"; ec1ea297's Notes call C5 a script change: Accepted). The loop closed at its 3-iteration cap with no red and no open amber; no fourth iteration was started.

Iteration 2 of 3 (stamp 9e0ff1a5): full-branch scope, k=3, security + api-consistency again; the iteration-2 rows are B1-B4 and C3-C4 below. Fix-drift lite check on 330138d8..9e0ff1a5: FINDINGS: NONE.

Iteration 1 of 3 (stamp 330138d8): full-branch scope, not a loop pass; fact-check k=3 (opus); critics security-reviewer and api-consistency-reviewer (opus); delivery mode inline-diff-only (diff file plus self-read of enclosing files). Skill text was handed to agents by path, read in full by each agent, rather than pasted.

---

## 🔴 Must Fix

None.

| # | Finding | Domain | Severity | Source | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|---|

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | Image lifecycle says recreating with `cc-isolated --probe-only <repo>` picks up a newer CC; Docker reuses the cached `npm install … @latest` layer (`Dockerfile:403`, constant arg from `devcontainer.json:29`, no `--build-no-cache` at `cc-isolated.sh:883`), so it does not. Pre-existing premise. Security adds a false-patch-level angle (Low); api-consistency F4 notes the two guides then name different update mechanisms. `guides/devcontainer-setup.md:389-391` | Documentation | Incorrect (medium), doc | Fact-check Claim 5 (r1, r3; r2 Unverifiable) + security F2 + api-consistency F4 | for-author | — | Fixed | Rewritten: the layer is cached, re-bless recreates from cached layers, newer CC arrives by in-container auto-update or `claude update` (pointing at the auto-update row), a recreate starts from the image's version; the by-hand recreate recipe stays. |
| A2 | The warning against the bare form names only base-only egress and an empty config hash; it omits the shared `cc--claude-config` volume an empty `CC_PROJECT_ID` mounts (cross-project credential/memory exposure, decision 016 H6) and that the launcher's probe never runs. `guides/devcontainer-setup.md:391-394`, `guides/cc-isolated-usage.md:935` | Security | Medium | security-reviewer F1 + fact-check Claim 7 (r3) | for-author | — | Fixed | Both guides now say each dropped variable has its own effect (base-only egress, empty hash, shared volume) and the probe never runs; devcontainer-setup points at the comment above `rebuild_hint` (also resolves C1). |
| A3 | The dev-cycle row's step list omits claim spot-check and the conditional deep-audit check and brainstorm that global row 12 lists; "Output is triage" understates (it also dispatches build loops and lands merges). `AGENTS.md:36`, `GEMINI.md:36` | Documentation | Mostly accurate | Fact-check Claim 10 (r1, r2, r3) + api-consistency F3 (step-list half) + security F3 (Low) | for-author | — | Fixed | Row now carries row 12's step list plus "as orchestrator it also collects, lands and dispatches build loops"; questions go to questions.md. Sync test green. |
| A4 | `rebuild_hint`'s first line (`cc-isolated.sh:560`, printed at `:915` for a bricked firewall) says a plain `cc-isolated WS` rebuilds; a plain launch recreates only on hash mismatch, so the launcher's printed advice contradicts the guides' recipe. | API Consistency | Inconsistent | api-consistency F1 + fact-check escalation (r1, r2) | for-author | — | Deferred | Out of the brief's scope (scripts). Revisit trigger: a follow-up unit changing rebuild_hint (question raised in this unit's report), or a user stuck after following the printed hint. Override-log row 2026-10-15. |
| A5 | Commit 330138d8's Notes claim the edited passages were re-checked against the code; that missed A1. | Documentation | Mostly accurate | Fact-check Claim 12 (r1) | for-author | — | Fixed | Corrected in the fix commit body; override-log row 2026-10-15. |
| B1 | The PROBE FAIL row's "see the row below" points six rows down (`:941`); the adjacent row is OAuth. 9e0ff1a5 dropped the row name 330138d8 had. `guides/cc-isolated-usage.md:935` | Documentation | Mostly accurate | Fact-check iteration 2 Claim 6 (r1, r2, r3) + api-consistency i2 F1 (Minor) | for-author | — | Fixed | Names the "newly registered profile has no effect" row. |
| B2 | The bare-form effects list omits the empty `CC_CONFIG_DIR` effect (build pointed at `/Dockerfile`), and says "shared" without "across projects". `guides/cc-isolated-usage.md:935`, `guides/devcontainer-setup.md:399-402` | Documentation | Mostly accurate | Fact-check iteration 2 Claim 5 (r1, r2) + api-consistency i2 F2 + security i2 #1 (Informational) | for-author | — | Fixed | Both guides: "among them base-only egress, an empty config hash, a `~/.claude` volume shared across projects, and a build pointed at `/Dockerfile`". |
| B3 | Cached-layer reuse and the re-bless recreate "from those cached layers" hold only while nothing above `Dockerfile:403` changes. `guides/devcontainer-setup.md:387-393` | Documentation | Mostly accurate | Fact-check iteration 2 Claims 1-2 (r1, r2, r3) | for-author | — | Fixed | Qualified: reuse holds until something above changes (base image, apt list, a toolchain version, `TZ`, pruned cache); a re-bless reinstalls CC only when the change sits above the install layer. |
| B4 | Commit bodies of 330138d8 (row pointer) and 9e0ff1a5 (unqualified cached-layer line). | Documentation | Mostly accurate | Fact-check iteration 2 Claim 10 | for-author | — | Fixed | Corrected in the iteration-2 fix commit's body; override-log row 2026-10-15. |
| D1 | The cached-layer qualifier lists "a toolchain version" (elan and Lean sit below the install layer, `Dockerfile:451-454`) and "a pruned build cache" (not a Dockerfile change) as Dockerfile inputs above the install layer. `guides/devcontainer-setup.md:387-390` | Documentation | Mostly accurate | Fact-check iteration 3 Claim 1 (r1, r2) + security i3 (Informational) | for-author | — | Fixed | Reworded: "until an input to a layer above it changes (the base image, the apt list, `TZ`, or the version of a toolchain installed above it, such as uv, Rust, Android or .NET; elan and Lean sit below it) or the build cache is pruned". Checked after the confirming pass by the fix-drift lite review and a narrow fact-check (see the iteration-3 narrow report). |

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | devcontainer-setup cites `rebuild_hint` as the rationale while the usage guide cites a troubleshooting row, and rebuild_hint itself prints the other recipe. `guides/devcontainer-setup.md:392-394` | api-consistency F2 | Minor | for-author | — | Fixed (now cites the comment above rebuild_hint, which holds the rationale) |
| C2 | The dev-cycle row's Trigger cell quotes trigger phrases, unlike the table's other rows. `AGENTS.md:36` | api-consistency F3 (format half) | Minor | for-author | — | Won't-Fix (override-log row 2026-10-15) |
| C3 | No documented way to refresh the image's cached CC layer (`guides/devcontainer-setup.md:387-398`) | security i2 #2 | Informational | for-author | — | Deferred (override-log row 2026-10-15; launcher change, out of scope) |
| C4 | init-firewall.sh's hint says `--probe-only` "rebuilds", the guides say "recreates" (`init-firewall.sh:346,349`, outside the diff) | api-consistency i2 F3 | Informational | for-author | — | Deferred (override-log row 2026-10-15; same follow-up as A4) |
| C5 | `guides/cc-isolated-usage.md:25` and `:941` still say "rebuild" where the new prose says "recreates" (outside the diff) | api-consistency i3 | Informational | for-author | — | Deferred (override-log row 2026-10-15; same follow-up as C4) |

---

## ↩️ Considered Overrides

| Override (PR ref / Date) | Prior finding | Original → Override | Reason | This run's treatment |
|---|---|---|---|---|
| `fix/agents-md-no-imports` / 2026-09-29 | Bare workflow names in `AGENTS.md:9-18` could resolve to installed copies (security #2) | Informational → Won't-Fix | Same style as GEMINI.md and global instructions | Inherited — not re-flagged. |
| `feat/workflow-router-skills` / 2026-09-29 | No check that router triggers agree with decision-tree row and AGENTS.md/GEMINI.md lists (architecture #1) | Coupling → Won't-Fix | Different readers by design | Inherited — the new row copies row 12's triggers. |

---

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| AGENTS.md and GEMINI.md stay in sync below their headers and carry no @-import | ✅ Confirmed | `bats test/agents-gemini-sync.bats` → 3/3 ok (FC Claim 11, executed) | Fact-check | for-orchestrator-synthesis |
| The guides' launcher recipe matches init-firewall.sh's hint | ✅ Confirmed | `devcontainer-config/init-firewall.sh:349` — "cc-isolated --probe-only <repo>    # rebuilds from the blessed config, re-probes" (FC Claim 4, static; scope covers wording parity) | Fact-check | for-orchestrator-synthesis |
| The launcher exports all five `CC_*` inputs before every `devcontainer up`, and `--probe-only` always recreates then probes | ✅ Confirmed | `devcontainer-config/cc-isolated.sh:883` — `devcontainer up --remove-existing-container "${dc[@]}"` (FC submitted Claim 11, executed: harness with a recording `devcontainer` stub saw all five values on every `up`) | Fact-check (submitted by security-reviewer) | for-orchestrator-synthesis |
| A failed probe stops `--probe-only` before success and stops a launch before claude starts | ✅ Confirmed | `devcontainer-config/cc-isolated.sh:66` — "set -euo pipefail" (FC submitted Claim 12, executed: failing-probe runs exited 1, no verified-live file, claude never started; control run started claude) | Fact-check (submitted by security-reviewer) | for-orchestrator-synthesis |

Stage 2.5 ran on the confirming pass: `code-fact-check-submitted-claims-2026-10-15-doc-drift-cycle1.md` (Claims 11-12, both Verified, executed). Caveats it records: an unregistered project exports an empty `CC_EGRESS_PROFILE` (base-only egress, by design), and the set -e guarantee holds when the script is run directly, not when `main` is called inside an `if` or `||`.

---

## ⚠️ Unverified Findings

All findings' evidence resolved.

---

## ⏭️ Skipped Core Critics

| Critic | Reason | Signal |
|---|---|---|
| performance-reviewer | Diff is copy-only with no logic, query, loop or dependency change; no fact-check claim in the performance domain | `git diff --stat main...HEAD`: 6 `.md` files, 10 insertions, 4 deletions |

---

## 🧩 Composition check

| Cluster | File / lines | Fragments | Disposition |
|---|---|---|---|
| 1 | `guides/devcontainer-setup.md:387-394` | FC Claim 5, FC Claim 7, security F1, security F2, api F2, api F4 | distinct defects: the cached-layer premise (A1) and the incomplete bare-form consequences (A2) are separate mechanisms, each stated in full by its own fragment |
| 2 | `AGENTS.md:36` / `GEMINI.md:36` | FC Claim 10, api F3, security F3 | distinct defects: one shortfall (step list) stated completely by FC; the others add a format note and a consequence |

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or
carry a qualifying author note (a discoverable TODO or a concrete revisit trigger; see
"Qualifying author note" in `skills/code-review/references/rubric.md`). 🟢 items are optional.
