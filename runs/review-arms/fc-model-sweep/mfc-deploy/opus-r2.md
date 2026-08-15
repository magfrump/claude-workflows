# Code Fact-Check Report
Commit: 4329d6e

**Repository:** `/workspace/external/cc-review-eval/mfc-deploy`
**Scope:** `git diff main...review` — `CLAUDE.md`, `README.md`, plus commit messages in `git log main..review`
**Checked:** 2026-08-15
**Total claims checked:** 19
**Summary:** 10 verified, 6 mostly accurate, 0 stale, 1 incorrect, 2 unverifiable

---

## Claim 1: "each end user clicks the 'Deploy with Vercel' button in the README and runs their own copy with their own `ANTHROPIC_API_KEY`. There is no shared hosted instance and no demo mode."

**Location:** `CLAUDE.md:73`
**Type:** Architectural / Configuration
**Verdict:** Mostly accurate
**Confidence:** High

The key is read only from the server-side process environment, so a deployment is keyed by its own env var:

```ts
// app/lib/llm/callLlm.ts:112-113
  const anthropicKey = process.env.ANTHROPIC_API_KEY;
  const openRouterKey = process.env.OPENROUTER_API_KEY;
```

"No demo mode" is imprecise: with neither key set, `callLlm` does not error — it returns a mock provider result that each route substitutes with canned text:

```ts
// app/lib/llm/callLlm.ts:203-211
  console.warn(`[${endpoint}] No API key configured — returning mock response.\n\n To generate real responses, add ANTHROPIC_API_KEY or OPENROUTER_API_KEY to .env.local`);
  const usage: LlmCallUsage = {
    provider: "mock",
    ...
```

```ts
// app/api/edit/inline/route.ts:24
    const text = usage.provider === "mock" ? mockResponse(selection, instruction) : responseText;
```

A keyless deployment therefore runs in a mock/demo-like mode. The precise statement would be "no *hosted* demo instance"; a keyless local or Vercel deploy still renders mock content (the same `provider === "mock"` branch appears in `app/api/edit/whole/route.ts:32`, `app/api/edit/artifact/route.ts:54`, `app/api/refine/context/route.ts:49`, `app/api/formalization/lean/route.ts:131`, `app/api/decomposition/extract/route.ts:121`) (paraphrased — no quote available because the claim is about a pattern repeated across six route files and reads more clearly as an enumeration than as six near-identical fragments).

**Evidence:** `app/lib/llm/callLlm.ts:112-118`, `app/lib/llm/callLlm.ts:202-221`, `app/api/edit/inline/route.ts:24`

---

## Claim 2: "There is no in-browser BYO-key flow; keys live in the Vercel project's environment variables (or `.env.local` in dev)."

**Location:** `CLAUDE.md:75`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High

Every read of an API key in the codebase is a server-side `process.env` read; there are exactly four, all in `app/lib/llm/`:

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

There is no client-side key entry path: `rg -n -i 'apiKey|API_KEY' app/components app/hooks` returns zero matches, and `rg -n 'NEXT_PUBLIC' .` returns zero matches anywhere in the repo, so no key is exposed to or accepted from the browser (paraphrased — no quote available because the claim covers the absence of code; the evidence is empty grep results).

**Evidence:** `app/lib/llm/callLlm.ts:112-113`, `app/lib/llm/streamLlm.ts:87-88`

---

## Claim 3: "The Lean verifier is a separate Dockerized service and cannot run inside a Vercel Function."

**Location:** `CLAUDE.md:76`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** Medium

The verifier is a separate container that shells out to `lake` inside a Lean project directory — not importable Node code:

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

```ts
// verifier/server.ts:131-138
    execFile(
      "lake",
```

The Next.js side reaches it only over HTTP:

```ts
// app/api/verification/lean/route.ts:21-26
    const res = await fetch(`${LEAN_VERIFIER_URL}/verify`, {
      method: "POST",
```

