Commit: 6cf4b0d

# API Consistency Review — assisted evidence integration (Phase 4)

**Scope:** `git diff 6cf4b0d^..6cf4b0d` — `app/api/evidence-integrate/` (`route.ts`, `integrateValidation.ts`, `integrateValidation.test.ts`) and `app/lib/utils/applyProposals.ts`
**Date:** 2026-08-07
**Based on:** `hunt-verify/candB-fact-check.md` (Claim 3 flagged the counterexamples key mismatch)

The consumer contract under review is the **field-path vocabulary** the server publishes to the LLM in `SCHEMA_DESCRIPTIONS`. The LLM is told which `fieldPath` strings are valid for each artifact type; the server then resolves each path against the real artifact via `resolveFieldPath` and applies `proposedValue`. So the artifact's actual field names ARE the API surface here — every documented path must match the canonical artifact type in `app/lib/types/artifacts.ts`, or proposals silently fail to resolve (`resolveFieldPath` returns null → `validateProposal` drops the proposal → `applyProposals` skips it).

## Baseline Conventions

- **Route naming:** sibling evidence routes are `evidence-search`, `evidence-score`, `evidence-overlap` (`app/api/evidence-*/route.ts`) — `evidence-<verb>`, kebab-case. `evidence-integrate` fits.
- **Error envelope:** all sibling routes return `{ error: string }` for 4xx/500 and `{ error, details }` for 502 `OpenRouterError` (`app/api/evidence-search/route.ts:146-192`, `app/api/evidence-score/route.ts:142-236`). The new route matches exactly (`route.ts:98-119, 236-246`).
- **No-key fallback:** `evidence-score` signals the mock/no-key path with an explicit flag: `{ scores, mock: true }` (`app/api/evidence-score/route.ts:210`).
- **Artifact array key (counterexamples):** the canonical type is `CounterexamplesResponse.counterexamples.scenarios` (`app/lib/types/artifacts.ts:113-128`); the generator route emits `"scenarios"` (`app/api/formalization/counterexamples/route.ts:9,34`); the consumer panel treats `scenarios` as canonical with only a legacy `counterexamples` fallback (`CounterexamplesPanel.tsx:26-27`). `scenarios` is the established name in 3 independent places.
- **editType vocabulary:** the union `IntegrationEditType` (`app/lib/types/evidence.ts`) is the source of truth: `update-prior | add-evidence | flag-contradiction | refine-wording`.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|----------|----------|------------------|----------------|---------|
| `POST /api/evidence-integrate` | route | `evidence-search`, `evidence-score`, `evidence-overlap` | `app/api/evidence-*/route.ts` | Consistent — `evidence-<verb>` kebab-case |
| `resolveFieldPath`, `getFieldValue`, `applyProposals` | function (exported) | `stripCodeFences`, `serializeTargetKey` | `app/lib/utils/*`, `app/lib/types/evidence.ts` | Consistent — verb-noun camelCase |
| `validateProposal` | function (exported) | `serializeTargetKey`, `isReviewType` | `app/lib/types/evidence.ts` | Consistent |
| editType enum values | field/enum | `IntegrationEditType` union | `app/lib/types/evidence.ts:214-218` | Consistent — matches union exactly |
| `counterexamples[i].*` field paths (in `SCHEMA_DESCRIPTIONS.counterexamples`) | field name (published contract) | `scenarios` array key | `app/lib/types/artifacts.ts:115-116`, `app/api/formalization/counterexamples/route.ts:9`, `CounterexamplesPanel.tsx:26` | **Inconsistent — canonical array key is `scenarios`, not `counterexamples`** (expanded → Finding 1) |
| `statistical-model` field paths (`summary`, `variables[i].distribution`, `hypotheses[i].*`, `assumptions[i]`, `sampleRequirements`) | field name (published contract) | `StatisticalModelResponse.statisticalModel.*` | `app/lib/types/artifacts.ts:48-66` | Consistent — every documented path matches the inner artifact |

## Findings

#### Counterexamples field-path contract names the wrong array key (`counterexamples` vs `scenarios`)

**Severity:** Breaking
**Location:** `app/api/evidence-integrate/route.ts:54-68`
**Move:** #3 (consumer contract) + #7 (asymmetry, naming-shaped)
**Confidence:** High

Precedent: `scenarios` array key used in `app/lib/types/artifacts.ts:115-116`, `app/api/formalization/counterexamples/route.ts:9,34`, `app/components/panels/CounterexamplesPanel.tsx:26-27`

