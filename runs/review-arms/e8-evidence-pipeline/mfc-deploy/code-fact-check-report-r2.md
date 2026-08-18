# Code Fact-Check Report

**Commit:** 4329d6e
**Repository:** /workspace/external/cc-review-eval/mfc-deploy
**Scope:** Files changed in `git diff d86d2dc...HEAD` — `CLAUDE.md` (new Deployment section) and `README.md` (Deploy-to-Vercel section, Lean Verification Service edits) — with doc claims traced into the code they describe.
**Checked:** 2026-08-18
**Total claims checked:** 22
**Summary:** 13 verified, 2 mostly accurate, 0 stale, 1 incorrect, 6 unverifiable

Evidence from executions is captured under
`/workspace/runs/review-arms/e8-evidence-pipeline/mfc-deploy/evidence/` (files prefixed `r2-`).
Executions used a locally started Next.js dev server (`npx next dev -p 3400`, cwd
`/workspace/external/cc-review-eval/mfc-deploy`), throwaway Node HTTP stubs on ports 3100/3101
standing in for the Lean verifier, and one temporary Vitest probe (created, run, and deleted).
All servers were killed and the `data/` directory removed afterward; `git status` is clean.

---

## Claim 1: "There is no shared hosted instance and no demo mode."

**Location:** `CLAUDE.md:73`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the absence of a demo-mode feature in this codebase; does not establish anything about hosted instances elsewhere (external world), and does not cover the keyless mock-LLM fallback, which is a distinct documented behavior.

No demo-mode feature, flag, or route exists in the repo (paraphrased — no quote available
because the claim covers absence of code: case-insensitive grep for "demo" across `app/`
matches only an unrelated comment and ReactFlow imports). Flag on the broader reading: the app
does run without any API key and serves canned responses — `app/lib/llm/callLlm.ts:203` warns
`` `[${endpoint}] No API key configured — returning mock response.` `` — so a keyless
deployment behaves demo-like even though no feature named "demo mode" exists. The
"no shared hosted instance" half is about the outside world and is not checkable from the
codebase (paraphrased — no quote available because the claim is about external deployments,
not code).

**Evidence:** `app/lib/llm/callLlm.ts:202-211`

---

## Claim 2: "There is no in-browser BYO-key flow; keys live in the Vercel project's environment variables (or `.env.local` in dev)."

**Location:** `CLAUDE.md:75`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers where API keys are read (server-side `process.env` only) and the absence of any client-side key input; does not establish trust-boundary properties beyond key handling.

API keys are read exclusively from server-side environment variables:

```ts
// app/lib/llm/callLlm.ts:112-113
const anthropicKey = process.env.ANTHROPIC_API_KEY;
const openRouterKey = process.env.OPENROUTER_API_KEY;
```

The same pattern appears at `app/lib/llm/streamLlm.ts:87-88`. No client component collects or
stores an API key (paraphrased — no quote available because the claim covers absence of code:
grepping `app/components` and `app/hooks` for key-related identifiers surfaces only
localStorage keys for workspace/session persistence, e.g. `useWorkspaceSessions.ts`, none
holding provider credentials). The `.env.local` half is corroborated by the mock-fallback
warning text, which instructs `` `add ANTHROPIC_API_KEY or OPENROUTER_API_KEY to .env.local` ``
(`app/lib/llm/callLlm.ts:203`).

**Evidence:** `app/lib/llm/callLlm.ts:112-113`, `app/lib/llm/callLlm.ts:203`, `app/lib/llm/streamLlm.ts:87-88`

---

## Claim 3a: "The Lean verifier is a separate Dockerized service"

**Location:** `CLAUDE.md:76`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence and packaging of the verifier as a separate Docker service; does not establish that the built image works (see Claim 9a).

The verifier lives in its own directory with a Dockerfile and is wired as a compose service:

```yaml
# docker-compose.yml:1-8
services:
  lean-verifier:
    build:
      context: ./verifier
      dockerfile: Dockerfile
    ports:
      - "3100:3100"
```

`verifier/server.ts` defines the HTTP surface: `app.get("/health", ...)`
(`verifier/server.ts:77`), `app.post("/verify", ...)` (`verifier/server.ts:86`), and
`const PORT = process.env.PORT ?? 3100;` (`verifier/server.ts:9`).

