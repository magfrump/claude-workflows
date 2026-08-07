# Code Fact-Check Report — Merged (k=3)

**Scope:** `git diff d86d2dc..HEAD` in `wt-validate-arm2` (detached at 99e1229; ancestors only). Files: `app/layout.tsx`, `app/lib/utils/exportGraph.ts` (+`.test.ts`), `proxy.ts` (+`proxy.test.ts`).
**Commit:** 99e1229 (`fix: address full-review blockers R1-R4 (e3 arm2 iter1)`)
**Replication:** k=3 (three fresh, independent code-fact-check draws: r1, r2, r3)
**Collation:** mechanical, most-severe-wins per cluster (Incorrect(high) > Incorrect(med) > Stale > Mostly-accurate > Verified). Each Incorrect/Stale cluster tagged with its decision-031 tier-policy-T class.
**Purpose:** validate decision 031 tier policy T — does the fact-check axis yield any 🔴 for arm 2 full-review pass 2?
**Caveat carried by all three draws:** no `node_modules` in the worktree; test-suite execution could not be run. All test claims verified by static assertion-vs-code analysis, not a green run.

---

## Verified clusters (all k=3 agree — Verified/Correct)

### Cluster 1 — Request-header CSP forwarding delivers the nonce where Next reads it
**Source:** `proxy.ts:33-46` comment + code; `layout.tsx` comment; 99e1229 R1.
**Replicate verdicts:** r1 Verified/High · r2 Correct · r3 Correct (render-time half Likely-Correct, med-high).
`csp = buildCsp(nonce)` is set identically on both the forwarded request headers (`requestHeaders.set("Content-Security-Policy", csp)` via `NextResponse.next({request:{headers}})`) and the response. This is the documented Next.js nonce-with-CSP mechanism; response-only is insufficient under `'strict-dynamic'`. Code is correct for the contract. The render-time behavior (Next parsing the nonce off the request CSP header) is a framework behavior not executable in a unit test; manual browser verification remains recommended per the commit.
**Merged verdict:** Verified · Confidence High.

### Cluster 2 — exportGraph `dataUrlToBlob`: correct decode, both call sites, no `data:` fetch remains
**Source:** `exportGraph.ts:16-65`; 99e1229 R2.
**Replicate verdicts:** r1 Verified/High · r2 Correct · r3 Correct.
Decoder splits on first comma, validates `data:` prefix, detects `;base64`, strips media-type params via `.split(";")[0]`, base64-decodes `atob`→`charCodeAt`→`Uint8Array` (preserves non-UTF-8 bytes; test `//79`→`[0xff,0xfe,0xfd]`), percent-decodes the non-base64 branch, falls back to `application/octet-stream`. Both former `fetch(dataUrl)` sites replaced (`downloadGraphAsPng`→`triggerDownload(dataUrlToBlob(...))`; `graphToPngBlob`→`return dataUrlToBlob(...)`). Only surviving `fetch` token is in the docstring. R2 rationale accurate (`fetch("data:...")` is `connect-src`-governed; `'self'` refuses `data:`).
**Merged verdict:** Verified · Confidence High.

### Cluster 3 — proxy.test.ts assertions match; CSP-forwarding test genuinely falsifies broken wiring
**Source:** `proxy.test.ts`; 99e1229 R3.
**Replicate verdicts:** r1 Verified/High · r2 Correct · r3 Correct.
`buildCsp` exported and imported by the test; directive-set assertion matches the 9 emitted directives one-to-one; nonce+`'strict-dynamic'` on script-src and `'unsafe-inline'` on style-src match. `forwardedRequestHeader()` decodes Next's `x-middleware-override-headers`/`x-middleware-request-*` encoding — the correct observable. The "forwards the same CSP on the request" test asserts non-null + equal-to-response; against pre-R1 wiring (CSP response-only) the forwarded header is absent, `forwardedRequestHeader` returns null, and the test fails. Genuinely falsifies broken wiring. Per-request freshness and x-nonce overwrite assertions consistent.
**Merged verdict:** Verified · Confidence High.

### Cluster 4 — layout `force-dynamic` comment mechanism
**Source:** `app/layout.tsx:21-27`; 99e1229 R4.
**Replicate verdicts:** r1 Verified/High · r2 Correct · r3 Correct.
`export const dynamic = "force-dynamic"` present; comment mechanism accurate (static prerender would bake in one reused nonce; per-request render required; Next takes the nonce from the request CSP header; "nothing here reads it directly"). No `headers()` call remains in the layout. R4 correctly describes replacing the prior (d90d6bb) discarded `await headers()` with the module-surface `dynamic` export.
**Merged verdict:** Verified · Confidence High.

