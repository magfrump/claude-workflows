# Code Fact-Check Report — CARRY-FORWARD (pass 2)

**Repository:** meta-formalism-copilot (pinned worktree /workspace/runs/review-arms/e3-loops/wt-carry-arm2, detached at 99e1229)
**Mechanism:** Arm-Carry (decision 031 / review-arm-ideas-2026-08-06.md). Carry-forward from pass-1 merged report at /workspace/runs/review-arms/e1/csp-dirty/code-fact-check-report.md (Commit d90d6bb).
**Fix under review:** `git diff d90d6bb..99e1229` — arm2's fix of the four full-review blockers R1-R4 on top of the CSP feature.
**Checked:** 2026-08-06
**Replication:** k=1 (single pass, scoped to the changed-set)

**Commit:** 99e1229
**Carry:** carried 0 claims / rechecked 15 claims / changed-set = 8 files.

> Note: csp is the deliberate near-zero-carry **worst case** for the Arm-Carry mechanism. All three pass-1 Verified claims (Claims 3, 9, 13) cite files inside the changed-set, so **nothing is carry-eligible** — every claim falls to MUST-RECHECK. This is the point of testing carry here: it demonstrates that when the changeset is central to the reviewed surface, carry correctly declines to carry anything rather than hiding findings.

---

## Step 1 — Changed-set (fix files ∪ one-hop import closure)

Fix files (`git diff d90d6bb..99e1229 --name-only`):

1. `proxy.ts`
2. `app/layout.tsx`
3. `app/lib/utils/exportGraph.ts`
4. `proxy.test.ts`
5. `app/lib/utils/exportGraph.test.ts`

One-hop import closure (imports of/by the fix source files, under `app/` + root):

6. `app/lib/utils/export.ts` — imported by exportGraph.ts (`import { triggerDownload } from "./export"`)
7. `app/lib/utils/exportAll.ts` — imports exportGraph.ts (`downloadGraphAsPng`/`graphToPngBlob`)
8. `app/components/panels/GraphPanel.tsx` — imports exportGraph.ts

