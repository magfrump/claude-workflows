# Code Fact-Check Report

**Repository:** meta-formalism-copilot (pinned worktree /workspace/runs/review-arms/e1/wt-fscompat-dirty, detached at b64c1ca)
**Scope:** `git diff d86d2dc..b64c1ca` — extraction of `dataDir()` helper (app/lib/utils/dataDir.ts) and rewiring of app/lib/analytics/persist.ts and app/lib/llm/cache.ts; commit messages 2136fd6 and b64c1ca
**Checked:** 2026-08-06
**Total claims checked:** 13
**Summary:** 7 Verified, 4 Mostly accurate, 1 Incorrect, 1 Unverifiable. The one Incorrect finding — flagged unanimously by all three replicates — is a dangling documentation reference: persist.ts points readers to a "Deploy to Vercel" section of the README that does not exist anywhere in the repo at this commit (no file outside the diffed code mentions Vercel at all). The Mostly-accurate findings are completeness gaps: the dataDir() docstring and the 2136fd6 tradeoff paragraph attribute data loss solely to cold starts and omit per-instance `/tmp` isolation across concurrent Vercel instances; 2136fd6's "writes were silently swallowed by upstream try/catch" holds for the LLM paths but not the unguarded `DELETE /api/analytics` route; and cache.ts's "Corrupt or missing cache file" catch comment is narrower than the catch it annotates. Path-resolution and no-behavior-change claims check out exactly in all replicates.

**Commit:** b64c1ca
**Replication:** k=3 (independent code-fact-check replicates merged mechanically, most-severe verdict wins per cluster)

## Claim 1: Analytics history doesn't persist across cold starts on Vercel

**Location:** app/lib/analytics/persist.ts:6-7
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High — mechanism read end-to-end in this repo; the Vercel-platform half matches well-established platform behavior.
**Legibility-target:** for-orchestrator-synthesis

> // On Vercel, analytics history doesn't persist across cold starts — see
> // Deploy to Vercel in README. See dataDir() for the underlying rationale.

(persist.ts:6-7)

The persistence half of the comment is accurate. `DATA_DIR = dataDir()` (persist.ts:8), and `dataDir()` resolves to `/tmp` when `process.env.VERCEL` is truthy: `const base = process.env.VERCEL ? "/tmp" : join(process.cwd(), "data");` (app/lib/utils/dataDir.ts:13). Analytics entries are appended to `join(DATA_DIR, "analytics.jsonl")` (persist.ts:9), i.e. `/tmp/analytics.jsonl` on Vercel, which is instance-local ephemeral storage — lost on cold start. Vercel sets `VERCEL=1` in its build and runtime environments (paraphrased — platform behavior outside the repo). The README-reference half of this comment is Claim 2. Replicates r2 and r3 assessed this assertion inside a combined claim whose headline verdict (Incorrect) was explicitly keyed to the reference half; both state the behavioral half is accurate.

**Evidence:** app/lib/analytics/persist.ts:6-9; app/lib/utils/dataDir.ts:13.
**Replicate verdicts:** r1=Verified · r2=Verified (behavioral half of its combined Claim 1) · r3=Verified (behavioral half of its combined Claim 1)

## Claim 2: "see Deploy to Vercel in README"

**Location:** app/lib/analytics/persist.ts:6-7
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High — exhaustive repo-wide grep at this commit, replicated in all three passes.
**Legibility-target:** for-author

The comment directs readers to a "Deploy to Vercel" section of the README. No such section exists at b64c1ca. The README's full heading list is:

> `# Metaformalism Copilot` / `## What is this?` / `### The Philosophy: Live Theory` / `### How it works` / `## Getting Started` / `### Prerequisites` / `### Install and run` / `### Lean Verification Service` / `## Available Scripts` / `## How to Contribute` / `## Project Documentation` / `## Questions or Issues?` / `## License` (README.md:1-119, via `grep -n "^#" README.md`)

A case-insensitive repo-wide search for "vercel" (excluding node_modules) matches only `app/lib/analytics/persist.ts` and `app/lib/utils/dataDir.ts` — there is no Vercel deployment documentation anywhere in the repo, not just missing from the README. This is a dangling forward reference: the doc section was either never written or planned but not landed in this range. The same dangling reference was introduced in intermediate commit 2136fd6 and carried forward by b64c1ca, so it is in-range, not pre-existing.

