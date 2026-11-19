Commit: d90d6bb

# Code Fact-Check Report

**Commit:** d90d6bb
**Replication:** k=3
**Repository:** meta-formalism-copilot (scratch worktree wt-csp, detached HEAD d90d6bb)
**Scope:** branch diff d86d2dc..d90d6bb (`app/layout.tsx`, `proxy.ts`) plus the three commit bodies
**Checked:** 2026-11-19
**Total claims checked:** 18
**Summary:** 5 verified, 3 mostly accurate, 0 stale, 7 incorrect, 3 unverifiable

Merged most-severe-wins from `code-fact-check-report-r1.md`, `-r2.md`, `-r3.md` (all `Commit: d90d6bb`) by the orchestrator; mechanical collation only. r1 and r2 ran static only (no `node_modules` in the worktree); r3 copied `node_modules` from `/workspace/external/cc-review-eval/mfc-csp` into its own scratch copy and ran `next build`, `next start`, `vitest` and `eslint` (logs preserved in `fc-r3-logs/`). Several merged verdicts are static Incorrects that r3's executed run contradicts on self-hosted `next start`; most-severe-wins keeps the Incorrect and the executed counter-evidence is carried in the annotations.

---

## Claim 1: "Opt this layout out of static rendering" (`await headers()`; also 9b4e453 body "required because per-request nonces can't be cached")

**Location:** `app/layout.tsx:26-31`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that `await headers()` turns `/` from prerendered-static to dynamic in a `next build` of 16.2.4; does not establish Vercel build behaviour or later routes with their own segment config.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "does not establish behavior under cacheComponents/PPR (not enabled: next.config.ts is empty)" · r2: "does not establish that the dynamic render actually gets a nonce applied to its scripts"
**Legibility-target:** for-orchestrator-synthesis

r3 built with and without `headers()`: without it `/` was prerendered (`fc-r3-logs/build-noheaders.log`).

**Evidence:** `app/layout.tsx:22-43`, `next.config.ts:1-7`, `fc-r3-logs/build.log`, `fc-r3-logs/build-noheaders.log`

---

## Claim 2: "...so proxy.ts runs on every request and can attach a fresh per-request CSP nonce"

**Location:** `app/layout.tsx:26-28`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the stated causal link (dynamic rendering makes the proxy run) on `next start`; does not establish Vercel/CDN behaviour.
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect
**Replicate annotations:** r1+r2+r3: "dynamic rendering is needed so the HTML carries a fresh nonce; the proxy runs for every matched request either way; 9b4e453 stated the right reason and d90d6bb replaced it" · r3: "a static `/` still got a fresh CSP header, with 0/18 scripts nonced" · r3: "does not establish Vercel/CDN behaviour, where a cached static page could also bypass the proxy"
**Legibility-target:** for-author

**Evidence:** `proxy.ts:51-64`, `fc-r3-logs/noheaders-headers.txt`, `fc-r3-logs/noheaders-body.html`

---

## Claim 3: "Next.js automatically tags its own bootstrap <script> elements with the nonce from the response's CSP header, so we don't need to read x-nonce here ourselves."

**Location:** `app/layout.tsx:28-30`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers where Next.js reads its script nonce (the request CSP header) and that this proxy sets CSP only on the response; does not establish runtime behaviour (no browser was run by the winning replicates).
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Verified
**Replicate annotations:** r1+r2: "the proxy sets CSP only on the response and forwards only x-nonce, which Next ignores; under 'strict-dynamic' the unnonced scripts would be blocked and the app would not hydrate" · r3 (executed, contradicts the winning verdict on self-hosted Node): "on `next start` 15 of 15 `<script>` tags carry the response CSP's nonce, because the router copies proxy response headers onto `req.headers` (`next/dist/server/lib/router-utils/resolve-routes.js:443-446`) and the renderer reads the request header (`app-render.js:166-167`)" · r3: "does not establish Vercel's runtime, where response headers might not be mirrored into request headers; there the proxy could leave Next without a nonce" · r2: "framework-internal verdicts rest on Next.js source knowledge, not an installed copy"
**Legibility-target:** for-author

Winning evidence (r1): `requestHeaders.set("x-nonce", nonce);` … `response.headers.set("Content-Security-Policy", buildCsp(nonce));` (`proxy.ts:41-48`). The comment's mechanism ("from the response's CSP header") is wrong either way: Next reads the request header, which here holds the value only through the router copy r3 found.

