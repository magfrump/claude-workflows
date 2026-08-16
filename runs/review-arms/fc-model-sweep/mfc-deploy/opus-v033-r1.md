# Code Fact-Check Report

Commit: 4329d6e

**Repository:** `/workspace/external/cc-review-eval/mfc-deploy`
**Scope:** `git diff main...review` — `CLAUDE.md`, `README.md`, plus commit messages in `git log main..review` (`1859488`, `4329d6e`)
**Checked:** 2026-08-15
**Total claims checked:** 23
**Summary:** 14 verified, 3 mostly accurate, 0 stale, 4 incorrect, 2 unverifiable

---

## Claim 1: "There is no shared hosted instance and no demo mode."

**Location:** `CLAUDE.md:73`
**Type:** Architectural / Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium

The "no shared hosted instance" half is not contradicted by anything in the repo; there is no deploy target, tenant identifier, or hosted-instance configuration (paraphrased — no quote available because the claim covers absence of code: `rg` for `vercel.json` returns no such file, and the only environment reads in the repo are `ANTHROPIC_API_KEY`, `OPENROUTER_API_KEY`, `LEAN_VERIFIER_URL`, `LEAN_PROJECT_DIR`, `DEV_URL`, `PORT`, `SIMULATE_STREAM_FROM_CACHE`).

The "no demo mode" half is imprecise: the LLM layer has an explicit keyless mock provider that serves canned artifact responses when neither API key is set, which functions as a demo path:

```ts
// app/lib/llm/callLlm.ts:202-211
  // Mock fallback — caller provides its own mock text
  console.warn(`[${endpoint}] No API key configured — returning mock response.\n\n To generate real responses, add ANTHROPIC_API_KEY or OPENROUTER_API_KEY to .env.local`);
  const usage: LlmCallUsage = {
    provider: "mock",
    model: "mock",
```

and the artifact route substitutes canned content for that provider:

```ts
// app/lib/formalization/artifactRoute.ts:91-92
    if (usage.provider === "mock") {
      return NextResponse.json({ [config.responseKey]: config.mockResponse(body.sourceText) });
```

A precise version would say there is no *hosted* demo instance, while noting that a keyless local/deployed copy still serves mock responses rather than erroring.

**Evidence:** `CLAUDE.md:73`, `app/lib/llm/callLlm.ts:202-220`, `app/lib/formalization/artifactRoute.ts:38`, `app/lib/formalization/artifactRoute.ts:91-92`

---

## Claim 2: "There is no in-browser BYO-key flow; keys live in the Vercel project's environment variables (or `.env.local` in dev)."

**Location:** `CLAUDE.md:75`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High

No client-side component or hook accepts, stores, or forwards an API key (paraphrased — no quote available because the claim covers absence of code: a case-insensitive `rg` for `apikey|api_key|api key` across `app/components` and `app/hooks`, excluding tests, returns zero matches).

Keys are read only server-side from the process environment:

```ts
// app/lib/llm/callLlm.ts:112-113
  const anthropicKey = process.env.ANTHROPIC_API_KEY;
  const openRouterKey = process.env.OPENROUTER_API_KEY;
```

The same server-side-only pattern holds in the streaming client (`app/lib/llm/streamLlm.ts:87-88`), which is the only other key reader in the repo (paraphrased — no quote available because the assertion is an inventory over all `process.env.*` reads in the repo rather than a single snippet).

**Evidence:** `app/lib/llm/callLlm.ts:112-113`, `app/lib/llm/streamLlm.ts:87-88`

---

## Claim 3: "The Lean verifier is a separate Dockerized service and cannot run inside a Vercel Function."

**Location:** `CLAUDE.md:76`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** Medium

The verifier is defined as a separately built container exposing port 3100:

```yaml
# docker-compose.yml:3-11
    build:
...
      - "3100:3100"
...
      - PORT=3100
...
      test: ["CMD", "curl", "-f", "http://localhost:3100/health"]
```

