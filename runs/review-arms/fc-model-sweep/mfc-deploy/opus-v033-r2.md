# Code Fact-Check Report

Commit: 4329d6e

**Repository:** `/workspace/external/cc-review-eval/mfc-deploy`
**Scope:** `git diff main...review` — `CLAUDE.md`, `README.md`, plus commit messages in `git log main..review` (`1859488`, `4329d6e`)
**Checked:** 2026-08-15
**Total claims checked:** 26
**Summary:** 15 verified, 2 mostly accurate, 0 stale, 4 incorrect, 5 unverifiable

---

## Claim 1: "each end user clicks the \"Deploy with Vercel\" button in the README and runs their own copy with their own `ANTHROPIC_API_KEY`"

**Location:** `CLAUDE.md:73`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High

The README does carry a Deploy-with-Vercel button, and the clone URL pre-declares `ANTHROPIC_API_KEY` as the prompted environment variable:

```md
<!-- README.md:5 -->
[![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=...&env=ANTHROPIC_API_KEY&envDescription=Anthropic%20API%20key%20...)
```

`ANTHROPIC_API_KEY` is the primary provider key read by the LLM entry point:

```ts
// app/lib/llm/callLlm.ts:112
const anthropicKey = process.env.ANTHROPIC_API_KEY;
```

**Evidence:** `README.md:5`, `README.md:100-106`, `app/lib/llm/callLlm.ts:112`

---

## Claim 2: "There is no in-browser BYO-key flow; keys live in the Vercel project's environment variables (or `.env.local` in dev)."

**Location:** `CLAUDE.md:75`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High

Both provider keys are read only from server-side `process.env` inside server modules:

```ts
// app/lib/llm/callLlm.ts:112-113
const anthropicKey = process.env.ANTHROPIC_API_KEY;
const openRouterKey = process.env.OPENROUTER_API_KEY;
```

```ts
// app/lib/llm/streamLlm.ts:87-88
const anthropicKey = process.env.ANTHROPIC_API_KEY;
const openRouterKey = process.env.OPENROUTER_API_KEY;
```

No client-side key-entry path exists (paraphrased — no quote available because the claim covers the *absence* of code: `rg 'process\.env\.[A-Z_]+' app` returns only the six matches in `app/api/verification/lean/route.ts`, `app/lib/llm/callLlm.ts` and `app/lib/llm/streamLlm.ts`, none of them `NEXT_PUBLIC_`-prefixed; and no `localStorage` hit in `app/` stores or persists an API key — the `localStorage` users are workspace/session persistence modules only).

The mock-fallback warning likewise points users at `.env.local`, not at a UI:

```ts
// app/lib/llm/callLlm.ts:203
console.warn(`[${endpoint}] No API key configured — returning mock response.\n\n To generate real responses, add ANTHROPIC_API_KEY or OPENROUTER_API_KEY to .env.local`);
```

**Evidence:** `app/lib/llm/callLlm.ts:112-113`, `app/lib/llm/callLlm.ts:203`, `app/lib/llm/streamLlm.ts:87-88`

---

## Claim 3a: "The Lean verifier is a separate Dockerized service"

**Location:** `CLAUDE.md:76`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High

The verifier is its own service defined in `docker-compose.yml` with its own build context and Dockerfile:

```yaml
# docker-compose.yml:1-9
services:
  lean-verifier:
    build:
      context: ./verifier
      dockerfile: Dockerfile
    ports:
      - "3100:3100"
    environment:
      - PORT=3100
```

It runs as a standalone HTTP server that shells out to the Lean toolchain:

```ts
// verifier/server.ts:9
const PORT = process.env.PORT ?? 3100;
```

```ts
// verifier/server.ts:164-166
app.listen(PORT, () => {
  console.log(`Lean verifier listening on port ${PORT}`);
});
```

**Evidence:** `docker-compose.yml:1-17`, `verifier/server.ts:9`, `verifier/server.ts:164-166`

---

## Claim 3b: "... and cannot run inside a Vercel Function."

