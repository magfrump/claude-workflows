# Architecture Review — fscompat-clean (d86d2dc..2cd3b67)

**Scope:** `git diff d86d2dc..2cd3b67` — 4 files, +54/-2. New leaf module `app/lib/utils/dataDir.ts` plus its test, and conversion of two persistence consumers (`app/lib/analytics/persist.ts`, `app/lib/llm/cache.ts`) from inline `join(process.cwd(), "data")` to the shared resolver.
**Date:** 2026-08-06
**Based on:** merged code fact-check (k=3, 0 Incorrect) at `/workspace/runs/review-arms/e1/fscompat-clean/code-fact-check-report.md`. Documented behavior from that report is treated as established and not re-verified here.
`Commit: 2cd3b67`

Structural integrity only. No security, performance, or implementation-quality findings except where they follow from a structural cause. A companion `security-review.md` was not present at write time, so no boundary labels are cross-referenced.

---

### Dependency Map

```
app/api/analytics/route.ts ────────────┐
app/lib/llm/callLlm.ts ────────────────┤
app/lib/llm/streamLlm.ts ──────────────┼──> app/lib/analytics/persist.ts ──┐
                                       │      (const DATA_DIR = dataDir())  │
app/lib/llm/callLlm.ts ────────────────┤                                    │
app/lib/llm/streamLlm.ts ──────────────┼──> app/lib/llm/cache.ts ───────────┼──> app/lib/utils/dataDir.ts
app/lib/formalization/artifactRoute.ts ┘      (const CACHE_DIR =            │      (leaf; imports only `path`)
                                               join(dataDir(), "cache"))    │            │
                                                                            │            ├─> process.env.VERCEL
                                                                            │            └─> process.cwd()
app/lib/utils/dataDir.test.ts ──────────────────────────────────────────────┘
```

**Direction.** Clean and acyclic. `dataDir.ts` is a true leaf — its only import is node's `path`, it imports nothing from `analytics/`, `llm/`, `formalization/`, or `types/`, and nothing imports it except the two persistence modules and its own test. The change strictly *reduces* fan-out on the ambient environment: `rg` across the tree (excluding `node_modules`) returns exactly one `process.env.VERCEL` hit and exactly one non-test `process.cwd()` hit, both inside `dataDir.ts`. Before this change the `data/` path literal was duplicated across the two consumers; after, it exists once.

**Layering.** `app/api/*` (route) → `app/lib/{analytics,llm}` (domain/persistence) → `app/lib/utils` (leaf). No upward or lateral dependencies were introduced. The layer problem in this diff is not a direction violation; it is that a semantic distinction created at the leaf (Finding A) is not representable in the type that crosses the layers above it.

**Binding surface.** Consumers bind to `dataDir()` by value at module-evaluation time, not by reference: `const DATA_DIR = dataDir()` and `const CACHE_DIR = join(dataDir(), "cache")` are both module-level constants. This is the source of Findings B and D.

---

### Findings

#### A. `string` return type erases the durability and consistency difference the module exists to create

**Severity:** Structural
**Location:** `app/lib/utils/dataDir.ts:14-16`; consumed at `app/lib/analytics/persist.ts:7`, `app/lib/llm/cache.ts:7`; surfaced at `app/api/analytics/route.ts:5-8`
**Move:** Substitutability (Liskov) — do the two return values honor the same contract from the caller's point of view?
**Confidence:** High
**Evidence:**

```ts
export function dataDir(): string {
  return process.env.VERCEL ? "/tmp" : join(process.cwd(), "data");
}
```

and the docstring that states the difference the type does not:

```
 * On Vercel Functions only `/tmp` is writable. `/tmp` lives only as long as
 * a warm container, so persistence does not survive cold starts; it is also
 * per-instance, so concurrent Function instances each see their own
 * independent contents (no cross-instance sharing). In dev and self-hosted
 * deployments we write to the repo's `data/` dir for durable cross-restart
 * storage.
```

**Legibility-target:** the author of `app/api/analytics/route.ts`, who calls `readAnalyticsEntries()` and must decide whether the result is the analytics record or a fragment of it.

