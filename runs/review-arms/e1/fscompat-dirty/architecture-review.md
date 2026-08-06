# Architecture Review — fscompat-dirty (d86d2dc..b64c1ca)

**Scope:** `git diff d86d2dc..b64c1ca` in the pinned worktree `/workspace/runs/review-arms/e1/wt-fscompat-dirty` (detached at b64c1ca) — extraction of `dataDir()` into `app/lib/utils/dataDir.ts` and rewiring of `app/lib/analytics/persist.ts` and `app/lib/llm/cache.ts`. Reviewed as structure only: dependency direction, responsibility boundaries, module boundaries, layer violations, interface segregation, substitutability, coupling surface, extension points.
**Date:** 2026-08-06
**Based on:** merged code-fact-check report (k=3, `code-fact-check-report.md`) — taken as foundation, not re-verified.
**Commit:** b64c1ca

No `security-review.md` existed in the output directory at the time this review was written, so no boundary-label cross-referencing was performed.

### Dependency Map

New and changed edges introduced by this range (`→` = imports):

```
app/api/analytics/route.ts ─────────────┐
app/lib/llm/callLlm.ts ─────────────────┼──→ app/lib/analytics/persist.ts ──┐
app/lib/llm/streamLlm.ts ───────────────┤                                   │
                                        └──→ app/lib/llm/cache.ts ──────────┤
app/lib/formalization/artifactRoute.ts ─────→ app/lib/llm/cache.ts ─────────┤
                                                                            │
                                            ┌───────────────────────────────┘
                                            ▼
                              app/lib/utils/dataDir.ts   (NEW)
                                            │
                                            ├──→ node:path (join)
                                            ├──→ process.cwd()        [ambient]
                                            └──→ process.env.VERCEL   [ambient — hosting vendor]
```

Sibling context, unchanged by the diff but relevant to the module-boundary audit:

```
app/page.tsx, app/hooks/**, app/components/panels/** ("use client")
        └──→ app/lib/utils/{textSelection,export,exportAll,exportGraph,
                            fileExtraction,latexParser,pdfPropositionParser,
                            workspacePersistence,throttle,...}
             ── same directory as, and no barrier against, dataDir.ts ──
```

Shape of the change: previously `persist.ts` and `cache.ts` each owned a private, duplicated copy of the location policy (an inline `process.env.VERCEL ? … : …` ternary). Now both depend on one leaf module that has no internal dependencies. The direction is correct — two mid-layer modules pointing at a shared leaf, no cycles, no new upward edges, no new packages (fact-check Claim 10). The problems are not in the arrow directions; they are in what the leaf's interface promises versus what it delivers, and in where the leaf was placed.

### Findings

#### F1. `/tmp` and `<cwd>/data` are presented as interchangeable but are not semantically substitutable

**Severity:** Structural
**Location:** `app/lib/utils/dataDir.ts:12-15`; consumers `app/lib/analytics/persist.ts:8-9`, `app/lib/llm/cache.ts:7`; downstream `app/api/analytics/route.ts:4-11`
**Move:** Substitutability
**Confidence:** High — the interface is one line and both consumers were traced end to end; the per-instance consequence is established by fact-check Claims 3 and 11 (unanimous / single-replicate respectively) and is not re-derived here.
**Evidence:**

> ```ts
> export function dataDir(...subpaths: string[]): string {
>   const base = process.env.VERCEL ? "/tmp" : join(process.cwd(), "data");
>   return subpaths.length > 0 ? join(base, ...subpaths) : base;
> }
> ```

(app/lib/utils/dataDir.ts:12-15)

**Legibility-target:** for-orchestrator-synthesis

The return type is `string` — a filesystem path — which is the same type in both branches and therefore invites callers to treat the branches as equivalent. They are not: `<cwd>/data` is a single, durable, process-shared store, while `/tmp` on Vercel is per-instance and ephemeral, so the same code path acquires a different durability *and* a different consistency model depending on an ambient environment variable. The consequence is visible one layer up: `GET /api/analytics` calls `readAnalyticsEntries()` and `DELETE /api/analytics` calls `clearAnalyticsEntries()` (app/api/analytics/route.ts:4-11), and on Vercel each serves whichever instance's private `/tmp` answered the request — so the analytics panel can show a partial history and "clear" can clear one instance's file while others keep theirs. This is a Liskov-shaped violation at the module level: the abstraction hides a substitution that the caller's correctness actually depends on, and no caller was changed to account for it.

