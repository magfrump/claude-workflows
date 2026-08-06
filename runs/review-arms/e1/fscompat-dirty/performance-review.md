# Performance Review — fscompat-dirty (d86d2dc..b64c1ca)

**Scope:** `git diff d86d2dc..b64c1ca` in the pinned worktree `/workspace/runs/review-arms/e1/wt-fscompat-dirty` (detached at b64c1ca) — extraction of `dataDir()` (`app/lib/utils/dataDir.ts`) and rewiring of `app/lib/analytics/persist.ts` and `app/lib/llm/cache.ts` onto it. 3 files, 21 insertions, 2 deletions.
**Date:** 2026-08-06
**Based on:** merged code-fact-check report (k=3), `code-fact-check-report.md` — treated as foundation, not re-verified.

**Commit:** b64c1ca

---

## Data Flow and Hot Paths

The diff changes one thing: where two persistence modules resolve their base directory. It introduces no new I/O calls, no new loops, and no new dependencies. Its entire performance surface is **which volume the existing I/O lands on**, and that volume differs by deployment target.

Three paths carry the traffic:

1. **LLM call path (hottest).** `callLlm()` (`app/lib/llm/callLlm.ts:110-130`) and `streamLlm()` (`app/lib/llm/streamLlm.ts:97-115`) each do, per invocation: one `computeHash` (sha256 over the full prompt), one `getCachedResult` → `readFile` from `CACHE_DIR`, and on a miss one `appendAnalyticsEntry` → `existsSync` + `appendFileSync` to `DATA_DIR`, plus one `setCachedResult` → `writeFile` to `CACHE_DIR`. Every user-facing formalization action traverses this. **Hot.**
2. **Analytics read path.** `GET /api/analytics` (`app/api/analytics/route.ts:4-7`) → `readAnalyticsEntries()` → a synchronous whole-file `readFileSync` plus a per-line `JSON.parse`. Fired once per mount of `useAnalytics` (`app/hooks/useAnalytics.ts:24-26`), i.e. per page load, not per LLM call. **Cold-to-warm.**
3. **Module-load path.** `dataDir()` is called exactly twice in the whole repo — `persist.ts:8` and `cache.ts:7` — both at module scope. Per the merged fact-check, this is once per module load, not per request. **Cold, and correctly so.**

The deployment split is what makes this a performance change rather than a pure refactor. Off-Vercel, `dataDir()` resolves bitwise-identically to the pre-diff constants (fact-check Claim 6), so paths 1-3 are unchanged. On Vercel, all three now target `/tmp`, which the merged fact-check establishes is **both wiped per cold start and private per concurrent instance**. That single fact drives the two most serious findings below, and — awkwardly — they pull in opposite directions: the same ephemerality that destroys cache hit rate (F1) is also what keeps the unbounded-growth cliff (F2) out of reach.

---

## Findings

#### F1 — LLM cache relocated to per-instance ephemeral storage; cost-of-miss is a paid API call

**Severity:** High
**Location:** `app/lib/llm/cache.ts:7` (`const CACHE_DIR = dataDir("cache");`), `app/lib/utils/dataDir.ts:13`
**Move:** (8) caches — hit-rate collapse where the cost-of-miss is real dollars; (7) contention across concurrent instances
**Classification:** Macro / Hot — evidence: `getCachedResult` is called on every `callLlm` (`callLlm.ts:125`) and every `streamLlm` (`streamLlm.ts:101`) invocation; these are the only paths that reach the LLM providers, so cache-hit rate is the primary determinant of user-visible latency and of spend.
**Confidence:** High for the mechanism (read end-to-end, corroborated 3/3 in fact-check Claim 3); Medium for the magnitude, which depends on unobserved production traffic and instance count.
**Baseline:** 246 recorded LLM calls as of 2026-04-16 (`docs/decisions/007-cost-estimation-model.md:60`, "Coefficients are based on 246 calls (2026-04-16)"). Per-miss cost from the repo's own pricing table (`app/lib/llm/costs.ts:14`, `claude-sonnet-4-6` at $3/M input, $15/M output) and median output tokens (`ENDPOINT_ESTIMATES`): a `decomposition/extract` miss = **$0.0375** (2100 output tok + ~2000 input tok); a full 8-endpoint Sonnet formalization sweep with all misses = **$0.2595** (14,100 output tokens).

**Evidence:**

