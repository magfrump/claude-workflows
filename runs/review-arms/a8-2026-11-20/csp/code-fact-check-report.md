Commit: d90d6bb

# Code Fact-Check Report

**Repository:** meta-formalism-copilot (scratch worktree at d90d6bb)
**Scope:** d86d2dc..d90d6bb — `proxy.ts`, `app/layout.tsx`, commit messages 9b4e453, b25e939, d90d6bb
**Checked:** 2026-11-19
**Total claims checked:** 24
**Summary:** 8 verified, 3 mostly accurate, 0 stale, 10 incorrect, 3 unverifiable
**Commit:** d90d6bb
**Replication:** k=3

Merged by the orchestrator from `code-fact-check-report-r1.md`, `-r2.md`, `-r3.md` (all `Commit: d90d6bb`), most-severe-wins; delivery mode self-read. Evidence is carried by reference to the winning replicate's claim; read it there.

## Claim 1: `await headers()` opts the layout out of static rendering

**Location:** `app/layout.tsx:27,31`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that headers() makes the route dynamic (no cacheComponents/PPR configured); does not establish build output.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none
**Evidence:** winning replicate: r2 Claim 1, r3 Claim 8
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 2: "so proxy.ts runs on every request and can attach a fresh per-request CSP nonce"

**Location:** `app/layout.tsx:27-28`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the router order (proxy runs before page lookup for every matched path, static or not); does not establish runtime by execution.
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect
**Replicate annotations:** r2: `resolve-routes.js:57-72` puts the proxy before page lookup · all: dynamic rendering is needed so the HTML carries the per-request nonce, not to make the proxy run
**Evidence:** winning replicate: r2 Claim 2 (High)
**Legibility-target:** for-author

---

## Claim 3: "Next.js automatically tags its own bootstrap <script> elements with the nonce from the response's CSP header"

**Location:** `app/layout.tsx:28-30`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers Next 16.2.4's render path reading the nonce from request headers; does not establish whether the router's response-to-request header copy runs on Vercel.
**Replicate verdicts:** r1=Incorrect · r2=Mostly accurate · r3=Incorrect
**Replicate annotations:** r2: "works on `next start` only because the router also copies the proxy's response headers onto `req.headers` (`resolve-routes.js:442-443`)"; Vercel unconfirmed · r1+r3: no nonce reaches Next, so 'strict-dynamic' blocks every bootstrap script
**Evidence:** winning replicate: r3 Claim 10 (High): `app-render.js:166-167`, `spec-extension/response.js:35-39`
**Legibility-target:** for-author

---

## Claim 4: "so we don't need to read x-nonce here ourselves"

**Location:** `app/layout.tsx:30`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the layout never reads x-nonce; does not establish that Next obtains a nonce (see Claim 3).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Incorrect (compound with Claim 3)
**Replicate annotations:** r3 verdicted this sentence with Claim 3 as one compound (Incorrect on the nonce source); r1+r2: the layout indeed never reads x-nonce, true as written. Merge rule (decision 033) carries the compound Incorrect onto this row
**Evidence:** winning replicate: r1 Claim 3, r2 Claim 4
**Legibility-target:** for-author

---

## Claim 5: "Next.js 16 renamed Middleware → Proxy"

**Location:** `proxy.ts:5`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers Next 16 docs and build code; does not establish the deprecation warning text by build.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none
**Evidence:** winning replicate: r3 Claim 1
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 6: "only scripts that Next.js has explicitly tagged with the nonce can run, and any scripts they load inherit trust"

**Location:** `proxy.ts:7-10`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether Next tags any script under this proxy, per its render path; does not establish browser behavior by execution.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Incorrect
**Replicate annotations:** r1+r2: the strict-dynamic semantics are correct · r3: the premise fails, Next gets no nonce (same mechanism as Claim 3)
**Evidence:** winning replicate: r3 Claim 2 (High)
**Legibility-target:** for-author

---

## Claim 7: "Tailwind v4 emits inline styles" (why style-src needs 'unsafe-inline')

**Location:** `proxy.ts:12-14`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the Tailwind pipeline (@tailwindcss/postcss, external stylesheet) and the app's inline-style sources; does not establish built CSS output.
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect
**Replicate annotations:** all: 'unsafe-inline' is still needed, for ~30 React style={} props, KaTeX and React Flow
**Evidence:** winning replicate: r1 Claim 6
**Legibility-target:** for-author