**Location:** `CLAUDE.md:76`
**Type:** Architectural
**Verdict:** Unverifiable
**Confidence:** Medium

This asserts a limitation of an external hosting platform, not a property of the code. The codebase shows only that the verifier is packaged as a Docker image that invokes a Lean toolchain via `execFile`:

```ts
// verifier/server.ts:2
import { execFile } from "child_process";
```

```ts
// verifier/server.ts:131-139
    execFile(
```

Whether Vercel's Function runtime can host that image cannot be determined from static analysis of this repository. Verifying it would require Vercel platform documentation or a deployment attempt.

**Evidence:** `verifier/server.ts:2`, `verifier/server.ts:131-139`, `docker-compose.yml:1-9`

---

## Claim 4a: "When `LEAN_VERIFIER_URL` is unset ... `app/api/verification/lean/route.ts` falls back to a mock `{ valid: true, mock: true }` response."

**Location:** `CLAUDE.md:76`
**Type:** Behavioral / Configuration
**Verdict:** Incorrect
**Confidence:** High

Unset does not by itself produce the mock. The route substitutes a default URL and then issues a real request to it:

```ts
// app/api/verification/lean/route.ts:3-4
const LEAN_VERIFIER_URL =
  process.env.LEAN_VERIFIER_URL ?? "http://localhost:3100";
```

```ts
// app/api/verification/lean/route.ts:21
    const res = await fetch(`${LEAN_VERIFIER_URL}/verify`, {
```

The mock is returned only from the `catch` block, i.e. only when that fetch throws:

```ts
// app/api/verification/lean/route.ts:37-40
  } catch {
    // Service unavailable — fall back to mock
    return NextResponse.json({ valid: true, mock: true });
  }
```

With the variable unset and the shipped compose stack running, the default URL reaches the real verifier — `docker-compose.yml` publishes exactly that port on the host:

```yaml
# docker-compose.yml:6-7
    ports:
      - "3100:3100"
```

So in the documented local-dev configuration (`docker compose up --build`, `LEAN_VERIFIER_URL` unset), verification is real, not mocked. A reader acting on this claim — e.g. assuming mock-valid results whenever the variable is absent, or debugging why type-checking is actually running — is misled. The precise statement is: *when `LEAN_VERIFIER_URL` is unset the route targets `http://localhost:3100`, and falls back to the mock only if that request fails.*

**Evidence:** `app/api/verification/lean/route.ts:3-4`, `app/api/verification/lean/route.ts:21`, `app/api/verification/lean/route.ts:37-40`, `docker-compose.yml:6-7`

---

## Claim 4b: "When `LEAN_VERIFIER_URL` is ... unreachable, `app/api/verification/lean/route.ts` falls back to a mock `{ valid: true, mock: true }` response."

**Location:** `CLAUDE.md:76`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

An unreachable verifier makes `fetch` reject, and the `catch` returns exactly the claimed payload:

```ts
// app/api/verification/lean/route.ts:37-40
  } catch {
    // Service unavailable — fall back to mock
    return NextResponse.json({ valid: true, mock: true });
  }
```

The same `catch` also covers the 35-second abort path, which is the timeout form of unreachability:

```ts
// app/api/verification/lean/route.ts:5
const REQUEST_TIMEOUT_MS = 35_000;
```

```ts
// app/api/verification/lean/route.ts:18-19
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);
```

**Evidence:** `app/api/verification/lean/route.ts:5`, `app/api/verification/lean/route.ts:18-19`, `app/api/verification/lean/route.ts:37-40`

---

## Claim 5: "This is a known silent-pass behavior — `useFormalizationPipeline` treats it as `valid` and there is currently no \"verifier offline\" UI state."

**Location:** `CLAUDE.md:76`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High

The hook branches only on `valid` and never inspects the `mock` flag:

```ts
// app/hooks/useFormalizationPipeline.ts:121-124
      const vStatus = result.valid ? "valid" as const : "invalid" as const;
      ...
      if (result.valid) a.setVerificationErrors("");
```