Confidence is Medium rather than High because the "cannot run inside a Vercel Function" half is a statement about the Vercel platform (no Lean toolchain, no `lake` binary, no long-lived container in the function image) that cannot be settled from this repository alone; the code-side half — a separate Docker service invoked over HTTP — is fully confirmed.

**Evidence:** `docker-compose.yml:1-16`, `verifier/server.ts:121-155`, `app/api/verification/lean/route.ts:21-26`

---

## Claim 4: "When `LEAN_VERIFIER_URL` is unset or unreachable, `app/api/verification/lean/route.ts` falls back to a mock `{ valid: true, mock: true }` response."

**Location:** `CLAUDE.md:76`
**Type:** Behavioral / Configuration
**Verdict:** Mostly accurate
**Confidence:** High

The *unreachable* half is exact — any throw from the fetch, JSON parse, or the 35 s abort lands in the catch:

```ts
// app/api/verification/lean/route.ts:37-40
  } catch {
    // Service unavailable — fall back to mock
    return NextResponse.json({ valid: true, mock: true });
  }
```

The *unset* half is imprecise. Unset does not by itself produce the mock; the route substitutes a default URL and then behaves exactly as in the reachable/unreachable cases:

```ts
// app/api/verification/lean/route.ts:3-4
const LEAN_VERIFIER_URL =
  process.env.LEAN_VERIFIER_URL ?? "http://localhost:3100";
```

So with the variable unset and `docker compose up` running locally, the route reaches the real verifier at `http://localhost:3100/verify` and returns genuine type-check results — no mock. The precise version is "when `LEAN_VERIFIER_URL` is unreachable — including the `http://localhost:3100` default used when it is unset."

One further nuance: a *reachable* verifier that returns a non-2xx status is passed through rather than mocked, so the mock is strictly a transport/parse-failure path:

```ts
// app/api/verification/lean/route.ts:32-34
    if (!res.ok) {
      return NextResponse.json(data, { status: res.status });
    }
```

**Evidence:** `app/api/verification/lean/route.ts:3-5`, `app/api/verification/lean/route.ts:17-40`

---

## Claim 5: "This is a known silent-pass behavior — `useFormalizationPipeline` treats it as `valid` and there is currently no 'verifier offline' UI state."

**Location:** `CLAUDE.md:76`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High

The client wrapper discards the `mock` flag entirely, keeping only `valid` and `errors`:

```ts
// app/lib/formalization/api.ts:103-111
export async function verifyLean(leanCode: string) {
  const res = await fetch("/api/verification/lean", {
    ...
  const data = await res.json();
  return { valid: Boolean(data.valid), errors: (data.errors as string | undefined) ?? "" };
}
```

`useFormalizationPipeline` then maps that straight to the `valid` status:

```ts
// app/hooks/useFormalizationPipeline.ts:140-144
    const { valid, errors } = await verifyLean(fullCode);
    const vStatus = valid ? "valid" as const : "invalid" as const;
```

```ts
// app/hooks/useFormalizationPipeline.ts:121-122
      const vStatus = result.valid ? "valid" as const : "invalid" as const;
      a.setVerificationStatus(vStatus);
```

And the status union has no offline/mock member:

```ts
// app/lib/types/session.ts:1
export type VerificationStatus = "none" | "verifying" | "valid" | "invalid";
```

Nothing outside the route itself reads the `mock` field: `rg -n '\bmock\b' app --glob '!*.test.*'` returns hits only in `app/api/**` route handlers keyed off `usage.provider === "mock"` (the LLM mock path, unrelated to verification) and the route's own `{ valid: true, mock: true }` literal — no component or hook consumes it (paraphrased — no quote available because the claim covers the absence of a consumer; the evidence is the grep result set).

**Evidence:** `app/lib/formalization/api.ts:103-111`, `app/hooks/useFormalizationPipeline.ts:119-144`, `app/lib/types/session.ts:1`