**Evidence:** `proxy.ts:22`, `proxy.ts:34-49`, `app/layout.tsx:27-31`, `fc-r3-logs/root-headers.txt`, `fc-r3-logs/root-body.html`

---

## Claim 4: "CSP proxy (Next.js 16 renamed Middleware → Proxy)" / "middleware.ts builds with a deprecation warning"

**Location:** `proxy.ts:5`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the file-convention rename and the deprecation warning for `middleware.ts` in next 16.2.4; does not establish other renamed APIs.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `package.json:21`, `proxy.ts:5`, `proxy.ts:34`

---

## Claim 5: "only scripts that Next.js has explicitly tagged with the nonce can run, and any scripts they load inherit trust"

**Location:** `proxy.ts:7-10`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers that the emitted policy is nonce + 'strict-dynamic' and every server-emitted script carries the nonce on `next start`; does not establish that features loading script-like resources outside `<script>` elements still work.
**Replicate verdicts:** r1=Verified · r2=— · r3=Verified
**Replicate annotations:** r3: "'strict-dynamic' makes 'self' ignored and script-src is the fallback for worker-src, so the pdf.js workers loaded via GlobalWorkerOptions.workerSrc may be blocked (`fileExtraction.ts:26-29`, `pdfPropositionParser.ts:443-446`)" · r1: "does not establish that Next.js actually tags its scripts under this proxy, or how workers such as the pdfjs worker are treated"
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `proxy.ts:7-10`, `proxy.ts:19-32`

---

## Claim 6: "Why `style-src 'unsafe-inline'`: Tailwind v4 emits inline styles. Tightening to nonces would require rebuilding how Tailwind ships styles in dev and SSR."

**Location:** `proxy.ts:12-14`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the production HTML contains and where Tailwind's output lands; does not establish dev-mode style injection.
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect
**Replicate annotations:** r1+r2+r3: "'unsafe-inline' is still needed, but for React `style={{}}` props (30-31 sites, e.g. `LatexRenderer.tsx:32`), KaTeX and React Flow, not Tailwind" · r3: "prod build ships external .css via nonced `<link>` tags, no `<style>` tags"
**Legibility-target:** for-author

**Evidence:** `postcss.config.mjs:1-7`, `app/globals.css:1`, `app/components/features/output-editing/LatexRenderer.tsx:32`, `fc-r3-logs/root-body.html`

---

## Claim 7: "Anthropic / OpenAlex / OpenRouter calls are server-to-server (Next API routes), not browser-to-third-party."

**Location:** `proxy.ts:16-17`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the Anthropic and OpenRouter call sites and their importers; does not establish anything about OpenAlex, which has no code in the repo.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Mostly accurate
**Replicate annotations:** r1+r3: "OpenAlex appears nowhere except this comment" · r2: "does not establish that 'self' covers every browser-side fetch (see Claim 8)"
**Legibility-target:** for-author

**Evidence:** `app/lib/llm/callLlm.ts:7`, `app/lib/formalization/api.ts:1-12`

---

## Claim 8: "`connect-src 'self'` is sufficient"

**Location:** `proxy.ts:16`, `proxy.ts:26`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers browser `fetch` calls in client code reachable under this policy; does not establish html-to-image's or pdfjs's internal requests.
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect
**Replicate annotations:** r1+r2+r3: "`fetch(dataUrl)` at `app/lib/utils/exportGraph.ts:24` and `:37`; 'self' never matches `data:`; PNG export and the graph image in Export All break, with only a `console.error` in `GraphPanel.tsx:98-110`" · r3: "not browser-tested"
**Legibility-target:** for-author

```ts
// app/lib/utils/exportGraph.ts:20-26 (r1)
  const dataUrl = await toPng(viewportElement, {
    pixelRatio: 2,
    backgroundColor: EXPORT_BG,
  });
  const res = await fetch(dataUrl);
```

**Evidence:** `proxy.ts:26`, `app/lib/utils/exportGraph.ts:16-39`, `app/lib/utils/exportAll.ts:64`, `app/components/panels/GraphPanel.tsx:98-110`

---

## Claim 9: "the Edge runtime that Next proxy runs in"

**Location:** `proxy.ts:35-36`
**Type:** Configuration
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the runtime next 16.2.4 assigns to `proxy.ts`; does not establish Vercel's hosting placement.
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect
**Replicate annotations:** r3: "`get-page-static-info.js:576`: 'Proxy always runs on Node.js runtime'; built manifest records \"runtime\": \"nodejs\""
**Legibility-target:** for-author

