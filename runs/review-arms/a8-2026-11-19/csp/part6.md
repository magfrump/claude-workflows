
## Stage-1 merged fact-check summary (k=3, most-severe-wins; full report has 18 claims, only non-Verified rows shown)

Full merged report: /workspace/.claude/wt-2026-11-19-a8-token-measurement/runs/review-arms/a8-2026-11-19/csp/code-fact-check-report.md (replicates r1-r3 beside it; r3 ran `next build`/`next start` in its own copy, logs in `fc-r3-logs/`).

Incorrect:
- Claim 2 (`app/layout.tsx:26-28`): dynamic rendering does not make the proxy run (the matcher does); it makes the HTML carry a fresh nonce. 3/3 replicates.
- Claim 3 (`app/layout.tsx:28-30`): Next reads the script nonce from the request CSP header, not the response one; the proxy sets CSP only on the response. r1+r2 static: Next gets no nonce, 'strict-dynamic' blocks every script. r3 executed: on `next start` 15/15 scripts carry the nonce because the router copies proxy response headers onto `req.headers` (`next/dist/server/lib/router-utils/resolve-routes.js:443-446`); Vercel unconfirmed.
- Claim 6 (`proxy.ts:12-14`): Tailwind v4 ships an external stylesheet; 'unsafe-inline' is needed for React `style={{}}` props, KaTeX and React Flow, not Tailwind. 3/3.
- Claim 8 (`proxy.ts:16,26`): `connect-src 'self'` blocks `fetch(dataUrl)` at `app/lib/utils/exportGraph.ts:24,37`; graph PNG export and Export All break with only a console.error (`GraphPanel.tsx:98-110`). 3/3.
- Claim 9 (`proxy.ts:35-36`): the Next 16 proxy runs on Node.js, not Edge. 3/3.
- Claim 11 (`proxy.ts:39-42`): nothing reads `x-nonce`; no `<Script>` exists. 
- Claim 13 (9b4e453 body): "Next applies the nonce to every script" contradicted statically by r2; r3 executed: holds on self-hosted `next start` for `/`.

Mostly accurate:
- Claim 7 (`proxy.ts:16-17`): OpenAlex has no code in the repo.
- Claim 12 (`proxy.ts:52-62`): `public/` files and non-prefetch RSC navigations still pass the matcher; `(?!api` also skips paths like `/apiary`.
- Claim 14 (9b4e453 body): KaTeX trust:false is the default, not configured.

Unverifiable: Claim 16 (lint/221 tests: r3 ran them, 221 pass, no test touches proxy.ts), Claim 17, Claim 18.

Verified with a caveat: Claim 5 (`proxy.ts:7-10`, strict-dynamic semantics) — r3: "script-src with 'strict-dynamic' is the worker-src fallback and ignores 'self', so the pdf.js worker (`fileExtraction.ts:26-29`, `pdfPropositionParser.ts:443-446`) may be blocked".

### Escalations (routing contract)
- E1 `proxy.ts:41-48` — CSP never set on forwarded request headers; nonce reaches Next only through the router's header copy (self-hosted), Vercel unconfirmed. Addressee: security-reviewer, architecture-review.
- E2 `app/lib/utils/exportGraph.ts:24,37` / `proxy.ts:26` — connect-src 'self' breaks graph PNG and Export All. Addressee: security-reviewer.
- E3 `fileExtraction.ts:26-29`, `pdfPropositionParser.ts:443-446` — pdf.js worker may be blocked (no worker-src). Addressee: security-reviewer.
- E4 `proxy.ts:16` — OpenAlex named with no code. Addressee: orchestrator.
