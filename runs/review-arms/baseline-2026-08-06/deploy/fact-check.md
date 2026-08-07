Commit: 4329d6e
# Code Fact-Check Report

**Repository:** meta-formalism-copilot (wt-deploy worktree)
**Scope:** branch diff d86d2dc..4329d6e (CLAUDE.md, README.md)
**Checked:** 2026-08-06
**Total claims checked:** 9
**Summary:** 6 verified, 1 mostly accurate, 0 stale, 0 incorrect, 2 unverifiable

Note: `docs/reviews/hallucination-patterns.md` was not present in the worktree; proceeded normally.

---

## Claim 1: "When `LEAN_VERIFIER_URL` is unset or unreachable, `app/api/verification/lean/route.ts` falls back to a mock `{ valid: true, mock: true }` response."

**Location:** `CLAUDE.md:78`
**Type:** Behavioral / Configuration
**Verdict:** Mostly accurate
**Confidence:** High

The mock fallback exists and returns exactly the claimed shape, but it triggers on a fetch failure (the catch block), not directly on the env var being unset. When unset, the URL defaults to localhost:3100 and only reaches the mock if that fetch fails:

```ts
// app/api/verification/lean/route.ts:3-4
const LEAN_VERIFIER_URL =
  process.env.LEAN_VERIFIER_URL ?? "http://localhost:3100";
```

```ts
// app/api/verification/lean/route.ts (catch)
} catch {
  // Service unavailable — fall back to mock
  return NextResponse.json({ valid: true, mock: true });
}
```

So "unset" only produces the mock indirectly (via an unreachable default localhost). In a Vercel deployment the outcome matches the claim; the phrasing conflates "unset" with "unreachable." The mock shape itself is verified verbatim.

**Evidence:** `app/api/verification/lean/route.ts:3-4`, catch block at end of `POST`

---

## Claim 2: "`useFormalizationPipeline` treats it as `valid` and there is currently no 'verifier offline' UI state."

**Location:** `CLAUDE.md:78`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High

The pipeline consumes only `result.valid` / `valid` from the verify call and branches to "valid"/"invalid"; a mock `{valid:true}` therefore reads as valid:

```ts
// app/hooks/useFormalizationPipeline.ts:121-124
const vStatus = result.valid ? "valid" as const : "invalid" as const;
...
a.onSessionUpdate?.({ verificationStatus: vStatus, verificationErrors: result.valid ? "" : result.errors });
```

A grep for `offline` / `mock` across `app/components` and `app/hooks` returned no matches, confirming no "verifier offline" UI state (paraphrased — no quote available because the claim is about absence of code; grep produced zero hits).

**Evidence:** `app/hooks/useFormalizationPipeline.ts:121-124`, `app/hooks/useFormalizationPipeline.ts:140-142`

---

## Claim 3: "The LLM cache and analytics log write to the local filesystem in dev."

**Location:** `CLAUDE.md:79`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

Both write under `process.cwd()/data`:

```ts
// app/lib/analytics/persist.ts:1,5-6,16
import { appendFileSync, readFileSync, writeFileSync, mkdirSync, existsSync } from "fs";
const DATA_DIR = join(process.cwd(), "data");
const FILE_PATH = join(DATA_DIR, "analytics.jsonl");
appendFileSync(FILE_PATH, JSON.stringify(entry) + "\n", "utf-8");
```

The cache writes to `process.cwd()/data/cache` via `fs/promises` (paraphrased — no quote available because the redaction filter mangled the grep display of `app/lib/llm/cache.ts`; the import is `from "fs/promises"` and `CACHE_DIR = join(process.cwd(), "data", "cache")`).

**Evidence:** `app/lib/analytics/persist.ts:1-16`, `app/lib/llm/cache.ts:1-`

---

## Claim 4: "The Next.js route reads `LEAN_VERIFIER_URL` from the environment (defaults to `http://localhost:3100`)."

**Location:** `README.md:88`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High

```ts
// app/api/verification/lean/route.ts:3-4
const LEAN_VERIFIER_URL =
  process.env.LEAN_VERIFIER_URL ?? "http://localhost:3100";
```

**Evidence:** `app/api/verification/lean/route.ts:3-4`

---

## Claim 5: "`OPENROUTER_API_KEY` acts as a fallback LLM provider when `ANTHROPIC_API_KEY` is unset."

