# Code Fact-Check Report

**Commit:** 4329d6e
**Repository:** /workspace/external/cc-review-eval/mfc-deploy
**Scope:** `git diff d86d2dc...HEAD` — `CLAUDE.md` (new Deployment section), `README.md` (Deploy-to-Vercel section, Lean Verification Service edits)
**Checked:** 2026-08-18
**Total claims checked:** 24
**Summary:** 14 verified, 1 mostly accurate, 0 stale, 1 incorrect, 8 unverifiable

Environment notes relevant to executed verdicts: all raw execution output is captured under
`/workspace/runs/review-arms/e8-evidence-pipeline/mfc-deploy/evidence/` (prefix `r1-`). A stub
Lean-verifier HTTP service was already listening on `localhost:3100` in the review sandbox
(planted by the environment, not started by this review); it answers every request with
`{"valid":false,"errors":"stub-verifier-real-response"}` — this made it possible to observe which
requests actually reach the default verifier URL. Docker is not installed in the sandbox
(`docker not found`), which blocks execution of the Docker-based verifier claims.

---

## Claim 1a: "There is no shared hosted instance"

**Location:** `CLAUDE.md:73`
**Type:** Architectural
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers only whether the codebase reveals a hosted instance; does not establish whether anyone operates a shared deployment of this app elsewhere.

Whether a shared hosted instance exists is a fact about the world outside the repository
(paraphrased — no quote available because the claim covers absence of an external deployment,
which no code snippet can attest). Nothing in the repo points at a shared instance — no hosted
URL is referenced in `README.md` or config — but that absence cannot prove the negative.

**Evidence:** `README.md`, `CLAUDE.md`, `next.config.ts`

---

## Claim 1b: "…and no demo mode"

**Location:** `CLAUDE.md:73`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the absence of a demo-mode code path or flag in `app/`; does not establish anything about the separately-verdicted mock LLM fallback, which is a keyless fallback rather than a "demo mode".

A case-insensitive search for "demo" across `app/` finds no demo-mode flag, route, or UI state
(paraphrased — no quote available because the claim covers absence of code; the only hits are a
comment "to demonstrate cross-document connectivity" at `app/api/decomposition/extract/route.ts:51`
and unrelated identifiers).

**Evidence:** `app/api/decomposition/extract/route.ts:51`

---

## Claim 2: "There is no in-browser BYO-key flow; keys live in the Vercel project's environment variables (or `.env.local` in dev)."

**Location:** `CLAUDE.md:75`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers where API keys are read in this codebase and the absence of client-side key entry; does not establish how a particular Vercel project is actually configured.

API keys are read exclusively from server-side environment variables:

```ts
// app/lib/llm/callLlm.ts:112-113
const anthropicKey = process.env.ANTHROPIC_API_KEY;
const openRouterKey = process.env.OPENROUTER_API_KEY;
```

No component or hook under `app/components/` or `app/hooks/` references `apiKey` or any API-key
input (paraphrased — no quote available because the claim covers absence of code; the grep for
`apiKey`/`API_KEY` over those directories returns zero non-test hits). The `.env.local`-in-dev
half is Next.js framework env-file loading rather than repo code (paraphrased — no quote
available because the loading is implemented inside the `next` dependency, not in this
repository).

**Evidence:** `app/lib/llm/callLlm.ts:112-113`, `app/lib/llm/streamLlm.ts:88`

---

## Claim 3a: "The Lean verifier is a separate Dockerized service"

**Location:** `CLAUDE.md:76`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence and packaging of the verifier as its own Docker service; does not establish that the image builds or runs (see Claim 10).

The verifier is its own Docker Compose service built from `verifier/`:

```yaml
# docker-compose.yml:1-7
services:
  lean-verifier:
    build:
      context: ./verifier
      dockerfile: Dockerfile
    ports:
      - "3100:3100"
```

It is an Express server (`verifier/server.ts`) shelling out to `lake`:

```ts
// verifier/server.ts:131-132
    execFile(
      "lake",
```

**Evidence:** `docker-compose.yml:1-16`, `verifier/server.ts:131-132`, `verifier/Dockerfile`

---

## Claim 3b: "…and cannot run inside a Vercel Function"