**Evidence:** `docker-compose.yml:1-16`, `verifier/server.ts:9`, `verifier/server.ts:77-86`, `verifier/Dockerfile:1-28`

---

## Claim 3b: "…and cannot run inside a Vercel Function."

**Location:** `CLAUDE.md:76`
**Type:** Architectural
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers only the assertion about the Vercel Functions runtime; the Docker packaging that motivates it is established in Claim 3a.

This is a claim about the Vercel platform's capabilities, not about this codebase. The verifier
requires a Docker build that installs a Lean toolchain — `verifier/Dockerfile:27` runs
`curl https://elan.lean-lang.org/elan-init.sh -sSf | bash -s -- --default-toolchain none -y` —
which is consistent with the claim, but whether Vercel Functions can or cannot host such a
workload is a property of an external platform that cannot be established from this repo.
Verifying it would require deploying to Vercel or citing Vercel's runtime documentation
(paraphrased — no quote available because the claim's subject is an external platform, not
code in this repo).

**Evidence:** `verifier/Dockerfile:1-28`

---

## Claim 4a: "When `LEAN_VERIFIER_URL` is unset … `app/api/verification/lean/route.ts` falls back to a mock `{ valid: true, mock: true }` response."

**Location:** `CLAUDE.md:76`
**Type:** Behavioral / Configuration
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the route's behavior when the env var is unset; does not dispute that unset deployments on Vercel will in practice receive the mock (the default `localhost:3100` is unreachable there) — the refuted part is the stated mechanism.

Unset does not trigger the mock fallback. Unset substitutes a default URL, and the mock is
returned only when the fetch to that URL fails:

```ts
// app/api/verification/lean/route.ts:3-4
const LEAN_VERIFIER_URL =
  process.env.LEAN_VERIFIER_URL ?? "http://localhost:3100";
```

```ts
// app/api/verification/lean/route.ts:37-40
} catch {
  // Service unavailable — fall back to mock
  return NextResponse.json({ valid: true, mock: true });
}
```

Executed refutation: with the dev server started with `LEAN_VERIFIER_URL` unset and a stub
service listening on the default port 3100, the route returned the stub's real response —
`{"valid":false,"errors":"stub-verifier-real-response","url":"/verify"}` — not the mock.
Command: `curl -s -X POST http://localhost:3400/api/verification/lean -H "Content-Type:
application/json" -d '{"leanCode":"theorem t : True := trivial"}'`, cwd
`/workspace/external/cc-review-eval/mfc-deploy`, exit code 0, 2026-08-18T06:14:24Z. A reader
acting on the claim as written (e.g., expecting mock behavior in dev with the env var unset
while the Docker verifier happens to be running — the exact workflow README documents) would
be misled: they would get real verification, not the mock.

**Evidence:** `app/api/verification/lean/route.ts:3-4`, `app/api/verification/lean/route.ts:37-40`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-deploy/evidence/r2-e2-unset-stubverifier.txt`

---

## Claim 4b: "When `LEAN_VERIFIER_URL` is … unreachable, `app/api/verification/lean/route.ts` falls back to a mock `{ valid: true, mock: true }` response."

**Location:** `CLAUDE.md:76`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fetch-failure path of the route (connection refused, both with the default URL and an explicitly set URL); does not cover non-network failures such as the verifier returning HTTP errors, which are passed through, not mocked (`app/api/verification/lean/route.ts:32-34`).

The catch-all around the fetch returns the mock (quoted in Claim 4a,
`app/api/verification/lean/route.ts:37-40`). Executed twice:

- E1 — env var unset, nothing listening on the default port. Command: `curl -s -X POST
  http://localhost:3400/api/verification/lean -H "Content-Type: application/json" -d
  '{"leanCode":"theorem t : True := trivial"}'`, cwd
  `/workspace/external/cc-review-eval/mfc-deploy`, exit code 0, 2026-08-18T06:14:06Z.
  Response: `{"valid":true,"mock":true}`.
- E3 — `LEAN_VERIFIER_URL=http://127.0.0.1:3101` set with nothing listening. Same command,
  exit code 0, 2026-08-18T06:16:02Z. Response: `{"valid":true,"mock":true}`.