**Recommendation:** Make the durability difference visible in the type rather than hidden behind a path string — e.g. return `{ path: string; durable: boolean }`, or export a companion `isDurableStorage()` that consumers with read-your-writes semantics (the analytics API) can branch on. Minimally, document the consistency contract in the `dataDir()` docstring so the next consumer does not inherit the assumption silently. Deciding what analytics *should* do on Vercel (accept partial history, move to an external store, or disable the panel) is a product call and out of scope here; the structural ask is that the choice be forced rather than defaulted.

#### F2. The deploy-environment branch is asymmetric: no local gate can execute it

**Severity:** Structural
**Location:** `app/lib/utils/dataDir.ts:13`; test config `vitest.config.ts:8-10`; scripts `package.json:5-11`
**Move:** Extension points / testability of a boundary
**Confidence:** High — verified directly: no test file imports `dataDir` (repo-wide `rg -n "dataDir"` returns only the definition and the two consumers), and the branch predicate is a single ambient env read.
**Evidence:**

> `  const base = process.env.VERCEL ? "/tmp" : join(process.cwd(), "data");`

(app/lib/utils/dataDir.ts:13)

**Legibility-target:** for-author

Every local verification gate this repo has — `next dev`, `next build`, `eslint`, and `vitest run` — runs with `VERCEL` unset and therefore takes the `else` branch exclusively; the Vercel branch's first execution is in production. The test suite cannot close this by accident either: `vitest.config.ts` sets `environment: 'jsdom'`, and no test imports the module, so the count of assertions covering the `/tmp` path at this commit is zero. That asymmetry is the structural cost of the extraction as written: the change centralized a rule that no automated check can see, which means future edits to that one line are unverifiable by anything short of a deploy. The mitigating fact is that `dataDir()` is now a pure function of `process.env` plus `process.cwd()` and returns a string with no I/O — it is the most testable shape this policy has ever had, and the extraction is what made that possible.

**Recommendation:** Add `app/lib/utils/dataDir.test.ts` asserting both branches by stubbing `process.env.VERCEL` (`vi.stubEnv`) — three cases: unset → `<cwd>/data`, set → `/tmp`, and subpath joining on both. This is a handful of lines, requires no jsdom/node environment change since the function touches no filesystem, and converts an untestable-by-default production-only branch into a covered one. Note that this covers the helper, not the consumers — see F6 for why consumer-level coverage is harder.

#### F3. A core library module now depends on a hosting vendor's environment variable

**Severity:** Structural
**Location:** `app/lib/utils/dataDir.ts:13`
**Move:** Dependency direction
**Confidence:** Medium-High — the coupling is unambiguous in the code; the severity rests on a judgment about deployment portability, and the repo does self-describe as supporting self-hosted deploys (dataDir.ts:8-10).
**Evidence:**

> ` * On Vercel Functions only `/tmp` is writable, and it lives only as long as
>  * the warm container — so persistence does not survive cold starts. In dev
>  * and self-hosted deployments we write to the repo's `data/` dir for durable
>  * cross-restart storage.`

(app/lib/utils/dataDir.ts:7-10)

**Legibility-target:** for-author

The dependency runs the wrong way: application persistence policy — a domain concern — now reads a vendor-specific ambient signal and infers infrastructure capability from it. That inference is what makes the module fragile in both directions: any other read-only-filesystem host (Netlify, Lambda, a container with a read-only root) gets the durable branch and the silent-write-failure behavior this range exists to fix, while a self-hosted deploy that happens to export `VERCEL` for any reason is misrouted to `/tmp` (fact-check Claim 4, caveat b). Inverting it — having the module read *its own* configuration contract, with Vercel supplying the value — removes the vendor knowledge from `app/lib/` entirely and, as a side effect, makes F2's branch reachable locally by exporting one variable.