**Location:** `CLAUDE.md:76`
**Type:** Architectural
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers only what can be inferred from the verifier's packaging; does not establish actual Vercel Function limits, which would require deploying to Vercel.

This is a claim about the Vercel platform's runtime constraints and would need a Vercel
deployment attempt to verify (paraphrased — no quote available because the claim is about an
external platform's capabilities, not this codebase). It is directionally supported by the
image's requirements — the Dockerfile installs a full Lean toolchain plus a ~1 GB Mathlib cache:

```dockerfile
# verifier/Dockerfile:24-25
# lake exe cache get downloads prebuilt Mathlib .olean files (~1 GB) so the
# image build avoids compiling Mathlib from source (~4 h).
```

**Evidence:** `verifier/Dockerfile:22-31`

---

## Claim 4a: "When `LEAN_VERIFIER_URL` is unset … `app/api/verification/lean/route.ts` falls back to a mock `{ valid: true, mock: true }` response."

**Location:** `CLAUDE.md:76`
**Type:** Behavioral / Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the route's behavior when the env var is unset; does not establish behavior on Vercel specifically, where the default URL happens to be unreachable and the conclusion coincidentally holds (see Claim 17b).

Unset does not select the mock. The route substitutes a default URL and attempts a real request:

```ts
// app/api/verification/lean/route.ts:3-4
const LEAN_VERIFIER_URL =
  process.env.LEAN_VERIFIER_URL ?? "http://localhost:3100";
```

The mock is returned only when that fetch throws:

```ts
// app/api/verification/lean/route.ts:37-40
  } catch {
    // Service unavailable — fall back to mock
    return NextResponse.json({ valid: true, mock: true });
  }
```

Executed refutation: with `ANTHROPIC_API_KEY`, `OPENROUTER_API_KEY`, and `LEAN_VERIFIER_URL` all
unset, and a stub service listening on `localhost:3100`, the route returned the stub's real
response, not the mock — `{"valid":false,"errors":"stub-verifier-real-response","url":"/verify"}`
(quoted from the captured output in
`/workspace/runs/review-arms/e8-evidence-pipeline/mfc-deploy/evidence/r1-lean-route-unset-reachable.txt`).
Command: `curl -s -X POST http://localhost:3000/api/verification/lean -H "Content-Type: application/json" -d '{"leanCode":"theorem t : True := trivial"}'`
against a dev server started with those vars unset; cwd `/workspace/external/cc-review-eval/mfc-deploy`;
exit 0; 2026-08-18T06:15Z. A reader relying on "unset → mock" (e.g. expecting mock behavior in
tests, or debugging why verification results are real) is misled: in the documented dev setup the
default port is exactly where the real verifier runs.

**Evidence:** `app/api/verification/lean/route.ts:3-4`, `app/api/verification/lean/route.ts:37-40`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-deploy/evidence/r1-lean-route-unset-reachable.txt`

---

## Claim 4b: "When `LEAN_VERIFIER_URL` is … unreachable, `app/api/verification/lean/route.ts` falls back to a mock `{ valid: true, mock: true }` response."

**Location:** `CLAUDE.md:76`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the connection-refused failure path (and by the same catch block, timeout/abort); does not establish behavior when the verifier responds with a non-OK HTTP status, which is forwarded rather than mocked (`route.ts:32-34`).

The catch-all fallback quoted under Claim 4a returns `{ valid: true, mock: true }` on any fetch
failure. Executed confirmation: the real route handler was invoked with
`LEAN_VERIFIER_URL=http://127.0.0.1:59999` (no listener) via a temporary Vitest test using real
fetch; the response equaled `{ valid: true, mock: true }` and the assertion passed.
Command: `npx vitest run --environment=node app/api/verification/lean/cfc-tmp-route.test.ts`;
cwd `/workspace/external/cc-review-eval/mfc-deploy`; exit 0; 2026-08-18T06:18:30Z; raw output in
`/workspace/runs/review-arms/e8-evidence-pipeline/mfc-deploy/evidence/r1-vitest-lean-route.txt`.

**Evidence:** `app/api/verification/lean/route.ts:37-40`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-deploy/evidence/r1-vitest-lean-route.txt`

---

## Claim 5: "This is a known silent-pass behavior — `useFormalizationPipeline` treats it as `valid` and there is currently no 'verifier offline' UI state."

**Location:** `CLAUDE.md:76`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the client-side handling of the mock response through `verifyLean` and the pipeline hook; does not establish behavior of every panel that displays verification status.

The client-side `verifyLean` wrapper discards the `mock` flag entirely, keeping only `valid`:

```ts
// app/lib/formalization/api.ts:110
return { valid: Boolean(data.valid), errors: (data.errors as string | undefined) ?? "" };
```

The pipeline hook maps that straight to the `"valid"` status:

```ts
// app/hooks/useFormalizationPipeline.ts:121-122
const vStatus = result.valid ? "valid" as const : "invalid" as const;
a.setVerificationStatus(vStatus);
```

No component or hook outside test files references `mock` or an offline/verifier-down state
(paraphrased — no quote available because the claim covers absence of code; grep for
`mock|offline` in `app/hooks/useFormalizationPipeline.ts` and `app/components/` returns hits only
in `*.test.tsx` files).

**Evidence:** `app/lib/formalization/api.ts:103-111`, `app/hooks/useFormalizationPipeline.ts:121-124`, `app/lib/formalization/leanRetryLoop.ts:69-73`

---

## Claim 6: "The LLM cache and analytics log write to the local filesystem in dev."

**Location:** `CLAUDE.md:77`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers where the cache and analytics persistence write in a local dev process; does not establish what happens to those writes on Vercel (see Claim 7 / 19b).

Both persistence layers target `<cwd>/data` on the local filesystem:

```ts
// app/lib/analytics/persist.ts:5-6
const DATA_DIR = join(process.cwd(), "data");
const FILE_PATH = join(DATA_DIR, "analytics.jsonl");
```

```ts
// app/lib/llm/cache.ts:6
const CACHE_DIR = join(process.cwd(), "data", "cache");
```

Executed confirmation, twice: (1) the Vitest callLlm run (see Claim 16 provenance) created
`data/analytics.jsonl` and `data/cache/<hash>.json` in the repo root — directory listing and file
contents captured in
`/workspace/runs/review-arms/e8-evidence-pipeline/mfc-deploy/evidence/r1-data-dir-writes.txt`;
(2) a dev-server call to `/api/formalization/semiformal` with no API keys appended
`{"id":"97ec5be5-…","endpoint":"formalization/semiformal","provider":"mock",…}` to
`data/analytics.jsonl` (quoted from the captured output in
`/workspace/runs/review-arms/e8-evidence-pipeline/mfc-deploy/evidence/r1-mock-llm-and-analytics.txt`).
Command: `curl -s -X POST http://localhost:3000/api/formalization/semiformal -H "Content-Type: application/json" -d '{"sourceText":"cfc probe"}'`;
cwd `/workspace/external/cc-review-eval/mfc-deploy`; exit 0; 2026-08-18T06:15Z. The created
`data/` directory was removed afterwards to leave the clone pristine.

**Evidence:** `app/lib/analytics/persist.ts:5-17`, `app/lib/llm/cache.ts:6`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-deploy/evidence/r1-data-dir-writes.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-deploy/evidence/r1-mock-llm-and-analytics.txt`

---

## Claim 7: "Vercel Functions can only write to `/tmp` and that lasts only as long as the warm container"

**Location:** `CLAUDE.md:77`
**Type:** Configuration
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers only what can be checked from this repo; does not establish Vercel's actual filesystem policy, which requires platform access or authoritative platform documentation.

This is a claim about the Vercel platform, not this codebase; verifying it requires a Vercel
deployment or Vercel's documentation as ground truth (paraphrased — no quote available because
the claim's subject is an external platform, not code in this repo). Worth noting: this code
writes to `<cwd>/data`, not `/tmp` (quoted at Claim 6), so if the platform claim is true these
writes would fail on Vercel; write failures are swallowed in `callLlm`'s
`recordAndCache` — `} catch { /* persistence failure must not break LLM calls */ }`
(`app/lib/llm/callLlm.ts:91`) — but `appendAnalyticsEntry` calls from
`app/api/analytics/route.ts` paths are outside that guard.

**Evidence:** `app/lib/analytics/persist.ts:5-17`, `app/lib/llm/callLlm.ts:84-97`

---

## Claim 8: Deploy button links to `https://vercel.com/new/clone?repository-url=…github.com%2Faditya-adiga%2Fmeta-formalism-copilot&env=ANTHROPIC_API_KEY…&envLink=…%23deploy-to-vercel…`

