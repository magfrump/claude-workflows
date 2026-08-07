Commit: 6cf4b0d

# Code Fact-Check Report

**Repository:** /workspace/runs/review-arms/baseline-2026-08-06/wt-candB (meta-formalism-copilot)
**Scope:** Introducing diff `6cf4b0d^..6cf4b0d`, evidence-integration feature (`app/api/evidence-integrate/`, `app/lib/utils/applyProposals.ts`)
**Checked:** 2026-08-07
**Total claims checked:** 9
**Summary:** 8 verified, 0 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable
<!-- corrected 2026-08-07 per review fact-check: header previously said 7/…/1 unverifiable, disagreeing with the report body (8 Verified, 0 Unverifiable) -->

---

## Claim 1: "Takes an artifact (statistical-model or counterexamples) and scored papers, returns surgical edit proposals ... This is Phase 4 of the evidence grounding architecture."

**Location:** `app/api/evidence-integrate/route.ts:1-7`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High

The route validates `artifactType` against `SCHEMA_DESCRIPTIONS`, whose keys are exactly `"statistical-model"` and `counterexamples`:

```ts
// app/api/evidence-integrate/route.ts:98-101
if (!body.artifactType || !(body.artifactType in SCHEMA_DESCRIPTIONS)) {
  return NextResponse.json({ error: "artifactType must be 'statistical-model' or 'counterexamples'" }, { status: 400 });
}
```

The "Phase 4" label matches the type module's own section header:

```ts
// app/lib/types/evidence.ts:209-211
// Integration proposals (Phase 4)
```

Comment/doc-only.

**Evidence:** `app/api/evidence-integrate/route.ts:1-7,98-101`, `app/lib/types/evidence.ts:209-211`

---

## Claim 2: statistical-model SCHEMA_DESCRIPTIONS structure and valid fieldPaths

**Location:** `app/api/evidence-integrate/route.ts:33-51`
**Type:** Behavioral (data contract)
**Verdict:** Verified
**Confidence:** High

The doc string tells the LLM the artifact has top-level keys `summary`, `variables[]`, `hypotheses[]`, `assumptions[]`, `sampleRequirements`, and lists paths such as `variables[i].distribution`, `hypotheses[i].statement`, `hypotheses[i].nullHypothesis`, `hypotheses[i].testSuggestion`, `assumptions[i]`. These match the real inner artifact object exactly:

```ts
// app/lib/types/artifacts.ts:48-66
statisticalModel: {
  variables: Array<{ id; label; role; distribution?; }>;
  hypotheses: Array<{ id; statement; nullHypothesis; testSuggestion; }>;
  assumptions: string[];
  sampleRequirements?: string;
  summary: string;
};
```

Every documented leading key (`variables`, `hypotheses`, `assumptions`, `summary`, `sampleRequirements`) is present, so `resolveFieldPath` walks these paths successfully. Behavioral, and correct.

**Evidence:** `app/api/evidence-integrate/route.ts:33-51`, `app/lib/types/artifacts.ts:48-66`

---

## Claim 3: counterexamples SCHEMA_DESCRIPTIONS structure and valid fieldPaths (`counterexamples[i].*`)

**Location:** `app/api/evidence-integrate/route.ts:53-68`
**Type:** Behavioral (data contract)
**Verdict:** Incorrect
**Confidence:** High

The doc string tells the LLM the counterexamples artifact's array key is `counterexamples` and that valid paths include `counterexamples[i].scenario`, `counterexamples[i].explanation`, `counterexamples[i].plausibility`:

```ts
// app/api/evidence-integrate/route.ts:53-68
counterexamples: `The artifact is a counterexamples analysis with this structure:
{
  "claim": "string",
  "counterexamples": [{ "id": ..., "scenario": ..., ... }],
  ...
}
Valid fieldPaths include:
- "counterexamples[i].scenario" — a counterexample scenario
- "counterexamples[i].explanation" — why the counterexample works
- "counterexamples[i].plausibility" — plausibility rating (high/medium/low)
```

But the real artifact's array key is `scenarios`, not `counterexamples`:

```ts
// app/lib/types/artifacts.ts:115-128
counterexamples: {
  claim: string;
  scenarios: Array<{ id; scenario; targetAssumption; explanation; plausibility; }>;
  robustnessAssessment: string;
  summary: string;
};
```

The emitting route defines the same shape — its LLM contract uses `"scenarios"` as the array key:

```ts
// app/api/formalization/counterexamples/route.ts:8-9,49-51
{ "claim": "string", "scenarios": [ ... ] }
...
responseKey: "counterexamples",   // wraps the inner object under `counterexamples`
```

The object passed to the integration API is that inner object (top-level `claim` — matching the doc string's top-level `claim`, confirming it is unwrapped), whose array key is `scenarios`. The consumer panel even confirms `scenarios` is canonical, keeping only a legacy fallback:

```ts
// app/components/panels/CounterexamplesPanel.tsx:26-27
function getScenarios(data: any) {
  return data?.scenarios ?? data?.counterexamples;
}
```

Consequence (checked against `resolveFieldPath`): a path like `counterexamples[0].scenario` is split to `["counterexamples","0","scenario"]`; the walk reads `obj["counterexamples"]`, which is `undefined` on the real artifact, so the function returns null:

```ts
// app/lib/utils/applyProposals.ts:29-32
current = current?.[idx];
if (current === undefined || current === null) return null;
```

`validateProposal` then rejects the proposal (`if (!resolveFieldPath(artifact, fieldPath)) return null;`, integrateValidation.ts:51), and even if it slipped through, `applyProposals` skips it (`if (!resolved) continue;`, applyProposals.ts:74). So every per-scenario counterexample proposal the LLM is instructed to make is **silently dropped**; only top-level scalar paths (`claim`, `robustnessAssessment`, `summary`) survive. **Behavioral** — the counterexamples integration feature silently no-ops for all scenario-level edits.

**Evidence:** `app/api/evidence-integrate/route.ts:53-68`, `app/lib/types/artifacts.ts:115-128`, `app/api/formalization/counterexamples/route.ts:8-19,49-54`, `app/components/panels/CounterexamplesPanel.tsx:26-27`, `app/lib/utils/applyProposals.ts:29-32,74`, `app/api/evidence-integrate/integrateValidation.ts:51`

---

## Claim 4: resolveFieldPath — "Resolve a dot-notation field path ... Returns null if the path cannot be resolved against the object."

**Location:** `app/lib/utils/applyProposals.ts:3-8`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

Implementation returns `{ parent, key }` when the final key exists on an object, else null:

```ts
// app/lib/utils/applyProposals.ts:34-38
if (typeof current !== "object" || current === null) return null;
if (!(lastKey in current)) return null;
return { parent: current, key: lastKey };
```

Intermediate missing segments also return null (lines 29-32). Behavioral, correct.

**Evidence:** `app/lib/utils/applyProposals.ts:3-8,20-38`

---

## Claim 5: inline comment — `// Split "hypotheses[1].statement" → ["hypotheses", "1", "statement"]`

