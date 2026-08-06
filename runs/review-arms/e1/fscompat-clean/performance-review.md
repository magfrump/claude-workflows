# Performance Review — fscompat-clean (d86d2dc..2cd3b67)

**Scope:** `git diff d86d2dc..2cd3b67` — 4 files, +54/-2. `app/lib/utils/dataDir.ts` (new), `app/lib/utils/dataDir.test.ts` (new), `app/lib/analytics/persist.ts`, `app/lib/llm/cache.ts`. Commits outside the range are context only.
**Date:** 2026-08-06
**Based on:** merged code fact-check (k=3, 0 Incorrect; path equivalence, module-scope `dataDir()` calls, and the 4-export cache seam all verified — not re-verified here).

`Commit: 2cd3b67`

---

### Data Flow and Hot Paths

Two consumers were realigned onto one `dataDir()` helper that returns `/tmp` when `process.env.VERCEL` is truthy and `join(process.cwd(), "data")` otherwise. Both call it **at module scope** (`app/lib/analytics/persist.ts:8`, `app/lib/llm/cache.ts:7`), so path resolution costs one `getcwd` + one `join` per process, not per request.

The paths that matter:

**Path A — LLM generation (hot).** The client fans out artifact generation in parallel: `app/hooks/useArtifactGeneration.ts:77` does `Promise.allSettled` over the selected artifact types, and `app/lib/formalization/formalizeNode.ts:127` does `Promise.all` over the same set. `ArtifactType` has 7 members (`app/lib/types/session.ts:8-15`), so a full run issues up to 7 concurrent HTTP requests plus decomposition. Each request lands in `artifactRoute.ts`, which routes to either `streamLlm()` (SSE) or `callLlm()`. Both do, in order: `computeHash()` → `getCachedResult()` → provider call → `appendAnalyticsEntry()` → `setCachedResult()`. The cache read/write is `fs/promises` (async); the analytics append is `fs` **sync**.

**Path B — analytics dashboard (warm, every page mount).** `app/hooks/useAnalytics.ts:24-26` calls `refresh()` from a mount `useEffect`, hitting `GET /api/analytics` → `readAnalyticsEntries()` → `existsSync` + `readFileSync` of the entire `analytics.jsonl` + `JSON.parse` per line. This runs on every initial render of the app.

**What the diff itself adds to those paths: nothing.** No new I/O operation, allocation, loop, or dependency is introduced. Every finding below is either (a) pre-existing work whose *exposure profile* changed because the storage medium moved from a durable repo directory to an ephemeral, per-instance, size-capped `/tmp`, or (b) the item the author explicitly deferred.

---

### Findings

#### F1. Deferred cache-hit collapse: the seam holds, but the carry cost is a billed API call per miss and the fan-out multiplies it

**Severity:** High
**Location:** `app/lib/llm/cache.ts:7` (`const CACHE_DIR = join(dataDir(), "cache")`), `app/lib/utils/dataDir.ts:14`
**Move:** (8) caches — LLM cache on ephemeral per-instance `/tmp`, cost-of-miss is a billed API call; amplified by (7) contention across concurrent instances
**Classification:** Macro / Hot (Path A — every artifact generation request passes through `getCachedResult` before any provider call, `callLlm.ts:125`, `streamLlm.ts:101`)
**Confidence:** High on the mechanism and the cost arithmetic; Medium on real-world hit-rate delta, which depends on deployment traffic shape that is not observable in-repo.
**Baseline:** From the repo's own tables — `PRICING["claude-sonnet-4-6"]` = $3/M input, $15/M output (`app/lib/llm/costs.ts:14`); `ENDPOINT_ESTIMATES` output tokens sum to **14,100 tokens** across the 8 sonnet endpoints, derived from **246 logged calls as of 2026-04-16** (`app/lib/llm/costs.ts:50-52`, `docs/decisions/007-cost-estimation-model.md`). One full-pass regeneration therefore costs **$0.2115 in output tokens alone** (14,100 × 15/1e6), plus **$0.0423 per 1,000 input tokens shared across the 8 calls** (14,100 × 3/1e6 is the output-side figure; input scales with `inputCharLength/4` per `estimateCost`). Per-artifact: causal-graph $0.0225, dialectical-map $0.0360.
**Evidence:** `dataDir.ts:8-11` — "`/tmp` lives only as long as a warm container, so persistence does not survive cold starts; it is also per-instance, so concurrent Function instances each see their own independent contents (no cross-instance sharing)."
**Legibility-target:** The deferral note reads the risk as a *migration-churn* question ("the cache interface is already abstracted, so a follow-up branch can migrate to Vercel KV / Upstash without churn"). That framing is correct about churn and silent about carry cost.

