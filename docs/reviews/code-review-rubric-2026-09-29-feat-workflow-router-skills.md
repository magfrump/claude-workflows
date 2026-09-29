Commit: 33fdfd3
Loop closed at 33fdfd3

# Code Review Rubric

**Scope:** feat/workflow-router-skills vs main (8 router skills, divergent-design router edit, test/skills/workflow-routers.bats, workflows/review-fix-loop.md frontmatter, global instructions paragraph, README, guides/skill-creation.md, decision log row 66) | **Reviewed:** 2026-09-29 | **Status: 🟢 PASS** — the final confirming pass had no Must Fix and no Must Address. Its Consider items were applied after the pass or logged in the override log. Single-sample review; absence of findings is not an attestation.

Loop: 2 iterations.
1. **Iteration 1:** k=3 fact-check on 3a63c56, fixes in 881762a, then 4 critics on de96617, fixes in 028105b.
2. **Iteration 2, the final confirming pass on 33fdfd3:** full branch after merging main, k=3 fact-check, security, performance, api-consistency and architecture-review.

The post-pass Consider fixes were verified by targeted suites (19 tests) and a mutation for the new orphan test. Delivery mode: self-read. Dispatch mode: parallel. Considered overrides: no prior overrides matched this diff.

---

## 🔴 Must Fix

None in either iteration.

---

## 🟡 Must Address (iteration 1, all resolved)

| # | Finding | Source | Status |
|---|---|---|---|
| A1 | Row 66 and the test header cited the "DD 15x, RPI 0x" usage figures, which their source withdrew (Q-017) | fact-check ×3 | ✅ Fixed (881762a) |
| A2 | The review-fix-loop router contradicted its workflow | fact-check ×3 | ✅ Fixed: router removed; opt-out via workflow frontmatter |
| A3 | "Cannot drift" was false: routers copied workflow facts | fact-check; architecture Coupling #2 | ✅ Fixed |
| A4 | Flat skill matching lost the decision tree's precedence | architecture Coupling #1; api; performance | ✅ Fixed: precedence clauses plus the first-match rule |
| A5 | Descriptions ran past the 250-char listing cut-off | api #1 | ✅ Fixed (all ≤250 in full after the final pass) |
| A6 | The relative handoff path could follow a same-named file in another project | security Medium; performance; architecture | ✅ Fixed: installed path plus the never-follow line; tested |
| A7 | pr-prep and code-review descriptions overlap | api #2 | 🟡 Deferred (outside diff; override log) |

## 🟢 Consider (final pass)

| # | Finding | Source | Status |
|---|---|---|---|
| C1 | "Triggers inside 250" held for the label, not the whole list; three routers named no sibling | fact-check r1–r3 (Mostly accurate) | ✅ Fixed: descriptions ≤250 in full; each names a sibling; row 66 reworded |
| C2 | Router descriptions still named the relative `workflows/<name>.md` | security final #1 (Low) | ✅ Fixed: descriptions now say "the <name> workflow" |
| C3 | RPI did not route feasibility questions to spike | api final #1 | ✅ Fixed |
| C4 | Global paragraph wrote the opt-out as `router: none` | fact-check r1, r2 | ✅ Fixed |
| C5 | Test header called the DD suite "stricter" | fact-check r2 | ✅ Fixed |
| C6 | Orphaned routers are not caught | architecture final #1 | ✅ Fixed: reverse test, verified by mutation |
| C7 | The `router:` key is undocumented where workflow frontmatter is described | architecture final #3 | ✅ Fixed: guides/skill-creation.md |
| C8 | Two routers restate their workflow's gate | architecture final #2 | 🟢 Won't-Fix (override log: deliberate safety restatements) |
| C9 | The DD router test still requires `when:` | architecture final #5; api final #3 | 🟢 Deferred (override log) |
| C10 | ~675 tokens/session in every project; one extra tool call per fire | performance final #3/#4 | 🟢 Accepted |
| C11 | The loader ignoring `when:` can't be checked in-repo | fact-check r2 (Unverifiable) | 🟢 Accepted (guides/skill-format-audit.md F1) |

## ⏭️ Skipped Core Critics

None.

## 🧩 Composition check

| Cluster | Disposition |
|---|---|
| Description window (fact-check r1–r3, performance final #1) | distinct defects: none new; one fix (C1) |
| Handoff path (security final #1, performance final #2) | distinct defects: none new; one fix (C2) |

Artifacts from iteration 1 that share canonical names with fix/agents-md-no-imports are kept as `*-routers-3a63c56.md` / `*-routers-de96617.md`. The final-pass artifacts are `*-routers-final.md`.
