# Review pass: shared context (identical for every agent in this pass)

User goal: A full code review (terminal pass, not a loop pass) of the change d86d2dc..d90d6bb in the meta-formalism-copilot repository, so the owner learns what is wrong with it before it ships.

The reviewed state is checked out at /tmp/claude-1000/-workspace/42e4626f-a408-4056-99e9-68895fd49c97/scratchpad/2026-11-19-a8-settling-runs/wt-csp (detached HEAD d90d6bb). Run git commands there (for example `git -C <that path> diff d86d2dc..d90d6bb`). Do not modify, commit or check out anything in that worktree; it is read-only for you. You may read any file in it, including files outside the diff (consumers, callers, config).

Rules for this pass:
- Complete-unit reading rule: before verdicting a claim or filing a finding about code inside a function or method, read the entire enclosing unit, signature to final line, explicitly including the lines after the last line the finding cites, plus the flow of any value the analyzed lines produce to its first point of use. Any quoted excerpt that ends inside its enclosing unit must carry a truncation marker naming the remainder (for example `excerpt ends :99; enclosing getClient() continues to :108 — read`).
- Probe-cleanup rule: any process you start (a sleep, a FIFO reader, a background script, a dev server) runs under `timeout` and is killed before you report. Do not install packages or use the network.

Scope: the full change d86d2dc..d90d6bb (3 commits, 2 files). The whole changeset is under review; no sibling work outside the scope.

## What this PR is trying to accomplish

Adds a strict Content-Security-Policy with per-request nonces via a Next.js 16 proxy (proxy.ts) as an XSS guardrail, and makes the root layout dynamic so the proxy runs on every request. Commits: "feat: add strict CSP with per-request nonces", "fix: correct layout comment to reference proxy.ts (renamed from middleware.ts)", "refactor: minor cleanup of CSP proxy and layout comment".

Commit message of 9b4e453 (verbatim body):

> The XSS surface in the app is already defensive (no dangerouslySetInnerHTML, no rehype-raw, KaTeX trust:false), so this is a guardrail, not a fix. CSP catches the regression where someone later adds rehype-raw for "render the LLM markdown more faithfully" and forgets that LLM output is user-derived.
>
> Implementation notes:
> - File is named proxy.ts because Next.js 16 renamed Middleware to Proxy (middleware.ts builds with a deprecation warning).
> - The matcher skips /api routes, _next/static, and prefetches so we don't burn nonces on requests that don't render HTML.
> - Layout reads headers() to opt out of static rendering — required because per-request nonces can't be cached.
> - style-src keeps 'unsafe-inline' as a deliberate carve-out for Tailwind v4. Documented in proxy.ts; tightening would require reworking how Tailwind ships styles in dev/SSR.
> - connect-src is just 'self' because all external API calls (Anthropic, OpenAlex, OpenRouter) go server-to-server, never browser-to-third-party.
>
> Verified prod build emits the CSP header and Next applies the nonce to every <script> tag it generates. Manual end-to-end browser verification on the Vercel preview is still recommended — CSP issues sometimes only appear once Next's full bootstrap is exercised.

Commit message of d90d6bb (verbatim body):

> - proxy.ts: add explicit return type, inline single-use csp local.
> - layout.tsx: correct comment — headers() is called to opt out of static rendering so the proxy can attach per-request CSP, not to read x-nonce (the nonce is only written, never read by the layout).
>
> No behavior change; CSP directives preserved exactly. Lint clean; 221/221 tests pass.

## Review material (self-read delivery: the diff and files are not inlined)

The diff and the files it touches are not pasted into this prompt. Before anything else, read them yourself:

- The diff: run `git -C /tmp/claude-1000/-workspace/42e4626f-a408-4056-99e9-68895fd49c97/scratchpad/2026-11-19-a8-settling-runs/wt-csp diff d86d2dc..d90d6bb` (2 files: `proxy.ts`, new; `app/layout.tsx`, modified).
- The enclosing files, in full, at their post-change state: `/tmp/claude-1000/-workspace/42e4626f-a408-4056-99e9-68895fd49c97/scratchpad/2026-11-19-a8-settling-runs/wt-csp/proxy.ts` and `/tmp/claude-1000/-workspace/42e4626f-a408-4056-99e9-68895fd49c97/scratchpad/2026-11-19-a8-settling-runs/wt-csp/app/layout.tsx`.

