# Code Fact-Check Report

**Commit:** b64c1ca
**Repository:** /workspace/external/cc-review-eval/mfc-fscompat
**Scope:** Files changed in `git diff d86d2dc...HEAD` (`app/lib/analytics/persist.ts`, `app/lib/llm/cache.ts`, `app/lib/utils/dataDir.ts`) plus the two commit messages (2136fd6, b64c1ca) and documentation they reference
**Checked:** 2026-08-18
**Total claims checked:** 20
**Summary:** 14 verified, 1 mostly accurate, 0 stale, 1 incorrect, 4 unverifiable

Evidence directory (executed-claim provenance): `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-fscompat/evidence/` (prefix `r2-`). All executions ran in cwd `/workspace/external/cc-review-eval/mfc-fscompat` on 2026-08-18 between 06:42:36Z and 06:44:00Z (see `r2-timestamps.txt` and per-file `date:` lines). Scratch test sources are preserved as `r2-scratch-local.test.ts.txt` and `r2-scratch-vercel.test.ts.txt`; the test files were placed in the clone, run, and deleted, leaving the clone pristine.

---

## Claim 1a: "On Vercel, analytics history [is written to ephemeral /tmp rather than the durable data/ dir]" (mechanism half of "On Vercel, analytics history doesn't persist across cold starts")

**Location:** `app/lib/analytics/persist.ts:6-8`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers where `appendAnalyticsEntry` writes when the `VERCEL` env var is set in this sandbox's Node runtime; does not establish anything about Vercel's actual container lifecycle (that is Claim 1b).

The routing mechanism is in the new helper:

```ts
// app/lib/utils/dataDir.ts:13
const base = process.env.VERCEL ? "/tmp" : join(process.cwd(), "data");
```

and `persist.ts` builds its path from it:

```ts
// app/lib/analytics/persist.ts:8-9
const DATA_DIR = dataDir();
const FILE_PATH = join(DATA_DIR, "analytics.jsonl");
```

Executed: with `VERCEL=1`, a scratch vitest test called `appendAnalyticsEntry` and asserted the entry landed in `/tmp/analytics.jsonl` and that `<cwd>/data/analytics.jsonl` was NOT created; all assertions passed.
Command: `VERCEL=1 npx vitest run app/lib/utils/r2scratch-vercel.test.ts` · cwd: `/workspace/external/cc-review-eval/mfc-fscompat` · exit code 0 · 2026-08-18T06:42:38Z (7/7 tests passed).

**Evidence:** `app/lib/utils/dataDir.ts:13`, `app/lib/analytics/persist.ts:8-9`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-fscompat/evidence/r2-vitest-vercel.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-fscompat/evidence/r2-scratch-vercel.test.ts.txt`

---

## Claim 1b: "On Vercel, analytics history doesn't persist across cold starts" (platform-lifecycle half)

**Location:** `app/lib/analytics/persist.ts:6-7`
**Type:** Behavioral / Invariant
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the assertion that Vercel discards `/tmp` contents on cold start; does not dispute the local routing mechanism (Claim 1a, verified).

The claim depends on Vercel Functions' container lifecycle — that `/tmp` is per-instance and cleared when a container is recycled (paraphrased — no quote available because the claim is about platform runtime behavior, not code in this repo). This is an executable guarantee only on a deployed Vercel environment; the specific blocker is that the review sandbox has no Vercel deployment and cannot reproduce cold-start container recycling, so the local half is verified (Claim 1a) and the platform half cannot be executed. The claim is consistent with Vercel's documented behavior, but per the mandatory-execution rule it cannot be Verified from here.

**Evidence:** `app/lib/utils/dataDir.ts:7-10` (the same platform assertion, checked as Claim 8)

---

## Claim 2: "see Deploy to Vercel in README"

**Location:** `app/lib/analytics/persist.ts:7`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the existence of a "Deploy to Vercel" section (or any Vercel mention) in the repo's README and other documentation at HEAD; does not establish whether such a section is planned or exists in a deployment branch.

No such section exists. Case-insensitive search for "vercel" across `README.md`, `CONTRIBUTING.md`, `docs/`, and `documentation/` returns zero hits (exit 1), and `CLAUDE.md` also has zero matches (`grep -c -i vercel CLAUDE.md` → 0). The README's full heading list contains no deploy section of any kind; the closest headings are:

```
# README.md headings (from r2-grep-readme.txt)
42:## Getting Started
58:### Lean Verification Service
94:## Available Scripts
```

A reader following this cross-reference finds nothing. Note the reference predates this diff's refactor — the same phrase existed in commit 2136fd6's version of the comment — but it was never resolvable at any commit in this range (paraphrased — no quote available because the claim covers absence of content: zero grep matches).
Command: `grep -rn -i vercel README.md CONTRIBUTING.md docs documentation` · cwd: `/workspace/external/cc-review-eval/mfc-fscompat` · exit code 1 (no matches) · 2026-08-18T06:43:56Z.

**Evidence:** `app/lib/analytics/persist.ts:6-7`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-fscompat/evidence/r2-grep-readme.txt`

