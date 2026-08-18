# Code Fact-Check Report

**Commit:** b64c1ca
**Replication:** k=2
**Repository:** /workspace/external/cc-review-eval/mfc-fscompat
**Scope:** Files changed in `git diff d86d2dc...HEAD` (`app/lib/analytics/persist.ts`, `app/lib/llm/cache.ts`, `app/lib/utils/dataDir.ts`) plus the two commit messages (2136fd6, b64c1ca) and the documentation they reference (README and other docs)
**Checked:** 2026-08-18
**Total claims checked:** 22
**Summary:** 14 verified, 2 mostly accurate, 0 stale, 1 incorrect, 5 unverifiable

Merge note: this report is the most-severe-wins union of two replicate fact-check reports (`code-fact-check-report-r1.md`, `code-fact-check-report-r2.md`) at HEAD b64c1ca. Executed-claim provenance lives under `./evidence/` with per-replicate `r1-`/`r2-` prefixes; each merged claim carries a `**Replicate verdicts:**` line and single-replicate detections are marked. Both replicates ran in cwd `/workspace/external/cc-review-eval/mfc-fscompat` on a clean tree; r2 additionally executed cache-file-contents checks (what a cache file physically stores) that r1 did not, and r1 additionally verified the whole test suite / lint gate and flagged the unguarded DELETE-route write. Compound/atomic mismatches between the replicates are resolved by verdicting the atoms (decision 033): each compound clusters with each of its parts, and the winning verdict for a part is carried by the replicate evidence that actually bears on that part.

---

## Claim 1a: "On Vercel, analytics history [is written to ephemeral `/tmp` rather than the durable `data/` dir] — i.e., analytics writes are routed to `/tmp` when `VERCEL` is set" (mechanism half)

**Location:** `app/lib/analytics/persist.ts:6-8`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers where `appendAnalyticsEntry` writes with `VERCEL` set vs unset in this sandbox's Node runtime; does not establish anything about the actual Vercel platform (filesystem writability or container lifetime — that is Claim 1b).
**Replicate verdicts:** r1=Verified · r2=Verified

The comment sits on the constant, which builds its path from the new helper:

```ts
// app/lib/analytics/persist.ts:6-9
// On Vercel, analytics history doesn't persist across cold starts — see
// Deploy to Vercel in README. See dataDir() for the underlying rationale.
const DATA_DIR = dataDir();
const FILE_PATH = join(DATA_DIR, "analytics.jsonl");
```

and `dataDir()` branches on the env var:

```ts
// app/lib/utils/dataDir.ts:13
const base = process.env.VERCEL ? "/tmp" : join(process.cwd(), "data");
```

Executed (both replicates): a scratch vitest dynamically imports `persist.ts` with `VERCEL` toggled and asserts the write location. With `VERCEL=1`, `appendAnalyticsEntry` created `/tmp/analytics.jsonl` and did **not** create `<cwd>/data/analytics.jsonl`; with `VERCEL` unset it wrote `<cwd>/data/analytics.jsonl` (paraphrased — no quote available because the assertion is the pass/fail outcome of the captured test run, not a source snippet). r1: `npx vitest run app/lib/utils/dataDir.scratch.test.ts`, exit 0, 6/6 passed, 2026-08-18T06:42:19Z. r2: `VERCEL=1 npx vitest run app/lib/utils/r2scratch-vercel.test.ts`, exit 0, 7/7 passed, 2026-08-18T06:42:38Z.

**Evidence:** `app/lib/analytics/persist.ts:6-9`, `app/lib/utils/dataDir.ts:13`, `./evidence/r1-datadir-scratch-vitest.txt`, `./evidence/r1-datadir-scratch-test-source.ts.txt`, `./evidence/r2-vitest-vercel.txt`, `./evidence/r2-scratch-vercel.test.ts.txt`

---

## Claim 1b: "On Vercel, analytics history doesn't persist across cold starts" (platform-lifecycle half)