The two branches return the same type but not the same thing: one is a durable, single, process-shared store; the other is ephemeral, per-instance, and unshared. Because both are `string`, no consumer can branch on the difference, and the difference is invisible at every call site — `GET /api/analytics` returns whatever slice of history the Function instance that happened to serve the request holds, and `DELETE` clears that one instance's slice while leaving the others intact, with no indication in either response that this is a partial view. The docstring in `dataDir.ts` and the new caveat comment in `persist.ts` are the only carriers of this fact, and neither travels with the value; a consumer three modules away sees a path and reasonably assumes filesystem semantics. This is the diff's central structural cost, and it is a cost the extraction *created leverage over* rather than introduced — the pre-change inline `join(process.cwd(), "data")` had the same problem with no single place to fix it.

**Recommendation:** Make the distinction representable rather than documented. Either widen the return to a small record — `{ path: string; durable: boolean; scope: "shared" | "per-instance" }` — or, cheaper and non-breaking for the two existing consumers, add a sibling export `isEphemeralStorage(): boolean` from the same module so the analytics route can attach a `partial: true` / `ephemeral: true` field to its JSON response. The second option keeps the zero-arg `dataDir()` the review process already converged on and costs one exported predicate.

---

#### B. No override hatch: the policy is a compiled-in branch, not configuration

**Severity:** Coupling
**Location:** `app/lib/utils/dataDir.ts:15`
**Move:** Extension points — can a new deployment target be accommodated without editing this module?
**Confidence:** High
**Evidence:**

```ts
  return process.env.VERCEL ? "/tmp" : join(process.cwd(), "data");
```

**Legibility-target:** an operator self-hosting the app, who has no documented or discoverable way to point persistence anywhere.

The resolver reads exactly one environment variable and it is not one an operator would set deliberately — `VERCEL` is injected by the platform. There is no `DATA_DIR` or `APP_DATA_DIR` override, so a self-hosted deployment on a read-only application filesystem, a container that wants a mounted volume, or a CI run that wants an isolated scratch directory has no configuration point at all; the only recourse is editing this function and its test. The zero-arg signature (rest-args deliberately dropped per the review that produced this commit) is the right *call-site* shape, but it left the module with neither a parameter seam nor an env seam, so the extension surface went to zero rather than moving. This is the one place in the diff where the review's simplification traded away something with no replacement.

**Recommendation:** Add an explicit override as the first branch — `process.env.DATA_DIR ?? (process.env.VERCEL ? "/tmp" : join(process.cwd(), "data"))` — and extend `dataDir.test.ts` with a case pinning that the override wins over the Vercel branch. This restores an extension point without reopening the argument-passing question the review closed, and the resulting configuration is legible to operators rather than to callers.

---

#### C. Consumers are structurally untestable against the branch the new test pins

**Severity:** Coupling
**Location:** `app/lib/analytics/persist.ts:8-9`; `app/lib/llm/cache.ts:7`; test coverage boundary at `app/lib/utils/dataDir.test.ts`
**Move:** Coupling surface — hidden ambient dependency captured at module-evaluation time
**Confidence:** High
**Evidence:**

```ts
const DATA_DIR = dataDir();
const FILE_PATH = join(DATA_DIR, "analytics.jsonl");
```

**Legibility-target:** whoever next writes the first test for `persist.ts` and discovers the directory cannot be redirected.

`dataDir()` is evaluated once, at import, and frozen into a module constant in both consumers. The new `dataDir.test.ts` works precisely because it calls the function directly and stubs env *per call*; that technique does not transfer to the consumers, where the env is read before any test body runs. The practical consequence is that `app/lib/analytics/persist.ts` has no test file at all (the directory contains only `persist.ts`) and cannot cheaply acquire one — an honest test would write real files into the developer's checked-out `data/` directory, so the only route is `vi.mock`ing the whole module, which is what `streamLlm.test.ts:11-13` already does. So the new test closes the "did someone delete or invert the Vercel branch" risk at the resolver, but it closes nothing about whether the consumers still *use* the resolver correctly; that remains type-checked only.

**Recommendation:** Treat this as accepted-with-a-note rather than a rewrite. The minimal structural fix is to defer the capture — make `FILE_PATH`/`CACHE_DIR` small functions (`const filePath = () => join(dataDir(), "analytics.jsonl")`) instead of module constants, which makes both consumers env-stubbable with the same `vi.stubEnv` technique the new test already uses, at the cost of two extra calls per operation. If that isn't worth it, record in the module docstring that the path is import-time-frozen so the next test author doesn't spend the discovery.

---

#### D. Vendor detection where a capability question belongs

