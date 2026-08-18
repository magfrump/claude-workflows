# Code Fact-Check Report — Submitted Claims (Stage 2.5)

**Repository:** cc-review-eval / mfc-hygiene (Metaformalism Copilot)
**Scope:** Endorsement claims routed by Stage-2 critics on `git diff d86d2dc...f2f149b` — the LLM-server hygiene diff (`app/lib/llm/callLlm.ts`, `app/lib/llm/streamLlm.ts`, `app/api/edit/artifact/route.ts`, `app/lib/llm/callLlm.test.ts`)
**Checked:** 2026-08-18
**Commit:** f2f149b
**Total claims checked:** 2
**Summary:** 2 verified, 0 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Two endorsement claims were routed for Stage-2.5 verification: one from `security-reviewer`
(`route: code-fact-check`), one from `performance-reviewer` (`[unverified — submitted as
claim]`). The `api-consistency-reviewer` report carries no routing tags — nothing collected
from it.

---

## Submitted Claims

## Claim 1: "Removing the module-scope Anthropic singleton means a rotated `ANTHROPIC_API_KEY` is used on the next call — the old key is not retained in a cached client across calls."

**Submitted by:** security-reviewer
**Location:** `app/lib/llm/callLlm.ts:10-16,111,133`; `app/lib/llm/streamLlm.ts:84,207`; `app/lib/llm/callLlm.test.ts:41-54`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that no module-scope client is retained across calls and that a rotated `ANTHROPIC_API_KEY` is picked up on the next invocation of both consumers (`callLlm` and `streamAnthropic`), by execution. Does NOT establish how quickly the Vercel platform propagates a dashboard env-var change to a running instance (outside the codebase) — the critic itself scoped that out in its `Not verified` pair.

This endorsement is fully carried by the executed merged-report **Claim 2** and **Claim 3**
(`runs/review-arms/e8-evidence-pipeline/mfc-hygiene/code-fact-check-report.md`), both
`Verdict: Verified`, `Verification mode: executed`, and I cite them rather than re-running.
The endorsement's wording decomposes into three atoms, each already covered:

- *"the old key is not retained in a cached client across calls"* — no module-scope singleton
  survives. Merged Claim 2 established statically that `rg -n "getAnthropicClient" app` returns
  no hits and the `let _anthropicClient` / `getAnthropicClient` singleton form was removed, and
  the factory constructs unconditionally:

  ```ts
  // app/lib/llm/callLlm.ts:14-16
  export function makeAnthropicClient(apiKey: string): Anthropic {
    return new Anthropic({ apiKey });
  }
  ```

- *"a rotated key is used on the next call"* — the env var is re-read per call, so a rotation
  takes effect on the next invocation. Merged Claim 3 quoted the per-call read
  (`app/lib/llm/callLlm.ts:111` `const anthropicKey = process.env.ANTHROPIC_API_KEY;`) and the
  streaming equivalent (`streamLlm.ts:84` reads the env var, `:207` calls
  `makeAnthropicClient`).

- *the shipped test asserting rotation* — merged Claim 2's executed run
  (`callLlm Anthropic client lifetime > constructs a fresh Anthropic client per call`) passed
  at exit 0, recording constructions `[{ apiKey: "key-A" }, { apiKey: "key-B" }]` across two
  rotated env keys; merged Claim 3's executed streaming test recorded
  `[{ apiKey: "stream-key-A" }, { apiKey: "stream-key-B" }]`.

The endorsement's wording introduces no assertion beyond what Claims 2/3 already verdicted at
`executed` — its coverage is complete, and the critic's own `Not verified` note (platform
propagation latency) matches Claim 3's Scope exactly. Verdict inherits Verified/executed.

**Evidence:** `runs/review-arms/e8-evidence-pipeline/mfc-hygiene/code-fact-check-report.md` (merged Claims 2 & 3), `app/lib/llm/callLlm.ts:14-16,111`, `app/lib/llm/streamLlm.ts:84,207`, `./evidence/r2-vitest-callLlm-existing.txt`, `./evidence/r2-vitest-scratch.txt`, `./evidence/r1-calllm-client-lifetime-test.txt`

---

## Claim 2: "Per-call construction of `new Anthropic({ apiKey })` does not open a fresh TCP/TLS connection per call — the `@anthropic-ai/sdk` HTTP client reuses connections at the process-global dispatcher level rather than binding a keep-alive pool per client instance."