**Evidence:** `rg -i -l "vercel"` over the worktree → only the two source files above; README.md heading grep shows no matching section.
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect

## Claim 3: dataDir docstring — /tmp-only writability and warm-container lifetime on Vercel Functions

**Location:** app/lib/utils/dataDir.ts:7-10
**Type:** Behavioral / architectural (platform)
**Verdict:** Mostly accurate
**Confidence:** Medium — the code-side mechanism is fully verified; the platform-side claim is true but incomplete, and platform behavior itself is outside the repo.
**Legibility-target:** for-author

> * On Vercel Functions only `/tmp` is writable, and it lives only as long as
> * the warm container — so persistence does not survive cold starts.

(dataDir.ts:7-8)

Both stated facts are correct for Vercel Functions (paraphrased — platform behavior outside the repo). But the docstring's framing — cold starts as the only durability boundary — is incomplete: Vercel scales function instances horizontally, and each concurrent warm instance has its own private `/tmp`. Two consequences for this app's consumers that "does not survive cold starts" undersells:

- Analytics: `appendAnalyticsEntry` (persist.ts:17-20) writes to the serving instance's `/tmp`, while `readAnalyticsEntries` — consumed by `app/api/analytics/route.ts` — reads only the `/tmp` of whichever instance handles the GET. Even with zero cold starts, the analytics endpoint can show a partial history (entries written by other warm instances are invisible), and `clearAnalyticsEntries()` (persist.ts:37-40) clears only one instance's file.
- LLM cache: `getCachedResult`/`setCachedResult` (cache.ts) hit only the local instance's `/tmp/cache`, so cache hit rate degrades with instance count even while everything stays warm; cross-instance requests are guaranteed misses.

The claim is not wrong — persistence indeed does not survive cold starts — but the same-warm-lifetime framing implies a single shared store during warm periods, which is not how multiple concurrent instances behave.

**Evidence:** app/lib/utils/dataDir.ts:7-8,13; app/lib/analytics/persist.ts:17-20,22-24,37-40; app/api/analytics/route.ts:2 (`import { readAnalyticsEntries, clearAnalyticsEntries } from "@/app/lib/analytics/persist";`); app/lib/llm/cache.ts:7 (`const CACHE_DIR = dataDir("cache");`).
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate

## Claim 4: dataDir docstring — dev/self-hosted deployments write to the repo's `data/` dir for durable cross-restart storage

**Location:** app/lib/utils/dataDir.ts:8-11
**Type:** Behavioral / configuration
**Verdict:** Verified
**Confidence:** High — the branch is one line and both consumers were traced.
**Legibility-target:** for-orchestrator-synthesis

> * In dev
> * and self-hosted deployments we write to the repo's `data/` dir for durable
> * cross-restart storage.

(dataDir.ts:8-10)

The env gate is `process.env.VERCEL` (dataDir.ts:13): when unset (dev, self-hosted), base is `join(process.cwd(), "data")` — the repo's `data/` dir for a Next.js server started at the repo root, which is how this app runs (`"dev": "next dev"` per package.json scripts). That is ordinary disk, durable across restarts. Both branches do what the docstring says. Minor caveats, not counted against the claim: (a) the path is cwd-relative, so a self-hosted deploy launched from a different working directory would get `<cwd>/data`; (b) the gate is truthiness of `VERCEL`, so a self-hosted deploy that happens to export `VERCEL` (any non-empty value) would be misrouted to `/tmp` — an unusual configuration.

**Evidence:** app/lib/utils/dataDir.ts:12-15 (full function body); consumers persist.ts:8 and cache.ts:7; package.json scripts.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

## Claim 5: Mixed call conventions resolve to the intended paths; no doc claims uniformity

**Location:** app/lib/llm/cache.ts:7 and app/lib/analytics/persist.ts:8-9
**Type:** Behavioral (brief item 4)
**Verdict:** Verified
**Confidence:** High — pure path arithmetic on read code.
**Legibility-target:** for-orchestrator-synthesis

