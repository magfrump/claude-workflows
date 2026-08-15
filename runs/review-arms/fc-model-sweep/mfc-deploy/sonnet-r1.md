# Code Fact-Check Report

Commit: 4329d6e

**Repository:** /workspace/external/cc-review-eval/mfc-deploy
**Scope:** `git diff main...review` — `CLAUDE.md`, `README.md` (branch `review`, HEAD `4329d6e`)
**Checked:** 2026-08-15
**Total claims checked:** 11
**Summary:** 6 verified, 5 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

---

## Claim 1: "There is no in-browser BYO-key flow; keys live in the Vercel project's environment variables (or `.env.local` in dev)."

**Location:** `CLAUDE.md:75`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High

A search of the client-side components and hooks for any key-entry surface (`byo`, `api key` input) returns zero matches (paraphrased — no quote available because the claim covers absence of code; a grep for `byo|api.?key` across `app/components` and `app/hooks` produced no hits). The only place an API key is read is `process.env.ANTHROPIC_API_KEY` / `process.env.OPENROUTER_API_KEY` inside `callLlm`:

```ts
// app/lib/llm/callLlm.ts:112-113
const anthropicKey = process.env.ANTHROPIC_API_KEY;
const openRouterKey = process.env.OPENROUTER_API_KEY;
```

Both are server-side `process.env` reads inside an API-route-adjacent module, not values sourced from client state or a form. There is no code path where a browser-supplied key reaches `callLlm`.

**Evidence:** `app/lib/llm/callLlm.ts:112-113`; grep of `app/components`, `app/hooks` for key-entry UI (no hits)

---

## Claim 2: "When `LEAN_VERIFIER_URL` is unset or unreachable, `app/api/verification/lean/route.ts` falls back to a mock `{ valid: true, mock: true }` response."

**Location:** `CLAUDE.md:76`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High

The end state is correct — both an unset and an unreachable verifier ultimately produce the mock response — but the claim compresses two distinct steps into one. When the variable is unset, the code does not go straight to a mock branch; it first substitutes a default URL:

```ts
// app/api/verification/lean/route.ts:3-4
const LEAN_VERIFIER_URL =
  process.env.LEAN_VERIFIER_URL ?? "http://localhost:3100";
```

The mock response is returned only from the `catch` block wrapping the `fetch` call, which fires whenever that URL (default or explicit) is unreachable or the request throws:

```ts
// app/api/verification/lean/route.ts:19-36
try {
  ...
  const res = await fetch(`${LEAN_VERIFIER_URL}/verify`, { ... });
  ...
} catch {
  // Service unavailable — fall back to mock
  return NextResponse.json({ valid: true, mock: true });
}
```

So "unset" is not a separate branch that triggers the mock directly — it is a precursor state (default URL substitution) that reliably leads to the same `catch`-block mock in any environment where nothing listens on `localhost:3100` (which is the normal case on Vercel). The observable behavior matches the claim; the mechanism description slightly overstates that "unset" is itself a fallback trigger.

**Evidence:** `app/api/verification/lean/route.ts:3-4`, `app/api/verification/lean/route.ts:19-36`

---

## Claim 3: "This is a known silent-pass behavior — `useFormalizationPipeline` treats it as `valid` and there is currently no 'verifier offline' UI state."

**Location:** `CLAUDE.md:76`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High

`useFormalizationPipeline` branches purely on `result.valid` / `valid`, with no check of the `mock` field:

```ts
// app/hooks/useFormalizationPipeline.ts:121-124
const vStatus = result.valid ? "valid" as const : "invalid" as const;
a.setVerificationStatus(vStatus);
if (result.valid) a.setVerificationErrors("");
a.onSessionUpdate?.({ verificationStatus: vStatus, verificationErrors: result.valid ? "" : result.errors });
```

```ts
// app/hooks/useFormalizationPipeline.ts:140-143
const { valid, errors } = await verifyLean(fullCode);
const vStatus = valid ? "valid" as const : "invalid" as const;
```