The Next.js side reaches it only over HTTP, never in-process:

```ts
// app/api/verification/lean/route.ts:21
    const res = await fetch(`${LEAN_VERIFIER_URL}/verify`, {
```

Confidence is Medium rather than High because "cannot run inside a Vercel Function" is partly a platform assertion (a Lean 4 toolchain image is not a JS function runtime) that static analysis of this repo can support but not fully settle.

**Evidence:** `docker-compose.yml:3-11`, `app/api/verification/lean/route.ts:3-4`, `app/api/verification/lean/route.ts:21`

---

## Claim 4a: "When `LEAN_VERIFIER_URL` is unset ... `app/api/verification/lean/route.ts` falls back to a mock `{ valid: true, mock: true }` response."

**Location:** `CLAUDE.md:76`
**Type:** Behavioral / Configuration
**Verdict:** Incorrect
**Confidence:** High

The unset case does not trigger the mock. The module substitutes a default URL, so an unset variable produces a real request to `http://localhost:3100/verify`:

```ts
// app/api/verification/lean/route.ts:3-4
const LEAN_VERIFIER_URL =
  process.env.LEAN_VERIFIER_URL ?? "http://localhost:3100";
```

```ts
// app/api/verification/lean/route.ts:21-26
    const res = await fetch(`${LEAN_VERIFIER_URL}/verify`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ leanCode }),
      signal: controller.signal,
    });
```

With the Docker verifier running locally (the documented dev setup, which binds `3100:3100` per `docker-compose.yml:7`), an unset `LEAN_VERIFIER_URL` yields **real type-checking**, not the mock. The mock is reached only via the `catch` block, i.e. on fetch failure/timeout. A reader acting on this claim — expecting mock behavior in tests, or debugging why verification is real despite an unset variable — is misled. This claim also splits from Claim 4b on verdict; the README's own Configuration line (Claim 9) documents the default correctly, so the two documents disagree.

**Evidence:** `app/api/verification/lean/route.ts:3-4`, `app/api/verification/lean/route.ts:17-40`, `docker-compose.yml:7`, `README.md:88`

---

## Claim 4b: "When `LEAN_VERIFIER_URL` is ... unreachable, `app/api/verification/lean/route.ts` falls back to a mock `{ valid: true, mock: true }` response."

**Location:** `CLAUDE.md:76`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

Any thrown error from the fetch (connection refused, DNS failure, or the 35s abort) lands in the catch, which returns exactly the claimed shape:

```ts
// app/api/verification/lean/route.ts:37-40
  } catch {
    // Service unavailable — fall back to mock
    return NextResponse.json({ valid: true, mock: true });
  }
```

The abort path that makes a hung verifier "unreachable" is wired to the same try block:

```ts
// app/api/verification/lean/route.ts:17-19
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);
```

**Evidence:** `app/api/verification/lean/route.ts:5`, `app/api/verification/lean/route.ts:17-19`, `app/api/verification/lean/route.ts:37-40`

---

## Claim 5: "This is a known silent-pass behavior — `useFormalizationPipeline` treats it as `valid` and there is currently no 'verifier offline' UI state."

**Location:** `CLAUDE.md:76`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High

The client helper coerces `data.valid` and discards the `mock` flag entirely:

```ts
// app/lib/formalization/api.ts:109-110
  const data = await res.json();
  return { valid: Boolean(data.valid), errors: (data.errors as string | undefined) ?? "" };
```

The pipeline hook consumes that boolean and maps it to a two-state status:

```ts
// app/hooks/useFormalizationPipeline.ts:140-142
    const { valid, errors } = await verifyLean(fullCode);
    const vStatus = valid ? "valid" as const : "invalid" as const;
    const vErrors = valid ? "" : errors || "Verification failed";
```

The status type admits no offline/mock member:

```ts
// app/lib/types/persistence.ts:22
  verificationStatus: "none" | "valid" | "invalid";
```

No component or hook reads a `mock` field (paraphrased — no quote available because the claim covers absence of code: `rg -n "mock"` over `app/components`, `app/hooks`, and `app/lib` excluding tests returns hits only in the LLM provider layer — `callLlm.ts`, `streamLlm.ts`, `artifactRoute.ts`, `transformSseStream.ts`, `types/analytics.ts` — and none in verification UI).

**Evidence:** `app/lib/formalization/api.ts:103-111`, `app/hooks/useFormalizationPipeline.ts:140-142`, `app/lib/types/persistence.ts:22`

---

## Claim 6a: "The LLM cache and analytics log write to the local filesystem in dev."

**Location:** `CLAUDE.md:77`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High

Both write through Node `fs` to a directory under the process working directory. Cache:

```ts
// app/lib/llm/cache.ts:6
const CACHE_DIR = join(process.cwd(), "data", "cache");
```

```ts
// app/lib/llm/cache.ts:65-67
  await ensureCacheDir();
  const filePath = join(CACHE_DIR, `${hash}.json`);
  await writeFile(filePath, JSON.stringify(result, null, 2), "utf-8");
```

Analytics:

```ts
// app/lib/analytics/persist.ts:5-6
const DATA_DIR = join(process.cwd(), "data");
const FILE_PATH = join(DATA_DIR, "analytics.jsonl");
```

```ts
// app/lib/analytics/persist.ts:14-17
export function appendAnalyticsEntry(entry: AnalyticsEntry): void {
  ensureDir();
  appendFileSync(FILE_PATH, JSON.stringify(entry) + "\n", "utf-8");
}
```

Both are invoked from the LLM call path:

```ts
// app/lib/llm/callLlm.ts:84-95
  try {
    appendAnalyticsEntry({
...
  if (text) {
    try { await setCachedResult(cacheHash, result); } catch { /* cache write failure is non-fatal */ }
```

**Evidence:** `app/lib/llm/cache.ts:6`, `app/lib/llm/cache.ts:61-68`, `app/lib/analytics/persist.ts:5-17`, `app/lib/llm/callLlm.ts:84-96`

---

## Claim 6b: "Vercel Functions can only write to `/tmp` and that lasts only as long as the warm container" (as the account of what happens to the LLM cache and analytics writes on Vercel)

**Location:** `CLAUDE.md:77`
**Type:** Behavioral / Configuration
**Verdict:** Incorrect
**Confidence:** Medium

Read in isolation the sentence states a true platform fact, but in context — a bullet whose subject is "The LLM cache and analytics log" — its natural reading is that these writes land in `/tmp` and survive until the container recycles. Neither writer targets `/tmp`; both target `process.cwd()/data`, which is on the read-only deployment filesystem in a Vercel Function:

```ts
// app/lib/llm/cache.ts:6
const CACHE_DIR = join(process.cwd(), "data", "cache");
```

```ts
// app/lib/analytics/persist.ts:5-6
const DATA_DIR = join(process.cwd(), "data");
const FILE_PATH = join(DATA_DIR, "analytics.jsonl");
```

No code substitutes `/tmp`, `os.tmpdir()`, or an environment-conditional path (paraphrased — no quote available because the claim covers absence of code: `rg` for `/tmp` and `tmpdir` across `app/` returns no matches in either module, and neither module reads `process.env.NODE_ENV` or `VERCEL`).

The practical consequence is therefore stronger than "lasts only as long as the warm container": the writes fail immediately and are swallowed, so nothing is cached or logged even *within* a single warm container. Both call sites discard the error:

```ts
// app/lib/llm/callLlm.ts:91
  } catch { /* persistence failure must not break LLM calls */ }
```

Confidence is Medium because the read-only-filesystem behavior is a platform property outside this codebase; the in-repo, fully checkable part is that the target path is `process.cwd()/data` and never `/tmp`.