Assessing the deferral rationale on its own terms: **it holds structurally.** The seam is genuine — `computeHash`, `getCachedResult`, `setCachedResult`, `removeCachedResult` are the only exports, three are already `async`, no caller constructs or inspects a path, and the `dirEnsured` latch is module-private, so a KV backend drops in behind the same four signatures. The one sync export, `computeHash`, is pure crypto with no I/O and needs no change. So the "migrate later without churn" claim is sound and I do not dispute the decision to defer.

What the rationale does not price is the **cost of the deferral window**, and the fan-out is what makes it non-trivial. Because `useArtifactGeneration.ts:77` issues up to 7 artifact requests concurrently, a single user action can be spread across up to 7 Function instances, each with its own `/tmp`. A cache entry written by the instance that served `causal-graph` is invisible to the instance that later re-serves it, so the effective hit rate degrades roughly as 1/N in the number of instances the platform spins up — and it resets to zero on every cold start regardless. Prior to 2136fd6 the cache was a no-op on Vercel (writes to a read-only FS, silently swallowed), so this is not a regression; it is a feature that now *appears* to work while delivering a fraction of its nominal benefit, which is the more expensive failure mode because nobody investigates it. At $0.2115 of output tokens per full regeneration, the deferral is affordable for the single-tenant deploys 2136fd6's message scopes it to, and unaffordable if the app ever serves shared traffic.

**Recommendation:** Keep the deferral; amend it with a trigger rather than a date. Two cheap steps in the meantime: (1) log the cache hit/miss ratio — `callLlm.ts:126` already logs hits, so counting misses alongside them makes the collapse measurable instead of theoretical, and gives the KV migration a before/after number; (2) record in the follow-up branch's brief that the migration's success metric is hit rate, not code cleanliness. If the deployment target ever changes from single-tenant, promote this to blocking before the change ships.

---

#### F2. `readAnalyticsEntries` synchronously reads and parses an unbounded, never-rotated JSONL on every page mount, blocking the event loop

**Severity:** High
**Location:** `app/lib/analytics/persist.ts:22-35`; consumers `app/api/analytics/route.ts:5`, `app/hooks/useAnalytics.ts:11,24-26`
**Move:** (5) file-access patterns — sync fs on a request path; (9) asymptotics — O(N) in total lifetime entries with no bound; (7) contention — a sync read blocks all co-resident requests
**Classification:** Macro / Hot (confirmed: `useAnalytics.ts:24-26` fires `GET /api/analytics` from a mount `useEffect`, so this executes on every initial render of the app, and the handler is `readFileSync` on the Node request thread)
**Confidence:** High on the mechanism and the growth shape; Medium on present-day magnitude, because `data/` is gitignored (`.gitignore:37`) and absent from the worktree, so the file cannot be measured directly.
**Baseline:** **246 entries as of 2026-04-16**, measured — the ENDPOINT_ESTIMATES docstring states medians were "derived from analytics data (246 calls, 2026-04-16)" (`app/lib/llm/costs.ts:51`). The `AnalyticsEntry` shape (uuid `id`, `endpoint`, `provider`, `model`, four numerics, ISO `timestamp`) puts a line at roughly 250 bytes, so ≈**61.5 KB** at that count — an estimate derived from the type, not a measured file size.
**Evidence:** `persist.ts:22-27` — `if (!existsSync(FILE_PATH)) return []; const content = readFileSync(FILE_PATH, "utf-8"); ... for (const line of content.split("\n"))`.
**Legibility-target:** 61.5 KB looks harmless, and it is — today. The problem is the *shape*, not the current value: nothing in the code bounds N. There is no rotation, no size cap, no date window, and no pagination on the route; `clearAnalyticsEntries()` is the only pruning mechanism and it is user-initiated from the dashboard. Every LLM call appends one line forever.

