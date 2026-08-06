# Code Fact-Check Report

**Repository:** meta-formalism-copilot (pinned worktree /workspace/runs/review-arms/e1/wt-fscompat-clean, detached at 2cd3b67)
**Scope:** `git diff d86d2dc..2cd3b67` (app/lib/analytics/persist.ts, app/lib/llm/cache.ts, app/lib/utils/dataDir.ts, app/lib/utils/dataDir.test.ts) plus commit messages 2136fd6, b64c1ca, 2cd3b67
**Checked:** 2026-08-06
**Total claims checked:** 14 (merged clusters from 3 replicates: 13 + 16 + 11 raw claims)
**Summary:** 9 Verified, 3 Mostly accurate, 2 Unverifiable, 0 Stale, 0 Incorrect. The dataDir extraction and its review-fix commit are documented accurately: path equivalence holds across all commit states, the per-instance caveat landed, the broken README cross-reference is fully gone, the new test genuinely pins both env branches, and the static test count reconciles exactly (221 + 3 = 224). The three Mostly-accurate findings are wording-level: a test title says "unset" while the test stubs an empty string; "dead-code" overstates a guard whose both branches were live (redundant, not dead); and "the codebase convention" generalizes from a very small sample. Lint/test execution outcomes are unverifiable under the static-only mandate; two clusters show replicate disagreement (both resolved most-severe-wins).

**Commit:** 2cd3b67
**Replication:** k=3

## Claim 1: persist.ts Vercel-persistence comment and self-contained dataDir() pointer

**Location:** app/lib/analytics/persist.ts:6-7
**Type:** Behavioral / reference
**Verdict:** Verified
**Confidence:** High — the pointer target exists in-repo and the behavior chain (dataDir → /tmp → warm-container lifetime) is directly readable.
**Legibility-target:** for-orchestrator-synthesis

The comment reads:

> `// On Vercel, analytics history doesn't persist across cold starts and is`
> `// per-Function-instance. See dataDir() for the underlying rationale.` (app/lib/analytics/persist.ts:6-7)

`DATA_DIR = dataDir()` (app/lib/analytics/persist.ts:8) resolves to `/tmp` when `process.env.VERCEL` is set (`return process.env.VERCEL ? "/tmp" : join(process.cwd(), "data");`, app/lib/utils/dataDir.ts:15), and `dataDir()`'s docstring carries the rationale the comment points to (app/lib/utils/dataDir.ts:7-11), including both the cold-start and per-instance halves. The cross-reference is self-contained: it points at a function in this repo, not at a README section. The behavioral content matches the docstring and Vercel's documented `/tmp` semantics (paraphrased — no quote available because the Vercel platform behavior is external to the repo).

**Evidence:** app/lib/analytics/persist.ts:6-8; app/lib/utils/dataDir.ts:7-15.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

## Claim 2: cache.ts `join(dataDir(), "cache")` path equivalence across all historical states

**Location:** app/lib/llm/cache.ts:7
**Type:** Behavioral / invariant
**Verdict:** Verified
**Confidence:** High — pure path arithmetic over the readable file versions.
**Legibility-target:** for-orchestrator-synthesis

Post-fix: `const CACHE_DIR = join(dataDir(), "cache");` (app/lib/llm/cache.ts:7). Pre-fix (b64c1ca): `const CACHE_DIR = dataDir("cache");` where `dataDir(...subpaths)` returned `subpaths.length > 0 ? join(base, ...subpaths) : base` (b64c1ca app/lib/utils/dataDir.ts) — i.e. `join(base, "cache")`, identical to the post-fix expression. First in-range state (2136fd6): `process.env.VERCEL ? "/tmp/cache" : join(process.cwd(), "data", "cache")` — `join("/tmp", "cache")` normalizes to `/tmp/cache` and the non-Vercel arm is associatively identical to `join(join(cwd, "data"), "cache")`. Pre-range (d86d2dc): `const CACHE_DIR = join(process.cwd(), "data", "cache");` — matches the post-fix non-Vercel arm exactly; the Vercel arm intentionally differs (that divergence is the feature 2136fd6 introduced, not drift). The "match the persist.ts pattern" claim also holds: persist.ts uses `const DATA_DIR = dataDir(); const FILE_PATH = join(DATA_DIR, ...)` (app/lib/analytics/persist.ts:8-9).