```ts
// app/hooks/useFormalizationPipeline.ts:140-142
    const { valid, errors } = await verifyLean(fullCode);
    const vStatus = valid ? "valid" as const : "invalid" as const;
    const vErrors = valid ? "" : errors || "Verification failed";
```

The verification status vocabulary is limited to `valid` / `invalid` with no offline state (paraphrased — no quote available because the claim covers the absence of code: `rg '\bmock\b' app/components app/hooks app/lib/api` returns only Vitest `vi.mock(...)` calls in `*.test.tsx` files, so no component or hook reads the `mock` field).

**Evidence:** `app/hooks/useFormalizationPipeline.ts:121-124`, `app/hooks/useFormalizationPipeline.ts:140-142`, `app/hooks/useFormalizationPipeline.ts:162-164`

---

## Claim 6a: "The LLM cache and analytics log write to the local filesystem in dev."

**Location:** `CLAUDE.md:77`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

Both persistence modules write to a `data/` directory under the process working directory. Analytics:

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

LLM cache:

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

That directory is treated as local-only state:

```
# .gitignore:36-37
# local data (analytics + LLM response cache)
/data/
```

**Evidence:** `app/lib/analytics/persist.ts:5-17`, `app/lib/llm/cache.ts:6`, `app/lib/llm/cache.ts:61-68`, `.gitignore:36-37`

---

## Claim 6b: "Vercel Functions can only write to `/tmp` and that lasts only as long as the warm container" (as the account of what happens to this app's cache and analytics writes on Vercel)

**Location:** `CLAUDE.md:77`
**Type:** Behavioral / Configuration
**Verdict:** Incorrect
**Confidence:** Medium

The generic platform sentence is not what the code refutes — the bullet's stated mechanism for *this app's* persistence is. Neither writer targets `/tmp`; both write under `process.cwd()`:

```ts
// app/lib/analytics/persist.ts:5
const DATA_DIR = join(process.cwd(), "data");
```

```ts
// app/lib/llm/cache.ts:6
const CACHE_DIR = join(process.cwd(), "data", "cache");
```

There is no `/tmp` path and no environment-conditional storage root anywhere in the app (paraphrased — no quote available because the claim covers the absence of code: `rg 'writeFile|mkdir|appendFile|createWriteStream|/tmp'` over the repo excluding `node_modules`/`.next` matches only `app/lib/analytics/persist.ts`, `app/lib/llm/cache.ts`, `verifier/server.ts`, and two Markdown files; the two app modules are the ones quoted above, and neither mentions `/tmp`).

By the bullet's own premise that a Vercel Function's filesystem is writable only at `/tmp`, writes to `process.cwd()/data` do not become short-lived warm-container writes — they fail. Both call sites swallow the resulting error:

```ts
// app/lib/llm/callLlm.ts:84-95
  try {
    appendAnalyticsEntry({ ... });
  } catch { /* persistence failure must not break LLM calls */ }
  const result: CallLlmResult = { text, usage, cacheKey };
  if (text) {
    try { await setCachedResult(cacheHash, result); } catch { /* cache write failure is non-fatal */ }
  }
```

The precise statement is: *the cache and analytics log write to `process.cwd()/data`, which is not a writable location in a Vercel Function; those writes throw and are silently swallowed, so nothing is persisted at all — not even for the life of the warm container.* The bullet's practical advice ("don't add features that assume durable filesystem state") still holds, but the mechanism a reader would act on is wrong. Confidence is Medium rather than High because the read-only-ness of `process.cwd()` on Vercel is external platform behavior, not a fact in this repo.

**Evidence:** `app/lib/analytics/persist.ts:5-17`, `app/lib/llm/cache.ts:6`, `app/lib/llm/cache.ts:26-31`, `app/lib/llm/callLlm.ts:84-95`, `app/lib/llm/streamLlm.ts:55-60`

---

## Claim 7: Deploy button target — "repository-url=https://github.com/aditya-adiga/meta-formalism-copilot"

