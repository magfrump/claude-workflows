# Code Fact-Check Report

Commit: 4329d6e

**Repository:** `/workspace/external/cc-review-eval/mfc-deploy`
**Scope:** `git diff main...review` — `CLAUDE.md`, `README.md`, plus branch commit messages (`git log main..review`: `1859488`, `4329d6e`)
**Checked:** 2026-08-15
**Total claims checked:** 22
**Summary:** 13 verified, 5 mostly accurate, 0 stale, 1 incorrect, 3 unverifiable

---

## Claim 1: "There is no shared hosted instance and no demo mode."

**Location:** `CLAUDE.md:73`
**Type:** Architectural / Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium

There is no hosted-instance configuration in the repo: no `vercel.json`, and `next.config.ts` carries no deployment or multi-tenant settings (paraphrased — no quote available because the claim covers the absence of code; `ls vercel.json` returns "No such file or directory" and the config body is the empty object below).

```ts
// next.config.ts:3-5
const nextConfig: NextConfig = {
  /* config options here */
};
```

The "no demo mode" half is imprecise: when neither key is configured the LLM layer takes a mock branch rather than erroring, which functions as a keyless demo path:

```ts
// app/lib/llm/callLlm.ts:203-204
  // Mock fallback — caller provides its own mock text
  console.warn(`[${endpoint}] No API key configured — returning mock response.\n\n To generate real responses, add ANTHROPIC_API_KEY or OPENROUTER_API_KEY to .env.local`);
```

A precise version would say there is no *user-facing* demo mode, while noting that a keyless deployment silently serves mock LLM output.

**Evidence:** `next.config.ts:1-7`, `app/lib/llm/callLlm.ts:203-216`, `app/lib/llm/streamLlm.ts:140-157`

---

## Claim 2: "There is no in-browser BYO-key flow; keys live in the Vercel project's environment variables (or `.env.local` in dev)."

**Location:** `CLAUDE.md:75`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High

A case-insensitive grep for `apikey|api_key|api key` across `app/components`, `app/hooks`, and `app/lib/stores` returns zero hits, so no client component, hook, or store collects or stores a key (paraphrased — no quote available because the claim covers the absence of code; there are no matching grep results to quote). There are likewise no `NEXT_PUBLIC_*` references anywhere in the source tree, so no key is exposed to the browser bundle (paraphrased — no quote available because this too is an absence-of-code claim with zero grep results).

Keys are read only server-side, from `process.env`:

```ts
// app/lib/llm/callLlm.ts:100-101
  const anthropicKey = process.env.ANTHROPIC_API_KEY;
  const openRouterKey = process.env.OPENROUTER_API_KEY;
```

**Evidence:** `app/lib/llm/callLlm.ts:100-101`, `app/lib/llm/streamLlm.ts:85-92`, `app/components/**`, `app/hooks/**`

---

## Claim 3: "The Lean verifier is a separate Dockerized service and cannot run inside a Vercel Function."

**Location:** `CLAUDE.md:76`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** Medium

The verifier is defined as its own Compose service with its own Dockerfile and port:

```yaml
# docker-compose.yml:1-9
services:
  lean-verifier:
    build:
      context: ./verifier
      dockerfile: Dockerfile
    ports:
      - "3100:3100"
```

The Next.js side reaches it only over HTTP, never in-process:

```ts
// app/api/verification/lean/route.ts:22
    const res = await fetch(`${LEAN_VERIFIER_URL}/verify`, {
```

Confidence is Medium rather than High because the "cannot run inside a Vercel Function" half is a claim about the Vercel platform's runtime, which is not decidable from this codebase.

**Evidence:** `docker-compose.yml:1-15`, `app/api/verification/lean/route.ts:19-27`

---

## Claim 4: "When `LEAN_VERIFIER_URL` is unset or unreachable, `app/api/verification/lean/route.ts` falls back to a mock `{ valid: true, mock: true }` response."