`cache.ts` uses `const CACHE_DIR = dataDir("cache")` (cache.ts:7) → `join(base, "cache")` via dataDir.ts:14. `persist.ts` uses `const DATA_DIR = dataDir()` then `const FILE_PATH = join(DATA_DIR, "analytics.jsonl")` (persist.ts:8-9) → `join(base, "analytics.jsonl")`. Both resolve to the intended locations on both branches (Vercel: `/tmp/cache`, `/tmp/analytics.jsonl`; otherwise `<cwd>/data/cache`, `<cwd>/data/analytics.jsonl`), identical to the pre-refactor constants. `persist.ts` keeps a separate `DATA_DIR` because `ensureDir()` (persist.ts:11-15) needs the directory itself, so the mixed convention has a functional reason (r3). No comment, docstring, or commit message in the range claims the two call conventions are uniform — commit b64c1ca's message only says the helper "makes future server-side persistence trivially correct (dataDir(\"x\"))", which is forward-looking, not a uniformity claim about existing callers. Nothing to flag as stale.

**Evidence:** app/lib/llm/cache.ts:7; app/lib/analytics/persist.ts:8-15; app/lib/utils/dataDir.ts:13-14; commit b64c1ca message body.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

## Claim 6: Commit b64c1ca — "No behavior change; both DATA_DIR and CACHE_DIR resolve to the same paths they did before" (plus same-inline-pattern and comment-dedup claims)

**Location:** commit b64c1ca message
**Type:** Behavioral / invariant
**Verdict:** Verified
**Confidence:** High — before/after expressions compared directly.
**Legibility-target:** for-orchestrator-synthesis

Before (at 2136fd6, the immediate parent):

> `const DATA_DIR = process.env.VERCEL ? "/tmp" : join(process.cwd(), "data");` (persist.ts at 2136fd6, via `git show 2136fd6`)
> `const CACHE_DIR = process.env.VERCEL ? "/tmp/cache" : join(process.cwd(), "data", "cache");` (cache.ts at 2136fd6, via `git show 2136fd6`)

After: `dataDir()` → `process.env.VERCEL ? "/tmp" : join(process.cwd(), "data")` (dataDir.ts:13), identical truthiness test and identical results; `dataDir("cache")` → `join("/tmp", "cache")` = `"/tmp/cache"` and `join(cwd, "data", "cache")` respectively. Path resolution is bitwise-identical in all four cases; both old and new code evaluate `process.env.VERCEL` once at module load, so no timing change either (r2). The other message claims ("Both analytics and LLM cache had the same Vercel/dev branching pattern inline" — verified as a standalone claim by r2; "puts the Vercel-only /tmp-writability rationale in one place"; "shrinks comment duplication") are all confirmed by the 2136fd6 diff, which shows two near-duplicate inline comment blocks and ternaries that b64c1ca collapses into the single dataDir docstring plus a 2-line pointer.

**Evidence:** `git show 2136fd6` diff hunks for persist.ts and cache.ts; app/lib/utils/dataDir.ts:12-15 at b64c1ca.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

## Claim 7: Commit b64c1ca — "makes future server-side persistence trivially correct (dataDir(\"x\"))"

**Location:** commit b64c1ca message
**Type:** Architectural claim (borderline intent/opinion)
**Verdict:** Verified
**Confidence:** Medium — the mechanism is checkable; "trivially correct" is partly judgment.
**Legibility-target:** for-orchestrator-synthesis

The variadic signature `export function dataDir(...subpaths: string[]): string` (app/lib/utils/dataDir.ts:12) does give any future consumer the correct Vercel/dev branching by construction, as `cache.ts` already demonstrates. The judgment word "trivially" is not checkable; the mechanism it describes exists as claimed. (Noting for-orchestrator context: `persist.ts` itself does not use the subpath form — it joins the filename at the caller — so the "trivially correct" pattern is a convention, not enforced.)

**Evidence:** app/lib/utils/dataDir.ts:12 — `export function dataDir(...subpaths: string[]): string {`; app/lib/llm/cache.ts:7 — `const CACHE_DIR = dataDir("cache");`
**Replicate verdicts:** r1=— · r2=Verified · r3=— · single-replicate detection

## Claim 8: Commit b64c1ca — "Lint clean; 221/221 tests pass."

**Location:** commit b64c1ca message
**Type:** Test/lint status
**Verdict:** Unverifiable
**Confidence:** Medium — pass/clean status cannot be verified statically (no node_modules; running tests is out of scope), but the test count is independently corroborated.
**Legibility-target:** for-orchestrator-synthesis