**Evidence:** `proxy.ts:34-37`, `proxy.ts:51-64`, `fc-r3-logs/build.log`

---

## Claim 10: "crypto.randomUUID and Buffer are both available"

**Location:** `proxy.ts:35-37`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers availability in the Node.js runtime the proxy actually uses; does not establish the Edge availability the comment names (moot, Claim 9).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `proxy.ts:37`, `package.json:36`

---

## Claim 11: "Forward the nonce to server components via a request header so layouts can read it via `headers()` and pass it to <Script> tags they render."

**Location:** `proxy.ts:39-42`
**Type:** Architectural
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every reader of `x-nonce` and every `<Script>` in the repo at d90d6bb; does not establish whether a future consumer is planned.
**Replicate verdicts:** r1=Mostly accurate · r2=Incorrect · r3=Mostly accurate
**Replicate annotations:** r1+r2+r3: "nothing reads x-nonce and there are no `<Script>` tags or `next/script` imports" · r2: "the comment contradicts `app/layout.tsx:30`"
**Legibility-target:** for-author

**Evidence:** `proxy.ts:39-46`, `app/layout.tsx:27-31`

---

## Claim 12: "Skip API routes …, Next's static assets …, and prefetches" / "so we don't burn nonces on requests that don't render HTML"

**Location:** `proxy.ts:52-62`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which paths and headers the matcher excludes; does not establish runtime matcher semantics beyond path-to-regexp and `missing`.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: "the `(?!api` lookahead is prefix-based and also skips e.g. `/apiary`" · r1+r2: "`public/` files (file.svg, next.svg, …) and non-prefetch RSC navigations still pass through the proxy" · r3 (executed): "checked `/`, `/api/analytics`, a `/_next/static` chunk, `/favicon.ico`, an unknown page and both prefetch headers (`fc-r3-logs/matcher.txt`)"
**Legibility-target:** for-author

**Evidence:** `proxy.ts:51-64`, `fc-r3-logs/matcher.txt`

---

## Claim 13: "Verified prod build emits the CSP header and Next applies the nonce to every <script> tag it generates." (9b4e453 body)

**Location:** commit 9b4e453 (body)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the nonce-stamping half against the proxy as committed; does not establish what a build printed (no build in the winning replicate).
**Replicate verdicts:** r1=Unverifiable · r2=Incorrect · r3=Verified
**Replicate annotations:** r3 (executed, contradicts the winning verdict on self-hosted Node): "on a self-hosted prod build of `/` (fonts stubbed) every script carried the nonce; does not establish other routes, client-navigation payloads or the Vercel preview" · r1: "needs a build plus browser run; static evidence contradicts the nonce half"
**Legibility-target:** for-author

**Evidence:** `proxy.ts:41-48`, `fc-r3-logs/root-body.html`

---

## Claim 14: "The XSS surface in the app is already defensive (no dangerouslySetInnerHTML, no rehype-raw, KaTeX trust:false)" (9b4e453 body)

**Location:** commit 9b4e453 (body)
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `app/` source outside tests; does not establish dependency internals.
**Replicate verdicts:** r1=Mostly accurate · r2=Unverifiable · r3=Verified
**Replicate annotations:** r1: "KaTeX trust is false only by default; nothing sets it explicitly" · r2: "not checked in depth in this replicate" · r3: "does not establish the absence of other DOM sinks in third-party libraries"
**Legibility-target:** for-author

**Evidence:** `app/components/features/output-editing/LatexRenderer.tsx:1-40`

---

## Claim 15: "No behavior change; CSP directives preserved exactly." (d90d6bb body)