**Location:** `CLAUDE.md:76`
**Type:** Behavioral / Configuration
**Verdict:** Mostly accurate
**Confidence:** High

The *unreachable* half is exact — a thrown `fetch` (connection refused, DNS failure, or the 35s abort) lands in the catch block:

```ts
// app/api/verification/lean/route.ts:38-41
  } catch {
    // Service unavailable — fall back to mock
    return NextResponse.json({ valid: true, mock: true });
  }
```

The *unset* half is imprecise. The route does not test whether the variable is set; it substitutes a default and then makes a real request to it:

```ts
// app/api/verification/lean/route.ts:3-4
const LEAN_VERIFIER_URL =
  process.env.LEAN_VERIFIER_URL ?? "http://localhost:3100";
```

So with the variable unset *and* a local verifier running on port 3100 — the documented dev setup — the route type-checks for real and does not mock. "Unset" only produces the mock when nothing is listening on `http://localhost:3100`, which is the Vercel case but not the dev case.

A second imprecision: an *unreachable* verifier that nonetheless answers with an HTTP error status is not mocked — the error is forwarded to the client:

```ts
// app/api/verification/lean/route.ts:32-34
    if (!res.ok) {
      return NextResponse.json(data, { status: res.status });
    }
```

**Evidence:** `app/api/verification/lean/route.ts:3-4`, `app/api/verification/lean/route.ts:22-41`

---

## Claim 5: "`useFormalizationPipeline` treats it as `valid` and there is currently no 'verifier offline' UI state."

**Location:** `CLAUDE.md:76`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High

The client helper coerces the response to a boolean and discards the `mock` flag entirely:

```ts
// app/lib/formalization/api.ts:103-111
export async function verifyLean(leanCode: string) {
  const res = await fetch("/api/verification/lean", {
    ...
  const data = await res.json();
  return { valid: Boolean(data.valid), errors: (data.errors as string | undefined) ?? "" };
}
```

The pipeline maps that boolean straight onto the `valid` status:

```ts
// app/hooks/useFormalizationPipeline.ts:140-144
    const { valid, errors } = await verifyLean(fullCode);
    const vStatus = valid ? "valid" as const : "invalid" as const;
    const vErrors = valid ? "" : errors || "Verification failed";
    a.setVerificationStatus(vStatus);
```

The status type admits no offline state:

```ts
// app/lib/types/session.ts:1
export type VerificationStatus = "none" | "verifying" | "valid" | "invalid";
```

and the badge renders the mock result as "Verified":

```tsx
// app/components/ui/VerificationBadge.tsx:8-10
  if (status === "valid") {
    return <span className="ml-2 text-xs font-normal text-green-700">Verified</span>;
  }
```

**Evidence:** `app/lib/formalization/api.ts:103-111`, `app/hooks/useFormalizationPipeline.ts:118-130`, `app/hooks/useFormalizationPipeline.ts:137-146`, `app/lib/types/session.ts:1`, `app/components/ui/VerificationBadge.tsx:1-12`

---

## Claim 6: "The LLM cache and analytics log write to the local filesystem in dev."

**Location:** `CLAUDE.md:77`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High

Both write under `process.cwd()/data`. The cache writes one JSON file per hash:

```ts
// app/lib/llm/cache.ts:7
const CACHE_DIR = join(process.cwd(), "data", "cache");
```
```ts
// app/lib/llm/cache.ts:60-67
export async function setCachedResult(
  hash: string,
  result: CachedResult
): Promise<void> {
  await ensureCacheDir();
  const filePath = join(CACHE_DIR, `${hash}.json`);
  await writeFile(filePath, JSON.stringify(result, null, 2), "utf-8");
}
```

The analytics log appends JSONL to a sibling file:

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

**Evidence:** `app/lib/llm/cache.ts:7`, `app/lib/llm/cache.ts:26-32`, `app/lib/llm/cache.ts:60-67`, `app/lib/analytics/persist.ts:5-17`