**Evidence:** `app/api/verification/lean/route.ts:17-40`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-deploy/evidence/r2-e1-unset-noverifier.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-deploy/evidence/r2-e3-set-unreachable.txt`

---

## Claim 5: "This is a known silent-pass behavior — `useFormalizationPipeline` treats it as `valid` and there is currently no 'verifier offline' UI state."

**Location:** `CLAUDE.md:76`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the client-side handling of the mock response in `verifyLean` and `useFormalizationPipeline`, and the absence of an offline value in the status types; does not cover every panel's rendering of the status.

The client fetch wrapper discards the `mock` field entirely:

```ts
// app/lib/formalization/api.ts:109-110
const data = await res.json();
return { valid: Boolean(data.valid), errors: (data.errors as string | undefined) ?? "" };
```

The pipeline maps that boolean straight to UI status:

```ts
// app/hooks/useFormalizationPipeline.ts:140-141
const { valid, errors } = await verifyLean(fullCode);
const vStatus = valid ? "valid" as const : "invalid" as const;
```

So a mock `{valid: true}` becomes `verificationStatus: "valid"`. No offline state exists in
the type:

```ts
// app/lib/types/session.ts:1
export type VerificationStatus = "none" | "verifying" | "valid" | "invalid";
```

No component or hook references a verifier-offline concept (paraphrased — no quote available
because the claim covers absence of code: grep for "offline"/"unavailable" in `app/components`
and `app/hooks` matches only analytics-persistence comments in `useAnalytics.ts`).

**Evidence:** `app/lib/formalization/api.ts:103-111`, `app/hooks/useFormalizationPipeline.ts:121-124`, `app/hooks/useFormalizationPipeline.ts:140-145`, `app/lib/types/session.ts:1`

---

## Claim 6: "The LLM cache and analytics log write to the local filesystem in dev."

**Location:** `CLAUDE.md:77`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both write paths (`data/analytics.jsonl` and `data/cache/<hash>.json` under `process.cwd()`); does not establish behavior on Vercel (see Claims 7 and 17b).

Both stores resolve under the working directory:

```ts
// app/lib/analytics/persist.ts:5-6
const DATA_DIR = join(process.cwd(), "data");
const FILE_PATH = join(DATA_DIR, "analytics.jsonl");
```

```ts
// app/lib/llm/cache.ts:6
const CACHE_DIR = join(process.cwd(), "data", "cache");
```

Executed, analytics half (E5): with no API keys configured, `POST /api/edit/inline` against
the dev server took the mock-LLM path and created `data/analytics.jsonl` containing
`{"id":"…","endpoint":"edit/inline","provider":"mock",…}` where no `data/` directory existed
before the call. Command: `curl -s -X POST http://localhost:3400/api/edit/inline -H
"Content-Type: application/json" -d '{"fullText":"hello world","selection":{"start":0,"end":5,
"text":"hello"},"instruction":"capitalize"}'`, cwd
`/workspace/external/cc-review-eval/mfc-deploy`, exit code 0, 2026-08-18T06:16:27Z.

Executed, cache half (E6): a temporary Vitest probe calling `setCachedResult` from
`app/lib/llm/cache.ts` confirmed `data/cache/<hash>.json` was written and round-tripped
through `getCachedResult` (assertions `existsSync(filePath) → true` and
`onDisk.text === "probe-text"` passed). Command: `npx vitest run
app/lib/llm/__r2_cfc_cache_write.test.ts`, cwd `/workspace/external/cc-review-eval/mfc-deploy`,
exit code 1, 2026-08-18T06:17:42Z. Note on the exit code: the only failing assertion was the
probe's own cleanup step, which called `removeCachedResult(hash)` — the real signature takes
`(model, systemPrompt, userContent, maxTokens)` (`app/lib/llm/cache.ts:70-75`) — a probe
authoring error, not a code defect; the three write/read assertions preceding it all passed
(full output in the captured file, probe source inlined there; probe file and `data/` removed
afterward).

