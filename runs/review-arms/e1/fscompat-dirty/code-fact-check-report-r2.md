# Code Fact-Check Report

**Repository:** meta-formalism-copilot (pinned worktree /workspace/runs/review-arms/e1/wt-fscompat-dirty, detached at b64c1ca)
**Scope:** `git diff d86d2dc..b64c1ca` — new `app/lib/utils/dataDir.ts` helper plus rewiring of `app/lib/analytics/persist.ts` and `app/lib/llm/cache.ts`; commit messages 2136fd6 and b64c1ca
**Checked:** comments/docstrings in the three diffed files; both commit messages; callers (`callLlm.ts`, `streamLlm.ts`, `artifactRoute.ts`, `app/api/analytics/route.ts`); README; static test-case count
**Total claims checked:** 10
**Summary:** 5 Verified, 3 Mostly accurate, 1 Incorrect, 1 Unverifiable. The one Incorrect finding is a dangling documentation reference: two comments point readers to a "Deploy to Vercel" section of the README that does not exist anywhere in the repo at this commit (no file mentions "Vercel" outside the diffed code). The Mostly-accurate findings are completeness gaps: the dataDir() docstring attributes data loss solely to cold starts and omits that concurrent Vercel instances each have an independent `/tmp` (so analytics/cache are per-instance even while warm), and the 2136fd6 claim that failed writes were "silently swallowed by upstream try/catch" is true for the LLM call paths but not for the unguarded `DELETE /api/analytics` route.

**Commit:** b64c1ca

## Claim 1: persist.ts — "analytics history doesn't persist across cold starts — see Deploy to Vercel in README"

**Location:** app/lib/analytics/persist.ts:6-7
**Type:** Behavioral + reference claim
**Verdict:** Incorrect
**Confidence:** High — the behavioral half is directly traceable through `dataDir()`, and the reference half was checked with a repo-wide case-insensitive grep.
**Legibility-target:** for-author

The comment reads:

> `// On Vercel, analytics history doesn't persist across cold starts — see`
> `// Deploy to Vercel in README. See dataDir() for the underlying rationale.` (app/lib/analytics/persist.ts:6-7)

**Behavioral half — accurate.** `DATA_DIR = dataDir()` (app/lib/analytics/persist.ts:8), and `dataDir()` resolves to `/tmp` when `process.env.VERCEL` is truthy: `const base = process.env.VERCEL ? "/tmp" : join(process.cwd(), "data");` (app/lib/utils/dataDir.ts:13). Vercel Functions' `/tmp` is instance-local ephemeral storage that is discarded with the container, so analytics written there is lost on cold start. Paraphrased — no quote available because the `/tmp` lifetime is Vercel platform behavior, not represented in this repo.

