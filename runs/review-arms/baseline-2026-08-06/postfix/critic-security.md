Commit: 7f30210

# Security Review — post-review-fix changeset (9c9edf5..7f30210)

**Scope:** git diff 9c9edf5..7f30210 in worktree wt-postfix (proxy.ts CSP gating, evidence-search comment, BalancedPerspectivesPanel render guard + test, evidenceStore doc comment, proxy.test.ts)
**Date:** 2026-08-06
**Based on:** /workspace/runs/review-arms/baseline-2026-08-06/postfix/fact-check.md (9 claims, 7 verified, 2 unverifiable, 0 incorrect)

This is a post-review-fix state. The changeset is small; three of the six files are pure comment/test changes with no runtime effect. The two runtime-affecting changes are the CSP `allowUnsafeEval` gating (proxy.ts) and the `t.between` render guard (BalancedPerspectivesPanel.tsx).

## Trust Boundary Map

```
B1: [browser HTTP request]        → [proxy() NextResponse]      → [Content-Security-Policy header]   (modified)
B2: [LLM/OpenAlex-streamed JSON]   → [displayMap.tensions map]  → [React text rendering in panel]    (guard added)
B3: [POST body.queries[]]          → [sanitizeQueries()]        → [OpenAlex query + Math.max spread] (comment only)
```

B1 is the load-bearing boundary this diff touches: the CSP header is the browser-side control that constrains what injected script can do. B2 is a client-side render path consuming untrusted (model-generated, partial-JSON-streamed) content. B3 is unchanged at runtime — only its justifying comment was edited; `sanitizeQueries` already bounds the override path to `MAX_OVERRIDE_QUERIES` (5), so the `Math.max(...allWorks)` spread is bounded to ≤25 args (fact-check Claim 1, verified).

## Findings

#### CSP `allowUnsafeEval` default fails open on ambiguous NODE_ENV

**Severity:** Low
**Location:** `proxy.ts:26-32`
**Boundary:** B1
**Move:** #3 (error/edge path), #5 (invert the control — what does the default permit?)
**Confidence:** High (mechanism); Medium (exploitability, depends on deploy config outside the diff)

The gate is `allowUnsafeEval: boolean = process.env.NODE_ENV !== "production"`. This is permissive-by-default for every NODE_ENV value that is not exactly the string `"production"` — unset, empty, `"prod"`, `"staging"`, `"test"`, or a typo all cause `'unsafe-eval'` to be emitted into `script-src`. The default direction is fail-open: a misconfigured or non-Vercel deployment (self-hosted `next start` with NODE_ENV unset, a custom Docker image) would silently ship `'unsafe-eval'` in what is meant to be a production CSP. Evidence, quoted: `allowUnsafeEval: boolean = process.env.NODE_ENV !== "production"` and `${allowUnsafeEval ? " 'unsafe-eval'" : ""}`.

Exploitability is bounded and indirect: `'unsafe-eval'` does not by itself grant script execution — the primary gate is `'nonce-…' 'strict-dynamic'`, and `'strict-dynamic'` does not relax for `'unsafe-eval'`. The incremental risk is defense-in-depth degradation: if an attacker separately achieves nonce-trusted script execution (or an eval-gadget in a trusted script), `'unsafe-eval'` widens what that foothold can do. For the documented single-tenant Vercel deploy model (CLAUDE.md), Vercel sets `NODE_ENV=production` for production builds, so the common path is safe. The residual risk is only the non-Vercel / misconfigured deploy. Note the comment's claim "Production output is genuinely eval-free" is unverifiable from source (fact-check Claim 3) — it is an assertion about Next.js bundler output, not repo code.

**Recommendation:** Prefer explicit opt-in over env-inequality: gate on `process.env.NODE_ENV === "development"` (fail-closed — only the exact dev value enables eval), or thread an explicit build-time flag. At minimum, document the deploy requirement that NODE_ENV be `"production"` for the CSP to harden. **Legibility target:** a reviewer can confirm safety by checking whether every supported deploy path guarantees `NODE_ENV === "production"`; the `!== "production"` phrasing hides that dependency.

#### Optional-chaining guard on streamed tension endpoints (robustness, not a trust flaw)

**Severity:** Informational
**Location:** `app/components/panels/BalancedPerspectivesPanel.tsx:113-120`
**Boundary:** B2
**Move:** #2 (implicit assumption about input shape)
**Confidence:** High

The `{t.between && (…)}` guard prevents a `TypeError` when partial-JSON streaming yields a tension before its `between` tuple arrives (fact-check Claim 6, verified). This is a correctness/availability robustness fix for untrusted model-generated data, and is the right direction. No injection surface: sibling `{t.description}` and the guarded `{t.between[0/1]}` are rendered as React text children, which React escapes by default — no `dangerouslySetInnerHTML` is introduced. Included only to confirm B2 was reviewed and is safe. **Legibility target:** none needed; the inline test regression comment already documents the why.

## What Looks Good

- CSP structure is otherwise strong: per-request 128-bit nonce from `crypto.getRandomValues` (not `Math.random`), `'strict-dynamic'`, `object-src 'none'`, `frame-ancestors 'none'`, `base-uri 'self'`, explicit `form-action 'self'`.
- `'unsafe-eval'` is correctly scoped to `script-src` only and never leaks into other directives (fact-check Claim 9, verified; proxy.test.ts asserts exactly one occurrence).
- proxy.test.ts pins the production CSP with an explicit `buildCsp(NONCE, false)`, decoupling the assertions from the runner's ambient NODE_ENV — good test hygiene that prevents a false-green if the runner sets NODE_ENV to a dev value.
- The evidence-search spread (B3) is bounded by `sanitizeQueries`/`MAX_OVERRIDE_QUERIES`; the edited comment now accurately states the bound. No DoS via unbounded spread.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | CSP `allowUnsafeEval` default fails open on ambiguous NODE_ENV | Low | B1 | `proxy.ts:26-32` | High/Med |
| 2 | Streamed-tension render guard (robustness, safe) | Informational | B2 | `BalancedPerspectivesPanel.tsx:113-120` | High |

## Overall Assessment

Security posture is sound for the documented deploy model. There are no High/Critical findings and nothing warranting escalation. The only substantive observation is that the CSP eval gate defaults permissive whenever NODE_ENV is not the exact string `"production"` — a fail-open direction that is harmless on Vercel (which forces NODE_ENV=production) but could silently ship `'unsafe-eval'` on a misconfigured self-hosted deploy. The single most valuable change is to invert the gate to an explicit `=== "development"` (fail-closed) check; the fix is a one-line, in-place change and does not indicate an architectural problem.