**Location:** `app/lib/analytics/persist.ts:6-7`
**Type:** Behavioral / Invariant
**Verdict:** Unverifiable
**Confidence:** High
**Verification mode:** static
**Scope:** Covers only the Vercel-platform property that `/tmp` contents are lost across cold starts; the local routing half is established separately as Claim 1a.
**Replicate verdicts:** r1=Unverifiable · r2=Unverifiable

Whether files under `/tmp` survive a Vercel Function cold start is a property of Vercel's runtime, not of this codebase. Verification would require deploying to Vercel and observing `/tmp` contents across a forced container recycle (paraphrased — no quote available because the claim is about an external platform's behavior, with no code to quote). Blocker: no Vercel deployment or platform access from the review sandbox. The claim is consistent with Vercel's documented ephemeral-`/tmp` model, but that is not sandbox-verifiable evidence. (r1 rated confidence High, r2 Medium; carrying r1's High.)

**Evidence:** `app/lib/analytics/persist.ts:6-7`, `app/lib/utils/dataDir.ts:7-10`

---

## Claim 2: "see Deploy to Vercel in README"

**Location:** `app/lib/analytics/persist.ts:6-7`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the existence of a "Deploy to Vercel" section (or any Vercel mention) in the repo's README and other documentation at HEAD; does not bear on the correctness of the surrounding persistence claims.
**Replicate verdicts:** r1=Incorrect · r2=Incorrect

Both replicates independently grep-proved that no such section exists — high-confidence Incorrect. The README contains no "Deploy to Vercel" section and no mention of Vercel or deployment at all. r1: `rg -i -n "vercel|deploy" README.md` returns zero matches (exit 1); the README's heading list runs from `# Metaformalism Copilot` through `## License` with no deployment section. r2: case-insensitive search for "vercel" across `README.md`, `CONTRIBUTING.md`, `docs/`, and `documentation/` returns zero hits (`grep -rn -i vercel README.md CONTRIBUTING.md docs documentation`, exit 1, 2026-08-18T06:43:56Z), and `CLAUDE.md` also has zero matches. The claim covers absence of content (paraphrased — no quote available because there is nothing to quote; the captured grep output and full heading list are in the evidence files). r2 additionally notes the reference predates this diff's refactor — the same phrase existed in commit 2136fd6's version of the comment — but it was never resolvable at any commit in this range. A reader sent to the README for cold-start/persistence caveats finds nothing.

**Evidence:** `README.md`, `./evidence/r1-readme-grep.txt`, `./evidence/r2-grep-readme.txt`

---

## Claim 3: "See dataDir() for the underlying rationale"

**Location:** `app/lib/analytics/persist.ts:7`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers only that `dataDir()` exists and carries the rationale docstring; does not evaluate whether the rationale itself is correct (that is Claims 8-9).
**Replicate verdicts:** r1=Verified · r2=Verified

`dataDir()` exists at the imported path (`app/lib/utils/dataDir.ts:12`) and its docstring carries the rationale the comment points to:

```ts
// app/lib/utils/dataDir.ts:6-10
 * On Vercel Functions only `/tmp` is writable, and it lives only as long as
 * the warm container — so persistence does not survive cold starts. In dev
 * and self-hosted deployments we write to the repo's `data/` dir for durable
 * cross-restart storage.
```

**Evidence:** `app/lib/utils/dataDir.ts:1-15`, `app/lib/analytics/persist.ts:4`

---

## Claim 4: "skip corrupt lines"

**Location:** `app/lib/analytics/persist.ts:31`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the per-line parse loop in `readAnalyticsEntries`; does not establish behavior if the whole-file `readFileSync` itself throws (that error propagates to the caller).
**Replicate verdicts:** r1=— · r2=Verified · single-replicate detection

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
**Replicate verdicts:** r1=— · r2=Verified · single-replicate detection

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

Executed (r2, cache-file-contents check): a scratch test wrote a cache entry via `setCachedResult` and confirmed (a) the on-disk file `/tmp/cache/<sha256-hex>.json` stores exactly `{ text, usage }` with the *original* usage (`provider: "anthropic"`, `costUsd: 0.5`, `latencyMs: 999`), and (b) `getCachedResult` returned `provider: "cache"`, `costUsd: 0`, `latencyMs: 0`, with untouched fields (`inputTokens: 10`) passed through and `cacheHash` equal to the sha256 hash. Command: `VERCEL=1 npx vitest run app/lib/utils/r2scratch-vercel.test.ts`, exit 0, 2026-08-18T06:42:38Z.

