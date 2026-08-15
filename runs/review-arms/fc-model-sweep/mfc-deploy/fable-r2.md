# Code Fact-Check Report
Commit: 4329d6e

**Repository:** /workspace/external/cc-review-eval/mfc-deploy
**Scope:** branch diff `main...review` (`CLAUDE.md`, `README.md`) plus commit messages `main..review`
**Checked:** 2026-08-15
**Total claims checked:** 16
**Summary:** 10 verified, 4 mostly accurate, 0 stale, 1 incorrect, 1 unverifiable

---

## Claim 1: "There is no in-browser BYO-key flow; keys live in the Vercel project's environment variables (or `.env.local` in dev)."

**Location:** `CLAUDE.md:75`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High

API keys are read only server-side from the process environment:

```ts
// app/lib/llm/callLlm.ts:112-113
const anthropicKey = process.env.ANTHROPIC_API_KEY;
const openRouterKey = process.env.OPENROUTER_API_KEY;
```

The streaming path does the same (`app/lib/llm/streamLlm.ts:87-88`, quoted under Claim 9). No client-side key entry path exists: a case-insensitive search for `apiKey` across `app/` hits only server-side LLM libraries and API routes, and searches for "enter your key"/"BYO"-style UI strings in `app/components` and `app/page.tsx` return nothing (paraphrased — no quote available because the claim covers absence of code; greps for `apiKey`, `byo`, and key-entry phrasing outside `app/api` and `app/lib` produced zero client-component hits).

**Evidence:** `app/lib/llm/callLlm.ts:112-113`, `app/lib/llm/streamLlm.ts:87-88`

---

## Claim 2: "The Lean verifier is a separate Dockerized service and cannot run inside a Vercel Function."

**Location:** `CLAUDE.md:76`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** Medium

The verifier is a separate Docker service in this repo:

```yaml
# docker-compose.yml:1-6
services:
  lean-verifier:
    build:
      context: ./verifier
      dockerfile: Dockerfile
    ports:
      - "3100:3100"
```

The `verifier/` directory contains its own `Dockerfile`, `server.ts`, `package.json`, and a `lean-project/` (paraphrased — no quote available because the claim is about directory layout, not a snippet). The "cannot run inside a Vercel Function" half is a platform-capability statement about Vercel, not about this codebase; it matches Vercel's publicly documented runtime model (no arbitrary Docker containers in Functions) but cannot be proven from static analysis of this repo alone — hence Medium confidence.

**Evidence:** `docker-compose.yml:1-16`, `verifier/Dockerfile`, `verifier/server.ts`

---

## Claim 3: "When `LEAN_VERIFIER_URL` is unset or unreachable, `app/api/verification/lean/route.ts` falls back to a mock `{ valid: true, mock: true }` response."

**Location:** `CLAUDE.md:76`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High

The *unreachable* half is correct — any fetch/timeout/JSON-parse failure returns the mock:

```ts
// app/api/verification/lean/route.ts:37-40
  } catch {
    // Service unavailable — fall back to mock
    return NextResponse.json({ valid: true, mock: true });
  }
```

The *unset* half needs a qualifier. When the variable is unset, the route does not go straight to the mock — it substitutes a default URL and attempts a real request:

```ts
// app/api/verification/lean/route.ts:3-4
const LEAN_VERIFIER_URL =
  process.env.LEAN_VERIFIER_URL ?? "http://localhost:3100";
```

So "unset" produces the mock only when nothing is listening at `http://localhost:3100` (always the case on Vercel, but in dev with `docker compose up` running, an unset variable still yields real type-checking). A further edge the claim omits: if the verifier responds but with a non-OK status, the route passes the error through rather than mocking:

```ts
// app/api/verification/lean/route.ts:32-34
    if (!res.ok) {
      return NextResponse.json(data, { status: res.status });
    }
```

The precise version: "When the verifier is unreachable at `LEAN_VERIFIER_URL` (default `http://localhost:3100` when unset), the route falls back to `{ valid: true, mock: true }`."

**Evidence:** `app/api/verification/lean/route.ts:3-4`, `app/api/verification/lean/route.ts:21-40`

---

## Claim 4: "This is a known silent-pass behavior — `useFormalizationPipeline` treats it as `valid` and there is currently no 'verifier offline' UI state."

**Location:** `CLAUDE.md:76`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High

