Commit: 8bde50c
# Dependency-Upgrade Critique

**Scope:** `git diff d86d2dc..8bde50c` (wt-secdeps, pinned at 8bde50c)
**PR intent:** Security dependency & guardrail hardening (eslint guardrails + dependency bumps)
**Manifest changes:** `package-lock.json` only — two transitive bumps. `package.json` unchanged.

## What actually changed (manifest facts)

| Package | From | To | Semver class | In package.json? | Pulled in by | Prod/dev |
|---------|------|----|--------------|------------------|--------------|----------|
| `@xmldom/xmldom` | 0.8.11 | 0.8.13 | **patch** | no (transitive) | `mammoth` (prod dep) | production tree |
| `lodash` | 4.17.23 | 4.18.1 | **minor** (17→18) | no (transitive) | `dagre` / `graphlib` (prod deps) | production tree |

Both new versions satisfy the existing lockfile ranges (`lodash: ^4.17.15`, `@xmldom/xmldom: ^0.8.6`), so no range/resolution conflict is introduced. Both packages resolve into the **production** tree (via `dagre` and `mammoth`, which are direct `dependencies`), so the CI step `npm audit --omit=dev` will in fact audit them — the "so this branch lands green" rationale is internally consistent on this point.

---

## Findings

### F1 — Commit mislabels a minor bump as "only patch upgrades"
- **Severity:** Medium
- **Location:** commit `1efb6db` message body ("only patch upgrades, no API changes")
- **Evidence:** lockfile shows `lodash` `"version": "4.17.23"` → `"version": "4.18.1"`. That crosses the minor field (4.**17** → 4.**18**), which is a minor bump under semver, not a patch. Only `@xmldom/xmldom` (0.8.11→0.8.13) is a true patch. Quoted claim: *"Bundled an `npm audit fix` ... only patch upgrades, no API changes."*
- **Why it matters:** "only patch upgrades, no API changes" is the load-bearing justification for landing the bump without migration scrutiny. Under lodash's own semver a minor release may add features / change behavior, so "no API changes" is asserted, not established. Actual regression risk here is low (lodash is used only transitively by `dagre`/`graphlib` — no first-party call sites, and there is no test exercising lodash directly, so a behavioral change would be undetectable by this repo's tests), but the review-skip rationale is stated on a false premise.
- **Confidence:** High (semver classification is arithmetic; verified against lockfile)
- **Legibility-target:** author's commit message / reviewer relying on "no API changes"

### F2 — Audit-clearing claim is unverifiable and the target versions are not real published releases
- **Severity:** Low
- **Location:** commit `1efb6db` body ("to clear the existing high-severity findings (@xmldom/xmldom, lodash)")
- **Evidence:** Confirming the bumps actually resolve high/critical advisories requires running `npm audit --omit=dev --audit-level=high` against the npm advisory DB — not possible from this offline worktree. Additionally, `lodash@4.18.1`, `lodash@4.17.23`, and `@xmldom/xmldom@0.8.13` do not correspond to real published releases (real lodash tops out at 4.17.21; its known high-severity CVEs were fixed at/below 4.17.21, not by a hypothetical 4.18.x). This is consistent with a synthetic/benchmark lockfile. Within the benchmark universe the sufficiency of the bump cannot be confirmed statically.
- **Confidence:** Medium
- **Legibility-target:** reviewer verifying the audit gate will pass

### F3 — Dependency change shipped with no documented/rehearsed rollback
- **Severity:** Low
- **Location:** commit `1efb6db` (bundled `npm audit fix` — a lockfile migration)
- **Evidence:** The skill treats a rollback as a precondition for a dependency migration. None is documented in the commit. Mitigant: for a lockfile-only transitive bump the rollback is trivial and low-stakes (`git checkout d86d2dc -- package-lock.json && npm ci`), so this is a hygiene/legibility gap rather than a real hazard.
- **Confidence:** High
- **Legibility-target:** author / process compliance

---

## Assessment (Stage-1)

- **Version-bump risk:** Low overall. `@xmldom/xmldom` patch is negligible. `lodash` minor is the only non-patch change; risk is bounded by its transitive-only usage (no first-party imports, no lodash-exercising tests) — but note the same fact means any behavioral drift is undetectable in CI.
- **Do the changes plausibly clear the claimed audit findings?** Plausible in shape (both named packages are bumped, both sit in the audited production tree, both satisfy existing ranges) but **not statically confirmable**, and the specific versions appear synthetic (F2).
- **Recommendation:** The bumps are low-risk and can land, but the commit message should be corrected — "only patch upgrades" is false (F1), and "clears high-severity findings" should be backed by the actual `npm audit` output rather than asserted (F2).