---

## Claim 7: "Vercel Functions can only write to `/tmp` and that lasts only as long as the warm container."

**Location:** `CLAUDE.md:77`
**Type:** Configuration / Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium

The claim itself is about the Vercel runtime's filesystem semantics, which cannot be established from this repository — verifying it would require Vercel platform documentation or a deployed function (paraphrased — no quote available because the claim concerns an external hosting platform, not code in this repo).

What *is* checkable is that no code in the repo writes to `/tmp`, or is capable of being redirected there: a repo-wide grep for `/tmp` across `app/` returns zero hits, and both persistence modules hardcode `process.cwd()`-relative paths with no environment override (paraphrased — no quote available because this is an absence-of-code claim with zero grep results; the hardcoded paths are quoted in Claim 6). Taken with the platform premise the bullet asserts, the operative consequence on Vercel is stronger than "best-effort": `appendFileSync` and `writeFile` against a read-only `process.cwd()` would throw rather than write ephemerally. Those throws are swallowed:

```ts
// app/lib/llm/callLlm.ts:82-91
  try {
    appendAnalyticsEntry({
      ...
  } catch { /* persistence failure must not break LLM calls */ }
  const result: CallLlmResult = { text, usage, cacheKey };
  if (text) {
    try { await setCachedResult(cacheHash, result); } catch { /* cache write failure is non-fatal */ }
  }
```

**Evidence:** `app/lib/llm/cache.ts:7`, `app/lib/analytics/persist.ts:5-17`, `app/lib/llm/callLlm.ts:73-92`, `app/lib/llm/streamLlm.ts:48-66`

---

## Claim 8: "update both `README.md` (Deploy to Vercel section) and this file."

**Location:** `CLAUDE.md:79`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High

The referenced section exists at the cited name:

```md
# README.md:98
## Deploy to Vercel
```

**Evidence:** `README.md:98-120`

---

## Claim 9: Deploy button target — `repository-url=https://github.com/aditya-adiga/meta-formalism-copilot`, `envLink=...#deploy-to-vercel`

**Location:** `README.md:5`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium

The in-repo half checks out: the `#deploy-to-vercel` anchor resolves to the heading quoted in Claim 8, and the single required env var named in the button (`env=ANTHROPIC_API_KEY`) matches the required-variable table:

```md
# README.md:106
| `ANTHROPIC_API_KEY` | https://console.anthropic.com — create a key with API access. |
```

The GitHub repository URL cannot be checked: `git remote -v` produces no output, so this clone has no configured remote to compare against, and network access to GitHub is out of scope for a static check (paraphrased — no quote available because the command returns empty output, and confirming the URL requires an external system). Verifying it would need either a configured remote or a fetch of the GitHub URL.

**Evidence:** `README.md:5`, `README.md:98`, `README.md:104-106`

---

## Claim 10: "When the service is not reachable, the verification API route returns a mock `{ valid: true, mock: true }` response so the rest of the app keeps working"

**Location:** `README.md:64`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The literal shape and the not-reachable trigger both match the catch branch:

```ts
// app/api/verification/lean/route.ts:38-41
  } catch {
    // Service unavailable — fall back to mock
    return NextResponse.json({ valid: true, mock: true });
  }
```

Unlike the CLAUDE.md phrasing in Claim 4, this sentence scopes the fallback to unreachability only, which is exactly what the code implements — the abort controller extends "not reachable" to include a 35-second timeout:

```ts
// app/api/verification/lean/route.ts:5
const REQUEST_TIMEOUT_MS = 35_000;
```

**Evidence:** `app/api/verification/lean/route.ts:5`, `app/api/verification/lean/route.ts:19-41`

---

## Claim 11: "generated Lean code is reported as valid without actually being type-checked"

**Location:** `README.md:64`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The mock body sets `valid: true` without any Lean process being invoked — the catch branch is reached precisely because the `fetch` to the verifier failed:

```ts
// app/api/verification/lean/route.ts:22-41
    const res = await fetch(`${LEAN_VERIFIER_URL}/verify`, {
    ...
  } catch {
    // Service unavailable — fall back to mock
    return NextResponse.json({ valid: true, mock: true });
  }
```

Downstream, that `true` is surfaced to the user as "Verified" with no mock indication, as quoted in Claim 5.

**Evidence:** `app/api/verification/lean/route.ts:22-41`, `app/lib/formalization/api.ts:103-111`, `app/components/ui/VerificationBadge.tsx:8-10`

---

## Claim 12: "The Next.js route reads `LEAN_VERIFIER_URL` from the environment (defaults to `http://localhost:3100`)."

**Location:** `README.md:88`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High

Both halves are literal:

```ts
// app/api/verification/lean/route.ts:3-4
const LEAN_VERIFIER_URL =
  process.env.LEAN_VERIFIER_URL ?? "http://localhost:3100";
```

The default also matches the port the Compose service publishes:

```yaml
# docker-compose.yml:6-9
    ports:
      - "3100:3100"
    environment:
      - PORT=3100
```

Note the reconciliation with Claim 4: because a default is substituted, "unset" is never observed as a distinct branch — an unset variable produces a live request to `http://localhost:3100`, and only the failure of that request yields the mock.

**Evidence:** `app/api/verification/lean/route.ts:3-4`, `docker-compose.yml:6-9`

---

## Claim 13: "When the verifier is unreachable, the route falls back to the mock response described above."

**Location:** `README.md:88`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

Same catch branch as Claim 10:

```ts
// app/api/verification/lean/route.ts:38-41
  } catch {
    // Service unavailable — fall back to mock
    return NextResponse.json({ valid: true, mock: true });
  }
```

**Evidence:** `app/api/verification/lean/route.ts:38-41`

---

## Claim 14: "The rest of the app keeps working without the verifier. Lean code can still be generated and edited; the type-check step returns the mock-valid response."

**Location:** `README.md:96`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** Medium

Lean generation is a separate route that never contacts the verifier — it goes through the LLM layer:

```ts
// app/lib/formalization/api.ts:117-121
  const data = await fetchApi<{ leanCode: string }>(
    "/api/formalization/lean",
    { informalProof, previousAttempt, errors, instruction, contextLeanCode },
  );
  return data.leanCode;
```

The verifier's absence surfaces only through `verifyLean`, whose two call sites are the pipeline's verify step and the retry loop (paraphrased — no quote available because the assertion is an inventory of grep hits across three files rather than a single snippet: `app/hooks/useFormalizationPipeline.ts:140`, `app/lib/formalization/leanRetryLoop.ts:69`, and the definition at `app/lib/formalization/api.ts:103`). Confidence is Medium because "keeps working" is a broad claim about the whole UI that static reading can support only for the generation and verification paths.

**Evidence:** `app/lib/formalization/api.ts:103-121`, `app/hooks/useFormalizationPipeline.ts:140`, `app/lib/formalization/leanRetryLoop.ts:69`

---

## Claim 15: "Required environment variable | `ANTHROPIC_API_KEY`"

**Location:** `README.md:102-106`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High

`ANTHROPIC_API_KEY` is not required for the app to boot or serve requests — it is the first of three branches, and its absence degrades to OpenRouter or to mock output rather than failing:

```ts
// app/lib/llm/callLlm.ts:126-127
  if (anthropicKey) {
    const model = anthropicModel ?? DEFAULT_ANTHROPIC_MODEL;
```
```ts
// app/lib/llm/callLlm.ts:162
  if (openRouterKey && openRouterModel) {
```
```ts
// app/lib/llm/callLlm.ts:203-204
  // Mock fallback — caller provides its own mock text
  console.warn(`[${endpoint}] No API key configured — returning mock response.\n\n To generate real responses, add ANTHROPIC_API_KEY or OPENROUTER_API_KEY to .env.local`);
```

