# Code Fact-Check Report

Commit: 4329d6e

**Repository:** /workspace/external/cc-review-eval/mfc-deploy
**Scope:** `git diff main...review` — `CLAUDE.md`, `README.md` (branch `review`, HEAD `4329d6e`); also `git log main..review` commit messages
**Checked:** 2026-08-15
**Total claims checked:** 12
**Summary:** 6 verified, 4 mostly accurate, 0 stale, 2 incorrect, 0 unverifiable

---

## Claim 1: "There is no in-browser BYO-key flow; keys live in the Vercel project's environment variables (or `.env.local` in dev)."

**Location:** `CLAUDE.md:75`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High

Both API-key-consuming provider calls read the keys exclusively from `process.env`, never from a request body or client-submitted value:

```ts
// app/lib/llm/callLlm.ts:111-112
const anthropicKey = process.env.ANTHROPIC_API_KEY;
const openRouterKey = process.env.OPENROUTER_API_KEY;
```

A repo-wide search for any client component or hook that references an API key found no matches — `grep -rni "api.?key\|byo" app/components` and `grep -rni "apiKey" app --include="*.tsx" --include="*.ts"` (excluding tests) return hits only in `app/lib/llm/callLlm.ts` and `app/lib/llm/streamLlm.ts`, both server-side modules invoked from Next.js API routes (paraphrased — no quote available because this is the absence of a match across the whole `app/components` tree, not a snippet). No form field, input, or state variable anywhere in `app/components/**` collects or forwards a key.

**Evidence:** `app/lib/llm/callLlm.ts:111-112`, `app/lib/llm/streamLlm.ts:119,129,196,209,253`

---

## Claim 2: "When `LEAN_VERIFIER_URL` is unset or unreachable, `app/api/verification/lean/route.ts` falls back to a mock `{ valid: true, mock: true }` response."

**Location:** `CLAUDE.md:76`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High

The end-state outcome is correct for both the unset and unreachable cases, but the two "halves" the claim asks to verify separately are not actually separate code paths — there is a single try/catch around the fetch, and the unset case is folded into the default-then-fail-to-connect path rather than being an explicit branch:

```ts
// app/api/verification/lean/route.ts:3-4
const LEAN_VERIFIER_URL =
  process.env.LEAN_VERIFIER_URL ?? "http://localhost:3100";
...
// app/api/verification/lean/route.ts:16-36
try {
    ...
    const res = await fetch(`${LEAN_VERIFIER_URL}/verify`, { ... });
    ...
} catch {
    // Service unavailable — fall back to mock
    return NextResponse.json({ valid: true, mock: true });
}
```

When unset, `LEAN_VERIFIER_URL` resolves to the `localhost:3100` default; the route then attempts to `fetch` that URL, which throws (nothing is listening) and is caught by the same generic `catch` block that handles the explicitly-unreachable case. So "unset" does not get its own detection/handling — it is indistinguishable at runtime from "set to an address that refuses the connection," both landing in the identical catch-and-mock branch. The claimed outcome (mock response) is correct for both; the claim's phrasing ("unset or unreachable") is directionally accurate but implies two handled cases where the code has one.

**Evidence:** `app/api/verification/lean/route.ts:3-4,16-36`

---

## Claim 3: "This is a known silent-pass behavior — `useFormalizationPipeline` treats it as `valid` and there is currently no 'verifier offline' UI state."

**Location:** `CLAUDE.md:76`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

`useFormalizationPipeline` derives UI verification status purely from `result.valid` / `valid`, with no check of the `mock` field, so a mock response is indistinguishable from a real pass:

```ts
// app/hooks/useFormalizationPipeline.ts:121-124
const vStatus = result.valid ? "valid" as const : "invalid" as const;
a.setVerificationStatus(vStatus);
if (result.valid) a.setVerificationErrors("");
a.onSessionUpdate?.({ verificationStatus: vStatus, verificationErrors: result.valid ? "" : result.errors });
```

```ts
// app/hooks/useFormalizationPipeline.ts:140-145
const { valid, errors } = await verifyLean(fullCode);
const vStatus = valid ? "valid" as const : "invalid" as const;
```

Neither snippet, nor any other reference to `mock` in this file (there are none — `grep -n "mock" app/hooks/useFormalizationPipeline.ts` returns no hits), branches on the `mock` flag, so there is no distinct "verifier offline" UI state as claimed.

**Evidence:** `app/hooks/useFormalizationPipeline.ts:121-124,140-145`