Since a mock response has `valid: true`, both call sites set status `"valid"` identically to a real pass. A grep for any UI or hook code reading `.mock` / `mock:` outside test files returns no hits (paraphrased — no quote available because the claim covers absence of code; a repo-wide grep for `\.mock\b|mock:` in `app/hooks` and `app/components`, excluding tests, produced zero matches), confirming there is no distinct "verifier offline" UI state.

**Evidence:** `app/hooks/useFormalizationPipeline.ts:121-124`, `app/hooks/useFormalizationPipeline.ts:140-143`; grep of `app/hooks`, `app/components` for `.mock`/`mock:` (no hits outside tests)

---

## Claim 4: "Persistence on Vercel is best-effort. The LLM cache and analytics log write to the local filesystem in dev. Vercel Functions can only write to `/tmp` and that lasts only as long as the warm container — don't add features that assume durable filesystem state without an explicit storage backend."

**Location:** `CLAUDE.md:77`
**Type:** Behavioral / Configuration
**Verdict:** Mostly accurate
**Confidence:** Medium

The "writes to the local filesystem in dev" half is verified directly — both persistence modules resolve their target directory from `process.cwd()`, not from any `/tmp`-aware path:

```ts
// app/lib/llm/cache.ts:6
const CACHE_DIR = join(process.cwd(), "data", "cache");
```

```ts
// app/lib/analytics/persist.ts:5-6
const DATA_DIR = join(process.cwd(), "data");
const FILE_PATH = join(DATA_DIR, "analytics.jsonl");
```

Neither module, nor any config file in the repo, redirects these paths to `/tmp` on Vercel (paraphrased — no quote available because the claim covers absence of code; grep for `process.cwd|/tmp|VERCEL` in `app/lib/analytics` and `app/lib/llm` matches only the two `process.cwd()` lines quoted above, and there is no `vercel.json` in the repo root). This means the general Vercel platform fact stated in the second sentence ("Functions can only write to `/tmp`") is true as platform behavior but doesn't describe what *this code* does: the code never targets `/tmp` at all. On Vercel, `process.cwd()/data` sits outside the one writable exception, so — rather than succeeding and then being lost when the warm container recycles, as the "lasts only as long as the warm container" phrasing suggests — these writes are more likely to fail immediately on every invocation (a read-only-filesystem error). That failure is caught and swallowed at every call site (`app/lib/llm/callLlm.ts:94`, `:91`, `:219`; `app/lib/llm/streamLlm.ts:56-64`), so the app keeps functioning either way, but the "best-effort persistence with container-lifetime durability" framing overstates how far the writes actually get.

**Evidence:** `app/lib/llm/cache.ts:6`, `app/lib/analytics/persist.ts:5-6`, `app/lib/llm/callLlm.ts:84-96`, `app/lib/llm/callLlm.ts:212-219`, `app/lib/llm/streamLlm.ts:55-65`; grep for `process.cwd|/tmp|VERCEL` in `app/lib/analytics`, `app/lib/llm` (no `/tmp` or `VERCEL` references found); no `vercel.json` in repo root

---

## Claim 5: "When the service is not reachable, the verification API route returns a mock `{ valid: true, mock: true }` response so the rest of the app keeps working — note that this means generated Lean code is reported as valid without actually being type-checked."

**Location:** `README.md:64`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

Directly matches the route's `catch` block:

```ts
// app/api/verification/lean/route.ts:33-36
} catch {
  // Service unavailable — fall back to mock
  return NextResponse.json({ valid: true, mock: true });
}
```

As shown under Claim 3, `useFormalizationPipeline` treats `valid: true` identically whether it came from a real Lean check or this mock, so unchecked Lean code is indeed reported as valid.

**Evidence:** `app/api/verification/lean/route.ts:33-36`; `app/hooks/useFormalizationPipeline.ts:121-124`

---

## Claim 6: "**Configuration:** The Next.js route reads `LEAN_VERIFIER_URL` from the environment (defaults to `http://localhost:3100`). When the verifier is unreachable, the route falls back to the mock response described above."