**Location:** `README.md:5`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers that the referenced GitHub repo URL resolves and that the button's env parameter and anchor match this README; does not establish that the GitHub repo's contents match this clone, nor that Vercel's clone flow succeeds end-to-end.

The referenced repository exists: `curl -sI https://github.com/aditya-adiga/meta-formalism-copilot`
returned `HTTP/2 200` (quoted from the captured output in
`/workspace/runs/review-arms/e8-evidence-pipeline/mfc-deploy/evidence/r1-github-repo-head.txt`);
cwd `/workspace/external/cc-review-eval/mfc-deploy`; exit 0; 2026-08-18T06:13:34Z — true as of
github.com at that time. The `env=ANTHROPIC_API_KEY` parameter matches the key the code actually
reads (`process.env.ANTHROPIC_API_KEY`, quoted at Claim 2), and the `envLink` anchor
`#deploy-to-vercel` corresponds to the `## Deploy to Vercel` heading at `README.md:98`.

**Evidence:** `README.md:5`, `README.md:98`, `app/lib/llm/callLlm.ts:112`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-deploy/evidence/r1-github-repo-head.txt`

---

## Claim 9: "When the service is not reachable, the verification API route returns a mock `{ valid: true, mock: true }` response so the rest of the app keeps working — note that this means generated Lean code is reported as valid without actually being type-checked."

**Location:** `README.md:64`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the unreachable-verifier fallback and its valid-without-type-checking consequence; does not establish the unset-variable case, which behaves differently (see Claim 4a).

Same mechanism and execution as Claim 4b: with `LEAN_VERIFIER_URL` pointing at a closed port the
route returned `{ valid: true, mock: true }` (executed; provenance and captured output at
`/workspace/runs/review-arms/e8-evidence-pipeline/mfc-deploy/evidence/r1-vitest-lean-route.txt`,
exit 0, 2026-08-18T06:18:30Z). The "reported as valid" consequence follows from the client
dropping the `mock` flag — `return { valid: Boolean(data.valid), … }`
(`app/lib/formalization/api.ts:110`) — so downstream the mock is indistinguishable from a real
pass (see Claim 5).

**Evidence:** `app/api/verification/lean/route.ts:37-40`, `app/lib/formalization/api.ts:110`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-deploy/evidence/r1-vitest-lean-route.txt`