> `const CACHE_DIR = dataDir("cache");`

(`app/lib/llm/cache.ts:7`)

> `const base = process.env.VERCEL ? "/tmp" : join(process.cwd(), "data");`

(`app/lib/utils/dataDir.ts:13`)

**Legibility-target:** for-author

The pre-diff cache lived on the deployment's `data/` directory — one store, durable across restarts. On Vercel it now lives on `/tmp`, which the fact-check establishes is private per warm instance *and* wiped per cold start. Hit rate therefore degrades on two independent axes: it decays toward zero as concurrent instance count rises (a request routed to instance B can never hit an entry written by instance A, so with *k* uniformly-loaded warm instances the steady-state hit probability for a repeated prompt is ~1/*k*), and it resets to zero on every cold start regardless of instance count. Because the miss is not a slow re-read but a billed provider call, the scaling factor lands directly on the invoice as well as on p95 latency: at 246 calls, a hit rate falling from (say) 40% to 10% is ~74 additional Sonnet calls, ~$2.8 at the per-miss figures above — small in absolute terms at current volume, but it scales linearly with traffic while the *codebase* looks like it has a working cache. The docstring at `dataDir.ts:7-8` describes only the cold-start axis, which is why this is easy to miss on review.

**Recommendation:** Keep `/tmp` as the fallback, but treat the Vercel cache as a *local* tier and add a shared one behind it (Vercel KV / Upstash Redis / any object store keyed by the existing sha256 hash — `computeHash` already produces a perfect cache key). If a shared tier is out of scope for now, at minimum amend the `dataDir()` docstring to state the per-instance property (fact-check Claim 3 flags the same gap as a documentation defect) and add a hit/miss counter to the analytics entries so the degradation is observable rather than inferred — `provider: "cache"` is already recorded on hits (`cache.ts:51`), so the data to measure this is one aggregation away.

---

#### F2 — Cache directory has no eviction, now writing to a small fixed-size volume; exhaustion fails silently

**Severity:** Medium
**Location:** `app/lib/llm/cache.ts:62-69` (`setCachedResult`), whole module — no eviction path exists
**Move:** (4) memory/resource lifecycle; (9) asymptotics — unbounded growth against a bounded budget
**Classification:** Macro / Hot — evidence: `setCachedResult` runs on every cache miss from both `callLlm.ts:94` and `streamLlm.ts:64`; growth is monotonic in total miss count with no bound in the code.
**Confidence:** Medium — the absence of eviction is High-confidence (`rg -n "evict|TTL|ttl|prune|maxAge|readdir|cleanup" app/lib/llm/ app/lib/analytics/` returns zero matches at this commit); the reachability of the cliff is Medium and depends on platform limits not stated in the repo.
**Baseline:** No measured cache-directory size available — `data/` is gitignored (`.gitignore:37`, `/data/`) and absent from the worktree, so **no baseline available — flagged as speculative** for the current on-disk footprint. Derived estimate only: at ~16.3 KiB per `callLlm`-path entry (see F5), **32,148 entries** fill a 512 MiB `/tmp` budget.

**Evidence:**

> ```
> export async function setCachedResult(
>   hash: string,
>   result: CachedResult
> ): Promise<void> {
>   await ensureCacheDir();
>   const filePath = join(CACHE_DIR, `${hash}.json`);
>   await writeFile(filePath, JSON.stringify(result, null, 2), "utf-8");
> }
> ```

(`app/lib/llm/cache.ts:62-69`)

> `try { await setCachedResult(cacheHash, result); } catch { /* cache write failure is non-fatal */ }`

(`app/lib/llm/callLlm.ts:94`)

**Legibility-target:** for-author

The cache is write-only-forever: one file per distinct prompt hash, never swept, never expired, never size-capped. That was tolerable when `CACHE_DIR` was a directory on a self-hosted disk measured in tens of gigabytes; the diff moves it to a volume measured in hundreds of megabytes. The failure mode when the budget is reached is the bad part: `writeFile` throws `ENOSPC`, `callLlm.ts:94` and `streamLlm.ts:64` swallow it into a bare `catch`, and the instance silently degrades to a 0% write rate — every subsequent call is a full-price miss, with no log line, no analytics entry, and no alarm. That is the exact silent-degradation class the parent commit 2136fd6 was written to eliminate.