The client-side fetch wrapper coerces the mock response to a plain boolean and drops the `mock` flag:

```ts
// app/lib/formalization/api.ts:103-110
export async function verifyLean(leanCode: string) {
  const res = await fetch("/api/verification/lean", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ leanCode }),
  });
  const data = await res.json();
  return { valid: Boolean(data.valid), errors: (data.errors as string | undefined) ?? "" };
}
```

The pipeline hook then maps that boolean directly to UI status with no mock/offline branch:

```ts
// app/hooks/useFormalizationPipeline.ts:140-141
    const { valid, errors } = await verifyLean(fullCode);
    const vStatus = valid ? "valid" as const : "invalid" as const;
```

A search for "verifier offline"/"offline" across `app/` finds no UI state for that condition, and `mock` appears in the hook and components nowhere in a verification context (paraphrased — no quote available because the claim covers absence of code; the only `mock`/`offline` grep hits are in `app/lib/llm/streamLlm.ts` and `app/lib/llm/callLlm.ts`, which concern the LLM mock fallback, not the verifier).

**Evidence:** `app/lib/formalization/api.ts:103-110`, `app/hooks/useFormalizationPipeline.ts:121-142`

---

## Claim 5: "Persistence on Vercel is best-effort. The LLM cache and analytics log write to the local filesystem in dev. Vercel Functions can only write to `/tmp` and that lasts only as long as the warm container."

**Location:** `CLAUDE.md:77`
**Type:** Behavioral / Configuration
**Verdict:** Mostly accurate
**Confidence:** Medium

The dev-side half is verified — both writers target the local filesystem under the project directory:

```ts
// app/lib/analytics/persist.ts:5-6
const DATA_DIR = join(process.cwd(), "data");
const FILE_PATH = join(DATA_DIR, "analytics.jsonl");
```

```ts
// app/lib/llm/cache.ts:6
const CACHE_DIR = join(process.cwd(), "data", "cache");
```

But the `/tmp` sentence, while true of the Vercel platform generally, does not describe what this code does: neither writer uses `/tmp` — both write under `process.cwd()`, which in a Vercel Function is the read-only deployment bundle. So on Vercel these writes would not land in ephemeral warm-container storage; they would fail outright, and both call sites swallow the failure silently:

```ts
// app/lib/llm/callLlm.ts:84-95
  try {
    appendAnalyticsEntry({
      id: randomUUID(),
      endpoint,
      ...usage,
      timestamp: new Date().toISOString(),
    });
  } catch { /* persistence failure must not break LLM calls */ }
  const result: CallLlmResult = { text, usage, cacheKey };
  if (text) {
    try { await setCachedResult(cacheHash, result); } catch { /* cache write failure is non-fatal */ }
  }
```

The claim's operative conclusion — do not assume durable filesystem state on Vercel — holds, which is why this is Mostly accurate rather than Incorrect. The precise version: "the cache and analytics log write to `data/` under the project directory, which is read-only on Vercel, so writes fail and are silently ignored." Confidence is Medium because the read-only-cwd behavior on Vercel is platform knowledge, not statically checkable from this repo.

**Evidence:** `app/lib/analytics/persist.ts:5-16`, `app/lib/llm/cache.ts:6`, `app/lib/llm/callLlm.ts:75-97`

---

## Claim 6: "When the service is not reachable, the verification API route returns a mock `{ valid: true, mock: true }` response so the rest of the app keeps working — note that this means generated Lean code is reported as valid without actually being type-checked."

**Location:** `README.md:64`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The catch-all fallback returns exactly the claimed shape:

```ts
// app/api/verification/lean/route.ts:37-40
  } catch {
    // Service unavailable — fall back to mock
    return NextResponse.json({ valid: true, mock: true });
  }
```

And "reported as valid" is what the consumer does with it — `verifyLean` returns `valid: Boolean(data.valid)` (`app/lib/formalization/api.ts:110`, quoted under Claim 4), and the hook maps `valid` to the `"valid"` UI status (`app/hooks/useFormalizationPipeline.ts:140-141`, quoted under Claim 4). No type-checking occurs on this path — the fetch to the verifier is the only checking mechanism and it has failed (paraphrased — no quote available because the claim covers absence of code: there is no local Lean checker in the route or its imports).

**Evidence:** `app/api/verification/lean/route.ts:21-40`, `app/lib/formalization/api.ts:103-110`, `app/hooks/useFormalizationPipeline.ts:140-141`