**Location:** `README.md:5`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium

The button URL names a specific GitHub repository, but that reference cannot be checked from inside this checkout: the clone has no remotes configured, and `package.json` carries a generic name (paraphrased — no quote available because the claim is about repository metadata rather than a code snippet: `git remote -v` returns no output, and `grep -n '"name"' package.json` yields `"name": "nextjs"`). Verifying this would need network access to GitHub.

**Evidence:** `README.md:5`, `package.json:2`

---

## Claim 8: "When the service is not reachable, the verification API route returns a mock `{ valid: true, mock: true }` response so the rest of the app keeps working — note that this means generated Lean code is reported as valid without actually being type-checked."

**Location:** `README.md:64`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The unreachable path returns exactly that payload:

```ts
// app/api/verification/lean/route.ts:37-40
  } catch {
    // Service unavailable — fall back to mock
    return NextResponse.json({ valid: true, mock: true });
  }
```

And the consumer maps `valid: true` straight to a `valid` status without checking `mock`:

```ts
// app/hooks/useFormalizationPipeline.ts:140-142
    const { valid, errors } = await verifyLean(fullCode);
    const vStatus = valid ? "valid" as const : "invalid" as const;
    const vErrors = valid ? "" : errors || "Verification failed";
```

The "actually type-checked" contrast is also accurate: the real path is a `lake build` invocation in the verifier service, which the mock bypasses entirely:

```ts
// verifier/server.ts:152-153
          valid: false,
          errors: errorOutput || `lake build exited with code ${execError.code}`,
```

**Evidence:** `app/api/verification/lean/route.ts:37-40`, `app/hooks/useFormalizationPipeline.ts:140-142`, `verifier/server.ts:131-153`

---

## Claim 9: "The Next.js route reads `LEAN_VERIFIER_URL` from the environment (defaults to `http://localhost:3100`). When the verifier is unreachable, the route falls back to the mock response described above."

**Location:** `README.md:88`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High

Both halves match the route. The default:

```ts
// app/api/verification/lean/route.ts:3-4
const LEAN_VERIFIER_URL =
  process.env.LEAN_VERIFIER_URL ?? "http://localhost:3100";
```

The unreachable-only fallback:

```ts
// app/api/verification/lean/route.ts:37-40
  } catch {
    // Service unavailable — fall back to mock
    return NextResponse.json({ valid: true, mock: true });
  }
```

This README line is the precise form of the behavior that `CLAUDE.md:76` (Claim 4a) states incorrectly: here the fallback is conditioned on *unreachable* only, and the default value is stated separately, so the two are correctly reconciled.

**Evidence:** `app/api/verification/lean/route.ts:3-4`, `app/api/verification/lean/route.ts:37-40`

---

## Claim 10: "The rest of the app keeps working without the verifier. Lean code can still be generated and edited; the type-check step returns the mock-valid response described above."

**Location:** `README.md:96`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High

Lean generation is a separate API route from verification, so it is unaffected by verifier availability (paraphrased — no quote available because the claim is about file/route structure rather than a snippet: generation lives at `app/api/formalization/lean/route.ts` and verification at `app/api/verification/lean/route.ts`; the generation route calls `callLlm`/`streamLlm` and never contacts `LEAN_VERIFIER_URL`, whose only reference in `app/` is `app/api/verification/lean/route.ts:4`).

The verification step degrades to the mock rather than erroring:

```ts
// app/api/verification/lean/route.ts:37-40
  } catch {
    // Service unavailable — fall back to mock
    return NextResponse.json({ valid: true, mock: true });
  }
```

**Evidence:** `app/api/verification/lean/route.ts:37-40`, `app/api/formalization/lean/route.ts:104`, `app/api/formalization/lean/route.ts:128`

---

## Claim 11: `ANTHROPIC_API_KEY` listed under "Required environment variable"

**Location:** `README.md:102-106`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High