I am rating this **Medium** rather than the Macro×Hot matrix default of High, and want the deviation on the record: the per-instance, per-cold-start ephemerality that drives F1 also *caps* accumulation, because `/tmp` empties long before 32k entries land in any single warm container. F1 and F2 are the same property viewed from two sides and cannot both bite hard on the same instance — the more F1 hurts, the further F2 recedes. Off-Vercel the growth is genuinely unbounded but the volume is large and the path is unchanged by this diff, so it is cold there.

**Recommendation:** Add a bounded-cache policy before the shared tier from F1 lands (the two are naturally the same piece of work): an LRU sweep on a size or file-count ceiling, or a TTL check inside `getCachedResult` using file mtime. Separately, and cheaply: give the `catch` at `callLlm.ts:94` / `streamLlm.ts:64` a `console.warn` so a cache that has stopped writing is visible in the function logs. Non-fatal should not mean invisible.

---

#### F3 — Synchronous `appendFileSync` on the LLM request path blocks the event loop

**Severity:** Medium
**Location:** `app/lib/analytics/persist.ts:17-20`, reached from `callLlm.ts:85`, `callLlm.ts:213`, `streamLlm.ts:56`, `streamLlm.ts:149`
**Move:** (5) file-access patterns on request paths; (3) work in the wrong place
**Classification:** Macro / Hot — evidence: every LLM call, streaming and non-streaming, writes one analytics line before returning; four call sites, all inside request handling.
**Confidence:** High that the calls are synchronous and on the request path (per the merged fact-check, this is a pre-existing pattern that the diff rewired rather than introduced); Medium on impact, which depends on per-instance request concurrency.
**Baseline:** **No baseline available — flagged as speculative.** No profiling data, event-loop-lag metric, or benchmark exists in the repo; the recorded `latencyMs` field measures provider latency (`callLlm.ts` usage construction), not persistence time.

**Evidence:**

> ```
> export function appendAnalyticsEntry(entry: AnalyticsEntry): void {
>   ensureDir();
>   appendFileSync(FILE_PATH, JSON.stringify(entry) + "\n", "utf-8");
> }
> ```

(`app/lib/analytics/persist.ts:17-20`)

**Legibility-target:** for-author

`appendFileSync` halts the Node event loop for the duration of an `open`/`write`/`close` triple, and `ensureDir()` adds an `existsSync` `stat` in front of it (see F6). On a single ~200-byte line this is sub-millisecond in the common case, but it is *serializing*: in a self-hosted deployment where one Node process fields many concurrent requests, every in-flight request pays for every other request's analytics write, and a slow or contended filesystem converts a background bookkeeping write into head-of-line blocking on user-facing traffic. The sibling module got this right — `cache.ts:2` imports from `fs/promises` and every cache operation is `await`ed without blocking. The diff is a natural moment to notice the asymmetry, since it was unifying these two modules' directory handling, and it left the two I/O styles divergent.

I flag it here rather than dismissing it as out-of-range because the rewiring changes the target volume's characteristics: `/tmp` on a Function is fast, but a self-hosted `<cwd>/data` on network-attached storage is not, and the diff is precisely what makes the two branches diverge.

**Recommendation:** Convert `persist.ts` to `fs/promises` (`appendFile`) and make `appendAnalyticsEntry` async — the four call sites are already inside `async` functions wrapped in `try`/`catch`, so the change is mechanical and the "must not break LLM calls" invariant is preserved. If the sync signature must stay for compatibility, at minimum drop the `existsSync` per F6.

---

#### F4 — `readAnalyticsEntries` reads and parses the entire history synchronously, with no pagination or rotation

**Severity:** Medium
**Location:** `app/lib/analytics/persist.ts:22-35`, reached from `app/api/analytics/route.ts:5`
**Move:** (9) asymptotics — O(N) in lifetime call count with no bound; (6) serialization tax; (2) size of N
**Classification:** Macro / Cold — evidence: `GET /api/analytics` fires once per mount of `useAnalytics` (`app/hooks/useAnalytics.ts:24-26`), i.e. per page load, not per LLM call; it is user-facing but low-frequency relative to path 1.
**Confidence:** High — the function is 14 lines, fully read, and its single consumer is traced.
**Baseline:** 246 entries at 2026-04-16 (`docs/decisions/007-cost-estimation-model.md:60`), ~200 bytes per `AnalyticsEntry` JSON line (9 fields, per `app/lib/types/analytics.ts:18-29`) → **~48 KiB**, i.e. entirely negligible today. Projected: 100,000 entries → **19.1 MiB** read and parsed synchronously per request.

