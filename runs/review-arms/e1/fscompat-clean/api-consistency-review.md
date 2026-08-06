# API Consistency Review — fscompat-clean (d86d2dc..2cd3b67)

**Scope:** `git diff d86d2dc..2cd3b67` — 4 files, +54/−2: new `app/lib/utils/dataDir.ts` (exports `dataDir()`), new `app/lib/utils/dataDir.test.ts`, and rewiring of the two existing consumers `app/lib/analytics/persist.ts` and `app/lib/llm/cache.ts`. Commits `2136fd6` and `b64c1ca` are inside the range; `d86d2dc` and earlier are context only.
**Date:** 2026-08-06
**Based on:** merged code fact-check (k=3, 0 Incorrect). Foundation accepted without re-verification: call conventions are now uniform (`join(dataDir(), …)` in both consumers), the two path forms are equivalent to the pre-extraction literals, both branches are pinned by the new test, and no dangling doc references remain after the README ref was dropped. The fact-check's two caveats — that the test titled "when VERCEL is unset" actually stubs `VERCEL=""`, and that the "codebase convention" claim rests on n≈2 — are carried into findings below rather than re-litigated.
**Commit:** 2cd3b67

---

### Baseline Conventions

Sampled siblings: `app/lib/utils/textSelection.ts`, `app/lib/utils/exportGraph.ts`, `app/lib/utils/export.ts`, `app/lib/utils/workspacePersistence.ts`, `app/lib/llm/cache.ts`, `verifier/server.ts`, `app/api/verification/lean/route.ts`.

1. **`app/lib/utils/` helper shape.** One concern per file, filename in camelCase matching the primary export, plain `export function` (no default export, no barrel/index re-export), explicit return type annotation. 46 exported symbols across the directory; every consumer imports the named function directly by path.
2. **Verb-first function naming.** Exported functions in `app/lib/utils/` are overwhelmingly verb-led: `getSelectionCoordinates`, `getGraphViewportElement`, `triggerDownload`, `sanitizeFilename`, `extractTextFromFile`, `loadWorkspace`, `saveWorkspace`, `gatherDependencyContext`, `stripCodeFences`, `mergeStreamingPreview`, `parseLatexPropositions`. Predicates use `is*` (`isBoldFont`, `isLatexStructured`). The only non-verb exports are `throttle` and `topologicalSort` — both established terms of art naming an operation, not a value.
3. **Module-scope const for resolved paths and config.** `const PORT = …`, `const LEAN_PROJECT_DIR = …`, `const VERIFY_FILE = path.join(LEAN_PROJECT_DIR, "Verify.lean")` (`verifier/server.ts:9–17`), `const LEAN_VERIFIER_URL = …` (`app/api/verification/lean/route.ts:4`), `const CACHE_DIR`/`const DATA_DIR`/`const FILE_PATH` in the two consumers. Resolution happens once at import; derived paths are built with `join`/`path.join` on the base const.
4. **Env-var handling: `??` with an explicit override.** All four pre-existing server-side env reads use nullish coalescing against a default: `process.env.PORT ?? 3100`, `process.env.LEAN_PROJECT_DIR ?? path.resolve(…)`, `process.env.LEAN_VERIFIER_URL ?? "http://localhost:3100"`. `verifier/server.ts:12–16` is the closest precedent to this diff — a path derived by heuristic, with a documented env override "for alternative deployment layouts". API keys (`streamLlm.ts:87–88`, `callLlm.ts:112–113`) are read bare and validated downstream.
5. **Test placement and naming.** Unit tests sit beside their subject (`textSelection.test.ts`, `fileExtraction.test.ts`, `workspacePersistence.test.ts`, `pdfPropositionParser.test.ts`); `describe()` takes the exported symbol name; `it()` titles state the literal input condition ("returns null when no text is selected (cursor only)"). Env manipulation in tests has one precedent: `delete process.env.ANTHROPIC_API_KEY` (`app/lib/llm/streamLlm.test.ts:21–22`). `vitest.config.ts` sets a single global `jsdom` environment with no per-file overrides.

Caveat on strength: conventions 3 and 4 rest on a small sample (four env reads, three of them in two files). Findings that lean on them are scored accordingly.