---

## Claim 6: "Persistence on Vercel is best-effort. The LLM cache and analytics log write to the local filesystem in dev. Vercel Functions can only write to `/tmp` and that lasts only as long as the warm container."

**Location:** `CLAUDE.md:77`
**Type:** Behavioral / Configuration
**Verdict:** Mostly accurate
**Confidence:** High

The first half is exact — both writers target paths under `process.cwd()`:

```ts
// app/lib/llm/cache.ts:6
const CACHE_DIR = join(process.cwd(), "data", "cache");
```

```ts
// app/lib/analytics/persist.ts:5-6
const DATA_DIR = join(process.cwd(), "data");
const FILE_PATH = join(DATA_DIR, "analytics.jsonl");
```

The `/tmp` sentence is directionally right about durability but misdescribes this code. Nothing in the repository ever writes to `/tmp`, and there is no environment-conditional path selection — `rg -n 'tmp' app` finds no `/tmp` write target, and the only `process.env` reads in `app/` are `ANTHROPIC_API_KEY`, `OPENROUTER_API_KEY`, `SIMULATE_STREAM_FROM_CACHE`, and `LEAN_VERIFIER_URL` (paraphrased — no quote available because the claim covers the absence of code; the evidence is the empty/enumerated grep result sets). On a platform whose deployment filesystem is read-only outside `/tmp`, `mkdir(process.cwd()/data/cache)` and `appendFileSync` would therefore fail rather than write to an ephemeral `/tmp` copy — and the failures are swallowed:

```ts
// app/lib/llm/callLlm.ts:91-95
  } catch { /* persistence failure must not break LLM calls */ }
  const result: CallLlmResult = { text, usage, cacheKey };
  if (text) {
    try { await setCachedResult(cacheHash, result); } catch { /* cache write failure is non-fatal */ }
  }
```

So the operational advice ("don't add features that assume durable filesystem state") is correct, but the stated mechanism is not what the code does: writes are silently dropped, not written to a warm-container `/tmp`. The Vercel-platform half of the sentence is itself outside what this repository can settle.

**Evidence:** `app/lib/llm/cache.ts:6`, `app/lib/llm/cache.ts:26-31`, `app/lib/llm/cache.ts:61-68`, `app/lib/analytics/persist.ts:5-17`, `app/lib/llm/callLlm.ts:84-96`, `app/lib/llm/streamLlm.ts:55-66`

---

## Claim 7: Deploy button target — `repository-url=https://github.com/aditya-adiga/meta-formalism-copilot`, `envLink=...#deploy-to-vercel`

**Location:** `README.md:5`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium

The `#deploy-to-vercel` anchor half resolves — the README defines the heading it points at:

```md
<!-- README.md:98 -->
## Deploy to Vercel
```

The repository URL cannot be checked: `git remote -v` in this clone returns no output, so there is no configured remote to compare the slug against, and no network access is in scope. Verifying it would require either a configured `origin` remote or an HTTP fetch of the GitHub URL (paraphrased — no quote available because the claim is about an external locator with no in-repo counterpart).

**Evidence:** `README.md:5`, `README.md:98`

---

## Claim 8: "Each user runs their own copy with their own Anthropic API key"

**Location:** `README.md:7`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High

Same evidence as Claim 2: the key is read only from `process.env` server-side and there is no multi-tenant key handling or per-request key parameter anywhere:

```ts
// app/lib/llm/callLlm.ts:112
  const anthropicKey = process.env.ANTHROPIC_API_KEY;
```

The Anthropic client is a module-level singleton built from that one process-wide key, which is only coherent under a one-key-per-deployment model:

```ts
// app/lib/llm/callLlm.ts:11-17
let _anthropicClient: Anthropic | null = null;
export function getAnthropicClient(apiKey: string): Anthropic {
  if (!_anthropicClient) {
    _anthropicClient = new Anthropic({ apiKey });
  }
  return _anthropicClient;
}
```

