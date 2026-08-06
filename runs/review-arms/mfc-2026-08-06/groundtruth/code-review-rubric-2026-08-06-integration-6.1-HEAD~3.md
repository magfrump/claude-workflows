# Code Review Rubric

**Scope:** HEAD~3..HEAD on integration/6.1 (4d5f743, 2e23824, c0e0a35, merge 7f30210) in meta-formalism-copilot | **Reviewed:** 2026-08-06 | **Commit:** 7f30210 | **Status: 🔴 DOES NOT PASS** — 1 red item unresolved

Pipeline: code-fact-check (k=3, merged most-severe-wins, 85% verdict agreement) + security + performance + api-consistency + architecture-review + ui-visual-review (advisory). test-strategy skipped (tests ship with both code changes); dependency-upgrade skipped (no manifest change); tech-debt-triage skipped (small diff). Ground-truth measurement run — all severities retained.

---

## 🔴 Must Fix

| # | Finding | Domain | Severity | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|
| R1 | `mergeStreamingPreview<T>` returns the *complete* type `T` for values that on the streaming path are partial-JSON parses; four panels bind to it, the `between` contract disagrees three ways (JSON Schema unbounded array / TS fixed 2-tuple / renderer indices 0-1), and the new test can only construct real streaming input via `as unknown as Tension`. The shipped guard is correct but patches one symptom of this seam; the next partial-field crash is latent in the other three panels. | Architecture (Structural) | Structural | `app/lib/utils/mergeStreamingPreview.ts:8-16`, `app/lib/types/artifacts.ts:100` | for-author | — | 🔴 Unresolved (fix is a follow-up outside this range: `DeepPartial` streaming type + schema `minItems`/`maxItems`) |

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | `allowUnsafeEval` defaults fail-open: `NODE_ENV !== "production"` grants `'unsafe-eval'` to unset/"test"/"staging"/custom envs; the repo's own precedent has the safe polarity (`corpus/flag.ts:21` returns false unless explicitly dev). Convergence: security + api-consistency + architecture + fact-check C16 (Mostly accurate). | Security | Medium | security F1 + api F1 + arch A2 + fact-check | for-author | — | 🟡 Open | — |
| A2 | The default call path is now untested: tests pin `buildCsp(NONCE, false)`/`(NONCE, true)`, so the default expression at `proxy.ts:28` — the thing production actually runs via `proxy.ts:53` — is exercised by zero tests. Convergence: security + api-consistency. | Security / Testing | Medium | security F2 + api F6 | for-author | — | 🟡 Open | — |
| A3 | The eval-policy decision is caller-selectable: `allowUnsafeEval` is an exported overridable parameter, so "dev-only" is enforced only by there being a single call site — a future `buildCsp(nonce, true)` ships `'unsafe-eval'` silently. Security implication tagged by architecture (relocating the decision moves a trust-boundary control). | Architecture (Coupling) | Coupling | arch A3 + security F3 + fact-check escalation | for-author | — | 🟡 Open | — |
| A4 | `process.env.NODE_ENV` read in a default parameter pulls ambient process state into a previously pure formatter; all six pre-existing default params in the repo are literal constants or injectable seams. Fix is one line: evaluate in `proxy()` and pass explicitly. | Architecture (Coupling) / API | Coupling / Inconsistent | arch A2 + api F2 | for-author | — | 🟡 Open | — |
| A5 | The rewritten spread-bound comment's guarantee rests on OpenAlex honoring `per_page=5`: `data.results` is used without defensive truncation (`route.ts:126`), so a misbehaving/changed API response turns `Math.max(...allWorks)` (`route.ts:181`) into a RangeError cliff. Preventive `.slice(0, PER_QUERY_RESULTS)` at the boundary. Convergence: performance + security F5 + fact-check C1 note. | Performance | Medium | performance 1 + security F5 | for-author | — | 🟡 Open | — |
| A6 | The guard tests array *presence*, not element presence: a one-element `between` (confirmed-reachable partial-parse state) renders a dangling `A ↔` row; `between[1]` is indexed unconditionally. In-range hardening: `t.between?.length >= 2` (schema fix belongs to R1). Convergence: ui-visual F2 + api F3/F8 + security F7. | Correctness / API | Inconsistent | api F3/F4 + ui F2 + security F7 | for-author | — | 🟡 Open | — |
| A7 | connect-src docstring's "not browser-to-third-party" enumeration omits the DD-009 corpus git worker (`gitWorker.ts:33` `isomorphic-git/http/web`; `gitCore.ts:203-218` push/pull to user-configured remotes) — dev-flag-gated today, silently drifts when S4/S5 ships. | Fact-check (Mostly Accurate) | Contested-adjacent (MA) | fact-check C6 + security F8 | for-author | — | 🟡 Open | — |
| A8 | Comment-accuracy residue: the parity claim 4d5f743 set out to drop survives verbatim at `evidenceStore.ts:17` (and is the drifted one — workspaceStore's adapter moved to `corpus/storeAdapter.ts`); c0e0a35's "optional chaining" characterization is wrong (guard is a `&&` conditional render; other streamed leaves unguarded). | Fact-check (Mostly Accurate) | MA | fact-check C12/C18 + api F7 + arch A5 | for-author | — | 🟡 Open | — |

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | Tension arrow `↔` is `text-red-400` on `bg-red-50` = 2.53:1 contrast, failing WCAG 1.4.3/1.4.11 for the row's only relationship indicator. Inherited styling this diff re-emits rather than introduces (ui-visual escalated the counting question; advisory tier per contextual-critic rule). | ui-visual F1 | Major (advisory) | for-author | — | 🟢 Open |
| C2 | Endpoints flex row lacks `flex-wrap`/`min-w-0`; a long unbroken LLM label gives the whole panel body a horizontal scrollbar at 360px/split-pane. | ui-visual F3 | Minor | for-author | — | 🟢 Open |
| C3 | `mt-1` on description now unconditional while the row above is conditional → off-center card spacing when the row is suppressed. | ui-visual F4 | Minor | for-author | — | 🟢 Open |
| C4 | Regression test pins only complete/absent states (not F2's partial state); mocking `ArtifactPanelShell` to a bare div discards the scroll chain, so it can't catch C2/C3. | ui-visual F6 | Informational | for-author | — | 🟢 Open |
| C5 | Sanitizer validates shape not content: `,`/`|` in an override query inject extra OpenAlex filter clauses (`route.ts:113`, `querySanitize.ts`). | security F6 | Low | for-author | — | 🟢 Open |
| C6 | Dev environment loses the eval backstop on the surface handling uploads/LLM output; mitigated by no `innerHTML` sinks in `app/` + intact nonce/strict-dynamic. | security F4 | Low | for-orchestrator-synthesis | — | 🟢 Open |
| C7 | Touched evidence-search route remains unauthenticated/unthrottled — consistent with run-your-own-copy model; raises C5/A5 stakes if that changes. | security F9 | Informational | for-orchestrator-synthesis | — | 🟢 Open |
| C8 | `buildCsp` rebuilds a constant 10-directive array + join per navigation; only the nonce varies. Cold-ish path, micro. | performance 2 | Low | for-author | — | 🟢 Open |
| C9 | `NODE_ENV` read per-request via default param; hoistable to module scope without losing test injectability. | performance 3 | Low | for-author | — | 🟢 Open |
| C10 | Index-keyed tension list re-reconciles fully per streaming tick (pre-existing, adjacent). | performance 4 | Informational | for-orchestrator-synthesis | — | 🟢 Open |
| C11 | `allowUnsafeEval` is the only `allow*` boolean among 27 `is*`/`has*` names. | api F5 | Minor | for-author | — | 🟢 Open |
| C12 | `makeData` helper takes a full array where the sibling panel test uses partial-override objects. | api F9 | Informational | for-author | — | 🟢 Open |
| C13 | Positional boolean param is control coupling; switch to options object if a second relaxation appears. | arch A4 | Minor | for-author | — | 🟢 Open |
| C14 | Single shared `pending` timer in the debounced adapter — latent caveat if a second store ever shares it. | performance 6 | Informational | for-orchestrator-synthesis | — | 🟢 Open |

---

## ↩️ Considered Overrides

No prior overrides matched this diff. (The target repo's `docs/reviews/override-log.md` contains no entries.)

---

## ✅ Confirmed Good

All rows passed the Confirmed-Good cross-check against the merged fact-check report and all three per-replicate reports (Commit: 7f30210); universally quantified rows carry their executed enumeration.

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| Spread-bound constants are exactly as documented: `PER_QUERY_RESULTS = 5` (`route.ts:20`), `MAX_OVERRIDE_QUERIES = 5` enforced by `break` (`querySanitize.ts:9,20`), LLM path ≤3 via `slice(0, 3)` (`route.ts:94`) — *narrowed to the constants/caps; the OpenAlex-trust residual is filed as A5, not confirmed here* | ✅ Confirmed | `route.ts:20,94`, `querySanitize.ts:9,20` — quoted in fact-check C1 (3/3 replicates) | fact-check (k=3 unanimous) | for-orchestrator-synthesis |
| The `'unsafe-eval'` scoping invariant is genuinely established by the assertion pair: exact-match on script-src (`proxy.test.ts:41-43`) + global count of 1 (`proxy.test.ts:45`) ⇒ zero occurrences elsewhere | ✅ Confirmed | `proxy.test.ts:36-46` — reasoning replicated 3/3 | fact-check C11 | for-orchestrator-synthesis |
| The crash fix works for the absent-`between` state and the regression test reaches the real crashing path (traced end-to-end incl. `CollapsibleSection` always-render, mocks pass-through; not executed — no node_modules) | ✅ Confirmed | `BalancedPerspectivesPanel.tsx:113-119`, `test.tsx:7-13,46-55`, `CollapsibleSection.tsx:50-51` — fact-check C19 (3/3, Medium confidence) | fact-check + architecture | for-orchestrator-synthesis |
| Debounced-storage comment is accurate: 300 ms trailing debounce on `setItem`, wired via `createJSONStorage(() => debouncedStorage)` | ✅ Confirmed | `evidenceStore.ts:20-41,355-357` — quoted in fact-check C5 (3/3) | fact-check | for-orchestrator-synthesis |
| All client-side fetches *in the default (non-corpus-flagged) app* are same-origin `/api/...` paths — enumeration executed by all 3 replicates (grep of `fetch(`/`WebSocket`/`EventSource`/`XMLHttpRequest`/`sendBeacon` across `app/`, ~25 call sites listed); third-party URLs are server-side only; exports use `createObjectURL`, pdf worker bundled same-origin — *narrowed to exclude the corpus git worker, which is filed as A7* | ✅ Confirmed | fact-check C6 evidence block (r2's full enumeration; `callLlm.ts:7,203`, `exportGraph.ts:6`, `fileExtraction.ts:26-29`) | fact-check (k=3) | for-orchestrator-synthesis |
| Test suite pins both CSP modes explicitly and NODE_ENV-independently (`buildCsp(NONCE, false)`/`(NONCE, true)`) | ✅ Confirmed | `proxy.test.ts:12,37` — fact-check C10/C17 (3/3) — *the untested-default residual is filed as A2, not contradicted: the pinned assertions themselves are sound* | fact-check | for-orchestrator-synthesis |
| Shell layout mechanics correct: docked `WholeTextEditBar` outside the scroll container; `min-h-0`/`flex-1`/`overflow-y-auto` pairing correct; no new absolute positioning | ✅ Confirmed | ui-visual "clean on mechanical items 2-4" with file cites | ui-visual | for-orchestrator-synthesis |

Cross-check note: two candidate ✅ rows were narrowed before publication (spread bound → constants only, A5 carries the residual; connect-src → default-app only, A7 carries the omission). One candidate row ("production output eval-free") was **not published** — fact-check verdict is Unverifiable (C7), and a confirmation that cannot be grounded is not a confirmation.

Soundness-contradiction sweep: no critic report quotes a stated intent verbatim alongside a mechanism that behaviorally defeats it — the closest candidates (fail-open NODE_ENV vs "development only"; presence-vs-element guard vs the commit's crash claim) are precision/robustness gaps, not behavioral inversions of the quoted intent. No lifts.

---

## ⚠️ Unverified Findings

All findings' evidence resolved. (In-diff citations cross-checked against the range diff; out-of-diff citations — `flag.ts:21`, `storeAdapter.ts:33-46`, `gitCore.ts:203-218` — corroborated independently by ≥2 fact-check replicates.)

---

## ⏭️ Skipped Core Critics

All core critics ran; no skips applied. (Contextual: test-strategy skipped — tests ship with both code changes; dependency-upgrade skipped — no manifest change; tech-debt-triage skipped — 6 files / ~110 lines.)

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or carry an author note. 🟢 items are optional.