Static corroboration (independently reproduced by all three replicates): the repo at b64c1ca contains 24 `*.test.*` files, and counting `it(`/`test(` declarations across them yields exactly 221, with zero `it.each`/`test.each`/`.skip`/`.todo` parameterizations that would make the static count diverge from the runtime count. A `lint` script exists (`"lint": "eslint"`, package.json:9) and a `test` script exists (`"test": "vitest run"`, package.json:10), so both claims are at least well-formed against real tooling. Plausible — the diff touches no tested module's logic (no test file imports `dataDir`; streamLlm.test.ts stubs the cache/persist modules) (r3) — but whether all 221 pass and whether lint is clean at this commit cannot be confirmed without executing.

**Evidence:** static grep counts as described (`rg -o "^\s*(it|test)\(" -g '*.test.*'` → 221; no `.each`/`.skip` matches); package.json:9-10.
**Replicate verdicts:** r1=Unverifiable · r2=Unverifiable · r3=Unverifiable

## Claim 9: Commit 2136fd6 — "data/ at the project root ... is read-only on Vercel Functions. Writes were silently swallowed by upstream try/catch — features just degraded with no indication anything was off."

**Location:** commit 2136fd6 message (in range)
**Type:** Behavioral + architectural (historical state at d86d2dc)
**Verdict:** Mostly accurate
**Confidence:** High for the try/catch audit (every caller grepped and read); Medium for the read-only-bundle platform claim (external to repo).
**Legibility-target:** for-author

- **"read-only on Vercel Functions"** — consistent with Vercel's read-only deployment bundle (paraphrased — platform behavior).
- **"Writes were silently swallowed by upstream try/catch"** — true for the LLM paths: all `appendAnalyticsEntry` call sites (callLlm.ts:84-91, callLlm.ts:212-219, streamLlm.ts:55-62, streamLlm.ts:148ff) and both `setCachedResult` sites (callLlm.ts:94, streamLlm.ts:64) sit in bare `catch` blocks with no logging, and `getCachedResult`'s failed reads return `null` (cache.ts:56-59). **But not universally true:** `DELETE /api/analytics` calls `clearAnalyticsEntries();` (app/api/analytics/route.ts:10) with no try/catch, and `clearAnalyticsEntries` does `ensureDir(); writeFileSync(FILE_PATH, "", "utf-8");` (app/lib/analytics/persist.ts:37-40) — on read-only `data/` (pre-2136fd6 on Vercel) `mkdirSync`/`writeFileSync` would throw and the route would 500, which is an indication, not silent swallowing. This route existed at d86d2dc in identical form. The "silently ... no indication anything was off" claim over-generalizes from the LLM paths.
- **"Local dev is unchanged"** — checked separately as Claim 10.

**Evidence:** app/api/analytics/route.ts:9-12 — `export async function DELETE() { clearAnalyticsEntries(); return NextResponse.json({ ok: true }); }` (no try/catch); app/lib/analytics/persist.ts:37-40; app/lib/llm/callLlm.ts:91 — `} catch { /* persistence failure must not break LLM calls */ }`; caller inventory via `rg -n "appendAnalyticsEntry|readAnalyticsEntries|clearAnalyticsEntries|getCachedResult|setCachedResult|removeCachedResult"` — no call sites beyond those cited (plus mocks in streamLlm.test.ts and the guarded `removeCachedResult` at app/lib/formalization/artifactRoute.ts:104).
**Replicate verdicts:** r1=Verified · r2=Mostly accurate · r3=Mostly accurate

## Claim 10: Commit 2136fd6 — "Local dev is unchanged" and "zero new dependencies"

**Location:** commit 2136fd6 message
**Type:** Behavioral / configuration
**Verdict:** Verified
**Confidence:** High — diff-level comparison of both branches.
**Legibility-target:** for-orchestrator-synthesis

The non-Vercel branch at 2136fd6 (`join(process.cwd(), "data")` / `join(process.cwd(), "data", "cache")`) is byte-identical in effect to the d86d2dc constants, so local dev paths are unchanged — confirmed by all three replicates. The "zero new dependencies" half (checked only by r3, within this same commit-message claim): `git diff d86d2dc..b64c1ca --stat` touches only persist.ts, cache.ts, and dataDir.ts — no package.json or lockfile — and `dataDir.ts` imports only `path` (dataDir.ts:1).

**Evidence:** diff stat (3 files, 21 insertions); dataDir.ts:1 `import { join } from "path";`; d86d2dc file contents per Claim 9 evidence.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