---

### Name-Pattern Audit

| New public name | Kind | Closest existing neighbors | Neighbor pattern | Verdict |
|---|---|---|---|---|
| `dataDir()` | exported function | `getGraphViewportElement()` (`app/lib/utils/exportGraph.ts:10`), `getSelectionCoordinates()` (`app/lib/utils/textSelection.ts:1`), `getCachedResult()` (`app/lib/llm/cache.ts:33`) | verb-first accessor, `get*` for "return a resolved value" | **Deviates** — bare noun phrase; reads as a value, not a call. See F3. |
| `app/lib/utils/dataDir.ts` | module path | `stripCodeFences.ts`, `topologicalSort.ts`, `leanContext.ts` | camelCase filename == primary export, flat in `app/lib/utils/` | Matches |
| `app/lib/utils/dataDir.test.ts` | test module | `textSelection.test.ts`, `fileExtraction.test.ts` | `<subject>.test.ts` colocated with subject | Matches |
| `describe("dataDir")` | test group | `describe("computeCost")`, `describe('getSelectionCoordinates')` | group named for the exported symbol | Matches |
| `DATA_DIR` (`persist.ts:8`) | module const, re-pointed | `LEAN_PROJECT_DIR`, `CACHE_DIR`, `VERIFY_FILE` | SCREAMING_SNAKE module-scope path const | Matches (unchanged name, new source) |
| `CACHE_DIR` (`cache.ts:7`) | module const, re-pointed | as above | as above | Matches (unchanged name, new source) |

No new types, config fields, HTTP surfaces, CLI flags, or event payloads in this range. `dataDir()` is the single new public name.

---

### Findings

#### F1 — `/tmp` branch drops the `data/` namespace segment, so the two branches are not structurally parallel

**Severity:** Inconsistent
**Location:** `app/lib/utils/dataDir.ts:15`; effects at `app/lib/analytics/persist.ts:8–9` and `app/lib/llm/cache.ts:7`
**Move:** (7) asymmetries
**Confidence:** High — the asymmetry is visible in the one-line body; the judgment that it matters is Medium.
**Evidence:**

```ts
return process.env.VERCEL ? "/tmp" : join(process.cwd(), "data");
```

**Legibility-target:** the next person debugging a Vercel-only file collision, and anyone auditing what this app writes into the Function sandbox.

The local branch returns a private, app-owned subdirectory; the Vercel branch returns the runtime's shared scratch root itself. The resulting layouts are not isomorphic: locally the app owns `<cwd>/data/analytics.jsonl` and `<cwd>/data/cache/`, but on Vercel it writes `/tmp/analytics.jsonl` and `/tmp/cache/` directly into a namespace it shares with Next.js, the Node runtime, and any dependency that scratches to `/tmp`. Baseline convention 3 shows the codebase otherwise derives paths by `join`-ing onto a base it controls (`VERIFY_FILE` under `LEAN_PROJECT_DIR`), and the local branch of this very function follows that shape — only the Vercel branch does not. The blast radius is concrete rather than theoretical: `clearAnalyticsEntries()` truncates `/tmp/analytics.jsonl`, and `cache.ts` calls `unlink` on paths under `/tmp/cache/`, so a name collision means this code deletes or overwrites something it does not own. The fix costs one `join` and preserves every path relationship the local branch already has.

**Recommendation:** `return process.env.VERCEL ? join("/tmp", "data") : join(process.cwd(), "data");` — then both branches end in an app-owned `data` segment and the only difference is the root. Update `dataDir.test.ts:21` and `:26` to expect `/tmp/data`.

---

#### F2 — No explicit env override, diverging from the `LEAN_PROJECT_DIR` precedent for exactly this problem

**Severity:** Inconsistent
**Location:** `app/lib/utils/dataDir.ts:14–16`
**Move:** (1) baseline conventions — env-var handling
**Confidence:** Medium — the precedent is clear but n=1 for the path-resolution case (n=3 counting `PORT` and `LEAN_VERIFIER_URL` as the general `??`-override shape).
**Precedent:** `process.env.<VAR> ?? <derived default>` used in `verifier/server.ts:9,14-16` and `app/api/verification/lean/route.ts:4`.
**Evidence:** from `verifier/server.ts:12–16`:

```ts
// An explicit env var overrides this for alternative deployment layouts.
const LEAN_PROJECT_DIR =
  process.env.LEAN_PROJECT_DIR ??
  path.resolve(__dirname, "../../lean-project");
```

**Legibility-target:** a self-hoster or Docker operator whose working directory is read-only or whose data volume is mounted elsewhere.

`dataDir()` is the codebase's second helper that resolves a writable directory by inference, and the first one already established the answer: infer a sensible default, but let an env var override it, and say so in a comment. This diff offers only binary platform auto-detection — Vercel or `<cwd>/data`, with no third option. That matters because `docker-compose.yml` is present in the repo and the docstring explicitly claims to serve "self-hosted deployments", which are precisely the "alternative deployment layouts" the `LEAN_PROJECT_DIR` comment was written for. Adding the override is one `??` and keeps the existing two-branch behavior as the default, so it costs nothing for Vercel or dev.

**Recommendation:** `return process.env.DATA_DIR ?? (process.env.VERCEL ? join("/tmp", "data") : join(process.cwd(), "data"));`, with a comment mirroring `verifier/server.ts:12–14`, plus a test case pinning that `DATA_DIR` wins over `VERCEL`.

---

#### F3 — `dataDir()` is a bare noun where every sibling accessor is verb-first

**Severity:** Minor
**Location:** `app/lib/utils/dataDir.ts:14`
**Move:** (2) naming vs neighbors
**Confidence:** High — the naming pattern across the directory is near-uniform.
**Precedent:** `get<Noun>()` for "resolve and return a value" used in `app/lib/utils/exportGraph.ts:10` (`getGraphViewportElement`), `app/lib/utils/textSelection.ts:1` (`getSelectionCoordinates`), `app/lib/llm/cache.ts:33` (`getCachedResult`); verb-first generally across `app/lib/utils/*.ts` (see Baseline 2).
**Evidence:**

```ts
export function dataDir(): string {
```

and at the call site, `app/lib/llm/cache.ts:7`:

```ts
const CACHE_DIR = join(dataDir(), "cache");
```

**Legibility-target:** a reader skimming `cache.ts:7` who needs to notice that a `process.env` read is happening on that line.

Of the 46 exported symbols in `app/lib/utils/`, the only non-verb-led functions are `throttle` and `topologicalSort`, both of which name a well-known operation; `dataDir` names a *value*. The cost is that `join(dataDir(), "cache")` visually parses as a constant lookup, concealing that the module-scope const is now the frozen result of an environment probe — which is exactly the subtlety F4 and F7 are about. A `get*`/`resolve*` prefix restores the signal at zero behavioral cost, and this is the cheapest moment to rename since the symbol has exactly two non-test call sites.

**Recommendation:** rename to `getDataDir()` (matching the two `get*` accessors in `app/lib/utils/`) or `resolveDataDir()` if the inference is worth emphasizing. Two call sites plus the test's `describe` title.

---

#### F4 — Documented caveat lands on one consumer of the helper but not the other

**Severity:** Minor
**Location:** `app/lib/analytics/persist.ts:6–8` (present) vs `app/lib/llm/cache.ts:7` (absent)
**Move:** (7) asymmetries
**Confidence:** High
**Evidence:** `persist.ts:6–8`:

```ts
// On Vercel, analytics history doesn't persist across cold starts and is
// per-Function-instance. See dataDir() for the underlying rationale.
const DATA_DIR = dataDir();
```

`cache.ts` received the import and the `join(dataDir(), "cache")` rewrite with no corresponding comment.

**Legibility-target:** whoever next investigates "why is the LLM cache hit rate ~0 in production".

The review fix added a per-consumer caveat precisely because the pointer-to-`dataDir()` docstring alone was judged insufficient at the call site — but it applied that reasoning to only one of the two consumers. The two share identical ephemerality semantics, and the cache arguably has the more surprising failure mode: a silently-cold cache costs real API spend rather than lost history, and `cache.ts` has no other signal that `CACHE_DIR` may vanish between requests. Baseline convention 3's neighbor `VERIFY_FILE`/`LEAN_PROJECT_DIR` pairs its derived path const with an explanatory comment, so the commented form is the house style here. Symmetric treatment is two lines.