**Location:** commit d90d6bb (body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the full `git diff 9b4e453 d90d6bb`; does not establish that the pre-existing behaviour was correct.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `proxy.ts:19-32`, `proxy.ts:34-49`, `app/layout.tsx:27-30`

---

## Claim 16: "Lint clean; 221/221 tests pass." (d90d6bb body)

**Location:** commit d90d6bb (body)
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing executed in the winning replicate; does not establish lint or test status.
**Replicate verdicts:** r1=Unverifiable · r2=Unverifiable · r3=Verified
**Replicate annotations:** r3 (executed): "`vitest run` 221 pass and `eslint app/layout.tsx proxy.ts` clean at d90d6bb; does not establish full-repo eslint, and no test exercises proxy.ts" · r1: "the diff adds no tests, so the suite does not exercise the CSP either way"
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `package.json:5-12`, `fc-r3-logs/vitest.log`, `fc-r3-logs/eslint.log`

---

## Claim 17: "the nonce is only written, never read by the layout" (d90d6bb body)

**Location:** commit d90d6bb (body)
**Type:** Architectural
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** The "never read" half is true; the first half of the sentence restates the mechanism refuted in Claim 2.
**Replicate verdicts:** r1=Verified · r2=— · r3=Unverifiable
**Replicate annotations:** r1: "does not establish that Next.js itself obtains the nonce (see Claim 3)"
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `app/layout.tsx:22-43`

---

## Claim 18: "Manual end-to-end browser verification on the Vercel preview is still recommended" (9b4e453 body)

**Location:** commit 9b4e453 (body)
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Advice, not a code claim.
**Replicate verdicts:** r1=— · r2=— · r3=Unverifiable · single-replicate detection
**Replicate annotations:** r3: "the sandbox found concrete browser-only breakages (Claims 8, 5 annotation) that confirm the caution"
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** commit 9b4e453 body

---

## Claims Requiring Attention

### Incorrect
- **Claim 2** (`app/layout.tsx:26-28`): dynamic rendering does not make the proxy run; it makes the HTML carry the nonce.
- **Claim 3** (`app/layout.tsx:28-30`): Next reads the nonce from the request CSP header; the proxy sets CSP only on the response (r3: works on `next start` via the router's header copy; Vercel unconfirmed).
- **Claim 6** (`proxy.ts:12-14`): Tailwind v4 ships a stylesheet; 'unsafe-inline' is for React style props, KaTeX, React Flow.
- **Claim 8** (`proxy.ts:16,26`): `connect-src 'self'` blocks `fetch(dataUrl)` in `exportGraph.ts:24,37`; PNG and zip export break.
- **Claim 9** (`proxy.ts:35-36`): the Next 16 proxy runs on Node.js, not Edge.
- **Claim 11** (`proxy.ts:39-42`): nothing reads x-nonce; no `<Script>` exists.
- **Claim 13** (9b4e453 body): nonce-on-every-script contradicted statically (r3 executed: holds on `next start`).

### Stale
- none

### Mostly Accurate
- **Claim 7** (`proxy.ts:16-17`): OpenAlex has no code in the repo.
- **Claim 12** (`proxy.ts:52-62`): `public/` files and non-prefetch RSC navigations pass through; `/apiary`-style paths skipped.
- **Claim 14** (9b4e453 body): KaTeX trust:false is the default, not configured.

## Escalations

- **E1** `proxy.ts:41-48` — CSP never set on the forwarded request headers; static replicates say Next gets no nonce and 'strict-dynamic' blocks every script; r3 shows it works on `next start` only via the router's response-to-request header copy and flags Vercel as unconfirmed. Raised by r1, r2, r3. Addressee: security-reviewer, architecture-review.
- **E2** `app/lib/utils/exportGraph.ts:24,37` / `proxy.ts:26` — `connect-src 'self'` breaks graph PNG and Export All. Raised by r1, r2, r3. Addressee: security-reviewer.
- **E3** `fileExtraction.ts:26-29`, `pdfPropositionParser.ts:443-446` — pdf.js worker may be blocked: no `worker-src`, script-src with 'strict-dynamic' ignores 'self'. Raised by r3 (r1 listed it out of scope). Addressee: security-reviewer.
- **E4** `proxy.ts:16` — OpenAlex named as an external API with no code; possible hallucination-log entry. Raised by r1. Addressee: orchestrator.

## Verdict stability

- Total clusters: 18 (17 reported by 2+ replicates, 1 single-replicate).
- Agreed among reporting replicates: 9 (Claims 1, 2, 4, 5, 6, 8, 9, 10, 15).
- Disagreed: 8 — Claim 3 (I/I/V), 7 (MA/V/MA), 11 (MA/I/MA), 12 (MA/V/V), 13 (U/I/V), 14 (MA/U/V), 16 (U/U/V), 17 (V/—/U).
- Agreement rate: 9/17 = 53% on multi-replicate clusters. Four of the eight disagreements (3, 13, 16 and partly 14) are static-vs-executed splits: r3 ran the build that r1 and r2 could not.

## Goal-Alignment Note
- Success criterion (restated verbatim): A merged code-fact-check report (most-severe-wins over r1-r3) saved as csp/code-fact-check-report.md.
- Answered: yes
- Out of scope: none
- Escalate: E1-E4 above.
