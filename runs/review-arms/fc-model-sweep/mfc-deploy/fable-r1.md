# Code Fact-Check Report
Commit: 4329d6e

**Repository:** /workspace/external/cc-review-eval/mfc-deploy
**Scope:** branch diff `main...review` (`CLAUDE.md`, `README.md`) plus commit messages `main..review`
**Checked:** 2026-08-15
**Total claims checked:** 14
**Summary:** 9 verified, 3 mostly accurate, 0 stale, 1 incorrect, 1 unverifiable

---

## Claim 1: "There is no in-browser BYO-key flow; keys live in the Vercel project's environment variables (or `.env.local` in dev)."

**Location:** `CLAUDE.md:75`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** Medium

API keys are read exclusively from server-side environment variables in the LLM client:

```ts
// app/lib/llm/callLlm.ts:112-113
const anthropicKey = process.env.ANTHROPIC_API_KEY;
const openRouterKey = process.env.OPENROUTER_API_KEY;
```

The same pattern appears in the streaming client (`app/lib/llm/streamLlm.ts:87-88`, quoted in Claim 8's context). No client-side key-entry path exists: greps for `apiKey`, key-input UI, or key storage in `app/components/` and `app/hooks/` return no hits (paraphrased — no quote available because the claim covers absence of code; no matching grep results in `app/components/` or `app/hooks/` outside tests). Confidence is Medium rather than High only because absence claims rest on grep coverage rather than a single readable code path.

**Evidence:** `app/lib/llm/callLlm.ts:112-113`, `app/lib/llm/streamLlm.ts:87-88`

---

## Claim 2: "When `LEAN_VERIFIER_URL` is unset or unreachable, `app/api/verification/lean/route.ts` falls back to a mock `{ valid: true, mock: true }` response."

**Location:** `CLAUDE.md:76`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High

The *unreachable* half is exactly right. The route wraps the fetch in try/catch and returns the mock on any network failure or timeout:

```ts
// app/api/verification/lean/route.ts:37-40
} catch {
  // Service unavailable — fall back to mock
  return NextResponse.json({ valid: true, mock: true });
}
```

The *unset* half is imprecise in two ways. First, unset does not itself trigger the mock — it substitutes a default URL:

```ts
// app/api/verification/lean/route.ts:3-4
const LEAN_VERIFIER_URL =
  process.env.LEAN_VERIFIER_URL ?? "http://localhost:3100";
```

So with the variable unset but a verifier running on `localhost:3100` (the normal dev setup), the route reaches the real verifier, not the mock. "Unset" only produces the mock when `localhost:3100` is also unreachable (as it is inside a Vercel Function). Second, a *reachable* verifier that returns a non-OK status is forwarded, not mocked:

```ts
// app/api/verification/lean/route.ts:32-34
if (!res.ok) {
  return NextResponse.json(data, { status: res.status });
}
```

The precise version: "When the verifier at `LEAN_VERIFIER_URL` (default `http://localhost:3100`) cannot be reached, the route falls back to `{ valid: true, mock: true }`; unset therefore implies the mock only in environments where localhost:3100 is unreachable."

**Evidence:** `app/api/verification/lean/route.ts:3-4`, `app/api/verification/lean/route.ts:17-40`

---

## Claim 3: "This is a known silent-pass behavior — `useFormalizationPipeline` treats it as `valid` and there is currently no 'verifier offline' UI state."

**Location:** `CLAUDE.md:76`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High

The client wrapper coerces the mock response's `valid: true` and discards the `mock` flag:

```ts
// app/lib/formalization/api.ts:109-110
const data = await res.json();
return { valid: Boolean(data.valid), errors: (data.errors as string | undefined) ?? "" };
```

The pipeline hook then maps it straight to the `"valid"` status:

```ts
// app/hooks/useFormalizationPipeline.ts:140-142
const { valid, errors } = await verifyLean(fullCode);
const vStatus = valid ? "valid" as const : "invalid" as const;
const vErrors = valid ? "" : errors || "Verification failed";
```

The same mapping occurs at `app/hooks/useFormalizationPipeline.ts:121-124`. No "offline" or mock-aware UI state exists: a case-insensitive grep for `offline` and `mock` across `app/components/` and `app/hooks/` (excluding tests) returns zero hits (paraphrased — no quote available because the claim covers absence of code; no matching grep results).

**Evidence:** `app/lib/formalization/api.ts:103-111`, `app/hooks/useFormalizationPipeline.ts:121-124`, `app/hooks/useFormalizationPipeline.ts:140-142`

---

## Claim 4: "The LLM cache and analytics log write to the local filesystem in dev. Vercel Functions can only write to `/tmp` and that lasts only as long as the warm container"

**Location:** `CLAUDE.md:77`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium

The dev half is verified. The cache writes JSON files under `<cwd>/data/cache`:

```ts
// app/lib/llm/cache.ts:6
const CACHE_DIR = join(process.cwd(), "data", "cache");
```

and the analytics log appends JSONL under `<cwd>/data`:

```ts
// app/lib/analytics/persist.ts:5-6
const DATA_DIR = join(process.cwd(), "data");
const FILE_PATH = join(DATA_DIR, "analytics.jsonl");
```

The Vercel half is a true platform statement but misdescribes what happens to *these* writes. Neither writer targets `/tmp` — both target `process.cwd()/data`, which in a Vercel Function is the read-only deployment bundle, so the writes would throw rather than land in warm-container `/tmp` storage (paraphrased — no quote available because the read-only nature of Vercel's deployment directory is platform behavior, not code in this repo). The failures are deliberately swallowed:

```ts
// app/lib/llm/callLlm.ts:94
try { await setCachedResult(cacheHash, result); } catch { /* cache write failure is non-fatal */ }
```

and analytics likewise (`app/lib/llm/callLlm.ts:84-91`, `try { appendAnalyticsEntry({...}) } catch { /* persistence failure must not break LLM calls */ }`). So on Vercel the realistic behavior is "writes silently fail entirely," not "writes survive only as long as the warm container." The bullet's practical conclusion (don't assume durable filesystem state) still holds. Confidence is Medium because Vercel runtime behavior cannot be confirmed by static analysis of this repo.

**Evidence:** `app/lib/llm/cache.ts:6`, `app/lib/llm/cache.ts:61-68`, `app/lib/analytics/persist.ts:5-17`, `app/lib/llm/callLlm.ts:84-95`

---

## Claim 5: "When the service is not reachable, the verification API route returns a mock `{ valid: true, mock: true }` response so the rest of the app keeps working — note that this means generated Lean code is reported as valid without actually being type-checked."

**Location:** `README.md:64`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The unreachable path returns exactly that shape:

```ts
// app/api/verification/lean/route.ts:37-40
} catch {
  // Service unavailable — fall back to mock
  return NextResponse.json({ valid: true, mock: true });
}
```

and the consumer reports it as valid (see Claim 3's quotes from `app/lib/formalization/api.ts:109-110` and `app/hooks/useFormalizationPipeline.ts:140-142`) — no type-checking occurs on this path, since the only call to the real verifier is the failed fetch at `app/api/verification/lean/route.ts:21-26`. This README revision correctly scopes the trigger to "not reachable," avoiding the unset-case imprecision noted in Claim 2.

**Evidence:** `app/api/verification/lean/route.ts:17-40`, `app/lib/formalization/api.ts:103-111`, `app/hooks/useFormalizationPipeline.ts:140-142`

---

## Claim 6: "The Next.js route reads `LEAN_VERIFIER_URL` from the environment (defaults to `http://localhost:3100`). When the verifier is unreachable, the route falls back to the mock response described above."

**Location:** `README.md:88`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High

Both the default and the fallback match the implementation:

```ts
// app/api/verification/lean/route.ts:3-4
const LEAN_VERIFIER_URL =
  process.env.LEAN_VERIFIER_URL ?? "http://localhost:3100";
```

The default also matches the Docker service, which binds port 3100 (`docker-compose.yml:7`, `"3100:3100"`). The unreachable fallback is the catch branch quoted in Claim 5 (`app/api/verification/lean/route.ts:37-40`). This line reconciles cleanly with Claim 2: the unset case resolves to this default, and the mock fires only on unreachability.

**Evidence:** `app/api/verification/lean/route.ts:3-4`, `app/api/verification/lean/route.ts:37-40`, `docker-compose.yml:7-9`

---

## Claim 7: "The rest of the app keeps working without the verifier. Lean code can still be generated and edited; the type-check step returns the mock-valid response described above."

**Location:** `README.md:96`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

Lean generation is a separate LLM route (`app/api/formalization/lean/route.ts:104`, which passes `openRouterModel: OPENROUTER_MODEL` to the LLM client and has no dependency on the verifier — paraphrased for the no-dependency part: no quote available because the claim covers absence of any verifier call in that route; grep for `verification` there returns nothing). The type-check step returns the mock via the catch branch quoted in Claim 5:

```ts
// app/api/verification/lean/route.ts:39
return NextResponse.json({ valid: true, mock: true });
```

**Evidence:** `app/api/verification/lean/route.ts:37-40`, `app/api/formalization/lean/route.ts:104`

---

## Claim 8: "`OPENROUTER_API_KEY` … Acts as a fallback LLM provider when `ANTHROPIC_API_KEY` is unset. **Privacy note:** prompts (including your source material) are sent to OpenRouter when this path is used."

**Location:** `README.md:114`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High

The provider selection is Anthropic-first, OpenRouter-second, mock-last:

```ts
// app/lib/llm/callLlm.ts:114-118
const effectiveModel = anthropicKey
  ? (anthropicModel ?? DEFAULT_ANTHROPIC_MODEL)
  : (openRouterKey && openRouterModel)
    ? openRouterModel
    : "mock";
```

with the actual call gated the same way (`app/lib/llm/callLlm.ts:131` `if (anthropicKey) {…}` then `app/lib/llm/callLlm.ts:162` `if (openRouterKey && openRouterModel) {…}`), mirrored in the streaming client (`app/lib/llm/streamLlm.ts:89-93`, `117-127`). The OpenRouter branch requires the calling route to supply an OpenRouter model, and the API routes do so via imported constants, e.g.:

```ts
// app/api/edit/inline/route.ts:3
import { DEEPSEEK_CHAT as OPENROUTER_MODEL } from "@/app/lib/llm/models";
```

The privacy note is accurate — the full system prompt and user content (which carries source material) are POSTed to openrouter.ai:

```ts
// app/lib/llm/callLlm.ts:164-175
const response = await fetch(OPENROUTER_API_URL, {
  method: "POST",
  ...
  body: JSON.stringify({
    model: openRouterModel,
    messages: [
      { role: "system", content: systemPrompt },
      { role: "user", content: userContent },
    ],
```

where `OPENROUTER_API_URL = "https://openrouter.ai/api/v1/chat/completions"` (`app/lib/llm/callLlm.ts:7`).

**Evidence:** `app/lib/llm/callLlm.ts:7`, `app/lib/llm/callLlm.ts:112-118`, `app/lib/llm/callLlm.ts:162-199`, `app/lib/llm/streamLlm.ts:87-93`, `app/api/edit/inline/route.ts:3`

---

## Claim 9: "`LEAN_VERIFIER_URL` — Points the Lean type-check API at a running verifier. … cannot run on Vercel; host it elsewhere … When unset, Lean code is generated but the type-check step returns the mock-valid response."

**Location:** `README.md:115`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** Medium

The variable does point the route at the verifier (`app/api/verification/lean/route.ts:3-4` and the fetch at `:21`, `` await fetch(`${LEAN_VERIFIER_URL}/verify`, … ``). The "when unset → mock" outcome holds *in this table's Vercel context*: unset resolves to `http://localhost:3100` (quoted in Claim 6), which is unreachable from inside a Vercel Function, so the fetch throws and the catch returns the mock (`app/api/verification/lean/route.ts:37-40`, quoted in Claim 5). The mechanism is indirection through an unreachable default rather than an explicit unset check — see Claim 2 for the dev-environment caveat, which does not apply to this Vercel-scoped table. "Cannot run on Vercel" is a platform claim about running Docker services in serverless functions (paraphrased — no quote available because it concerns Vercel platform capabilities, not code in this repo); the verifier is indeed a separate Docker service (`docker-compose.yml:7-11` maps port 3100 and health-checks `http://localhost:3100/health`). Medium confidence because the Vercel-side unreachability is inferred platform behavior.

**Evidence:** `app/api/verification/lean/route.ts:3-4`, `app/api/verification/lean/route.ts:21-40`, `docker-compose.yml:7-11`

---

## Claim 10: "**Lean verification** runs only when `LEAN_VERIFIER_URL` points at a separately hosted verifier (see above)."

**Location:** `README.md:119`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium

Same evidence chain as Claim 9: on Vercel, without the variable the route targets the unreachable `http://localhost:3100` default (`app/api/verification/lean/route.ts:3-4`, quoted in Claim 6) and returns the mock instead of verifying (`app/api/verification/lean/route.ts:37-40`, quoted in Claim 5), so real type-checking on Vercel requires the variable to point at a reachable hosted verifier (paraphrased — no quote available because the Vercel-side unreachability of localhost is platform behavior, not code).

**Evidence:** `app/api/verification/lean/route.ts:3-4`, `app/api/verification/lean/route.ts:17-40`

---

## Claim 11: "**Analytics history** is written to the local filesystem and does not persist across Vercel function invocations; treat the analytics panel as dev-only."

**Location:** `README.md:120`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium

Analytics is indeed written to the local filesystem:

```ts
// app/lib/analytics/persist.ts:14-17
export function appendAnalyticsEntry(entry: AnalyticsEntry): void {
  ensureDir();
  appendFileSync(FILE_PATH, JSON.stringify(entry) + "\n", "utf-8");
}
```

at `<cwd>/data/analytics.jsonl` (`app/lib/analytics/persist.ts:5-6`, quoted in Claim 4). "Does not persist across invocations" is directionally right but understates: because the path is under `process.cwd()` (the read-only deployment bundle), not `/tmp`, the write on Vercel would fail outright and be swallowed by the caller's try/catch (`app/lib/llm/callLlm.ts:84-91`, quoted in Claim 4) — the entry is most likely never written at all, even within one warm container (paraphrased — no quote available because the read-only deployment directory is Vercel platform behavior, not code in this repo). The practical advice ("treat the analytics panel as dev-only") is sound; the precise version would say the write silently fails on Vercel. The panel's GET reads the same file (`app/api/analytics/route.ts:4-7`, `readAnalyticsEntries()` over `FILE_PATH`), so on Vercel it would return an empty list (`app/lib/analytics/persist.ts:20`, `if (!existsSync(FILE_PATH)) return [];`).

**Evidence:** `app/lib/analytics/persist.ts:5-17`, `app/lib/analytics/persist.ts:19-21`, `app/api/analytics/route.ts:1-12`, `app/lib/llm/callLlm.ts:84-91`

---

## Claim 12: "corrected the Lean verifier section — the 'falls back to { valid: true, mock: true }' claim is no longer accurate (the route now signals the verifier is offline rather than silently passing)."

**Location:** commit `1859488` (message body)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High

The route does not signal that the verifier is offline; it silently returns the mock-valid response:

```ts
// app/api/verification/lean/route.ts:37-40
} catch {
  // Service unavailable — fall back to mock
  return NextResponse.json({ valid: true, mock: true });
}
```

While a `mock: true` flag is present in the JSON, no consumer reads it — the client wrapper keeps only `valid` and `errors` (`app/lib/formalization/api.ts:110`, quoted in Claim 3), and no offline UI state exists (Claim 3). The branch's own follow-up commit `4329d6e` concedes this: "Replace the inaccurate 'verifier offline — proof not checked' claims … with accurate description of the current behavior on this branch (silent mock…). The graceful-degradation behavior lives on a sibling branch" (quoted from `git log main..review`, commit `4329d6e` message body). The claim was wrong about this branch's code when written, not made wrong by later change, so the verdict is Incorrect rather than Stale.

**Evidence:** `app/api/verification/lean/route.ts:17-40`, `app/lib/formalization/api.ts:103-111`, commit messages `1859488` and `4329d6e` (`git log main..review`)

---

## Claim 13: "docs: tighten Vercel deploy section, accurately describe verifier behavior … Remove OPENALEX_MAILTO from the optional env var table; OpenAlex / evidence-search is not on this branch's main yet. … No code change."

**Location:** commit `4329d6e` (message body)
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High

Three sub-claims, all confirmed. (1) The verifier description this commit installs (silent mock `{ valid: true, mock: true }`) matches the route — see the catch branch quoted in Claims 2 and 5 (`app/api/verification/lean/route.ts:37-40`). (2) OpenAlex is genuinely absent: a case-insensitive grep for `openalex` across `app/`, `scripts/`, and `package.json` returns zero matches (paraphrased — no quote available because the claim covers absence of code; no matching grep results). (3) "No code change" is confirmed by the branch diff touching only documentation: `git diff main...review --stat` lists `CLAUDE.md | 10 ++++++++++` and `README.md | 34 +++++++++++++++++++++++++++++++---` and nothing else (quoted from git output; no in-file line to cite for a diff-stat).

**Evidence:** `app/api/verification/lean/route.ts:37-40`, `git diff main...review --stat`, grep of `app/`, `scripts/`, `package.json`

---

## Claim 14: "Lint clean; 221/221 tests pass."

**Location:** commit `4329d6e` (message body)
**Type:** Reference / Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium

The claim requires actually running `npm run lint` and `vitest run`, and the checkout's `node_modules` is empty (8.0K, no installed packages or `.bin/` directory — paraphrased: no quote available because the claim is about directory contents, not a snippet), so neither command can execute here without a fresh dependency install. An attempted `npx vitest run` failed with `MODULE_NOT_FOUND` resolving `vitest.config.ts` dependencies. The test suite does exist (`vitest.config.ts`, `vitest.setup.ts`, and `*.test.ts` files such as `app/lib/llm/costs.test.ts`, `app/hooks/useDecomposition.test.ts`), and since the commit changes only Markdown files (Claim 13), it is plausible the suite's status is unchanged from main — but the specific 221/221 count and lint-clean status cannot be confirmed statically. Verifying would require `npm ci && npm run lint && npm test` in this checkout.

**Evidence:** `package.json:10` (`"test": "vitest run"`), `vitest.config.ts`, `app/lib/llm/costs.test.ts`

---

## Claims Requiring Attention

### Incorrect
- **Claim 12** (commit `1859488`): The message claims the route "signals the verifier is offline rather than silently passing"; the route silently returns `{ valid: true, mock: true }` and no consumer reads the `mock` flag. Already corrected in the docs by `4329d6e`, but the message remains misleading in history.

### Stale
- (none)

### Mostly Accurate
- **Claim 2** (`CLAUDE.md:76`): "Unset" alone does not trigger the mock — unset substitutes the default `http://localhost:3100`, and the mock fires only when that (or the configured URL) is unreachable; non-OK responses from a reachable verifier are forwarded, not mocked. Tighten to "when the verifier cannot be reached."
- **Claim 4** (`CLAUDE.md:77`): Cache and analytics write to `process.cwd()/data`, not `/tmp` — on Vercel these writes fail silently (swallowed by try/catch) rather than surviving in warm-container `/tmp`. Tighten the mechanism or drop the `/tmp` framing.
- **Claim 11** (`README.md:120`): On Vercel the analytics write most likely fails outright (read-only cwd, swallowed error) rather than persisting-then-vanishing; "does not persist" understates. The dev-only advice stands.

### Unverifiable
- **Claim 14** (commit `4329d6e`): "Lint clean; 221/221 tests pass" needs `npm ci && npm run lint && npm test` — dependencies are not installed in this checkout.