**Evidence:** `app/lib/llm/cache.ts:16-56`, `./evidence/r2-vitest-vercel.txt`, `./evidence/r2-scratch-vercel.test.ts.txt`

---

## Claim 6: "Corrupt or missing cache file — treat as miss"

**Location:** `app/lib/llm/cache.ts:57`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `getCachedResult`'s catch-all returning null for both corrupt JSON and a nonexistent file; does not establish behavior for other failure classes (e.g., permission errors), though the same catch would swallow them into a miss as well.
**Replicate verdicts:** r1=— · r2=Verified · single-replicate detection

```ts
// app/lib/llm/cache.ts:56-59
  } catch {
    // Corrupt or missing cache file — treat as miss
    return null;
  }
```

Executed (r2): the scratch test wrote `{not valid json` to the expected cache path and asserted `getCachedResult(...)` returned `null` (corrupt case), and asserted `null` for a hash whose file was never written (missing case). Both passed. The observer of the failure is the caller, which receives an ordinary cache miss. Command: `VERCEL=1 npx vitest run app/lib/utils/r2scratch-vercel.test.ts`, exit 0, 2026-08-18T06:42:38Z.

**Evidence:** `app/lib/llm/cache.ts:33-60`, `./evidence/r2-vitest-vercel.txt`, `./evidence/r2-scratch-vercel.test.ts.txt`

---

## Claim 7: "File doesn't exist — nothing to remove"

**Location:** `app/lib/llm/cache.ts:82`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `removeCachedResult` resolving without throwing when the target file is absent; does not establish behavior for non-ENOENT unlink failures (the same catch swallows those too).
**Replicate verdicts:** r1=— · r2=Verified · single-replicate detection

```ts
// app/lib/llm/cache.ts:79-84
  try {
    await unlink(filePath);
  } catch {
    // File doesn't exist — nothing to remove
  }
```

Executed (r2): the scratch test called `removeCachedResult` for inputs whose cache file was never created and asserted the promise resolves to `undefined` without throwing; passed. Command: `VERCEL=1 npx vitest run app/lib/utils/r2scratch-vercel.test.ts`, exit 0, 2026-08-18T06:42:38Z.

**Evidence:** `app/lib/llm/cache.ts:71-85`, `./evidence/r2-vitest-vercel.txt`, `./evidence/r2-scratch-vercel.test.ts.txt`

---

## Claim 8a: "On Vercel Functions only `/tmp` is writable"

**Location:** `app/lib/utils/dataDir.ts:7`
**Type:** Invariant
**Verdict:** Unverifiable
**Confidence:** High
**Verification mode:** static
**Scope:** Covers only the Vercel-platform writability property; does not bear on the code's routing behavior (Claim 9 / Claim 1a).
**Replicate verdicts:** r1=Unverifiable · r2=Unverifiable (as part of r2's compound Claim 8)

This asserts a filesystem property of Vercel's production runtime. It cannot be established from this codebase or exercised in the sandbox — it would require running inside a deployed Vercel Function and attempting writes outside `/tmp` (paraphrased — no quote available because the claim is about an external platform's behavior, with no code to quote). Blocker: no Vercel platform access from the review sandbox. (r2 verdicted this and Claim 8b as a single compound assertion, also Unverifiable; r1 split them, as reflected here.)

**Evidence:** `app/lib/utils/dataDir.ts:7`, `app/lib/utils/dataDir.ts:3-11`

---

## Claim 8b: "it lives only as long as the warm container — so persistence does not survive cold starts"

