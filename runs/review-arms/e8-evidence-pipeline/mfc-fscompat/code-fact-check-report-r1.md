# Code Fact-Check Report

**Commit:** b64c1ca
**Repository:** /workspace/external/cc-review-eval/mfc-fscompat
**Scope:** Files changed in `git diff d86d2dc...HEAD` (`app/lib/analytics/persist.ts`, `app/lib/llm/cache.ts`, `app/lib/utils/dataDir.ts`) plus the two commit messages (2136fd6, b64c1ca) and the README cross-reference they cite
**Checked:** 2026-08-18
**Total claims checked:** 17
**Summary:** 9 verified, 2 mostly accurate, 0 stale, 1 incorrect, 5 unverifiable

Provenance note: all executed verdicts ran in cwd `/workspace/external/cc-review-eval/mfc-fscompat` at HEAD b64c1ca with a clean working tree. Two earlier runs (23:41–23:42 UTC) were discarded because a concurrent replicate's scratch test files (`r2scratch-*.test.ts`) were present in the shared clone and contaminated test/lint counts; the runs cited below were re-executed after the tree was verified clean (`git status --short` empty). A pre-existing zero-byte `/workspace/external/package.json` above the clone broke vitest's dependency probe (exit 1 despite all tests passing); it temporarily contained `{}` during the cited runs and was restored to zero bytes afterward.

---

## Claim 1a: "On Vercel, analytics history [is written to a location that doesn't persist] — i.e., analytics writes are routed to `/tmp` when `VERCEL` is set" (mechanism half)

**Location:** `app/lib/analytics/persist.ts:6-8`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers where `appendAnalyticsEntry` writes with `VERCEL` set vs unset in this sandbox; does not establish anything about the actual Vercel platform (filesystem writability or container lifetime).

The comment sits on the constant:

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

Executed: scratch vitest (source preserved at `r1-datadir-scratch-test-source.ts.txt`) dynamically re-imports `persist.ts` with `VERCEL` toggled and asserts the write location. With `VERCEL=1`, `appendAnalyticsEntry` created `/tmp/analytics.jsonl` containing the marker entry and did not create `<cwd>/data/analytics.jsonl`; with `VERCEL` unset it wrote `<cwd>/data/analytics.jsonl` (paraphrased — no quote available because the assertion is the pass/fail outcome of the captured test run, not a source snippet). Command: `npx vitest run app/lib/utils/dataDir.scratch.test.ts`, cwd `/workspace/external/cc-review-eval/mfc-fscompat`, exit 0, 6/6 tests passed, 2026-08-18T06:42:19Z. All artifacts (`/tmp/analytics.jsonl`, `/tmp/cache`, `<cwd>/data`) were removed by the test's `afterAll` and the scratch file deleted.

**Evidence:** `app/lib/analytics/persist.ts:6-9`, `app/lib/utils/dataDir.ts:13`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-fscompat/evidence/r1-datadir-scratch-vitest.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-fscompat/evidence/r1-datadir-scratch-test-source.ts.txt`

---

## Claim 1b: "On Vercel, analytics history doesn't persist across cold starts" (platform half)

**Location:** `app/lib/analytics/persist.ts:6-7`
**Type:** Behavioral / Invariant
**Verdict:** Unverifiable
**Confidence:** High
**Verification mode:** static
**Scope:** Covers only the Vercel-platform property that `/tmp` contents are lost across cold starts; the local routing half is established separately as Claim 1a.

Whether files under `/tmp` survive a Vercel Function cold start is a property of Vercel's runtime, not of this codebase. Verification would require deploying to Vercel and observing `/tmp` contents across a cold start (paraphrased — no quote available because the claim is about an external platform's behavior, with no code to quote). Blocker: no Vercel deployment or platform access from the review sandbox. The claim is consistent with Vercel's documented ephemeral-`/tmp` model, but that is not sandbox-verifiable evidence.

**Evidence:** `app/lib/analytics/persist.ts:6-7`, `app/lib/utils/dataDir.ts:7-10`

---

## Claim 2: "see Deploy to Vercel in README"

**Location:** `app/lib/analytics/persist.ts:6-7`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers only the existence of the referenced README section; does not bear on the correctness of the surrounding persistence claims.

The README contains no "Deploy to Vercel" section and no mention of Vercel or deployment at all: `rg -i -n "vercel|deploy" README.md` returns zero matches (exit 1), and the README's heading list runs from `# Metaformalism Copilot` through `## License` with no deployment section (paraphrased — no quote available because the claim covers absence of content; the captured grep output and full heading list are in the evidence file). A reader sent to the README for cold-start/persistence caveats will find nothing.