---

## Claim 10: "When running, submitted Lean code is type-checked by a real Lean 4 installation."

**Location:** `README.md:64`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the verifier's code path as written; does not establish that the Docker image builds and type-checks, because execution was required but blocked.

This is an executable guarantee (a documented dev workflow), so under the mandatory-execution
rule it cannot be Verified statically — and execution is blocked: Docker is not installed in the
review sandbox (`which docker` → `docker not found`), so `docker compose up --build` cannot run.
Static reading supports the claim: the server writes submitted code to the Lean project and runs
`lake` (quoted at Claim 3a, `verifier/server.ts:131-132`), and the image installs the pinned
toolchain via `elan toolchain install $(cat /home/lean/lean-project/lean-toolchain)`
(`verifier/Dockerfile:29`). Verifying would need a sandbox with Docker (or a host with elan/lake)
to build the image and POST a theorem to `/verify`.

**Evidence:** `verifier/server.ts:121-155`, `verifier/Dockerfile:27-31`

---

## Claim 11: "The verifier runs on port 3100."

**Location:** `README.md:74`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the configured port in compose and the server default; does not establish that the container actually starts (blocked, see Claim 10).

Compose maps `"3100:3100"` and sets `PORT=3100` (quoted at Claim 3a,
`docker-compose.yml:6-9`), and the server defaults to the same:

```ts
// verifier/server.ts:9
const PORT = process.env.PORT ?? 3100;
```

**Evidence:** `docker-compose.yml:6-9`, `verifier/server.ts:9`

---

## Claim 12: curl examples — `{"leanCode":"theorem t : True := trivial"}` "Should return { \"valid\": true }" and the `False` variant "Should return { \"valid\": false, \"errors\": \"...\" }"