`SCHEMA_DESCRIPTIONS.counterexamples` documents the structure as `{ "claim": ..., "counterexamples": [{ ... }] }` and publishes valid paths `"counterexamples[i].scenario"`, `"counterexamples[i].explanation"`, `"counterexamples[i].plausibility"`. But the real (unwrapped) artifact object is `{ claim, scenarios: [...], robustnessAssessment, summary }` — the array key is `scenarios`. That the artifact is passed unwrapped is confirmed by the sibling `statistical-model` block, whose top-level paths (`summary`, `variables[i]...`) match the *inner* `statisticalModel` object, not the wrapped `{ statisticalModel: {...} }`. Consequence: for every scenario-level path the LLM is instructed to emit, `resolveFieldPath` reads `obj["counterexamples"]` = `undefined` and returns null (`applyProposals.ts:29-32`); `validateProposal` then drops the proposal (`integrateValidation.ts:56`). The counterexamples integration feature **silently no-ops for all per-scenario edits** — only top-level scalars (`claim`, `robustnessAssessment`, `summary`) can ever apply. No error surfaces; the user sees fewer/zero proposals with no signal why.

**Recommendation:** Rename the documented array key and paths to `scenarios` / `scenarios[i].scenario` / `scenarios[i].explanation` / `scenarios[i].plausibility` to match `app/lib/types/artifacts.ts`. Add a counterexamples-artifact fixture to `integrateValidation.test.ts` (current tests only exercise a statistical-model-shaped artifact, so this class of mismatch is invisible to the suite).

#### No-key fallback drops the `mock`/status flag that the sibling route publishes

**Severity:** Minor
**Location:** `app/api/evidence-integrate/route.ts:205-208`
**Move:** #7 (asymmetry — response envelope)
**Confidence:** Medium

On the no-API-key path the route returns `{ proposals: [] }`, indistinguishable from a genuine "the LLM found nothing to propose" result. The sibling `evidence-score` route handles the same mock branch by returning `{ scores, mock: true }` (`app/api/evidence-score/route.ts:210`), letting consumers tell "not configured" apart from "no results." Consumers of `evidence-integrate` (`app/hooks/useEvidenceIntegration.ts`) cannot make that distinction.

**Recommendation:** Return `{ proposals: [], mock: true }` on the `!text` branch to match the `evidence-score` envelope, or document that an empty `proposals` array conflates the two cases.

#### editType allowed-values list is triplicated across three sources of truth

**Severity:** Minor
**Location:** `app/api/evidence-integrate/integrateValidation.ts:9-14`
**Move:** #3 (consumer contract — drift risk)
**Confidence:** High

The four edit-type strings are declared three times: the `IntegrationEditType` union (`app/lib/types/evidence.ts:214-218`), the `INTEGRATE_SCHEMA` JSON-schema enum (`route.ts:138-141`), and the local `VALID_EDIT_TYPES` array (`integrateValidation.ts:9-14`). All three agree today, but adding a fifth edit type requires editing all three in lockstep; miss one and the JSON schema, the runtime validator, and the TS type diverge silently.

**Recommendation:** Derive `VALID_EDIT_TYPES` (and ideally the schema enum) from a single exported runtime tuple in `evidence.ts` — the pattern already used for `EVIDENCE_ARTIFACT_TYPES` and `STUDY_TYPES` in that same file.

## What Looks Good

- Route path, error envelope (`{ error }` / `{ error, details }` + status codes 400/502/500), and `OpenRouterError` handling match the sibling evidence routes precisely.
- The `statistical-model` field-path contract is fully consistent with the canonical artifact type — every documented path resolves.
- Exported util names (`resolveFieldPath`, `getFieldValue`, `applyProposals`, `validateProposal`) follow the codebase's verb-noun camelCase convention.
- `editType` enum values match the `IntegrationEditType` union exactly.
- Request validation (`artifactType` membership, non-empty `papers`, `MAX_INTEGRATION_PAPERS` cap) mirrors `evidence-score`'s guard style.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Counterexamples paths use `counterexamples` key; canonical is `scenarios` — all scenario edits silently no-op | Breaking | `route.ts:54-68` | High |
| 2 | No-key fallback omits `mock` flag that `evidence-score` publishes | Minor | `route.ts:205-208` | Medium |
| 3 | editType values triplicated (union / schema enum / validator array) | Minor | `integrateValidation.ts:9-14` | High |

## Overall Assessment

The new route is well-aligned with the evidence-* family on naming, error envelope, and validation style — the author clearly surveyed the sibling routes. The one serious problem is a published-contract mismatch: the counterexamples field-path vocabulary names the array `counterexamples` where every other place in the codebase (the artifact type, the generator route, the consumer panel) calls it `scenarios`. Because `resolveFieldPath` fails closed and no error is raised, the counterexamples half of this feature is dead on arrival for per-scenario edits, and the test suite can't see it because it only fixtures a statistical-model artifact. Finding 1 is a one-line-vocabulary fix plus a counterexamples test fixture; Findings 2-3 are consistency polish. Consumer impact of Finding 1 is high (a whole artifact type's integration silently produces nothing); the rest is low.