Read any further file you need on demand (consumers, callers, config, framework code under `node_modules` if present).

## Stage-1 merged fact-check summary (k=3, most-severe-wins; full report has 24 claims, only non-Verified rows shown)

Full merged report: /workspace/.worktrees/wt-2026-11-19-a8-settling-runs/runs/review-arms/a8-2026-11-20/csp/code-fact-check-report.md (replicates r1-r3 beside it). All verdicts static except r2's vitest/eslint run; no replicate could run `next build` (no network for `next/font/google`).

Incorrect:
- Claim 2 (`app/layout.tsx:27-28`): the proxy runs on every matched request whether or not the page is static; dynamic rendering is needed so the HTML carries the per-request nonce. 3/3.
- Claim 3 (`app/layout.tsx:28-30`): Next reads the script nonce from the request CSP header (`app-render.js:166-167`), not the response one; the proxy sets CSP only on the response. r1+r3: Next gets no nonce, 'strict-dynamic' blocks every bootstrap script. r2 (Mostly accurate): on `next start` the router copies proxy response headers onto `req.headers` (`next/dist/server/lib/router-utils/resolve-routes.js:442-443`), so it works there; Vercel unconfirmed.
- Claim 4 (`app/layout.tsx:30`): true as written (the layout never reads x-nonce); Incorrect only through r3's compound verdict with Claim 3.
- Claim 6 (`proxy.ts:7-10`): strict-dynamic semantics are right, but the premise that Next tags its scripts fails for this proxy (r3; same mechanism as Claim 3).
- Claim 7 (`proxy.ts:12-14`): Tailwind v4 ships an external stylesheet; 'unsafe-inline' is needed for ~30 React `style={}` props, KaTeX and React Flow. 3/3.
- Claim 10 (`proxy.ts:16,26`): `connect-src 'self'` blocks `fetch(dataUrl)` at `app/lib/utils/exportGraph.ts:24,37`; graph PNG export and export-all break with only a console.error. 3/3.
- Claim 11 (`proxy.ts:35-36`): the Next 16 proxy runs on Node.js, not Edge. 3/3.
- Claim 18 (9b4e453 body): repeats the Tailwind and connect-src reasons.
- Claim 19 (9b4e453 body): "Next applies the nonce to every script" — r3 Incorrect from the render path; r1/r2 Unverifiable.
- Claim 20 (d90d6bb body): "headers() ... so the proxy can attach per-request CSP" — same wrong mechanism as Claim 2; it replaced 9b4e453's correct reason. 3/3.

Mostly accurate:
- Claim 9 (`proxy.ts:16`): OpenAlex has no code at d90d6bb (only on an unmerged branch).
- Claim 13 (`proxy.ts:39-42`): x-nonce is forwarded but nothing reads it; no `<Script>` in app/.
- Claim 14 (`proxy.ts:52-62`): `(?!api` has no trailing slash, so any path starting with "api" is skipped; public/ SVGs and non-prefetch RSC requests still run the proxy.

Unverifiable: Claim 16 (deprecation warning; no build), Claim 23 (lint/221 tests: r2 executed vitest 221/221 and eslint exit 0), Claim 24 (Vercel preview).

### Escalations (routing contract)
- E1 `proxy.ts:41-48` — CSP never set on forwarded request headers; nonce reaches Next only through the router's header copy (self-hosted), Vercel unconfirmed. Addressee: security-reviewer, architecture-review.
- E2 `app/lib/utils/exportGraph.ts:24,37` / `proxy.ts:26` — connect-src 'self' breaks graph PNG and export-all. Addressee: security-reviewer.
- E3 `app/lib/utils/fileExtraction.ts:26`, `app/lib/utils/pdfPropositionParser.ts:443` — pdf.js worker may be blocked (no worker-src); unchecked. Addressee: security-reviewer.
- E4 `proxy.ts:20-30` — no dev-only 'unsafe-eval' in script-src (Next guide `content-security-policy.md:42`). Addressee: security-reviewer.
- E5 `proxy.ts:52-62` — unanchored `(?!api` lookahead: future pages under paths starting with "api" get no CSP. Addressee: security-reviewer.
- E6 no tests cover `proxy.ts`. Addressee: test-strategy.