---

## Claim 4: "Persistence on Vercel is best-effort. The LLM cache and analytics log write to the local filesystem in dev. Vercel Functions can only write to `/tmp` and that lasts only as long as the warm container."

**Location:** `CLAUDE.md:77`
**Type:** Configuration / Behavioral
**Verdict:** Incorrect
**Confidence:** Medium

The "in dev" half is verified: both persistence modules resolve their write paths from `process.cwd()`, which is the project root in `npm run dev`:

```ts
// app/lib/llm/cache.ts:6
const CACHE_DIR = join(process.cwd(), "data", "cache");
```

```ts
// app/lib/analytics/persist.ts:5-6
const DATA_DIR = join(process.cwd(), "data");
const FILE_PATH = join(DATA_DIR, "analytics.jsonl");
```

But the claim's Vercel description does not match what this code actually does on Vercel. Neither module ever targets `/tmp` — both hardcode `process.cwd()/data`, which on the general Vercel Node.js runtime resolves to the read-only deployment bundle directory, not the one writable `/tmp` mount (paraphrased — no quote available because Vercel's filesystem model is platform documentation external to this repo, not a line I can cite from the codebase). Given that, a write attempt on Vercel would fail immediately (not merely fail to outlive the container) — and the code confirms every call site swallows that failure silently rather than surfacing it or retrying against `/tmp`:

```ts
// app/lib/llm/callLlm.ts:73-81
async function recordAndCache(...): Promise<CallLlmResult> {
  try {
    appendAnalyticsEntry({ ... });
  } catch { /* persistence failure must not break LLM calls */ }
  ...
  if (text) {
    try { await setCachedResult(cacheHash, result); } catch { /* cache write failure is non-fatal */ }
  }
  ...
}
```

So the claim's mechanism — "writes to `/tmp`, which survives only for the life of the warm container" — describes a scenario the code doesn't implement: the writes never reach `/tmp` at all, and are caught-and-discarded on every Vercel invocation, not just discarded between invocations. The observable end state ("no durable persistence on Vercel") is directionally right, but the described mechanism is not what the code does, which is why this is Incorrect rather than Mostly accurate. Confidence is Medium because the Vercel-filesystem half of this rests on external platform knowledge rather than something verifiable purely by reading this repo.

**Evidence:** `app/lib/llm/cache.ts:6`, `app/lib/analytics/persist.ts:5-6`, `app/lib/llm/callLlm.ts:73-81,94,213-218`, `app/lib/llm/streamLlm.ts:48-63,149-155`

---

## Claim 5: "When the service is not reachable, the verification API route returns a mock `{ valid: true, mock: true }` response so the rest of the app keeps working — note that this means generated Lean code is reported as valid without actually being type-checked."

**Location:** `README.md:64`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

Matches the route's catch branch exactly:

```ts
// app/api/verification/lean/route.ts:34-36
} catch {
    // Service unavailable — fall back to mock
    return NextResponse.json({ valid: true, mock: true });
}
```