### Cluster 5 — connect-src 'self' load-bearing claim (all external calls server-to-server)
**Source:** `proxy.ts:12-15` comment; 9b4e453.
**Replicate verdicts:** r1 Mostly-accurate/High (load-bearing part) · r2 Correct (load-bearing part) · r3 Correct.
All three independently re-enumerated client network calls: every browser `fetch`/`fetchApi`/`fetchStreamingApi` targets a same-origin `/api/*` route (ContextInput, LeanCodeDisplay, useAnalytics, formalization/api.ts). Third-party origins (`OPENROUTER_API_URL`, Anthropic SDK, `LEAN_VERIFIER_URL`) are reached only from server-side `app/api/**/route.ts` modules. No browser-to-third-party call; no WebSocket/EventSource/sendBeacon. `connect-src 'self'` is sufficient. **Load-bearing security claim: Verified.** (The stale vendor name inside this same comment is clustered separately — see Cluster A.)
**Merged verdict:** Verified · Confidence High.

---

## Claims Requiring Attention

Three comment-level clusters plus one immutable-history item. Most-severe-wins verdict shown; every Incorrect/Stale cluster carries a **T-class:** tag.

### Cluster A — `connect-src` comment names "OpenAlex", a vendor absent from the codebase
**Source:** `proxy.ts:14-15` (connect-src rationale docstring).
**Replicate verdicts:** r1 Mostly-accurate (comment-only) · r2 **Stale** (comment-only, `rg -rin openalex` → 0 matches) · r3 Correct (did not separately flag; folded into Cluster 5 as verified).
**Merged verdict:** Stale (most-severe = r2) · Confidence High.
**Code status:** correct — `connect-src 'self'` is right precisely *because* there are no client calls to OpenAlex or anyone else.
**T-class:** `comment-only`. Although the enclosing comment is a security rationale, the *load-bearing* security claim (all calls server-to-server) is Verified (Cluster 5); the stale part is only a stray vendor name that no future change binds to. Reader-misinformed, code correct → 🟡 under T, not a contract/security-rationale red. Fix: drop "OpenAlex" from the list.

### Cluster B — `x-nonce` comment overstates an inactive smuggling path
**Source:** `proxy.ts:41-45` (x-nonce overwrite-not-append comment).
**Replicate verdicts:** r1 Verified (overwrite behavior; no attention flag) · r2 **Stale** / comment-only imprecision (flagged: no server component reads `x-nonce`; header currently unused) · r3 Correct (overwrite behavior; no flag).
**Merged verdict:** Stale (most-severe = r2) · Confidence Medium (1 of 3 flagged).
**Code status:** correct — overwriting a client-supplied `x-nonce` via `Headers.set()` is harmless and correct-by-construction; test enforces it.
**T-class:** `comment-only`. The comment implies an active smuggling path to a server component, but no consumer reads `x-nonce`; it is defense-in-depth for a consumer that does not yet exist. Reader-misinformed, code correct → 🟡. Not a contract a future change binds to today. Fix: reword as "future/defense-in-depth" or drop the header.

### Cluster C — `proxy.ts` "Edge runtime" comment (crypto.randomUUID / Buffer availability)
**Source:** `proxy.ts:32-35` ("`crypto.randomUUID` and `Buffer` are both available in the Edge runtime that Next proxy runs in").
**Replicate verdicts:** r1 Mostly-accurate/Medium (comment-only) · r2 not raised · r3 **Incorrect/Stale** (comment; Next runs proxy on the Node runtime by default, no `runtime:"edge"` config present) — 🟡, comment-only.
**Merged verdict:** Incorrect (most-severe = r3, runtime label wrong) · Confidence Medium (raised by 2 of 3, only r3 called it Incorrect).
**Code status:** correct — `crypto.randomUUID()` and `Buffer` are available in *both* Node and Edge runtimes, so the behavior the comment guards works regardless of the mislabeled runtime.
**T-class:** `comment-only`. Reader-facing runtime name is off; code behavior unaffected; explicitly not a security/contract rationale (r3). → 🟡 under T. This is the "known marginal-red class" from decision 031's context, and it lands 🟡, not 🔴.

