Commit: d90d6bb

# Code review rubric: csp (d86d2dc..d90d6bb), A8 self-read control pass

Status: 2 red, 7 amber. Do not merge. Delivery mode: self-read. Terminal pass: k=3 fact-check, 5 critics in parallel, Stage 2.5 on 7 routed claims. Synthesized inline by the orchestrator (not an agent; not in the token totals). Override log: the reviewed repo has none; no prior overrides matched this diff.

## 🔴 Must Fix

| ID | Finding | Location | Source | Severity |
|---|---|---|---|---|
| R1 | `connect-src 'self'` blocks `fetch(dataUrl)`, so graph PNG export and export-all break, with only a console.error | `proxy.ts:26`; `app/lib/utils/exportGraph.ts:24,37` | api-consistency Breaking (High); fact-check Claim 10 Incorrect 3/3; security Low #4; architecture Coupling #2; test-strategy G7 | Breaking |
| R2 | CSP is set only on the response, while Next reads the nonce from the request CSP header. It works on `next start` only through the router's response-to-request header copy; on a host without it, every script is blocked | `proxy.ts:41-48`; `app/layout.tsx:28-30` | api-consistency Breaking (Medium); security Medium #1; architecture Coupling #1; fact-check Claim 3 (I/MA/I); test-strategy G3/G6 | Breaking |

## 🟡 Must Address

| ID | Finding | Location | Source |
|---|---|---|---|
| A1 | `x-nonce` is forwarded but nothing reads it; the comment describes a `<Script>` contract that does not exist | `proxy.ts:39-42` | fact-check Claim 13 (MA 3/3); api Minor #3; architecture Minor #4 |
| A2 | "proxy runs on every request because of `await headers()`" is the wrong mechanism (the matcher decides); d90d6bb replaced the correct reason with it | `app/layout.tsx:27-28`; d90d6bb body | fact-check Claims 2, 20 (Incorrect 3/3); architecture Minor #3 |
| A3 | `await headers()` drops the static prerender of `/`; the cost is not recorded as weighed | `app/layout.tsx:27-31` | performance Medium #1 |
| A4 | "Tailwind v4 emits inline styles" is the wrong reason for `style-src 'unsafe-inline'` | `proxy.ts:12-14`; 9b4e453 body | fact-check Claims 7, 18 (Incorrect 3/3); api Minor #5 |
| A5 | Comment says the proxy runs in the Edge runtime; Next 16 runs it on Node.js | `proxy.ts:35-36` | fact-check Claim 11 (Incorrect 3/3); api Minor #5 |
| A6 | Matcher: unanchored `(?!api` skips any path starting with "api"; `purpose: prefetch` HTML is served with no CSP | `proxy.ts:52-63` | security Low #3; api Minor #4; architecture Minor #5; fact-check Claim 14 (MA) |
| A7 | 9b4e453's "Next applies the nonce to every script tag" is contradicted by the render path for this proxy | 9b4e453 body | fact-check Claim 19 (r3 Incorrect) |

## 🟢 Consider

- C1 security Low #2: no `form-action` directive.
- C2 security Info #6: no `report-to`.
- C3 security Info #7: no dev-only `'unsafe-eval'`; pdf.js worker under `'strict-dynamic'` with no `worker-src` unchecked (fact-check E3, E4; test-strategy G8, G9).
- C4 test-strategy G1, G2, G4, G5: nothing pins the directive list, nonce freshness, the matcher or the prefetch arms.
- C5 performance Info #2: `public/` files and non-prefetch RSC requests still run the proxy.
- C6 Stage 2.5 Claim 27b: the performance critic's "constant work" endorsement was refuted by execution (cost grows with request header count, about 15 µs at 21 headers). Source: performance endorsement, refuted by fact-check. Doc-class, so 🟢.
- C7 architecture Info #6: CLAUDE.md does not describe `proxy.ts`.

## ✅ Confirmed Good

- Nonce from `crypto.randomUUID`, unique over 20,000 executed calls and accepted by Next's nonce parser (Stage 2.5 Claim 25, executed). Not established: CDN replay of a cached page.
- Router prefetches (`next-router-prefetch`, `purpose: prefetch`) skip the proxy (Claim 28, executed on `next dev`).
- d90d6bb kept the directive block byte-identical (Claim 31, Mostly accurate: the diff also adds a return type).

## ⏭️ Skipped Core Critics

None. ui-visual-review not selected at Step 5 (layout.tsx hunks are header/nonce plumbing; same call as the first pass and the baseline).

## 🧩 Composition check

- `proxy.ts:39-48` cluster (security #1, api #2, architecture #1, fact-check Claims 3/13): distinct defects already stated whole by R2 and A1.
- `proxy.ts:52-63` cluster (security #3, api #4, architecture #5, Claim 14): distinct defects: one regex, each fragment states its own case and fix.

Single-sample review; absence of findings is not an attestation.
