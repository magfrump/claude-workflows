Commit: d90d6bb

# Code Review Rubric

**Scope:** `d86d2dc..d90d6bb` (meta-formalism-copilot, csp canon cell; terminal pass, k=3) | **Reviewed:** 2026-11-19 | **Status: 🔴 DOES NOT PASS** — 1 red item(s) unresolved

Synthesized inline by the orchestrator (as in the 2026-08-06 baseline); no rubric agent, so no rubric-stage tokens. Delivery mode: inline (shared block 8,755 bytes ≈ 2.2k tokens for Stage 1, 11,716 bytes ≈ 2.9k tokens for Stage 2, budget 25k). Override log: the reviewed repo has no `docs/reviews/override-log.md`; no prior overrides matched this diff.

---

## 🔴 Must Fix

| # | Finding | Domain | Severity | Source | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|---|
| R1 | `connect-src 'self'` blocks the browser's `fetch(dataUrl)` in the graph export, so "Export .png" and the graph image in Export All fail with only a `console.error`; the docblock's "connect-src 'self' is sufficient" rationale is false | API / Behavior | Breaking (api), Incorrect high behavioral (fc 3/3) | api-consistency-reviewer #1; fact-check Claim 8; architecture #2 (Coupling); security #5 (Info); test-strategy G8 | `proxy.ts:26`, `app/lib/utils/exportGraph.ts:24,37` | for-author | — | 🔴 Unresolved |

Evidence: `"connect-src 'self'",` (`proxy.ts:26`); `const res = await fetch(dataUrl);` (`app/lib/utils/exportGraph.ts:24`).

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|---|
| A1 | CSP is set only on the response; Next reads the nonce from the request CSP header and gets it only through the router's undocumented response-to-request header copy (works on `next start`, unconfirmed on Vercel; if absent, 'strict-dynamic' blocks every script) | Architecture / Security | Coupling (arch), Inconsistent (api), Low (sec), Incorrect medium (fc Claim 3) | architecture #1; api-consistency #3; security #2; fact-check Claim 3, E1; test-strategy G3 | `proxy.ts:41-47` | for-author | — | 🟡 Open |
| A2 | Requests carrying `Purpose: prefetch` are excluded by the matcher and get the full HTML document with no CSP | Security | Medium | security-reviewer #1 | `proxy.ts:52-62` | for-author | — | 🟡 Open |
| A3 | `await headers()` makes `/` (the only page) and the 404 page dynamic: `s-maxage` cache HIT becomes `no-store`, a full render per view | Performance | Medium | performance-reviewer #1 (+ #2 Low) | `app/layout.tsx:22-31` | for-author | — | 🟡 Open |
| A4 | The CSP silently constrains client features with nothing linking them: besides R1, the pdf.js worker may be blocked (no `worker-src`; 'strict-dynamic' ignores 'self'); unconfirmed without a browser | Architecture | Coupling (arch); Breaking Medium-confidence (api, worker half) | architecture #2; api-consistency #1 (worker half); fact-check Claim 5 caveat, E3; security #6; test-strategy G9 | `proxy.ts:19-31`, `app/lib/utils/fileExtraction.ts:26-29` | for-author | — | 🟡 Open |
| A5 | Layout comment: "so proxy.ts runs on every request" — the matcher decides that; dynamic rendering only gives the HTML a fresh nonce; and "nonce from the response's CSP header" is the wrong source | Fact-check (comment) | Incorrect high, comment-only | fact-check Claims 2, 3; architecture #4 (Minor) | `app/layout.tsx:26-30` | for-author | — | 🟡 Open |
| A6 | "the Edge runtime that Next proxy runs in" — the Next 16 proxy runs on Node.js | Fact-check (comment) | Incorrect high, comment-only | fact-check Claim 9 (executed); security #9 | `proxy.ts:35-36` | for-author | — | 🟡 Open |
| A7 | "Tailwind v4 emits inline styles" — Tailwind ships a stylesheet; 'unsafe-inline' is needed for React `style` props, KaTeX, React Flow | Fact-check (comment) | Incorrect high, comment-only | fact-check Claim 6 (executed); security #7 | `proxy.ts:12-14` | for-author | — | 🟡 Open |
| A8 | `x-nonce` is forwarded "so layouts can read it … and pass it to <Script>": nothing reads it, no `<Script>` exists, and the layout comment says the opposite | API / Fact-check | Inconsistent (api), Incorrect high (fc Claim 11) | api-consistency #2; fact-check Claim 11; architecture #3 | `proxy.ts:39-42`, `app/layout.tsx:27-31` | for-author | — | 🟡 Open |
| A9 | Mostly-accurate claims: OpenAlex named with no code (Claim 7); matcher lets `public/` files and RSC navigations through and `(?!api` also skips `/apiary` (Claim 12); KaTeX trust:false is only the default (Claim 14) | Fact-check | Mostly Accurate | fact-check Claims 7, 12, 14; perf #3; arch #5; api #5; sec #8 | `proxy.ts:16-17`, `proxy.ts:57` | for-author | — | 🟡 Open |
| A10 | 9b4e453 body "Next applies the nonce to every <script> tag" — Incorrect (medium) statically, holds on `next start` (r3, executed); a merged commit message cannot be edited | Fact-check (history) | Incorrect medium | fact-check Claim 13 | commit 9b4e453 | for-author | — | Accepted-immutable |