The scaling factor is linear in cumulative lifetime calls, and it is paid three times over per page load: one `readFileSync` (whole file into a string), one `split("\n")` (a second full copy as an array), and one `JSON.parse` per line. Because `readFileSync` is synchronous inside a Next.js route handler, it blocks the Node event loop for the duration — and the workload that generates the entries is exactly the workload that suffers, since up to 7 concurrent SSE artifact streams (`useArtifactGeneration.ts:77`) share that instance and stall behind it. At 246 entries this is sub-millisecond and invisible. At 250,000 entries — a year of moderate self-hosted use — it is a multi-megabyte synchronous read plus 250k `JSON.parse` calls on every page load, and the streams visibly stutter. Note the change under review *bounds* this on Vercel, where `/tmp` resets on cold start; the unbounded case is the self-hosted `data/` path the diff leaves durable, which is also the path with no operator watching it.

**Recommendation:** Two independent fixes, neither large. (1) Switch to `fs/promises` `readFile` so the read yields the event loop — this alone removes the interference with concurrent artifact streams and is a near-mechanical change. (2) Bound N: either cap the route to the most recent K entries (read the tail rather than the whole file), or rotate `analytics.jsonl` at a size threshold in `appendAnalyticsEntry`. The dashboard computes summary aggregates in `useAnalytics`'s `useMemo`, so if full-history aggregates are required, a rolling summary written alongside the log is the durable answer. Fix (1) first; it is cheap and removes the contention.

---

#### F3. `appendAnalyticsEntry` does a sync `existsSync` + `appendFileSync` on the LLM completion path, under 7-way concurrency

**Severity:** Medium
**Location:** `app/lib/analytics/persist.ts:11-20`; callers `callLlm.ts:85,213`, `streamLlm.ts:56,149`
**Move:** (5) file-access patterns — sync fs on a request path; (7) contention — concurrent artifact requests share one instance and one file handle
**Classification:** Micro / Hot (matrix places Micro×Hot at Low-Medium; rated at the top of that band because the fan-out at `useArtifactGeneration.ts:77` puts up to 7 concurrent requests through this same synchronous call on one instance)
**Confidence:** High that the calls are synchronous and on the completion path; Low on whether the blocking duration is ever material, since no latency measurement of the append exists.
**Baseline:** `no baseline available — flagged as speculative`
**Evidence:** `persist.ts:17-20` — `export function appendAnalyticsEntry(entry: AnalyticsEntry): void { ensureDir(); appendFileSync(FILE_PATH, JSON.stringify(entry) + "\n", "utf-8"); }`, where `ensureDir()` is `if (!existsSync(DATA_DIR)) { mkdirSync(...) }`.
**Legibility-target:** This is genuinely small work — one `stat` and one ~250-byte append — sitting next to a multi-second LLM call, so the ratio argues it will never matter.

The reason to record it anyway is that it is *synchronous* work in an async server, and the scaling factor is the fan-out width rather than the payload size: 7 concurrent artifact requests completing near-simultaneously each block the shared event loop for the duration of a `stat` plus an `append`, serializing what is otherwise fully concurrent, and doing so precisely when the SSE streams are flushing their final `done` events. The `existsSync` is also pure repeated work — unlike `cache.ts`'s `ensureCacheDir`, which latches on a module-scope `dirEnsured` boolean and does its `mkdir` once per process, `ensureDir()` re-`stat`s on every single append. `docs/plans/refactoring-plan.md:38` already flags the equivalent `existsSync`-before-write pattern in `cache.ts` as a TOCTOU anti-pattern; `persist.ts` is the instance that survived.

**Recommendation:** Adopt `cache.ts`'s pattern in `persist.ts` — a module-scope `dirEnsured` latch removes the per-append `stat` for a two-line change. Converting `appendFileSync` to async `appendFile` is the larger win but ripples into the four call sites and their `try/catch` blocks; worth doing together with F2's async conversion, not separately.

---

#### F4. Cache files written via `callLlm` embed a full, never-read copy of the system prompt and user content, pretty-printed