**Evidence:** `app/lib/llm/callLlm.ts:11-17`, `app/lib/llm/callLlm.ts:112-113`

---

## Claim 9: "When running, submitted Lean code is type-checked by a real Lean 4 installation. When the service is not reachable, the verification API route returns a mock `{ valid: true, mock: true }` response ... generated Lean code is reported as valid without actually being type-checked."

**Location:** `README.md:64`
**Type:** Behavioral
**Confidence:** High
**Verdict:** Verified

The verifier writes the submitted code to a Lean source file and runs a real `lake` build over it:

```ts
// verifier/server.ts:103
    await writeFile(VERIFY_FILE, deduplicateImports(leanCode as string), "utf-8");
```

```ts
// verifier/server.ts:131-153
    execFile(
      "lake",
      ...
          errors: errorOutput || `lake build exited with code ${execError.code}`,
```

The unreachable path returns exactly the claimed shape:

```ts
// app/api/verification/lean/route.ts:37-40
  } catch {
    // Service unavailable — fall back to mock
    return NextResponse.json({ valid: true, mock: true });
  }
```

And the "reported as valid without being type-checked" consequence holds downstream, since the client coerces that payload to `valid: true` (see Claim 5's quotes at `app/lib/formalization/api.ts:110` and `app/hooks/useFormalizationPipeline.ts:141`). Note this line's condition — "not reachable" — is the precise one, unlike the "unset or unreachable" phrasing in `CLAUDE.md:76` (Claim 4).

**Evidence:** `verifier/server.ts:87-118`, `verifier/server.ts:121-155`, `app/api/verification/lean/route.ts:37-40`

---

## Claim 10: "The Next.js route reads `LEAN_VERIFIER_URL` from the environment (defaults to `http://localhost:3100`). When the verifier is unreachable, the route falls back to the mock response described above."

**Location:** `README.md:88`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High

Both halves match the route exactly:

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

The default port also agrees with the container's published port:

```yaml
# docker-compose.yml:6-9
    ports:
      - "3100:3100"
    environment:
      - PORT=3100
```

This line is the reconciliation point for Claim 4: the default is what makes an unset variable behave like a *reachability* question rather than an unconditional mock.

**Evidence:** `app/api/verification/lean/route.ts:3-5`, `app/api/verification/lean/route.ts:37-40`, `docker-compose.yml:6-9`

---

## Claim 11: "The rest of the app keeps working without the verifier. Lean code can still be generated and edited; the type-check step returns the mock-valid response."

**Location:** `README.md:96`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

Lean generation goes through a separate route that never touches the verifier:

```ts
// app/lib/formalization/api.ts:120-123
  const data = await fetchApi<{ leanCode: string }>(
    "/api/formalization/lean",
    { informalProof, previousAttempt, errors, instruction, contextLeanCode },
  );
```

and the verification failure is contained inside the route's catch (quoted at Claim 4, `app/api/verification/lean/route.ts:37-40`), which returns HTTP 200 with the mock body, so `verifyLean` resolves normally rather than throwing:

```ts
// app/lib/formalization/api.ts:109-110
  const data = await res.json();
  return { valid: Boolean(data.valid), errors: (data.errors as string | undefined) ?? "" };
}
```

**Evidence:** `app/lib/formalization/api.ts:103-124`, `app/api/verification/lean/route.ts:37-40`

---

## Claim 12: "`OPENROUTER_API_KEY` — Acts as a fallback LLM provider when `ANTHROPIC_API_KEY` is unset. **Privacy note:** prompts (including your source material) are sent to OpenRouter when this path is used."

**Location:** `README.md:114`
**Type:** Behavioral / Configuration
**Verdict:** Mostly accurate
**Confidence:** High

The fallback ordering is as described — the OpenRouter branch is reached only when `anthropicKey` is falsy:

```ts
// app/lib/llm/callLlm.ts:131-132
  if (anthropicKey) {
    const model = anthropicModel ?? DEFAULT_ANTHROPIC_MODEL;
```

```ts
// app/lib/llm/callLlm.ts:162
  if (openRouterKey && openRouterModel) {
```

The missing qualifier is the second conjunct: the key alone is not sufficient. A caller that does not pass `openRouterModel` falls through to the mock provider even with `OPENROUTER_API_KEY` set:

```ts
// app/lib/llm/callLlm.ts:114-118
  const effectiveModel = anthropicKey
    ? (anthropicModel ?? DEFAULT_ANTHROPIC_MODEL)
    : (openRouterKey && openRouterModel)
      ? openRouterModel
      : "mock";
```

The privacy note is exact — both the system prompt and the user content are sent in the request body:

```ts
// app/lib/llm/callLlm.ts:170-177
      body: JSON.stringify({
        model: openRouterModel,
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: userContent },
        ],
```

The streaming path is identical in both respects:

```ts
// app/lib/llm/streamLlm.ts:127-128
        } else if (openRouterKey && openRouterModel) {
          await streamOpenRouter(controller, {
```

**Evidence:** `app/lib/llm/callLlm.ts:112-118`, `app/lib/llm/callLlm.ts:162-178`, `app/lib/llm/streamLlm.ts:89-93`, `app/lib/llm/streamLlm.ts:255-262`

---

## Claim 13: "`LEAN_VERIFIER_URL` ... When unset, Lean code is generated but the type-check step returns the mock-valid response."

**Location:** `README.md:115`
**Type:** Behavioral / Configuration
**Verdict:** Mostly accurate
**Confidence:** High

Same imprecision as Claim 4, and it sits two tables below the `README.md:88` line that states the default. Unset means the route targets `http://localhost:3100`:

```ts
// app/api/verification/lean/route.ts:3-4
const LEAN_VERIFIER_URL =
  process.env.LEAN_VERIFIER_URL ?? "http://localhost:3100";
```

In the Vercel context this table describes, nothing listens on that address inside the function, so the fetch throws and the mock is returned — the claim's conclusion holds *for Vercel*. Read as a general statement of route behavior (which the table cell's phrasing invites), it is wrong for local development with `docker compose up`, where an unset variable yields real type-checking.