**Evidence:** app/lib/llm/cache.ts:7; `git show b64c1ca:app/lib/utils/dataDir.ts` lines 13-16; `git show 2136fd6:app/lib/llm/cache.ts` lines 9-11; `git show d86d2dc:app/lib/llm/cache.ts` line 6.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

## Claim 3: dataDir.test.ts pins both branches of the env switch (header comment + commit claim)

**Location:** app/lib/utils/dataDir.test.ts:5-7 (also commit 2cd3b67 message: "Add dataDir.test.ts pinning both branches of the env switch")
**Type:** Invariant / behavioral
**Verdict:** Verified
**Confidence:** High — both branches are directly asserted and each assertion is falsified by flipping the branch it covers.
**Legibility-target:** for-orchestrator-synthesis

> `// Cheap unit test for an asymmetric deploy invariant: the Vercel branch`
> `// of dataDir() is invisible in local dev, so a refactor that flips or`
> `// deletes it would never be caught by lint/types/build. Pin both branches.` (app/lib/utils/dataDir.test.ts:5-7)

The Vercel branch is pinned by `vi.stubEnv("VERCEL", "1"); expect(dataDir()).toBe("/tmp");` (app/lib/utils/dataDir.test.ts:19-20) and by the truthy-value variant at lines 24-25 (`"preview"` → `/tmp`); the non-Vercel branch by `expect(dataDir()).toBe(join(originalCwd, "data"))` (app/lib/utils/dataDir.test.ts:29-30). If `dataDir()` always returned `/tmp` the third test fails; if it always returned `<cwd>/data` the first two fail — so the tests would catch a flipped or deleted branch. The lint/types/build claim is sound: the ternary in dataDir.ts:15 type-checks identically in either orientation (paraphrased — no quote available because the claim is about the absence of a check, which has no code location). The env manipulation is sound: `dataDir()` reads `process.env.VERCEL` at call time, not module load (app/lib/utils/dataDir.ts:15), so `vi.stubEnv` takes effect, and `vi.unstubAllEnvs()` in both `beforeEach` and `afterEach` (app/lib/utils/dataDir.test.ts:12-16) prevents leakage between tests and out of the file.

**Evidence:** app/lib/utils/dataDir.test.ts:5-31; app/lib/utils/dataDir.ts:15.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

## Claim 4: test title "returns <cwd>/data when VERCEL is unset"

**Location:** app/lib/utils/dataDir.test.ts:28
**Type:** Behavioral (test description)
**Verdict:** Mostly accurate
**Confidence:** High — the discrepancy is directly readable in the two adjacent lines.
**Legibility-target:** for-author

> `it("returns <cwd>/data when VERCEL is unset", () => {` followed by `vi.stubEnv("VERCEL", "");` (app/lib/utils/dataDir.test.ts:28-29)

The test does not unset `VERCEL`; it stubs it to the empty string — a set-but-falsy value, not an absent variable. That is behaviorally equivalent for `process.env.VERCEL ? ... : ...` (both `undefined` and `""` are falsy), so the branch-coverage claim in Claim 3 stands, but "unset" is not literally what the test exercises. If the implementation ever changed to a presence check (`"VERCEL" in process.env`), this test would pass for the wrong reason while genuinely-unset behavior went untested. Minor wording drift only.

**Evidence:** app/lib/utils/dataDir.test.ts:28-30; app/lib/utils/dataDir.ts:15.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate

## Claim 5: dataDir() docstring — /tmp-only writability, warm-container lifetime, per-instance isolation, dev data/ path