---

## Claim 7: "The Next.js route reads `LEAN_VERIFIER_URL` from the environment (defaults to `http://localhost:3100`). When the verifier is unreachable, the route falls back to the mock response described above."

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

The unreachable-case fallback is the mock return in the catch block (`app/api/verification/lean/route.ts:37-40`, quoted under Claim 6). This README line, unlike CLAUDE.md's Claim 3, correctly conditions the mock on *unreachable* only, so no qualifier is missing. The docker-compose service publishes port 3100 (`docker-compose.yml:7`, quoted under Claim 2), consistent with the default.

**Evidence:** `app/api/verification/lean/route.ts:3-4`, `app/api/verification/lean/route.ts:37-40`, `docker-compose.yml:6-8`

---

## Claim 8: "The rest of the app keeps working without the verifier. Lean code can still be generated and edited; the type-check step returns the mock-valid response described above."

**Location:** `README.md:96`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

Lean generation is a separate endpoint that never touches the verifier:

```ts
// app/lib/formalization/api.ts:113-124 (excerpt)
export async function generateLean(
  informalProof: string,
  ...
  const data = await fetchApi<{ leanCode: string }>(
    "/api/formalization/lean",
    { informalProof, previousAttempt, errors, instruction, contextLeanCode },
  );
```

The type-check step's mock-valid behavior is the route's catch fallback plus the client's boolean coercion (`app/api/verification/lean/route.ts:37-40` and `app/lib/formalization/api.ts:110`, quoted under Claims 6 and 4). The verification route only errors to the client for malformed input, never for verifier absence (paraphrased — no quote available because the claim covers absence of code: the route's only non-mock error paths are the 400 for missing `leanCode` and pass-through of verifier HTTP errors, both quoted or cited under Claims 3 and 6).

**Evidence:** `app/lib/formalization/api.ts:103-125`, `app/api/verification/lean/route.ts:8-40`

---

## Claim 9: "`OPENROUTER_API_KEY` — Acts as a fallback LLM provider when `ANTHROPIC_API_KEY` is unset. **Privacy note:** prompts (including your source material) are sent to OpenRouter when this path is used."

**Location:** `README.md:114`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The provider chain checks the Anthropic key first and falls through to OpenRouter only when it is absent:

```ts
// app/lib/llm/callLlm.ts:112-118
  const anthropicKey = process.env.ANTHROPIC_API_KEY;
  const openRouterKey = process.env.OPENROUTER_API_KEY;
  const effectiveModel = anthropicKey
    ? (anthropicModel ?? DEFAULT_ANTHROPIC_MODEL)
    : (openRouterKey && openRouterModel)
      ? openRouterModel
      : "mock";
```

The streaming path mirrors it: "Provider chain mirrors callLlm(): Anthropic → OpenRouter → mock." (`app/lib/llm/streamLlm.ts:76`) with the same key checks at `app/lib/llm/streamLlm.ts:87-93`. One internal condition the table omits: the OpenRouter branch also requires the endpoint to pass an `openRouterModel` — but every LLM endpoint does (paraphrased — no quote available because the invariant is inferred from multiple call sites: all nine `callLlm`/`streamLlm` call sites in `app/api/*/route.ts` and `app/lib/formalization/artifactRoute.ts` pass `openRouterModel: OPENROUTER_MODEL`), so the user-facing claim holds. The privacy note is confirmed by the request body sent to OpenRouter:

```ts
// app/lib/llm/callLlm.ts:164-179 (excerpt)
    const response = await fetch(OPENROUTER_API_URL, {
      ...
      body: JSON.stringify({
        model: openRouterModel,
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: userContent },
        ],
```

`userContent` carries the user's source material from the calling endpoints, and `OPENROUTER_API_URL` is the third-party host `"https://openrouter.ai/api/v1/chat/completions"` (`app/lib/llm/callLlm.ts:7`).

**Evidence:** `app/lib/llm/callLlm.ts:7`, `app/lib/llm/callLlm.ts:112-118`, `app/lib/llm/callLlm.ts:162-183`, `app/lib/llm/streamLlm.ts:76-93`, `app/api/edit/whole/route.ts:29`, `app/api/formalization/lean/route.ts:104`

---

## Claim 10: "`LEAN_VERIFIER_URL` — Points the Lean type-check API at a running verifier. The verifier ... cannot run on Vercel; host it elsewhere ... When unset, Lean code is generated but the type-check step returns the mock-valid response."

