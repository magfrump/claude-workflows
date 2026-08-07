Commit: 6cf4b0d

# Architecture Review — assisted evidence integration (`app/api/evidence-integrate/`, `app/lib/utils/applyProposals.ts`)

**Scope:** `git diff 6cf4b0d^..6cf4b0d -- app/api/evidence-integrate/ app/lib/utils/applyProposals.ts`
**Date:** 2026-08-07
**Based on:** `candB-fact-check.md` (9 claims; Claim 3 = counterexamples schema drift, Incorrect/High)
**PR intent:** LLM proposes field-path edits to a structured artifact; proposals are validated then applied.

## Dependency Map

Volatile → stable, and the direction is sound:

- `route.ts` (HTTP boundary) depends on `integrateValidation.ts`, `applyProposals.ts` (via re-export of `resolveFieldPath`), `callLlm`, and `types/evidence`.
- `integrateValidation.ts` (server, testable) depends on `applyProposals.ts` (`resolveFieldPath`) and `types/evidence`.
- `applyProposals.ts` (`app/lib/utils`, stable leaf) depends only on `types/evidence`. No inward edges from types or infra.
- Consumers: `useEvidenceIntegration.ts` (client hook) calls the route; `FindEvidenceButton.tsx` calls `applyProposals`.

The key structural fact: **`resolveFieldPath` is the single shared field-path navigator used by both the server validation path (`integrateValidation`) and the client write path (`applyProposals`).** That is good — one resolver, one semantics. The problem is not the resolver; it is the *contract the resolver is validated against*, described below.

## Findings

#### The LLM field-path contract is decoupled from its source-of-truth artifact types

**Severity:** Structural
**Location:** `app/api/evidence-integrate/route.ts:38-71` (`SCHEMA_DESCRIPTIONS`) vs `app/lib/types/artifacts.ts:70-134`
**Move:** #3 (module boundary) / #7 (coupling surface)
**Confidence:** High

The set of legal `fieldPath`s is the true public contract of this feature — it is what the LLM is told to emit, what `resolveFieldPath` walks, and what the artifact types actually expose. That contract is expressed **three separate times in three separate representations**: (1) an opaque prose string in `SCHEMA_DESCRIPTIONS`, (2) the runtime `artifacts.ts` type (`StatisticalModelResponse`, `CounterexamplesResponse`), and (3) the shape `resolveFieldPath` navigates at runtime. Only (2) is machine-checked; (1) is a hand-maintained string with no compile-time tie to (2). Nothing forces them to agree.

The counterexamples bug the fact-check found (Claim 3: schema says `counterexamples[i].*`, real key is `scenarios`) is not an isolated typo — it is the *guaranteed* failure mode of this structure. Because the schema is a string divorced from the type, any rename or new artifact field silently drifts, and the failure is invisible: `resolveFieldPath` returns null → `validateProposal` drops the proposal → the feature no-ops with no error. Every future artifact-type change re-opens this trap.

> `SCHEMA_DESCRIPTIONS: Record<EvidenceArtifactType, string>` — keyed by the type union (so a *new artifact type* is caught at compile time), but the field-path bodies inside each string are free text (uncheckable).

**Recommendation:** Derive the field-path list (or at least assert it) from the artifact types rather than hand-writing prose. E.g. generate the schema description from a typed field-path registry, or add a test that enumerates the documented paths and asserts each `resolveFieldPath`s against a representative fixture of each artifact type. The compile-time key-coverage on the `Record` is the right instinct; extend it inward to the paths.

#### `editType` legal-value list is triplicated across three modules

**Severity:** Coupling
**Location:** `app/lib/types/evidence.ts:213-217` (`IntegrationEditType` union), `app/api/evidence-integrate/route.ts:157-160` (JSON-schema `enum`), `app/api/evidence-integrate/integrateValidation.ts:9-14` (`VALID_EDIT_TYPES`)
**Move:** #7 (coupling)
**Confidence:** High

The four edit-type strings are declared independently in the type union, the OpenRouter response-schema `enum`, and the runtime `VALID_EDIT_TYPES` array. Adding or renaming an edit type requires editing all three, and only the union is compiler-enforced — the enum and the array can silently fall out of sync with it (a `VALID_EDIT_TYPES` entry not in the union would not be caught; the runtime array is `readonly string[]`, deliberately un-narrowed).