**Location:** app/lib/utils/dataDir.ts:3-13
**Type:** Behavioral / architectural / configuration
**Verdict:** Verified
**Confidence:** High for the code-side claims; Medium for the Vercel-platform facts, which are external to the repo but match Vercel's documented `/tmp` semantics.
**Legibility-target:** for-orchestrator-synthesis

The post-fix docstring states: "On Vercel Functions only `/tmp` is writable. `/tmp` lives only as long as a warm container, so persistence does not survive cold starts; it is also per-instance, so concurrent Function instances each see their own independent contents (no cross-instance sharing). In dev and self-hosted deployments we write to the repo's `data/` dir" (app/lib/utils/dataDir.ts:7-12). The per-Function-instance caveat requested in review is present and correctly framed; the claim that it was *added* in the review-fix commit is confirmed — the b64c1ca docstring mentioned only cold-start lifetime with no per-instance sentence (`git show b64c1ca:app/lib/utils/dataDir.ts` lines 7-8). The env gate matches: `return process.env.VERCEL ? "/tmp" : join(process.cwd(), "data");` (app/lib/utils/dataDir.ts:15). Vercel sets `VERCEL=1` in all deployment environments, so the gate selects `/tmp` exactly on Vercel and `data/` in dev/self-hosted (paraphrased — no quote available because the env-var contract is Vercel platform documentation). Edge case, not a doc error: a self-hosted deploy that exports `VERCEL` itself would be misrouted to `/tmp`.

**Evidence:** app/lib/utils/dataDir.ts:3-16; consumers at app/lib/analytics/persist.ts:8 and app/lib/llm/cache.ts:7; `git show b64c1ca:app/lib/utils/dataDir.ts` lines 7-8.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

## Claim 6: Commit 2136fd6 — "Writes were silently swallowed by upstream try/catch" and read-only project root on Vercel

**Location:** commit 2136fd6 message
**Type:** Behavioral (historical)
**Verdict:** Verified
**Confidence:** High for the try/catch claim (all call sites read); Medium for the read-only-filesystem platform fact.
**Legibility-target:** for-orchestrator-synthesis

Every write path is wrapped by callers: `try { await setCachedResult(cacheHash, result); } catch { /* cache write failure is non-fatal */ }` (app/lib/llm/callLlm.ts:94); same pattern at app/lib/llm/streamLlm.ts:64; and all four `appendAnalyticsEntry` call sites sit inside `try {` blocks (app/lib/llm/callLlm.ts:84-85, 212-213; app/lib/llm/streamLlm.ts:55-56, 148-149). `getCachedResult` additionally swallows its own read errors (`catch { ... return null; }`, app/lib/llm/cache.ts:56-59). So on a read-only filesystem, writes would indeed fail without surfacing. The pre-change constants wrote to the project root: `const DATA_DIR = join(process.cwd(), "data");` (`git show d86d2dc:app/lib/analytics/persist.ts` line 5) and `const CACHE_DIR = join(process.cwd(), "data", "cache");` (`git show d86d2dc:app/lib/llm/cache.ts` line 6). Vercel Functions' deployment filesystem being read-only outside `/tmp` is platform behavior (paraphrased — no quote available because it is external to the repo).

**Evidence:** app/lib/llm/callLlm.ts:84-94, 212-213; app/lib/llm/streamLlm.ts:55-64, 148-149; app/lib/llm/cache.ts:56-59; `git show d86d2dc:app/lib/analytics/persist.ts`; `git show d86d2dc:app/lib/llm/cache.ts`.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=—

## Claim 7: Commit b64c1ca — "No behavior change; both DATA_DIR and CACHE_DIR resolve to the same paths they did before"

**Location:** commit b64c1ca message
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High — mechanical path comparison between 2136fd6 and b64c1ca file states.
**Legibility-target:** for-orchestrator-synthesis

"Before" = 2136fd6: `DATA_DIR = process.env.VERCEL ? "/tmp" : join(process.cwd(), "data")` (2136fd6:app/lib/analytics/persist.ts:9) and `CACHE_DIR = process.env.VERCEL ? "/tmp/cache" : join(process.cwd(), "data", "cache")` (2136fd6:app/lib/llm/cache.ts:9-11). After: `DATA_DIR = dataDir()` and `CACHE_DIR = dataDir("cache")`, with `dataDir` returning the identical base and `join(base, "cache")` respectively (b64c1ca:app/lib/utils/dataDir.ts:12-15). Resolutions match branch-for-branch.