**Evidence:** `app/api/verification/lean/route.ts:3-5`, `app/api/verification/lean/route.ts:17-40`

---

## Claim 14: "**Lean verification** runs only when `LEAN_VERIFIER_URL` points at a separately hosted verifier."

**Location:** `README.md:119`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium

Under the "Limitations on Vercel" heading this is accurate: the only path to a real type-check is a successful fetch to `${LEAN_VERIFIER_URL}/verify`, and every failure mode returns the mock:

```ts
// app/api/verification/lean/route.ts:21-26
    const res = await fetch(`${LEAN_VERIFIER_URL}/verify`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ leanCode }),
      signal: controller.signal,
    });
```

Confidence is Medium because the code-level condition is *reachability of the resolved URL*, not the variable being set — the claim is true on Vercel only because the `http://localhost:3100` default cannot resolve to a verifier there, which is a platform fact this repository cannot confirm.

**Evidence:** `app/api/verification/lean/route.ts:3-5`, `app/api/verification/lean/route.ts:17-40`

---

## Claim 15: "**Analytics history** is written to the local filesystem and does not persist across Vercel function invocations"

**Location:** `README.md:120`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High

"Written to the local filesystem" is right, and the target is a fixed repo-relative path with no Vercel-specific branch:

```ts
// app/lib/analytics/persist.ts:5-16
const DATA_DIR = join(process.cwd(), "data");
const FILE_PATH = join(DATA_DIR, "analytics.jsonl");

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

"Does not persist across Vercel function invocations" misstates the mechanism in a way that matters to a reader acting on it. It describes a write that succeeds and is then discarded when the container recycles. What actually happens on a platform whose deployment filesystem is read-only outside `/tmp` is that `mkdirSync`/`appendFileSync` throw on the *first* write, and every call site swallows the throw:

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
// app/lib/llm/streamLlm.ts:55-62
  try {
    appendAnalyticsEntry({
      ...
  } catch { /* persistence failure must not break LLM calls */ }
```