**Recommendation:** add the parallel comment above `CACHE_DIR` in `cache.ts`, e.g. "On Vercel the LLM cache is per-Function-instance and lost on cold start, so expect misses (and real API spend) after idle. See dataDir()."

---

#### F5 — Test title claims "unset" but stubs an empty string, so the genuinely-unset path is unpinned

**Severity:** Minor
**Location:** `app/lib/utils/dataDir.test.ts:28–31`
**Move:** (3) consumer contracts — the test is the contract document for a branch nothing else exercises
**Confidence:** High — carried from the merged fact-check, which flagged the same mismatch.
**Precedent:** literal-condition `it()` titles in `app/lib/utils/textSelection.test.ts:5` ("returns null when no text is selected (cursor only)") and `app/lib/llm/costs.test.ts:11`; `delete process.env.<VAR>` as the existing idiom for clearing env in `app/lib/llm/streamLlm.test.ts:21–22`.
**Evidence:**

```ts
it("returns <cwd>/data when VERCEL is unset", () => {
  vi.stubEnv("VERCEL", "");
  expect(dataDir()).toBe(join(originalCwd, "data"));
});
```

**Legibility-target:** the future refactorer this test file was explicitly written to catch (per its own header comment).

The file's own comment says its job is to pin both branches so a refactor that flips or deletes the Vercel check gets caught, which makes title accuracy load-bearing rather than cosmetic. Sibling titles in `textSelection.test.ts` and `costs.test.ts` describe the literal input state, not the intended scenario, and the divergence here matters because empty-string and absent are the same only under the truthiness check of F6 — swap in the codebase's `??` idiom and this test would keep passing while the described case broke. The file also introduces `vi.stubEnv` where `streamLlm.test.ts` already established `delete process.env.X`; that is a defensible upgrade (stubbing auto-restores), just worth noting as a second env-test idiom now in play.

**Recommendation:** rename to "returns `<cwd>/data` when VERCEL is empty" and add a third case using `vi.stubEnv("VERCEL", undefined)` (or `delete process.env.VERCEL`, matching `streamLlm.test.ts`) titled "…when VERCEL is unset".

---

#### F6 — Truthiness env check diverges from the codebase's `??` idiom

**Severity:** Informational
**Location:** `app/lib/utils/dataDir.ts:15`
**Move:** (1) baseline conventions — env-var handling
**Confidence:** Medium — behavior is arguably more correct here; the finding is about consistency and its untested edge.
**Precedent:** `??` (nullish, so `""` and `"0"` count as set) in `verifier/server.ts:9,15` and `app/api/verification/lean/route.ts:4`.
**Evidence:**

```ts
return process.env.VERCEL ? "/tmp" : join(process.cwd(), "data");
```

**Legibility-target:** anyone adding a third env-driven branch and reaching for the wrong idiom by analogy.

This is the only truthiness-based env read in the codebase; the four pre-existing reads all use `??`. For a platform marker the truthiness form is defensible and probably preferable — `VERCEL=""` genuinely should not mean "on Vercel" — but the choice is silent, and the one test that would document it (F5) mislabels the case it covers. Since Vercel sets `VERCEL=1`, nothing observable turns on this today; the risk is a later reader normalizing this line to `??` for consistency and quietly changing the empty-string semantics. One comment removes that risk.

**Recommendation:** keep the truthiness check; add `// truthiness, not ??: VERCEL="" should mean "not on Vercel"` and let the F5 test rename document it.

---

#### F7 — Function shape advertises per-call resolution; both consumers freeze it at import

**Severity:** Informational
**Location:** `app/lib/analytics/persist.ts:8`, `app/lib/llm/cache.ts:7`
**Move:** (9) idempotency / safety
**Confidence:** High
**Evidence:**

```ts
const DATA_DIR = dataDir();          // persist.ts:8
const CACHE_DIR = join(dataDir(), "cache");   // cache.ts:7
```

**Legibility-target:** a future third consumer deciding whether to hoist `dataDir()` to module scope or call it inline.