**Evidence:** `README.md`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-fscompat/evidence/r1-readme-grep.txt`

---

## Claim 3: "See dataDir() for the underlying rationale"

**Location:** `app/lib/analytics/persist.ts:7`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers only that `dataDir()` exists and carries the rationale docstring; does not evaluate whether the rationale itself is correct (that is Claims 4-6).

`dataDir` exists at the imported path and its docstring carries the rationale:

```ts
// app/lib/utils/dataDir.ts:6-10
 * On Vercel Functions only `/tmp` is writable, and it lives only as long as
 * the warm container — so persistence does not survive cold starts. In dev
 * and self-hosted deployments we write to the repo's `data/` dir for durable
 * cross-restart storage.
```

**Evidence:** `app/lib/utils/dataDir.ts:1-15`, `app/lib/analytics/persist.ts:4`

---

## Claim 4: "On Vercel Functions only `/tmp` is writable"

**Location:** `app/lib/utils/dataDir.ts:7`
**Type:** Invariant
**Verdict:** Unverifiable
**Confidence:** High
**Verification mode:** static
**Scope:** Covers only the Vercel-platform writability property; does not bear on the code's routing behavior (Claim 6 / Claim 1a).

This asserts a filesystem property of Vercel's production runtime. It cannot be established from this codebase or exercised in the sandbox — it would require running inside a deployed Vercel Function and attempting writes outside `/tmp` (paraphrased — no quote available because the claim is about an external platform's behavior, with no code to quote). Blocker: no Vercel platform access from the review sandbox.

**Evidence:** `app/lib/utils/dataDir.ts:7`

---

## Claim 5: "it lives only as long as the warm container — so persistence does not survive cold starts"

**Location:** `app/lib/utils/dataDir.ts:7-8`
**Type:** Invariant
**Verdict:** Unverifiable
**Confidence:** High
**Verification mode:** static
**Scope:** Covers only the Vercel `/tmp` lifetime property; same platform blocker as Claims 1b and 4.

Same class as Claim 1b: `/tmp` lifetime on Vercel is a platform property requiring a deployed function observed across a cold start (paraphrased — no quote available because the claim is about an external platform's behavior, with no code to quote). Blocker: no Vercel deployment available in the sandbox.

**Evidence:** `app/lib/utils/dataDir.ts:7-8`

---

## Claim 6: "In dev and self-hosted deployments we write to the repo's `data/` dir for durable cross-restart storage"

**Location:** `app/lib/utils/dataDir.ts:8-10`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `dataDir()`'s return values and actual analytics/cache write destinations with `VERCEL` unset in this sandbox; "durable" is established only as ordinary on-disk persistence, not against any deployment topology.

The non-Vercel branch resolves to the repo `data/` dir:

```ts
// app/lib/utils/dataDir.ts:13-14
const base = process.env.VERCEL ? "/tmp" : join(process.cwd(), "data");
return subpaths.length > 0 ? join(base, ...subpaths) : base;
```

Executed: the scratch vitest asserted `dataDir() === join(process.cwd(), "data")` and `dataDir("cache") === join(process.cwd(), "data", "cache")` with `VERCEL` deleted, and that `appendAnalyticsEntry` and `setCachedResult` actually created files under `<cwd>/data/` and `<cwd>/data/cache/` respectively (paraphrased — no quote available because the assertion is the pass/fail outcome of the captured test run). Command: `npx vitest run app/lib/utils/dataDir.scratch.test.ts`, cwd `/workspace/external/cc-review-eval/mfc-fscompat`, exit 0, 6/6 passed, 2026-08-18T06:42:19Z. Ordinary files on disk persist across process restarts, which is all "durable cross-restart storage" asserts for a self-hosted process.

**Evidence:** `app/lib/utils/dataDir.ts:12-15`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-fscompat/evidence/r1-datadir-scratch-vitest.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-fscompat/evidence/r1-datadir-scratch-test-source.ts.txt`