So the entry is lost immediately and silently, not at the next cold start — within a single warm invocation the analytics panel would still show nothing, because the reader guards on the file's existence and returns empty:

```ts
// app/lib/analytics/persist.ts:19-20
export function readAnalyticsEntries(): AnalyticsEntry[] {
  if (!existsSync(FILE_PATH)) return [];
```

The practical advice that follows ("treat the analytics panel as dev-only") is correct. A precise statement would be "analytics writes target a repo-relative `data/analytics.jsonl` and fail silently on Vercel's read-only filesystem, so no history is recorded at all."

**Evidence:** `app/lib/analytics/persist.ts:1-37`, `app/lib/llm/callLlm.ts:84-91`, `app/lib/llm/callLlm.ts:212-219`, `app/lib/llm/streamLlm.ts:55-62`, `app/api/analytics/route.ts:4-7`

---

## Claim 16: "corrected the Lean verifier section — the 'falls back to `{ valid: true, mock: true }`' claim is no longer accurate (the route now signals the verifier is offline rather than silently passing)"

**Location:** commit `1859488` message body
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High

The route did not and does not signal an offline state; it returns the mock-pass payload:

```ts
// app/api/verification/lean/route.ts:37-40
  } catch {
    // Service unavailable — fall back to mock
    return NextResponse.json({ valid: true, mock: true });
  }
```

The route file has not been touched on this branch — `git log --oneline -- app/api/verification/lean/route.ts` returns only `5c2c8f5` and `1bb244c`, both of which predate `1859488` and `4329d6e`, so no commit on `main..review` could have changed this behavior (paraphrased — no quote available because the assertion is about file history rather than file contents). The follow-up commit `4329d6e` identifies and reverses this same error in its own message ("Replace the inaccurate 'verifier offline — proof not checked' claims ... with accurate description of the current behavior on this branch"), so the branch tip's documentation is correct and only the intermediate commit message remains wrong.

**Evidence:** `app/api/verification/lean/route.ts:37-40`, `git log -- app/api/verification/lean/route.ts`

---

## Claim 17: "Remove `OPENALEX_MAILTO` from the optional env var table; OpenAlex / evidence-search is not on this branch's main yet."

**Location:** commit `4329d6e` message body
**Type:** Architectural / Staleness
**Verdict:** Verified
**Confidence:** High

`rg -ril 'openalex' app` returns zero matches, and `rg -n 'process\.env\.' app` enumerates exactly four variables — `ANTHROPIC_API_KEY`, `OPENROUTER_API_KEY`, `SIMULATE_STREAM_FROM_CACHE`, `LEAN_VERIFIER_URL` — with no `OPENALEX_MAILTO` among them (paraphrased — no quote available because the claim covers the absence of code; the evidence is empty and enumerated grep result sets). Documenting the variable would therefore have described a feature that does not exist in this tree; removing it matches the code.

**Evidence:** `app/lib/llm/callLlm.ts:112-113`, `app/lib/llm/streamLlm.ts:87-88`, `app/lib/llm/streamLlm.ts:105`, `app/api/verification/lean/route.ts:4`

---

## Claim 18: "Correct `OPENROUTER_API_KEY` description: it's a fallback when `ANTHROPIC_API_KEY` is unset, not per-model routing."

**Location:** commit `4329d6e` message body
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

Provider selection is a strict fallback chain gated on key presence, with no routing logic keyed on the requested model:

```ts
// app/lib/llm/callLlm.ts:131
  if (anthropicKey) {
```

```ts
// app/lib/llm/callLlm.ts:162
  if (openRouterKey && openRouterModel) {
```