**Severity:** Minor
**Location:** `app/lib/utils/dataDir.ts:15`
**Move:** Responsibility boundaries — is this module deciding the right question?
**Confidence:** Medium
**Evidence:**

```ts
  return process.env.VERCEL ? "/tmp" : join(process.cwd(), "data");
```

**Legibility-target:** a future reader adding a second serverless target, who must recognize that "is this Vercel" was always a proxy for "is the application filesystem writable".

The module names itself after storage (`dataDir`) but branches on hosting vendor. Those coincide today and the containment is genuinely good — one `process.env.VERCEL` reference in the entire tree — but the abstraction is one level below where it should sit, so adding AWS Lambda, Cloud Run, or Netlify means editing the conditional and the test rather than setting a variable. Combined with Finding B (no override), every new target is a code change. This is low-urgency: at one vendor, a boolean is the correct amount of machinery, and inverting to a capability model before the second target arrives would be speculative.

**Recommendation:** Leave the implementation; adjust the docstring's first line to state the question being answered ("is the application filesystem writable") rather than only the answer. If Finding B's `DATA_DIR` override lands, this finding largely dissolves — an operator on a new ephemeral platform sets `DATA_DIR=/tmp` and the vendor check never needs to grow.

---

#### E. The "unset" test case pins a falsy value, not absence

**Severity:** Minor
**Location:** `app/lib/utils/dataDir.test.ts:28-31`
**Move:** Substitutability — does the test constrain the contract or the current implementation?
**Confidence:** High
**Evidence:**

```ts
  it("returns <cwd>/data when VERCEL is unset", () => {
    vi.stubEnv("VERCEL", "");
    expect(dataDir()).toBe(join(originalCwd, "data"));
  });
```

**Legibility-target:** the next person to harden the check, who will read this test as covering absence and be wrong.

The test name says "unset" but the stub sets an empty string. Under the current truthiness check the two are equivalent, so the test passes and is not wrong today. It becomes wrong the moment someone switches to a presence check — `"VERCEL" in process.env` or `!== undefined`, both plausible hardenings since Vercel always sets the variable — at which point local dev silently starts resolving to `/tmp` while this test continues to pass green. The merged fact-check flagged the same divergence. Since the stated purpose of this file is to pin an invariant that "lint/types/build" cannot catch, a case that can't catch the specific regression it names undercuts that purpose.

**Recommendation:** Change to `vi.stubEnv("VERCEL", undefined)` (vitest deletes the key for `undefined`) and keep the existing empty-string case as a separately named test, e.g. `"treats empty VERCEL as non-Vercel"`. Two lines, and the file then pins absence and falsiness independently.

---

#### F. Server-only module placed in a directory that is a client import surface

**Severity:** Minor
**Location:** `app/lib/utils/dataDir.ts` (placement)
**Move:** Module boundary audit — does the directory still carry a uniform contract?
**Confidence:** Medium
**Evidence:** `app/lib/utils/` is imported by 15+ `"use client"` modules, e.g. `app/components/features/source-input/FileUpload.tsx:5`:

```ts
import { extractTextFromFile } from "@/app/lib/utils/fileExtraction";
```

**Legibility-target:** anyone adding a `utils/index.ts` barrel, or importing from `utils/` inside a client component, who currently has no signal that some files there are node-only.

Before this diff every file in `app/lib/utils/` was environment-agnostic or browser-oriented — `throttle`, `textSelection`, `stripCodeFences`, `exportGraph`, `mergeStreamingPreview` — and client components import from it freely across panels, hooks, and `page.tsx`. `dataDir.ts` is node-only: it touches `process.cwd()` and `process.env`. Nothing breaks today because imports are per-file and no barrel exists, so the browser bundle never reaches it. The cost is that the directory stops being a reliable boundary signal: a later barrel file, or a client component that reasonably assumes anything in `utils/` is safe, pulls `process.cwd()` toward the bundle. Note that `vitest.config.ts` sets `environment: 'jsdom'` globally, so the new test runs a node-only module under a browser-ish environment — it passes, but it's the same category confusion.

**Recommendation:** Move to `app/lib/server/dataDir.ts`, or keep the location and add `import "server-only";` at the top of the file so the mistake fails at build time rather than at runtime in a browser. The `server-only` package ships with Next.js; one line.

---

#### G. The "all persistence goes through `dataDir()`" convention has no enforcement