**Evidence:** `app/lib/llm/cache.ts:6`, `app/lib/analytics/persist.ts:5-12`, `app/lib/llm/callLlm.ts:84-96`

---

## Claim 7: Deploy button targets `github.com/aditya-adiga/meta-formalism-copilot` with `env=ANTHROPIC_API_KEY` and `envLink` anchor `#deploy-to-vercel`

**Location:** `README.md:5`
**Type:** Reference / Configuration
**Verdict:** Unverifiable
**Confidence:** Medium

The `#deploy-to-vercel` anchor half resolves — the heading exists:

```md
<!-- README.md:98 -->
## Deploy to Vercel
```

and `ANTHROPIC_API_KEY` is the variable the app actually requires first (`app/lib/llm/callLlm.ts:112`, quoted under Claim 2).

The repository URL itself cannot be checked from the codebase: this clone has no configured remote and `package.json` declares only `"name": "nextjs"` (paraphrased — no quote available because the claim covers absence of configuration: `git remote -v` produces no output, and `package.json` contains no `repository` field). Verifying that `aditya-adiga/meta-formalism-copilot` is the correct upstream would require network access to GitHub.

**Evidence:** `README.md:5`, `README.md:98`, `package.json:2`

---

## Claim 8: "When the service is not reachable, the verification API route returns a mock `{ valid: true, mock: true }` response ... generated Lean code is reported as valid without actually being type-checked."

**Location:** `README.md:64`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The unreachable path returns exactly that body (route catch quoted under Claim 4b, `app/api/verification/lean/route.ts:37-40`), and the consumer converts it to a `valid` status without inspecting `mock`:

```ts
// app/lib/formalization/api.ts:110
  return { valid: Boolean(data.valid), errors: (data.errors as string | undefined) ?? "" };
```

```ts
// app/hooks/useFormalizationPipeline.ts:141
    const vStatus = valid ? "valid" as const : "invalid" as const;
```

No type-checking occurs on this path, since the only type-check is performed by the remote verifier the failed `fetch` was trying to reach (`app/api/verification/lean/route.ts:21`, quoted under Claim 3).

**Evidence:** `app/api/verification/lean/route.ts:21`, `app/api/verification/lean/route.ts:37-40`, `app/lib/formalization/api.ts:103-111`, `app/hooks/useFormalizationPipeline.ts:140-142`

---

## Claim 9: "The Next.js route reads `LEAN_VERIFIER_URL` from the environment (defaults to `http://localhost:3100`). When the verifier is unreachable, the route falls back to the mock response described above."

**Location:** `README.md:88`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High

Both halves hold, so no split is warranted. The default:

```ts
// app/api/verification/lean/route.ts:3-4
const LEAN_VERIFIER_URL =
  process.env.LEAN_VERIFIER_URL ?? "http://localhost:3100";
```

matching the compose port binding:

```yaml
# docker-compose.yml:7
      - "3100:3100"
```

The unreachable fallback is the catch block quoted under Claim 4b (`app/api/verification/lean/route.ts:37-40`).

This line is also the correct reconciliation of Claim 4a: the README documents the default substitution that CLAUDE.md's "unset ... falls back to a mock" wording contradicts.

**Evidence:** `app/api/verification/lean/route.ts:3-4`, `app/api/verification/lean/route.ts:37-40`, `docker-compose.yml:7`

---

## Claim 10: "The rest of the app keeps working without the verifier. Lean code can still be generated and edited; the type-check step returns the mock-valid response."

**Location:** `README.md:96`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High

Lean generation runs through a separate route that never contacts the verifier:

```ts
// app/api/formalization/lean/route.ts:104
      openRouterModel: OPENROUTER_MODEL,
```

(the generation route calls the LLM layer only — paraphrased — no quote available because the assertion is about the absence of a verifier call in that module: `rg -n "verifyLean|LEAN_VERIFIER_URL"` matches nothing under `app/api/formalization/`).