Closure notes:
- `proxy.ts` and `app/layout.tsx` are Next.js framework entry points with **no source importers** (`layout.tsx`'s apparent importers were path false-positives from the `app/components/layout/` directory; `page.tsx` imports `PanelShell`, not the root layout). Their imports are `next/*` + CSS only — no additional app/ files enter the closure through them.
- `proxy.ts`'s only importer is `proxy.test.ts` (already in the set).

**K = 8 files.**

## Step 2 — Partition of pass-1 claims

CARRY-ELIGIBLE = verdict Verified AND every cited file OUTSIDE the changed-set.
MUST-RECHECK = everything else.

| Claim | Location cited | Pass-1 verdict | Cites changed-set file? | Partition |
|---|---|---|---|---|
| 1 | app/layout.tsx:27-28 | Mostly accurate | yes (layout.tsx) | MUST-RECHECK |
| 2 | app/layout.tsx:28-30 | Incorrect | yes (layout.tsx) | MUST-RECHECK |
| 3 | proxy.ts:5 | **Verified** | yes (proxy.ts) | MUST-RECHECK |
| 4 | proxy.ts:7-10 | Mostly accurate | yes (proxy.ts) | MUST-RECHECK |
| 5 | proxy.ts:12-14 | Incorrect | yes (proxy.ts) | MUST-RECHECK |
| 6 | proxy.ts:16-17 + exportGraph.ts | Incorrect | yes (proxy.ts, exportGraph.ts) | MUST-RECHECK |
| 7 | proxy.ts:35-37 | Stale | yes (proxy.ts) | MUST-RECHECK |
| 8 | proxy.ts:39-41 | Mostly accurate | yes (proxy.ts) | MUST-RECHECK |
| 9 | proxy.ts:52-55 | **Verified** | yes (proxy.ts) | MUST-RECHECK |
| 10 | commit 9b4e453 | Mostly accurate | (historical) | MUST-RECHECK |
| 11 | commit 9b4e453 / LatexRenderer.tsx | Mostly accurate | no (not Verified anyway) | MUST-RECHECK |
| 12 | commit 9b4e453 | Incorrect | (historical) | MUST-RECHECK |
| 13 | commit b25e939 / app/layout.tsx:27 | **Verified** | yes (layout.tsx) | MUST-RECHECK |
| 14 | commit d90d6bb | Mostly accurate | (historical) | MUST-RECHECK |
| 15 | commit d90d6bb | Unverifiable | (historical) | MUST-RECHECK |

**Counts: CARRY-ELIGIBLE = 0 · MUST-RECHECK = 15.**

All three pass-1 Verified claims cite a changed-set file (Claims 3 & 9 → proxy.ts; Claim 13 → layout.tsx), so each falls to MUST-RECHECK. No claim qualifies for carry. The carried-forward "do not re-check" appendix is therefore empty.

## Step 3 — Fresh scoped fact-check at 99e1229

Scope: the 8 changed-set files at 99e1229, including re-verification that the pass-1 reds are closed and the marginal comment claims (Edge-runtime; connect-src enumeration). Repo-wide negative greps (OpenAlex, `<Script>`, `fetch(data:)`) were still run because the claims are existential over the repo.

---

### Claim 1: layout root-render contract — "a statically prerendered HTML document would bake in one nonce and reuse it for every visitor, which defeats the nonce."

**Location:** app/layout.tsx:21-25 (new comment) + `export const dynamic = "force-dynamic"` (app/layout.tsx:26)
**Type:** Behavioral / mechanism
**Verdict:** Verified
**Confidence:** High
**Change vs pass-1:** Pass-1 Claim 1 was **Mostly accurate** — the `await headers()` comment gave the wrong reason ("so proxy.ts runs on every request"). The fix (R4) removed `await headers()`, replaced it with `export const dynamic = "force-dynamic"`, and rewrote the comment to the correct causal story (a prerendered page would bake one nonce for all visitors). The misattribution is gone. **Closed.**

**Evidence:**
- `export const dynamic = "force-dynamic";` — app/layout.tsx:26; `import { headers }` and `await headers()` both removed (diff d90d6bb..99e1229).
- Comment now states the caching rationale, not the "proxy runs per request" rationale.

### Claim 2 (R1): nonce delivery — "Next.js takes the nonce from the request's Content-Security-Policy header (set in proxy.ts) and stamps it onto the bootstrap `<script>` tags it emits."

**Location:** app/layout.tsx:22-24 (comment) + proxy.ts:41-47
**Type:** Behavioral (framework mechanism)
**Verdict:** Verified
**Confidence:** High (mechanism); Medium-High for the operational result (no live build in worktree)
**Change vs pass-1:** Pass-1 Claim 2 was the load-bearing **Incorrect** finding — the comment said Next reads the nonce from the *response* CSP header, and proxy.ts set CSP only on the response, so no nonce ever reached the scripts. The fix (R1) now sets the identical policy string on **both** the forwarded request headers and the response (proxy.ts:47 `requestHeaders.set("Content-Security-Policy", csp)` and proxy.ts:55 `response.headers.set(...)`), and both the layout comment and proxy.ts:41-45 now correctly name the **request** header as the source. This matches the documented Next.js mechanism (Next parses the request `Content-Security-Policy` header during render). **R1 CLOSED.**

**Evidence:**
- proxy.ts:39 `const csp = buildCsp(nonce);`; proxy.ts:47 sets CSP on request headers; proxy.ts:55 sets same `csp` on the response — one policy string on both.
- proxy.test.ts:78-86 asserts the forwarded request carries the same `Content-Security-Policy` as the response (via Next's `x-middleware-request-*` / `x-middleware-override-headers` encoding) — makes the nonce-delivery belief falsifiable.
- Next.js request-header nonce-discovery mechanism: carried from pass-1 evidence (vercel/next.js CSP guide); no network in sandbox.

### Claim 3: "CSP proxy (Next.js 16 renamed Middleware → Proxy) with per-request nonces."

**Location:** proxy.ts:5
**Type:** Reference / architectural
**Verdict:** Verified
**Confidence:** High
**Change vs pass-1:** None — comment unchanged; re-verified because it cites proxy.ts (changed-set). File still named `proxy.ts` at root, exports `proxy`, config.matcher present, nonce generated per invocation.

**Evidence:**
- `"next": "16.2.4"` (package.json); `export function proxy(request: NextRequest): NextResponse` — proxy.ts:34; `const nonce = Buffer.from(crypto.randomUUID()).toString("base64")` — proxy.ts:37.

### Claim 4: "Why nonces + 'strict-dynamic': only scripts that Next.js has explicitly tagged with the nonce can run…"

**Location:** proxy.ts:7-10
**Type:** Behavioral (CSP semantics)
**Verdict:** Verified
**Confidence:** Medium-High
**Change vs pass-1:** Pass-1 Claim 4 was **Mostly accurate** only because its premise ("scripts Next has tagged with the nonce") failed — nothing was tagged (dependency on the then-Incorrect Claim 2). With R1 fixed, Next now receives the nonce via the request header and tags its bootstrap scripts, so the premise holds. Comment text unchanged; verdict upgraded to **Verified** as a consequence of the R1 fix.

**Evidence:**
- proxy.ts:22 `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'`; dependency on Claim 2 now satisfied (proxy.ts:47).

### Claim 5: "Why `style-src 'unsafe-inline'`: Tailwind v4 emits inline styles…"

**Location:** proxy.ts:12-14
**Type:** Behavioral / configuration rationale
**Verdict:** Incorrect
**Confidence:** Medium
**Change vs pass-1:** **Unchanged — not addressed by the fix.** The comment still attributes the `'unsafe-inline'` carve-out to Tailwind v4 emitting inline styles. Tailwind v4 here compiles through PostCSS into `globals.css` and ships as a linked stylesheet — it does not emit inline styles. The carve-out is genuinely needed, but for React `style={}` attributes, reactflow inline transforms, KaTeX spans, and dev-mode HMR style injection. Note: the **new** proxy.test.ts:59-61 comment states the correct attribution ("Required by React style={} attributes, reactflow's inline transforms and KaTeX"), but the proxy.ts docstring was left wrong. Remains **Incorrect**.

**Evidence:**
- proxy.ts:23 `style-src 'self' 'unsafe-inline'`; `@tailwindcss/postcss` + `import "./globals.css"`; proxy.test.ts:59-61 (correct attribution, in the test only).

### Claim 6 (R2): "`connect-src 'self'` is sufficient because Anthropic / OpenAlex / OpenRouter calls are server-to-server…"

**Location:** proxy.ts:16-17 (+ formerly exportGraph.ts:20-26,33-38)
**Type:** Behavioral / invariant
**Verdict:** Stale
**Confidence:** High
**Change vs pass-1:** Pass-1 Claim 6 was **Incorrect** for two reasons; the fix resolves one and leaves the other:
- **Sufficiency (R2) — CLOSED.** The counterexample was `fetch(dataUrl)` on a `data:` URL in exportGraph.ts, which `connect-src 'self'` blocked. The fix replaced both call sites with an in-process `dataUrlToBlob()` decoder (exportGraph.ts:23-44, 54, 65). A repo-wide grep now finds **no** client-side `fetch()` of a `data:`/cross-origin URL (the only remaining hit is the explanatory comment at exportGraph.ts:19). So `connect-src 'self'` is now genuinely sufficient. PNG/zip export no longer blocked.
- **OpenAlex enumeration — STILL STALE.** `rg -il openalex` matches only proxy.ts — OpenAlex is referenced nowhere else in the repo; there is no OpenAlex call, server-side or otherwise. The comment names a service that does not exist in the codebase.

Because the sufficiency conclusion now holds but the directive comment still enumerates a phantom dependency, the residual verdict is **Stale** (down from Incorrect).

**Evidence:**
- exportGraph.ts:23-44 (`dataUrlToBlob`), :54 and :65 (call sites now decode in-process); no `fetch(data:)` remaining in `app/`.
- `rg -il openalex .` → proxy.ts only.
- exportGraph.test.ts:8-39 covers the decoder (base64, non-base64 percent-encoding, non-UTF-8 bytes, param stripping, rejects non-data URLs).

### Claim 7: "crypto.randomUUID and Buffer are both available in the Edge runtime that Next proxy runs in."

**Location:** proxy.ts:35-36
**Type:** Configuration / runtime
**Verdict:** Incorrect
**Confidence:** Medium
**Change vs pass-1:** **Unchanged — not addressed by the fix.** In Next.js 16, `proxy.ts` runs on the **Node.js runtime** by default; "the Edge runtime that Next proxy runs in" misidentifies the runtime. next.config.ts is empty and proxy.ts exports no `runtime` config, so nothing opts into Edge. The availability half is harmless (both APIs are first-class in Node), but the runtime premise is wrong. Pass-1 merged this as **Stale**; at 99e1229 the comment positively asserts an incorrect runtime, so it reads as **Incorrect**. (This is the marginal comment claim the safety check specifically targets.)

**Evidence:**
- proxy.ts:35-37; next.config.ts empty config; no `export const runtime` in proxy.ts.
- Next 16 Node-first proxy runtime: carried from pass-1 reasoning; no network in sandbox.

### Claim 8: nonce forwarding via `x-nonce` (was "so layouts can read it via headers() and pass to `<Script>` tags")

**Location:** proxy.ts:48-50 (comment rewritten)
**Type:** Architectural / behavioral
**Verdict:** Verified (with dead-plumbing note)
**Confidence:** High
**Change vs pass-1:** Pass-1 Claim 8 was **Mostly accurate** — the `x-nonce` forwarding worked but the described consumer (a layout reading `x-nonce` and rendering `<Script>` tags) did not exist. The fix removed that misleading comment. The new comment (proxy.ts:48-49) only claims the `set` overwrites (not appends) a client-supplied `x-nonce` to prevent smuggling — which is accurate (`Headers.set` overwrites; proxy.test.ts:97-108 asserts it). Delivery of the nonce to markup now happens via the request CSP header (Claim 2), so `x-nonce` is redundant plumbing, but the remaining comment is accurate and the anti-smuggling property is real. **Verified**; residual note: `x-nonce` still has no reader (`rg x-nonce` → only the write at proxy.ts:50) and no `<Script>` exists anywhere (`rg 'next/script|<Script'` → 0), so the header is dead but harmless.

**Evidence:**
- proxy.ts:48-50; proxy.test.ts:97-108 (overwrite-not-append); `rg x-nonce` → proxy.ts:50 only; `rg next/script|<Script` → 0 hits.

### Claim 9: matcher — "Apply CSP to page navigations only. Skip API routes, static assets, and prefetches."

**Location:** proxy.ts:59-72
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Change vs pass-1:** None — matcher and comment unchanged; re-verified because in changed-set file. Negative lookahead excludes `api`, `_next/static`, `_next/image`, `favicon.ico`; `missing` entries exclude both prefetch headers.

**Evidence:**
- proxy.ts:65-69.

### Claim 10: commit 9b4e453 — "feat: add strict CSP with per-request nonces"

**Location:** git history (9b4e453, pre-fix)
**Type:** Commit-message / behavioral (historical)
**Verdict:** Mostly accurate (historical; unchanged)
**Confidence:** High
**Change vs pass-1:** The commit diff is immutable; verdict stands re its own diff. Pass-1's qualifier ("the shipped policy behaves like a nonce-shaped allowlist that would block Next's own scripts") **no longer applies at HEAD** — R1 makes the strict CSP functional at 99e1229 — but that is a property of the later commit, not of 9b4e453.

**Evidence:** proxy.ts:22,37 as of 9b4e453; cross-reference now-closed Claim 2.

### Claim 11: commit 9b4e453 — "XSS surface already defensive (no dangerouslySetInnerHTML, no rehype-raw, KaTeX trust:false)"

**Location:** commit 9b4e453 body; cites app/components/features/output-editing/LatexRenderer.tsx (OUTSIDE changed-set)
**Type:** Invariant (historical)
**Verdict:** Mostly accurate (unchanged)
**Confidence:** High
**Change vs pass-1:** None. LatexRenderer.tsx and package.json are unchanged by the fix. `rg dangerouslySetInnerHTML|rehype-raw` still zero; KaTeX `trust` still relies on the library default (false) rather than explicit config. This is the one claim whose cited file is entirely outside the changed-set — a full-scope pass would return the identical verdict, so nothing is lost by not re-deriving it here.

**Evidence:** carried from pass-1 (LatexRenderer.tsx:6; zero dangerouslySetInnerHTML/rehype-raw); files untouched by d90d6bb..99e1229.

### Claim 12: commit 9b4e453 — "Verified prod build emits the CSP header and Next applies the nonce to every `<script>` tag it generates."

**Location:** commit 9b4e453 body (historical)
**Type:** Behavioral / verification claim (historical)
**Verdict:** Incorrect (historical; unchanged)
**Confidence:** Medium
**Change vs pass-1:** The claim describes a state that was false when 9b4e453 was written (its own wiring set CSP on the response only, so Next could not have applied the nonce). As a claim about 9b4e453 it remains **Incorrect**. Note the underlying defect is **now resolved at HEAD** by R1 — a fresh equivalent claim made about 99e1229 would be accurate — but the historical commit-message claim itself is unchanged.

**Evidence:** 9b4e453 wiring; cross-reference Claim 2 (mechanism) and R1 closure.

### Claim 13: commit b25e939 — "fix: correct layout comment to reference proxy.ts"

**Location:** git history (b25e939, pre-fix); cites app/layout.tsx (changed-set)
**Type:** Commit-message / reference (historical)
**Verdict:** Verified (historical; unchanged)
**Confidence:** High
**Change vs pass-1:** b25e939's diff is immutable and still a comment-only change referencing proxy.ts. Re-checked because it cites layout.tsx, which the fix later rewrote again (R4) — but that does not alter what b25e939 did. Verdict stands.

**Evidence:** `git show b25e939 --stat` = `app/layout.tsx | 2 +-`.

### Claim 14: commit d90d6bb — "No behavior change; CSP directives preserved exactly."

**Location:** commit d90d6bb body (this pass's base commit; historical)
**Type:** Behavioral (refactor invariant)
**Verdict:** Mostly accurate (historical; unchanged)
**Confidence:** Medium
**Change vs pass-1:** d90d6bb is the carry base and is not inside the fix range; its diff is unchanged. Verdict stands.

**Evidence:** carried from pass-1 (d90d6bb diff: comment rewrites + return-type annotation + `csp` inlining; buildCsp untouched).

### Claim 15: commit d90d6bb — "Lint clean; 221/221 tests pass."

**Location:** commit d90d6bb body (historical)
**Type:** Verification claim
**Verdict:** Unverifiable (unchanged)
**Confidence:** Medium
**Change vs pass-1:** No node_modules in worktree, so lint/tests cannot run. Static test-declaration count at d90d6bb was 221 (per pass-1). Note the test count at **99e1229** is now **234** (see Claim N1) — consistent with the fix adding proxy.test.ts + exportGraph.test.ts.

**Evidence:** node_modules absent; static counts (221 at d90d6bb, 234 at 99e1229).

---

### Claim N1 (NEW — fix commit 99e1229): "address full-review blockers R1-R4 … 234 tests pass (was 221)"

**Location:** commit 99e1229 message + the fix diff
**Type:** Commit-message / verification (new, in-range)
**Verdict:** Mostly accurate (execution claims Unverifiable in worktree)
**Confidence:** High for the code dispositions; Medium for the pass/lint counts (cannot execute)
**Assessment:** All four disposition claims are borne out by the diff:
- **R1** — both request and response now carry the same policy string (proxy.ts:47,55). ✓
- **R2** — `dataUrlToBlob` added and both `fetch(dataUrl)` sites replaced (exportGraph.ts). ✓
- **R3** — `buildCsp` is now exported (proxy.ts:19) and proxy.test.ts asserts the directive set, nonce on script-src, style-src carve-out, per-request freshness, x-nonce overwrite, and request-forwarding of the CSP. ✓
- **R4** — `export const dynamic = "force-dynamic"` replaces `await headers()` (layout.tsx:26). ✓

"234 tests pass (was 221)": a static count of `it(`/`test(` declarations across `*.test.ts(x)` at 99e1229 totals **234**, matching the claim; the +13 corresponds to the 5 new dataUrlToBlob tests + 8 new proxy tests. Execution (`vitest run`, `tsc --noEmit`, `lint`) could not be reproduced (no node_modules), so the pass/clean assertions are corroborated-but-not-executed.

**Evidence:** proxy.ts:19,47,55; layout.tsx:26; exportGraph.ts:23-65; proxy.test.ts (full); exportGraph.test.ts (full); static test count = 234.

---

## Step 4 — Merged pass-2 report summary

**Carried-eligible claims (verbatim, tagged `carried from d90d6bb`):** none — the carry appendix is empty (worst case).

**Fresh scoped verdicts (15 rechecked + 1 new):**

| Claim | Pass-1 | Pass-2 | Disposition |
|---|---|---|---|
| 1 (layout render contract) | Mostly accurate | **Verified** | R4/A1 fixed |
| 2 (nonce delivery) | Incorrect | **Verified** | R1 CLOSED |
| 3 (Middleware→Proxy) | Verified | Verified | unchanged |
| 4 (strict-dynamic semantics) | Mostly accurate | **Verified** | upgraded via R1 |
| 5 (style-src / Tailwind) | Incorrect | **Incorrect** | not addressed |
| 6 (connect-src) | Incorrect | **Stale** | R2 sufficiency CLOSED; OpenAlex still phantom |
| 7 (Edge runtime) | Stale | **Incorrect** | not addressed |
| 8 (x-nonce forwarding) | Mostly accurate | **Verified** | misleading comment removed; dead-but-harmless |
| 9 (matcher) | Verified | Verified | unchanged |
| 10 (9b4e453 strict CSP) | Mostly accurate | Mostly accurate | historical |
| 11 (9b4e453 XSS surface) | Mostly accurate | Mostly accurate | historical, out-of-blast-radius |
| 12 (9b4e453 nonce-applied) | Incorrect | Incorrect | historical; defect resolved at HEAD |
| 13 (b25e939 comment fix) | Verified | Verified | historical |
| 14 (d90d6bb no behavior change) | Mostly accurate | Mostly accurate | historical |
| 15 (d90d6bb lint/221 tests) | Unverifiable | Unverifiable | historical |
| N1 (99e1229 R1-R4 / 234 tests) | — | Mostly accurate | new; code dispositions verified |

**Open findings at 99e1229 (still requiring attention):**
- **Claim 7 (proxy.ts:35-36) — Incorrect:** "Edge runtime" mislabels the Node.js runtime that Next 16 proxy uses by default. Harmless to execution, wrong as documentation. Untouched by the R1-R4 fix.
- **Claim 6 (proxy.ts:16) — Stale:** the connect-src comment enumerates "OpenAlex", which is referenced nowhere in the repo. (The sufficiency conclusion is now correct after R2.)
- **Claim 5 (proxy.ts:12-14) — Incorrect:** `style-src 'unsafe-inline'` is misattributed to Tailwind emitting inline styles; the real reasons (React `style={}`, reactflow, KaTeX, dev HMR) are stated correctly only in the test file, not the source docstring.

**Closed by the fix:** R1 (Claim 2, and consequentially Claims 1, 4), R2 (Claim 6 sufficiency half), R3 (test coverage / Claim N1), R4 (Claim 1 / A1).

## SAFETY CHECK — did carry hide any finding a full-scope pass would catch?

**No. Safety check PASSES.**

Every finding a full-scope validation pass at 99e1229 would surface is present in this scoped output, because every one lives inside the fix's blast radius (all in `proxy.ts` / `exportGraph.ts` / `app/layout.tsx`, which are changed-set files):

| Full-scope finding | In scoped output? | Where |
|---|---|---|
| Edge-runtime comment Incorrect (proxy.ts:35-36) | ✓ | Claim 7 |
| connect-src OpenAlex staleness (proxy.ts:16) | ✓ | Claim 6 |
| style-src/Tailwind misattribution still Incorrect (proxy.ts:12-14) | ✓ | Claim 5 |
| R1 closure (nonce delivery) | ✓ | Claims 2, 1, 4 |
| R2 closure (connect-src/exportGraph) | ✓ | Claim 6 |
| R3 closure (buildCsp export + tests) | ✓ | Claim N1, Claim 8 |
| R4 closure (force-dynamic) | ✓ | Claim 1 |

Nothing that the full scope would catch was missed by the scoped carry run. The only pass-1 claim whose cited evidence lies entirely **outside** the changed-set is Claim 11 (LatexRenderer.tsx, XSS surface) — its file is unchanged since pass-1, so a full-scope pass would return the identical "Mostly accurate" verdict; the scoped run restates it rather than re-deriving it, so no finding is lost there either.

**Why the safety property holds here trivially:** carry only ever declines to re-verify claims that are (a) already Verified and (b) cite no changed-set file. A finding (non-Verified verdict) can therefore *never* be carried — findings are MUST-RECHECK by construction. The danger carry must avoid is a *stale-but-Verified* claim whose truth was silently invalidated by the fix; that can only happen if the fix touched a file the claim cites, which is exactly the "cites a changed-set file → MUST-RECHECK" condition. csp confirms this end-to-end: 0 carried, every red re-examined.

## Cost note (csp = near-zero-carry worst case)

- Carried: **0** claims. Rechecked: **15** (+1 new). Changed-set: **8** files.
- Direct carry savings = **0** verification units (nothing was carry-eligible).
- Because several claims are existential over the whole repo (OpenAlex absence, no `<Script>`, no residual `fetch(data:)`, no `dangerouslySetInnerHTML`), even the *scoped* run had to grep the full tree, so scoping bought little beyond bounding file *reads* to 8 files.
- **Estimated tokens saved vs a full-scope pass: ~0-10% (negligible).** This is the designed worst case: the changeset is central (all 3 Verified claims and all reds are in the blast radius), so carry correctly carries nothing. The mechanism's value materializes only when a large reviewed surface has many Verified claims *outside* a small blast radius — the inverse of csp.