**Location:** `README.md:112` (Optional env vars table)
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High

`callLlm` selects Anthropic when its key is present, otherwise OpenRouter (when an OpenRouter model is also configured), otherwise mock:

```ts
// app/lib/llm/callLlm.ts:99,112-118
/** Centralized LLM call with Anthropic -> OpenRouter -> mock fallback.
const anthropicKey = process.env.ANTHROPIC_API_KEY;
const openRouterKey = process.env.OPENROUTER_API_KEY;
const effectiveModel = anthropicKey
  ? ...
  : (openRouterKey && openRouterModel)
    ? ...
    : "mock";
```

Minor nuance: the OpenRouter path also requires an `openRouterModel`; with the key set but no model it still falls to mock. The core claim (fallback when Anthropic unset) holds.

**Evidence:** `app/lib/llm/callLlm.ts:99-118`, `app/lib/llm/callLlm.ts:162-206`

---

## Claim 6: Deploy button `repository-url` = `github.com/aditya-adiga/meta-formalism-copilot`; `envLink` anchor `#deploy-to-vercel`.

**Location:** `README.md:5`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium

The `envLink` fragment `#deploy-to-vercel` resolves to the `## Deploy to Vercel` heading added in the same diff (GitHub slugifies to `deploy-to-vercel`):

```md
// README.md:98
## Deploy to Vercel
```

The single required env var in the button URL (`env=ANTHROPIC_API_KEY`) matches the required-var table and `callLlm`'s `process.env.ANTHROPIC_API_KEY`. The GitHub owner/repo path (`aditya-adiga/meta-formalism-copilot`) is plausible — the local git remote is `.../meta-formalism-copilot/` — but the actual GitHub owner cannot be confirmed from this worktree (remote is a local filesystem path). Anchor and env var: verified; external owner: not confirmable here.

**Evidence:** `README.md:5`, `README.md:98`, `app/lib/llm/callLlm.ts:112`

---

## Claim 7: "There is no in-browser BYO-key flow; keys live in the Vercel project's environment variables (or `.env.local` in dev)."

**Location:** `CLAUDE.md:77`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High

Both API keys are read only from `process.env` on the server (`app/lib/llm/callLlm.ts:112-113`); no component/hook accepts or forwards a user-supplied key (paraphrased — no quote available because the claim is about absence of a BYO-key UI; no such input surfaced in `app/components`/`app/hooks`). The mock-fallback warning also points users to `.env.local`.

**Evidence:** `app/lib/llm/callLlm.ts:112-113`, `app/lib/llm/callLlm.ts:203`

---

## Claim 8: "Vercel Functions can only write to `/tmp` and that lasts only as long as the warm container."

**Location:** `CLAUDE.md:79`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium

This describes Vercel platform runtime behavior, not this codebase (paraphrased — no quote available because the claim concerns an external hosting platform's filesystem semantics, outside static analysis of this repo). It matches widely-documented Vercel behavior but cannot be confirmed from the code.

**Evidence:** external platform behavior — no in-repo locator

---

## Claim 9: "the verification API route returns a mock `{ valid: true, mock: true }` response ... this means generated Lean code is reported as valid without actually being type-checked."

**Location:** `README.md:64`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The route's catch branch returns `{ valid: true, mock: true }` with no type-checking performed, and the pipeline reports `valid` from it (see Claims 1 and 2):

```ts
// app/api/verification/lean/route.ts (catch)
return NextResponse.json({ valid: true, mock: true });
```

**Evidence:** `app/api/verification/lean/route.ts` (catch block), `app/hooks/useFormalizationPipeline.ts:121-124`

---

## Claims Requiring Attention

### Incorrect
- (none)

### Stale
- (none)

### Mostly Accurate
- **Claim 1** (`CLAUDE.md:78`): "unset or unreachable → mock" conflates the two; an unset var defaults to `http://localhost:3100` and only reaches the mock via a failed fetch, not directly. Outcome matches in prod; tighten wording to "unreachable (including the unset default)."

### Unverifiable
- **Claim 8** (`CLAUDE.md:79`): Vercel `/tmp`-only filesystem behavior — external platform semantics; would need Vercel runtime docs/testing to confirm.
- **Claim 6** (`README.md:5`, partial): GitHub owner `aditya-adiga` — local git remote is a filesystem path, so the external repo owner cannot be confirmed from this worktree.