**Location:** `app/lib/utils/applyProposals.ts:17`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The transform matches the comment:

```ts
// app/lib/utils/applyProposals.ts:18-22
const segments = path
  .replace(/\[(\d+)\]/g, ".$1")
  .split(".")
  .filter(Boolean);
```

`"hypotheses[1].statement"` → `"hypotheses.1.statement"` → `["hypotheses","1","statement"]`. Comment/doc-only.

**Evidence:** `app/lib/utils/applyProposals.ts:17-22`

---

## Claim 6: getFieldValue — "Read the value at a dot-notation field path. Returns undefined if the path doesn't resolve."

**Location:** `app/lib/utils/applyProposals.ts:40-43`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

```ts
// app/lib/utils/applyProposals.ts:48-51
const resolved = resolveFieldPath(obj, path);
if (!resolved) return undefined;
return (resolved.parent as Record<string | number, unknown>)[resolved.key];
```

Comment/doc-only.

**Evidence:** `app/lib/utils/applyProposals.ts:40-51`

---

## Claim 7: applyProposals — "Only proposals with `decision === true` are applied ... Returns the updated JSON string, or the original if no proposals apply." plus "Try to parse proposedValue as JSON ... fall back to raw string"

**Location:** `app/lib/utils/applyProposals.ts:53-62,80-82`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

```ts
// app/lib/utils/applyProposals.ts:70-72
const approved = proposals.filter((p) => p.decision === true);
if (approved.length === 0) return artifactJson;
```

```ts
// app/lib/utils/applyProposals.ts:80-86
try { value = JSON.parse(proposal.proposedValue); }
catch { value = proposal.proposedValue; }
(resolved.parent as Record<string | number, unknown>)[resolved.key] = value;
```

Behavioral, correct.

**Evidence:** `app/lib/utils/applyProposals.ts:53-62,70-86`

---

## Claim 8: validateProposal JSDoc — "@param validPaperIds - Set of openAlexIds from the request papers" / "@returns A validated RawIntegrationProposal, or null if invalid"

**Location:** `app/api/evidence-integrate/integrateValidation.ts:16-24`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High

The route constructs `validPaperIds` exactly as documented and the function filters against it:

```ts
// app/api/evidence-integrate/route.ts:171
const validPaperIds = new Set(body.papers.map((p) => p.openAlexId));
```

```ts
// app/api/evidence-integrate/integrateValidation.ts:59-63
const filteredPaperIds = (paperIds as unknown[]).filter(
  (id): id is string => typeof id === "string" && validPaperIds.has(id),
);
if (filteredPaperIds.length === 0) return null;
```

Return type is `RawIntegrationProposal | null`. Comment/doc-only (accurate).

**Evidence:** `app/api/evidence-integrate/integrateValidation.ts:16-24,59-73`, `app/api/evidence-integrate/route.ts:171`

---

## Claim 9: route comment — "// No API key — return empty proposals" on the `!text` branch

**Location:** `app/api/evidence-integrate/route.ts:207`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium

`callLlm` returns `text: ""` only on the mock (no-API-key) fallback:

```ts
// app/lib/llm/callLlm.ts:98-100
/*  On mock fallback, returns text: "" — the caller provides its own mock text. */
```
```ts
// app/lib/llm/callLlm.ts:223
return { text: "", usage };
```

So a falsy `text` in the route corresponds to the no-key case, and the route returns `{ proposals: [] }`. Medium confidence because a real provider returning an empty string would take the same branch (an edge case), but the documented cause (no API key) is the actual trigger. Comment/doc-only.

**Evidence:** `app/api/evidence-integrate/route.ts:198-201`, `app/lib/llm/callLlm.ts:98-100,205-223`

---

## Claims Requiring Attention

### Incorrect
- **Claim 3** (`app/api/evidence-integrate/route.ts:53-68`): counterexamples schema doc names the array key `counterexamples` and paths `counterexamples[i].*`, but the real artifact key is `scenarios`; `resolveFieldPath` returns null for those paths, so all per-scenario proposals are silently dropped. Fix: change the documented structure and fieldPaths to `scenarios` / `scenarios[i].*`. Behavioral.

### Stale
- None.

### Mostly Accurate
- None.

### Unverifiable
- None material. (Claim 9 verified at Medium confidence.)