**Evidence:**

> ```
> export function readAnalyticsEntries(): AnalyticsEntry[] {
>   if (!existsSync(FILE_PATH)) return [];
>   const content = readFileSync(FILE_PATH, "utf-8");
> ```

(`app/lib/analytics/persist.ts:22-24`)

**Legibility-target:** for-author

The endpoint has no `limit`, no `since`, and no cursor: it returns the entire history, and the client immediately reduces over all of it four times to build the summary (`useAnalytics.ts:37-42`). The file's only truncation is a manual `DELETE`. Growth is one line per LLM call forever, so the read cost, the parse cost, the JSON response size, and the client-side reduce all scale linearly with cumulative product usage — a 400× growth from today's 246 entries turns a 48 KiB blocking read into a 19 MiB one. There is a genuine irony worth naming: on Vercel, the diff *improves* this finding, because the per-cold-start wipe of `/tmp` caps N at "calls since this instance woke up." The unbounded case is the self-hosted path the diff deliberately preserves.

**Recommendation:** Add a `limit` query parameter (default a few hundred, newest-first) to `GET /api/analytics` and have `readAnalyticsEntries` read only the tail rather than the whole file; the client only needs recent entries plus aggregates. Longer term, keep a small rolling aggregate alongside the JSONL so the summary does not require reading every line. Neither is urgent at N=246 — this is a "fix before it is a problem" item, and the measured baseline says the problem is not here yet.

---

#### F5 — `callLlm` writes the full prompt into every cache file and never reads it back (~48% dead weight)

**Severity:** Low
**Location:** `app/lib/llm/callLlm.ts:92-95`, consumed by `app/lib/llm/cache.ts:62-69`, read at `cache.ts:43-55`
**Move:** (6) serialization tax; (4) resource lifecycle — inflates the budget F2 is competing for
**Classification:** Micro / Hot — evidence: on the write side, once per `callLlm` cache miss; the excess bytes are paid on every such write.
**Confidence:** High — the types and both call sites were read directly; the asymmetry between the two writers is visible in the source.
**Baseline:** Derived, not measured — **no baseline available for real cache files (`data/` is gitignored and absent), flagged as speculative.** Estimate at a 2000-token prompt and 2100-token response: ~16.3 KiB file of which ~8 KiB (**~48%**) is the never-read `cacheKey`.

**Evidence:**

> `const result: CallLlmResult = { text, usage, cacheKey };`
> `if (text) {`
> `  try { await setCachedResult(cacheHash, result); } catch { /* cache write failure is non-fatal */ }`

(`app/lib/llm/callLlm.ts:92-94`)

> `try { await setCachedResult(cacheHash, { text, usage }); } catch { /* non-fatal */ }`

(`app/lib/llm/streamLlm.ts:64`)

**Legibility-target:** for-author

`setCachedResult` declares its parameter as `CachedResult` = `{ text, usage }` (`cache.ts:9-12`), but `callLlm` passes a `CallLlmResult` variable, which also carries `cacheKey: { model, systemPrompt, userContent, maxTokens }` (`callLlm.ts:62-73`). TypeScript's excess-property check does not fire when the value arrives through a variable rather than an object literal, so the full system prompt and user content are `JSON.stringify`d to disk on every write. `getCachedResult` then casts the parsed file back to `CachedResult` and destructures only `text` and `usage` (`cache.ts:44-55`) — the prompt is written, never read, and is in any case already fully determined by the sha256 filename. `streamLlm.ts:64` passes a literal and so writes the lean shape, meaning the two paths produce files differing roughly 2× in size for the same logical cache entry. The scaling factor is a constant ~1.9× on cache-directory footprint for every `callLlm`-path entry, which halves the number of entries that fit in F2's `/tmp` budget.

**Recommendation:** Pass `{ text, usage }` explicitly at `callLlm.ts:94`, matching `streamLlm.ts:64`. One-line change, no behavior change on read (the field was never consumed), and it roughly doubles effective cache capacity per byte of `/tmp`.

---

#### F6 — `existsSync` on every analytics append; the sibling module's memoization was not carried over