And matches how the consumer treats the result — as `valid`, with no distinction drawn between a real pass and a mock pass (see Claim 3's `useFormalizationPipeline.ts:121-124` snippet, not re-quoted here to avoid duplication).

**Evidence:** `app/api/verification/lean/route.ts:34-36`, `app/hooks/useFormalizationPipeline.ts:121-124`

---

## Claim 6: "**Configuration:** The Next.js route reads `LEAN_VERIFIER_URL` from the environment (defaults to `http://localhost:3100`). When the verifier is unreachable, the route falls back to the mock response described above."

**Location:** `README.md:88`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High

The default value is exact:

```ts
// app/api/verification/lean/route.ts:3-4
const LEAN_VERIFIER_URL =
  process.env.LEAN_VERIFIER_URL ?? "http://localhost:3100";
```

This reconciles with Claim 2 (CLAUDE.md's phrasing): this README line is narrower and more precise — it only asserts the "unreachable" case falls back to mock, and does not claim "unset" is separately handled, which matches the single-catch-block mechanism traced in Claim 2. Read together, the README's phrasing is the more accurate of the two.

**Evidence:** `app/api/verification/lean/route.ts:3-4,16-36`

---

## Claim 7: "The rest of the app keeps working without the verifier. Lean code can still be generated and edited; the type-check step returns the mock-valid response described above."

**Location:** `README.md:96`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

Lean code generation is a separate SSE/streaming pipeline (`streamLlm.ts` / `callLlm.ts`) that does not call the verification route at all; verification is invoked as a distinct step (`verifyLean`) from `useFormalizationPipeline.ts:140`, which is only reached after generation completes:

```ts
// app/hooks/useFormalizationPipeline.ts:137-140
const verifyWithDeps = useCallback(async (a: PipelineAccessors, code: string) => {
    const depContext = a.getDependencyContext?.();
    const fullCode = depContext ? `${depContext}\n\n${code}` : code;
    const { valid, errors } = await verifyLean(fullCode);
```

Since generation and verification are separate calls, a verifier failure (caught inside the `/api/verification/lean` route itself, per Claim 5) cannot prevent code generation from completing — it only affects the `valid`/`errors` values assigned afterward.

**Evidence:** `app/hooks/useFormalizationPipeline.ts:137-146`, `app/api/verification/lean/route.ts:16-36`

---

## Claim 8: "`OPENROUTER_API_KEY` | Acts as a fallback LLM provider when `ANTHROPIC_API_KEY` is unset. **Privacy note:** prompts (including your source material) are sent to OpenRouter when this path is used."

**Location:** `README.md:114`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High

The provider-selection logic is a strict `if (anthropicKey) {...} else if (openRouterKey && openRouterModel) {...}` cascade — OpenRouter is only reached when `anthropicKey` is falsy:

```ts
// app/lib/llm/callLlm.ts:130-131,162
if (anthropicKey) {
    ...
}
if (openRouterKey && openRouterModel) {
```

(Note the second is a plain `if`, not `else if`, but the first branch always `return`s via `recordAndCache`, so it is unreachable when `anthropicKey` is set — functionally equivalent to else-if.) The OpenRouter branch sends `systemPrompt` and `userContent` verbatim in the request body:

```ts
// app/lib/llm/callLlm.ts:167-176
body: JSON.stringify({
    model: openRouterModel,
    messages: [
      { role: "system", content: systemPrompt },
      { role: "user", content: userContent },
    ],
    ...
}),
```

confirming the privacy note that prompt content (which includes user source material passed in as `userContent` from the calling routes) leaves the deployment to OpenRouter's API when this fallback path is exercised.

**Evidence:** `app/lib/llm/callLlm.ts:130-131,162-176`

---

## Claim 9: "`LEAN_VERIFIER_URL` | ... The verifier is a separate Docker service ... and cannot run on Vercel; host it elsewhere (Railway, Render, Fly.io, your own infra) and set this to its URL. When unset, Lean code is generated but the type-check step returns the mock-valid response."

**Location:** `README.md:115`
**Type:** Architectural / Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium

The "generated but mock-valid type-check when unset" half is verified by the same mechanism traced in Claims 2 and 6 (default to `localhost:3100`, fetch fails, catch returns mock). The "cannot run on Vercel" half is a claim about the Lean verifier's own runtime requirements (a long-running Docker container with a persistent Lean 4 toolchain), which is not code in this repository's Next.js app — the verifier's `docker-compose.yml` / Dockerfile define a long-lived service, which is architecturally incompatible with Vercel's stateless, short-lived Function model (paraphrased — no quote available because this is a claim about Vercel platform constraints versus the verifier's own service definition, not a single quotable line in either). This half is plausible and consistent with the repo's own `docker-compose.yml` defining a persistent service, but the specific claim "cannot run on Vercel" ultimately rests on external platform knowledge rather than something this repo's code proves on its own — hence Mostly accurate/Medium rather than Verified/High.

**Evidence:** `app/api/verification/lean/route.ts:3-4,16-36`, `docker-compose.yml`

---

## Claim 10: "**Analytics history** is written to the local filesystem and does not persist across Vercel function invocations; treat the analytics panel as dev-only."

**Location:** `README.md:120`
**Type:** Configuration / Behavioral
**Verdict:** Incorrect
**Confidence:** Medium

Same underlying issue as Claim 4. The write target is `process.cwd()/data/analytics.jsonl`, not `/tmp`:

```ts
// app/lib/analytics/persist.ts:5-6,14-16
const DATA_DIR = join(process.cwd(), "data");
const FILE_PATH = join(DATA_DIR, "analytics.jsonl");
...
export function appendAnalyticsEntry(entry: AnalyticsEntry): void {
  ensureDir();
  appendFileSync(FILE_PATH, JSON.stringify(entry) + "\n", "utf-8");
}
```

"Does not persist across invocations" implies the write succeeds within an invocation (or a warm container) and is only lost between separate invocations/deploys — but since the target path is not `/tmp`, on Vercel's general read-only-outside-`/tmp` Function filesystem the write would fail outright on every attempt (caught silently per Claim 4's evidence), never persisting even momentarily. The practical end effect the doc wants readers to take away — "don't rely on the analytics panel on Vercel" — is correct, but the stated mechanism ("written ... does not persist across invocations") describes graceful degradation between calls rather than the write failing immediately every time. Confidence Medium for the same external-platform-knowledge caveat as Claim 4.

**Evidence:** `app/lib/analytics/persist.ts:5-6,14-16`, `app/api/analytics/route.ts:1-10`

---

## Claim 11: Commit message, `1859488` — "the route now signals the verifier is offline rather than silently passing"

**Location:** `git log` commit `1859488` (README/CLAUDE.md portion of its body)
**Type:** Reference / Behavioral
**Verdict:** Incorrect
**Confidence:** High

This commit's own message states "No code changes," so it cannot have altered `app/api/verification/lean/route.ts`'s runtime behavior:

```
// git log main..review, commit 1859488 body
- README: corrected the Lean verifier section — the "falls back to
  { valid: true, mock: true }" claim is no longer accurate (the route
  now signals the verifier is offline rather than silently passing).
...
No code changes.
```

But the route at `HEAD` (and, since neither commit touches it, presumably at every point on this branch) still contains the literal `{ valid: true, mock: true }` silent-pass fallback quoted in Claim 5 — there is no "verifier offline" signal anywhere in `route.ts`. This commit's claim about the route's behavior was false the moment it was written, given its own "no code changes" disclaimer, and it was self-corrected by the immediately following commit (`4329d6e`'s body: "Replace the inaccurate 'verifier offline — proof not checked' claims ... with accurate description of the current behavior ... silent mock"). Since `main...review`'s final diff (what ships) reflects the corrected text, this stale claim never reached the merged docs — it is a historical artifact of the branch, not a live inaccuracy in `CLAUDE.md`/`README.md` at `HEAD`.

**Evidence:** `app/api/verification/lean/route.ts:34-36`, commit `1859488` body, commit `4329d6e` body

---

## Claim 12: Commit message, `4329d6e` — "docs: tighten Vercel deploy section, accurately describe verifier behavior"

**Location:** `git log` commit `4329d6e` (subject line)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High

This is a self-referential claim about the commit's own docs changes describing verifier behavior accurately. Cross-checking the resulting `CLAUDE.md`/`README.md` text against `route.ts` (Claims 2, 5, 6, 7 above) confirms the verifier-behavior description at `HEAD` — mock `{ valid: true, mock: true }` on unreachable, treated as valid downstream, no offline UI state — matches the code. The subject's narrower claim ("accurately describe verifier behavior") holds; it does not extend to the Deployment/Persistence claims (Claims 4 and 10), which the commit message does not characterize as "verifier behavior."

**Evidence:** `app/api/verification/lean/route.ts:34-36`, `app/hooks/useFormalizationPipeline.ts:121-124,140-145`, `README.md:64,88,96`, `CLAUDE.md:76`

---

## Claims Requiring Attention

### Incorrect
- **Claim 4** (`CLAUDE.md:77`): Cache/analytics writes target `process.cwd()/data`, never `/tmp` — on Vercel the write would fail outright (caught silently) rather than succeeding to `/tmp` and being lost only when the warm container recycles.
- **Claim 10** (`README.md:120`): Same root cause as Claim 4 — "does not persist across invocations" implies a working-then-lost write; actual writes go to a path that would fail immediately on Vercel's read-only filesystem, not just fail to survive between calls.
- **Claim 11** (commit `1859488` body): Claims the route "now signals the verifier is offline," but the commit itself says "No code changes," and `route.ts` still does the silent `{ valid: true, mock: true }` fallback at HEAD — self-corrected by the next commit, so it never reached the merged docs.

### Mostly Accurate
- **Claim 2** (`CLAUDE.md:76`): "Unset or unreachable" implies two handled cases; the code has one catch-all branch — unset just resolves to the `localhost:3100` default and then fails to connect the same way an explicitly-unreachable URL would.
- **Claim 9** (`README.md:115`): The mock-on-unset half is verified; the "cannot run on Vercel" half is correct but rests on external Vercel/Docker platform knowledge rather than something checkable purely from this repo's Next.js code.

### Unverifiable
(none)