The key is required for real LLM output, but not for the app to build or serve: `callLlm` falls through to a mock provider when no key is present, and returns a normal result rather than throwing:

```ts
// app/lib/llm/callLlm.ts:202-211
  // Mock fallback — caller provides its own mock text
  console.warn(`[${endpoint}] No API key configured — returning mock response. ...`);
  const usage: LlmCallUsage = {
    provider: "mock",
    model: "mock",
    inputTokens: 0,
    outputTokens: 0,
    costUsd: 0,
    latencyMs: 0,
  };
```

The effective-model resolution also names `"mock"` as a legitimate terminal state:

```ts
// app/lib/llm/callLlm.ts:114-118
  const effectiveModel = anthropicKey
    ? (anthropicModel ?? DEFAULT_ANTHROPIC_MODEL)
    : (openRouterKey && openRouterModel)
      ? openRouterModel
      : "mock";
```

The precise version: `ANTHROPIC_API_KEY` is required for real LLM responses; without it (and without `OPENROUTER_API_KEY`) the deployment still runs and serves mock responses.

**Evidence:** `app/lib/llm/callLlm.ts:114-118`, `app/lib/llm/callLlm.ts:202-220`, `app/lib/llm/streamLlm.ts:87-88`

---

## Claim 12: "`OPENROUTER_API_KEY` — Acts as a fallback LLM provider when `ANTHROPIC_API_KEY` is unset. **Privacy note:** prompts (including your source material) are sent to OpenRouter when this path is used."

**Location:** `README.md:114`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High

The OpenRouter branch is guarded so that it is reached only after the Anthropic branch is skipped, which happens only when `anthropicKey` is falsy:

```ts
// app/lib/llm/callLlm.ts:131-132
  if (anthropicKey) {
    const model = anthropicModel ?? DEFAULT_ANTHROPIC_MODEL;
```

```ts
// app/lib/llm/callLlm.ts:162
  if (openRouterKey && openRouterModel) {
```

The privacy note is accurate: the system prompt and user content are placed in the request body sent to OpenRouter's endpoint:

```ts
// app/lib/llm/callLlm.ts:164-177
    const response = await fetch(OPENROUTER_API_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${openRouterKey}`,
      },
      body: JSON.stringify({
        model: openRouterModel,
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: userContent },
        ],
```

```ts
// app/lib/llm/callLlm.ts:7
export const OPENROUTER_API_URL = "https://openrouter.ai/api/v1/chat/completions";
```

The branch additionally requires the caller to supply `openRouterModel`, but every call site does, so the condition does not narrow the claim in practice (paraphrased — no quote available because the invariant is inferred from ten call sites across seven files: `rg -n 'openRouterModel' app` outside `app/lib/llm` shows `openRouterModel: OPENROUTER_MODEL` passed in `app/api/refine/context/route.ts:46`, `app/api/edit/inline/route.ts:21`, `app/api/edit/whole/route.ts:29`, `app/api/edit/artifact/route.ts:51`, `app/api/explanation/lean-error/route.ts:30`, `app/api/decomposition/extract/route.ts:116`, `app/api/formalization/lean/route.ts:104,128`, and `app/lib/formalization/artifactRoute.ts:76,87` — the complete set of `callLlm`/`streamLlm` callers).

**Evidence:** `app/lib/llm/callLlm.ts:7`, `app/lib/llm/callLlm.ts:131-132`, `app/lib/llm/callLlm.ts:162-177`, `app/lib/llm/streamLlm.ts:87-88`

---

## Claim 13a: "`LEAN_VERIFIER_URL` — The verifier is a separate Docker service ... and cannot run on Vercel"

**Location:** `README.md:115`
**Type:** Architectural
**Verdict:** Unverifiable
**Confidence:** Medium

Same external-platform limitation as Claim 3b. The repo establishes that the verifier is a Docker service that shells out to the Lean toolchain:

```yaml
# docker-compose.yml:2-5
  lean-verifier:
    build:
      context: ./verifier
      dockerfile: Dockerfile