**Severity:** Informational
**Location:** repo-wide; convention established at `app/lib/analytics/persist.ts:7` and `app/lib/llm/cache.ts:7`
**Move:** Coupling surface — is the invariant load-bearing or advisory?
**Confidence:** High
**Evidence:** the two consumers now uniformly do

```ts
const CACHE_DIR = join(dataDir(), "cache");
```

and a tree-wide `rg` for `process.cwd()` outside tests returns only `dataDir.ts:15`.

The convention is currently perfect — n=2 consumers, zero stragglers — but it holds by discipline alone. Nothing stops a third persistence module from writing `join(process.cwd(), "data", ...)` directly, and because that works fine in local dev and fails only on Vercel, the failure mode is exactly the asymmetric, invisible one the new test was written to guard against at the resolver. The fact-check correctly notes the convention claim rests on n≈2, which is a thin base for calling it a convention at all.

**Recommendation:** Optional, and cheap if wanted: an ESLint `no-restricted-syntax` or `no-restricted-properties` rule banning `process.cwd()` outside `app/lib/utils/dataDir.ts`. At n=2 this is arguably premature; revisit when a third persistence site appears.

---

#### H. Cache-hit-collapse deferral is structurally well-founded

**Severity:** Informational
**Location:** `app/lib/llm/cache.ts` public surface; verified against `app/lib/llm/streamLlm.test.ts:5-9`
**Move:** Interface segregation — is the deferred work actually isolated behind a seam?
**Confidence:** High
**Evidence:** every consumer binds only to the exported function surface, as the existing test demonstrates by replacing the module wholesale:

```ts
vi.mock("./cache", () => ({
  computeHash: vi.fn(() => "testhash"),
  getCachedResult: vi.fn(() => null),
  setCachedResult: vi.fn(),
}));
```

The author's note deferring cache-hit-collapse on the grounds that the cache is abstracted behind a seam holds up structurally. `CACHE_DIR` is module-private, no consumer constructs a cache file path, and `callLlm.ts`, `streamLlm.ts`, and `artifactRoute.ts` reach the cache only through `computeHash`/`getCachedResult`/`setCachedResult`/`removeCachedResult`. A later migration to Vercel KV, Blob, or Redis is a single-module rewrite with no caller changes — which is the condition that makes deferral a real deferral rather than an accumulation. Recorded here to confirm the premise, not to dispute the decision.

**Recommendation:** None. When the migration happens, `computeHash` is the one export whose name leaks the current implementation's shape (content-addressed files); consider renaming it then, not now.

---

### What Looks Good

- **The extraction itself is the right structural move.** One duplicated path literal became one leaf module with a single reason to change. Dependency direction is clean and acyclic, the module imports only `path`, and ambient-environment fan-out across the whole tree dropped to a single `process.env.VERCEL` reference and a single non-test `process.cwd()` reference — both inside the new module. That is textbook containment of a cross-cutting concern.
- **The test earns its keep on the specific risk it names.** The comment at `dataDir.test.ts:5-7` correctly identifies why this invariant needed a test rather than a type: the Vercel branch is invisible in local dev, so lint, types, and build all pass on a refactor that deletes or inverts it. Pinning both branches closes the "silent branch deletion" class outright. What it does not close — consumer usage (Finding C) and true absence semantics (Finding E) — is narrower than what it does close.
- **Consumers adopted a uniform convention rather than each inventing one.** `dataDir()` at the top, subpaths composed with `join` beneath it, in both modules. The `cache.ts` form `join(dataDir(), "cache")` composes cleanly and keeps the subdirectory decision local to the cache, which is where it belongs.
- **The per-instance caveat is documented at both altitudes.** The full rationale lives in the `dataDir()` docstring and a one-line pointer sits at `persist.ts:6-8` where a reader of the analytics module will actually encounter it. Prose is a weaker carrier than a type (Finding A), but the placement shows the right instinct about who needs to know.
- **Deferring cache-hit-collapse was defensible, and verifiably so.** See Finding H — the seam the deferral rests on is real, not asserted.

---

### Summary Table

