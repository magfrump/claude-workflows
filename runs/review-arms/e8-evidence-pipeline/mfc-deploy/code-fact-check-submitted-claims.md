# Code Fact-Check Report

**Commit:** 4329d6e

**Repository:** /workspace/external/cc-review-eval/mfc-deploy
**Scope:** Stage 2.5 endorsement-claim verification — 4 claims routed by critics (3 from security-review.md `route: code-fact-check`, 1 from performance-review.md `[unverified — submitted as claim]`; api-consistency-review.md routed none). Verified against `README.md`, `CLAUDE.md`, `app/lib/llm/callLlm.ts`, `app/lib/llm/streamLlm.ts`, `app/api/verification/lean/route.ts`, plus the merged Stage-1 report's executed evidence and one new executed probe.
**Checked:** 2026-08-18
**Total claims checked:** 4
**Summary:** 4 verified, 0 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Numbering continues from the merged report (`code-fact-check-report.md`, Claims 1–18b).

---

## Submitted Claims

## Claim 19: "The diff discloses that when the verifier is unreachable, generated Lean code is reported as valid without being type-checked (the silent-pass fail-open is documented, not hidden)."

**Submitted by:** security-reviewer
**Location:** `README.md:64`, `CLAUDE.md:76`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the presence and accuracy of the disclosure text in the two cited doc locations and the unreachable-verifier mock behavior it describes (execution-confirmed); does not establish whether every UI panel that displays verification status surfaces or obscures the mocked pass — Stage-1 Claim 5 scopes the UI check to `verifyLean` and `useFormalizationPipeline`, not every display component.

Both halves check out. The disclosure text exists exactly where cited:

```md
// README.md:64
When the service is not reachable, the verification API route returns a mock `{ valid: true, mock: true }` response so the rest of the app keeps working — note that this means generated Lean code is reported as valid without actually being type-checked.
```

```md
// CLAUDE.md:76
When `LEAN_VERIFIER_URL` is unset or unreachable, `app/api/verification/lean/route.ts` falls back to a mock `{ valid: true, mock: true }` response. This is a known silent-pass behavior — `useFormalizationPipeline` treats it as `valid` and there is currently no "verifier offline" UI state.
```

The disclosed behavior is accurate for the *unreachable* case, execution-confirmed by the Stage-1 merged report (Claims 4b and 9b, both Verified/executed): with `LEAN_VERIFIER_URL=http://127.0.0.1:3101` and nothing listening, the route returned `{"valid":true,"mock":true}` (evidence `r2-e3-set-unreachable.txt`, curl against the dev server, exit 0, 2026-08-18T06:16:02Z), and likewise with the var unset and no verifier running (`r2-e1-unset-noverifier.txt`, `r1-vitest-lean-route.txt`). The mechanism is the fetch-failure catch:

```ts
// app/api/verification/lean/route.ts:37-40
  } catch {
    // Verifier not reachable — return mock response so the rest of the app works
    return NextResponse.json({ valid: true, mock: true });
  }
```

Note the CLAUDE.md:76 sentence's *unset* half was separately verdicted Incorrect in Stage 1 (Claim 4a: unset substitutes `http://localhost:3100` and can reach a real verifier). The submitted claim as worded — disclosure of the *unreachable* silent-pass — does not rest on that refuted half; the security-reviewer's own endorsement text already carves it out and flags the 4a refutation elsewhere in its report.

**Evidence:** `README.md:64`, `CLAUDE.md:76`, `app/api/verification/lean/route.ts:37-40`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-deploy/evidence/r2-e3-set-unreachable.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-deploy/evidence/r2-e1-unset-noverifier.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-deploy/evidence/r1-vitest-lean-route.txt`

---

## Claim 20: "The diff discloses that the OpenRouter fallback path transmits prompts including the user's source material to OpenRouter."

**Submitted by:** security-reviewer
**Location:** `README.md:114`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the presence of the privacy disclosure at the cited line and the code-level accuracy of what it discloses (provider selection and outbound request body, execution-confirmed for one representative route); does not establish OpenRouter's server-side handling of the transmitted data, which is outside this repository.

The disclosure exists at the cited line:

```md
// README.md:114
| `OPENROUTER_API_KEY` | Acts as a fallback LLM provider when `ANTHROPIC_API_KEY` is unset. **Privacy note:** prompts (including your source material) are sent to OpenRouter when this path is used. |
```

The disclosed behavior matches the code: when the Anthropic key is absent and an OpenRouter key is present, `callLlm` POSTs the full system prompt and user content to OpenRouter:

```ts
// app/lib/llm/callLlm.ts:170-175
      body: JSON.stringify({
        model: openRouterModel,
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: userContent },
        ],