**Evidence:** `app/lib/analytics/persist.ts:5-17`, `app/lib/llm/cache.ts:6`, `app/lib/llm/cache.ts:61-68`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-deploy/evidence/r2-e5-analytics-write.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-deploy/evidence/r2-e6-cache-write.txt`

---

## Claim 7: "Vercel Functions can only write to `/tmp` and that lasts only as long as the warm container"

**Location:** `CLAUDE.md:77`
**Type:** Architectural
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers only the external-platform assertion; the codebase-side fact that these writes target `process.cwd()/data` (which would not be `/tmp` on Vercel) is established in Claim 6.

This asserts properties of the Vercel Functions runtime — an external system not exercisable
from this sandbox. Verifying it would require a Vercel deployment or Vercel's platform
documentation (paraphrased — no quote available because the claim's subject is an external
platform, not code in this repo). It is consistent with the code-side finding that the app
writes to `process.cwd()/data` (Claim 6), which would fail or vanish under such a runtime,
but the platform behavior itself cannot be confirmed here.

**Evidence:** `app/lib/analytics/persist.ts:5-6`, `app/lib/llm/cache.ts:6`

---

## Claim 8: Deploy-button link: repository-url `github.com/aditya-adiga/meta-formalism-copilot`, `env=ANTHROPIC_API_KEY`, envLink anchor `#deploy-to-vercel`

**Location:** `README.md:5`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers that the referenced GitHub repo exists (as of check time), that the prompted env var matches the app's required key, and that the envLink anchor resolves within this README; does not establish that the remote repo's contents match this clone (the clone has no `origin` remote configured to compare against).

Executed (E8): `curl -sI https://github.com/aditya-adiga/meta-formalism-copilot -o /dev/null
-w "%{http_code}"`, cwd `/workspace/external/cc-review-eval/mfc-deploy`, exit code 0,
2026-08-18T06:18:39Z — returned HTTP `200`, so the referenced repository exists (true as of
github.com at that time; repositories can be renamed or removed later). The `env=ANTHROPIC_API_KEY`
parameter matches the key the code actually reads (`process.env.ANTHROPIC_API_KEY`,
`app/lib/llm/callLlm.ts:112`, quoted under Claim 2). The envLink anchor target exists:
`## Deploy to Vercel` (`README.md:98`).

**Evidence:** `README.md:5`, `README.md:98`, `app/lib/llm/callLlm.ts:112`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-deploy/evidence/r2-e8-github-repo-exists.txt`

---

## Claim 9a: "When running, submitted Lean code is type-checked by a real Lean 4 installation."

**Location:** `README.md:64`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the end-to-end guarantee that a running verifier performs real Lean 4 type-checking; does not dispute the static structure, which is consistent with the claim.

This is an executable guarantee (documented dev workflow: `docker compose up` then real
type-checking), so under the mandatory-execution rule the verdict is capped at Unverifiable
from static reading — and execution is blocked: Docker is not available in this sandbox
(`which docker` → "docker not found"), so the verifier image (which installs the Lean
toolchain via `verifier/Dockerfile:27`, quoted under Claim 3b) cannot be built or started.
Static structure is consistent: the compose service, `/verify` endpoint, and Lean toolchain
install all exist (Claim 3a), but "type-checked by a real Lean 4 installation" cannot be
`Verified` without running it.

**Evidence:** `verifier/server.ts:86`, `verifier/Dockerfile:1-28`, `docker-compose.yml:1-16`

---

## Claim 9b: "When the service is not reachable, the verification API route returns a mock `{ valid: true, mock: true }` response so the rest of the app keeps working — note that this means generated Lean code is reported as valid without actually being type-checked."

**Location:** `README.md:64`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the unreachable→mock route behavior and the resulting valid-without-type-checking outcome; "the rest of the app keeps working" is covered only to the extent exercised (page load and one LLM route — see Claim 11).

The unreachable→mock mechanism is the fetch catch block
(`app/api/verification/lean/route.ts:37-40`, quoted under Claim 4a), executed as E1 and E3
(provenance under Claim 4b): both unreachable configurations returned
`{"valid":true,"mock":true}`. The "reported as valid without actually being type-checked"
consequence follows from the client mapping `valid: true` straight to the `"valid"` UI status
while discarding the `mock` flag (`app/lib/formalization/api.ts:109-110` and
`app/hooks/useFormalizationPipeline.ts:140-141`, quoted under Claim 5).

**Evidence:** `app/api/verification/lean/route.ts:37-40`, `app/lib/formalization/api.ts:109-110`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-deploy/evidence/r2-e1-unset-noverifier.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-deploy/evidence/r2-e3-set-unreachable.txt`

---

## Claim 10: "The Next.js route reads `LEAN_VERIFIER_URL` from the environment (defaults to `http://localhost:3100`). When the verifier is unreachable, the route falls back to the mock response described above."