Both consumers evaluate `dataDir()` exactly once at module load, which matches baseline convention 3 (`PORT`, `LEAN_PROJECT_DIR`, `LEAN_VERIFIER_URL` are all resolved-once module consts) and is uniform across the pair — the fact-check's "call conventions now uniform" finding holds. The note is that the exported surface is a function, so it *reads* as re-evaluated per call, and the only caller that actually depends on that dynamism is the test, which re-invokes it under three different stubbed environments. Nothing to change: `process.env.VERCEL` is fixed for a process lifetime, so both shapes agree. Flagging it only so the divergence between "what the signature implies" and "how every production caller uses it" is on the record.

**Recommendation:** none required. If a third consumer appears, keep the module-const idiom for consistency with the existing two rather than calling `dataDir()` inline per request.

---

#### F8 — Directory creation stays with consumers, in two different idioms, now visibly rooted at one place

**Severity:** Informational
**Location:** `app/lib/analytics/persist.ts:11–15` vs `app/lib/llm/cache.ts:27–32`
**Move:** (9) idempotency / safety
**Confidence:** High
**Evidence:** `persist.ts` checks and creates on every write —

```ts
function ensureDir() {
  if (!existsSync(DATA_DIR)) {
    mkdirSync(DATA_DIR, { recursive: true });
  }
}
```

— while `cache.ts` memoizes with a module flag: `let dirEnsured = false; … await mkdir(CACHE_DIR, { recursive: true }); dirEnsured = true;`.

**Legibility-target:** whoever eventually consolidates the two persistence layers.

Keeping `dataDir()` pure — resolution only, no `mkdir` side effect — is the right call and matches the sibling helpers in `app/lib/utils/`, none of which touch the filesystem at import. The divergence in how the two consumers then ensure their directory (sync-per-call vs memoized-async) predates this diff and is untouched by it, so it is out of scope for a fix here. It is worth recording because the extraction is what makes the two paths obviously siblings: the memoized flag in `cache.ts` is the riskier of the two under `/tmp` semantics, since a container that loses `/tmp` between invocations while keeping the module warm would leave `dirEnsured === true` against a directory that no longer exists.

**Recommendation:** none in this diff. If F1's `join("/tmp", "data")` lands, consider whether `cache.ts`'s `dirEnsured` memo should be dropped in favor of the unconditional `mkdir … { recursive: true }` (which is already idempotent and cheap) — but as a separate change.

---

### What Looks Good

- **Consumer call convention is genuinely uniform.** Both consumers now import `dataDir` by the same `@/app/lib/utils/dataDir` path-alias form and compose with `join`, matching `persist.ts`'s pre-existing `@/app/lib/types/analytics` import style and the `VERIFY_FILE = path.join(LEAN_PROJECT_DIR, …)` pattern in `verifier/server.ts:17`.
- **Module and test placement are exactly on-convention.** Flat file in `app/lib/utils/`, camelCase filename matching the export, colocated `.test.ts`, `describe()` named for the symbol, no barrel file introduced.
- **Explicit `: string` return type and total nullability.** `dataDir()` cannot return `null`/`undefined`, so neither consumer needs a guard — appropriate here, and distinct from the deliberately nullable `loadWorkspace(): PersistedWorkspace | null` and `getGraphViewportElement(): HTMLElement | null`, which return null for genuinely-absent state.
- **Both branches pinned by test.** The Vercel branch is invisible in local dev; testing it is the only mechanism that would catch its deletion, and the test file says so in its header comment. The `VERCEL="preview"` case correctly documents that any truthy value counts.
- **No documentation drift.** Dropping the README reference left nothing dangling — a repo-wide search for `VERCEL`, `/tmp`, `data/cache`, and `"data"` across `README.md`, `CLAUDE.md`, `CONTRIBUTING.md`, `docs/`, and `documentation/` returns no hits, and `.gitignore` already carries `/data/` under a "local data (analytics + LLM response cache)" comment that stays accurate.

---

### Summary Table