**Evidence:** `git show b64c1ca:app/lib/utils/dataDir.ts` lines 13-14; `git show 2136fd6:app/lib/analytics/persist.ts` line 9; `git show 2136fd6:app/lib/llm/cache.ts` lines 9-11.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

## Claim 8: Commit b64c1ca — "221/221 tests pass" (static count)

**Location:** commit b64c1ca message, final line
**Type:** Reference (static verification only)
**Verdict:** Verified
**Confidence:** High for the count arithmetic (static); the pass/fail outcome itself was not re-executed.
**Legibility-target:** for-orchestrator-synthesis

Static count of `it(`/`test(` declarations across `*.test.*` files at b64c1ca sums to 221 (`git grep -E "^\s*(it|test)(\.each)?\(" b64c1ca -- '*.test.ts' '*.test.tsx' | wc -l` → 221), matching "221/221" exactly. No `it.each`/`test.each` table-driven multipliers exist in the test tree (empty grep), so declaration count is a faithful proxy for run count (paraphrased — no quote available because the evidence is a computed count). The "pass" half is consistent with, but not proven by, static counting; see Claim 13 for the shared execution caveat.

**Evidence:** git grep count at b64c1ca = 221; empty grep for `it\.each|test\.each`.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

## Claim 9: Commit 2cd3b67 — rest-args "only used in one of two callsites and the codebase convention is 'base const + join at callsite'"

**Location:** commit 2cd3b67 message; app/lib/utils/dataDir.ts:14 (signature change)
**Type:** Architectural / reference
**Verdict:** Mostly accurate
**Confidence:** High — the callsite count is exact; the "convention" characterization is the imprecise part.
**Legibility-target:** for-author

"Only used in one of two callsites" is exact: at b64c1ca, cache.ts used the rest-args form (`const CACHE_DIR = dataDir("cache");`) while persist.ts called it bare (`const DATA_DIR = dataDir();`), and these were the only two consumers (rg for `dataDir` finds only persist.ts, cache.ts, dataDir.ts, dataDir.test.ts). The signature change is real (`dataDir(...subpaths: string[])` → `dataDir(): string`) and both consumers now use the same pattern: `const DATA_DIR = dataDir(); const FILE_PATH = join(DATA_DIR, "analytics.jsonl");` (app/lib/analytics/persist.ts:8-9) and `const CACHE_DIR = join(dataDir(), "cache");` (app/lib/llm/cache.ts:7). However, "the codebase convention" overstates the evidence: the only dir-const definitions in the repo are these same two files (rg for `const \w+_DIR` matches only persist.ts:8-9 and cache.ts:7), so the convention is attested by an n=2 sample consisting entirely of the files under change — one of which (pre-range cache.ts, `join(process.cwd(), "data", "cache")`) did follow base-plus-join composition. The pattern claim is true of the repo but the population is too small to call a "codebase convention." (r2, splitting the claim, rated the callsite census Verified and the convention Verified at Medium confidence on the same small-sample caveat; r3 additionally found `verifier/server.ts:14-17` following the pattern but likewise rated the bundle Mostly accurate for the thin generalization base.)

**Evidence:** `git show b64c1ca:app/lib/llm/cache.ts` line 7; `git show b64c1ca:app/lib/analytics/persist.ts` line 8; app/lib/utils/dataDir.ts:14-16; app/lib/analytics/persist.ts:8-9; app/lib/llm/cache.ts:7; rg results for `dataDir` and `const \w+_DIR`.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Mostly accurate

## Claim 10: Commit 2cd3b67 — "kills the dead-code subpaths.length guard"

**Location:** commit 2cd3b67 message; refers to app/lib/utils/dataDir.ts:14 at b64c1ca
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High — the pre-fix implementation is four lines and both callers are known.
**Legibility-target:** for-author