```

```ts
// verifier/server.ts:2
import { execFile } from "child_process";
```

Whether Vercel's runtime can host it is not determinable from the codebase; it would need Vercel platform documentation or a deployment attempt.

**Evidence:** `docker-compose.yml:2-5`, `verifier/server.ts:2`, `verifier/server.ts:131-139`

---

## Claim 13b: "When unset, Lean code is generated but the type-check step returns the mock-valid response."

**Location:** `README.md:115`
**Type:** Behavioral / Configuration
**Verdict:** Mostly accurate
**Confidence:** High

The conclusion holds in the context this table row is scoped to (a Vercel deployment), but the stated trigger is one step removed from the code. Unset substitutes a default rather than short-circuiting to the mock:

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

On Vercel nothing listens on the function's own `localhost:3100`, so the fetch fails and the mock is returned — mechanism and conclusion both land correctly *within the Vercel section*. The precise version: *when unset, the route requests `http://localhost:3100`, which on Vercel is unreachable, so the type-check step returns the mock-valid response.* (Note the same wording outside a Vercel context is wrong — see Claim 4a.)

**Evidence:** `app/api/verification/lean/route.ts:3-4`, `app/api/verification/lean/route.ts:21`, `app/api/verification/lean/route.ts:37-40`

---

## Claim 14: "**Lean verification** runs only when `LEAN_VERIFIER_URL` points at a separately hosted verifier"

**Location:** `README.md:119`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** Medium

Real verification requires the fetch to a reachable verifier to succeed; any other outcome yields the mock:

```ts
// app/api/verification/lean/route.ts:21-35
    const res = await fetch(`${LEAN_VERIFIER_URL}/verify`, {
```

```ts
// app/api/verification/lean/route.ts:37-40
  } catch {
    // Service unavailable — fall back to mock
    return NextResponse.json({ valid: true, mock: true });
  }
```

Since the default `http://localhost:3100` resolves inside the function container, on Vercel the variable must point elsewhere for verification to be real. Confidence is Medium because "runs only when" depends on Vercel's network behavior for `localhost` inside a function, which is external to this repo.

**Evidence:** `app/api/verification/lean/route.ts:3-4`, `app/api/verification/lean/route.ts:21-40`

---

## Claim 15a: "**Analytics history** is written to the local filesystem"

**Location:** `README.md:120`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

Analytics entries are appended synchronously to a JSONL file on disk:

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

**Evidence:** `app/lib/analytics/persist.ts:1-17`, `app/lib/llm/callLlm.ts:85-91`, `app/lib/llm/streamLlm.ts:56-60`

---

## Claim 15b: "... and does not persist across Vercel function invocations"

**Location:** `README.md:120`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium

"Does not persist" describes a write that happens and is then discarded. That is not the mechanism. The write target is under the deployment bundle, not a writable location:

```ts
// app/lib/analytics/persist.ts:5-6
const DATA_DIR = join(process.cwd(), "data");
const FILE_PATH = join(DATA_DIR, "analytics.jsonl");
```

`ensureDir` will itself attempt a `mkdirSync` there:

```ts
// app/lib/analytics/persist.ts:8-12
function ensureDir() {
  if (!existsSync(DATA_DIR)) {
    mkdirSync(DATA_DIR, { recursive: true });
  }
}
```

By the deploy documentation's own premise that a Vercel Function may write only to `/tmp` (`CLAUDE.md:77`), both the `mkdirSync` and the `appendFileSync` throw. Every production call site swallows that error, so the entry is never recorded at all — not written-then-lost:

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

```ts
// app/lib/llm/callLlm.ts:212-219
  try {
    appendAnalyticsEntry({ ... });
  } catch { /* persistence failure must not break LLM calls */ }
```

The read path is unaffected only because it checks for the file first and returns empty:

```ts
// app/lib/analytics/persist.ts:19-20
export function readAnalyticsEntries(): AnalyticsEntry[] {
  if (!existsSync(FILE_PATH)) return [];
```

