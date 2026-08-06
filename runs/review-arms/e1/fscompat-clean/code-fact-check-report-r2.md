# Code Fact-Check Report

**Repository:** meta-formalism-copilot (pinned worktree /workspace/runs/review-arms/e1/wt-fscompat-clean, detached at 2cd3b67)
**Scope:** `git diff d86d2dc..2cd3b67` (app/lib/analytics/persist.ts, app/lib/llm/cache.ts, app/lib/utils/dataDir.ts, app/lib/utils/dataDir.test.ts) plus commit messages 2136fd6, b64c1ca, 2cd3b67
**Checked:** comments, docstrings, test descriptions, and commit-message claims in the range, verified against the repo state at 2cd3b67 and its ancestors
**Total claims checked:** 16
**Summary:** 13 Verified, 2 Mostly accurate, 0 Stale, 0 Incorrect, 1 Unverifiable. The diff's documentation is in unusually good shape: the review-fix commit's claims (caveat added, rest-args dropped, README cross-ref removed, both env branches pinned, 221+3=224 test arithmetic) all check out. The two Mostly-accurate findings are terminological: the removed ternary guard was *redundant*, not dead code (both branches were reachable), and the third test's title says "when VERCEL is unset" while the test actually stubs it to the empty string.

**Commit:** 2cd3b67

## Claim 1: analytics history on Vercel is ephemeral and per-instance; rationale lives in dataDir()

**Location:** app/lib/analytics/persist.ts:6-7
**Type:** Behavioral / reference
**Verdict:** Verified
**Confidence:** High — the referenced docstring exists and states exactly the referenced rationale; the persistence path is gated by the same env check the rationale describes.
**Legibility-target:** for-orchestrator-synthesis

The comment claims:

> "// On Vercel, analytics history doesn't persist across cold starts and is
> // per-Function-instance. See dataDir() for the underlying rationale." (app/lib/analytics/persist.ts:6-7)

`DATA_DIR = dataDir()` (app/lib/analytics/persist.ts:8) resolves to `/tmp` when `VERCEL` is set, and the pointed-to docstring does contain the underlying rationale, including both the cold-start and per-instance halves:

**Evidence:**
> "`/tmp` lives only as long as a warm container, so persistence does not survive cold starts; it is also per-instance, so concurrent Function instances each see their own independent contents" (app/lib/utils/dataDir.ts:8-11)
> "export function dataDir(): string { return process.env.VERCEL ? \"/tmp\" : join(process.cwd(), \"data\"); }" (app/lib/utils/dataDir.ts:14-16)

All analytics writes go through `FILE_PATH = join(DATA_DIR, "analytics.jsonl")` (app/lib/analytics/persist.ts:9), so the ephemerality claim follows directly from the /tmp resolution. The reference is no longer to a README section (see Claim 12); `rg -n "README" app/lib` returns no hits — paraphrased — no quote available because the finding is an empty grep result over app/lib.

## Claim 2: CACHE_DIR via `join(dataDir(), "cache")` is path-equivalent to prior forms