The guard was `return subpaths.length > 0 ? join(base, ...subpaths) : base;` (`git show b64c1ca:app/lib/utils/dataDir.ts`, line 15) and it is gone at 2cd3b67 (app/lib/utils/dataDir.ts:14-16) — the removal claim is verified. But "dead-code" is imprecise: both branches were live at runtime (persist.ts exercised the `: base` arm, cache.ts the `join` arm). What the guard actually was is a semantic no-op — `join(base)` returns `base` unchanged for both possible values (`"/tmp"` and `join(cwd, "data")` are already normalized), so `return join(base, ...subpaths)` alone would have behaved identically (paraphrased — no quote available because this is Node `path.join` normalization semantics, external to the repo; r3 confirmed via `node -e "join('/tmp')"` → `/tmp`). Redundant, yes; dead (unreachable or effect-free branch), no.

**Evidence:** `git show b64c1ca:app/lib/utils/dataDir.ts` lines 12-16; app/lib/utils/dataDir.ts:14-16; callers at Claim 9.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate

## Claim 11: Commit 2cd3b67 deferred-finding note — "the cache interface is already abstracted, so a follow-up branch can migrate to Vercel KV / Upstash without churn"

**Location:** commit 2cd3b67 message
**Type:** Architectural
**Verdict:** Verified
**Confidence:** Medium — the seam demonstrably exists and no caller touches filesystem details, but "without churn" is a forward-looking judgment about an unwritten migration.
**Legibility-target:** for-orchestrator-synthesis

The cache module exports exactly four functions — `computeHash` (app/lib/llm/cache.ts:16), `getCachedResult` (:34), `setCachedResult` (:62), `removeCachedResult` (:71) — and all filesystem specifics (`CACHE_DIR`, file paths, `readFile`/`writeFile`/`unlink`, `ensureCacheDir`) are module-private. The three consumers bind only to the function interface: `import { computeHash, getCachedResult, setCachedResult } from "./cache"` (app/lib/llm/callLlm.ts:5, app/lib/llm/streamLlm.ts:4) and `import { removeCachedResult } from "@/app/lib/llm/cache"` (app/lib/formalization/artifactRoute.ts:5). No caller references `CACHE_DIR` or constructs cache paths (rg for `CACHE_DIR` outside cache.ts: no hits; paraphrased — no quote available because the evidence is an empty grep). The read/write/remove functions are already async (`Promise`-returning), so a network-backed KV store fits the existing signatures; keys are opaque sha256 strings (app/lib/llm/cache.ts:22-24) that map directly onto KV keys. Callers already treat writes as fallible (try/catch, app/lib/llm/callLlm.ts:94), which tolerates network-backed failure modes. A backend swap would be contained to cache.ts. Caveat (r2, r3): this is a module-of-functions seam, not an injectable interface, and a KV migration would still rewrite cache.ts internals — "without churn" holds for callers, which is what the claim asserts.

**Evidence:** app/lib/llm/cache.ts:7, 16-84; app/lib/llm/callLlm.ts:5,94,121,125; app/lib/llm/streamLlm.ts:4,64,95,101; app/lib/formalization/artifactRoute.ts:5,104.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

## Claim 12: Commit 2cd3b67 (and b64c1ca) — "Lint clean (0 errors)"

**Location:** commit 2cd3b67 message, final line (also b64c1ca "Lint clean")
**Type:** Configuration / reference (tooling outcome)
**Verdict:** Unverifiable
**Confidence:** High — the brief restricts this pass to static verification, and a lint outcome cannot be established without executing the linter.
**Legibility-target:** for-orchestrator-synthesis

No static artifact in the repo records the lint result, and executing project tooling inside the pinned worktree is outside this pass's scope (paraphrased — no quote available because the claim's evidence would be a command output that was not persisted). Nothing in the four diffed files visibly contradicts the claim (no unused imports, no obvious rule violations), but "0 errors" cannot be confirmed without running `npm run lint`.