The precise version would be "required for real LLM responses unless `OPENROUTER_API_KEY` is set" — which is what the optional-variable row (Claim 16) already implies, making the two table headings mildly inconsistent with each other.

**Evidence:** `app/lib/llm/callLlm.ts:114-118`, `app/lib/llm/callLlm.ts:126-127`, `app/lib/llm/callLlm.ts:162`, `app/lib/llm/callLlm.ts:203-216`

---

## Claim 16: "`OPENROUTER_API_KEY` | Acts as a fallback LLM provider when `ANTHROPIC_API_KEY` is unset. **Privacy note:** prompts (including your source material) are sent to OpenRouter when this path is used."

**Location:** `README.md:114`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High

The OpenRouter branch is reached only after the Anthropic branch is skipped, i.e. only when `ANTHROPIC_API_KEY` is falsy:

```ts
// app/lib/llm/callLlm.ts:126-127
  if (anthropicKey) {
    const model = anthropicModel ?? DEFAULT_ANTHROPIC_MODEL;
```
```ts
// app/lib/llm/callLlm.ts:162
  if (openRouterKey && openRouterModel) {
```

The same gating holds in the streaming path:

```ts
// app/lib/llm/streamLlm.ts:127
        } else if (openRouterKey && openRouterModel) {
```

The privacy note is exact — both the system prompt and the user content are placed in the outbound request body to OpenRouter:

```ts
// app/lib/llm/callLlm.ts:163-178
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

The extra `&& openRouterModel` conjunct does not falsify the claim: every LLM-calling route supplies a model constant, so the key alone is sufficient in practice (paraphrased — no quote available because the assertion is an inventory of ten call sites across separate route files: `app/api/edit/inline/route.ts:21`, `app/api/edit/whole/route.ts:29`, `app/api/edit/artifact/route.ts:51`, `app/api/explanation/lean-error/route.ts:30`, `app/api/refine/context/route.ts:46`, `app/api/formalization/lean/route.ts:104` and `:128`, `app/api/decomposition/extract/route.ts:116`, and `app/lib/formalization/artifactRoute.ts:76` and `:87`).

One nuance the row does not state: this is a fallback on *key absence*, not on Anthropic request failure — a set-but-failing `ANTHROPIC_API_KEY` throws rather than routing to OpenRouter, since the Anthropic branch returns unconditionally.

**Evidence:** `app/lib/llm/callLlm.ts:7`, `app/lib/llm/callLlm.ts:100-101`, `app/lib/llm/callLlm.ts:126-160`, `app/lib/llm/callLlm.ts:162-201`, `app/lib/llm/streamLlm.ts:85-135`

---

## Claim 17: "`LEAN_VERIFIER_URL` ... When unset, Lean code is generated but the type-check step returns the mock-valid response."

**Location:** `README.md:115`
**Type:** Behavioral / Configuration
**Verdict:** Mostly accurate
**Confidence:** High

Same imprecision as Claim 4, and it now sits two lines below the `http://localhost:3100` default documented at `README.md:88`. Unset does not by itself produce the mock; it produces a request to the default URL:

```ts
// app/api/verification/lean/route.ts:3-4
const LEAN_VERIFIER_URL =
  process.env.LEAN_VERIFIER_URL ?? "http://localhost:3100";
```