**Severity:** Low
**Location:** `app/lib/analytics/persist.ts:11-15`, called from `persist.ts:18` and `persist.ts:38`
**Move:** (1) hidden multiplications — one extra syscall per LLM call
**Classification:** Micro / Hot — evidence: `ensureDir()` runs inside `appendAnalyticsEntry`, which is on every LLM call from four sites.
**Confidence:** High — both modules read in full; the divergence is direct.
**Baseline:** **No baseline available — flagged as speculative.** A `stat` on a warm dentry cache is on the order of a microsecond; there is no measurement in the repo.

**Evidence:**

> ```
> function ensureDir() {
>   if (!existsSync(DATA_DIR)) {
>     mkdirSync(DATA_DIR, { recursive: true });
>   }
> }
> ```

(`app/lib/analytics/persist.ts:11-15`)

> ```
> let dirEnsured = false;
> async function ensureCacheDir() {
>   if (dirEnsured) return;
>   await mkdir(CACHE_DIR, { recursive: true });
>   dirEnsured = true;
> }
> ```

(`app/lib/llm/cache.ts:27-32`)

**Legibility-target:** for-author

`cache.ts` solved this exact problem with a process-scoped boolean: one `mkdir` per process, zero syscalls thereafter, and `mkdir { recursive: true }` is already idempotent so the `existsSync` guard buys nothing but a syscall. `persist.ts` re-`stat`s the directory on every single append. The multiplication is 1 extra syscall × every LLM call — genuinely small in absolute terms, which is why this is Low, but it is free to remove and the correct pattern is sitting in the file the diff was unifying `persist.ts` with. `docs/plans/refactoring-plan.md:38` already flags this shape of problem (its specific claim about `cache.ts` is stale per fact-check Claim 12 — `cache.ts` was fixed and `persist.ts` was not, which is exactly the drift being described).

**Recommendation:** Mirror the `dirEnsured` pattern in `persist.ts`, or simply drop the `existsSync` and call `mkdirSync(DATA_DIR, { recursive: true })` unconditionally — it is a no-op when the directory exists and removes the TOCTOU window as a bonus.

---

#### F7 — `dataDir()` re-resolves `process.env` and re-`join`s per call; the variadic signature invites hot-path use

**Severity:** Informational
**Location:** `app/lib/utils/dataDir.ts:12-15`
**Move:** (3) work in the wrong place — latent, not actual
**Classification:** Micro / Cold — evidence: per the merged fact-check, `dataDir()` is called at module scope in both consumers (`persist.ts:8`, `cache.ts:7`), i.e. twice per process lifetime, not per request. `rg` confirms no other call sites in the repo.
**Confidence:** High — the function is 4 lines and both call sites are traced.
**Baseline:** **No baseline available — flagged as speculative.** Two calls per process is below any measurement threshold.

**Evidence:**

> ```
> export function dataDir(...subpaths: string[]): string {
>   const base = process.env.VERCEL ? "/tmp" : join(process.cwd(), "data");
>   return subpaths.length > 0 ? join(base, ...subpaths) : base;
> }
> ```

(`app/lib/utils/dataDir.ts:12-15`)

**Legibility-target:** for-author

As written and as currently called, this costs nothing — flagged purely as a shape observation. `process.env` property access in Node is not a plain object read; it goes through a host getter that queries the real environment, and `process.cwd()` is a syscall. Both are re-executed on every call, and neither result can change during a process's life. The variadic signature is the reason to mention it: commit b64c1ca's own message advertises `dataDir("x")` as the pattern for future persistence code, which invites a future call like `dataDir("cache", hash)` from inside `getCachedResult` — at which point a syscall plus an env lookup lands on the hottest path in the app, and nothing in the function's shape discourages it.

**Recommendation:** Hoist the base to a module-level `const` computed once (`const BASE = process.env.VERCEL ? "/tmp" : join(process.cwd(), "data");`) so the function becomes a pure `join`. That makes per-request use harmless and costs one line. Note the tradeoff: it freezes the env read at module load, which is already the effective behavior at both current call sites and is fine for a deploy-time-constant like `VERCEL`, but would break any test that mutates `process.env.VERCEL` after import — worth a comment either way.

---

#### F8 — Cache files are pretty-printed with 2-space indentation

**Severity:** Informational
**Location:** `app/lib/llm/cache.ts:68`
**Move:** (6) serialization tax
**Classification:** Micro / Hot — evidence: executed on every cache write from both LLM paths.
**Confidence:** High — single line, unambiguous.
**Baseline:** **No baseline available — flagged as speculative.** Derived: on a text-dominated entry the indentation overhead is ~1-2% of bytes; on the small `usage`/metadata object alone it is ~30-40%.

