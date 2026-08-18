# Code Review Rubric

**Scope:** `9c9edf5...7f30210` (mfc-postfix) | **Commit:** 7f30210 | **Reviewed:** 2026-08-18 | **Status: 🔴 DOES NOT PASS** — 1 red item unresolved

Mixed change: CSP eval-policy helper (`proxy.ts`), a streaming-preview type seam (`mergeStreamingPreview` / panels), evidence-query lifecycle (`evidence-search/route.ts`, `evidenceStore.ts`), and a `between`-tension render guard. Fact-check ran k=2 (one replicate path degraded per header); Stage 2.5 verdicted 3 routed endorsement claims.

---

## 🔴 Must Fix

Issues that must be resolved before merge. Draft cannot pass review with any red items unresolved.

| # | Finding | Domain | Severity | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|
| pf-R1 | Streaming-preview seam gives partial-JSON data a **complete-artifact** type identity: `parsePartialJson` → `unknown` is `as`-cast to the complete type at `page.tsx:951-994`, and `mergeStreamingPreview<T>` returns it as `T`. The compiler then tells every consumer required fields are always present, so the next unguarded required-field dereference (`t.between[0]`) type-checks and crashes mid-stream; with **no error boundary anywhere in `app/`** (FC Claim 11, executed) the throw unmounts the whole tree. The shipped `{t.between && …}` guard fixes one field, not the seam. Mechanism intact — this is the root defect, not the crash. | Architecture (Structural) | Structural | `mergeStreamingPreview.ts:8-16`, `useStreamingMerge.ts:8-16`, `page.tsx:951-994`, `BalancedPerspectivesPanel.tsx:12-13` | for-author | — | 🔴 Unresolved |

---

## 🟡 Must Address