**Severity:** Medium
**Location:** `app/lib/llm/cache.ts:62-68` (`setCachedResult`), written from `app/lib/llm/callLlm.ts:92-95`
**Move:** (6) serialization tax; (4) memory lifecycle — bytes persisted that no reader consumes
**Classification:** Micro / Hot (on the write path of every cache miss; rated Medium rather than Low because the wasted payload scales with user input size and now lands on a size-capped volume)
**Confidence:** High — the type flow and the read path are both directly readable.
**Baseline:** Per-artifact system prompts are not separately measurable, but the route files that carry them run **1,649–7,655 bytes** (`app/api/formalization/semiformal/route.ts` through `app/api/formalization/lean/route.ts`, measured with `wc -c`), so the system-prompt component of the duplicated payload is on the order of single-digit KB. `userContent` is user-supplied source text — the repo ingests PDFs (`app/lib/utils/pdfPropositionParser.ts`), so its upper bound is `no baseline available — flagged as speculative`.
**Evidence:** `callLlm.ts:93-95` — `const result: CallLlmResult = { text, usage, cacheKey }; if (text) { try { await setCachedResult(cacheHash, result); }`, where `CacheKey = { model, systemPrompt, userContent, maxTokens }` (`callLlm.ts:61-66`). `setCachedResult` then does `await writeFile(filePath, JSON.stringify(result, null, 2), "utf-8")`.
**Legibility-target:** `setCachedResult`'s parameter is typed `CachedResult = { text, usage }`, so the file *looks* like it stores two fields. It stores three: because `result` is passed as a variable rather than an object literal, TypeScript's excess-property check does not fire, and `cacheKey` — containing the entire system prompt and the entire user content — is serialized to disk. `getCachedResult` reads back only `data.text` and `data.usage` (`cache.ts:44-53`), so those bytes are written and never read.

The scaling factor is one extra copy of every prompt per cached artifact, inflated further by `JSON.stringify(result, null, 2)`'s pretty-printing. Note the asymmetry: `streamLlm.ts:64` calls `setCachedResult(cacheHash, { text, usage })` with an object literal and writes only what is read — so the streaming path is already correct and `callLlm` is the outlier, which is what makes this a slip rather than a design choice. This is pre-existing and out of the diff's line-level scope; it earns a place here because the change under review relocates these files to `/tmp`, which carries a fixed platform size cap where the repo's `data/` directory carried none. (The existence of a Vercel `/tmp` cap is the load-bearing claim; the specific figure commonly cited is 512 MB, which I did not verify against provider docs and which the fact-check did not cover.)

**Recommendation:** Pass `{ text, usage }` at `callLlm.ts:93` to match `streamLlm.ts:64` — a one-line change that halves-or-better the cache footprint and aligns the two write paths. Separately, drop the `null, 2` argument from `JSON.stringify` in `setCachedResult`; these files are machine-read only, and the indentation is pure overhead. Tightening `setCachedResult`'s signature to reject extra properties would prevent the recurrence.

---

#### F5. LLM cache has no eviction, TTL, or size bound; `removeCachedResult` fires only on a JSON parse failure

**Severity:** Medium
**Location:** `app/lib/llm/cache.ts:62-83`; sole removal call site `app/lib/formalization/artifactRoute.ts:104`
**Move:** (4) memory lifecycle; (9) asymptotics — cache entries accumulate monotonically
**Classification:** Macro / Cold (growth accrues across sessions rather than within a request; no per-request cost)
**Confidence:** High on the absence of eviction; Medium on impact, which differs sharply between the two deployment targets.
**Baseline:** `no baseline available — flagged as speculative` — `data/cache/` is gitignored (`.gitignore:37`) and absent from the worktree, so neither entry count nor total size is measurable here.
**Evidence:** `artifactRoute.ts:104` — `try { await removeCachedResult(cacheKey.model, cacheKey.systemPrompt, cacheKey.userContent, cacheKey.maxTokens); } catch { /* ignore */ }`, reached only inside the `catch` of `JSON.parse(stripCodeFences(responseText))`.
**Legibility-target:** Every distinct `(model, systemPrompt, userContent, maxTokens)` tuple creates a new file that is never removed unless that specific response failed to parse as JSON. Since `userContent` is the user's source text, the key space is effectively unbounded — each edit to a proposition mints a fresh cache entry and orphans the previous one, so the growth rate tracks editing activity, not distinct documents.