**Evidence:** none obtainable within static scope; commit messages b64c1ca and 2cd3b67; static read of the four diffed files.
**Replicate verdicts:** r1=Unverifiable · r2=Unverifiable · r3=Unverifiable

## Claim 13: Commit 2cd3b67 — "224/224 tests pass"

**Location:** commit 2cd3b67 message, final line
**Type:** Reference / configuration (static verification only)
**Verdict:** Unverifiable
**Confidence:** Medium — the arithmetic component is fully verified; the run results cannot be confirmed without executing vitest, which is outside this static pass.
**Legibility-target:** for-orchestrator-synthesis

Static verification: counting `it(`/`test(` declarations across `*.test.ts`/`*.test.tsx` at 2cd3b67 yields exactly 224, of which `app/lib/utils/dataDir.test.ts` contributes 3 (app/lib/utils/dataDir.test.ts:18, 23, 28). The arithmetic reconciles perfectly with the prior commit: 221 (b64c1ca, Claim 8) + 3 new = 224. No dynamic test generation (`it.each`, loops around `it(`) that would break the count was found. The test runner is vitest (`"test": "vitest run"`, package.json:10), consistent with the vitest imports in the new file. However, "pass" is an execution outcome — `npm test` was not run in this pass, so that status is unverifiable statically. Nothing found contradicts it; both counts being exactly right is strong circumstantial support that the suite was actually run. (Most-severe-wins note: r1 and r2 rated the count-anchored claim Verified with the execution caveat in prose; r3, treating the pass status as the load-bearing assertion, rated it Unverifiable — the severity ordering carries r3's verdict.)

**Evidence:** `rg "^\s*(it|test)(\.each)?\(" -g '*.test.ts' -g '*.test.tsx' | wc -l` → 224; per-file `rg -c` shows `app/lib/utils/dataDir.test.ts:3` (paraphrased — no quote available because the evidence is computed counts); app/lib/utils/dataDir.test.ts:18,23,28; package.json:10.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Unverifiable

## Claim 14: Commit 2cd3b67 — dropped "broken cross-reference to README's Deploy to Vercel section (which doesn't exist on this branch's main yet)"

**Location:** commit 2cd3b67 message; app/lib/analytics/persist.ts:6-7 (post-fix state) vs. b64c1ca state
**Type:** Reference / staleness
**Verdict:** Verified
**Confidence:** High — both the absence of the README section and the absence of any remaining README references were checked repo-wide.
**Legibility-target:** for-orchestrator-synthesis

The pre-fix comment read "// On Vercel, analytics history doesn't persist across cold starts — see // Deploy to Vercel in README. See dataDir() for the underlying rationale." (b64c1ca:app/lib/analytics/persist.ts:6-7). The reference was indeed broken: README.md at 2cd3b67 contains zero occurrences of "Vercel" and no "Deploy to Vercel" section, and a repo-wide `rg -n "Deploy to Vercel"` at 2cd3b67 returns nothing — so the referenced section does not exist in this tree (paraphrased — no quote available because the evidence is empty grep output). The reference is gone post-fix (app/lib/analytics/persist.ts:6-7, quoted in Claim 1), and no dangling README-section references remain anywhere in the diffed files or under app/: `rg -ln "README" app` matches no source under app/lib (paraphrased — empty grep result). The replacement pointer ("See dataDir()") is self-contained and valid (Claim 1).

**Evidence:** `git show b64c1ca:app/lib/analytics/persist.ts` lines 6-7 (the removed text); rg over the full worktree for `Deploy to Vercel` and for `README` under `app/lib/`: zero hits; README.md at 2cd3b67.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

## Claims Requiring Attention

### Incorrect
None.

### Stale
None.

### Mostly Accurate
- Claim 4 — dataDir.test.ts:28: test titled "when VERCEL is unset" actually stubs `VERCEL=""` (set-but-falsy, not absent). Behaviorally equivalent for the truthiness gate today; would diverge if the implementation ever switched to a presence check. (r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate)
- Claim 9 — commit 2cd3b67: "the codebase convention is 'base const + join at callsite'" generalizes from a very small sample (the two files under change, plus verifier/server.ts per r3); the one-of-two-callsites count and signature change are exact. (r1=Mostly accurate · r2=Verified · r3=Mostly accurate)
- Claim 10 — commit 2cd3b67: the removed `subpaths.length` guard was a semantic no-op with both branches live at runtime — redundant, not dead code; the removal itself is real and behavior-preserving. (r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate)

### Unverifiable
- Claim 12 — "Lint clean (0 errors)" (commits b64c1ca and 2cd3b67): no persisted artifact; linter not executed under the static-only mandate; no counterevidence observed. (r1=Unverifiable · r2=Unverifiable · r3=Unverifiable)
- Claim 13 — "224/224 tests pass" (commit 2cd3b67): the static declaration count (224 = 221 + 3 new) reconciles exactly, but the pass outcome was not re-executed in this static pass. Most-severe-wins over two Verified replicate verdicts anchored to the count. (r1=Verified · r2=Verified · r3=Unverifiable)

## Verdict stability

- **Total clusters:** 14 (from 13 + 16 + 11 raw replicate claims; replicates differed in how they bundled/split claims — e.g. r2 split callsite-count from convention, r3 bundled lint with the test count)
- **Agreed:** 12 of 14 clusters — all replicates that surfaced the cluster returned the same verdict. One agreed cluster (Claim 6, 2136fd6 swallowed-writes) was surfaced by only r1 and r2 (r3 absent); no cluster was a single-replicate detection.
- **Disagreements:** 2
  - Claim 9 (rest-args / codebase convention): r1=Mostly accurate · r2=Verified · r3=Mostly accurate → merged Mostly accurate. Substantively convergent — r2 flagged the same small-sample caveat but expressed it as Medium confidence on a Verified verdict rather than downgrading the verdict.
  - Claim 13 ("224/224 tests pass"): r1=Verified · r2=Verified · r3=Unverifiable → merged Unverifiable. Substantively convergent — all three verified the count arithmetic and noted the pass status was unexecuted; the disagreement is which half of the claim the verdict attaches to.
- **Agreement rate:** 12/14 = 85.7%

## Goal-Alignment Note
- Answered: All seven briefed items, consistently across replicates. (1) Per-Function-instance caveat present, accurate, and confirmed newly added in the review-fix commit; env gate consistent (Claim 5). (2) No dangling README references remain in any diffed file or anywhere under app/; README.md contains no "Deploy to Vercel" section, confirming the dropped reference was indeed broken (Claims 1, 14). (3) dataDir.test.ts pins both env branches with sound `vi.stubEnv`/`vi.unstubAllEnvs` usage and call-time env reads; one title-wording nit (Claims 3, 4). (4) Rest-args drop: callsite count exact, both consumers converged on the same pattern, guard removal verified; "convention" and "dead-code" wording slightly overstated (Claims 9, 10). (5) 224 static test declarations, reconciling 221 + 3 (Claims 8, 13); lint and test-pass outcomes unverifiable statically (Claims 12, 13). (6) Cache abstraction is a real caller-facing seam — fs details fully module-private, callers bind only to four async exports (Claim 11). (7) Path equivalence holds across pre-fix, post-fix, first-in-range, and pre-range states (Claims 2, 7).
- Out of scope (all replicates): whether /tmp-on-Vercel is the right design (cache-hit-rate collapse was already deferred by the author as a follow-up — a critic concern, not a documentation-accuracy question); runtime execution of lint/tests inside the pinned worktree; Vercel platform behavior beyond consistency with vendor documentation; any commit newer than 2cd3b67.
- Escalate: nothing blocking. If the orchestrator wants the "Lint clean" and "tests pass" claims closed rather than statically corroborated, a single `npm run lint && npm test` in the worktree would settle Claims 12 and 13. Two cosmetic for-author items (Claims 4, 10) are candidates for a follow-up doc-polish commit but do not affect behavior.