```

That this path (not the mock) is selected under exactly the documented key configuration is execution-confirmed by Stage-1 Claim 15 (Verified/executed in both replicates): with `ANTHROPIC_API_KEY` unset and a fake `OPENROUTER_API_KEY` set, a live route call produced a real outbound OpenRouter request that failed 401 at OpenRouter's server — proof the request left the app on this path (evidence `r2-e7-openrouter-fallback-path.txt`, curl against the dev server, timestamp 2026-08-18T06:17:20Z; `r1-vitest-callllm-fallback.txt`). That user source material flows into `userContent` for formalization routes is established in Stage-1 Claim 15's trace of `artifactRoute.ts:76` (paraphrased — no quote available because the source-to-prompt flow spans `artifactRoute.ts` assembling the prompt from the request's source text and is quoted in full in the merged report's Claim 15).

**Evidence:** `README.md:114`, `app/lib/llm/callLlm.ts:162-177`, `app/lib/formalization/artifactRoute.ts:76`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-deploy/evidence/r2-e7-openrouter-fallback-path.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-deploy/evidence/r1-vitest-callllm-fallback.txt`

---

## Claim 21: "In this codebase, API keys are read from server-side environment variables and there is no in-browser key-entry path."

**Submitted by:** security-reviewer
**Location:** `CLAUDE.md:75`, `app/lib/llm/callLlm.ts:112-113`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers where keys are read in this codebase (server-side `process.env` in `callLlm.ts`/`streamLlm.ts`) and the absence of any key reference in client components/hooks; does not establish how a particular deployment's env is configured, nor that no route's error body could echo key-adjacent data (the OpenRouter error path forwards provider error details, not the key).

The key reads are server-side env lookups:

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

The absence half: a case-insensitive search for `apiKey`/`API_KEY` across `app/components/` and `app/hooks/` returns no non-test matches (paraphrased — no quote available because the claim is about the absence of matches; command: `grep -rn -i "apiKey\|API_KEY" app/components/ app/hooks/ | grep -v test` produced empty output, agreeing with Stage-1 Claim 2, Verified). The only client construction sites for the Anthropic SDK are the two server-side call sites through `getAnthropicClient` (see Claim 22). Absence-of-code-path claims are structural, so static mode is the appropriate ceiling here; no executable guarantee is asserted.

**Evidence:** `CLAUDE.md:75`, `app/lib/llm/callLlm.ts:112-113`, `app/lib/llm/streamLlm.ts:87-88`, `app/lib/llm/callLlm.ts:203`

---

## Claim 22: "The Anthropic SDK client is constructed at most once per warm server instance and reused across `callLlm`/`streamLlm` invocations in that instance, avoiding per-request client/TLS setup."

**Submitted by:** performance-reviewer
**Location:** `app/lib/llm/callLlm.ts:10-17`
**Type:** Performance / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers construction-count behavior within one warm Node module instance (executed: 3 `callLlm` + 2 `streamLlm` invocations yielded exactly one construction) and the absence of any other construction site in `app/`; does not establish behavior across separate serverless instances or separately-bundled module copies, nor that a key rotated at runtime would get a fresh client (the singleton ignores the `apiKey` argument after first construction).

The mechanism is a lazy module-level singleton:

```ts
// app/lib/llm/callLlm.ts:10-17
// Lazy-initialized Anthropic client — reused across calls
let _anthropicClient: Anthropic | null = null;
export function getAnthropicClient(apiKey: string): Anthropic {
  if (!_anthropicClient) {
    _anthropicClient = new Anthropic({ apiKey });
  }
  return _anthropicClient;
}
```

Both invocation paths route through it, and a repo-wide search finds no other construction site (paraphrased — no quote available because the assertion is about the absence of other matches; `grep -rn "new Anthropic\|getAnthropicClient" app/` returns only `callLlm.ts:12,14,134` and `streamLlm.ts:8,209`):

```ts
// app/lib/llm/callLlm.ts:134
    const client = getAnthropicClient(anthropicKey);
```

```ts
// app/lib/llm/streamLlm.ts:209
  const client = getAnthropicClient(opts.apiKey);
```

Executed (mandatory-execution rule — the claim is a runtime guarantee): a temporary vitest probe mocked `@anthropic-ai/sdk` with a counting constructor (cache and analytics mocked off the filesystem), ran 3 `callLlm` calls with distinct prompts plus 2 fully-drained `streamLlm` streams under a set `ANTHROPIC_API_KEY`, and asserted the count. Result: construction count 0 at import (lazy), 1 after the `callLlm` calls, still 1 after the `streamLlm` calls, and repeated `getAnthropicClient` returns the identical object.

- Command: `npx vitest run app/lib/llm/sc-client-reuse.probe.test.ts --disable-console-intercept`
- Cwd: `/workspace/external/cc-review-eval/mfc-deploy`
- Timestamp: 2026-08-18T06:34:59Z (UTC)
- Result: `Test Files 1 passed (1) / Tests 1 passed (1)`; logged counts `1 / 1 / 1`
- Exit code: 1 — nonzero despite the pass, caused by a pre-existing 0-byte `/workspace/external/package.json` outside the target repo triggering `ERR_INVALID_PACKAGE_CONFIG` during vitest's optional-dependency probing at startup (stack trace captured at the top of the output file); the test run and assertions are unaffected.
- The probe file was removed after the run (`git status` clean); its full source is preserved in the evidence directory.

**Evidence:** `app/lib/llm/callLlm.ts:10-17`, `app/lib/llm/callLlm.ts:134`, `app/lib/llm/streamLlm.ts:209`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-deploy/evidence/sc-client-reuse-probe.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-deploy/evidence/sc-client-reuse-probe-source.test.ts.txt`

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- None.

### Mostly Accurate
- None.

### Unverifiable
- None.