**Location:** `README.md:76-86`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the documented request/response examples against a running verifier; does not establish them, because the verifier cannot be started in this sandbox.

An executable guarantee (documented reproduction) that could not be executed: the real verifier
requires the Docker image (Docker absent — see Claim 10), and the service occupying
`localhost:3100` in the sandbox is a planted stub that returns
`{"valid":false,"errors":"stub-verifier-real-response"}` for every input, so it cannot stand in
for the real verifier. The response shape matches the server code — on build failure it returns
`errors: errorOutput || "lake build exited with code …"` (`verifier/server.ts:153`) — but the
valid/invalid outcomes for these specific theorems need a real Lean toolchain to confirm.

**Evidence:** `verifier/server.ts:121-155`

---

## Claim 13: "The Next.js route reads `LEAN_VERIFIER_URL` from the environment (defaults to `http://localhost:3100`). When the verifier is unreachable, the route falls back to the mock response described above."

**Location:** `README.md:88`
**Type:** Configuration / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the env read, the default URL, and the unreachable fallback; does not establish the non-OK-status path (forwarded, not mocked, per `route.ts:32-34`).

The default is exactly as documented — `process.env.LEAN_VERIFIER_URL ?? "http://localhost:3100"`
(quoted at Claim 4a, `app/api/verification/lean/route.ts:3-4`). Executed confirmation of both
halves: with the variable unset, the route's request arrived at the stub listening on
`localhost:3100` (proving the default URL is used — captured output in
`r1-lean-route-unset-reachable.txt`, exit 0, 2026-08-18T06:15Z), and with the variable set to an
unreachable address the route returned the mock (captured output in `r1-vitest-lean-route.txt`,
exit 0, 2026-08-18T06:18:30Z); both files under
`/workspace/runs/review-arms/e8-evidence-pipeline/mfc-deploy/evidence/`.

**Evidence:** `app/api/verification/lean/route.ts:3-4`, `app/api/verification/lean/route.ts:37-40`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-deploy/evidence/r1-lean-route-unset-reachable.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-deploy/evidence/r1-vitest-lean-route.txt`

---

## Claim 14: "The rest of the app keeps working without the verifier. Lean code can still be generated and edited; the type-check step returns the mock-valid response described above."

**Location:** `README.md:96`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that non-verifier features function with no verifier reachable and that verification degrades to the mock; does not establish full UI-level generation flows (only the API layer was exercised).

With no verifier reachable and no API keys, the dev server stayed up and the formalization API
answered normally — `/api/formalization/semiformal` returned a well-formed proof payload
(`{"proof":"-- Mock formalization (no API key configured)…`, quoted from the captured output in
`r1-mock-llm-and-analytics.txt`; provenance at Claim 6), and the type-check step's mock-valid
response is the executed result at Claim 4b (`r1-vitest-lean-route.txt`). The Lean generation
path does not depend on the verifier: `leanRetryLoop` calls `generateLean…` first and only then
`verifyLean` (`app/lib/formalization/leanRetryLoop.ts:1`, `:69` — `const { valid, errors } =
await verifyLean(fullCode);`).

**Evidence:** `app/lib/formalization/leanRetryLoop.ts:63-73`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-deploy/evidence/r1-mock-llm-and-analytics.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-deploy/evidence/r1-vitest-lean-route.txt`

---

## Claim 15: "Vercel clones the repo, prompts for the required env var, and deploys."

**Location:** `README.md:100`
**Type:** Behavioral / Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers only the consistency of the button URL's parameters with the claimed flow; does not establish Vercel's actual clone-and-deploy behavior, which requires exercising the Vercel flow.

The claim describes Vercel's hosted deploy flow, which cannot be exercised from this sandbox
(paraphrased — no quote available because the subject is an external service's behavior). The
button URL is consistent with the claim: it passes `repository-url=…meta-formalism-copilot` and
`env=ANTHROPIC_API_KEY` (`README.md:5`, quoted in part at Claim 8), which is the standard
vercel.com/new/clone parameterization for prompting an env var.

**Evidence:** `README.md:5`, `README.md:100`

---

## Claim 16: "`OPENROUTER_API_KEY` — Acts as a fallback LLM provider when `ANTHROPIC_API_KEY` is unset. Privacy note: prompts (including your source material) are sent to OpenRouter when this path is used."

**Location:** `README.md:114`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers provider selection order and outbound request contents in `callLlm` (and by identical logic `streamLlm`); does not establish OpenRouter's server-side data handling, only that the prompt leaves for OpenRouter's API.

The provider chain checks Anthropic first, then OpenRouter, then mock:

```ts
// app/lib/llm/callLlm.ts:114-118
const effectiveModel = anthropicKey
  ? (anthropicModel ?? DEFAULT_ANTHROPIC_MODEL)
  : (openRouterKey && openRouterModel)
    ? openRouterModel
    : "mock";