The `DELETE` path has no such guard and calls `ensureDir` unconditionally:

```ts
// app/api/analytics/route.ts:9-12
export async function DELETE() {
  clearAnalyticsEntries();
  return NextResponse.json({ ok: true });
}
```

The precise version: *analytics entries are appended to `process.cwd()/data/analytics.jsonl`, which is not writable in a Vercel Function; the write fails and is silently swallowed, so no analytics are recorded on Vercel at all.* The practical advice ("treat the analytics panel as dev-only") is right, but the mechanism a reader would act on is refuted. Confidence is Medium because the read-only-ness of `process.cwd()` on Vercel is external platform behavior.

**Evidence:** `app/lib/analytics/persist.ts:5-20`, `app/lib/llm/callLlm.ts:84-91`, `app/lib/llm/callLlm.ts:212-219`, `app/lib/llm/streamLlm.ts:55-60`, `app/api/analytics/route.ts:4-12`

---

## Claim 16: "No code changes." / "No code change."

**Location:** `git log main..review` — commits `1859488`, `4329d6e`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High

Both commits touch only Markdown (paraphrased — no quote available because the claim is about commit contents rather than a code snippet: `git show --stat 1859488` reports `CLAUDE.md | 10 ++++` and `README.md | 38 ++++--`, 2 files changed; `git show --stat 4329d6e` reports `CLAUDE.md | 2 +-` and `README.md | 32 ++---`, 2 files changed).

**Evidence:** `git show --stat 1859488`, `git show --stat 4329d6e`

---

## Claim 17: "Remove OPENALEX_MAILTO from the optional env var table; OpenAlex / evidence-search is not on this branch's main yet."

**Location:** `git log main..review` — commit `4329d6e`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High

Nothing in the checkout references OpenAlex (paraphrased — no quote available because the claim covers the absence of code: `rg -in 'openalex' --glob '!node_modules' -l` returns zero files across the working tree, including `README.md` and `CLAUDE.md`). The env var is correspondingly absent from the current optional table:

```md
<!-- README.md:112-115 -->
| Variable | Effect when set |
|---|---|
| `OPENROUTER_API_KEY` | ... |
| `LEAN_VERIFIER_URL` | ... |
```

**Evidence:** `README.md:112-115`

---

## Claim 18: "Correct OPENROUTER_API_KEY description: it's a fallback when ANTHROPIC_API_KEY is unset, not per-model routing."

**Location:** `git log main..review` — commit `4329d6e`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The provider selection is a strict fallback chain keyed on which key is present, not a per-model router:

```ts
// app/lib/llm/callLlm.ts:131
  if (anthropicKey) {
```

```ts
// app/lib/llm/callLlm.ts:162
  if (openRouterKey && openRouterModel) {
```

The Anthropic branch returns unconditionally when the key is set, so OpenRouter is unreachable in that case:

```ts
// app/lib/llm/callLlm.ts:159
    return recordAndCache(endpoint, usage, text, cacheHash, cacheKey);
```

**Evidence:** `app/lib/llm/callLlm.ts:131-160`, `app/lib/llm/callLlm.ts:162`, `app/lib/llm/streamLlm.ts:87-88`

---

## Claim 19: "README: corrected the Lean verifier section — the \"falls back to `{ valid: true, mock: true }`\" claim is no longer accurate (the route now signals the verifier is offline rather than silently passing)."

**Location:** `git log main..review` — commit `1859488`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High

The route did not signal an offline state at that commit, and does not at HEAD. At `1859488` the fallback was already the silent mock:

```ts
// app/api/verification/lean/route.ts at 1859488 (git show 1859488:app/api/verification/lean/route.ts)
  } catch {
    // Service unavailable — fall back to mock
    return NextResponse.json({ valid: true, mock: true });
  }
```

The same code stands at HEAD `4329d6e`:

```ts
// app/api/verification/lean/route.ts:37-40
  } catch {
    // Service unavailable — fall back to mock
    return NextResponse.json({ valid: true, mock: true });
  }
```