### Cluster D — 9b4e453 verification claim was false at that commit (immutable history)
**Source:** 9b4e453 commit message: "Verified prod build emits the CSP header and Next applies the nonce to every `<script>` tag it generates."
**Replicate verdicts:** r1 Incorrect (immutable-history) · r2 Incorrect (accepted-immutable per override) · r3 Incorrect (was false at that commit) — **all three route to override log**.
**Merged verdict:** Incorrect · Confidence High (k=3 unanimous).
At 9b4e453 the proxy set CSP **only on the response**, never on the forwarded request header, so Next would not have applied the per-request nonce — the exact defect R1 fixed in 99e1229. The claim was therefore false when written.
**T-class:** `immutable-history`. Per the LOOP-OWNER OVERRIDE and tier policy T(b), a fact-check Incorrect about a claim in already-merged history routes to the **override log as an accepted-immutable acknowledgment**, never 🔴, and is **not** a fresh finding. No code change can fix a merged commit message.

### Non-finding — 99e1229 absolute test/build claims (all k=3: Unverifiable by execution)
"234 tests pass (was 221)", tsc/lint clean. Absolute counts and clean-build results cannot be executed here (no `node_modules`). The **+13 delta is statically corroborated** by all three: 8 new proxy tests + 5 new exportGraph tests = 13; 221+13 = 234. Internally consistent; not a finding, not a red.

---

## Override log (immutable-history — not fresh findings)
- **9b4e453** commit message: "Verified prod build emits the CSP header and Next applies the nonce to every `<script>` tag it generates." Accepted-immutable per LOOP-OWNER OVERRIDE (tier policy T(b)). Recorded here; never scored 🔴. (Cluster D.)

---

## Verdict stability

| Cluster | r1 | r2 | r3 | Merged (most-severe) | Agreement |
|---|---|---|---|---|---|
| 1 CSP request-forwarding | Verified | Correct | Correct | **Verified** | 3/3 |
| 2 dataUrlToBlob | Verified | Correct | Correct | **Verified** | 3/3 |
| 3 proxy.test falsifiability | Verified | Correct | Correct | **Verified** | 3/3 |
| 4 force-dynamic | Verified | Correct | Correct | **Verified** | 3/3 |
| 5 connect-src load-bearing | Mostly-acc | Correct | Correct | **Verified** | 3/3 |
| A OpenAlex stale name | Mostly-acc | Stale | Correct | **Stale** (comment-only) | 2 flag / 1 correct |
| B x-nonce comment | Verified | Stale | Verified | **Stale** (comment-only) | 1 flag / 2 no |
| C Edge-runtime label | Mostly-acc | — | Incorrect | **Incorrect** (comment-only) | 2 raise / 1 silent |
| D 9b4e453 claim | Incorrect | Incorrect | Incorrect | **Incorrect** (immutable) | 3/3 |
| E abs. test counts | Unverif. | Unverif. | Unverif. | **Unverifiable** | 3/3 |

**Stability summary:** Complete unanimity (3/3) on all five core code claims (1-5), on the immutable-history item (D), and on the unverifiable-by-execution test-count item (E). Divergence appears only on the three comment-level nits: A (2 flag, r3 treats as correct), B (only r2 flags), C (r1+r3 raise, r2 silent; only r3 escalates to Incorrect). Crucially, **no cluster diverges on the code-status axis** — all three draws agree the code is correct everywhere; disagreement is confined to which comment nits rise to the level of a flagged finding. No replicate produced a behavioral-red or a security/contract-rationale red.

---

## T-tier tally

| T-class | Clusters | Tier T disposition | Count |
|---|---|---|---|
| `behavioral-red` (code wrong) | — | 🔴 | **0** |
| `contract/security-rationale` (comment a future change binds to) | — | 🔴 | **0** |
| `comment-only` (code correct, reader misinformed) | A, B, C | 🟡 | **3** |
| `immutable-history` | D | override log (never 🔴) | **1** |

**🔴 under tier policy T (behavioral-red + contract/security-rationale): 0.**
**🟡 under tier policy T: 3** (all comment-only; code correct in every case).
**Override log: 1** (9b4e453, immutable history).

### Does the fact-check side yield any 🔴 under T?
**No.** Every code claim in scope (Clusters 1-5) is Verified with k=3 unanimity. The only Incorrect/Stale clusters are three comment-only documentation nits (OpenAlex stale vendor name, x-nonce overstatement, Edge-runtime mislabel) — all 🟡 with the code correct — plus one immutable-history verification claim that routes to the override log per the LOOP-OWNER OVERRIDE. The fact-check axis produces **zero 🔴** for arm 2 full-review pass 2 at 99e1229, consistent with decision 031 tier policy T's expectation that this pass reaches 0-red and the loop terminates at two full passes. (The final termination determination is the loop owner's, informed by this 0-red fact-check input.)