```

and the OpenRouter request body carries the full prompts:

```ts
// app/lib/llm/callLlm.ts:170-175
body: JSON.stringify({
  model: openRouterModel,
  messages: [
    { role: "system", content: systemPrompt },
    { role: "user", content: userContent },
  ],
```

Executed confirmation via a temporary Vitest test with `fetch` stubbed (no real network): with
both keys unset the provider was `mock` and no fetch occurred; with only `OPENROUTER_API_KEY` set
the call went to `https://openrouter.ai/api/v1/chat/completions` and the request body contained
the user source material — all three assertions passed.
Command: `npx vitest run --environment=node app/lib/llm/cfc-tmp-fallback.test.ts`;
cwd `/workspace/external/cc-review-eval/mfc-deploy`; exit 0; 2026-08-18T06:14:16Z; raw output in
`/workspace/runs/review-arms/e8-evidence-pipeline/mfc-deploy/evidence/r1-vitest-callllm-fallback.txt`.
One qualifier: the OpenRouter path also requires the calling route to pass an `openRouterModel`
(third test: key set but no model → mock); every LLM route in `app/api` does pass one
(paraphrased — no quote available because this spans 8 call sites; grep for `openRouterModel:`
hits all 7 direct routes plus the shared `app/lib/formalization/artifactRoute.ts:76,87` used by
the remaining formalization routes).

**Evidence:** `app/lib/llm/callLlm.ts:112-118`, `app/lib/llm/callLlm.ts:162-177`, `app/lib/formalization/artifactRoute.ts:76`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-deploy/evidence/r1-vitest-callllm-fallback.txt`

---

## Claim 17a: "The verifier is a separate Docker service … and cannot run on Vercel; host it elsewhere (Railway, Render, Fly.io, your own infra) and set this to its URL."

**Location:** `README.md:115`
**Type:** Architectural
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the platform-capability assertion; does not establish it, mirroring Claim 3b — the separate-Docker-service half is Verified at Claim 3a.

Same platform claim as Claim 3b: "cannot run on Vercel" requires platform verification
(paraphrased — no quote available because the subject is an external platform's capabilities).
The separate-Docker-service premise is verified at Claim 3a (`docker-compose.yml:1-7`, quoted
there); the hosting recommendations are advice, not checkable claims.

**Evidence:** `docker-compose.yml:1-16`, `verifier/Dockerfile:22-31`

---

## Claim 17b: "When unset, Lean code is generated but the type-check step returns the mock-valid response."

**Location:** `README.md:115`
**Type:** Behavioral / Error-handling
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the unset case in the Vercel deployment context this table addresses; does not establish the same statement for local dev, where it is false when a verifier runs on the default port (Claim 4a).

Imprecise mechanism, correct conclusion in its stated scope. Unset does not directly select the
mock: the route first tries the default `http://localhost:3100`
(`process.env.LEAN_VERIFIER_URL ?? "http://localhost:3100"`, quoted at Claim 4a) and mocks only
when that fetch fails — demonstrated by execution in both directions (reachable default → real
response, `r1-lean-route-unset-reachable.txt`; unreachable → mock, `r1-vitest-lean-route.txt`;
provenance at Claims 4a/4b). Inside a Vercel Function no verifier listens on the function's own
localhost, so in this table's Vercel context the unset case does end at the mock-valid response;
the precise version would be "when unset, the route tries `localhost:3100`, which is unreachable
on Vercel, and falls back to the mock-valid response." The confidence is Medium only because the
"unreachable on Vercel's localhost" step rests on platform behavior not testable here.

**Evidence:** `app/api/verification/lean/route.ts:3-4`, `app/api/verification/lean/route.ts:37-40`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-deploy/evidence/r1-lean-route-unset-reachable.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-deploy/evidence/r1-vitest-lean-route.txt`

---

## Claim 18: "**Lean verification** runs only when `LEAN_VERIFIER_URL` points at a separately hosted verifier (see above)."

**Location:** `README.md:119`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the Vercel deployment context of the "Limitations on Vercel" list; does not establish the general statement outside Vercel, and rests partly on the untestable premise that nothing listens on a Vercel Function's localhost:3100.

Real verification requires a reachable verifier — the route performs a real POST to
`${LEAN_VERIFIER_URL}/verify` and mocks on failure (`app/api/verification/lean/route.ts:21-26,
37-40`, quoted at Claims 4a/4b). On Vercel the only way to make the verifier reachable is an
external URL, since the Docker service cannot be co-deployed (paraphrased — no quote available
because this step combines the platform premise of Claim 3b with the route code already quoted).
Confidence is Medium because that platform premise is not testable from this sandbox.

**Evidence:** `app/api/verification/lean/route.ts:21-40`, `docker-compose.yml:1-16`

---

## Claim 19a: "**Analytics history** is written to the local filesystem…"

**Location:** `README.md:120`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers where analytics entries are persisted; does not establish the Vercel-persistence half (Claim 19b).

Same finding as Claim 6: analytics append to `<cwd>/data/analytics.jsonl`
(`app/lib/analytics/persist.ts:5-6`, quoted there), confirmed by execution — the dev-server mock
LLM call created the file with a JSON line (captured in `r1-mock-llm-and-analytics.txt`;
provenance at Claim 6).

**Evidence:** `app/lib/analytics/persist.ts:5-17`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-deploy/evidence/r1-mock-llm-and-analytics.txt`

---

## Claim 19b: "…and does not persist across Vercel function invocations; treat the analytics panel as dev-only."

**Location:** `README.md:120`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers only what the repo shows; does not establish Vercel's cross-invocation filesystem behavior, which requires a deployed instance.

Cross-invocation persistence on Vercel is platform behavior requiring a live deployment to test
(paraphrased — no quote available because the subject is an external platform's runtime, not this
code). Consistent with the code: there is no storage backend — persistence is plain `fs` writes
to the working directory (`appendFileSync(FILE_PATH, …)`, `app/lib/analytics/persist.ts:16`), so
nothing in the app would carry state across ephemeral containers.

**Evidence:** `app/lib/analytics/persist.ts:14-17`

---

## Claims Requiring Attention

### Incorrect
- **Claim 4a** (`CLAUDE.md:76`): "unset → mock" is wrong — unset substitutes the default `http://localhost:3100` and reaches a real verifier when one is listening (the documented dev default); executed proof returned the real service's response, not the mock. The precise statement is the README:88 form: unset defaults the URL; the mock happens only on unreachable.

### Stale
- None.

### Mostly Accurate
- **Claim 17b** (`README.md:115`): "when unset → mock-valid" holds on Vercel only because localhost:3100 is unreachable there; tighten to "when unset, the route tries `localhost:3100` (unreachable on Vercel) and falls back to the mock-valid response."

### Unverifiable
- **Claim 1a** (`CLAUDE.md:73`): existence/absence of a shared hosted instance is a fact about the outside world.
- **Claim 3b** (`CLAUDE.md:76`): "cannot run inside a Vercel Function" needs a Vercel deployment attempt (statically plausible given the ~1 GB Lean/Mathlib image).
- **Claim 7** (`CLAUDE.md:77`): Vercel's `/tmp`-only, warm-container filesystem policy needs platform access; note the code writes to `<cwd>/data`, not `/tmp`.
- **Claim 10** (`README.md:64`): "type-checked by a real Lean 4 installation" is an executable guarantee blocked by missing Docker in the sandbox.
- **Claim 12** (`README.md:76-86`): the curl examples' expected outputs need a running real verifier (Docker blocked; the port-3100 service present in the sandbox is a planted stub).
- **Claim 15** (`README.md:100`): Vercel's clone-prompt-deploy flow needs the external service.
- **Claim 17a** (`README.md:115`): same platform claim as 3b.
- **Claim 19b** (`README.md:120`): cross-invocation non-persistence on Vercel needs a deployed instance.
