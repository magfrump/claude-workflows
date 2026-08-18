# Code Fact-Check Report — Submitted Claims (Stage 2.5)

**Repository:** /workspace/external/cc-review-eval/mfc-postfix (meta-formalism-copilot)
**Commit:** 7f30210
**Scope:** Endorsement claims routed by Stage-2 critics (`route: code-fact-check` / `[unverified — submitted as claim]`) — 3 total: 2 from security-review.md, 1 from performance-review.md. api-consistency-review.md, architecture-review.md, and ui-visual-review.md carried no routing tags.
**Checked:** 2026-08-18
**Total claims checked:** 3
**Summary:** 2 verified, 0 mostly accurate, 0 stale, 0 incorrect, 1 unverifiable

Merge note: k=1 by design (Stage 2.5 — these claims were authored by named critics, not sampled from prose, so Stage 1's verdict-stability rationale does not transfer). The two security claims are backed by *already-executed* Stage-1 merged verdicts (Claims 1 and 11, both executed k=2); no re-execution was performed — the verdicts below cite those executions with wording-coverage checks. The OpenAlex claim is an external-service assertion, not executable in-sandbox, and is verdicted Unverifiable; static grounding captured to `./evidence/sc-openalex-perpage-static.txt`.

---

## Submitted Claims

## Claim 14: "The added `t.between &&` presence guard prevents a streamed tension whose `between` tuple is absent from throwing `TypeError: Cannot read properties of undefined (reading '0')` during render."

**Submitted by:** security-reviewer
**Location:** `app/components/panels/BalancedPerspectivesPanel.tsx:113-119`
**Type:** Error-handling / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that indexing `t.between[0]` when `between` is undefined throws the named TypeError and that the shipped `{t.between && …}` guard prevents the crash — established by executed reproduction; does NOT establish behavior when `between` is present-but-malformed (`[]`, `{}`, truthy scalar), which the guard tests by presence not shape (the critic's own "Not verified" hop).

This submitted claim is covered verbatim by the executed Stage-1 merged verdict **Claim 11** (Verified, executed, replicate verdicts r1=Verified · r2=Verified). Wording-coverage check: the submitted assertion names (a) the `t.between &&` presence guard, (b) an absent `between` tuple, (c) the exact string `TypeError: Cannot read properties of undefined (reading '0')`, and (d) prevention during render. Claim 11's scope and evidence cover each: r1 removed the guard and observed the "does not crash" test fail with `AssertionError: expected [Function] to not throw … 'TypeError: Cannot read properties of undefined (reading '0')' was thrown`, then restored via `git checkout`; r2 independently reproduced the TypeError and confirmed the guarded suite passes, and found zero error boundaries (`componentDidCatch|ErrorBoundary|getDerivedStateFromError` across `app/`) so an uncaught throw unmounts the tree.

```tsx
// BalancedPerspectivesPanel.tsx:113-119 (paraphrased evidence quoted in Claim 11)
{t.between && (
  <span>{t.between[0]}</span> … <span>{t.between[1]}</span>
)}
```

The exact TypeError string in the submitted claim matches the executed observation character-for-character, so the endorsement is fully within Claim 11's executed scope. The malformed-but-truthy `between` shape is outside both Claim 11's scope and this endorsement's claim, and is correctly carried as the critic's "Not verified" hop.

**Evidence:** merged `code-fact-check-report.md` Claim 11 (executed, k=2); `app/components/panels/BalancedPerspectivesPanel.tsx:113-119`; Claim 11 evidence files `./evidence/r1-balanced-test.txt`, `./evidence/r1-regression-noguard.txt`, `./evidence/r2-between-index-typeerror.txt`, `./evidence/r2-committed-tests.txt`

---

## Claim 15: "`'unsafe-eval'`, when granted, is appended only to the `script-src` directive and appears exactly once — it does not leak into `default-src` or other directives."

**Submitted by:** security-reviewer
**Location:** `proxy.ts:30-32`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the directive-scoping and single-occurrence of `'unsafe-eval'` within `buildCsp`'s constructed string output when granted — established by executed sweep; does NOT establish the composed multi-directive header as actually emitted by `proxy()` on a live response (`proxy.ts:61,66`), and is the directive-scoping fact ONLY, not an endorsement of the eval *policy* (the critic deliberately withheld that guardrail from endorsement per move #11).

This submitted claim is covered by the executed Stage-1 merged verdict **Claim 1** (Verified, executed, replicate verdicts r1=Verified · r2=Verified). Wording-coverage check: the submitted assertion names (a) `'unsafe-eval'` appended only to `script-src`, (b) appearing exactly once, and (c) no leakage into `default-src`/other directives. Claim 1's executed sweep recorded that `test`, `development`, `staging`, and `undefined` each "append it exactly once (scoped to `script-src`)" — covering (a) and (b) directly. For (c): the construction appends the token solely into the `scriptSrc` template literal —

```ts
// proxy.ts:30-32 (quoted in Claim 1)
const scriptSrc = `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'${
  allowUnsafeEval ? " 'unsafe-eval'" : ""
}`;
```

— so the token cannot reach `default-src` or any other directive, and the security critic's own reproduction (`evidence/sec-buildcsp-nodeenv.txt`) plus the committed `proxy.test.ts` assertion `devCsp.match(/'unsafe-eval'/g)` length 1 corroborate the single-occurrence, script-src-only placement. The one hop outside scope — the header as served by `proxy()` at `proxy.ts:61,66` — is named in both Claim 1's scope boundary and the critic's "Not verified" line, and is preserved here rather than laundered into the endorsement.

**Evidence:** merged `code-fact-check-report.md` Claim 1 (executed, k=2); `proxy.ts:26-32`; Claim 1 evidence files `./evidence/r1-buildcsp-nodeenv.txt`, `./evidence/r2-buildcsp-env-default.txt`; corroborating `evidence/sec-buildcsp-nodeenv.txt`

---

## Claim 16: "OpenAlex honors the `per_page=5` request parameter and never returns more than its documented `per_page` ceiling (200) results in a single `data.results` array, so `allWorks.length` cannot exceed 1000 even if the requested `per_page` were disregarded."

**Submitted by:** performance-reviewer
**Location:** `app/api/evidence-search/route.ts:126` (`return (data.results ?? []) as OpenAlexWork[]`), `:181` (spread)
**Type:** Behavioral (external-service contract)
**Verdict:** Unverifiable
**Confidence:** High
**Verification mode:** static
**Scope:** Establishes statically that the code requests `per_page=5` and does NOT slice `data.results` before spreading, so the argument-count bound depends entirely on OpenAlex server-side behavior; does NOT — and cannot in-sandbox — establish that OpenAlex honors `per_page` or caps a single response at 200, which is the submitted claim's actual assertion.

This is an **external-service assertion** and is **not executable in-sandbox**. Confirming that OpenAlex honors `per_page=5` and never exceeds its documented 200-result ceiling requires the live OpenAlex API and its runtime response behavior — neither reachable from the review sandbox. Per the code-fact-check mandatory-execution rule, an executable/observable guarantee that cannot be run stays capped at **Unverifiable**, with the blocker named: **live OpenAlex API responses are not reachable in-sandbox**. Static reading cannot promote this to Verified.

What IS establishable statically (and only this) — grounded in `./evidence/sc-openalex-perpage-static.txt`:

```ts
// app/api/evidence-search/route.ts
const PER_QUERY_RESULTS = 5;                                    // :20
url.searchParams.set("per_page", String(PER_QUERY_RESULTS));   // :114  — request sends per_page=5
return (data.results ?? []) as OpenAlexWork[];                  // :126  — NO slice of the response array
const topScore = Math.max(...allWorks.map((w) => w.relevance_score ?? 0), 1); // :181 — spread
```

The code passes `per_page=5` and does **not** clamp or slice `data.results` before concatenating into `allWorks` and spreading it into `Math.max`. Therefore the argument-count bound on the spread depends **entirely** on OpenAlex's server-side behavior — exactly the boundary Stage-1 Claim 6's Scope explicitly left open ("does NOT establish behavior if the upstream OpenAlex API returns more results than the `per_page` parameter requested (external service behavior, not executable here)"). The submitted claim asks to close that boundary with an external-service guarantee, which cannot be established here.

This Unverifiable-pending outcome is the correct result and demonstrates the exact difference from a run that would falsely attest the spread's arithmetic as unconditionally safe: the local code establishes only the *code-controlled* side of the bound; the *external* side stays open. The claim is **not** promotable to a Confirmed-Good / ✅ row — it surfaces as *pending execution verification* wherever the spread's safety would otherwise be cited.

**Evidence:** `app/api/evidence-search/route.ts:20`, `:114`, `:126`, `:181`; merged `code-fact-check-report.md` Claim 6 (Verified, static — code-controlled bound only, external side excluded by Scope); `./evidence/sc-openalex-perpage-static.txt`

---

## Claims Requiring Attention

### Unverifiable
- **Claim 16** (`app/api/evidence-search/route.ts:126,181`): OpenAlex `per_page`-honoring / 200-ceiling guarantee is an external-service contract not reachable in-sandbox. Would need live OpenAlex API responses to verify. Stays Unverifiable-pending; not promotable to a Confirmed-Good row. Statically established only that the code sends `per_page=5` and does not slice `data.results`, so the spread's bound rests entirely on OpenAlex's server-side behavior.