## Claim 11: Commit 2136fd6 — tradeoff framing: "cache benefits and analytics history don't survive cold starts ... self-hosted deploys still get the durable data/ path"

**Location:** commit 2136fd6 message, "Tradeoff:" paragraph
**Type:** Behavioral / architectural
**Verdict:** Mostly accurate
**Confidence:** Medium — code side High; same platform-knowledge caveat as Claim 3.
**Legibility-target:** for-author

The stated tradeoff is real and the self-hosted half is verified (non-Vercel branch writes to `<cwd>/data`, dataDir.ts:13, which persists across restarts). But like the dataDir docstring (Claim 3), the framing understates the Vercel-side loss: with multiple concurrent instances, cache and analytics are per-instance even between cold starts, so "don't survive cold starts" is the *minimum* degradation, and the single-tenant-acceptability argument silently assumes a single warm instance. For a low-traffic single-tenant deploy that assumption is usually fine in practice, which is why this is Mostly accurate rather than Incorrect.

**Evidence:** commit 2136fd6 message "Tradeoff:" paragraph; dataDir.ts:13; consumer behavior per Claim 3 evidence.
**Replicate verdicts:** r1=— · r2=— · r3=Mostly accurate · single-replicate detection

## Claim 12: persist.ts ensureDir/error-handling comments (and LLM-caller error-path comments) still match behavior with the new base dir

**Location:** app/lib/analytics/persist.ts:11-15, 27-32; app/lib/llm/callLlm.ts:91, 94, 219; app/lib/llm/streamLlm.ts:62, 64
**Type:** Behavioral (brief item 6)
**Verdict:** Verified
**Confidence:** High — code is short and unchanged in the range; all consumers read end-to-end.
**Legibility-target:** for-orchestrator-synthesis

The only comment in persist.ts's error paths is `// skip corrupt lines` inside `readAnalyticsEntries`'s per-line `try { entries.push(JSON.parse(line)); } catch { ... }` (persist.ts:27-31), which exactly describes the behavior and is base-dir-independent. `ensureDir()` (persist.ts:11-15, `mkdirSync(DATA_DIR, { recursive: true })`) carries no comment and works identically for `/tmp` (already exists; recursive mkdir is a no-op) and `<cwd>/data`. Caller-side comments remain accurate with the new base dir: `} catch { /* persistence failure must not break LLM calls */ }` (callLlm.ts:91; same wording at callLlm.ts:219, streamLlm.ts:62) and `try { await setCachedResult(cacheHash, result); } catch { /* cache write failure is non-fatal */ }` (callLlm.ts:94; streamLlm.ts:64) wrap every write call from the LLM paths, so the "must not break" invariant holds regardless of which base directory `dataDir()` returns.

**Evidence:** app/lib/analytics/persist.ts:11-15, 26-33; app/lib/llm/callLlm.ts:84-94, 212-219; app/lib/llm/streamLlm.ts:55-64, 148-155.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

## Claim 13: cache.ts error-path comments still match behavior with the new base dir

**Location:** app/lib/llm/cache.ts:45, 56-57, 80-82
**Type:** Behavioral (brief item 6)
**Verdict:** Mostly accurate
**Confidence:** High — full file read.
**Legibility-target:** for-author

Comments checked: `// Override usage to reflect cache hit` (cache.ts:45) — matches the code, which rewrites `provider: "cache", costUsd: 0, latencyMs: 0` (cache.ts:46-52). `// File doesn't exist — nothing to remove` (cache.ts:80-81) — matches the swallow-on-unlink intent. The one slightly off comment: `// Corrupt or missing cache file — treat as miss` (cache.ts:56-57) sits on a catch that wraps both `readFile` and `JSON.parse` — accurate — but the same catch also absorbs any other I/O error (e.g., permission errors on a misconfigured base dir), which after the rewiring is the exact failure mode this range was written to fix. The comment names two causes for a catch that is actually the module's whole silent-degradation surface. Behavior is unchanged and intended; the comment is just narrower than the code. Base-dir change introduces no staleness: `ensureCacheDir`'s `dirEnsured` memoization (cache.ts:27-32) is per-process and works for both `/tmp/cache` and `<cwd>/data/cache` (both reset together with the process, so the flag tracks correctly).

**Evidence:** app/lib/llm/cache.ts:27-32, 43-59, 76-83.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=—