The two targets diverge. On Vercel this is self-limiting: `/tmp` resets on cold start, so accumulation is bounded by container lifetime — though it races the platform's fixed `/tmp` cap within a long-lived warm container, and a write that hits the cap fails silently into `callLlm.ts:94`'s `catch { /* cache write failure is non-fatal */ }`, degrading to permanent cache-miss with no signal. On self-hosted deploys, `data/cache/` grows without limit on real disk. This compounds with F4: unbounded entry count multiplied by per-entry prompt duplication.

**Recommendation:** Defer alongside F1 — a KV backend gets TTL for free, which is an underused argument *for* that migration and worth adding to the follow-up branch's brief. If the migration slips, the cheap interim is an mtime-based sweep in `ensureCacheDir` (which already runs once per process, so it is the natural hook) deleting entries older than N days. Do not build an LRU for the filesystem backend; that work does not survive the migration.

---

#### F6. `computeHash` runs twice per LLM call — once by the caller, once inside `getCachedResult`

**Severity:** Low
**Location:** `app/lib/llm/cache.ts:34-41`; callers `app/lib/llm/callLlm.ts:118,125` and `app/lib/llm/streamLlm.ts:93,101`
**Move:** (3) work moved to the wrong place — the API takes raw key components where the caller already holds the hash; (6) serialization tax
**Classification:** Micro / Hot (on every LLM call, both streaming and non-streaming)
**Confidence:** High on the duplication; High that the magnitude is small.
**Baseline:** `no baseline available — flagged as speculative` — no profiling data exists for hash or stringify cost on this path.
**Evidence:** `callLlm.ts:118` computes `const cacheHash = computeHash(effectiveModel, systemPrompt, userContent, maxTokens);` with the comment "Compute hash once, reuse for cache get and set", then `callLlm.ts:125` calls `getCachedResult(effectiveModel, systemPrompt, userContent, maxTokens)` — whose first statement (`cache.ts:40`) is `const hash = computeHash(model, systemPrompt, userContent, maxTokens);`.
**Legibility-target:** The comment at `callLlm.ts:117` says the hash is computed once and reused; it is reused for the *set* (since `setCachedResult` correctly takes a hash) but recomputed for the *get*, because `getCachedResult` takes the four raw components instead. Each recomputation is a `JSON.stringify` of the full prompt plus a SHA-256 over the result (`cache.ts:21-24`), so the scaling factor is linear in prompt size — for a PDF-derived `userContent` of a few hundred KB that is a stringify plus a hash of the same, on the order of a millisecond against a multi-second LLM call.

The regeneration path pays a third time: `artifactRoute.ts:104` calls `removeCachedResult` with raw components again. The cost is negligible and I would not fix this for performance alone; it is recorded because the asymmetry between `getCachedResult`'s and `setCachedResult`'s signatures is what causes it, and that asymmetry is worth knowing before the KV migration in F1 redesigns these signatures anyway.

**Recommendation:** Fold into the F1 migration rather than fixing standalone. When the interface is revised, make the hash the parameter for all three operations (`get`/`set`/`remove`) and let `computeHash` stay the caller's explicit first step — this also makes the KV key derivation obvious at the call site. No independent action warranted now.

---

#### F7. `readAnalyticsEntries` stats before reading — two syscalls where one `try/catch` would do

**Severity:** Informational
**Location:** `app/lib/analytics/persist.ts:23-24`
**Move:** (5) file-access patterns
**Classification:** Micro / Hot (same mount-time path as F2)
**Confidence:** High.
**Baseline:** `no baseline available — flagged as speculative`
**Evidence:** `persist.ts:23-24` — `if (!existsSync(FILE_PATH)) return []; const content = readFileSync(FILE_PATH, "utf-8");`
**Legibility-target:** `cache.ts:42-56` already demonstrates the better pattern in this same codebase — `getCachedResult` wraps `readFile` in `try/catch` and treats any failure as a miss, with the comment "Corrupt or missing cache file — treat as miss", costing one syscall on the miss path instead of two. `docs/plans/refactoring-plan.md:38` names the check-then-act shape as a TOCTOU anti-pattern and lists `cache.ts` as the offender; `cache.ts` was since fixed and `persist.ts` was not. The cost is one extra `stat` per page load, which is genuinely nothing — this is recorded for consistency with the codebase's own stated convention, not for speed.