A10 author note: `[auto: code-review]` immutable history (already-merged commit message); recorded here instead of an override-log row, since this run does not write to the reviewed repo.

---

## 🟢 Consider

| # | Finding | Source | Location |
|---|---|---|---|
| C1 | No `form-action`; no `report-to` | security #3 (Low), #4 (Info) | `proxy.ts:20-31` |
| C2 | `next dev` probably needs `'unsafe-eval'`; risk of adding it unconditionally | security #10 (Info, low confidence) | `proxy.ts:22` |
| C3 | Dynamic opt-in via a discarded `await headers()` can be deleted as dead code; prefer `connection()` / `dynamic = "force-dynamic"` | architecture #4; test-strategy G6 | `app/layout.tsx:31` |
| C4 | `proxy.ts` missing from the repo's CLAUDE.md directory layout | api-consistency #4 (Minor) | `CLAUDE.md` |
| C5 | Import/return-type style differs from route handlers | api-consistency #6 (Info) | `proxy.ts:1-2,34` |
| C6 | Test gaps: CSP directive list not pinned (G1), nonce freshness (G2), matcher table (G4, G5), built-app nonce smoke test (G7) | test-strategy (advisory) | `proxy.ts:19-62` |
| C7 | Proxy per-request work is bounded (header copy scales with header count), not strictly constant | performance endorsement, Stage 2.5 Claim 22 (Mostly accurate) | `proxy.ts:34-49` |

---

## ✅ Confirmed Good

| # | Claim | Evidence | Backing |
|---|---|---|---|
| G1 | Each request gets a fresh nonce from `crypto.randomUUID()`, base64-encoded into a valid nonce charset | `const nonce = Buffer.from(crypto.randomUUID()).toString("base64");` (`proxy.ts:37`) | Stage 2.5 Claim 19, executed (3 calls, 3 distinct nonces); scope does not cover CDN reuse |
| G2 | script-src carries no 'unsafe-inline' / 'unsafe-eval'; object-src 'none', base-uri 'self', frame-ancestors 'none' are set | `` `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'`, `` (`proxy.ts:22`) | Stage 2.5 Claim 20, executed |
| G3 | `/api/*` route handlers are excluded from the matcher, so their contracts are unchanged | `source: "/((?!api|_next/static|_next/image|favicon.ico).*)",` (`proxy.ts:57`) | Stage 2.5 Claim 24, executed; scope caveat `/apiary` (A9) |

---

## ⏭️ Skipped Core Critics

None. Contextual critic not selected: ui-visual-review (layout.tsx hunks are header/nonce plumbing; the className line is unchanged context).

---

## 🧩 Composition check

- `proxy.ts:39-48` (fact-check Claims 3, 11; architecture #1, #3; api #2, #3; security #2; test G3): distinct defects — each fragment already states its mechanism and fix (A1, A8).
- `exportGraph.ts:24,37` + `proxy.ts:26` (fact-check Claim 8; api #1; arch #2; sec #5; test G8): distinct defects by construction — one defect, fully stated in R1.
- `proxy.ts:52-62` (fact-check Claim 12; sec #1; perf #3; arch #5; api #5; test G4/G5): distinct defects — prefetch exemption (A2) and prefix match (A9) are separate mechanisms.