The verifier failure is contained inside the verification route's catch and returned as a normal 200 body, so no error propagates to callers:

```ts
// app/api/verification/lean/route.ts:37-40
  } catch {
    // Service unavailable — fall back to mock
    return NextResponse.json({ valid: true, mock: true });
  }
```

**Evidence:** `app/api/verification/lean/route.ts:37-40`, `app/api/formalization/lean/route.ts:104`, `app/lib/formalization/api.ts:103-111`

---

## Claim 11: "`OPENROUTER_API_KEY` — Acts as a fallback LLM provider when `ANTHROPIC_API_KEY` is unset. **Privacy note:** prompts (including your source material) are sent to OpenRouter when this path is used."

**Location:** `README.md:114`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High

The provider chain gates OpenRouter behind the absence of the Anthropic key — the Anthropic branch returns first:

```ts
// app/lib/llm/callLlm.ts:131-134
  if (anthropicKey) {
    const model = anthropicModel ?? DEFAULT_ANTHROPIC_MODEL;
...
```

```ts
// app/lib/llm/callLlm.ts:162
  if (openRouterKey && openRouterModel) {
```

The additional `openRouterModel` conjunct is satisfied in practice: every call site supplies it (paraphrased — no quote available because the assertion is an inventory across call sites: `rg -n "openRouterModel"` shows `openRouterModel: OPENROUTER_MODEL` passed at `app/api/edit/artifact/route.ts:51`, `app/api/refine/context/route.ts:46`, `app/api/edit/inline/route.ts:21`, `app/api/edit/whole/route.ts:29`, `app/api/decomposition/extract/route.ts:116`, `app/api/explanation/lean-error/route.ts:30`, `app/api/formalization/lean/route.ts:104`, `:128`, and `app/lib/formalization/artifactRoute.ts:76`, `:87`).

The privacy note is accurate — the full system prompt and user content go in the request body:

```ts
// app/lib/llm/callLlm.ts:170-177
      body: JSON.stringify({
        model: openRouterModel,
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: userContent },
        ],
```

and the user content embeds the source material verbatim:

```ts
// app/lib/formalization/artifactRoute.ts:21
  parts.push(`[Source Text]\n${req.sourceText}`);
```

**Evidence:** `app/lib/llm/callLlm.ts:112-118`, `app/lib/llm/callLlm.ts:131`, `app/lib/llm/callLlm.ts:162-178`, `app/lib/formalization/artifactRoute.ts:21`, `app/lib/formalization/artifactRoute.ts:74-87`

---

## Claim 12: "`LEAN_VERIFIER_URL` ... When unset, Lean code is generated but the type-check step returns the mock-valid response."

**Location:** `README.md:115`
**Type:** Behavioral / Configuration
**Verdict:** Mostly accurate
**Confidence:** Medium

Scoped to the Vercel deployment this table describes, the stated outcome holds — but by a route the row elides. Unset does not select the mock directly; it selects the localhost default:

```ts
// app/api/verification/lean/route.ts:3-4
const LEAN_VERIFIER_URL =
  process.env.LEAN_VERIFIER_URL ?? "http://localhost:3100";
```

On a Vercel Function nothing listens on that port, so the fetch throws and the catch returns the mock (`app/api/verification/lean/route.ts:37-40`, quoted under Claim 4b) — the conclusion the row states. The claim is only true under this Vercel-scoped reading: in local dev with the compose service up (`docker-compose.yml:7`, quoted under Claim 9), unset yields real type-checking. A precise version would say "when unset, the route falls back to `http://localhost:3100`, which is unreachable on Vercel, so the type-check step returns the mock-valid response."

The companion sentence in the same row — the verifier "is a separate Docker service ... and cannot run on Vercel" — is the same assertion verdicted under Claim 3, and the `#lean-verification-service` anchor it links resolves (`README.md:62`).