The doc comment on the function states the same chain:

```ts
// app/lib/llm/callLlm.ts:99-101
/** Centralized LLM call with Anthropic -> OpenRouter -> mock fallback.
 *  Returns the raw text response and usage/cost metadata.
 *  On mock fallback, returns text: "" — the caller provides its own mock text. */
```

`openRouterModel` is a per-call option supplied by the caller, used only *inside* the already-selected OpenRouter branch — it does not select the provider on its own (see Claim 12 for the `effectiveModel` quote at `app/lib/llm/callLlm.ts:114-118`).

**Evidence:** `app/lib/llm/callLlm.ts:99-101`, `app/lib/llm/callLlm.ts:114-118`, `app/lib/llm/callLlm.ts:131-200`, `app/lib/llm/streamLlm.ts:117-136`

---

## Claim 19: "No code change. Lint clean; 221/221 tests pass." and "The graceful-degradation behavior lives on a sibling branch and will replace these descriptions on merge."

**Location:** commit `4329d6e` message body
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** High

"No code change" is confirmed: `git diff --name-only main...review` lists only `CLAUDE.md` and `README.md` (paraphrased — no quote available because the claim is about the diff's file set, not a code snippet).

The test-count and lint claims cannot be checked in this environment — the test runner is not installed, so neither `npm test` nor `npx vitest run` can execute:

```
$ npm test
> vitest run
sh: 1: vitest: not found
```

Verifying `221/221` would require a working `node_modules` with `vitest` installed. The "sibling branch" claim is likewise unverifiable from this clone: `git branch -a` lists only `main` and `review`, so the referenced branch is not present locally and would require access to a remote (paraphrased — no quote available because the claim references a git ref that does not exist in this repository).

**Evidence:** `git diff --name-only main...review`, `git branch -a`, `package.json` test script

---

## Claims Requiring Attention

### Incorrect
- **Claim 15** (`README.md:120`): Analytics writes are not "written then lost between invocations" — they target `process.cwd()/data/analytics.jsonl` and throw on Vercel's read-only filesystem, with the throw swallowed at every call site, so nothing is ever recorded; restate as "writes fail silently on Vercel."
- **Claim 16** (commit `1859488`): "the route now signals the verifier is offline rather than silently passing" contradicts `app/api/verification/lean/route.ts:37-40`, which returns `{ valid: true, mock: true }`; the route was never changed on this branch. Already corrected by the message of `4329d6e`.

### Stale
- None.

### Mostly Accurate
- **Claim 1** (`CLAUDE.md:73`): "no demo mode" — a keyless deployment still serves mock content via the `provider === "mock"` branch in six route handlers; tighten to "no *hosted* demo instance."
- **Claim 4** (`CLAUDE.md:76`): "unset or unreachable" — unset substitutes the `http://localhost:3100` default; only unreachability triggers the mock. Tighten to "unreachable (including the default used when unset)."
- **Claim 6** (`CLAUDE.md:77`): No code path writes to `/tmp`; both writers use `process.cwd()/data` unconditionally, so on Vercel the writes fail rather than landing in a warm-container `/tmp`. Restate the mechanism.
- **Claim 12** (`README.md:114`): OpenRouter fallback also requires the caller to pass `openRouterModel`; the key alone falls through to mock. Add the qualifier.
- **Claim 13** (`README.md:115`): "When unset ... returns the mock-valid response" is true only on Vercel; locally with the verifier running, unset yields real type-checking. Scope the sentence to Vercel.

### Unverifiable
- **Claim 7** (`README.md:5`): Deploy-button `repository-url` slug — this clone has no configured git remote to compare against; needs an `origin` remote or network access.
- **Claim 19** (commit `4329d6e`): "221/221 tests pass" needs an installed `vitest` (`npm test` fails with `vitest: not found`); "sibling branch" needs a remote — `git branch -a` shows only `main` and `review`.