**Location:** `README.md:115`
**Type:** Configuration / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High

Setting the variable does point the route at the given host — the route fetches `${LEAN_VERIFIER_URL}/verify` (`app/api/verification/lean/route.ts:21`, and the env read with default at `app/api/verification/lean/route.ts:3-4`, quoted under Claim 3). The "when unset → mock-valid" sentence is accurate *in the Vercel context this table addresses* (unset → default `http://localhost:3100` → unreachable from a Vercel Function → catch → mock), but as written it is the same slight imprecision as Claim 3: unset does not itself trigger the mock; the code substitutes the localhost default and only mocks when that is unreachable:

```ts
// app/api/verification/lean/route.ts:3-4
const LEAN_VERIFIER_URL =
  process.env.LEAN_VERIFIER_URL ?? "http://localhost:3100";
```

In dev with the Docker verifier running, an unset variable still produces real type-checking. The "cannot run on Vercel" half carries the same external-platform caveat as Claim 2.

**Evidence:** `app/api/verification/lean/route.ts:3-4`, `app/api/verification/lean/route.ts:21-40`, `docker-compose.yml:1-16`

---

## Claim 11: "**Analytics history** is written to the local filesystem and does not persist across Vercel function invocations; treat the analytics panel as dev-only."

**Location:** `README.md:120`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium

Analytics writes do target the local filesystem:

```ts
// app/lib/analytics/persist.ts:14-17
export function appendAnalyticsEntry(entry: AnalyticsEntry): void {
  ensureDir();
  appendFileSync(FILE_PATH, JSON.stringify(entry) + "\n", "utf-8");
}
```

with `FILE_PATH` under `process.cwd()` (`app/lib/analytics/persist.ts:5-6`, quoted under Claim 5). "Does not persist across invocations" is directionally right but imprecise about mechanism: because the path is under the deployment's working directory — read-only on Vercel — the write is expected to *fail on every invocation* and be silently swallowed by the caller's catch (`app/lib/llm/callLlm.ts:84-91`, quoted under Claim 5), so nothing is ever written, rather than being written and then lost. The reader-facing consequence ("treat the analytics panel as dev-only" — the GET returns `[]` when the file is absent, `app/lib/analytics/persist.ts:20` `if (!existsSync(FILE_PATH)) return [];`) is correct either way. Medium confidence because the on-Vercel write failure is platform behavior, not statically provable from the repo.

**Evidence:** `app/lib/analytics/persist.ts:5-36`, `app/lib/llm/callLlm.ts:84-91`, `app/api/analytics/route.ts:4-12`

---

## Claim 12: "the 'falls back to `{ valid: true, mock: true }`' claim is no longer accurate (the route now signals the verifier is offline rather than silently passing)"

**Location:** commit `1859488` (message body)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High

The route at this branch (unchanged by either commit — the branch diff touches only `CLAUDE.md` and `README.md`, so `route.ts` is identical to main) does exactly what the commit message denies — it silently passes:

```ts
// app/api/verification/lean/route.ts:37-40
  } catch {
    // Service unavailable — fall back to mock
    return NextResponse.json({ valid: true, mock: true });
  }
```

There is no "verifier offline" signal anywhere in the route or its consumers (paraphrased — no quote available because the claim covers absence of code; greps for "offline" across `app/` hit only unrelated LLM files). The follow-up commit `4329d6e` explicitly acknowledges and reverses this error: "Replace the inaccurate 'verifier offline — proof not checked' claims in CLAUDE.md and README.md with accurate description of the current behavior on this branch (silent mock `{ valid: true, mock: true }` response)." So the mismatch was already caught in-branch, but the `1859488` message itself makes a false behavioral claim about the code as of that commit.

**Evidence:** `app/api/verification/lean/route.ts:37-40`, `git log main..review` (commit messages `1859488`, `4329d6e`), `git diff main...review --stat`

---

## Claim 13: "Remove OPENALEX_MAILTO from the optional env var table; OpenAlex / evidence-search is not on this branch's main yet."

**Location:** commit `4329d6e` (message body)
**Type:** Staleness / Architectural
**Verdict:** Verified
**Confidence:** High