---

## Claim 7: "The LLM cache and analytics log used to write to data/ at the project root"

**Location:** commit 2136fd6 (message, body)
**Type:** Behavioral / Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the pre-change constants at base commit d86d2dc; does not establish anything about runtime behavior on Vercel.

The base-commit versions of both files hardcode the project-root `data/` paths, visible in the diff's removed lines:

```ts
// git diff d86d2dc...HEAD, app/lib/analytics/persist.ts (removed line)
-const DATA_DIR = join(process.cwd(), "data");
```

```ts
// git diff d86d2dc...HEAD, app/lib/llm/cache.ts (removed line)
-const CACHE_DIR = join(process.cwd(), "data", "cache");
```

**Evidence:** `git diff d86d2dc...HEAD` over `app/lib/analytics/persist.ts:5`, `app/lib/llm/cache.ts:7` (pre-change)

---

## Claim 8: "data/ at the project root ... is read-only on Vercel Functions"

**Location:** commit 2136fd6 (message, body)
**Type:** Invariant
**Verdict:** Unverifiable
**Confidence:** High
**Verification mode:** static
**Scope:** Covers only the Vercel-platform read-only property of the deployed bundle's directory; same platform blocker as Claim 4.

Equivalent to Claim 4 restated from the other direction: whether the deployed project directory is read-only on Vercel Functions is a platform property, not checkable from the repo (paraphrased — no quote available because the claim is about an external platform's behavior). Blocker: no Vercel deployment available in the sandbox.

**Evidence:** commit 2136fd6 message

---

## Claim 9: "Writes were silently swallowed by upstream try/catch — features just degraded with no indication anything was off"

**Location:** commit 2136fd6 (message, body)
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the try/catch wrapping of every call site of `appendAnalyticsEntry`, `setCachedResult`, `getCachedResult`, and `clearAnalyticsEntries` at base d86d2dc; does not establish that write failures actually occur on Vercel (that is Claim 8).

The main write paths are indeed swallowed. At the base commit, every `appendAnalyticsEntry` call site is wrapped, e.g.:

```ts
// git show d86d2dc:app/lib/llm/callLlm.ts (lines ~84-91, unchanged at HEAD callLlm.ts:84-91)
  try {
    appendAnalyticsEntry({
      ...
    });
  } catch { /* persistence failure must not break LLM calls */ }
```

and the cache write likewise:

```ts
// git show d86d2dc:app/lib/llm/callLlm.ts (line 94, unchanged at HEAD)
    try { await setCachedResult(cacheHash, result); } catch { /* cache write failure is non-fatal */ }
```

`getCachedResult` swallows internally ("Corrupt or missing cache file — treat as miss", `app/lib/llm/cache.ts:56-59`). The two `appendAnalyticsEntry` sites in `streamLlm.ts` (lines 55-62 and 148-155 at HEAD, same at base) are wrapped identically (paraphrased — no quote available because the four call sites are materially identical to the one quoted above). The qualifier the claim misses: one write path is NOT swallowed — the analytics DELETE route calls `clearAnalyticsEntries()` (which does `writeFileSync`) with no try/catch:

```ts
// app/api/analytics/route.ts:9-12 (identical at d86d2dc)
export async function DELETE() {
  clearAnalyticsEntries();
  return NextResponse.json({ ok: true });
}
```

so a read-only-filesystem write failure there would surface as an unhandled route error, not silent degradation. The claim's mechanism and conclusion hold for the cache and the analytics *log append* paths the commit is about, but "writes were silently swallowed" stated universally omits this path.

**Evidence:** `app/lib/llm/callLlm.ts:84-94`, `app/lib/llm/callLlm.ts:212-219`, `app/lib/llm/streamLlm.ts:55-62`, `app/lib/llm/streamLlm.ts:148-155`, `app/lib/llm/cache.ts:43-59`, `app/api/analytics/route.ts:9-12`, `git show d86d2dc:app/api/analytics/route.ts`

---

## Claim 10a: "Switching to /tmp on Vercel ... at zero new dependencies"

**Location:** commit 2136fd6 (message, body)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the dependency manifest across d86d2dc...HEAD; does not cover runtime behavior.

`git diff --stat d86d2dc...HEAD` touches only `app/lib/analytics/persist.ts`, `app/lib/llm/cache.ts`, and `app/lib/utils/dataDir.ts` — no `package.json` or lockfile change (paraphrased — no quote available because the claim covers absence of manifest changes in the diff stat). The new module imports only `path`:

```ts
// app/lib/utils/dataDir.ts:1
import { join } from "path";
```

**Evidence:** `git diff --stat d86d2dc...HEAD`, `app/lib/utils/dataDir.ts:1`

---

## Claim 10b: "Switching to /tmp on Vercel keeps both features working within a warm container"

**Location:** commit 2136fd6 (message, body)
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** The local half — that with `VERCEL` set, analytics and cache writes succeed into `/tmp` and are readable back — is established by execution; the platform half (that this makes the features work in a real warm Vercel container) is not establishable from the sandbox.

Executed (local half): the scratch vitest showed that with `VERCEL=1`, `appendAnalyticsEntry` successfully wrote `/tmp/analytics.jsonl` and `setCachedResult` successfully wrote `/tmp/cache/<hash>.json` (paraphrased — no quote available because the assertion is the pass/fail outcome of the captured test run). Command: `npx vitest run app/lib/utils/dataDir.scratch.test.ts`, cwd `/workspace/external/cc-review-eval/mfc-fscompat`, exit 0, 6/6 passed, 2026-08-18T06:42:19Z. The platform half — that Vercel's `/tmp` is writable and shared within a warm container so the features "work" there — requires a Vercel deployment; blocker: no platform access. Under the most-severe-part rule the compound verdict stays Unverifiable.

**Evidence:** `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-fscompat/evidence/r1-datadir-scratch-vitest.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-fscompat/evidence/r1-datadir-scratch-test-source.ts.txt`, `app/lib/utils/dataDir.ts:13`

---

## Claim 11: "Local dev is unchanged"

**Location:** commit 2136fd6 (message, body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers path resolution and write destinations with `VERCEL` unset, plus the full test suite passing at HEAD; does not cover dev-server behavior end-to-end (`npm run dev` was not exercised).

With `VERCEL` unset, the new code resolves to exactly the base commit's paths — `join(process.cwd(), "data")` and `join(process.cwd(), "data", "cache")` (quoted at Claim 6 from `app/lib/utils/dataDir.ts:13-14`; base values quoted at Claim 7). Executed: the scratch vitest asserted those return values and actual write destinations with `VERCEL` deleted (6/6 passed, exit 0, 2026-08-18T06:42:19Z), and the full suite passes at HEAD: `npm test`, cwd `/workspace/external/cc-review-eval/mfc-fscompat`, exit 0, "Tests  221 passed (221)", 2026-08-18T06:43:09Z.

**Evidence:** `app/lib/utils/dataDir.ts:13-14`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-fscompat/evidence/r1-datadir-scratch-vitest.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-fscompat/evidence/r1-npm-test.txt`

---

## Claim 12: "Both analytics and LLM cache had the same Vercel/dev branching pattern inline"

**Location:** commit b64c1ca (message, body)
**Type:** Architectural / Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the state of both files at the parent commit 2136fd6; does not assess whether centralizing was a good idea.

At the refactor's parent commit, both files carried the ternary inline:

```ts
// git show 2136fd6:app/lib/analytics/persist.ts (line 9)
const DATA_DIR = process.env.VERCEL ? "/tmp" : join(process.cwd(), "data");
```

```ts
// git show 2136fd6:app/lib/llm/cache.ts (lines 9-10)
const CACHE_DIR = process.env.VERCEL
  ? "/tmp/cache"
```

**Evidence:** `git show 2136fd6:app/lib/analytics/persist.ts`, `git show 2136fd6:app/lib/llm/cache.ts`

---

## Claim 13: "No behavior change; both DATA_DIR and CACHE_DIR resolve to the same paths they did before"

**Location:** commit b64c1ca (message, body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the resolved values of `DATA_DIR` and `CACHE_DIR` in both env states relative to parent commit 2136fd6; does not cover any other module the refactor might have touched (it touched none).

The parent's inline values (quoted at Claim 12) are `/tmp` / `/tmp/cache` with `VERCEL` set and `join(cwd, "data")` / `join(cwd, "data", "cache")` otherwise. The refactored `dataDir()`/`dataDir("cache")` produce the same four values:

```ts
// app/lib/utils/dataDir.ts:13-14
const base = process.env.VERCEL ? "/tmp" : join(process.cwd(), "data");
return subpaths.length > 0 ? join(base, ...subpaths) : base;
```

Executed: the scratch vitest asserted all four resolved values under both env states (`/tmp`, `/tmp/cache`, `<cwd>/data`, `<cwd>/data/cache`) — `npx vitest run app/lib/utils/dataDir.scratch.test.ts`, cwd `/workspace/external/cc-review-eval/mfc-fscompat`, exit 0, 6/6 passed, 2026-08-18T06:42:19Z.

**Evidence:** `app/lib/utils/dataDir.ts:13-14`, `git show 2136fd6:app/lib/analytics/persist.ts`, `git show 2136fd6:app/lib/llm/cache.ts`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-fscompat/evidence/r1-datadir-scratch-vitest.txt`

---

## Claim 14: "Lint clean"

**Location:** commit b64c1ca (message, body)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `npm run lint` at HEAD b64c1ca on a clean tree; does not establish lint state at the moment the commit was authored.

Executed: `npm run lint`, cwd `/workspace/external/cc-review-eval/mfc-fscompat`, exit 0, 2026-08-18T06:43:20Z. ESLint exits successfully with zero errors, but reports "✖ 2 problems (0 errors, 2 warnings)" — two pre-existing `react-hooks/exhaustive-deps` warnings in a workspace-persistence hook unrelated to this diff (paraphrased — no quote available because the finding is the captured lint output, not repo source). "Lint clean" is right that the lint gate passes and the diff introduces no findings; strictly "clean" overstates a run that emits two warnings.

**Evidence:** `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-fscompat/evidence/r1-npm-lint.txt`

---

## Claim 15: "221/221 tests pass"

**Location:** commit b64c1ca (message, body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the vitest suite at HEAD b64c1ca on a clean tree; does not establish which tests cover the changed code specifically.

Executed: `npm test` (vitest run), cwd `/workspace/external/cc-review-eval/mfc-fscompat`, exit 0, 2026-08-18T06:43:09Z. Output: "Test Files  24 passed (24) / Tests  221 passed (221)" — exactly the claimed count (paraphrased — no quote available because the finding is the captured test-runner output, not repo source). An earlier run reported 224 tests; that count included a concurrent replicate's scratch test files, since removed — the clean-tree rerun matches the claim exactly.

**Evidence:** `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-fscompat/evidence/r1-npm-test.txt`

---

## Claims Requiring Attention

### Incorrect
- **Claim 2** (`app/lib/analytics/persist.ts:6-7`): "see Deploy to Vercel in README" — the README has no "Deploy to Vercel" section and no mention of Vercel or deployment; either add the section or drop the reference.

### Mostly Accurate
- **Claim 9** (commit 2136fd6): "Writes were silently swallowed by upstream try/catch" — true for analytics appends and cache reads/writes, but `clearAnalyticsEntries()` in the analytics DELETE route (`app/api/analytics/route.ts:9-12`) writes with no try/catch.
- **Claim 14** (commit b64c1ca): "Lint clean" — lint exits 0 with zero errors but emits 2 pre-existing `react-hooks/exhaustive-deps` warnings.

### Unverifiable
- **Claim 1b** (`app/lib/analytics/persist.ts:6-7`): Vercel `/tmp` non-persistence across cold starts — needs a deployed Vercel Function observed across a cold start.
- **Claim 4** (`app/lib/utils/dataDir.ts:7`): "only `/tmp` is writable" on Vercel Functions — needs write attempts inside a deployed function.
- **Claim 5** (`app/lib/utils/dataDir.ts:7-8`): `/tmp` lifetime = warm container — same platform blocker.
- **Claim 8** (commit 2136fd6): project dir read-only on Vercel Functions — same platform blocker.
- **Claim 10b** (commit 2136fd6): features "keep working within a warm container" on Vercel — local `/tmp` write half established by execution; platform half needs a Vercel deployment.