**Recommendation:** Fold into F2's async conversion — replacing `existsSync` + `readFileSync` with a `try { await readFile(...) } catch { return [] }` accomplishes F2's non-blocking fix and this one in the same edit. Not worth a separate change.

---

#### F8. Analytics writes and reads have no instance affinity on Vercel, so the dashboard reads one instance's slice

**Severity:** Informational
**Location:** `app/lib/analytics/persist.ts:8`, `app/api/analytics/route.ts:5`
**Move:** (7) contention — shared-file assumptions that no longer hold across instances
**Classification:** Macro / Cold (affects data completeness rather than latency; no per-request cost)
**Confidence:** High on the mechanism, which the diff's own docstring states.
**Baseline:** **246 logged calls as of 2026-04-16** (`app/lib/llm/costs.ts:51`) — the figure the current cost model was calibrated on, and the number at risk of becoming unrepresentative under this deployment.
**Evidence:** `dataDir.ts:9-11` — "it is also per-instance, so concurrent Function instances each see their own independent contents (no cross-instance sharing)."
**Legibility-target:** The performance-relevant consequence is second-order but worth naming: `ENDPOINT_ESTIMATES` (`costs.ts:56-66`) drives the app's cost estimates and its wait-time estimate (`app/hooks/useWaitTimeEstimate.ts`), and those medians are recalibrated from logged analytics. On Vercel, a 7-way fan-out scatters one user action's entries across up to 7 instances' independent `/tmp` files, and `GET /api/analytics` reads whichever single instance serves it — so the sample feeding any future recalibration is both partial and non-uniform across endpoints. The estimates degrade quietly rather than visibly.

This is inherent to the `/tmp` approach and is not an argument against the change, which correctly traded durability for a working feature. It is an argument for treating Vercel-sourced analytics as non-authoritative until F1's migration lands.

**Recommendation:** No code change. Add one line to `persist.ts`'s existing comment noting that Vercel-sourced analytics are a partial sample and should not be used to recalibrate `ENDPOINT_ESTIMATES`; the comment at `persist.ts:5-7` already establishes the caveat and this extends it to the consumer.

---

### What Looks Good

- **Module-scope path resolution preserved.** Both consumers evaluate `dataDir()` once at module load (`persist.ts:8`, `cache.ts:7`) rather than per call. The refactor could easily have introduced a per-request `dataDir()` — and `cache.ts` in particular calls it inside a `join`, which is exactly where a per-call regression would hide — but did not. One `getcwd` per process, zero per request.
- **The helper is I/O-free.** `dataDir()` is a single env read and a `join` (`dataDir.ts:14`), so even if a future caller does invoke it per request the cost stays trivial. Extracting it did not create a hot-path hazard.
- **`dirEnsured` latch is correct memoization.** `cache.ts:26-31` performs `mkdir` once per process rather than per cache write, and it is module-private so the F1 migration can delete it cleanly.
- **`ensureCacheDir` is deliberately absent from the read path.** `getCachedResult` does not stat-or-mkdir before reading, so a cache miss costs exactly one failed `readFile` (`cache.ts:42-56`). This is the pattern F3 and F7 recommend propagating to `persist.ts`.
- **The cache path is async throughout.** `cache.ts:2` imports from `fs/promises`, so cache reads and writes yield the event loop under the 7-way artifact fan-out. The contention findings are confined to `persist.ts`.
- **The new test costs nothing to run.** `dataDir.test.ts` exercises a pure function with `vi.stubEnv` and no I/O or filesystem fixtures, so it adds negligible time to the 224-test suite while pinning an invariant that is invisible to local dev, build, and lint.
- **The change is net-neutral on work performed.** No new allocation, loop, syscall, serialization step, or dependency. As a performance diff in isolation, this is a no-op — the correct outcome for a path-resolution refactor.

---

### Summary Table