---

## Claim 8: "Anthropic / OpenRouter calls are server-to-server (Next API routes)"

**Location:** `proxy.ts:16-17`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every fetch to those hosts in the repo; does not establish OpenAlex (Claim 9).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none
**Evidence:** winning replicate: r1 Claim 7a
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 9: "OpenAlex ... calls are server-to-server"

**Location:** `proxy.ts:16`
**Type:** Behavioral
**Verdict:** Mostly Accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers d90d6bb: no OpenAlex code exists.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r1: OpenAlex code exists only on unmerged `origin/feat/evidence-integration`
**Evidence:** winning replicate: r1 Claim 7b
**Legibility-target:** for-author

---

## Claim 10: "connect-src 'self' is sufficient" (and 9b4e453 body)

**Location:** `proxy.ts:16,26`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every browser-side fetch in app/; does not establish browser behavior by execution.
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect
**Replicate annotations:** all: `app/lib/utils/exportGraph.ts:24,37` `fetch(dataUrl)` on a data: URL is blocked; graph PNG export (`GraphPanel.tsx:98-110`) and export-all (`exportAll.ts:64`) break with only console.error
**Evidence:** winning replicate: r1 Claim 7c, r3 Claim 4b
**Legibility-target:** for-author

---

## Claim 11: "the Edge runtime that Next proxy runs in"

**Location:** `proxy.ts:35-36`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers Next 16 docs and build code (proxy forced to nodejs).
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect
**Replicate annotations:** r2: `get-page-static-info.js:576` "Proxy always runs on Node.js runtime", `build/index.js:1515`
**Evidence:** winning replicate: r2 Claim 9a
**Legibility-target:** for-author

---

## Claim 12: "crypto.randomUUID and Buffer are both available"

**Location:** `proxy.ts:35-37`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers Node.js runtime globals.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none
**Evidence:** winning replicate: r3 Claim 5a
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 13: x-nonce is forwarded "so layouts can read it via headers() and pass it to <Script> tags"

**Location:** `proxy.ts:39-42`
**Type:** Behavioral
**Verdict:** Mostly Accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every reader of x-nonce and every Script use in app/.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** all: nothing reads x-nonce; no `<Script>`/next/script in app/
**Evidence:** winning replicate: r3 Claim 6
**Legibility-target:** for-author

---

## Claim 14: matcher skips API routes, static assets and prefetches (comment and 9b4e453 body)

**Location:** `proxy.ts:52-62`
**Type:** Behavioral
**Verdict:** Mostly Accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the matcher regex and `has`/`missing` clauses.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Mostly accurate
**Replicate annotations:** r1+r3: lookahead `(?!api` has no trailing slash, so any path starting with api is skipped · r3: public/ SVGs and non-prefetch RSC requests still run the proxy · r1: _next/image and favicon.ico also skipped, unmentioned
**Evidence:** winning replicate: r3 Claim 7
**Legibility-target:** for-author

---

## Claim 15: "no dangerouslySetInnerHTML, no rehype-raw, KaTeX trust:false"

**Location:** 9b4e453 body; app/components/features/output-editing/LatexRenderer.tsx:6-10
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers a repo-wide search of app/ for those sinks; does not establish future additions.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r3: trust is false by default, not set explicitly
**Evidence:** winning replicate: r1 Claim 11
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 16: "middleware.ts builds with a deprecation warning"

**Location:** 9b4e453 body
**Type:** Configuration
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** No build could run.
**Replicate verdicts:** r1=Unverifiable · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r2: verified from Next source text
**Evidence:** winning replicate: r1 Claim 12
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 17: "Layout reads headers() to opt out of static rendering — required because per-request nonces can't be cached"

**Location:** 9b4e453 body
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the static/dynamic mechanism.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** none
**Evidence:** winning replicate: r2 Claim 15
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 18: 9b4e453 body repeats the Tailwind and connect-src reasons

**Location:** 9b4e453 body
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Same evidence as Claims 7 and 10.
**Replicate verdicts:** r1=Incorrect (compound, Claim 7c) · r2=Incorrect · r3=Incorrect (compound, Claim 4b)
**Replicate annotations:** none
**Evidence:** winning replicate: r2 Claim 16
**Legibility-target:** for-author