| # | Finding | Severity | Location | Move |
|---|---|---|---|---|
| F1 | `/tmp` branch drops the `data/` segment; branches not parallel | Inconsistent | `dataDir.ts:15` | 7 |
| F2 | No env override, diverging from `LEAN_PROJECT_DIR` precedent | Inconsistent | `dataDir.ts:14–16` | 1 |
| F3 | `dataDir()` bare noun vs verb-first sibling accessors | Minor | `dataDir.ts:14` | 2 |
| F4 | Caveat comment on `persist.ts` but not `cache.ts` | Minor | `persist.ts:6–8` / `cache.ts:7` | 7 |
| F5 | Test says "unset", stubs `""`; true-unset path unpinned | Minor | `dataDir.test.ts:28–31` | 3 |
| F6 | Truthiness env check vs codebase `??` idiom | Informational | `dataDir.ts:15` | 1 |
| F7 | Function shape implies per-call resolution; consumers freeze it | Informational | `persist.ts:8`, `cache.ts:7` | 9 |
| F8 | Two divergent `ensureDir` idioms under one resolved root | Informational | `persist.ts:11–15`, `cache.ts:27–32` | 9 |

No Breaking findings. `dataDir()` is new, so it has no prior consumers to break; the two rewired consumers produce byte-identical paths off Vercel and were already `/tmp`-bound on Vercel as of `2136fd6`.

---

### Overall Assessment

The extraction is clean and lands squarely on the directory's conventions: single-concern helper, correct file and test placement, explicit return type, pure resolution with side effects left to consumers, and both call sites converged on one idiom. The review-fix commit (`2cd3b67`) did the right things — dropping the rest-args variadic signature in favor of `join(dataDir(), …)` at call sites removed a second way to spell the same thing, which is the kind of API narrowing that pays off later.

Two findings are worth acting on before this is treated as settled. F1 is the substantive one: the Vercel branch returns the shared `/tmp` root rather than an app-owned subdirectory, so the two branches produce structurally different layouts and the app writes — and `unlink`s and truncates — in a namespace it does not own. One `join` fixes it. F2 is the consistency gap: the codebase already solved "path resolved by inference, needs an escape hatch" in `verifier/server.ts` and answered it with an env override plus a comment; this helper answers it with binary platform detection while its own docstring promises to serve self-hosted deployments. The remaining findings are polish — a rename, a mirrored comment, a test title — each cheap now and progressively more annoying once more consumers exist.

Confidence in the review is limited chiefly by sample size on the env-handling convention (four reads across two files), which is why F2 and F6 are scored Medium and Informational respectively rather than higher.

---

## Goal-Alignment Note

- **Answered:** whether `dataDir()`'s name, signature, and return contract match `app/lib/utils/` neighbors (Name-Pattern Audit, F3); whether the two consumers now bind to it uniformly and whether their derived paths preserve the pre-extraction contract (F7, and the fact-check foundation); whether the post-fix code still carries the un-namespaced `/tmp` asymmetry raised in scope (F1 — yes, still present); whether env handling matches the `LEAN_PROJECT_DIR` override precedent (F2, F6); nullability and idempotency of the new surface (What Looks Good, F8); whether the new test file follows sibling test conventions (F5); whether dropping the README reference left dangling docs (What Looks Good — it did not).
- **Out of scope:** correctness of the `/tmp`-only-writable premise about Vercel Functions (a platform fact, not an interface question — and accepted by the fact-check); whether ephemeral analytics and an ephemeral LLM cache are acceptable product behavior on Vercel at all, versus moving to a real store; security review of writing to a shared `/tmp` (F1 notes the collision surface as a consistency asymmetry, but attacker-model analysis belongs to `security-reviewer`); performance of the sync `existsSync`/`appendFileSync` calls in `persist.ts` (pre-existing, and `performance-reviewer`'s call); test coverage adequacy beyond the new file's own conventions (`test-strategy`).
- **Escalate:** F1 to whoever owns the Vercel deployment — the fix is one line, but if any tooling or runbook already assumes analytics land at `/tmp/analytics.jsonl`, the path change needs to be coordinated rather than merged silently. F2 to the same owner if a self-hosted or Docker deployment is actually planned (`docker-compose.yml` is in the repo), since the absence of a `DATA_DIR` override is only a real problem in that scenario.