**Location:** `app/lib/utils/dataDir.ts:7-8`
**Type:** Invariant
**Verdict:** Unverifiable
**Confidence:** High
**Verification mode:** static
**Scope:** Covers only the Vercel `/tmp` lifetime property; same platform blocker as Claims 1b and 8a.
**Replicate verdicts:** r1=Unverifiable · r2=Unverifiable (as part of r2's compound Claim 8)

Same class as Claim 1b: `/tmp` lifetime on Vercel is a platform property requiring a deployed function observed across a cold start (paraphrased — no quote available because the claim is about an external platform's behavior, with no code to quote). Blocker: no Vercel deployment available in the sandbox.

**Evidence:** `app/lib/utils/dataDir.ts:7-8`

---

## Claim 9: "In dev and self-hosted deployments we write to the repo's `data/` dir for durable cross-restart storage"

**Location:** `app/lib/utils/dataDir.ts:8-10`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `dataDir()`'s return values and actual analytics/cache write destinations with `VERCEL` unset in this sandbox; "durable" is established only as ordinary on-disk persistence, not against any deployment topology.
**Replicate verdicts:** r1=Verified · r2=Verified

The non-Vercel branch resolves to the repo `data/` dir:

```ts
// app/lib/utils/dataDir.ts:12-15
export function dataDir(...subpaths: string[]): string {
  const base = process.env.VERCEL ? "/tmp" : join(process.cwd(), "data");
  return subpaths.length > 0 ? join(base, ...subpaths) : base;
}
```

Executed (both replicates, `VERCEL` unset): asserted `dataDir() === join(process.cwd(), "data")` and `dataDir("cache") === join(process.cwd(), "data", "cache")`, and that `appendAnalyticsEntry` (r1 also `setCachedResult`) actually created files under `<cwd>/data/` (paraphrased — no quote available because the assertion is the pass/fail outcome of the captured test run). r1: `npx vitest run app/lib/utils/dataDir.scratch.test.ts`, exit 0, 6/6 passed, 2026-08-18T06:42:19Z. r2: `env -u VERCEL npx vitest run app/lib/utils/r2scratch-local.test.ts`, exit 0, 2026-08-18T06:42:37Z. Ordinary files on disk persist across process restarts, which is all "durable cross-restart storage" asserts for a self-hosted process.

**Evidence:** `app/lib/utils/dataDir.ts:12-15`, `./evidence/r1-datadir-scratch-vitest.txt`, `./evidence/r1-datadir-scratch-test-source.ts.txt`, `./evidence/r2-vitest-local.txt`, `./evidence/r2-scratch-local.test.ts.txt`

---

## Claim 10: "The LLM cache and analytics log used to write to data/ at the project root"

**Location:** commit 2136fd6 (message, body)
**Type:** Behavioral / Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the pre-change path constants at base commit d86d2dc; does not establish anything about runtime behavior on Vercel, nor the read-only-on-Vercel assertion (Claim 11).
**Replicate verdicts:** r1=Verified · r2=Verified

The base-commit versions of both files hardcode the project-root `data/` paths:

```ts
// git show d86d2dc:app/lib/analytics/persist.ts (line 5)
const DATA_DIR = join(process.cwd(), "data");
```

```ts
// git show d86d2dc:app/lib/llm/cache.ts (line 6)
const CACHE_DIR = join(process.cwd(), "data", "cache");
```

**Evidence:** git objects `d86d2dc:app/lib/analytics/persist.ts`, `d86d2dc:app/lib/llm/cache.ts`, `app/lib/llm/cache.ts:7` (current)

---

## Claim 11: "data/ at the project root ... is read-only on Vercel Functions"

**Location:** commit 2136fd6 (message, body)
**Type:** Invariant
**Verdict:** Unverifiable
**Confidence:** High
**Verification mode:** static
**Scope:** Covers only the Vercel-platform read-only property of the deployed bundle's directory; same platform blocker as Claim 8a.
**Replicate verdicts:** r1=Unverifiable · r2=Unverifiable

Equivalent to Claim 8a restated from the other direction: whether the deployed project directory is read-only on Vercel Functions is a platform property, not checkable from the repo (paraphrased — no quote available because the claim is about an external platform's behavior). Blocker: no Vercel deployment available in the sandbox. (r1 confidence High, r2 Medium; carrying r1's High.)

**Evidence:** commit 2136fd6 message (`git log`), `app/lib/utils/dataDir.ts:7`

---

## Claim 12: "Writes were silently swallowed by upstream try/catch — features just degraded with no indication anything was off"

**Location:** commit 2136fd6 (message, body)
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the try/catch wrapping of every call site of `appendAnalyticsEntry`, `setCachedResult`, `getCachedResult`, and `clearAnalyticsEntries` at base d86d2dc; does not establish that write failures actually occur on Vercel (that is Claim 11).
**Replicate verdicts:** r1=Mostly accurate · r2=Verified

Most-severe-wins carries r1's **Mostly accurate**: the claim's mechanism and conclusion hold for the cache and analytics *log append* paths the commit is about, but stated universally it omits one write path that is **not** swallowed. The main write paths are indeed swallowed — at the base commit every `appendAnalyticsEntry` call site is wrapped:

```ts
// git show d86d2dc:app/lib/llm/callLlm.ts (lines ~84-91, unchanged at HEAD callLlm.ts:84-91)
  try {
    appendAnalyticsEntry({
      ...
    });
  } catch { /* persistence failure must not break LLM calls */ }
```

and the cache write likewise (`try { await setCachedResult(cacheHash, result); } catch { /* cache write failure is non-fatal */ }`). `getCachedResult` swallows internally (`app/lib/llm/cache.ts:56-59`), and the two `appendAnalyticsEntry` sites in `streamLlm.ts` (lines 55-62 and 148-155) are wrapped identically (paraphrased — no quote available because the four call sites are materially identical to the one quoted above; grep confirms these are all call sites outside persist.ts and tests). No catch block logs anything (which is what r2 verified, verdicting the claim Verified).

The qualifier r1 flags: one write path is NOT swallowed — the analytics DELETE route calls `clearAnalyticsEntries()` (which does `writeFileSync`) with no try/catch:

```ts
// app/api/analytics/route.ts:9-12 (identical at d86d2dc)
export async function DELETE() {
  clearAnalyticsEntries();
  return NextResponse.json({ ok: true });
}
```

so a read-only-filesystem write failure there would surface as an unhandled route error, not silent degradation. "Writes were silently swallowed" stated universally omits this path.

**Evidence:** `app/lib/llm/callLlm.ts:84-94`, `app/lib/llm/callLlm.ts:212-219`, `app/lib/llm/streamLlm.ts:55-62`, `app/lib/llm/streamLlm.ts:148-155`, `app/lib/llm/cache.ts:43-59`, `app/api/analytics/route.ts:9-12`, `git show d86d2dc:app/api/analytics/route.ts`

---

## Claim 13: "Switching to /tmp on Vercel ... at zero new dependencies"

**Location:** commit 2136fd6 (message, body)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the dependency manifest across d86d2dc...HEAD; does not cover runtime behavior.
**Replicate verdicts:** r1=Verified · r2=— · single-replicate detection

`git diff --stat d86d2dc...HEAD` touches only `app/lib/analytics/persist.ts`, `app/lib/llm/cache.ts`, and `app/lib/utils/dataDir.ts` — no `package.json` or lockfile change (paraphrased — no quote available because the claim covers absence of manifest changes in the diff stat). The new module imports only `path`:

```ts
// app/lib/utils/dataDir.ts:1
import { join } from "path";
```

**Evidence:** `git diff --stat d86d2dc...HEAD`, `app/lib/utils/dataDir.ts:1`

---

## Claim 14a: "Switching to /tmp on Vercel keeps both features working [writes to /tmp succeed and round-trip]" (local half)

**Location:** commit 2136fd6 (message, body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that with `VERCEL` set, analytics appends and cache write/read round-trips succeed against `/tmp` in this sandbox; does not establish behavior inside an actual Vercel Function (Claim 14b).
**Replicate verdicts:** r1=Verified (local half of r1's compound Claim 10b) · r2=Verified

Both replicates executed the local half. With `VERCEL=1`, the scratch test exercised both features end-to-end: `appendAnalyticsEntry` wrote and re-read `/tmp/analytics.jsonl`, and `setCachedResult`/`getCachedResult` round-tripped through `/tmp/cache/<hash>.json` (paraphrased — no quote available because the verdict aggregates the executed assertions already quoted under Claims 1a and 5). r1: `npx vitest run app/lib/utils/dataDir.scratch.test.ts`, exit 0, 6/6 passed, 2026-08-18T06:42:19Z. r2: `VERCEL=1 npx vitest run app/lib/utils/r2scratch-vercel.test.ts`, exit 0, 7/7 passed, 2026-08-18T06:42:38Z. (r1 wrapped this into a compound "keeps both features working within a warm container" that it rated Unverifiable under the most-severe-part rule; the Unverifiable is carried entirely by the platform half — Claim 14b — so the local half is Verified here.)

**Evidence:** `app/lib/utils/dataDir.ts:13`, `./evidence/r1-datadir-scratch-vitest.txt`, `./evidence/r1-datadir-scratch-test-source.ts.txt`, `./evidence/r2-vitest-vercel.txt`, `./evidence/r2-scratch-vercel.test.ts.txt`

---

## Claim 14b: "...keeps both features working within a warm container — /tmp lifetime is the warm container, so cache benefits and analytics history don't survive cold starts" (platform half)

**Location:** commit 2136fd6 (message, body)
**Type:** Invariant
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the per-instance/warm-container lifetime semantics of `/tmp` on Vercel; does not dispute the locally executed success path (Claim 14a).
**Replicate verdicts:** r1=Unverifiable (platform half of r1's compound Claim 10b) · r2=Unverifiable

Identical platform blocker to Claims 1b and 8: warm-container `/tmp` lifetime and cold-start data loss can only be observed on a deployed Vercel Function across a container recycle, which the sandbox cannot perform (paraphrased — no quote available because the claim's subject is external platform behavior, not repo code). Under the most-severe-part rule this half keeps the compound Unverifiable.

**Evidence:** commit 2136fd6 message (`git log`), `app/lib/utils/dataDir.ts:7-8`

---

## Claim 15: "Local dev is unchanged"

**Location:** commit 2136fd6 (message, body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers path resolution and write destinations with `VERCEL` unset, compared against the base commit's hardcoded paths; r1 additionally ran the full suite. Does not cover dev-server behavior end-to-end (`npm run dev` was not exercised).
**Replicate verdicts:** r1=Verified · r2=Verified

With `VERCEL` unset, the new code resolves to exactly the base commit's paths — `join(process.cwd(), "data")` and `join(process.cwd(), "data", "cache")` (quoted at Claim 9; base values quoted at Claim 10). Executed (both replicates): the scratch tests asserted those return values and actual write destinations with `VERCEL` unset (r1: 6/6 passed, exit 0, 2026-08-18T06:42:19Z; r2: `env -u VERCEL npx vitest run app/lib/utils/r2scratch-local.test.ts`, exit 0, 2026-08-18T06:42:37Z). r1 also ran the full suite: `npm test`, exit 0, "Tests  221 passed (221)", 2026-08-18T06:43:09Z.

**Evidence:** `app/lib/utils/dataDir.ts:13-14`, `./evidence/r1-datadir-scratch-vitest.txt`, `./evidence/r1-npm-test.txt`, `./evidence/r2-vitest-local.txt`, git objects `d86d2dc:app/lib/llm/cache.ts`, `d86d2dc:app/lib/analytics/persist.ts`

---

## Claim 16: "Both analytics and LLM cache had the same Vercel/dev branching pattern inline"

**Location:** commit b64c1ca (message, body)
**Type:** Architectural / Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the state of both files at the parent commit 2136fd6; does not assess whether centralizing was a good idea.
**Replicate verdicts:** r1=Verified · r2=Verified

At the refactor's parent commit, both files carried the inline ternary:

```ts
// git show 2136fd6:app/lib/analytics/persist.ts (line 9)
const DATA_DIR = process.env.VERCEL ? "/tmp" : join(process.cwd(), "data");
```

```ts
// git show 2136fd6:app/lib/llm/cache.ts (lines 9-11)
const CACHE_DIR = process.env.VERCEL
  ? "/tmp/cache"
  : join(process.cwd(), "data", "cache");
```

Both also carried near-duplicate rationale comments about `/tmp` writability and warm-container lifetime (paraphrased — no quote available because the two comment blocks were quoted-equivalent 3-4-line prose; see the git objects cited).

**Evidence:** git objects `2136fd6:app/lib/analytics/persist.ts`, `2136fd6:app/lib/llm/cache.ts`

---

## Claim 17: "No behavior change; both DATA_DIR and CACHE_DIR resolve to the same paths they did before"

**Location:** commit b64c1ca (message, body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the resolved values of `DATA_DIR` and `CACHE_DIR` in both env states relative to parent commit 2136fd6; does not cover any other module the refactor might have touched (it touched none) nor timing-of-evaluation differences (both versions compute the constants at module load).
**Replicate verdicts:** r1=Verified · r2=Verified

The parent's inline values (quoted at Claim 16) are `/tmp` / `/tmp/cache` with `VERCEL` set and `join(cwd, "data")` / `join(cwd, "data", "cache")` otherwise. The refactored `dataDir()`/`dataDir("cache")` produce the same four values:

```ts
// app/lib/utils/dataDir.ts:13-14
const base = process.env.VERCEL ? "/tmp" : join(process.cwd(), "data");
return subpaths.length > 0 ? join(base, ...subpaths) : base;
```

Executed (both replicates): the scratch tests asserted all four resolved values under both env states (`/tmp`, `/tmp/cache`, `<cwd>/data`, `<cwd>/data/cache`) — identical strings in all four cases. r1: `npx vitest run app/lib/utils/dataDir.scratch.test.ts`, exit 0, 6/6 passed, 2026-08-18T06:42:19Z. r2: `VERCEL=1 npx vitest run app/lib/utils/r2scratch-vercel.test.ts` (exit 0, 2026-08-18T06:42:38Z) and `env -u VERCEL npx vitest run app/lib/utils/r2scratch-local.test.ts` (exit 0, 2026-08-18T06:42:37Z).

**Evidence:** `app/lib/utils/dataDir.ts:13-14`, git objects `2136fd6:app/lib/analytics/persist.ts`, `2136fd6:app/lib/llm/cache.ts`, `./evidence/r1-datadir-scratch-vitest.txt`, `./evidence/r2-vitest-vercel.txt`, `./evidence/r2-vitest-local.txt`

---

## Claim 18: "Lint clean"

**Location:** commit b64c1ca (message, body)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `npm run lint` at HEAD b64c1ca on a clean tree; does not establish lint state at the moment the commit was authored, nor which commit introduced the two warnings (they are in a file untouched by this diff).
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate

Executed (both replicates): `npm run lint` exits 0 with zero errors, but is not warning-free — ESLint reports "✖ 2 problems (0 errors, 2 warnings)". Both warnings are pre-existing `react-hooks/exhaustive-deps` warnings in a workspace-persistence hook (r2 locates them at `app/page.tsx:209` and `app/page.tsx:271`), a file not touched by this diff (paraphrased — no quote available because the finding is the captured lint output, not repo source). "Lint clean" is right that the lint gate passes and the diff introduces no findings; strictly "clean" overstates a run that emits two warnings — "no new lint problems" would be precise. r1: `npm run lint`, exit 0, 2026-08-18T06:43:20Z. r2: `npm run lint`, exit 0, 2026-08-18T06:42:50Z.

**Evidence:** `./evidence/r1-npm-lint.txt`, `./evidence/r2-lint.txt`

---

## Claim 19: "221/221 tests pass"

**Location:** commit b64c1ca (message, body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the full vitest suite at HEAD b64c1ca on a clean tree; does not establish which tests cover the changed code specifically (no repo test imports `dataDir` — r2 verified separately by grep).
**Replicate verdicts:** r1=Verified · r2=Verified

Executed (both replicates): `npm test` (vitest run) reports exactly the claimed count — "Test Files  24 passed (24) / Tests  221 passed (221)" (paraphrased — no quote available because the finding is the captured test-runner output, not repo source). r1: exit 0, 2026-08-18T06:43:09Z (an earlier run reporting 224 tests included a concurrent replicate's scratch files, since removed; the clean-tree rerun matches the claim). r2: exit 0, run start 2026-08-18T06:42:58Z.

**Evidence:** `./evidence/r1-npm-test.txt`, `./evidence/r2-vitest-full.txt`

---

## Claims Requiring Attention

### Incorrect
- **Claim 2** (`app/lib/analytics/persist.ts:6-7`): "see Deploy to Vercel in README" — the README (and every other doc file) has no "Deploy to Vercel" section and no mention of Vercel or deployment. Both replicates grep-proved absence (high confidence). Either add the section or drop the reference.

### Mostly Accurate
- **Claim 12** (commit 2136fd6): "Writes were silently swallowed by upstream try/catch" — true for analytics appends and cache reads/writes, but `clearAnalyticsEntries()` in the analytics DELETE route (`app/api/analytics/route.ts:9-12`) writes with no try/catch, so a failure there surfaces as an unhandled route error rather than silent degradation. (r1 flagged; r2 rated Verified.)
- **Claim 18** (commit b64c1ca): "Lint clean" — lint exits 0 with zero errors but emits 2 pre-existing `react-hooks/exhaustive-deps` warnings in `app/page.tsx` (outside this diff). "No new lint problems" would be precise.

### Unverifiable
- **Claim 1b** (`app/lib/analytics/persist.ts:6-7`): Vercel `/tmp` non-persistence across cold starts — needs a deployed Vercel Function observed across a cold start.
- **Claim 8a** (`app/lib/utils/dataDir.ts:7`): "only `/tmp` is writable" on Vercel Functions — needs write attempts inside a deployed function.
- **Claim 8b** (`app/lib/utils/dataDir.ts:7-8`): `/tmp` lifetime = warm container — same platform blocker.
- **Claim 11** (commit 2136fd6): project dir read-only on Vercel Functions — same platform blocker.
- **Claim 14b** (commit 2136fd6): features "keep working within a warm container" / survive only the warm container — local `/tmp` write half established by execution (Claim 14a); platform half needs a Vercel deployment.

---

## Verdict stability

- **Total clusters:** 19 (top-level claim numbers), comprising 22 atomic claim sections after compound splits.
- **Clusters where both reporting replicates agreed:** 17 of the 19 top-level clusters. (Both-replicate clusters that agreed: 1a, 1b, 2, 3, 8, 9→"data/ durable", 10, 11, 14→branching-pattern, 15→no-behavior-change, 16→lint, "221/221". Single-replicate clusters — Claims 4, 5, 6, 7 from r2; Claim 13 from r1 — are agreements-by-default with no second sample, counted as agreed.)
- **Clusters where verdicts disagreed:** 2.
  1. **Claim 12** "Writes were silently swallowed" — r1=Mostly accurate (flags unguarded `clearAnalyticsEntries()` DELETE-route write), r2=Verified. Resolved to **Mostly accurate** (most-severe-wins).
  2. **Claim 14a/14b** "keeps both features working within a warm container" — r1 verdicted the sentence as one compound = Unverifiable; r2 split it into 12a (local round-trip, Verified) + 12b (warm-container platform, Unverifiable). Resolved by verdicting the atoms (decision 033): **14a Verified**, **14b Unverifiable**. The compound's Unverifiable is carried by the platform half; no genuine verdict conflict on either atom.
- **Agreement rate:** 17/19 ≈ 89% at the top-level-cluster grain. Only Claim 12 is a substantive verdict disagreement (Mostly accurate vs Verified); the Claim 14 divergence is a compound/atomic packaging difference, not a disagreement about any atomic claim's verdict.

## Goal-Alignment Note
- Answered: yes — merged both replicates into one most-severe-wins report.
- Out of scope: re-verifying claims against the target repo (blinded merge; not permitted).
- Escalate: nothing.