**Location:** `README.md:88`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High

Both halves match the implementation exactly:

```ts
// app/api/verification/lean/route.ts:3-4
const LEAN_VERIFIER_URL =
  process.env.LEAN_VERIFIER_URL ?? "http://localhost:3100";
```

Unlike CLAUDE.md's Claim 2, this sentence correctly scopes the mock fallback to the "unreachable" case only (not to "unset" directly), which matches the `catch`-block trigger shown in Claim 2's evidence.

**Evidence:** `app/api/verification/lean/route.ts:3-4`, `app/api/verification/lean/route.ts:33-36`

---

## Claim 7: "The rest of the app keeps working without the verifier. Lean code can still be generated and edited; the type-check step returns the mock-valid response described above."

**Location:** `README.md:96`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

Lean code generation happens via `callLlm`/`streamLlm` (independent of the verifier route), and the verification step itself never throws out of `verifyLean`/`route.ts` — any fetch failure is caught and converted into the mock JSON response rather than propagated as an error:

```ts
// app/api/verification/lean/route.ts:19-36
try {
  ...
  const res = await fetch(`${LEAN_VERIFIER_URL}/verify`, { ... });
  ...
} catch {
  return NextResponse.json({ valid: true, mock: true });
}
```

Because the route always resolves with a 200 JSON body rather than an unhandled error, the pipeline's `try/catch` in `useFormalizationPipeline` (Claim 3 evidence) never hits its error branch on a verifier outage — generation and editing are unaffected.

**Evidence:** `app/api/verification/lean/route.ts:19-36`; `app/hooks/useFormalizationPipeline.ts:121-124`

---

## Claim 8: "`OPENROUTER_API_KEY` | Acts as a fallback LLM provider when `ANTHROPIC_API_KEY` is unset. **Privacy note:** prompts (including your source material) are sent to OpenRouter when this path is used."

**Location:** `README.md:114`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High

The effective-model / provider selection is gated exactly this way:

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

```ts
// app/lib/llm/callLlm.ts:131, 162
if (anthropicKey) { ... }
if (openRouterKey && openRouterModel) { ... }
```

OpenRouter is only reached in the `if (openRouterKey && openRouterModel)` branch, which is unreachable when `anthropicKey` is truthy because the `anthropicKey` branch above it `return`s first. The privacy note is also accurate — the full system prompt and user content (which includes source material passed up from the UI) are sent verbatim to OpenRouter's endpoint:

```ts
// app/lib/llm/callLlm.ts:164-178
const response = await fetch(OPENROUTER_API_URL, {
  method: "POST",
  headers: { "Content-Type": "application/json", Authorization: `Bearer ${openRouterKey}` },
  body: JSON.stringify({
    model: openRouterModel,
    messages: [
      { role: "system", content: systemPrompt },
      { role: "user", content: userContent },
    ],
    ...(responseFormat && { response_format: responseFormat }),
  }),
});
```

**Evidence:** `app/lib/llm/callLlm.ts:112-118`, `app/lib/llm/callLlm.ts:131`, `app/lib/llm/callLlm.ts:162`, `app/lib/llm/callLlm.ts:164-178`

---

## Claim 9: "`LEAN_VERIFIER_URL` | ... cannot run on Vercel; host it elsewhere ... and set this to its URL. When unset, Lean code is generated but the type-check step returns the mock-valid response."

**Location:** `README.md:115`
**Type:** Configuration / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High

The observable outcome ("unset → mock-valid response") is correct, but as with Claim 2 the mechanism is one step removed from what the row implies: an unset `LEAN_VERIFIER_URL` does not itself trigger the mock branch — it substitutes the default `http://localhost:3100` (`app/api/verification/lean/route.ts:3-4`), and the mock is returned only when the subsequent `fetch` to that URL fails inside the `catch` block (`app/api/verification/lean/route.ts:33-36`, both quoted under Claim 2). On Vercel this distinction is moot in practice — nothing listens on `localhost:3100` in a serverless function regardless of whether the variable was set or left unset — so the end-user-facing claim holds, but "when unset ... returns the mock-valid response" reads as a direct causal link that the code doesn't implement as a separate branch.