## Claims Requiring Attention

### Incorrect
- **Claim 2** (persist.ts:6-7): "see Deploy to Vercel in README" — the README at b64c1ca has no such section, and no file in the repo besides the two source comments mentions Vercel at all. Flagged unanimously (3/3 replicates). Either write the README section (2136fd6's tradeoff paragraph is ready-made content for it) or drop the reference and rely on the dataDir() docstring pointer.

### Stale
- None.

### Mostly Accurate
- **Claim 3** (dataDir.ts:7-10): "lives only as long as the warm container" frames cold starts as the only durability boundary; concurrent Vercel instances each have a private `/tmp`, so analytics reads can be partial and cache hits per-instance even with no cold start. Flagged unanimously (3/3). One added clause would close the gap.
- **Claim 9** (commit 2136fd6): "writes were silently swallowed by upstream try/catch" holds for all LLM-path call sites but not for `DELETE /api/analytics` → `clearAnalyticsEntries()`, which is unguarded and would have thrown (500) rather than degrading silently. Flagged by r2 and r3; r1 rated the claim Verified without checking the DELETE route (most-severe wins).
- **Claim 11** (commit 2136fd6 tradeoff): "don't survive cold starts" understates the degradation; per-instance isolation applies even while warm, and the single-tenant-acceptability argument assumes a single warm instance. Single-replicate detection (r3).
- **Claim 13** (cache.ts:56-57): "Corrupt or missing cache file" catch comment is narrower than the catch, which also silently absorbs permission/I-O errors — the very failure class this change set was motivated by. Flagged by r1; r2 rated the same comments Verified (most-severe wins).

### Unverifiable
- **Claim 8** (commit b64c1ca message): "Lint clean; 221/221 tests pass" — cannot execute tests/lint in this environment; static test-case count independently equals 221 in all three replicates, which corroborates but does not confirm.

## Verdict stability

- **Total clusters:** 13
- **Agreed (all replicates that surfaced the cluster gave the same verdict):** 11 of 13 — including 2 single-replicate detections (Claim 7, r2 only; Claim 11, r3 only) that are trivially agreed. 9 of the 11 multi-replicate clusters agreed outright.
- **Disagreements (2):**
  - Claim 9 (2136fd6 "silently swallowed"): r1=Verified · r2=Mostly accurate · r3=Mostly accurate → merged Mostly accurate (most-severe wins; r2/r3 found the unguarded DELETE route counterexample).
  - Claim 13 (cache.ts error-path comments): r1=Mostly accurate · r2=Verified · r3=— → merged Mostly accurate (most-severe wins; r1 found the narrower-than-catch comment).
- **Agreement rate:** 11/13 = 85% (multi-replicate clusters only: 9/11 = 82%).

## Goal-Alignment Note
- Answered: All six briefed items across all replicates — README reference (Claim 2, Incorrect), /tmp completeness vs concurrent instances (Claims 3, 11), env-check branches (Claim 4), mixed call conventions (Claim 5), both commit messages' checkable statements including the no-behavior-change and test/lint claims (Claims 6-11), and ensureDir/error-path comments (Claims 12-13).
- Out of scope: Whether writing analytics/cache to per-instance `/tmp` is a good design (review judgment — per-instance sharding belongs to architecture/performance critics, not fact-check); running tests/lint (dynamic verification excluded by brief); anything newer than b64c1ca. Also noted by r2 for the orchestrator, outside the reviewed range: a pre-existing stale claim in docs/plans/refactoring-plan.md:38 ("`cache.ts`: `ensureCacheDir` calls `existsSync` before `mkdirSync` on every write") describes code that does not exist at b64c1ca — `ensureCacheDir` (cache.ts:27-32) uses a `dirEnsured` boolean and never calls `existsSync`; this was already true at d86d2dc.
- Escalate: The dangling "Deploy to Vercel" README reference (Claim 2) is both a doc bug and a signal that a planned documentation task was dropped between 2136fd6 and b64c1ca — all three replicates escalated it; r2 notes CLAUDE.md's Documentation Maintenance section explicitly requires README updates for user-facing deployment behavior changes in the same PR. Secondary: the per-instance-isolation omission (Claims 3/11) may warrant an architecture-critic look, since the "acceptable for single-tenant" argument in 2136fd6 rests on an undocumented single-instance assumption.