**Location:** app/lib/llm/cache.ts:7
**Type:** Behavioral / invariant (path equivalence, brief item 7 and commit 2cd3b67's "switch to join(dataDir(), \"cache\") to match the persist.ts pattern")
**Verdict:** Verified
**Confidence:** High — all three historical forms read directly from the worktree's git history; the equivalence is mechanical.
**Legibility-target:** for-orchestrator-synthesis

Post-fix:

> "const CACHE_DIR = join(dataDir(), \"cache\");" (app/lib/llm/cache.ts:7)

Pre-fix (b64c1ca): `const CACHE_DIR = dataDir("cache");` where `dataDir(...subpaths)` returned `subpaths.length > 0 ? join(base, ...subpaths) : base` — paraphrased in part; full quote in Evidence. In both branches `join(dataDir(), "cache")` = `join(base, "cache")` = `dataDir("cache")`: `/tmp/cache` on Vercel, `<cwd>/data/cache` otherwise. The first in-range commit (2136fd6) had `CACHE_DIR = process.env.VERCEL ? "/tmp/cache" : join(process.cwd(), "data", "cache")` — identical resolution. The pre-range original (d86d2dc) was `const CACHE_DIR = join(process.cwd(), "data", "cache");` — equivalent on the non-Vercel branch; the Vercel-branch divergence is the intended behavior change introduced by 2136fd6, not drift.

**Evidence:**
> "export function dataDir(...subpaths: string[]): string { const base = process.env.VERCEL ? \"/tmp\" : join(process.cwd(), \"data\"); return subpaths.length > 0 ? join(base, ...subpaths) : base; }" (b64c1ca:app/lib/utils/dataDir.ts:12-15)
> "const CACHE_DIR = process.env.VERCEL ? \"/tmp/cache\" : join(process.cwd(), \"data\", \"cache\");" (2136fd6:app/lib/llm/cache.ts:9-11)
> "const CACHE_DIR = join(process.cwd(), \"data\", \"cache\");" (d86d2dc:app/lib/llm/cache.ts:6)

## Claim 3: test-file header — Vercel branch invisible to lint/types/build; test pins both branches

**Location:** app/lib/utils/dataDir.test.ts:5-7
**Type:** Behavioral / architectural
**Verdict:** Verified
**Confidence:** High — the env gate is a runtime `process.env` read (invisible to static tooling), and the two branch tests assert mutually exclusive concrete paths.
**Legibility-target:** for-orchestrator-synthesis

> "// Cheap unit test for an asymmetric deploy invariant: the Vercel branch
> // of dataDir() is invisible in local dev, so a refactor that flips or
> // deletes it would never be caught by lint/types/build. Pin both branches." (app/lib/utils/dataDir.test.ts:5-7)

Both branches are exercised: `vi.stubEnv("VERCEL", "1")` then `expect(dataDir()).toBe("/tmp")` (app/lib/utils/dataDir.test.ts:19-20), and `vi.stubEnv("VERCEL", "")` then `expect(dataDir()).toBe(join(originalCwd, "data"))` (app/lib/utils/dataDir.test.ts:29-30). If the ternary flipped, the Vercel test would receive `<cwd>/data` and the non-Vercel test `/tmp` — both assertions fail; if the Vercel branch were deleted, the first two tests fail. The env manipulation is sound: `dataDir()` reads `process.env.VERCEL` at call time (app/lib/utils/dataDir.ts:15), not at module load, so `vi.stubEnv` takes effect, and `vi.unstubAllEnvs()` runs in both `beforeEach` and `afterEach` (app/lib/utils/dataDir.test.ts:12-16), preventing leakage between tests regardless of the host environment's VERCEL value.

**Evidence:**
> "it(\"returns /tmp when VERCEL is set\", () => { vi.stubEnv(\"VERCEL\", \"1\"); expect(dataDir()).toBe(\"/tmp\"); });" (app/lib/utils/dataDir.test.ts:18-21)
> "return process.env.VERCEL ? \"/tmp\" : join(process.cwd(), \"data\");" (app/lib/utils/dataDir.ts:15)

## Claim 4: test title "returns <cwd>/data when VERCEL is unset"

**Location:** app/lib/utils/dataDir.test.ts:28
**Type:** Behavioral (test description)
**Verdict:** Mostly accurate
**Confidence:** High — the discrepancy is directly visible in the two adjacent lines.
**Legibility-target:** for-author

> "it(\"returns <cwd>/data when VERCEL is unset\", () => { vi.stubEnv(\"VERCEL\", \"\"); ..." (app/lib/utils/dataDir.test.ts:28-29)

The title says "unset", but the test stubs `VERCEL` to the empty string — the variable is *set* to a falsy value, not absent. For the truthiness gate `process.env.VERCEL ? ... : ...` (app/lib/utils/dataDir.ts:15) the two are behaviorally identical, so the branch is correctly pinned; the title is just imprecise about which falsy state it establishes. (Deleting the var outright — `vi.stubEnv` cannot express that; `delete process.env.VERCEL` could — would behave the same here.) Minor wording nit, no behavioral consequence.

**Evidence:**
> "vi.stubEnv(\"VERCEL\", \"\"); expect(dataDir()).toBe(join(originalCwd, \"data\"));" (app/lib/utils/dataDir.test.ts:29-30)

## Claim 5: dataDir() docstring — /tmp-only writability, cold-start lifetime, per-instance isolation, durable data/ in dev/self-hosted

**Location:** app/lib/utils/dataDir.ts:3-13
**Type:** Behavioral / configuration (brief item 1)
**Verdict:** Verified
**Confidence:** Medium — the code-facing halves (env gate, dev path) are directly verified; the platform-facing halves (/tmp sole writability, per-instance /tmp, warm-container lifetime) match Vercel's documented Functions filesystem model but cannot be proven from this repo alone.
**Legibility-target:** for-orchestrator-synthesis

> "On Vercel Functions only `/tmp` is writable. `/tmp` lives only as long as
> a warm container, so persistence does not survive cold starts; it is also
> per-instance, so concurrent Function instances each see their own
> independent contents (no cross-instance sharing). In dev and self-hosted
> deployments we write to the repo's `data/` dir for durable cross-restart
> storage." (app/lib/utils/dataDir.ts:7-12)

The per-Function-instance caveat demanded by the review is present and correctly scoped (warm instances are isolated from each other; no cross-instance sharing). The env gate matches the docstring's deploy taxonomy: `process.env.VERCEL` is set on all Vercel deployments (production and preview) and absent in local dev/self-hosted, so the /tmp claim attaches exactly to Vercel and the `data/` claim to everything else — the platform statements (only-/tmp-writable, per-instance ephemeral /tmp, VERCEL env var set on all Vercel targets) are paraphrased — no quote available because they describe Vercel platform behavior documented outside this repository; they are consistent with Vercel's published Functions model as of the knowledge cutoff. The dev-branch claim is directly verified: `join(process.cwd(), "data")` (app/lib/utils/dataDir.ts:15) is an on-disk repo path that survives restarts.

**Evidence:**
> "return process.env.VERCEL ? \"/tmp\" : join(process.cwd(), \"data\");" (app/lib/utils/dataDir.ts:15)
> Test pinning the taxonomy including preview values: "it(\"treats any truthy VERCEL value as Vercel\", () => { vi.stubEnv(\"VERCEL\", \"preview\"); expect(dataDir()).toBe(\"/tmp\"); });" (app/lib/utils/dataDir.test.ts:23-26)

## Claim 6: commit 2136fd6 — writes went to data/ at project root and were "silently swallowed by upstream try/catch"

**Location:** commit 2136fd6 message, lines 3-6
**Type:** Behavioral (historical)
**Verdict:** Verified
**Confidence:** High — both the pre-range constants and the swallowing try/catch blocks are directly readable.
**Legibility-target:** for-orchestrator-synthesis

> "The LLM cache and analytics log used to write to data/ at the project
> root, which is read-only on Vercel Functions. Writes were silently
> swallowed by upstream try/catch" (commit 2136fd6)

Pre-range: `const DATA_DIR = join(process.cwd(), "data");` (d86d2dc:app/lib/analytics/persist.ts:5) and `const CACHE_DIR = join(process.cwd(), "data", "cache");` (d86d2dc:app/lib/llm/cache.ts:6). The swallowing catch blocks exist at 2cd3b67 in both call paths and wrap both the analytics append and the cache write.

**Evidence:**
> "} catch { /* persistence failure must not break LLM calls */ }" (app/lib/llm/callLlm.ts:91; identical at app/lib/llm/streamLlm.ts:62)
> "try { await setCachedResult(cacheHash, result); } catch { /* cache write failure is non-fatal */ }" (app/lib/llm/callLlm.ts:94; equivalent at app/lib/llm/streamLlm.ts:64)

The "read-only on Vercel Functions" half is a platform claim — paraphrased — no quote available because it describes Vercel infrastructure, not repo code; consistent with Vercel's documented deployment filesystem.

## Claim 7: commit b64c1ca — "No behavior change; both DATA_DIR and CACHE_DIR resolve to the same paths they did before"

**Location:** commit b64c1ca message
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High — mechanical path comparison between 2136fd6 and b64c1ca file states.
**Legibility-target:** for-orchestrator-synthesis

"Before" = 2136fd6: `DATA_DIR = process.env.VERCEL ? "/tmp" : join(process.cwd(), "data")` (2136fd6:app/lib/analytics/persist.ts:9) and `CACHE_DIR = process.env.VERCEL ? "/tmp/cache" : join(process.cwd(), "data", "cache")` (2136fd6:app/lib/llm/cache.ts:9-11). After: `DATA_DIR = dataDir()` and `CACHE_DIR = dataDir("cache")`, with `dataDir` returning the identical base and `join(base, "cache")` respectively (b64c1ca:app/lib/utils/dataDir.ts:12-15). Resolutions match branch-for-branch.

**Evidence:**
> "const base = process.env.VERCEL ? \"/tmp\" : join(process.cwd(), \"data\"); return subpaths.length > 0 ? join(base, ...subpaths) : base;" (b64c1ca:app/lib/utils/dataDir.ts:13-14)

## Claim 8: commit b64c1ca — "221/221 tests pass"

**Location:** commit b64c1ca message, final line
**Type:** Reference / staleness (static verification only, per brief item 5)
**Verdict:** Verified
**Confidence:** Medium — the declaration count is exact, but pass status was not re-executed (out of scope per the brief).
**Legibility-target:** for-orchestrator-synthesis

Static count at 2cd3b67 across all `*.test.*` files: 224 `it(`/`test(` declarations, of which 3 are in the new app/lib/utils/dataDir.test.ts (added in 2cd3b67, after b64c1ca). 224 − 3 = 221, matching the claim exactly. No `it.each`/`test.each` multipliers exist in the suite — paraphrased — no quote available because the finding is an empty grep for `it\.each|test\.each` over the test files. The "pass" half is consistent with, but not proven by, static counting.

**Evidence:**
> Count per file including "app/lib/utils/dataDir.test.ts:3" and total 224 — paraphrased — no quote available because the evidence is aggregate `rg -c` output over 25 test files, reproduced in Claim 13.

## Claim 9: commit 2cd3b67 — rest-args "only used in one of two callsites"

**Location:** commit 2cd3b67 message ("Drop the rest-args feature — only used in one of two callsites...")
**Type:** Reference (usage census)
**Verdict:** Verified
**Confidence:** High — exhaustive grep of the b64c1ca tree.
**Legibility-target:** for-orchestrator-synthesis

At b64c1ca, `dataDir` had exactly two callsites: `const CACHE_DIR = dataDir("cache");` (b64c1ca:app/lib/llm/cache.ts:7) used the rest-args; `const DATA_DIR = dataDir();` (b64c1ca:app/lib/analytics/persist.ts:8) did not. No other callers existed then or exist now: at 2cd3b67, `rg -n "dataDir" app --glob '!*.test.ts'` finds only persist.ts:8 and cache.ts:7 as call sites — paraphrased — no quote available because the finding is a two-hit grep census.

**Evidence:**
> "const CACHE_DIR = dataDir(\"cache\");" (b64c1ca:app/lib/llm/cache.ts:7)
> "const DATA_DIR = dataDir();" (b64c1ca:app/lib/analytics/persist.ts:8)

## Claim 10: commit 2cd3b67 — "the codebase convention is 'base const + join at callsite'"

**Location:** commit 2cd3b67 message
**Type:** Architectural / convention
**Verdict:** Verified
**Confidence:** Medium — the convention holds in every path-building consumer the repo has, but that population is only two modules, so "codebase convention" rests on a small sample.
**Legibility-target:** for-orchestrator-synthesis

Every module that builds persistence paths follows base-const-then-join: persist.ts holds `DATA_DIR` and joins at the callsite ("const FILE_PATH = join(DATA_DIR, \"analytics.jsonl\");", app/lib/analytics/persist.ts:9); cache.ts holds `CACHE_DIR` and joins per file ("const filePath = join(CACHE_DIR, `${hash}.json`);", app/lib/llm/cache.ts:41, repeated at :67 and :78). A repo-wide grep for `const [A-Z_]+ = join(` finds no counterexample modules — paraphrased — no quote available because the evidence is a grep returning only the two files above. Both consumers now use the same pattern (persist.ts base via `dataDir()` at line 8; cache.ts base via `join(dataDir(), "cache")` at line 7), confirming the commit's "to match the persist.ts pattern" for cache.ts.

**Evidence:**
> "const FILE_PATH = join(DATA_DIR, \"analytics.jsonl\");" (app/lib/analytics/persist.ts:9)
> "const filePath = join(CACHE_DIR, `${hash}.json`);" (app/lib/llm/cache.ts:41)

## Claim 11: commit 2cd3b67 — "kills the dead-code subpaths.length guard"

**Location:** commit 2cd3b67 message
**Type:** Behavioral (historical)
**Verdict:** Mostly accurate
**Confidence:** High — the removed guard is quoted from b64c1ca and both of its branches were demonstrably reachable.
**Legibility-target:** for-author

The removed guard:

> "return subpaths.length > 0 ? join(base, ...subpaths) : base;" (b64c1ca:app/lib/utils/dataDir.ts:14)

"Dead code" is a mischaracterization: both branches of the ternary executed in production — `dataDir("cache")` (b64c1ca:app/lib/llm/cache.ts:7) took the `join` branch and `dataDir()` (b64c1ca:app/lib/analytics/persist.ts:8) took the `base` branch. The guard was *redundant*, not dead: `join(base, ...[])` returns `base` for these already-normalized inputs (Node's `path.join` with a single segment normalizes and returns it — paraphrased — no quote available because this is Node stdlib behavior, not repo code), so the ternary could have been collapsed to `join(base, ...subpaths)` with no behavior change. The substantive point — the guard was removable and its removal loses nothing — is correct; only the "dead-code" label is off.

**Evidence:**
> "export function dataDir(): string { return process.env.VERCEL ? \"/tmp\" : join(process.cwd(), \"data\"); }" (app/lib/utils/dataDir.ts:14-16) — post-fix signature with rest-args and guard removed, confirming the signature-change half of the claim.

## Claim 12: commit 2cd3b67 — dropped "broken cross-reference to README's Deploy to Vercel section (which doesn't exist on this branch's main yet)"

**Location:** commit 2cd3b67 message (brief item 2)
**Type:** Reference / staleness
**Verdict:** Verified
**Confidence:** High — both the absence of the README section and the absence of any remaining README references were checked repo-wide.
**Legibility-target:** for-orchestrator-synthesis

The pre-fix comment read "// On Vercel, analytics history doesn't persist across cold starts — see // Deploy to Vercel in README. See dataDir() for the underlying rationale." (b64c1ca:app/lib/analytics/persist.ts:6-7). The reference was indeed broken: README.md at 2cd3b67 (121 lines) contains zero occurrences of "Vercel" and no "Deploy to Vercel" section — paraphrased — no quote available because the evidence is an empty grep over README.md. The reference is gone post-fix (app/lib/analytics/persist.ts:6-7, quoted in Claim 1), and no dangling README-section references remain anywhere in the diffed files or in app/ generally: `rg -ln "README" app` matches no source under app/lib — paraphrased — no quote available because the finding is an empty grep result. The replacement pointer ("See dataDir()") is self-contained and valid (Claim 1).

**Evidence:**
> "// On Vercel, analytics history doesn't persist across cold starts — see
> // Deploy to Vercel in README. See dataDir() for the underlying rationale." (b64c1ca:app/lib/analytics/persist.ts:6-7) — the removed text.

## Claim 13: commit 2cd3b67 — "Add dataDir.test.ts pinning both branches of the env switch"

**Location:** commit 2cd3b67 message
**Type:** Behavioral (brief item 3)
**Verdict:** Verified
**Confidence:** High — both branches are asserted against distinct concrete paths; env stubbing verified sound (see Claim 3).
**Legibility-target:** for-orchestrator-synthesis

Covered in detail under Claim 3: the VERCEL branch is pinned by two tests (`"1"` and `"preview"` both expecting `/tmp`, app/lib/utils/dataDir.test.ts:18-26), the non-VERCEL branch by one (empty string expecting `join(originalCwd, "data")`, app/lib/utils/dataDir.test.ts:28-31), and a flip or deletion of either branch fails at least one assertion. The file registers exactly 3 test declarations, reconciling the 221→224 count (Claim 8, Claim 14).

**Evidence:**
> "rg -c" per-file counts summing to 224 with "app/lib/utils/dataDir.test.ts:3" — paraphrased — no quote available because the evidence is aggregate grep-count output across 25 test files.

## Claim 14: commit 2cd3b67 — "224/224 tests pass"

**Location:** commit 2cd3b67 message, final line
**Type:** Reference (static verification only, per brief item 5)
**Verdict:** Verified
**Confidence:** Medium — the static declaration count is exactly 224; pass status not re-executed (out of scope).
**Legibility-target:** for-orchestrator-synthesis

Static count of `it(`/`test(` declarations across all `*.test.*` files at 2cd3b67 is exactly 224, with no parameterized-test multipliers (`it.each`/`test.each` absent). Arithmetic reconciles with the prior commit's claim: 221 (b64c1ca, Claim 8) + 3 (new dataDir.test.ts) = 224. Both counts being exactly right is strong circumstantial support that the suite was actually run, though "pass" itself remains unexecuted here.

**Evidence:**
> Total of 224 from `rg -o "^\s*(it|test)(\.each)?\(" --glob '*.test.*' | wc -l` — paraphrased — no quote available because the evidence is a computed count over the whole test suite.

## Claim 15: commit 2cd3b67 — "Lint clean (0 errors)"

**Location:** commit 2cd3b67 message, final line (also b64c1ca "Lint clean")
**Type:** Reference (tooling outcome)
**Verdict:** Unverifiable
**Confidence:** High — the brief restricts this pass to static verification, and a lint outcome cannot be established without executing the linter.
**Legibility-target:** for-orchestrator-synthesis

No static inspection can substitute for a lint run, and executing project tooling inside the pinned worktree is outside this pass's scope. Nothing in the four diffed files visibly contradicts the claim (no unused imports, no obvious rule violations) — paraphrased — no quote available because this is an absence-of-counterevidence observation over files fully quoted elsewhere in this report.

**Evidence:** none obtainable within static scope.

## Claim 16: commit 2cd3b67 author note — "the cache interface is already abstracted, so a follow-up branch can migrate to Vercel KV / Upstash without churn"

**Location:** commit 2cd3b67 message (deferred-finding note; brief item 6)
**Type:** Architectural
**Verdict:** Verified
**Confidence:** Medium — the caller-facing seam is real and complete, but "interface" overstates the mechanism slightly (it is a module boundary with a concrete fs implementation, not an injectable interface), and a KV migration would still rewrite cache.ts internals — the claim's "without churn" holds for callers, which is what it asserts.
**Legibility-target:** for-orchestrator-synthesis

The abstraction claim checks out at the module boundary. Non-test callers import only the four exported functions and never touch filesystem details: "import { computeHash, getCachedResult, setCachedResult } from \"./cache\";" (app/lib/llm/callLlm.ts:5; identically app/lib/llm/streamLlm.ts:4) and "import { removeCachedResult } from \"@/app/lib/llm/cache\";" (app/lib/formalization/artifactRoute.ts:5). `CACHE_DIR`, the per-hash file layout, and the fs/promises calls are all module-private (app/lib/llm/cache.ts:7, :41, :67, :78 — not exported). All storage-touching exports are already async (`getCachedResult`, `setCachedResult`, `removeCachedResult` return Promises — app/lib/llm/cache.ts:33-39, :62-65, :71-76), so a KV/Upstash backend needs no signature changes; `computeHash` (app/lib/llm/cache.ts:16) is pure and backend-agnostic, serving directly as a KV key. Callers already treat writes as fallible ("try { await setCachedResult(cacheHash, result); } catch { /* cache write failure is non-fatal */ }", app/lib/llm/callLlm.ts:94), which tolerates network-backed failure modes. A swap would rewrite the bodies of cache.ts only — zero caller churn, as claimed.

**Evidence:**
> "const cached = await getCachedResult(effectiveModel, systemPrompt, userContent, maxTokens);" (app/lib/llm/callLlm.ts:125; equivalent at app/lib/llm/streamLlm.ts:101)
> "export async function setCachedResult(hash: string, result: CachedResult): Promise<void>" (app/lib/llm/cache.ts:62-65)

## Claims Requiring Attention

### Incorrect

None.

### Stale

None.

### Mostly Accurate

- **Claim 4** (app/lib/utils/dataDir.test.ts:28): test title says "when VERCEL is unset" but the test stubs `VERCEL=""` (set-but-empty). Behaviorally equivalent for the truthiness gate; title wording only.
- **Claim 11** (commit 2cd3b67): the removed `subpaths.length` guard was redundant, not "dead-code" — both ternary branches were reachable and executed (cache.ts took the join branch, persist.ts the base branch). Removal was still safe; only the label is off.

### Unverifiable

- **Claim 15** (commits 2cd3b67 and b64c1ca): "Lint clean (0 errors)" — a tooling outcome not checkable within this pass's static-only scope; no counterevidence observed.

## Goal-Alignment Note
- Answered: All seven brief items — (1) per-Function-instance caveat present and accurate, env gate holds (Claim 5); (2) no dangling README references anywhere in app/, and the dropped reference was confirmed broken against README.md at 2cd3b67 (Claims 1, 12); (3) both env-switch branches genuinely pinned with sound `vi.stubEnv`/`unstubAllEnvs` usage and call-time env reads (Claims 3, 13, with the title nit in Claim 4); (4) one-of-two-callsites, convention, signature change, and guard removal verified, with "dead-code" downgraded to redundant (Claims 9, 10, 11); (5) 224 static test declarations, 221+3 arithmetic reconciles, lint unverifiable statically (Claims 8, 14, 15); (6) cache seam confirmed — callers bind only to four async exports, fs details module-private (Claim 16); (7) path equivalence across all three historical forms of CACHE_DIR (Claim 2).
- Out of scope: executing the test suite or linter inside the pinned worktree; verifying Vercel platform behavior (only-/tmp-writable, per-instance /tmp, VERCEL env semantics) beyond consistency with documented platform behavior; any commit newer than 2cd3b67.
- Escalate: nothing blocking. Two cosmetic for-author items (Claims 4, 11) are candidates for a follow-up doc-polish commit but do not affect behavior; the "Lint clean" claim would be trivially confirmable by any pass permitted to run project tooling.