**Evidence:**

> `await writeFile(filePath, JSON.stringify(result, null, 2), "utf-8");`

(`app/lib/llm/cache.ts:68`)

**Legibility-target:** for-author

`null, 2` costs extra CPU in `stringify` and extra bytes on a volume that F2 establishes is now size-capped, in exchange for human-readability of a sha256-named machine cache that no human navigates by hand. The effect is genuinely tiny because the entries are dominated by the response text, which is why this is Informational rather than Low — it is listed for completeness alongside F5, the other avoidable inflation of the same budget. Fixing F5 matters ~40× more than fixing this.

**Recommendation:** Drop the pretty-printing (`JSON.stringify(result)`) unless someone is actually inspecting cache files during development, in which case leave it and note why. Not worth a standalone change; fold it in if F5 is addressed.

---

## What Looks Good

- **`dataDir()` is called at module scope in both consumers**, not per request (`persist.ts:8`, `cache.ts:7`). The most obvious way to get this refactor wrong — turning a compile-time constant into a per-call function invocation on the hot path — was avoided. This is the single most important thing the diff got right.
- **Path resolution is bitwise-identical off-Vercel** (fact-check Claim 6, verified 3/3). Dev and self-hosted deployments have zero performance delta from this change; the entire risk surface is Vercel-only, which makes the change easy to reason about and easy to revert.
- **`cache.ts` uses `fs/promises` throughout** (`cache.ts:2`) and the rewiring preserved that. The non-blocking style on the hotter of the two modules is the right allocation of care, and it is a standing example for F3's recommendation.
- **The `dirEnsured` memoization survives the base-directory change correctly** (`cache.ts:27-32`). It is process-scoped, and both `/tmp/cache` and `<cwd>/data/cache` reset together with the process, so the flag can never go stale against the wrong directory — a real hazard that this refactor happened not to introduce.
- **`computeHash` is computed once and reused for both the get and the set** (`callLlm.ts:122`, with the comment "Compute hash once, reuse for cache get and set"). sha256 over a multi-kilobyte prompt is the most expensive pure-CPU operation on the path; doing it once rather than twice is exactly right, and the comment documents the intent.
- **Zero new dependencies and zero new I/O calls** (fact-check Claim 10; diff stat: 3 files, 21 insertions). The refactor is genuinely subtractive — it collapses two duplicated inline ternaries into one helper — and carries no hidden cost of its own.

---

## Summary Table

| ID | Finding | Severity | Class | Temp. | Confidence | Baseline |
|----|---------|----------|-------|-------|-----------|----------|
| F1 | LLM cache on per-instance ephemeral `/tmp`; hit-rate collapse, cost-of-miss is a paid API call | High | Macro | Hot | High (mech.) / Med (mag.) | 246 calls @ 2026-04-16; $0.0375/miss, $0.2595/sweep |
| F2 | No cache eviction, now on a fixed-size volume; exhaustion fails silently | Medium | Macro | Hot | Medium | Speculative (derived: 32,148 entries fill 512 MiB) |
| F3 | `appendFileSync` blocks the event loop on every LLM call | Medium | Macro | Hot | High (mech.) / Med (impact) | No baseline available — speculative |
| F4 | Whole-history sync read + parse per `GET /api/analytics`; no pagination or rotation | Medium | Macro | Cold | High | 246 entries ≈ 48 KiB today; 100k ≈ 19.1 MiB |
| F5 | `callLlm` writes the full prompt into every cache file, never reads it back | Low | Micro | Hot | High | Speculative (derived: ~48% of ~16.3 KiB) |
| F6 | `existsSync` per append; `cache.ts`'s memoization not carried over | Low | Micro | Hot | High | No baseline available — speculative |
| F7 | `dataDir()` re-reads `process.env`/`cwd()` per call; variadic shape invites hot-path use | Informational | Micro | Cold | High | No baseline available — speculative |
| F8 | Cache files pretty-printed with 2-space indent | Informational | Micro | Hot | High | Speculative (derived: ~1-2% of bytes) |