**Submitted by:** performance-reviewer
**Location:** `app/lib/llm/callLlm.ts:14-16,133`; `app/lib/llm/streamLlm.ts:207`
**Type:** Performance / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the app's actual construction path — `new Anthropic({ apiKey })` with no `fetch` and no `fetchOptions`/`dispatcher` — on the Node 20 global-fetch runtime the repo targets: the transport binding is process-global (one shared `globalThis.fetch`, no per-client dispatcher), so per-call construction creates no per-instance connection pool. Does NOT establish reuse *rates* against the live `api.anthropic.com` under concurrent production load, and the socket-reuse demonstration used a plaintext localhost keep-alive server as a scheme-independent stand-in (the TLS handshake itself was not exercised); it also does not cover a hypothetical caller that injects a custom `fetch` or `fetchOptions.dispatcher`, which the app does not do.

This claim IS executable and was probed at `/workspace/external/cc-review-eval/mfc-hygiene`
(clone left pristine; probe output relocated to this instance's `evidence/`). The decisive
evidence is transport-binding **reference identity** in the SDK, corroborated by a live
socket-reuse count.

**SDK source (v0.90.0, static).** The client resolves its transport once at construction to the
global `fetch` and stores `fetchOptions` verbatim:

```js
// node_modules/@anthropic-ai/sdk/client.js:72,74
this.fetchOptions = options.fetchOptions;
this.fetch = options.fetch ?? Shims.getDefaultFetch();
```

```js
// node_modules/@anthropic-ai/sdk/internal/shims.js:9-14
function getDefaultFetch() {
    if (typeof fetch !== 'undefined') {
        return fetch;
    }
    throw new Error('`fetch` is not defined as a global; ...');
}
```

The app constructs with neither `fetch` nor `fetchOptions`
(`app/lib/llm/callLlm.ts:15` `return new Anthropic({ apiKey });`), so every instance binds
`this.fetch = globalThis.fetch` and `this.fetchOptions = undefined`. On the request path the SDK
merges only `(this.fetchOptions ?? {})` and `(options.fetchOptions ?? {})`
(`client.js:445-446`) — no `dispatcher` key is ever set. There is therefore no per-client
transport object that could hold a per-instance connection pool.

**Executed probe (reference identity + localhost socket reuse).** Constructed two clients with
rotated keys and issued 6 requests alternating across the two instances' `.fetch` against a
localhost keep-alive server, counting server-observed TCP sockets:

```
== Part A: SDK transport binding (per-instance vs shared) ==
c1.fetch === c2.fetch                  : true
c1.fetch === globalThis.fetch          : true
c2.fetch === globalThis.fetch          : true
c1.fetchOptions (per-client dispatcher): null
c2.fetchOptions (per-client dispatcher): null
c1.apiKey !== c2.apiKey (distinct keys): true

== Part B: localhost keep-alive socket reuse (6 requests via c1.fetch/c2.fetch alternating) ==
distinct server-observed TCP sockets   : 2
```

Part A proves the binding is shared and per-client-dispatcher-free: two distinct-key client
instances resolve to the identical `globalThis.fetch` function and neither carries a
dispatcher. Part B shows the connection pool is shared across those distinct instances — 6
requests routed through two different client objects opened **2** sockets, not 6, i.e.
connections are reused and pooling is not per-instance (the 2-vs-1 residual is undici's
global-dispatcher pool behavior, not a per-client pool; the load-bearing contrast is 2 ≪ 6).
Because Node 20's global `fetch` is backed by a single process-global undici dispatcher and the
SDK binds nothing per client, per-call construction reuses that process-global pool rather than
opening a fresh connection per call — exactly as claimed. The "adds a TLS handshake per request"
failure mode the critic feared is refuted: no per-call construction cost of that kind exists on
this path.

- **Command:** `node evidence/sc-probe.mjs` (run in the clone; output captured)
- **Working directory:** `/workspace/external/cc-review-eval/mfc-hygiene`
- **Exit code:** 0
- **Timestamp:** 2026-08-18T06:58Z

**Evidence:** `./evidence/sc-connection-reuse-probe.txt`, `./evidence/sc-connection-reuse-probe.mjs`, `./evidence/sc-sdk-transport-source-facts.txt`, `node_modules/@anthropic-ai/sdk/client.js:72,74,445-446`, `node_modules/@anthropic-ai/sdk/internal/shims.js:9-14`, `app/lib/llm/callLlm.ts:15`

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- None.

### Mostly Accurate
- None.

### Unverifiable
- None.

Both submitted endorsement claims verdict **Verified** at `executed` mode and are admissible
backing for ✅ Confirmed-Good rows per provenance rule 5 (each `executed`, each with a `Scope:`
line bounding what it covers).