**Evidence:** `app/api/verification/lean/route.ts:3-4`, `app/api/verification/lean/route.ts:33-36`

---

## Claim 10: "**Analytics history** is written to the local filesystem and does not persist across Vercel function invocations; treat the analytics panel as dev-only."

**Location:** `README.md:120`
**Type:** Behavioral / Configuration
**Verdict:** Mostly accurate
**Confidence:** Medium

"Written to the local filesystem" and "dev-only" in practice are verified — the write target is `process.cwd()/data/analytics.jsonl`, not any Vercel-writable path:

```ts
// app/lib/analytics/persist.ts:5-6, 14-17
const DATA_DIR = join(process.cwd(), "data");
const FILE_PATH = join(DATA_DIR, "analytics.jsonl");
...
export function appendAnalyticsEntry(entry: AnalyticsEntry): void {
  ensureDir();
  appendFileSync(FILE_PATH, JSON.stringify(entry) + "\n", "utf-8");
}
```

The phrase "does not persist across ... invocations" is directionally right (a reader correctly concludes they can't rely on this data on Vercel) but implies each invocation's write succeeds and is merely lost on the next one. Since `DATA_DIR` is never `/tmp` and there is no Vercel-specific path override (see Claim 4's evidence), the more precise behavior is that the write is likely to fail on every single invocation (read-only filesystem outside `/tmp`), and that failure is silently swallowed by the calling code's `try { appendAnalyticsEntry(...) } catch { /* persistence failure must not break LLM calls */ }` (`app/lib/llm/callLlm.ts:84-91`) rather than succeeding transiently. The net effect for a user — no durable analytics history on Vercel — matches the claim; the "does not persist across invocations" framing slightly understates that the write may never land at all.

**Evidence:** `app/lib/analytics/persist.ts:5-6`, `app/lib/analytics/persist.ts:14-17`, `app/lib/llm/callLlm.ts:84-91`

---

## Claim 11: Commit message — "docs: tighten Vercel deploy section, accurately describe verifier behavior" (replacing "verifier offline — proof not checked" language with "silent mock `{ valid: true, mock: true }` response").

**Location:** git log, commit `4329d6e` (no in-file line — commit message, not file content)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High

The commit message's characterization of current behavior matches the code at HEAD: `app/api/verification/lean/route.ts` has no "offline" signaling path — every unreachable/failing verifier call falls through to the same silent `{ valid: true, mock: true }` response quoted under Claim 5 (`app/api/verification/lean/route.ts:33-36`), and nothing in the route or `useFormalizationPipeline` distinguishes a "verifier offline" state from a genuine pass (Claim 3 evidence). The commit's stated correction — moving CLAUDE.md/README off an "offline" framing and onto the silent-mock framing — is consistent with what the code at this commit actually does.

**Evidence:** `app/api/verification/lean/route.ts:33-36`; `app/hooks/useFormalizationPipeline.ts:121-124`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 2** (`CLAUDE.md:76`): "unset or unreachable ... falls back to mock" conflates two steps — unset substitutes a default URL first; the mock only fires from the `catch` block when that URL (default or explicit) is unreachable.
- **Claim 4** (`CLAUDE.md:77`): The code never writes to `/tmp` — both cache and analytics target `process.cwd()/data`. On Vercel this path is outside the one writable exception, so writes likely fail on every invocation (silently caught) rather than succeeding in `/tmp` and expiring with the warm container as the phrasing implies.
- **Claim 9** (`README.md:115`): Same mechanism gap as Claim 2 — "when unset" implies a direct branch to the mock response, but unset only leads there via the default-URL-then-unreachable path.
- **Claim 10** (`README.md:120`): "Does not persist across invocations" implies a write that succeeds then expires; more precisely the write targets a non-`/tmp` path and is likely to fail outright on Vercel, with the failure silently caught.

### Unverifiable
(none)