**Recommendation:** Replace vendor detection with a first-class config input: `const base = process.env.APP_DATA_DIR ?? join(process.cwd(), "data")`, and set `APP_DATA_DIR=/tmp` in the Vercel project environment (keeping `process.env.VERCEL` as a fallback default if you want zero-config Vercel deploys to keep working). This makes the policy portable to any host, testable locally, overridable by self-hosters who want data outside the repo, and turns "which directory" into a documented deployment knob rather than an inference.

#### F4. A server-only module was placed in the directory the project documents as client utilities

**Severity:** Coupling
**Location:** `app/lib/utils/dataDir.ts` (placement); `CLAUDE.md` directory-layout section; `docs/ARCHITECTURE.md:135`
**Move:** Module boundary audit / layer violation
**Confidence:** High for the boundary mismatch (both docs and the import graph were checked); Medium for the concrete bundling failure mode, which depends on Next.js build behavior not exercised here.
**Evidence:**

> `## Utilities (`lib/utils/`)`
> …
> `### textSelection.ts`
> `**Purpose**: Calculate accurate text position in textarea for popup placement`

(docs/ARCHITECTURE.md:135-141 — the section's only documented member is a DOM utility)

**Legibility-target:** for-author

`app/lib/utils/` is the project's grab-bag for browser-safe helpers: `textSelection.ts`, `export.ts`, `workspacePersistence.ts` (localStorage), `throttle.ts`, `latexParser.ts` and friends, imported directly by `"use client"` panels and hooks (`app/page.tsx`, `app/components/panels/*.tsx`, `app/hooks/*.ts`). `dataDir.ts` is the first member that reads `process.cwd()` and imports `node:path`, and nothing marks the difference — no `server-only` import, no `server/` subdirectory, and the project has no `server-only` dependency at all. The immediate risk is low because there is no barrel file, so a client import would have to name `dataDir` explicitly; the durable risk is that the directory's meaning has quietly become "utilities, some of which crash in the browser," and the next person adding a helper here has no signal telling them which kind they are looking at.

**Recommendation:** Move the module to a server-scoped location — `app/lib/server/dataDir.ts` is the smallest change and needs only two import updates — or, if it stays put, add `import "server-only";` at the top so a client import fails at build time rather than at runtime. Either way, update the `lib/utils/` descriptions in `CLAUDE.md` and `docs/ARCHITECTURE.md:135`, which currently describe the directory as UI-side helpers only.

#### F5. The extraction stopped at "where" and left "ensure it exists" duplicated in both consumers

**Severity:** Coupling
**Location:** `app/lib/analytics/persist.ts:11-15` and `app/lib/llm/cache.ts:27-32`
**Move:** Interface segregation / responsibility boundaries
**Confidence:** High — both implementations are short and were read in full; fact-check Claim 12/13 confirms both are behaviorally correct on either base directory.
**Evidence:**

> ```ts
> function ensureDir() {
>   if (!existsSync(DATA_DIR)) {
>     mkdirSync(DATA_DIR, { recursive: true });
>   }
> }
> ```

(app/lib/analytics/persist.ts:11-15)

**Legibility-target:** for-orchestrator-synthesis

What the two consumers genuinely share is not a path string but a capability: *a writable directory that exists*. The refactor centralized only the first half, so each consumer still carries its own directory-creation logic in a different idiom — `persist.ts` re-checks `existsSync` synchronously on every write, while `cache.ts` memoizes with a module-scoped `dirEnsured` boolean and uses async `mkdir`. Both are correct today (fact-check Claim 13 confirms the memoization is safe because the flag and the directory share a process lifetime), but they are two implementations of one policy, which is exactly the duplication the commit set out to remove, one level down. Because the `/tmp` branch is the case where the directory is *most* likely to be absent, directory-ensuring is arguably part of the same deploy-environment concern rather than a consumer detail.

**Recommendation:** Extend the helper to own the whole capability — e.g. `export async function ensureDataDir(...subpaths: string[]): Promise<string>` alongside the existing pure `dataDir()` — and have both consumers call it. Keep `dataDir()` exported for path construction that does not write. This is a follow-up, not a blocker: nothing is broken today, and doing it in the same commit would have expanded a no-behavior-change refactor into a behavior-touching one.

#### F6. Both consumers freeze the policy at module load, so the new seam offers no late binding

**Severity:** Coupling
**Location:** `app/lib/analytics/persist.ts:8-9`; `app/lib/llm/cache.ts:7`
**Move:** Coupling surface / extension points
**Confidence:** High — both are module-scope `const` initializers; fact-check Claim 6 independently confirms the load-time evaluation is unchanged from the pre-refactor code.
**Evidence:**

> `const CACHE_DIR = dataDir("cache");`

(app/lib/llm/cache.ts:7)

**Legibility-target:** for-orchestrator-synthesis

Turning an inline ternary into a function creates a seam, but both consumers immediately collapse it back into a constant at import time, so the seam has no late binding: the value is fixed by whatever `process.env.VERCEL` said when the module graph first loaded. The practical cost is testability at the consumer level — a test that wants `persist.ts` or `cache.ts` to write somewhere else must stub the env *and* reset the module registry (`vi.resetModules()` plus a dynamic `import()`), which is why F2's recommended test targets the helper rather than its consumers. Note this is not a regression: the pre-refactor constants had exactly the same timing (fact-check Claim 6), so the refactor's gain is deduplication and a single edit point, not injectability. The gap worth naming is between what the commit message advertises — a helper that makes future persistence "trivially correct" — and a call pattern that makes the helper's one degree of freedom unusable at runtime.

**Recommendation:** Leave as is unless consumer-level tests are wanted; if they are, call `dataDir()` inside the functions that use it (`ensureDir`, `appendAnalyticsEntry`, `getCachedResult`, …) rather than at module scope. The cost is one `join` per call on paths that already perform filesystem I/O, which is negligible, and it makes both modules testable with a plain `vi.stubEnv`.

#### F7. Two call conventions for a two-caller helper, with no canonical form

**Severity:** Minor
**Location:** `app/lib/analytics/persist.ts:8-9` vs `app/lib/llm/cache.ts:7`
**Move:** Interface segregation
**Confidence:** High — fact-check Claim 5 verified both conventions resolve correctly and that persist.ts has a functional reason for its form; nothing here disputes that.
**Evidence:**

> `const DATA_DIR = dataDir();`
> `const FILE_PATH = join(DATA_DIR, "analytics.jsonl");`

(app/lib/analytics/persist.ts:8-9)

**Legibility-target:** for-author

The helper's variadic signature advertises `dataDir("x")` as the idiom, and `cache.ts` uses it, but `persist.ts` calls `dataDir()` bare and joins the filename itself — because it needs the directory handle separately for `ensureDir()`. Both are correct (fact-check Claim 5), and the asymmetry is a symptom rather than a defect: it exists because the helper supplies a path but not directory creation, which is F5. Worth noting only because the helper's stated purpose is to give future consumers one obvious correct pattern, and at two callers it already has two.

**Recommendation:** Resolving F5 collapses this automatically — with `ensureDataDir("...")` owning creation, `persist.ts` no longer needs a separate directory constant. No independent action needed.

#### F8. A cross-cutting policy shipped without a documentation home

**Severity:** Minor
**Location:** `app/lib/analytics/persist.ts:6-7`; `docs/decisions/` (no record); `CLAUDE.md` and `docs/ARCHITECTURE.md:135` (directory descriptions not updated)
**Move:** Responsibility boundaries (documentation as an architectural artifact)
**Confidence:** High — the dangling reference is fact-check Claim 2 (Incorrect, unanimous 3/3); the missing decision record and stale directory descriptions were verified directly (`docs/decisions/` contains eight records, none about persistence or deployment).
**Evidence:**

> `// On Vercel, analytics history doesn't persist across cold starts — see`
> `// Deploy to Vercel in README. See dataDir() for the underlying rationale.`

(app/lib/analytics/persist.ts:6-7)

**Legibility-target:** for-author

Architecturally this is more than a broken link: the range establishes an invariant that governs what every future server-side feature may assume about persistence, and the invariant's only home is a docstring on a leaf utility that new contributors have no reason to open. The comment points at a README section that does not exist (the repo contains no Vercel documentation at all outside these two source files), there is no decision record despite `CLAUDE.md` calling for one on "significant architectural approach," and the `lib/utils/` descriptions in both `CLAUDE.md` and `docs/ARCHITECTURE.md` still describe a client-utilities directory. The result is that the policy is centralized in code and dispersed to nowhere in docs.

**Recommendation:** Write the README "Deploy to Vercel" section the comment already promises — commit 2136fd6's tradeoff paragraph is ready-made content — and state the per-instance/ephemeral consistency contract there, since that is the part consumers need and the docstring currently understates (fact-check Claims 3 and 11). Add `docs/decisions/00N-server-side-persistence-location.md` recording the policy, the vendor-detection choice, and the accepted tradeoff. If the README section is not going to be written, delete the reference rather than leaving it dangling.

#### F9. The extension point cannot express a durability requirement

**Severity:** Informational
**Location:** `app/lib/utils/dataDir.ts:12` (signature); commit b64c1ca message
**Move:** Extension points
**Confidence:** Medium — this is a projection about future consumers, not a defect in current code; the two existing consumers both tolerate ephemerality.
**Evidence:**

> `export function dataDir(...subpaths: string[]): string {`

(app/lib/utils/dataDir.ts:12)

**Legibility-target:** for-orchestrator-synthesis

The commit frames the helper as making future server-side persistence "trivially correct," and for location it does. But the interface answers only "where do I write?" — it cannot answer "is durable storage available here?", and it has no way to refuse or warn. Today's two consumers are both best-effort caches or logs that degrade acceptably; the risk is the third consumer, which might be something whose loss is not acceptable (queued jobs, user drafts, uploaded source documents) and which will get an ephemeral, instance-local directory with no signal that anything is wrong. That is the same silent-degradation failure class commit 2136fd6 was written to escape, re-entering through a different door.

**Recommendation:** Track with F1 — whichever mechanism surfaces durability to callers (a returned flag, a companion predicate, or a documented contract) closes this too. No separate work item.

### What Looks Good

- **Dependency direction is correct and the graph got simpler.** Two mid-layer modules that each owned a private copy of a policy now share one dependency-free leaf. No cycles, no new upward edges, no new packages (fact-check Claim 10), and the leaf imports only `node:path`.
- **The policy became a pure function.** `dataDir()` performs no I/O and reads no module state — it is a function of `process.env.VERCEL` and `process.cwd()` returning a string. That is precisely the shape that makes F2's missing test cheap to write; the previous inline ternaries could not have been tested at all.
- **The refactor is genuinely behavior-preserving.** Path resolution is identical in all four before/after cases and the env read happens at the same point in the lifecycle (fact-check Claim 6, unanimous). Separating the behavior change (2136fd6) from the structural extraction (b64c1ca) is the right commit hygiene and made this review tractable.
- **Consumer error handling was left intact and remains correct on both branches.** Every write from the LLM paths stays inside its existing `catch`, and the "persistence failure must not break LLM calls" invariant holds regardless of which base directory is returned (fact-check Claim 12).
- **Scope discipline.** Three files, 21 insertions, no drive-by changes to the consumers' logic, no speculative generality beyond the one variadic parameter that `cache.ts` immediately uses.

### Summary Table

| ID | Finding | Severity | Move | Location |
|----|---------|----------|------|----------|
| F1 | `/tmp` and `<cwd>/data` presented as interchangeable but differ in durability and consistency | Structural | Substitutability | dataDir.ts:12-15; api/analytics/route.ts:4-11 |
| F2 | Vercel branch unexecutable by dev/build/lint/test; no test at this commit | Structural | Extension points | dataDir.ts:13; vitest.config.ts:8-10 |
| F3 | Core lib module sniffs a hosting vendor's env var to infer filesystem capability | Structural | Dependency direction | dataDir.ts:13 |
| F4 | Server-only module placed in the documented client-utilities directory; no `server-only` guard | Coupling | Module boundary / layer | app/lib/utils/dataDir.ts; ARCHITECTURE.md:135 |
| F5 | Directory-ensuring left duplicated in both consumers in two different idioms | Coupling | Interface segregation | persist.ts:11-15; cache.ts:27-32 |
| F6 | Both consumers freeze the policy at module load; seam has no late binding | Coupling | Coupling surface | persist.ts:8-9; cache.ts:7 |
| F7 | Two call conventions at two callers; no canonical form | Minor | Interface segregation | persist.ts:8-9 vs cache.ts:7 |
| F8 | Policy has no documentation home — dangling README reference, no decision record, stale dir descriptions | Minor | Responsibility boundaries | persist.ts:6-7; docs/decisions/ |
| F9 | Interface cannot express a durability requirement to future consumers | Informational | Extension points | dataDir.ts:12 |

### Overall Assessment

As a refactor, this is well-executed and structurally net-positive: it removes duplicated policy, introduces no cycles or upward dependencies, preserves behavior exactly, and leaves the rule in the most testable shape it has ever had. The findings are not objections to the extraction — they are the consequences of extracting a *deploy-environment* policy specifically, which is a different animal from an ordinary shared helper.

The three structural findings share one root: the module presents an infrastructure capability difference as a path string. F1 is that mismatch at the interface (durability and cross-instance consistency hidden behind a `string`), F2 is that mismatch at the verification boundary (the branch that carries the difference is the one no local gate runs), and F3 is that mismatch at the dependency boundary (capability inferred from a vendor's env var rather than declared as configuration). They are worth addressing together, and F3's fix — reading `APP_DATA_DIR` instead of sniffing `VERCEL` — is the highest-leverage single change, since it simultaneously inverts the dependency, makes the branch locally exercisable, and turns the policy into a documented deployment knob.

The deploy-environment invariant deserves the explicit call-out the brief asks for: an asymmetric branch that only production executes is a standing architectural liability regardless of how small it is. It is one line today, correct today, and covered by nothing — which means the first person to edit it will get no feedback until deploy. The mitigation is disproportionately cheap (a three-case unit test on a pure function), and it is the one recommendation in this review I would not defer.

Nothing here blocks the change. F1/F2/F3 are follow-ups that should be sequenced before the *next* server-side persistence consumer lands, because that consumer is where F9's silent-ephemerality risk turns from projection into incident.

## Goal-Alignment Note
- Answered: All eight briefed structural lenses against the d86d2dc..b64c1ca diff — dependency direction (F3, Dependency Map), responsibility boundaries (F5, F8), module boundary audit (F4), layer violations (F4), interface segregation (F5, F7), substitutability (F1), coupling surface (F6), extension points (F2, F9). The deploy-environment invariant was assessed explicitly as a structural concern (F2, plus the Overall Assessment). All severities reported down to Informational, per the measurement-run brief; no fix loop was run and no files in the worktree were modified.
- Out of scope: Security posture of writing to `/tmp` (no `security-review.md` existed to cross-reference; boundary-label alignment was a no-op). Performance of the cache hit-rate degradation under horizontal scaling — noted only as a consequence of F1, left to the performance critic. Re-verification of anything in the merged fact-check report, including the README reference, the per-instance-isolation gap, and the lint/test claims, all of which were consumed as foundation. Whether analytics *should* be filesystem-backed at all, and running tests or builds (dynamic verification excluded by the historical-review rule).
- Escalate: F1 to the orchestrator — the analytics API's read-your-writes semantics silently became instance-scoped on Vercel, and no caller was changed to account for it; this is the one finding with a user-visible consequence rather than a maintainability cost. Secondary: the fact-check report escalated the per-instance-isolation omission (Claims 3/11) for an architecture-critic look — that request is answered by F1, which concludes the single-warm-instance assumption underlying 2136fd6's "acceptable for single-tenant" argument is real, undocumented, and load-bearing for the analytics panel's correctness.