**Reference half — incorrect.** The README at this commit has no "Deploy to Vercel" section and no mention of Vercel at all. Its full heading list is: `# Metaformalism Copilot`, `## What is this?`, `### The Philosophy: Live Theory`, `### How it works`, `## Getting Started`, `### Prerequisites`, `### Install and run`, `### Lean Verification Service`, `## Available Scripts`, `## How to Contribute`, `## Project Documentation`, `## Questions or Issues?`, `## License` (README.md:1-119, heading grep). A repo-wide `rg -ril "vercel" --glob '!node_modules'` returns no files — the only occurrences of "Vercel" anywhere in the repo are in the three diffed source files and the two commit messages. Readers are directed to documentation that does not exist. (This same dangling reference was introduced in 2136fd6's version of the comment and carried forward by b64c1ca.)

**Evidence:**
- app/lib/utils/dataDir.ts:13 — `const base = process.env.VERCEL ? "/tmp" : join(process.cwd(), "data");`
- README.md heading grep (all 13 headings listed above) — no Vercel/deploy section
- `rg -ril "vercel"` across the worktree (excluding node_modules) — zero matching files

## Claim 2: dataDir.ts docstring — "/tmp only writable on Vercel Functions, lives only as long as the warm container, so persistence does not survive cold starts"

**Location:** app/lib/utils/dataDir.ts:7-10
**Type:** Behavioral/platform claim (completeness check requested)
**Verdict:** Mostly accurate
**Confidence:** Medium — the code path is fully verifiable; the platform semantics (writability, instance concurrency) rest on general Vercel Functions knowledge, not anything checkable in-repo.
**Legibility-target:** for-author

The docstring reads:

> `* On Vercel Functions only `/tmp` is writable, and it lives only as long as`
> `* the warm container — so persistence does not survive cold starts.` (app/lib/utils/dataDir.ts:8-9)

What it says is true: on Vercel Functions the deployment bundle filesystem is read-only and `/tmp` is the writable scratch area, scoped to the function instance's lifetime. Paraphrased — no quote available because this is Vercel platform behavior, not represented in the repo.

What it omits is material to this app's two consumers: Vercel scales functions to **multiple concurrent instances, each with its own `/tmp`**. So even with zero cold starts:

- *Analytics*: `appendAnalyticsEntry` (app/lib/analytics/persist.ts:17-20) appends to whichever instance served the LLM call, while `GET /api/analytics` — `const entries = readAnalyticsEntries();` (app/api/analytics/route.ts:5) — reads only the file on the instance that happened to serve the GET. Under any concurrency, the analytics panel shows an arbitrary per-instance slice of history, not merely "history that resets on cold start".
- *LLM cache*: `getCachedResult` (app/lib/llm/cache.ts:34-60) hits only if the same instance previously wrote that hash; cross-instance requests are guaranteed misses.

The docstring's "lives only as long as the warm container" frames cold starts as the sole durability limit; per-instance partitioning is an equally real one for this app. Fine as a rationale for choosing `/tmp`; incomplete as a description of the resulting behavior.

**Evidence:**
- app/lib/utils/dataDir.ts:8-9 — docstring quoted above
- app/api/analytics/route.ts:5 — `const entries = readAnalyticsEntries();`
- app/lib/llm/cache.ts:41 — `const filePath = join(CACHE_DIR, `${hash}.json`);` (per-instance file lookup)
- Multiple-concurrent-instance behavior: paraphrased — no quote available because it is Vercel platform behavior external to the repo

## Claim 3: dataDir.ts docstring — "In dev and self-hosted deployments we write to the repo's `data/` dir for durable cross-restart storage"

**Location:** app/lib/utils/dataDir.ts:9-11
**Type:** Behavioral/configuration claim
**Verdict:** Verified
**Confidence:** High — single-expression function, both branches read directly.

The implementation is exactly the described branch:

> `const base = process.env.VERCEL ? "/tmp" : join(process.cwd(), "data");` (app/lib/utils/dataDir.ts:13)

When `VERCEL` is unset (dev via `npm run dev`, self-hosted `next start` from the repo root), `process.cwd()` is the repo root, so the base is the repo's `data/` dir; it persists across restarts because it is ordinary disk. Two pedantic caveats, neither rising to a verdict change: (a) it is `cwd`-relative, so a self-hosted deploy launched from a different working directory would get `<cwd>/data`, not the repo's dir — Next.js standard invocations run from the project root; (b) the gate is truthiness of `VERCEL`, so a self-hosted environment that exports `VERCEL` for any reason would silently switch to `/tmp`. Paraphrased — no quote available for the cwd semantics because they are Node.js/Next.js runtime behavior, not code in this repo.

**Evidence:**
- app/lib/utils/dataDir.ts:12-15 — full function body:
  ```ts
  export function dataDir(...subpaths: string[]): string {
    const base = process.env.VERCEL ? "/tmp" : join(process.cwd(), "data");
    return subpaths.length > 0 ? join(base, ...subpaths) : base;
  }
  ```

## Claim 4: Mixed call conventions — `dataDir("cache")` vs `join(dataDir(), ...)` both resolve to the intended paths

**Location:** app/lib/llm/cache.ts:7 and app/lib/analytics/persist.ts:8-9
**Type:** Behavioral/invariant claim (from the brief; also underpins b64c1ca's "no behavior change")
**Verdict:** Verified
**Confidence:** High — pure path arithmetic against the pre-refactor constants.

- `const CACHE_DIR = dataDir("cache");` (app/lib/llm/cache.ts:7) → `join("/tmp", "cache")` = `/tmp/cache` on Vercel, `join(cwd, "data", "cache")` otherwise — identical to the pre-refactor `process.env.VERCEL ? "/tmp/cache" : join(process.cwd(), "data", "cache")` (git show 2136fd6, app/lib/llm/cache.ts).
- `const DATA_DIR = dataDir();` + `const FILE_PATH = join(DATA_DIR, "analytics.jsonl");` (app/lib/analytics/persist.ts:8-9) → `/tmp/analytics.jsonl` or `<cwd>/data/analytics.jsonl` — identical to the pre-refactor `process.env.VERCEL ? "/tmp" : join(process.cwd(), "data")`.

No comment or doc in the diff claims the two call conventions are uniform, so the stylistic asymmetry (subpath argument vs. caller-side `join`) is not a documentation error — nothing to flag beyond noting both resolve correctly.

**Evidence:**
- app/lib/llm/cache.ts:7 — `const CACHE_DIR = dataDir("cache");`
- app/lib/analytics/persist.ts:8-9 — `const DATA_DIR = dataDir();` / `const FILE_PATH = join(DATA_DIR, "analytics.jsonl");`
- Pre-refactor constants quoted from `git show 2136fd6` in Claim 6's evidence

## Claim 5: persist.ts / cache.ts error-handling comments after rewiring

**Location:** app/lib/llm/cache.ts:57, cache.ts:82; app/lib/llm/callLlm.ts:91,94,219; app/lib/llm/streamLlm.ts:62,64
**Type:** Behavioral claims in touched modules
**Verdict:** Verified
**Confidence:** High — each catch block read in place with its guarded call.

The base-dir change does not invalidate any of the error-path comments:

- `// Corrupt or missing cache file — treat as miss` (app/lib/llm/cache.ts:57) — the whole `readFile`+`JSON.parse` is inside `try { ... } catch { return null; }` (cache.ts:43-59); a missing `/tmp/cache/<hash>.json` after a cold start lands here and returns a miss, exactly as described.
- `// File doesn't exist — nothing to remove` (app/lib/llm/cache.ts:82) — `unlink` failures are swallowed (cache.ts:79-83); still accurate.
- `} catch { /* persistence failure must not break LLM calls */ }` (app/lib/llm/callLlm.ts:91, callLlm.ts:219; same pattern app/lib/llm/streamLlm.ts:62) and `try { await setCachedResult(...); } catch { /* cache write failure is non-fatal */ }` (callLlm.ts:94; streamLlm.ts:64) — all four analytics-append sites and both cache-write sites remain wrapped, so the comments match behavior with the new base dir.
- `ensureDir()` (app/lib/analytics/persist.ts:11-15) and `ensureCacheDir()` (app/lib/llm/cache.ts:27-32) carry no comments, so nothing to drift. Note `ensureCacheDir`'s `dirEnsured` memo is per-process, which is fine: `/tmp/cache` outliving or not outliving the process tracks the flag correctly since both reset together.

**Evidence:**
- app/lib/llm/cache.ts:56-59 — `} catch { // Corrupt or missing cache file — treat as miss \n return null; }`
- app/lib/llm/callLlm.ts:94 — `try { await setCachedResult(cacheHash, result); } catch { /* cache write failure is non-fatal */ }`
- app/lib/llm/streamLlm.ts:55-64 — try-wrapped `appendAnalyticsEntry` and `setCachedResult` calls

## Claim 6: Commit 2136fd6 — "data/ … is read-only on Vercel Functions"; "Writes were silently swallowed by upstream try/catch — features just degraded with no indication"; "Local dev is unchanged"

**Location:** commit 2136fd642, message body
**Type:** Behavioral + architectural claims
**Verdict:** Mostly accurate
**Confidence:** High for the try/catch audit (every caller grepped and read); Medium for the read-only-bundle platform claim (external to repo).
**Legibility-target:** for-author

- **"read-only on Vercel Functions"** — consistent with Vercel's read-only deployment bundle. Paraphrased — no quote available because it is platform behavior.
- **"Writes were silently swallowed by upstream try/catch"** — true for the LLM paths: all four `appendAnalyticsEntry` call sites (callLlm.ts:84-91, callLlm.ts:212-219, streamLlm.ts:55-62, streamLlm.ts:148ff) and both `setCachedResult` sites (callLlm.ts:94, streamLlm.ts:64) sit in bare `catch` blocks with no logging, and `getCachedResult`'s failed reads return `null` (cache.ts:56-59). **But not universally true:** `DELETE /api/analytics` calls `clearAnalyticsEntries();` (app/api/analytics/route.ts:10) with no try/catch, and `clearAnalyticsEntries` does `ensureDir(); writeFileSync(FILE_PATH, "", "utf-8");` (app/lib/analytics/persist.ts:37-40) — on read-only `data/` (pre-2136fd6 on Vercel) `mkdirSync`/`writeFileSync` would throw and the route would 500, which is an indication, not silent swallowing. The "silently … no indication anything was off" claim over-generalizes from the LLM paths.
- **"Local dev is unchanged"** — verified: the non-`VERCEL` branch of every changed constant reproduces the previous path exactly (see Claim 4).

**Evidence:**
- app/api/analytics/route.ts:9-12 — `export async function DELETE() { clearAnalyticsEntries(); return NextResponse.json({ ok: true }); }` (no try/catch)
- app/lib/analytics/persist.ts:37-40 — `export function clearAnalyticsEntries(): void { ensureDir(); writeFileSync(FILE_PATH, "", "utf-8"); }`
- app/lib/llm/callLlm.ts:91 — `} catch { /* persistence failure must not break LLM calls */ }`
- Caller inventory via `rg -n "appendAnalyticsEntry|readAnalyticsEntries|clearAnalyticsEntries|getCachedResult|setCachedResult|removeCachedResult"` — no call sites beyond those cited (plus mocks in streamLlm.test.ts and the guarded `removeCachedResult` at app/lib/formalization/artifactRoute.ts:104)

## Claim 7: Commit b64c1ca — "Both analytics and LLM cache had the same Vercel/dev branching pattern inline"

**Location:** commit b64c1cad, message body
**Type:** Architectural/staleness claim
**Verdict:** Verified
**Confidence:** High — parent-commit state read directly.

At the parent commit both files contained the same inline ternary on `process.env.VERCEL`:

- `const DATA_DIR = process.env.VERCEL ? "/tmp" : join(process.cwd(), "data");` (git show 2136fd6, app/lib/analytics/persist.ts)
- `const CACHE_DIR = process.env.VERCEL ? "/tmp/cache" : join(process.cwd(), "data", "cache");` (git show 2136fd6, app/lib/llm/cache.ts)

"Shrinks comment duplication" also checks out: the two near-duplicate 3-4 line Vercel-rationale comments were consolidated into the dataDir() docstring, with persist.ts keeping a shorter pointer comment.

**Evidence:**
- `git show 2136fd6 -- app/lib/analytics/persist.ts app/lib/llm/cache.ts` — both ternaries quoted above

## Claim 8: Commit b64c1ca — "No behavior change; both DATA_DIR and CACHE_DIR resolve to the same paths they did before"

**Location:** commit b64c1cad, message body
**Type:** Invariant claim
**Verdict:** Verified
**Confidence:** High — path equivalence shown by direct substitution in Claim 4.

`dataDir()` = `process.env.VERCEL ? "/tmp" : join(cwd, "data")` and `dataDir("cache")` = `join(that, "cache")` reproduce the two pre-refactor ternaries value-for-value in both branches. The helper introduces no new observable behavior (no caching of the env read at a different time — both old and new code evaluate `process.env.VERCEL` once at module load).

**Evidence:**
- app/lib/utils/dataDir.ts:12-15 (quoted in Claim 3) vs. pre-refactor constants (quoted in Claim 7)

## Claim 9: Commit b64c1ca — "makes future server-side persistence trivially correct (dataDir(\"x\"))"

**Location:** commit b64c1cad, message body
**Type:** Architectural claim (borderline intent/opinion)
**Verdict:** Verified
**Confidence:** Medium — the mechanism is checkable; "trivially correct" is partly judgment.

The variadic signature `export function dataDir(...subpaths: string[]): string` (app/lib/utils/dataDir.ts:12) does give any future consumer the correct Vercel/dev branching by construction, as `cache.ts` already demonstrates. The judgment word "trivially" is not checkable; the mechanism it describes exists as claimed. (Noting for-orchestrator context: `persist.ts` itself does not use the subpath form — it joins the filename at the caller — so the "trivially correct" pattern is a convention, not enforced.)

**Evidence:**
- app/lib/utils/dataDir.ts:12 — `export function dataDir(...subpaths: string[]): string {`
- app/lib/llm/cache.ts:7 — `const CACHE_DIR = dataDir("cache");`

## Claim 10: Commit b64c1ca — "Lint clean; 221/221 tests pass"

**Location:** commit b64c1cad, message body
**Type:** Test/verification claim
**Verdict:** Unverifiable
**Confidence:** Medium — cannot execute vitest/eslint (static verification only, no node_modules run), but the test count was corroborated statically.

The pass/clean outcomes cannot be re-run here. However, the headline number is exactly corroborated by static counting: `rg -o "^\s*(it|test)\(" -g '*.test.*'` across the worktree returns **221** test cases over 24 test files, and a grep for `it.each|test.each|it.skip|describe.each` returns nothing that would make the static count diverge from the runtime count. So "221" matches the repo state precisely; whether all 221 passed and lint was clean at commit time is not statically checkable.

**Evidence:**
- `rg -o "^\s*(it|test)\(" -g '*.test.*' --glob '!node_modules' | wc -l` → `221`
- `rg -n "it\.each|test\.each|it\.skip|describe\.each" -g '*.test.*'` → no matches
- package.json:9,11 — `"lint": "eslint"`, `"test:watch": "vitest"` (tooling the claim refers to)

## Claims Requiring Attention

### Incorrect
- **Claim 1** (app/lib/analytics/persist.ts:6-7): comment directs readers to a "Deploy to Vercel" section of the README, but the README at b64c1ca contains no such section and no file in the repo mentions Vercel. Fix: either add the README section (2136fd6/b64c1ca read as if it was planned) or drop the reference and rely on the dataDir() docstring pointer.

### Stale
- None.

### Mostly Accurate
- **Claim 2** (app/lib/utils/dataDir.ts:7-10): docstring attributes persistence loss solely to cold starts; omits that concurrent Vercel instances each have an independent `/tmp`, so analytics reads and cache hits are per-instance even while warm. One added clause would close the gap.
- **Claim 6** (commit 2136fd6): "writes were silently swallowed by upstream try/catch" holds for all LLM-path call sites but not for `DELETE /api/analytics` → `clearAnalyticsEntries()`, which is unguarded and would have thrown (500) rather than degrading silently.

### Unverifiable
- **Claim 10** (commit b64c1ca): "Lint clean; 221/221 tests pass" — run results not reproducible statically; the 221 test-case count matches the repo exactly, which is weak positive corroboration.

## Goal-Alignment Note
- Answered: All six briefed items — README reference (Claim 1), /tmp completeness incl. concurrent instances (Claim 2), env-check branches (Claim 3), mixed call conventions and path resolution (Claim 4), both commit messages' checkable statements incl. test/lint claims (Claims 6-10), and post-rewiring error-path comments (Claim 5).
- Out of scope: A pre-existing stale claim in docs/plans/refactoring-plan.md:38 ("`cache.ts`: `ensureCacheDir` calls `existsSync` before `mkdirSync` on every write") describes code that does not exist at b64c1ca — `ensureCacheDir` (cache.ts:27-32) uses a `dirEnsured` boolean and never calls `existsSync`, and this was already true at d86d2dc, so it is outside the reviewed range; noting it here for the orchestrator rather than as a numbered claim. Also out of scope: whether /tmp-on-Vercel is the right design (review judgment, not fact-checking).
- Escalate: The missing "Deploy to Vercel" README section (Claim 1) is both a doc bug and a signal that a planned documentation task was dropped between 2136fd6 and b64c1ca — worth a synthesis-level flag since CLAUDE.md's Documentation Maintenance section explicitly requires README updates for user-facing deployment behavior changes in the same PR.