Issues that must be fixed or acknowledged by the author with justification for why they stand.

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| pf-A1 | **Fail-open eval-policy default.** `allowUnsafeEval = process.env.NODE_ENV !== "production"` hardens only for the exact string `"production"`; every other value (unset, `"staging"`, `"preview"`, `"test"`, `""`) appends `'unsafe-eval'` to `script-src` (FC Claim 1, executed — direction confirmed real). Diverges from the repo's only sibling dev-gate `isCorpusEnabled()`, which is fail-**closed** and caller-sealed; here the exported param is also caller-overridable, so "dev-only" holds by call-site discipline only. Named mechanism (a dev-only flag enforceable in production) holds the Medium floor. Fix: default `=== "development"` and/or route through a shared production-sealing guard. | Security | Medium | Security (Medium) + API-consistency (Inconsistent) + Architecture (Coupling) — 3-domain convergence | for-author | — | 🟡 Open | — |
| pf-A2 | **`buildCsp` default (NODE_ENV-derived) branch is untested.** The doc/coverage claim that the committed suite covers the default path is **Incorrect** (FC Claim 5, high): the only default-arg caller is prod code `proxy.ts:53`, while both tests pass an explicit boolean, so the env→boolean derivation is unexercised. Code is correct; the defect is that a reader believes the branch is tested. Fix: add a test stubbing `NODE_ENV` and calling `buildCsp(nonce)`. | Fact-check | Incorrect (high; reader-misinformed → 🟡 per decision 031) | Fact-check (Claim 5, Incorrect) + Security + Architecture | for-author | — | 🟡 Open | — |
| pf-A5 | **Unbounded spread of the OpenAlex response array into `Math.max(...allWorks.map(...))`.** `searchOpenAlex` returns `data.results` verbatim with **no slice** (`route.ts:126`); `per_page=5` is only a *request* param. Query-count bound (≤25/≤15) is Verified (FC Claim 6) but Claim 6's Scope **explicitly excludes** what OpenAlex actually returns. Security measured the spread ceiling: `Math.max(...arr)` throws `RangeError` at ~125k–130k args (node v20) → 500 on that request. **External residual is EXPLICIT and pending:** submitted Claim 16 (OpenAlex honors `per_page` / 200-ceiling) is **Unverifiable — pending execution verification** (live API unreachable in-sandbox); it is **not** certified and the arithmetic is **not** attested unconditionally safe. Fix: `.slice(0, PER_QUERY_RESULTS)` at `:126` and/or replace the spread with `reduce` (no arg-count ceiling). | Security | Medium (Confidence Low) | Security (Medium) + Performance (Low); external bound = submitted Claim 16 Unverifiable-pending | for-author | — | 🟡 Open | — |
| pf-A4 | **False "complete" contract shared by 4 panels; fix is a per-field spot-patch.** All four artifact panels bind to the same falsely-typed seam; `between[0]` is one instance of the class — any panel dereferencing a required nested field (`.synthesis.equilibrium`, edges, params) without a guard is exposed to the identical whole-tree crash. Only `BalancedPerspectivesPanel` was patched; three siblings remain latent. Change-propagation cost is structural. Convergence with pf-R1 (same seam). | Architecture (Coupling) | Coupling | Architecture (Coupling) | for-author | — | 🟡 Open | — |
| pf-A3 | **Two byte-identical merge utilities each claim to be "the" shared one.** `mergeStreamingPreview` (function) and `useStreamingMerge` (hook name, calls no hooks) are line-for-line identical; three panels use the hook, one the function. Two sources of truth for one cross-cutting concern — directly obstructs the pf-R1 seam repair (any honest-typing fix must be applied twice or the copies drift). Fix: collapse to one utility, repoint panels. | Architecture (Coupling) | Coupling | Architecture (Coupling) | for-author | — | 🟡 Open | — |
| pf-A6 | **Commit `c0e0a35` message calls the `between` fix "optional chaining."** Mostly accurate (FC Claim 13): the added guard and the sibling field guards are `&&` truthiness guards, not `?.`; the practical conclusion (consistent with the file's defensive pattern) is correct, only the construct is mislabeled. Wording nit; branch is pre-merge so editable. | Fact-check | Mostly Accurate | Fact-check (Claim 13) | for-author | — | 🟡 Open | Reword to "presence guards (`&&`)". |

---

## 🟢 Consider

Advisory findings from contextual critics and single-critic suggestions. Not required to pass review.

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| pf-C1 | `between` guard tests array-presence, not element count — a truthy `[]` or `["A"]` mid-stream renders a dangling `↔` glyph pointing at nothing / one missing pole. Transient, self-healing, but semantically wrong during the stream. Fix: `t.between?.length === 2 &&`. (Mechanism intact.) | ui-visual (Minor) | Minor | for-author | — | 🟢 Open |
| pf-C2 | A tension whose `between` and `description` are both still streaming renders an empty red-bordered box (info-free padding). Fix: gate the description `<p>` on `t.description`. (Mechanism intact.) | ui-visual (Minor) | Minor | for-author | — | 🟢 Open |
| pf-C3 | Relevance stage makes three passes over `allWorks` (`.map` for `Math.max`, `.filter`, `.map`). Trivially cheap at N≤25 and network-dominated; folds to two for free if the pf-A5 `reduce` is adopted. | performance (Informational) | Informational | for-author | — | 🟢 Open |
| pf-C4 | `allowUnsafeEval` introduces a new `allow*` boolean prefix; fits the existing `skip*`/`force*` imperative-toggle micro-family and mirrors the CSP token it controls. Keep; note the family now has three verbs. | api-consistency (Informational) | Informational | for-author | — | 🟢 Open |

---

## ↩️ Considered Overrides

No prior overrides matched this diff.

---

## ✅ Confirmed Good

Patterns/claims confirmed correct. Every row carries grounded `Evidence` and has passed the Confirmed-Good cross-check (provenance rule 5: executed verdict, or static `Verified` whose `Scope:` covers the row's full breadth). Submitted Claim 16 (Unverifiable) backs **no** row here.

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| The `{t.between && …}` guard prevents a streamed tension with an **absent** `between` tuple from throwing `TypeError: Cannot read properties of undefined (reading '0')` during render (crash-prevention only; malformed-but-truthy shapes are out of scope — see pf-C1). | ✅ Confirmed | `BalancedPerspectivesPanel.tsx:113-119` — `{t.between && (…<span>{t.between[0]}</span>…)}`; guard removed → crash test fails with the exact TypeError, restored via `git checkout`. `FC Claim 11 (executed, k=2)`; `submitted Claim 14 (executed)`. | code-fact-check | for-orchestrator-synthesis |
| When granted, `'unsafe-eval'` is appended **only** to `script-src` and appears **exactly once** — it does not leak into `default-src` or other directives (directive-scoping fact only; **not** an endorsement of the eval *policy*, which is pf-A1). | ✅ Confirmed | `proxy.ts:30-32` — token appended solely into the `scriptSrc` template literal; executed sweep across NODE_ENV values shows one occurrence, script-src-scoped; `proxy.test.ts` asserts `devCsp.match(/'unsafe-eval'/g)` length 1. `FC Claim 1 (executed, k=2)`; `submitted Claim 15 (executed)`. | code-fact-check | for-orchestrator-synthesis |
| Evidence-store persistence coalesces rapid writes through a 300 ms debounced `setItem` adapter, wired into the persist middleware via `createJSONStorage(() => debouncedStorage)`. | ✅ Confirmed | `evidenceStore.ts:24-33` (300 ms `setTimeout` coalescing), `:355-357` (wiring). `FC Claim 7 (static; Scope covers the adapter's existence + wiring)`. | code-fact-check | for-orchestrator-synthesis |
| `form-action 'self'` is emitted explicitly rather than relying on a `default-src` fallback (correct for CSP3, where `form-action` does not fall back). | ✅ Confirmed | `proxy.ts:43-44` — `// form-action does NOT fall back to default-src (CSP3); set explicitly.` / `"form-action 'self'"`. `FC Claim 3 (static; Scope covers directive presence + CSP3 fallback)`. | code-fact-check | for-orchestrator-synthesis |
| The committed test pins the production (eval-free) CSP explicitly via `buildCsp(NONCE, false)`, decoupling the "no eval/wildcard/http" assertions from the runner's ambient `NODE_ENV`. | ✅ Confirmed | `proxy.test.ts:12` — `const csp = buildCsp(NONCE, false);`; explicit arg overrides the env-derived default. `FC Claim 4 (static; Scope covers the explicit-arg decoupling; does not cover the default branch — see pf-A2)`. | code-fact-check | for-orchestrator-synthesis |

---

## ⚠️ Unverified Findings

All findings' evidence resolved.

---

## ⏭️ Skipped Core Critics

All core critics ran; no skips applied.

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or carry an author note. 🟢 items are optional.

**Recommended next action: block on architectural review.** (Next-action rule 1: architecture-review produced ≥1 🔴 Structural finding — pf-R1 is a seam-level design question, not a line fix; address it in a design pass before iterating.)
