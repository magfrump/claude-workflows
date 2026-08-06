# API Consistency Review — fscompat-dirty (d86d2dc..b64c1ca)

**Scope:** `git diff d86d2dc..b64c1ca` — 3 files, +21/−2. New exported helper `dataDir(...subpaths)` in `app/lib/utils/dataDir.ts`; rewires `app/lib/analytics/persist.ts` (`DATA_DIR = dataDir()`) and `app/lib/llm/cache.ts` (`CACHE_DIR = dataDir("cache")`). Commits outside the range are context only.
**Date:** 2026-08-06
**Based on:** merged code fact-check (k=3) at `/workspace/runs/review-arms/e1/fscompat-dirty/code-fact-check-report.md`. Its findings are the foundation and are not re-verified here: the two consumers' call conventions differ; the `persist.ts` comment carries a dangling README reference (Incorrect, 3/3); path equivalence off-Vercel is exact; `dataDir` has no test at this commit.
`Commit: b64c1ca`

---

### Baseline Conventions

Sampled siblings: `app/lib/utils/stripCodeFences.ts`, `app/lib/utils/throttle.ts`, `app/lib/utils/topologicalSort.ts`, `app/lib/utils/leanContext.ts`, plus the two consumers and `verifier/server.ts` (the repo's only other directory-resolution site).

| # | Convention | Evidence |
|---|---|---|
| B1 | **File named after its single primary export**, camelCase, no barrel. | `stripCodeFences.ts` → `stripCodeFences`; `throttle.ts` → `throttle`; `topologicalSort.ts` → `topologicalSort`. No `app/lib/utils/index.ts` exists. |
| B2 | **Exported utils are verb-phrase functions.** | `stripCodeFences`, `stripLeadingCodeFence`, `throttle`, `topologicalSort`, `gatherDependencyContext`. Zero noun-phrase exported functions in `app/lib/utils/` before this diff. |
| B3 | **JSDoc block on every exported util**, stating what it returns and the non-obvious edge case. | `topologicalSort`: "Handles disconnected components and gracefully skips cycle participants." `throttle`: "The last call is always delivered (trailing edge)." |
| B4 | **Module-scope path constants are SCREAMING_SNAKE and composed with `join(...)` at the const site.** | `persist.ts`: `FILE_PATH = join(DATA_DIR, "analytics.jsonl")`. `verifier/server.ts`: `VERIFY_FILE = path.join(LEAN_PROJECT_DIR, "Verify.lean")`. |
| B5 | **Directory resolution takes an explicit env-var override with a computed fallback**, and the override is documented inline. | `verifier/server.ts:13–16`: `// An explicit env var overrides this for alternative deployment layouts.` / `const LEAN_PROJECT_DIR = process.env.LEAN_PROJECT_DIR ?? path.resolve(__dirname, "../../lean-project");` This is the only pre-existing precedent for resolving a writable/working directory in the repo. |
| B6 | **Cross-module imports inside `app/` use the `@/app/lib/...` alias**; intra-directory imports use relative paths. | `persist.ts`: `from "@/app/lib/types/analytics"`. `cache.ts`: `from "./callLlm"`. `tsconfig.json` maps `"@/*": ["./*"]`. |
| B7 | **Colocated `*.test.ts` for utils with branching logic.** | `fileExtraction.test.ts`, `pdfPropositionParser.test.ts`, `textSelection.test.ts`, `workspacePersistence.test.ts` alongside their modules. |

---

### Name-Pattern Audit

New public surface introduced by this diff: one exported function and its parameter.

| New name | Kind | Closest existing neighbors | Neighbor pattern | Verdict |
|---|---|---|---|---|
| `dataDir` (module `dataDir.ts`) | exported function | `stripCodeFences`, `throttle`, `topologicalSort`, `gatherDependencyContext` (`app/lib/utils/`) | verb-phrase function names (B2) | **Diverges** — noun phrase. Reads as a constant/getter, not a call. See F4. |
| `dataDir.ts` (filename) | module | `throttle.ts`, `topologicalSort.ts`, `stripCodeFences.ts` | file named after single export (B1) | **Matches** |
| `...subpaths: string[]` | rest parameter | none — no other exported function in the repo uses rest args (`rg "export function \w+\(\.\.\."` returns only this line) | — | **No precedent in `app/` or `verifier/`.** Novel convention, unstated. See F1. |
| return type `string` | return contract | `topologicalSort(): string[]`, `stripCodeFences(): string`, `gatherDependencyContext(): string` | non-nullable returns, no error channel | **Matches** — total function, never null/throws. |
| `DATA_DIR`, `CACHE_DIR` (rebound, not new) | module consts | `FILE_PATH`, `LEAN_PROJECT_DIR`, `VERIFY_FILE` | SCREAMING_SNAKE (B4) | **Matches** — names preserved from before the diff. |

---

### Findings

#### F1. Two consumers bind to two different call conventions; no convention is established

**Severity:** Inconsistent
**Location:** `app/lib/utils/dataDir.ts:12–15`; `app/lib/analytics/persist.ts:8–9`; `app/lib/llm/cache.ts:7`
**Move:** (3) consumer contracts
**Confidence:** High
**Precedent:** No existing precedent in `app/` or `verifier/` — `rg "export function \w+\(\.\.\."` across the repo returns only `dataDir`. Nothing in the codebase previously offered a variadic path-composer, so there is no house rule to defer to.
**Evidence:**
```ts
// persist.ts
const DATA_DIR = dataDir();
const FILE_PATH = join(DATA_DIR, "analytics.jsonl");
// cache.ts
const CACHE_DIR = dataDir("cache");
```
**Legibility-target:** the next contributor adding a third persistence site, who must guess which of the two shapes is "the" way.

The helper ships with exactly two call sites and they demonstrate opposite conventions: `persist.ts` treats `dataDir()` as a base and composes with `join` at the callsite (matching B4, the established `join(BASE, leaf)` const pattern seen in both `persist.ts` and `verifier/server.ts`), while `cache.ts` pushes composition into the helper via rest args. The `...subpaths` parameter exists to serve a single caller; if `cache.ts` had followed `persist.ts`, the signature could have been the zero-arg `dataDir(): string` and the diff would be smaller. Neither the JSDoc nor the commit message states which shape is preferred, so the rest-args affordance is an unlabeled fork rather than a deliberate convention. Note the asymmetry is not merely stylistic: `dataDir("cache")` and `join(dataDir(), "cache")` are equivalent today, so the split is pure ambiguity with no compensating benefit.

**Recommendation:** Pick one and say so in the JSDoc. The lower-risk pick is to keep rest args and convert `persist.ts` to `const FILE_PATH = dataDir("analytics.jsonl")`, dropping `DATA_DIR`'s separate existence — but `ensureDir()` needs the directory, so the honest version is: keep `DATA_DIR = dataDir()` and change `cache.ts` to `join(dataDir(), "cache")`, then drop `...subpaths` entirely as unused surface. Either way, add one JSDoc line: "Compose subpaths at the callsite with `join`" or "Pass subpaths as arguments."

---

#### F2. The `data/` namespace segment silently disappears on Vercel, un-namespacing analytics into `/tmp` root

**Severity:** Inconsistent
**Location:** `app/lib/utils/dataDir.ts:13`
**Move:** (7) asymmetries
**Confidence:** High
**Evidence:**
```ts
const base = process.env.VERCEL ? "/tmp" : join(process.cwd(), "data");
```
**Legibility-target:** an operator debugging a Vercel function's filesystem, and any future code that also writes to `/tmp`.

Off-Vercel the two consumers resolve to `<cwd>/data/analytics.jsonl` and `<cwd>/data/cache/`; on Vercel they resolve to `/tmp/analytics.jsonl` and `/tmp/cache/`. The `data/` segment that gives the helper its name — and that namespaces this app's files away from everything else — is present in one branch and absent in the other. `cache.ts` is insulated by its own `"cache"` subpath, but `persist.ts` drops `analytics.jsonl` directly into the tmpdir root alongside whatever Next.js, the Node runtime, or a future dependency writes there. This is exactly the kind of branch-dependent shape divergence that B4's uniform `join(BASE, leaf)` pattern exists to prevent, and the function name `dataDir` asserts a `data`-rooted contract that the Vercel branch does not honor.

**Recommendation:** Make the branches structurally parallel: `process.env.VERCEL ? join("/tmp", "data") : join(process.cwd(), "data")`, or hoist the segment — `join(process.env.VERCEL ? "/tmp" : process.cwd(), "data")`. The second makes the invariant ("always a `data` dir, only the root varies") self-evident and shortens the line.

---

#### F3. No env-var override, diverging from the repo's only directory-resolution precedent

**Severity:** Inconsistent
**Location:** `app/lib/utils/dataDir.ts:13`
**Move:** (1) baseline conventions, (7) asymmetries
**Confidence:** Medium-High
**Precedent:** `process.env.<NAME> ?? <computed fallback>` used in `verifier/server.ts:14–16` (`LEAN_PROJECT_DIR`), with the rationale documented inline at `verifier/server.ts:13`.
**Evidence:**
```ts
// verifier/server.ts
// An explicit env var overrides this for alternative deployment layouts.
const LEAN_PROJECT_DIR =
  process.env.LEAN_PROJECT_DIR ??
  path.resolve(__dirname, "../../lean-project");
```
versus
```ts
// dataDir.ts
const base = process.env.VERCEL ? "/tmp" : join(process.cwd(), "data");
```
**Legibility-target:** someone self-hosting on a platform that is neither "Vercel" nor "repo checkout" — a container with a mounted volume, or a read-only-cwd deploy.

The repo already had a pattern for this exact problem and it is the inverse shape: `verifier/server.ts` reads a **naming** env var whose value *is* the directory, with a computed fallback, precisely so alternative deployment layouts need no code change. `dataDir` instead reads a **detection** env var (`VERCEL`, which the platform sets and whose value is unused) and hardcodes both outcomes. The JSDoc's own framing — "In dev and self-hosted deployments we write to the repo's `data/` dir" — asserts a binary world that the `LEAN_PROJECT_DIR` comment explicitly rejects for the sibling subsystem. A third deployment shape requires editing this function rather than setting a variable.

**Recommendation:** Add the escape hatch and keep the detection as fallback: `const base = process.env.DATA_DIR ?? (process.env.VERCEL ? "/tmp/data" : join(process.cwd(), "data"));`. This also makes the function testable (see F8) without stubbing `process.cwd()`.

---

#### F4. `dataDir` is a noun-phrase name in a directory whose exported functions are uniformly verb phrases

**Severity:** Minor
**Location:** `app/lib/utils/dataDir.ts:12`
**Move:** (2) naming vs neighbors
**Confidence:** Medium
**Precedent:** Verb-phrase exported-function naming used in `app/lib/utils/*.ts` — `stripCodeFences`, `stripLeadingCodeFence` (`stripCodeFences.ts`), `throttle` (`throttle.ts`), `topologicalSort` (`topologicalSort.ts`), `gatherDependencyContext` (`leanContext.ts`). No noun-phrase exported function exists in `app/lib/utils/` prior to this diff.
**Evidence:**
```ts
export function dataDir(...subpaths: string[]): string {
```
**Legibility-target:** a reader scanning `const CACHE_DIR = dataDir("cache");` who must decide whether `dataDir` is cheap, pure, and safe to call repeatedly.

Every existing `app/lib/utils/` export names an action (B2), which signals at the callsite that work happens. `dataDir` names a thing, so `dataDir("cache")` reads like an indexed lookup into a constant rather than a call that reads `process.env` and `process.cwd()` on every invocation. The divergence is small in isolation but compounds with F8: a noun-named accessor invites callers to assume a frozen value, which is exactly the assumption both current consumers happen to make and the signature does not guarantee. `resolveDataDir` or `getDataDir` would match B2 and pre-empt that read.

**Recommendation:** Rename to `resolveDataDir` (matches the `path.resolve` mental model and B2). Two call sites and one import line change. If the rename is judged not worth the churn, at minimum add a JSDoc line stating the result is computed per call.

---

#### F5. `persist.ts` gains a Vercel caveat comment that `cache.ts` does not, and it points at a README section that does not exist

**Severity:** Minor
**Location:** `app/lib/analytics/persist.ts:6–7`; absent at `app/lib/llm/cache.ts:7`
**Move:** (7) asymmetries
**Confidence:** High (dangling reference established by fact-check, Incorrect 3/3; asymmetry verified here)
**Evidence:**
```ts
// On Vercel, analytics history doesn't persist across cold starts — see
// Deploy to Vercel in README. See dataDir() for the underlying rationale.
const DATA_DIR = dataDir();
```
**Legibility-target:** a reader of `cache.ts` who needs to know the cache is equally ephemeral on Vercel.

Taking the fact-check's finding as given (no "Deploy to Vercel" section exists in `README.md`), there is a second, independent consistency problem: the two consumers of the same helper are documented asymmetrically. `cache.ts` is subject to the identical cold-start volatility — a `/tmp` LLM cache evaporates exactly as `/tmp/analytics.jsonl` does — yet it receives no comment at all, only the bare `const CACHE_DIR = dataDir("cache");`. Either both consumers carry the caveat or neither does and the JSDoc on `dataDir` is the single source of truth. The current split implies analytics is special when it is not.

**Recommendation:** Delete the pointer sentence from `persist.ts` (or add the README section it names) and let the `dataDir` JSDoc — which already states the cold-start rationale correctly — be the one place the caveat lives. That resolves the dangling reference and the asymmetry in one edit.

---

#### F6. Rest args accept traversal segments; `dataDir("..", "x")` escapes the data directory

**Severity:** Minor
**Location:** `app/lib/utils/dataDir.ts:14`
**Move:** (9) idempotency/safety
**Confidence:** High
**Evidence:**
```ts
return subpaths.length > 0 ? join(base, ...subpaths) : base;
```
Verified: `join("/tmp", "..", "etc")` → `"/etc"`.
**Legibility-target:** any future caller that threads a non-literal into `subpaths` — a cache key, a user-supplied export name, a request parameter.

`join` normalizes `..` rather than rejecting it, so the function's contract "returns a path under the data dir" is only true for literal-argument callers. Both current call sites pass literals, so there is no live exposure at this commit — this is a contract-shape finding, not an exploit report. But the function is a new shared util in `app/lib/utils/` explicitly framed as the writable-directory gateway for "analytics, LLM cache, etc.", so the next caller is likely to pass something computed. The JSDoc makes no statement about what `subpaths` may contain, and there is no sibling precedent to inherit a rule from (see the Name-Pattern Audit).

**Recommendation:** Either document the constraint ("`subpaths` must be literal path segments; traversal is not validated") or enforce it — one line: `if (subpaths.some((s) => s.split(/[\\/]/).includes(".."))) throw new Error(...)`. If F1 is resolved by dropping `...subpaths`, this finding disappears with it.

---

#### F7. The zero-subpath branch is redundant

**Severity:** Informational
**Location:** `app/lib/utils/dataDir.ts:14`
**Move:** (7) asymmetries
**Confidence:** High
**Evidence:**
```ts
return subpaths.length > 0 ? join(base, ...subpaths) : base;
```
Verified: `join("/tmp")` → `"/tmp"`; `join(base, ...[])` is `join(base)` which returns `base` normalized.
**Legibility-target:** a reader trying to work out whether the two branches differ in some subtle way.

`join` with a single argument returns that argument normalized, so `join(base, ...subpaths)` already handles the empty case identically. The ternary adds a branch that suggests the empty case needs different treatment when it does not, and it is the kind of defensive shape that a later reader will preserve out of caution. The one behavioral nuance — `base` is returned unnormalized in the false branch — is moot here because both branch values are themselves already `join`/literal outputs.

**Recommendation:** `return join(base, ...subpaths);`. Two-token change, one fewer branch to test.

---

#### F8. The signature promises per-call resolution; both consumers freeze the value at module load, and nothing tests either reading

**Severity:** Informational
**Location:** `app/lib/utils/dataDir.ts:12–15`; `app/lib/analytics/persist.ts:8`; `app/lib/llm/cache.ts:7`
**Move:** (9) idempotency/safety
**Confidence:** Medium
**Evidence:**
```ts
const DATA_DIR = dataDir();      // persist.ts, module scope
const CACHE_DIR = dataDir("cache"); // cache.ts, module scope
```
**Legibility-target:** a test author who wants to exercise the Vercel branch, and anyone who later calls `dataDir()` from inside a request handler.

Both call sites are module-scope consts, so `process.env.VERCEL` and `process.cwd()` are sampled exactly once per process at import time — the function is effectively a constant in practice. Its signature says otherwise, which means a later caller invoking it inside a handler after a `process.chdir` or env mutation would get a different answer than the module consts hold, and the two would silently disagree. Taking the fact-check's finding that `dataDir` has no test at this commit, neither reading is pinned: no test asserts the off-Vercel path, the Vercel path, or that the two consumers agree. This sits against B7, where `app/lib/utils/` colocates `*.test.ts` for branching utils (`fileExtraction`, `pdfPropositionParser`, `textSelection`, `workspacePersistence`).

**Recommendation:** Add `app/lib/utils/dataDir.test.ts` per B7 covering both env branches and the subpath composition. F3's `DATA_DIR` override makes this testable without stubbing `process.cwd()`. Separately, state the evaluation semantics in the JSDoc ("resolved per call; callers that cache the result at module scope will not observe later env changes").

---

#### F9. `dataDir` is unreachable from `verifier/`, the repo's other filesystem-touching entry point

**Severity:** Informational
**Location:** `app/lib/utils/dataDir.ts`; `verifier/tsconfig.json`
**Move:** (3) consumer contracts
**Confidence:** Medium
**Evidence:** `verifier/tsconfig.json` sets `"rootDir": "."`, `"include": ["server.ts"]`, and defines no `paths` mapping — the `@/*` alias exists only in the root `tsconfig.json` (`"@/*": ["./*"]`).
**Legibility-target:** whoever next needs a writable directory in the verifier service.

The helper is positioned as the app's general answer to "where can I write?", but the verifier compiles as a separate CommonJS project with no path alias and a `rootDir` that excludes `app/`, so it cannot import `dataDir` without either a relative climb out of `rootDir` or a tsconfig change. That is a reasonable boundary, not a defect — but it means the codebase now has two unrelated directory-resolution idioms (F3) with no shared mechanism, and the JSDoc's broad framing ("server-side persistence (analytics, LLM cache, etc.)") does not signal the boundary.

**Recommendation:** Narrow the JSDoc's first line to name the scope — "for Next.js server-side persistence" — so the limit is visible without reading two tsconfigs. No code change.

---

### What Looks Good

- **Import convention followed exactly.** Both consumers use `import { dataDir } from "@/app/lib/utils/dataDir";`, matching B6 and the neighboring `@/app/lib/types/analytics` import already in `persist.ts`.
- **File/export naming matches B1.** `dataDir.ts` exports `dataDir` and nothing else; no barrel file was introduced, consistent with the directory's flat, no-`index.ts` layout.
- **JSDoc matches B3's shape and depth.** It states the return, the platform constraint, and — like `topologicalSort`'s cycle note — the non-obvious consequence ("persistence does not survive cold starts") rather than restating the signature.
- **Existing const names preserved.** `DATA_DIR` and `CACHE_DIR` keep their identifiers and SCREAMING_SNAKE form (B4), so the refactor is invisible to anything reading those consts and the diff stays reviewable at 2 changed lines per consumer.
- **Off-Vercel path equivalence is exact** (per fact-check): `dataDir()` reproduces `join(process.cwd(), "data")` and `dataDir("cache")` reproduces `join(process.cwd(), "data", "cache")`. The refactor is a true no-op on the default path, which is the right property for a change of this shape.
- **Total function, no error channel.** Returns `string` unconditionally — never `null`, never throws — matching the nullability posture of every other `app/lib/utils/` export (`stripCodeFences`, `topologicalSort`, `gatherDependencyContext`). Move (8) surfaces nothing.
- **Error handling in consumers untouched.** `persist.ts`'s corrupt-line skip and `cache.ts`'s `dirEnsured` latch are unchanged; the refactor did not perturb error semantics. Move (4) surfaces nothing.

---

### Summary Table

| ID | Finding | Severity | Move | Confidence |
|---|---|---|---|---|
| F1 | Two consumers, two call conventions; `...subpaths` serves one caller | Inconsistent | 3 consumer contracts | High |
| F2 | `data/` segment absent on Vercel; `analytics.jsonl` lands in `/tmp` root | Inconsistent | 7 asymmetries | High |
| F3 | No env override; diverges from `LEAN_PROJECT_DIR` precedent | Inconsistent | 1 baseline, 7 asymmetries | Medium-High |
| F4 | `dataDir` noun-phrase vs verb-phrase sibling exports | Minor | 2 naming | Medium |
| F5 | Vercel caveat on `persist.ts` only, and it dangles at a missing README section | Minor | 7 asymmetries | High |
| F6 | `...subpaths` accepts `..`; escapes the data dir | Minor | 9 safety | High |
| F7 | Zero-subpath ternary branch is redundant | Informational | 7 asymmetries | High |
| F8 | Per-call signature vs module-load consumption; no test pins either branch | Informational | 9 idempotency | Medium |
| F9 | Unreachable from `verifier/`; JSDoc scope overstated | Informational | 3 consumer contracts | Medium |

Totals: 0 Breaking · 3 Inconsistent · 3 Minor · 3 Informational.

---

### Overall Assessment

The extraction is correct and well-mannered where it touches existing surface: names preserved, import alias correct, JSDoc in house style, off-Vercel behavior provably identical. Nothing here breaks a consumer — there are no Breaking findings, and both call sites are internal to this repo.

The consistency problems are concentrated in the *new* surface, and they share one root: the signature was widened to `...subpaths` for a single caller without a stated rule, and then the two callers immediately demonstrated opposite usages (F1). That is the finding to fix first, because F6 and F7 are downstream of the rest-args decision and both vanish if the parameter is dropped. F2 is independent and the most consequential in operation — the helper's name promises a `data`-rooted path that the Vercel branch does not deliver, and analytics files land unnamespaced in a shared tmpdir. F3 is the one place the diff had a house precedent available (`verifier/server.ts`) and chose a different shape without saying why.

Suggested order: F2 (one-line, removes an operational asymmetry), F1 (settles the convention; subsumes F6/F7), F5 (deletes a known-dangling reference), then F3/F8 together (the override makes the test writable), leaving F4 and F9 as documentation-grade cleanup.

---

## Goal-Alignment Note

- **Answered:** Whether `dataDir`'s new public surface matches `app/lib/utils/` conventions (B1–B3, B6–B7) and the repo's one prior directory-resolution precedent (B5, `verifier/server.ts`); whether the two consumers' divergent call conventions (`dataDir("cache")` vs `join(dataDir(), ...)`) reflect a deliberate convention — they do not, and no precedent exists to settle it; error consistency, nullability, and idempotency/safety of the new function and both rewired consumers; the asymmetric documentation between the two consumers and the asymmetric path shape between the two env branches.
- **Out of scope:** Correctness of the off-Vercel path equivalence and the dangling README reference (both taken as established by the merged k=3 fact-check and not re-verified). Whether `/tmp` is the right Vercel target at all, and whether analytics/cache *should* persist on Vercel — product and infrastructure decisions, not interface consistency. Performance of per-call `process.cwd()`. Security review of the traversal surface in F6 beyond its contract-shape implications — flagged for `security-reviewer` if that arm runs. Commit `2136fd6`, which introduced the `/tmp` redirect inline, is inside the range but its content is fully superseded by `b64c1ca`; reviewed as the diff's net effect only.
- **Escalate:** F2 needs a human call — whether `analytics.jsonl` landing at `/tmp/analytics.jsonl` rather than `/tmp/data/analytics.jsonl` was intentional (e.g., to keep the Vercel path short) or an oversight; the fix is one line either way, but the intent determines whether it is a fix. F1 needs an owner decision on which call convention is canonical before a third persistence site is added — this review can identify the fork but not pick the winner. This is a measurement run with no fix loop, so no changes were applied.