The statement is true in the Vercel context the table describes (nothing listens on the function's own localhost:3100), and false in dev with `docker compose up` running. Precise version: "When unset and no verifier is reachable at the default `http://localhost:3100`, ...".

**Evidence:** `app/api/verification/lean/route.ts:3-4`, `app/api/verification/lean/route.ts:22-41`, `README.md:88`

---

## Claim 18: "**Lean verification** runs only when `LEAN_VERIFIER_URL` points at a separately hosted verifier."

**Location:** `README.md:119`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** Medium

Real verification happens exclusively via the outbound HTTP call; there is no in-process Lean path in the route, and any failure of that call short-circuits to the mock:

```ts
// app/api/verification/lean/route.ts:22-41
    const res = await fetch(`${LEAN_VERIFIER_URL}/verify`, {
    ...
  } catch {
    // Service unavailable — fall back to mock
    return NextResponse.json({ valid: true, mock: true });
  }
```

Confidence is Medium because the claim is scoped to Vercel, and the assertion that a Vercel Function cannot itself host the verifier is a platform fact outside this codebase (see Claim 3).

**Evidence:** `app/api/verification/lean/route.ts:19-41`, `docker-compose.yml:1-15`

---

## Claim 19: "**Analytics history** is written to the local filesystem and does not persist across Vercel function invocations; treat the analytics panel as dev-only."

**Location:** `README.md:120`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium

The write target is correct — `process.cwd()/data/analytics.jsonl`, quoted in Claim 6 — and the user-facing conclusion ("dev-only") follows. The stated mechanism is imprecise in a way that matters to a reader reasoning about the Vercel case. Given the read-only-filesystem premise the branch's own CLAUDE.md asserts (Claim 7), the entry is not written-then-lost: `appendFileSync` against a read-only path throws, and every call site swallows the throw:

```ts
// app/lib/llm/callLlm.ts:83-89
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

Consequently the panel's read path returns an empty list rather than a partial in-invocation history:

```ts
// app/lib/analytics/persist.ts:19-21
export function readAnalyticsEntries(): AnalyticsEntry[] {
  if (!existsSync(FILE_PATH)) return [];
```

Precise version: "is written to the local filesystem in dev; on Vercel the write fails silently and no analytics history is recorded at all." Confidence is Medium because the read-only-filesystem premise is a platform fact, not a code fact (see Claim 7).

**Evidence:** `app/lib/analytics/persist.ts:5-32`, `app/lib/llm/callLlm.ts:81-91`, `app/lib/llm/callLlm.ts:210-217`, `app/lib/llm/streamLlm.ts:54-62`, `app/api/analytics/route.ts:1-12`

---

## Claim 20: "Remove `OPENALEX_MAILTO` from the optional env var table; OpenAlex / evidence-search is not on this branch's main yet."

**Location:** commit `4329d6e` (message body)
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High

A repo-wide grep for `OPENALEX` across `*.ts`, `*.tsx`, and `*.md` (excluding `node_modules`) returns zero hits, so neither the env var nor any OpenAlex/evidence-search code exists on this branch (paraphrased — no quote available because the claim covers the absence of code and there are no matching grep results to quote). The removal is also visible in the diff: the current optional table lists only `OPENROUTER_API_KEY` and `LEAN_VERIFIER_URL`.

```md
# README.md:112-115
| Variable | Effect when set |
|---|---|
| `OPENROUTER_API_KEY` | Acts as a fallback LLM provider when `ANTHROPIC_API_KEY` is unset. ...
| `LEAN_VERIFIER_URL` | Points the Lean type-check API at a running verifier. ...
```

**Evidence:** `README.md:112-115`, repo-wide grep for `OPENALEX` (0 hits)

---

## Claim 21: "No code change. Lint clean; 221/221 tests pass."

**Location:** commit `4329d6e` (message body); same "No code changes." claim in commit `1859488`
**Type:** Behavioral / Reference
**Verdict:** Unverifiable
**Confidence:** Medium

The "no code change" half is confirmed — the branch diff touches only the two Markdown files:

```
$ git diff --stat main...review
 CLAUDE.md | 10 ++++++++++
 README.md | 34 +++++++++++++++++++++++++++++++---
 2 files changed, 41 insertions(+), 3 deletions(-)
```

The lint and test-pass halves require running `eslint` and the test suite, which is outside static analysis (paraphrased — no quote available because the claim is about the outcome of executing tooling, not about code content). The denominator is at least consistent: counting `it(`/`test(` declarations across `app/**/*.test.ts{,x}` yields exactly 221 (paraphrased — no quote available because the figure is an aggregate count over many test files rather than a single snippet). Verifying the claim outright would require executing the lint and test commands.

**Evidence:** `git diff --stat main...review`, `app/**/*.test.ts`, `app/**/*.test.tsx`

---

## Claim 22: "corrected the Lean verifier section — the 'falls back to `{ valid: true, mock: true }`' claim is no longer accurate (the route now signals the verifier is offline rather than silently passing)."

**Location:** commit `1859488` (message body)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High

The route on this branch does exactly what the commit message says is no longer accurate — it silently returns the mock-valid body, with no offline signal in the payload beyond the `mock` flag that `verifyLean` discards (Claim 5):

```ts
// app/api/verification/lean/route.ts:38-41
  } catch {
    // Service unavailable — fall back to mock
    return NextResponse.json({ valid: true, mock: true });
  }
```

The later commit on the same branch, `4329d6e`, records the same finding and reverts the documentation, attributing the offline-signalling behavior to a sibling branch: "Replace the inaccurate 'verifier offline — proof not checked' claims in CLAUDE.md and README.md with accurate description of the current behavior on this branch (silent mock `{ valid: true, mock: true }` response)." The shipped documentation is therefore correct; only the intermediate commit message misstates the code.

**Evidence:** `app/api/verification/lean/route.ts:38-41`, `app/lib/formalization/api.ts:103-111`, commit `4329d6e` message body

---

## Claims Requiring Attention

### Incorrect
- **Claim 22** (commit `1859488`): Commit message asserts the verification route "now signals the verifier is offline rather than silently passing"; the route still returns `{ valid: true, mock: true }` on any fetch failure. The branch's later commit `4329d6e` already corrected the documentation, so no doc change is outstanding — the record lives only in git history.

### Stale
- None.

### Mostly Accurate
- **Claim 1** (`CLAUDE.md:73`): "no demo mode" — a keyless deployment still serves mock LLM output via the `provider: "mock"` branch; scope the claim to *user-facing* demo mode.
- **Claim 4** (`CLAUDE.md:76`): "unset or unreachable" conflates two cases — unset substitutes the `http://localhost:3100` default and only mocks if that is unreachable; and a verifier returning a non-OK HTTP status is forwarded, not mocked.
- **Claim 15** (`README.md:102-106`): `ANTHROPIC_API_KEY` is labelled "Required" but its absence degrades to OpenRouter or mock output; say "required for real LLM responses unless `OPENROUTER_API_KEY` is set."
- **Claim 17** (`README.md:115`): "When unset, ... returns the mock-valid response" — true only because nothing listens on the default `http://localhost:3100` on Vercel; false in dev with the Compose verifier running.
- **Claim 19** (`README.md:120`): "written to the local filesystem and does not persist across Vercel function invocations" states the wrong mechanism — the write to `process.cwd()/data` throws on Vercel's read-only filesystem and is swallowed, so nothing is written at all rather than written-then-lost.

### Unverifiable
- **Claim 7** (`CLAUDE.md:77`): "Vercel Functions can only write to `/tmp`" is a platform fact; confirming it needs Vercel documentation or a deployed function. Worth noting that no code in the repo targets `/tmp` — both persistence modules hardcode `process.cwd()`-relative paths with no override.
- **Claim 9** (`README.md:5`): The deploy button's `repository-url` cannot be checked — `git remote -v` is empty in this clone; needs a configured remote or a network fetch of the GitHub URL.
- **Claim 21** (commit `4329d6e`): "Lint clean; 221/221 tests pass" needs the lint and test commands executed. The 221 denominator matches a static count of `it(`/`test(` declarations; the "no code change" half is verified by `git diff --stat`.