**Location:** `README.md:88`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the env read, the default value's runtime effect, and the unreachable→mock fallback; does not cover the verifier's own `PORT` configuration.

The constant is read with the documented default:

```ts
// app/api/verification/lean/route.ts:3-4
const LEAN_VERIFIER_URL =
  process.env.LEAN_VERIFIER_URL ?? "http://localhost:3100";
```

Executed, default's runtime effect (E2): env unset + stub on `localhost:3100` → route
returned the stub's response, proving the default URL is what the route contacts (provenance
under Claim 4a). Executed, env pointing (E4): `LEAN_VERIFIER_URL=http://127.0.0.1:3101` with
a stub on 3101 → route returned `{"valid":false,"errors":"stub-3101-response"}`. Command:
`curl -s -X POST http://localhost:3400/api/verification/lean -H "Content-Type:
application/json" -d '{"leanCode":"theorem t : True := trivial"}'`, cwd
`/workspace/external/cc-review-eval/mfc-deploy`, exit code 0, 2026-08-18T06:16:16Z. The
unreachable→mock half is E3 (provenance under Claim 4b).

**Evidence:** `app/api/verification/lean/route.ts:3-4`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-deploy/evidence/r2-e2-unset-stubverifier.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-deploy/evidence/r2-e4-set-stub3101.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-deploy/evidence/r2-e3-set-unreachable.txt`

---

## Claim 11: "The rest of the app keeps working without the verifier. Lean code can still be generated and edited; the type-check step returns the mock-valid response described above."

**Location:** `README.md:96`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the type-check step's mock-valid response (fully executed) and app liveness without the verifier as exercised (root page 200, one LLM edit route functioning); does not establish that every panel and route is unaffected, and Lean *generation* specifically was not exercised (it shares the verifier-independent LLM path).

Executed: with no verifier running, the root page served HTTP 200, the verification route
returned `{"valid":true,"mock":true}` (E1, provenance under Claim 4b), and an LLM route
(`/api/edit/inline`) functioned end-to-end (E5, provenance under Claim 6). The Lean generation
route depends on the LLM path, not the verifier (paraphrased — no quote available because the
independence is inferred from multiple call sites: `app/api/formalization/lean/route.ts` calls
`callLlm`/streaming helpers and never references `LEAN_VERIFIER_URL`, which greps only in the
two verification/explanation routes and LLM test files).

**Evidence:** `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-deploy/evidence/r2-e1-unset-noverifier.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-deploy/evidence/r2-e5-analytics-write.txt`, `app/api/formalization/lean/route.ts:104`

---

## Claim 12: "Click the 'Deploy with Vercel' button at the top of this README. Vercel clones the repo, prompts for the required env var, and deploys."

**Location:** `README.md:100`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers only the described behavior of Vercel's clone-deploy flow; the button URL's parameters and repo existence are covered by Claim 8.

This describes the behavior of Vercel's hosted deploy flow — an external service that cannot
be exercised from this sandbox without a Vercel account and a real deployment (paraphrased —
no quote available because the claim's subject is an external service, not code in this repo).
The URL's `env=ANTHROPIC_API_KEY&envDescription=…` parameters (`README.md:5`) are the standard
inputs to that flow and are consistent with the described prompt, but the flow itself was not
run.

**Evidence:** `README.md:5`

---

## Claim 13: "`OPENROUTER_API_KEY` … Acts as a fallback LLM provider when `ANTHROPIC_API_KEY` is unset. **Privacy note:** prompts (including your source material) are sent to OpenRouter when this path is used."

**Location:** `README.md:114`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers provider selection order (Anthropic → OpenRouter → mock) and that request bodies containing the prompts go to openrouter.ai; does not establish behavior with a valid OpenRouter key beyond the request being sent (the test key was rejected 401), and notes the fallback engages only for routes that pass an `openRouterModel` — which all LLM routes do.

Selection order in code:

```ts
// app/lib/llm/callLlm.ts:114-118
const effectiveModel = anthropicKey
  ? (anthropicModel ?? DEFAULT_ANTHROPIC_MODEL)
  : (openRouterKey && openRouterModel)
    ? openRouterModel
    : "mock";