There is no offline signal anywhere in the route or its consumer — the payload contains only `valid` and `mock`, and the hook reads only `valid` (see Claim 5). The later commit `4329d6e` reverses this description in the README and CLAUDE.md, but the commit-message claim in `1859488` remains a false statement about the code at that commit.

**Evidence:** `app/api/verification/lean/route.ts:37-40`, `git show 1859488:app/api/verification/lean/route.ts`, `app/hooks/useFormalizationPipeline.ts:140-142`

---

## Claim 20: "The graceful-degradation behavior lives on a sibling branch and will replace these descriptions on merge."

**Location:** `git log main..review` — commit `4329d6e`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium

No such branch is present in this checkout, and there is no remote to consult (paraphrased — no quote available because the claim is about repository refs rather than a snippet: `git branch -a` lists only `main` and `review`; `git remote -v` returns no output). Verifying it would require access to the upstream repository's branch list.

**Evidence:** `git branch -a`, `git remote -v`

---

## Claim 21: "Lint clean; 221/221 tests pass."

**Location:** `git log main..review` — commit `4329d6e`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** High

This is a claim about the outcome of running the lint and test suites, which static reading of the codebase cannot establish (paraphrased — no quote available because the claim requires runtime execution rather than a code snippet). Verifying it would require executing `npm run lint` and the Vitest suite at commit `4329d6e` and comparing the reported test count.

**Evidence:** `package.json`, `vitest.config.ts`, `eslint.config.mjs`

---

## Claims Requiring Attention

### Incorrect
- **Claim 4a** (`CLAUDE.md:76`): "`LEAN_VERIFIER_URL` unset → mock" is wrong — unset substitutes `http://localhost:3100` and can reach a real verifier (the shipped `docker-compose.yml` publishes exactly that port); the mock comes only from the fetch `catch`. Reword to match `README.md:88`.
- **Claim 6b** (`CLAUDE.md:77`): the bullet frames Vercel persistence as short-lived `/tmp` writes, but `app/lib/analytics/persist.ts:5` and `app/lib/llm/cache.ts:6` write to `process.cwd()/data` — those writes fail outright and are swallowed. State that nothing is written, rather than that writes are ephemeral.
- **Claim 15b** (`README.md:120`): "does not persist across Vercel function invocations" describes a write-then-lose that does not occur; the `appendFileSync` to `process.cwd()/data/analytics.jsonl` throws and is caught in `app/lib/llm/callLlm.ts:91`, so no analytics are recorded on Vercel at all.
- **Claim 19** (commit `1859488`): the message says the route "now signals the verifier is offline rather than silently passing," but at that commit and at HEAD the route returns the silent `{ valid: true, mock: true }` mock and no offline signal exists.

### Stale
- None.

### Mostly Accurate
- **Claim 11** (`README.md:102-106`): `ANTHROPIC_API_KEY` is listed as required, but the app deploys and runs without it, serving mock responses (`app/lib/llm/callLlm.ts:202-220`). Say "required for real LLM responses."
- **Claim 13b** (`README.md:115`): "when unset ... returns the mock-valid response" is right for Vercel but skips the intermediate step — unset substitutes `http://localhost:3100`, which is unreachable inside a Vercel Function. State the default explicitly.

### Unverifiable
- **Claim 3b** (`CLAUDE.md:76`) and **Claim 13a** (`README.md:115`): "cannot run inside a Vercel Function / on Vercel" is an external platform limitation; would need Vercel runtime documentation or a deployment attempt.
- **Claim 7** (`README.md:5`): the deploy button's `repository-url` target cannot be checked — the clone has no configured remote; needs network access to GitHub.
- **Claim 20** (commit `4329d6e`): the referenced "sibling branch" is not present locally (`git branch -a` shows only `main` and `review`) and there is no remote; needs upstream branch access.
- **Claim 21** (commit `4329d6e`): "Lint clean; 221/221 tests pass" requires running the lint and Vitest suites at `4329d6e`.