| ID | Finding | Severity | Location | Blocking? |
|----|---------|----------|----------|-----------|
| A | `string` return erases durability/consistency difference between `/tmp` and `<cwd>/data`; API route serves a partial view unlabeled | Structural | `dataDir.ts:14-16`, `api/analytics/route.ts` | No — measurement run |
| B | No `DATA_DIR` override; policy is a compiled-in branch with zero extension surface | Coupling | `dataDir.ts:15` | No |
| C | Consumers capture the path at import time; `persist.ts` untested and not cheaply testable | Coupling | `persist.ts:8-9`, `cache.ts:7` | No |
| D | Branches on vendor (`VERCEL`) where the real question is filesystem writability | Minor | `dataDir.ts:15` | No |
| E | "Unset" test case stubs `""`, not absence — passes through a presence-check hardening | Minor | `dataDir.test.ts:28-31` | No |
| F | Node-only module placed in `utils/`, a directory 15+ client components import from | Minor | `dataDir.ts` placement | No |
| G | "All persistence via `dataDir()`" convention has no lint enforcement (n=2) | Informational | repo-wide | No |
| H | Cache-hit-collapse deferral rests on a verified seam — premise confirmed | Informational | `llm/cache.ts` surface | No |

---

### Overall Assessment

Structurally this diff is a net improvement and should not be blocked. It takes a duplicated environment-dependent path literal and gives it one home, one reason to change, and — new in this commit — a test that pins the branch local development cannot exercise. Dependency direction is clean, the module is a genuine leaf, and the tree-wide ambient-environment surface shrank rather than grew.

The residual risk is concentrated in one place and it is a *type* problem, not a *structure* problem. `dataDir(): string` presents two values with materially different durability and consistency guarantees as interchangeable, and the layers above it are consequently unable to see or react to the difference — most visibly at `GET /api/analytics`, which returns one Function instance's fragment of history as though it were the whole. The new test does not touch this; it pins which string comes back, not what the string means. Finding A is where the remaining leverage is, and the cheap version of it — an exported `isEphemeralStorage()` predicate the route can use to label its response — costs a few lines and does not disturb the zero-arg signature the review process converged on.

Findings B and C are the shape of what the simplification traded away: dropping rest-args produced a clean call site but left no parameter seam and no env seam, which is why there is no operator override and why `persist.ts` has no test. Adding a `DATA_DIR` env override addresses B directly and softens D as a side effect. E and F are two-line corrections. G is genuinely optional at n=2.

Nothing here compounds if left alone for a release; nothing here is a boundary the codebase will have to unwind. The one item worth doing before this pattern is copied to a third persistence site is A, because every additional consumer inherits the erased distinction, and the further from `dataDir.ts` a consumer sits, the less likely its author is to have read the docstring that carries it.

---

## Goal-Alignment Note

- **Answered:** Dependency direction (clean, acyclic, leaf module, fan-out reduced to one env reference tree-wide); responsibility boundaries (D — vendor detection standing in for a filesystem-capability question); module boundary audit (F — node-only module in a client-imported directory; G — convention unenforced at n=2); layer violations (none in direction; A is a semantic leak past the layers rather than a dependency violation); interface segregation (H — cache seam verified real via the existing `vi.mock` in `streamLlm.test.ts`); substitutability (A — the `string` return does still hide the durability and consistency difference from consumers, and the analytics route is where that becomes user-visible); coupling surface (B, C — no override hatch, import-time capture blocking consumer tests); extension points (B, D). On what the new test closes versus what remains: it closes silent deletion or inversion of the Vercel branch, the one failure mode invisible to lint, types, and build; it does not close consumer-side usage (C), true-absence semantics (E), vendor sniffing (D), the missing override (B), or consumer awareness of instance-scoping (A).
- **Out of scope:** Security posture of writing to `/tmp` on shared infrastructure, cache-poisoning and path-construction concerns, and the trust boundary around `process.env` — deferred to `security-review.md`, which did not exist at write time, so no boundary labels are cross-referenced here. Performance of module-level `existsSync`/`mkdir` calls and the `dirEnsured` memo, cost of cache misses after cold start, and the cache-hit-collapse behavior itself (structural premise assessed in H; the behavioral question is not architectural). Implementation quality inside unchanged function bodies. Test *coverage* breadth as a quality metric — only the structural risk the new test closes is assessed, per brief. No fix loop was run; this is a pass-1 measurement report and all severities are reported as found.
- **Escalate:** Finding A to whoever owns the analytics surface — `GET /api/analytics` and `DELETE /api/analytics` behave differently on Vercel than the response shape implies (partial read, partial clear, no indication of either), and that is a product-visible behavior question, not purely a code-structure one. Finding B to whoever owns deployment — if self-hosting on a read-only or volume-mounted filesystem is a supported target, the absence of a `DATA_DIR` override is a gap now rather than later.