```

The OpenRouter branch sends the prompts in the request body:

```ts
// app/lib/llm/callLlm.ts:170-175
body: JSON.stringify({
  model: openRouterModel,
  messages: [
    { role: "system", content: systemPrompt },
    { role: "user", content: userContent },
  ],
```

Every LLM API route passes an `openRouterModel` (paraphrased — no quote available because the
invariant is inferred from multiple call sites: grep shows `openRouterModel: OPENROUTER_MODEL`
in all seven `app/api/**` LLM routes plus `app/lib/formalization/artifactRoute.ts`). Executed
(E7): dev server started with `ANTHROPIC_API_KEY` unset and
`OPENROUTER_API_KEY=sk-or-v1-fake-key-for-path-test`; `POST /api/edit/inline` returned
`{"error":"OpenRouter API error: 401","details":"…\"User not found.\"…"}` with HTTP 502 and
the server log line `[edit/inline] OpenRouter error: 401` — i.e., the request was actually
sent to openrouter.ai (which authenticated and rejected the fake key), not the mock path.
Command: `curl -s -w "\nHTTP %{http_code}" -X POST http://localhost:3400/api/edit/inline -H
"Content-Type: application/json" -d '{"fullText":"hello world","selection":{"start":0,"end":5,
"text":"hello"},"instruction":"capitalize"}'`, cwd
`/workspace/external/cc-review-eval/mfc-deploy`, exit code 0, 2026-08-18T06:17:20Z. True as of
openrouter.ai's API at that time.

**Evidence:** `app/lib/llm/callLlm.ts:114-118`, `app/lib/llm/callLlm.ts:162-178`, `app/lib/llm/streamLlm.ts:117-137`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-deploy/evidence/r2-e7-openrouter-fallback-path.txt`

---

## Claim 14a: "`LEAN_VERIFIER_URL` … Points the Lean type-check API at a running verifier."

**Location:** `README.md:115`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that setting the env var redirects the verification route to the given URL; does not cover the second route that reads the same variable for error explanations (`app/api/explanation/lean-error/route.ts`), which behaves analogously but was not exercised.

Executed (E4): with `LEAN_VERIFIER_URL=http://127.0.0.1:3101` and a stub listening there, the
route returned the stub's response `{"valid":false,"errors":"stub-3101-response"}` (full
provenance under Claim 10). The mechanism is the env read at
`app/api/verification/lean/route.ts:3-4` (quoted under Claim 10).

**Evidence:** `app/api/verification/lean/route.ts:3-4`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-deploy/evidence/r2-e4-set-stub3101.txt`

---

## Claim 14b: "The verifier is a separate Docker service … and cannot run on Vercel; host it elsewhere … and set this to its URL."

**Location:** `README.md:115`
**Type:** Architectural
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the "cannot run on Vercel" platform assertion; the "separate Docker service" half is established in Claim 3a and takes that claim's Verified verdict.

Same platform assertion as Claim 3b: the Docker packaging is real
(`docker-compose.yml:1-8`, quoted under Claim 3a), but whether Vercel can host it is a
property of the external platform not checkable from this repo (paraphrased — no quote
available because the claim's subject is an external platform, not code in this repo). Per
the most-severe-part rule the compound sentence carries Unverifiable, driven by the
"cannot run on Vercel" part.

**Evidence:** `docker-compose.yml:1-16`, `verifier/Dockerfile:1-28`

---

## Claim 14c: "When unset, Lean code is generated but the type-check step returns the mock-valid response."

**Location:** `README.md:115`
**Type:** Behavioral / Configuration
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the unset case in this table's stated context (a Vercel deployment); does not hold as a general statement about the unset case in dev.

In the table's context (Vercel dashboard env vars), the conclusion holds: unset resolves to
the default `http://localhost:3100` (`app/api/verification/lean/route.ts:3-4`, quoted under
Claim 10), nothing listens on localhost inside the deployment, the fetch fails, and the mock
is returned — the unreachable→mock leg is executed-verified (E1/E3, provenance under Claim
4b). The imprecision: "when unset → mock" is not the actual mechanism — E2 (provenance under
Claim 4a) showed that unset with a service on the default port returns real verification. The
precise version: "When unset, the route targets `http://localhost:3100`; on Vercel that is
unreachable, so the type-check step returns the mock-valid response." Both mechanism-in-context
and conclusion are right, so this stays Mostly accurate rather than Incorrect — unlike
CLAUDE.md:76 (Claim 4a), which states "unset or unreachable → falls back" as the route's
general mechanism.

**Evidence:** `app/api/verification/lean/route.ts:3-4`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-deploy/evidence/r2-e1-unset-noverifier.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-deploy/evidence/r2-e2-unset-stubverifier.txt`

---

## Claim 15: "**Lean verification** runs only when `LEAN_VERIFIER_URL` points at a separately hosted verifier (see above)."

**Location:** `README.md:119`
**Type:** Behavioral / Configuration
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the "Limitations on Vercel" context where the statement's conclusion holds; does not hold as a strict "only when" about the route in general.

In the Vercel context this is the practical truth: without the env var, the route targets the
unreachable default and mocks (E1, provenance under Claim 4b); with it pointing at a reachable
verifier, real responses flow through (E4, provenance under Claim 10). Strictly, "only when"
is imprecise: real verification also runs when the variable is unset and a service happens to
listen on the default `localhost:3100` (E2, provenance under Claim 4a) — impossible inside a
Vercel Function but the reason this is "mostly" rather than exactly accurate. The precise
version: "on Vercel, Lean verification runs only when `LEAN_VERIFIER_URL` points at a
reachable verifier."

**Evidence:** `app/api/verification/lean/route.ts:3-4`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-deploy/evidence/r2-e2-unset-stubverifier.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-deploy/evidence/r2-e4-set-stub3101.txt`

---

## Claim 16a: "**Analytics history** is written to the local filesystem …"

**Location:** `README.md:120`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the analytics write path (`data/analytics.jsonl` under `process.cwd()`); does not cover the read path or the analytics panel UI.

The write path is `appendFileSync(FILE_PATH, …)` where `FILE_PATH` is
`join(process.cwd(), "data", "analytics.jsonl")` (`app/lib/analytics/persist.ts:5-6` and
`:14-17`, quoted under Claim 6). Executed as E5: a keyless LLM call created
`data/analytics.jsonl` with a `"provider":"mock"` entry (full provenance under Claim 6).

**Evidence:** `app/lib/analytics/persist.ts:5-17`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-deploy/evidence/r2-e5-analytics-write.txt`

---

## Claim 16b: "… and does not persist across Vercel function invocations; treat the analytics panel as dev-only."

**Location:** `README.md:120`
**Type:** Architectural
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the Vercel-persistence assertion; the local-write mechanism it rests on is established in Claim 16a.

Whether writes to `process.cwd()/data` survive across invocations is a property of the Vercel
Functions runtime, not of this codebase, and cannot be exercised from this sandbox
(paraphrased — no quote available because the claim's subject is an external platform, not
code in this repo). It is consistent with the code writing to an ephemeral working directory
rather than any storage backend (Claim 16a), but the platform behavior itself was not
verified.

**Evidence:** `app/lib/analytics/persist.ts:5-6`

---

## Claims Requiring Attention

### Incorrect
- **Claim 4a** (`CLAUDE.md:76`): "unset → falls back to mock" misstates the mechanism — unset substitutes the default `http://localhost:3100` and the mock is returned only on fetch failure; with a verifier on the default port and the var unset, real verification runs (executed, E2). Fix: say the route targets the default URL when unset and mocks only when that URL is unreachable.

### Stale
- (none)

### Mostly Accurate
- **Claim 14c** (`README.md:115`): "When unset … mock-valid" is true on Vercel only because the default `localhost:3100` is unreachable there; tighten to name the default-URL mechanism.
- **Claim 15** (`README.md:119`): "runs only when `LEAN_VERIFIER_URL` points at a … verifier" — strictly, unset-plus-reachable-default also runs real verification (executed, E2); tighten with "on Vercel".

### Unverifiable
- **Claim 3b** (`CLAUDE.md:76`): "cannot run inside a Vercel Function" — external-platform property; needs a Vercel deployment attempt or platform docs.
- **Claim 7** (`CLAUDE.md:77`): Vercel `/tmp`-only, warm-container lifetime — external-platform property.
- **Claim 9a** (`README.md:64`): real Lean 4 type-checking when the verifier runs — executable guarantee, blocked: Docker is not available in the sandbox, so the verifier image cannot be built/started.
- **Claim 12** (`README.md:100`): Vercel clone/prompt/deploy flow — external service, not exercisable here.
- **Claim 14b** (`README.md:115`): "cannot run on Vercel" — external-platform property.
- **Claim 16b** (`README.md:120`): non-persistence across Vercel invocations — external-platform property.