---

## Claim 3: "See dataDir() for the underlying rationale"

**Location:** `app/lib/analytics/persist.ts:7`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence of `dataDir()` and that its docstring states the rationale; does not assess whether that rationale is itself accurate (Claims 8-9).

`dataDir()` exists at `app/lib/utils/dataDir.ts:12` and its docstring carries the rationale the comment points to:

```ts
// app/lib/utils/dataDir.ts:7-10
 * On Vercel Functions only `/tmp` is writable, and it lives only as long as
 * the warm container — so persistence does not survive cold starts. In dev
 * and self-hosted deployments we write to the repo's `data/` dir for durable
 * cross-restart storage.
```

**Evidence:** `app/lib/utils/dataDir.ts:3-15`, `app/lib/analytics/persist.ts:7`

---

## Claim 4: "skip corrupt lines"

**Location:** `app/lib/analytics/persist.ts:31`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the per-line parse loop in `readAnalyticsEntries`; does not establish behavior if the whole-file `readFileSync` itself throws (that error propagates to the caller).

Each line is parsed inside a try/catch whose catch clause simply continues the loop, so a corrupt line is dropped and parsing proceeds:

```ts
// app/lib/analytics/persist.ts:28-32
    try {
      entries.push(JSON.parse(line));
    } catch {
      // skip corrupt lines
    }
```

The observer of the failure is the loop itself — the corrupt line is silently omitted from the returned array, which is exactly what "skip" claims.

**Evidence:** `app/lib/analytics/persist.ts:22-35`

---

## Claim 5: "Override usage to reflect cache hit"

**Location:** `app/lib/llm/cache.ts:45`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the usage-field rewriting on the cache-hit path of `getCachedResult` and what a cache file physically stores; does not establish that all callers preserve the overridden usage downstream.

The hit path rewrites `provider`, `costUsd`, and `latencyMs` while spreading the stored usage:

```ts
// app/lib/llm/cache.ts:44-53
    // Override usage to reflect cache hit
    return {
      text: data.text,
      usage: {
        ...data.usage,
        provider: "cache",
        costUsd: 0,
        latencyMs: 0,
      },
      cacheHash: hash,
    };
```

Executed: a scratch test wrote a cache entry via `setCachedResult` and confirmed (a) the on-disk file `/tmp/cache/<sha256-hex>.json` stores exactly `{ text, usage }` with the original usage (`provider: "anthropic"`, `costUsd: 0.5`, `latencyMs: 999`), and (b) `getCachedResult` returned `provider: "cache"`, `costUsd: 0`, `latencyMs: 0`, with untouched fields (`inputTokens: 10`) passed through and `cacheHash` equal to the sha256 hash.
Command: `VERCEL=1 npx vitest run app/lib/utils/r2scratch-vercel.test.ts` · cwd: `/workspace/external/cc-review-eval/mfc-fscompat` · exit code 0 · 2026-08-18T06:42:38Z.