**Evidence:** `app/api/verification/lean/route.ts:3-4`, `app/api/verification/lean/route.ts:37-40`, `docker-compose.yml:7`, `README.md:62`

---

## Claim 13: "**Lean verification** runs only when `LEAN_VERIFIER_URL` points at a separately hosted verifier."

**Location:** `README.md:119`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High

Real verification requires a reachable HTTP endpoint at the configured URL; there is no in-process fallback that type-checks:

```ts
// app/api/verification/lean/route.ts:21
    const res = await fetch(`${LEAN_VERIFIER_URL}/verify`, {
```

Every failure to reach it degrades to the mock rather than to a local check (`app/api/verification/lean/route.ts:37-40`, quoted under Claim 4b). No Lean toolchain is invoked from the Next.js process (paraphrased — no quote available because the claim covers absence of code: the only Lean-related environment read outside the route is `LEAN_PROJECT_DIR`, which lives in the containerized verifier service, not in the Next.js app).

**Evidence:** `app/api/verification/lean/route.ts:21`, `app/api/verification/lean/route.ts:37-40`, `docker-compose.yml:3-11`

---

## Claim 14: "**Analytics history** is written to the local filesystem and does not persist across Vercel function invocations."

**Location:** `README.md:120`
**Type:** Behavioral / Configuration
**Verdict:** Incorrect
**Confidence:** Medium

The stated mechanism — written, then lost between invocations — is not what happens. The write targets the deployment's read-only filesystem, not a writable temp location:

```ts
// app/lib/analytics/persist.ts:5-6
const DATA_DIR = join(process.cwd(), "data");
const FILE_PATH = join(DATA_DIR, "analytics.jsonl");
```

```ts
// app/lib/analytics/persist.ts:8-17
function ensureDir() {
  if (!existsSync(DATA_DIR)) {
    mkdirSync(DATA_DIR, { recursive: true });
  }
}

export function appendAnalyticsEntry(entry: AnalyticsEntry): void {
  ensureDir();
  appendFileSync(FILE_PATH, JSON.stringify(entry) + "\n", "utf-8");
}
```

On Vercel the `mkdirSync`/`appendFileSync` call raises `EROFS` rather than succeeding, and the caller swallows it:

```ts
// app/lib/llm/callLlm.ts:84-91
  try {
    appendAnalyticsEntry({
      id: randomUUID(),
      endpoint,
      ...usage,
      timestamp: new Date().toISOString(),
    });
  } catch { /* persistence failure must not break LLM calls */ }
```

So the entry is never written at all — not even within a single invocation — and a reader is misled twice: into believing history exists briefly and is merely non-durable, and into expecting a same-invocation read (`readAnalyticsEntries` at `app/lib/analytics/persist.ts:19-32`, served by `app/api/analytics/route.ts:4-7`) to return the entries just recorded. It returns `[]` because the file never exists. The claim's practical conclusion ("treat the analytics panel as dev-only") is right, but the mechanism it states is refuted, so it keeps the more severe verdict.

Confidence is Medium because the read-only-filesystem premise is a platform property; the in-repo checkable part — the path is `process.cwd()/data` and the failure is silently discarded — is High confidence.

**Evidence:** `app/lib/analytics/persist.ts:5-17`, `app/lib/analytics/persist.ts:19-32`, `app/lib/llm/callLlm.ts:84-91`, `app/lib/llm/callLlm.ts:212-219`, `app/api/analytics/route.ts:4-7`

---

## Claim 15: "corrected the Lean verifier section — the 'falls back to `{ valid: true, mock: true }`' claim is no longer accurate (the route now signals the verifier is offline rather than silently passing)."

**Location:** commit `1859488` message body
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High

At the commit that makes this claim, the route still returns the silently-passing mock and emits no offline signal. Reading the route as of `1859488`:

```ts
// app/api/verification/lean/route.ts @ 1859488:37-40 (via `git show 1859488:app/api/verification/lean/route.ts`)
  } catch {
    // Service unavailable — fall back to mock
    return NextResponse.json({ valid: true, mock: true });
  }
```

The file is byte-identical to `4329d6e`'s version in this region, and neither commit touches any `.ts` file (paraphrased — no quote available because the assertion is about diff contents rather than a snippet: `git diff --name-only main...review` lists only `CLAUDE.md` and `README.md`). The subsequent commit `4329d6e` reverses this description, restoring the mock wording.

**Evidence:** `app/api/verification/lean/route.ts:37-40`, `git show 1859488:app/api/verification/lean/route.ts`, `git diff --name-only main...review`

---

## Claim 16: "Remove `OPENALEX_MAILTO` from the optional env var table; OpenAlex / evidence-search is not on this branch's main yet."

**Location:** commit `4329d6e` message body
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High

Neither the identifier nor the feature exists anywhere in the working tree (paraphrased — no quote available because the claim covers absence of code: `rg -li "OPENALEX|openalex"` over the repo, excluding `node_modules` and `.next`, returns zero files, and `OPENALEX_MAILTO` does not appear among the repo's `process.env.*` reads).

**Evidence:** repo-wide search for `OPENALEX`; `README.md:108-115` (optional env table contains only `OPENROUTER_API_KEY` and `LEAN_VERIFIER_URL`)

---

## Claim 17a: "No code change." / "No code changes."

**Location:** commit `4329d6e` message body; commit `1859488` message body
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High

The branch touches only Markdown (paraphrased — no quote available because the claim is about diff/file structure rather than a snippet: `git diff --name-only main...review` outputs exactly `CLAUDE.md` and `README.md`, and the per-commit diffs contain no source-file paths).

**Evidence:** `git diff --name-only main...review`, `git log main..review`

---

## Claim 17b: "Lint clean; 221/221 tests pass."

**Location:** commit `4329d6e` message body
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** High

This is a runtime assertion about a test-suite execution, not a property readable from source (paraphrased — no quote available because verifying it requires executing tooling rather than reading code). Confirming it would require running the project's lint and test scripts at commit `4329d6e` and comparing the reported pass count to 221; the count is not recorded anywhere in the repository.

**Evidence:** commit `4329d6e` message body; `package.json` scripts section

---

## Claim 18: "Correct `OPENROUTER_API_KEY` description: it's a fallback when `ANTHROPIC_API_KEY` is unset, not per-model routing."

**Location:** commit `4329d6e` message body
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The provider selection is a strict precedence chain keyed on key presence, with no per-model routing table:

```ts
// app/lib/llm/callLlm.ts:114-118
  const effectiveModel = anthropicKey
    ? (anthropicModel ?? DEFAULT_ANTHROPIC_MODEL)
    : (openRouterKey && openRouterModel)
      ? openRouterModel
      : "mock";
```

```ts
// app/lib/llm/callLlm.ts:99
/** Centralized LLM call with Anthropic -> OpenRouter -> mock fallback.
```

The streaming path mirrors it:

```ts
// app/lib/llm/streamLlm.ts:76
 * Provider chain mirrors callLlm(): Anthropic → OpenRouter → mock.
```

**Evidence:** `app/lib/llm/callLlm.ts:99`, `app/lib/llm/callLlm.ts:112-118`, `app/lib/llm/callLlm.ts:131`, `app/lib/llm/callLlm.ts:162`, `app/lib/llm/streamLlm.ts:76`, `app/lib/llm/streamLlm.ts:91-92`

---

## Claim 19: "Each user runs their own deployment with their own `ANTHROPIC_API_KEY` — same trust model as the existing `.env.local` setup."

**Location:** commit `1859488` message body
**Type:** Architectural
**Verdict:** Verified
**Confidence:** Medium

The key is read from the process environment in exactly one way regardless of host, so a Vercel environment variable and a `.env.local` entry reach the same code path:

```ts
// app/lib/llm/callLlm.ts:112
  const anthropicKey = process.env.ANTHROPIC_API_KEY;
```

No per-request, per-user, or per-tenant key resolution exists (paraphrased — no quote available because the claim covers absence of code: the repo contains no request-scoped key lookup — `process.env.ANTHROPIC_API_KEY` appears only in `app/lib/llm/callLlm.ts:112` and `app/lib/llm/streamLlm.ts:87`, both module-level server reads).

**Evidence:** `app/lib/llm/callLlm.ts:112`, `app/lib/llm/streamLlm.ts:87`

---

## Claim 20: "Replace the inaccurate 'verifier offline — proof not checked' claims in CLAUDE.md and README.md with accurate description of the current behavior on this branch (silent mock `{ valid: true, mock: true }` response)."

**Location:** commit `4329d6e` message body (and subject line "accurately describe verifier behavior")
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High

The parenthetical it asserts is correct — the branch's route does return the silent mock:

```ts
// app/api/verification/lean/route.ts:37-40
  } catch {
    // Service unavailable — fall back to mock
    return NextResponse.json({ valid: true, mock: true });
  }
```

The claim of full accuracy is imprecise, however, because the replacement text this commit introduced attaches that mock to an *unset* `LEAN_VERIFIER_URL` as well as an unreachable one (`CLAUDE.md:76`), which the default substitution at `app/api/verification/lean/route.ts:3-4` (quoted under Claim 4a) refutes. The precise version would be "accurately describes the unreachable-verifier behavior."

**Evidence:** `app/api/verification/lean/route.ts:3-4`, `app/api/verification/lean/route.ts:37-40`, `CLAUDE.md:76`

---

## Claims Requiring Attention

### Incorrect
- **Claim 4a** (`CLAUDE.md:76`): "unset `LEAN_VERIFIER_URL` falls back to a mock" — unset substitutes `http://localhost:3100` (`route.ts:3-4`) and can reach a real verifier; the mock is reached only on fetch failure. Scope the sentence to the unreachable case.
- **Claim 6b** (`CLAUDE.md:77`): implies the LLM cache and analytics log write to `/tmp` on Vercel; both write to `process.cwd()/data` (`cache.ts:6`, `persist.ts:5-6`), which is read-only there, so the writes fail outright rather than surviving the warm container.
- **Claim 14** (`README.md:120`): "written to the local filesystem and does not persist across Vercel function invocations" — the write raises `EROFS` and is swallowed (`callLlm.ts:84-91`), so nothing is ever written, even within one invocation. Say the analytics write fails on Vercel.
- **Claim 15** (commit `1859488`): "the route now signals the verifier is offline rather than silently passing" — the route at that commit still returns `{ valid: true, mock: true }` and the commit changed no `.ts` files.

### Stale
- None.

### Mostly Accurate
- **Claim 1** (`CLAUDE.md:73`): "no demo mode" — a keyless mock provider serves canned artifact responses (`callLlm.ts:202-211`, `artifactRoute.ts:91-92`); narrow the claim to "no hosted demo instance."
- **Claim 12** (`README.md:115`): "when unset ... returns the mock-valid response" — true only on Vercel, and via the elided `http://localhost:3100` default; state the default explicitly.
- **Claim 20** (commit `4329d6e`): the mock description is accurate, but the replacement text it introduced also asserts an unset-case mock that the code refutes (see Claim 4a).

### Unverifiable
- **Claim 7** (`README.md:5`): the deploy button's `repository-url` (`aditya-adiga/meta-formalism-copilot`) cannot be checked — the clone has no git remote and `package.json` has no `repository` field; needs network access to GitHub.
- **Claim 17b** (commit `4329d6e`): "Lint clean; 221/221 tests pass" — needs the lint and test scripts executed at `4329d6e` to confirm the count.