No OpenAlex integration exists on `main` or `review`: `git grep -il openalex main` returns zero hits, and a repo-wide search (excluding `node_modules`) on the `review` checkout also returns nothing (paraphrased — no quote available because the claim covers absence of code — no matching grep results on either ref). The env-var table on `review` correctly no longer lists `OPENALEX_MAILTO` (`README.md:112-115` lists only `OPENROUTER_API_KEY` and `LEAN_VERIFIER_URL`).

**Evidence:** `README.md:112-115`, `git grep -il openalex main` (zero hits)

---

## Claim 14: "accurately describe verifier behavior ... accurate description of the current behavior on this branch (silent mock `{ valid: true, mock: true }` response). The graceful-degradation behavior lives on a sibling branch and will replace these descriptions on merge."

**Location:** commit `4329d6e` (message subject and body)
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High

The behavioral half is verified: the route's current behavior is the silent mock response, exactly as the commit describes:

```ts
// app/api/verification/lean/route.ts:37-40
  } catch {
    // Service unavailable — fall back to mock
    return NextResponse.json({ valid: true, mock: true });
  }
```

and the rewritten docs describe it faithfully (Claims 3, 6, 7 above). The sibling-branch reference cannot be confirmed from this clone — `git branch -a` shows only `main` and `review` (paraphrased — no quote available because the claim covers absence of code: no other branch or remote ref exists in this repository copy). That side reference does not undermine the verified behavioral claim, which is the load-bearing half.

**Evidence:** `app/api/verification/lean/route.ts:37-40`, `git branch -a` output (only `main`, `review`)

---

## Claim 15: "No code change." / "No code changes."

**Location:** commits `4329d6e` and `1859488` (message bodies)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High

The full branch diff touches only documentation: `git diff main...review --stat` reports `CLAUDE.md | 10 ++++++++++` and `README.md | 34 +++++++++++++++++++++++++++++++---` and nothing else (paraphrased — no quote available because the claim is about the diff's file list, not a code snippet). Each commit individually also touches only these two files.

**Evidence:** `git diff main...review --stat`, `git show --stat 1859488`, `git show --stat 4329d6e`

---

## Claim 16: "Lint clean; 221/221 tests pass."

**Location:** commit `4329d6e` (message body)
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Low

The claim requires running the lint and test suites, which is not possible in this environment: the project's `node_modules/.bin` contains no `vitest` binary, and invoking vitest via npx fails with `MODULE_NOT_FOUND` resolving `vitest.config.ts` dependencies (paraphrased — no quote available because the claim requires runtime execution that the environment cannot perform). As a plausibility check only: a static count of `it(`/`test(` occurrences across the repo's `*.test.ts`/`*.test.tsx` files totals approximately 223, which is consistent in magnitude with a 221-test suite (some occurrences are `it.each` templates or nested), but this does not verify that they pass. Verifying would need a working install (`npm ci` or equivalent) and a `vitest run` / lint run.

**Evidence:** `vitest.config.ts`, `package.json`, `app/**/*.test.ts(x)` (static count only)

---

## Claims Requiring Attention

### Incorrect
- **Claim 12** (`commit 1859488`): The message asserts the route "now signals the verifier is offline rather than silently passing"; the route silently returns `{ valid: true, mock: true }` (`app/api/verification/lean/route.ts:37-40`). The follow-up commit `4329d6e` already corrected the docs, but the `1859488` message remains a false record of behavior.

### Stale
- None.

### Mostly Accurate
- **Claim 3** (`CLAUDE.md:76`): "unset" alone does not trigger the mock — the route substitutes `http://localhost:3100` and mocks only when that is unreachable; non-OK verifier responses are passed through, not mocked.
- **Claim 5** (`CLAUDE.md:77`): the cache/analytics writers target `data/` under `process.cwd()`, not `/tmp`; on Vercel these writes fail (read-only cwd) and are silently swallowed rather than landing in ephemeral warm-container storage.
- **Claim 10** (`README.md:115`): "when unset → mock-valid" is accurate on Vercel but not universally — unset in dev with the local verifier running still yields real type-checking.
- **Claim 11** (`README.md:120`): analytics history on Vercel is never written at all (silent write failure), rather than written and lost across invocations; the dev-only conclusion stands.

### Unverifiable
- **Claim 16** (`commit 4329d6e`): "Lint clean; 221/221 tests pass" needs a working dependency install and a `vitest run`/lint execution; static test-count (~223 `it`/`test` sites) is merely consistent.