| # | Finding | Severity | Class | Temp | Baseline |
|---|---------|----------|-------|------|----------|
| F1 | Deferred cache-hit collapse on per-instance `/tmp`; seam holds, carry cost unpriced | High | Macro | Hot | $0.2115 output/full pass (costs.ts) |
| F2 | Unbounded `analytics.jsonl` read+parsed synchronously on every page mount | High | Macro | Hot | 246 entries @ 2026-04-16 (costs.ts:51) |
| F3 | Sync `existsSync`+`appendFileSync` on LLM completion path under 7-way fan-out | Medium | Micro | Hot | speculative |
| F4 | Cache files embed never-read prompt duplicate, pretty-printed | Medium | Micro | Hot | prompts 1.6–7.7 KB (wc -c) |
| F5 | No cache eviction, TTL, or size bound | Medium | Macro | Cold | speculative |
| F6 | `computeHash` computed twice per LLM call | Low | Micro | Hot | speculative |
| F7 | `existsSync` before `readFileSync` — two syscalls for one | Informational | Micro | Hot | speculative |
| F8 | Analytics scattered across instances; dashboard reads one slice | Informational | Macro | Cold | 246 calls (costs.ts:51) |

---

### Overall Assessment

**The diff under review introduces no performance regression.** It relocates two path constants behind a shared helper, preserves module-scope evaluation at both call sites, adds no I/O, and ships a zero-cost test. Judged strictly on what changed, this is clean and I would not block it on performance grounds.

The findings above are almost entirely *inherited exposure*. Moving persistence from a durable repo directory to an ephemeral, per-instance, size-capped `/tmp` does not add work, but it changes which pre-existing properties matter: unbounded growth (F2, F5) becomes bounded-but-capped, per-entry bloat (F4) starts competing for a fixed budget, and cache locality (F1) collapses. This is the honest shape of the review — the change is fine; it moved the code into an environment that scrutinizes different things.

Two items deserve attention beyond this branch. **F1** is the author's deferral, and I concur with it: the seam is real, the four exports are migration-ready, and the churn argument is correct. My one amendment is that the rationale prices migration effort and not the deferral window — at $0.2115 of output tokens per full regeneration and a hit rate degrading with instance count, the deferral is comfortable for the single-tenant scope 2136fd6 claims and uncomfortable outside it. Adding miss-rate logging makes that trigger observable rather than assumed, and costs one line next to the hit log that already exists. **F2** is the finding I would actually schedule: it is unrelated to the deferral, sits on the mount path of every page load, blocks the event loop that the concurrent artifact streams depend on, and grows without bound on the self-hosted path this diff leaves durable. The async conversion is small and subsumes F7.

Everything else is cleanup that should ride along with work already planned: F3 propagates a pattern `cache.ts` already demonstrates, F4 is a one-line alignment with `streamLlm.ts`'s already-correct call, and F6 should be folded into F1's interface revision rather than fixed standalone.

---

## Goal-Alignment Note

- **Answered:** Whether the diff itself adds hot-path work (it does not); whether the author's deferral rationale for the cache-hit-collapse finding holds (structurally yes — the seam is genuine and migration-ready; the gap is that it prices migration churn and not the cost of the deferral window, which the 7-way fan-out amplifies); the performance consequences of relocating persistence to ephemeral, per-instance, size-capped storage; all severities down to Informational, per the measurement-run instruction.
- **Out of scope:** Correctness of the `VERCEL` env switch and path equivalence (established by the merged k=3 fact-check; treated as foundation and not re-verified). Security of `/tmp` as a storage location, test coverage adequacy, and API design of the cache seam beyond its performance implications — those belong to security-reviewer, test-strategy, and api-consistency-reviewer respectively. No fix loop was run and no code was modified: this is a pass-1 measurement run.
- **Escalate:** Two claims could not be settled from the repo and should be confirmed before acting on F4 or F5 — (a) the exact Vercel `/tmp` size cap (the cap's *existence* is load-bearing; the commonly cited 512 MB figure is unverified against provider docs and was not covered by the fact-check), and (b) the current real-world size of `data/analytics.jsonl` and `data/cache/` on any self-hosted deploy, which are gitignored (`.gitignore:37`) and absent from the worktree, leaving F2's magnitude and F5 without a measured baseline. Also flagged for the author: the deployment-scope assumption in 2136fd6 ("acceptable for single-tenant deploys") is the load-bearing premise under F1's deferral — if that assumption changes, F1 should be re-rated before the follow-up branch lands.