**Recommendation:** Make `VALID_EDIT_TYPES` the single source (`as const` tuple), derive `IntegrationEditType` from it (`typeof VALID_EDIT_TYPES[number]`), and build the JSON-schema `enum` from the same tuple. One edit propagates everywhere and the compiler enforces coverage.

#### `applyProposals` reinterprets `proposedValue` as JSON, diverging from the validated string contract

**Severity:** Coupling
**Location:** `app/lib/utils/applyProposals.ts:78-86` vs `app/api/evidence-integrate/integrateValidation.ts:36-45`
**Move:** #6 (substitutability) / #7 (coupling)
**Confidence:** Medium

`proposedValue` is typed `string`, and `validateProposal` treats it strictly as a string (rejects non-string, compares equality to `currentValue`). But the write path `applyProposals` runs `JSON.parse(proposedValue)` and falls back to raw string on throw — so the same field is a plain string at validation time and a maybe-structured value at apply time. The two ends of the pipeline hold different mental models of the field. A `proposedValue` of `"42"` or `"true"` validates as a string edit but lands in the artifact as a number/boolean, silently changing the field's type. This coupling is invisible from the type (`string` at both ends) and lives only in the two implementations.

**Recommendation:** Decide the contract in one place. Either `proposedValue` is always a string (drop the `JSON.parse` in `applyProposals`), or it is a typed value the validator also parses — but the validation and apply paths must share the same interpretation, ideally the same helper.

#### `getFieldValue` exists to read current values but the validator never uses it to confirm `currentValue`

**Severity:** Minor
**Location:** `app/lib/utils/applyProposals.ts:44-51`, `app/api/evidence-integrate/integrateValidation.ts:29-34`
**Move:** #2 (responsibility) / #8 (extension points)
**Confidence:** Medium

The prompt rule "currentValue MUST exactly match what is currently in the artifact" (`route.ts:88`) is a real invariant, and `getFieldValue` is a purpose-built, exported reader for exactly this. Yet `validateProposal` only checks `currentValue` is a string and differs from `proposedValue`; it never asserts `currentValue === getFieldValue(artifact, fieldPath)`. The stale-value guard is stated in the prompt but unenforced in code, so a proposal built against drifted text is applied over whatever is actually there. Low structural impact but a missed use of an abstraction the diff already ships.

**Recommendation:** In `validateProposal`, compare `currentValue` against `getFieldValue(artifact, fieldPath)` and reject on mismatch — closes the stale-edit gap using code already present.

## What Looks Good

- **Shared resolver.** `resolveFieldPath` is defined once and reused by both the server validation path and the client apply path — the read/validate/write semantics cannot diverge, which is the correct call for a field-path contract.
- **Testable extraction.** Pulling `validateProposal` out of the route handler into `integrateValidation.ts` (with its own unit test) keeps the HTTP boundary thin and the validation logic pure — clean separation of the I/O shell from the decision core.
- **Compile-time key coverage.** `SCHEMA_DESCRIPTIONS: Record<EvidenceArtifactType, string>` forces every artifact type to have a schema entry; a new type won't silently lack a prompt. The right instinct — it just stops at the type key and doesn't reach the field paths.
- **Defense in depth at the trust boundary.** The route re-validates every LLM proposal (paper-id allowlist, field-path resolution, type checks) rather than trusting structured-output mode — correct posture for an LLM-sourced payload.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | LLM field-path contract decoupled from artifact types (drift is silent) | Structural | `route.ts:38-71` / `artifacts.ts:70-134` | High |
| 2 | `editType` list triplicated across three modules | Coupling | `evidence.ts:213`, `route.ts:157`, `integrateValidation.ts:9` | High |
| 3 | `proposedValue` reinterpreted as JSON at apply, string at validate | Coupling | `applyProposals.ts:78-86` | Medium |
| 4 | `currentValue` invariant unenforced despite `getFieldValue` existing | Minor | `integrateValidation.ts:29-34` | Medium |

## Overall Assessment

The module structure is sound — dependency direction is correct, the field-path resolver is shared rather than duplicated, and the validation core is cleanly extracted and tested. The single important structural concern is that the feature's real contract, the legal `fieldPath` set, lives as hand-written prose in `SCHEMA_DESCRIPTIONS` with no compile-time link to the artifact types it must mirror. The counterexamples `scenarios` bug is the predictable output of that decoupling, not a one-off, and it fails silently. This is fixable in place (derive/assert the paths from the types, or a coverage test) without restructuring, and doing so would also subsume the `editType` triplication — both are the same root pattern: a typed source of truth shadowed by an un-enforced duplicate.