---

## Claim 19: "Verified prod build emits the CSP header and Next applies the nonce to every <script> tag it generates"

**Location:** 9b4e453 body
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers Next's render path under this proxy; no build ran.
**Replicate verdicts:** r1=Unverifiable · r2=Unverifiable · r3=Incorrect
**Replicate annotations:** r2: "Reading the code, the nonce is passed into Next's script generation" (holds only via the router copy, Claim 3)
**Evidence:** winning replicate: r3 Claim 12
**Legibility-target:** for-author

---

## Claim 20: "headers() is called to opt out of static rendering so the proxy can attach per-request CSP"

**Location:** d90d6bb body
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Same evidence as Claim 2.
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect (compound, Claim 9)
**Replicate annotations:** r1: it replaced 9b4e453's correct reason
**Evidence:** winning replicate: r2 Claim 18a
**Legibility-target:** for-author

---

## Claim 21: "the nonce is only written, never read by the layout"

**Location:** d90d6bb body
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the layout source.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=—
**Replicate annotations:** none
**Evidence:** winning replicate: r2 Claim 18b
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 22: "No behavior change; CSP directives preserved exactly"

**Location:** d90d6bb body; proxy.ts:34-48
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the 9b4e453..d90d6bb diff of buildCsp.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none
**Evidence:** winning replicate: r1 Claim 15a
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 23: "Lint clean; 221/221 tests pass"

**Location:** d90d6bb body
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** executed
**Scope:** r2 executed vitest (221/221 pass) and eslint (exit 0) in the reference checkout; r1/r3 could not run.
**Replicate verdicts:** r1=Unverifiable · r2=Verified · r3=Unverifiable
**Replicate annotations:** r2: vitest exit 1 came from an empty /workspace/external/package.json, not a test (logs: r2-logs/)
**Evidence:** winning replicate: r2 Claim 20
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 24: "Manual end-to-end browser verification on the Vercel preview is still recommended"

**Location:** 9b4e453 body
**Type:** Configuration
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Needs a browser and a deployment.
**Replicate verdicts:** — · r2=Unverifiable · r3=Unverifiable
**Replicate annotations:** none
**Evidence:** winning replicate: r3 Claim 15
**Legibility-target:** for-orchestrator-synthesis

---

## Escalations

- E1 `proxy.ts:41-48` — CSP is set only on the response; Next reads the nonce from the request. It works on self-hosted `next start` only through the router copying response headers onto the request (`resolve-routes.js:442-443`, r2); r1+r3 read it as no nonce at all, every script blocked. Fix: also set CSP on `requestHeaders`. Raised by r1, r2, r3. Addressee: security-reviewer, architecture-review.
- E2 `app/lib/utils/exportGraph.ts:24,37` / `proxy.ts:26` — connect-src 'self' breaks graph PNG export and export-all. r1, r2, r3. Addressee: security-reviewer (functional regression; orchestrator).
- E3 `app/lib/utils/fileExtraction.ts:26`, `app/lib/utils/pdfPropositionParser.ts:443` — pdf.js worker may not load under 'strict-dynamic' with no worker-src; unchecked. r1. Addressee: security-reviewer.
- E4 `proxy.ts:20-30` — script-src has no dev-only 'unsafe-eval', which Next's guide says React needs in development (`content-security-policy.md:42`). r3. Addressee: security-reviewer.
- E5 `proxy.ts:52-62` — the `(?!api` lookahead is unanchored: a future page under a path starting with `api` gets no CSP. r2 (r1, r3 in claim prose). Addressee: security-reviewer.
- E6 no tests cover `proxy.ts`. r3. Addressee: test-strategy.

## Verdict stability

- Total clusters: 24. All reporting replicates agreed: 16. Disagreed: 8 — Claim 3 (I/MA/I), 4 (V/V/I compound), 6 (V/V/I), 9 (MA/V/V), 14 (MA/V/MA), 16 (U/V/V), 19 (U/U/I), 23 (U/V/U).
- Agreement rate: 16/24 = 67%. (Claims 18 and 20 counted as agreed where one replicate verdicted a compound.)