**Severity derivation:** the matrix (Macro×Hot=High, Macro×Cold=Medium, Micro×Hot=Low-Medium, Micro×Cold=Informational) is applied as written for F1, F3, F4, F5, F6, F7, F8. **F2 is a deliberate one-step downgrade from High to Medium**, justified in the finding: `/tmp`'s ephemerality (the cause of F1) caps accumulation well below the exhaustion threshold, so F1 and F2 cannot both bite hard on the same instance.

---

## Overall Assessment

This is a small, well-executed refactor with one significant performance consequence that lives entirely outside the diff's stated intent. As a refactor it is clean: 21 lines, no new dependencies, no new I/O, identical path resolution off-Vercel, and — critically — the helper is invoked at module scope rather than per request, so the abstraction costs nothing at runtime. Judged against its own goal ("no behavior change off-Vercel"), it succeeds completely.

The performance story is on the Vercel branch, and it is F1. Relocating the LLM cache to `/tmp` converts a durable shared cache into a per-instance, per-cold-start scratch cache whose misses are billed provider calls at roughly $0.04 each. The change is correct in the sense that the previous code could not write at all on Vercel — a broken cache is strictly worse than an ephemeral one — so this is not a regression against the deployed state so much as a design point that the codebase now silently occupies. What makes it worth flagging at High is that nothing in the code or the docstring signals it: `dataDir.ts:7-8` describes only the cold-start axis, the miss path is indistinguishable from a hit path in the logs, and the `catch` blocks around every cache write ensure that total cache failure is invisible. The independent fact-check flagged the same documentation gap from a different direction (Claim 3, unanimous 3/3), which is corroborating rather than coincidental.

F2, F3, F4, F5, and F6 are all pre-existing patterns that the diff rewired rather than introduced. I have reported them because the rewiring changes their operating conditions — a no-eviction cache behaves differently on a 512 MiB volume than on a self-hosted disk, and a synchronous append behaves differently on tmpfs than on network storage — but none of them is a reason to hold this change. F4 in particular is a "not yet" finding: at the measured baseline of 246 entries the whole-history read is 48 KiB and entirely fine.

If only one thing is done: add observability before optimization. `provider: "cache"` is already recorded on every hit (`cache.ts:51`), so the hit rate is one aggregation away from being a number rather than a hypothesis, and a `console.warn` in the two swallowed cache-write catches would surface F2's silent-failure mode for free. Both are smaller than the fixes they would justify, and both would replace the several "no baseline available — flagged as speculative" entries in the table above with measurements.

---

## Goal-Alignment Note

- **Answered:** All nine briefed cognitive moves, applied to the diff and its blast radius. Hidden multiplications (F6); size of N (F4, with a measured baseline of 246 entries from decision 007); work in the wrong place (F3, F7); memory/resource lifecycle (F2); file-access patterns — synchronous fs in `persist.ts` and cache read/write per LLM call (F3, F4, F1); serialization tax (F5, F8); contention across shared files and concurrent instances (F1, F2); the LLM cache on ephemeral `/tmp` with a real-dollar cost-of-miss (F1, the headline finding); asymptotics (F2, F4). The hot-path gate was applied: the sole High is on a confirmed hot path (`getCachedResult` on every `callLlm`/`streamLlm`) with the temperature evidence stated inline, and no Critical was issued because the growth is bounded by user traffic rather than unbounded. Every finding carries either a measured number with units and source or the literal speculative flag.
- **Out of scope:** Correctness and documentation accuracy of the `dataDir()` docstring and the dangling "Deploy to Vercel" README reference — owned by the fact-check (Claims 2, 3), consumed here as foundation and not re-verified. Security of `/tmp` as a store for prompt contents. Whether per-instance persistence is architecturally right (an architecture-critic question; I evaluated only its cost). Dynamic verification — no tests, benchmarks, or profiling were run, so all latency and footprint figures are derived from the repo's own pricing table, `ENDPOINT_ESTIMATES`, and decision 007's measured call count, never observed. Anything newer than b64c1ca.
- **Escalate:** F1 to whoever owns the Vercel deployment decision — the per-instance cache property is undocumented in the repo, the degradation is unobservable in the current logging, and the cost lands on a provider invoice rather than a latency dashboard, so it is unlikely to be noticed by the usual feedback loops. Secondary: F2's silent `ENOSPC` swallowing shares a root with the fact-check's Claim 9 finding about over-broad `catch` blocks — the two reviews independently identified the same silent-degradation surface in `app/lib/llm/`, which suggests the error-handling posture in that module, not any single call site, is the thing worth revisiting.