**Evidence:** `app/lib/llm/cache.ts:16-56`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-fscompat/evidence/r2-vitest-vercel.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-fscompat/evidence/r2-scratch-vercel.test.ts.txt`

---

## Claim 6: "Corrupt or missing cache file — treat as miss"

**Location:** `app/lib/llm/cache.ts:57`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `getCachedResult`'s catch-all returning null for both corrupt JSON and a nonexistent file; does not establish behavior for other failure classes (e.g., permission errors), though the same catch would swallow them into a miss as well.

```ts
// app/lib/llm/cache.ts:56-59
  } catch {
    // Corrupt or missing cache file — treat as miss
    return null;
  }
```

Executed: the scratch test wrote `{not valid json` to the expected cache path and asserted `getCachedResult(...)` returned `null` (corrupt case), and asserted `null` for a hash whose file was never written (missing case). Both passed. The observer of the failure is the caller, which receives an ordinary cache miss.
Command: `VERCEL=1 npx vitest run app/lib/utils/r2scratch-vercel.test.ts` · cwd: `/workspace/external/cc-review-eval/mfc-fscompat` · exit code 0 · 2026-08-18T06:42:38Z.

**Evidence:** `app/lib/llm/cache.ts:33-60`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-fscompat/evidence/r2-vitest-vercel.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-fscompat/evidence/r2-scratch-vercel.test.ts.txt`

---

## Claim 7: "File doesn't exist — nothing to remove"

**Location:** `app/lib/llm/cache.ts:82`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `removeCachedResult` resolving without throwing when the target file is absent; does not establish behavior for non-ENOENT unlink failures (the same catch swallows those too).

```ts
// app/lib/llm/cache.ts:79-84
  try {
    await unlink(filePath);
  } catch {
    // File doesn't exist — nothing to remove
  }
```

Executed: the scratch test called `removeCachedResult` for inputs whose cache file was never created and asserted the promise resolves to `undefined` without throwing; passed.
Command: `VERCEL=1 npx vitest run app/lib/utils/r2scratch-vercel.test.ts` · cwd: `/workspace/external/cc-review-eval/mfc-fscompat` · exit code 0 · 2026-08-18T06:42:38Z.

**Evidence:** `app/lib/llm/cache.ts:71-85`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-fscompat/evidence/r2-vitest-vercel.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-fscompat/evidence/r2-scratch-vercel.test.ts.txt`

---

## Claim 8: "On Vercel Functions only `/tmp` is writable, and it lives only as long as the warm container — so persistence does not survive cold starts"

**Location:** `app/lib/utils/dataDir.ts:7-8`
**Type:** Invariant / Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the platform assertions about Vercel Functions' filesystem (read-only outside `/tmp`; `/tmp` scoped to the warm container instance); does not cover the code's env-var routing, which is Claim 9 (verified by execution).

Both halves are claims about the Vercel Functions runtime, not about code in this repo (paraphrased — no quote available because the claim's subject is external platform behavior with no corresponding code to quote). The specific blocker: verifying "only /tmp is writable" and "/tmp does not survive cold starts" requires executing writes inside a deployed Vercel Function and forcing a container recycle — the review sandbox has no Vercel deployment or credentials. The claims match Vercel's publicly documented serverless filesystem model, but under the mandatory-execution rule an executable platform guarantee that cannot be run here caps at Unverifiable.

**Evidence:** `app/lib/utils/dataDir.ts:3-11`

---

## Claim 9: "In dev and self-hosted deployments we write to the repo's `data/` dir for durable cross-restart storage"

**Location:** `app/lib/utils/dataDir.ts:8-10`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `dataDir()`'s resolution and where analytics writes land in a Node process without `VERCEL` set; does not establish Vercel-side behavior (Claims 1b/8) or that every future persistence feature will route through `dataDir()`.

```ts
// app/lib/utils/dataDir.ts:12-15
export function dataDir(...subpaths: string[]): string {
  const base = process.env.VERCEL ? "/tmp" : join(process.cwd(), "data");
  return subpaths.length > 0 ? join(base, ...subpaths) : base;
}
```

Executed with `VERCEL` explicitly unset: a scratch test asserted `dataDir() === join(process.cwd(), "data")` and `dataDir("cache") === join(process.cwd(), "data", "cache")`, then called `appendAnalyticsEntry` and asserted the entry landed in `<cwd>/data/analytics.jsonl` on disk (durable repo dir). All 3 tests passed; scratch artifacts were removed afterward.
Command: `env -u VERCEL npx vitest run app/lib/utils/r2scratch-local.test.ts` · cwd: `/workspace/external/cc-review-eval/mfc-fscompat` · exit code 0 · 2026-08-18T06:42:37Z.

**Evidence:** `app/lib/utils/dataDir.ts:12-15`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-fscompat/evidence/r2-vitest-local.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-fscompat/evidence/r2-scratch-local.test.ts.txt`

---

## Claim 10a: "The LLM cache and analytics log used to write to data/ at the project root"

**Location:** commit 2136fd6 (message, body)
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the pre-change path constants at base commit d86d2dc; does not cover the read-only-on-Vercel assertion (Claim 10b).

The base-commit versions of both files hardcode project-root `data/` paths:

```ts
// git show d86d2dc:app/lib/llm/cache.ts (line 6)
const CACHE_DIR = join(process.cwd(), "data", "cache");
```

```ts
// git show d86d2dc:app/lib/analytics/persist.ts (line 5)
const DATA_DIR = join(process.cwd(), "data");
```

**Evidence:** `app/lib/llm/cache.ts:7` (current), git object `d86d2dc:app/lib/llm/cache.ts`, `d86d2dc:app/lib/analytics/persist.ts`

---

## Claim 10b: "[data/ at the project root] is read-only on Vercel Functions"

**Location:** commit 2136fd6 (message, body)
**Type:** Invariant
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the platform assertion that the deployed bundle's directory tree is not writable on Vercel Functions; does not dispute the (verified) pre-change paths of Claim 10a.

Same platform blocker as Claim 8: this is an assertion about the Vercel Functions filesystem, verifiable only by attempting a write from inside a deployed function (paraphrased — no quote available because the claim's subject is external platform behavior, not repo code). The sandbox has no Vercel deployment, so execution is blocked and the verdict caps at Unverifiable.

**Evidence:** commit 2136fd6 message (`git log`), `app/lib/utils/dataDir.ts:7`

---

## Claim 11: "Writes were silently swallowed by upstream try/catch — features just degraded with no indication anything was off"

**Location:** commit 2136fd6 (message, body)
**Type:** Error-handling / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers all repo call sites of `appendAnalyticsEntry` and `setCachedResult` at HEAD (grep-enumerated); does not establish that no other logging layer (e.g., platform-level stderr capture) would surface the failure.

Every persistence call site wraps the write in a try/catch with an empty (comment-only) handler. In `callLlm.ts`'s shared helper:

```ts
// app/lib/llm/callLlm.ts:75-93 (recordAndCache)
  try {
    appendAnalyticsEntry({
      ...
    });
  } catch { /* persistence failure must not break LLM calls */ }
  ...
    try { await setCachedResult(cacheHash, result); } catch { /* cache write failure is non-fatal */ }
```

and the same pattern in the streaming path:

```ts
// app/lib/llm/streamLlm.ts:64
    try { await setCachedResult(cacheHash, { text, usage }); } catch { /* non-fatal */ }
```

The two remaining `appendAnalyticsEntry` call sites (mock-fallback paths at `callLlm.ts:212-219` and `streamLlm.ts:148-155`) are also wrapped in `try { ... } catch { /* persistence failure must not break LLM calls */ }` / `catch { /* non-fatal */ }` (paraphrased — no quote available because the four call sites are near-identical blocks across two files and quoting all would be redundant; grep `appendAnalyticsEntry` confirms these are all call sites outside persist.ts and tests). No catch block logs anything, so the failure's only observer is the empty catch — "no indication anything was off" holds.

**Evidence:** `app/lib/llm/callLlm.ts:75-95`, `app/lib/llm/callLlm.ts:212-219`, `app/lib/llm/streamLlm.ts:55-65`, `app/lib/llm/streamLlm.ts:148-155`

---

## Claim 12a: "Switching to /tmp on Vercel keeps both features working [writes to /tmp succeed and round-trip]"

**Location:** commit 2136fd6 (message, body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that with `VERCEL` set, analytics appends and cache write/read round-trips succeed against `/tmp` in this sandbox; does not establish behavior inside an actual Vercel Function (Claim 12b).

With `VERCEL=1`, the scratch test exercised both features end-to-end: `appendAnalyticsEntry` wrote and re-read `/tmp/analytics.jsonl`, and `setCachedResult`/`getCachedResult` round-tripped through `/tmp/cache/<hash>.json` (see Claims 1a, 5, 6 for the specific assertions; all 7 tests passed) (paraphrased — no quote available because the verdict aggregates the executed assertions already quoted under Claims 1a and 5).
Command: `VERCEL=1 npx vitest run app/lib/utils/r2scratch-vercel.test.ts` · cwd: `/workspace/external/cc-review-eval/mfc-fscompat` · exit code 0 · 2026-08-18T06:42:38Z.

**Evidence:** `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-fscompat/evidence/r2-vitest-vercel.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-fscompat/evidence/r2-scratch-vercel.test.ts.txt`

---

## Claim 12b: "…within a warm container … /tmp lifetime is the warm container, so cache benefits and analytics history don't survive cold starts"

**Location:** commit 2136fd6 (message, body)
**Type:** Invariant
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the per-instance/warm-container lifetime semantics of `/tmp` on Vercel; does not dispute the locally executed success path (Claim 12a).

Identical platform blocker to Claims 1b and 8: warm-container `/tmp` lifetime and cold-start data loss can only be observed on a deployed Vercel Function across a container recycle, which the sandbox cannot perform (paraphrased — no quote available because the claim's subject is external platform behavior, not repo code).

**Evidence:** commit 2136fd6 message (`git log`), `app/lib/utils/dataDir.ts:7-8`

---

## Claim 13: "Local dev is unchanged"

**Location:** commit 2136fd6 (message, body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers path resolution and analytics write destination without `VERCEL` set, compared against the base commit's hardcoded paths; does not cover non-filesystem aspects of local dev (none are touched by this diff).

At base d86d2dc the local paths were `join(process.cwd(), "data")` and `join(process.cwd(), "data", "cache")` (quoted under Claim 10a). Executed at HEAD with `VERCEL` unset, `dataDir()` and `dataDir("cache")` resolve to exactly those same strings and `appendAnalyticsEntry` writes to `<cwd>/data/analytics.jsonl` (see Claim 9's run — same command, exit 0).
Command: `env -u VERCEL npx vitest run app/lib/utils/r2scratch-local.test.ts` · cwd: `/workspace/external/cc-review-eval/mfc-fscompat` · exit code 0 · 2026-08-18T06:42:37Z.

**Evidence:** `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-fscompat/evidence/r2-vitest-local.txt`, git objects `d86d2dc:app/lib/llm/cache.ts`, `d86d2dc:app/lib/analytics/persist.ts`

---

## Claim 14: "Both analytics and LLM cache had the same Vercel/dev branching pattern inline"

**Location:** commit b64c1ca (message, body)
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the state of both files at the parent commit 2136fd6; does not assess whether centralizing was the right design (out of scope for fact-check).

Both files at 2136fd6 carried the inline ternary:

```ts
// git show 2136fd6:app/lib/llm/cache.ts (lines 9-11)
const CACHE_DIR = process.env.VERCEL
  ? "/tmp/cache"
  : join(process.cwd(), "data", "cache");
```

```ts
// git show 2136fd6:app/lib/analytics/persist.ts (line 9)
const DATA_DIR = process.env.VERCEL ? "/tmp" : join(process.cwd(), "data");
```

Both also carried near-duplicate rationale comments about /tmp writability and warm-container lifetime (paraphrased — no quote available because the two comment blocks were quoted-equivalent 3-4-line prose; see the git objects cited below).

**Evidence:** git objects `2136fd6:app/lib/llm/cache.ts`, `2136fd6:app/lib/analytics/persist.ts`

---

## Claim 15: "No behavior change; both DATA_DIR and CACHE_DIR resolve to the same paths they did before"

**Location:** commit b64c1ca (message, body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers path-resolution equality between 2136fd6 and b64c1ca in both env states; does not cover timing-of-evaluation differences (both versions compute the constants at module load).

At 2136fd6 the inline expressions produced `/tmp` / `/tmp/cache` under `VERCEL` and `<cwd>/data` / `<cwd>/data/cache` otherwise (quoted under Claim 14). Executed at HEAD: `dataDir()` returned `/tmp` and `dataDir("cache")` returned `/tmp/cache` with `VERCEL=1` (`join("/tmp", "cache")` = `"/tmp/cache"`, matching the old literal), and `<cwd>/data` / `<cwd>/data/cache` without it — identical strings in all four cases.
Commands: `VERCEL=1 npx vitest run app/lib/utils/r2scratch-vercel.test.ts` (exit 0, 2026-08-18T06:42:38Z) and `env -u VERCEL npx vitest run app/lib/utils/r2scratch-local.test.ts` (exit 0, 2026-08-18T06:42:37Z) · cwd: `/workspace/external/cc-review-eval/mfc-fscompat`.

**Evidence:** `app/lib/utils/dataDir.ts:12-15`, git object `2136fd6:app/lib/llm/cache.ts`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-fscompat/evidence/r2-vitest-vercel.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-fscompat/evidence/r2-vitest-local.txt`

---

## Claim 16a: "Lint clean"

**Location:** commit b64c1ca (message, body)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the repo-wide `npm run lint` result at HEAD in this sandbox; does not establish which commit introduced the two warnings (they are in a file untouched by this diff).

`npm run lint` exits 0 with zero errors, but it is not warning-free — eslint reports:

```
# r2-lint.txt
✖ 2 problems (0 errors, 2 warnings)
```

Both warnings are `react-hooks/exhaustive-deps` in `app/page.tsx:209` and `app/page.tsx:271`, a file not touched by this diff (paraphrased — no quote available because the two warning lines are long single lines; full text is in the captured output). The precise version of the claim: "lint passes (exit 0, no errors); two pre-existing warnings remain outside the changed files." Mechanism and conclusion are right — the diff introduces no lint problems — but "clean" is imprecise.
Command: `npm run lint` · cwd: `/workspace/external/cc-review-eval/mfc-fscompat` · exit code 0 · 2026-08-18T06:42:50Z.

**Evidence:** `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-fscompat/evidence/r2-lint.txt`

---

## Claim 16b: "221/221 tests pass"

**Location:** commit b64c1ca (message, body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the full vitest suite at HEAD in this sandbox; does not establish coverage of the new `dataDir()` routing itself (no repo test imports `dataDir` — verified separately by grep for this report's scoping).

The full suite reports exactly the claimed count:

```
# r2-vitest-full.txt
 Test Files  24 passed (24)
      Tests  221 passed (221)
```

Command: `npm test` (runs `vitest run`) · cwd: `/workspace/external/cc-review-eval/mfc-fscompat` · exit code 0 · 2026-08-18T06:42:58Z (run start; timestamp window in `r2-timestamps.txt`).

**Evidence:** `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-fscompat/evidence/r2-vitest-full.txt`

---

## Claims Requiring Attention

### Incorrect
- **Claim 2** (`app/lib/analytics/persist.ts:7`): "see Deploy to Vercel in README" — no "Deploy to Vercel" section (or any mention of Vercel) exists in README.md or any documentation file; either add the section or drop the cross-reference.

### Mostly Accurate
- **Claim 16a** (commit b64c1ca): "Lint clean" — eslint exits 0 with 0 errors, but 2 pre-existing `react-hooks/exhaustive-deps` warnings remain in `app/page.tsx` (outside this diff); "no new lint problems" would be precise.

### Unverifiable
- **Claim 1b** (`app/lib/analytics/persist.ts:6-7`): Vercel cold-start data loss — needs a deployed Vercel Function and a forced container recycle to verify.
- **Claim 8** (`app/lib/utils/dataDir.ts:7-8`): "only /tmp is writable" + warm-container lifetime on Vercel Functions — needs write attempts inside a deployed Vercel Function; sandbox has no Vercel deployment.
- **Claim 10b** (commit 2136fd6): project-root `data/` is read-only on Vercel Functions — same blocker as Claim 8.
- **Claim 12b** (commit 2136fd6): `/tmp` lifetime is the warm container on Vercel — same blocker as Claim 8.
