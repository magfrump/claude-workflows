Commit: 330138d8

# Code Review Rubric

**Scope:** fix/doc-drift-cycle1 (`main...HEAD`, 1 commit, 12 non-docs lines) | **Reviewed:** 2026-10-15 | **Status: 🟡 CONDITIONAL PASS** — 0 amber item(s) awaiting resolution or justification after the iteration-1 fix commit (see statuses)

Iteration 1 of 3: full-branch scope, not a loop pass; fact-check k=3 (opus); critics security-reviewer and api-consistency-reviewer (opus); delivery mode inline-diff-only (diff file plus self-read of enclosing files). Skill text was handed to agents by path, read in full by each agent, rather than pasted.

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

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | devcontainer-setup cites `rebuild_hint` as the rationale while the usage guide cites a troubleshooting row, and rebuild_hint itself prints the other recipe. `guides/devcontainer-setup.md:392-394` | api-consistency F2 | Minor | for-author | — | Fixed (now cites the comment above rebuild_hint, which holds the rationale) |
| C2 | The dev-cycle row's Trigger cell quotes trigger phrases, unlike the table's other rows. `AGENTS.md:36` | api-consistency F3 (format half) | Minor | for-author | — | Won't-Fix (override-log row 2026-10-15) |

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

The security critic's launcher-path endorsement (routed to code-fact-check) is pending execution verification: Stage 2.5 was deferred to the confirming pass because fixes follow this pass.

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
