Commit: 2dc403e

# Tech Debt Triage: DD-009 corpus S0+S1 (`app/`, dc6dfb0..2dc403e)

Scope: the 15 `app/` files in the range (partial scope; branch docs read as context only). This change is new code behind a default-off flag, so most of what it adds is *staged* debt: it costs nothing until S2/S4 build on it, and then it costs a lot. The triage below asks, per item, whether that cost grows before the debt is paid. Line numbers are against the checked-out worktree at 2dc403e. Stage-1 fact-check claims are cross-referenced where they overlap (Claim N / E N).

Method: read every in-scope file in full, plus `workspaceStore.ts:493-545`, `app/page.tsx:78-83`, `docs/spikes/corpus-opfs-smoke.md` and the range log. I ran no tests (no `node_modules`). All `import` sites of `app/lib/corpus/*` were grepped: production code imports only `storeAdapter.ts` (`workspaceStore.ts:25`). `paths.ts` and `manifest.ts` have no non-test consumer.

---

## Tech Debt Triage: TD1. The OPFS adapter is not held to the shared contract suite, and the fake diverges from it

**Severity:** High (as debt) · **Confidence:** high · **Legibility-target:** for-author
**Location:** `app/lib/corpus/__tests__/corpusFs.contract.test.ts:1-8`; `app/lib/corpus/__tests__/inMemoryCorpusFs.ts:13-14`; `app/lib/corpus/opfsAdapter.ts:58`
**Evidence:**
```
1:/** Runs the shared CorpusFS contract against the in-memory fake (DD-009 S1).
2: *  The OPFS adapter is held to the same suite out-of-CI (Playwright); jsdom has
3: *  no OPFS so the real adapter cannot run here. */
...
8:defineCorpusFsContract("in-memory fake", () => createInMemoryCorpusFs());
```
```
13:function normalize(path: string): string {
14:  return path.replace(/^\/+|\/+$/g, "");
```
```
58:  const parts = path.replace(/^\/+|\/+$/g, "").split("/").filter(Boolean);
```
(excerpt; enclosing `splitPath()` continues to :62. Read.)
**Nature:** testing / substitutability.
**Cost of Deferral:** `+1 consumer that binds to fake-only semantics per sub-task (S2, S3, S4)`
**Failure Cost:** Med × Med. S4 migration logic is verified against a fake that behaves differently from OPFS (Stage-1 Claim 1: name clashes between a file and a directory, rm of a directory; plus `a//b`, which the fake keys literally and OPFS collapses). In production that could mean misplaced or unreadable corpus files.

### Carrying Cost: Medium
Today only the dev-flag blob path uses OPFS, so the gap is inert. But four docstrings and the f6361a3 body say the OPFS adapter is held to the same suite as the fake. Every later sub-task will trust the fake on that claim. `docs/spikes/corpus-opfs-smoke.md` is an unrun sketch ("How to run (sketch …)"). The more corpus logic is written against the fake, the more divergences will turn up at once when OPFS finally runs.

### Fix Cost
- **Scope:** localized (a browser harness, plus 2-3 extra contract cases for the divergences)
- **Effort:** about a day (an esbuild bundle and a Playwright runner, following the iso-git spike harness), plus hours to make the fake reject file/dir clashes
- **Risk:** low. Tests only. The cost is setting up the environment (Playwright on WSL2).
- **Incremental?** yes. First correct the docstrings to say "fake only; OPFS pending the smoke", then add the harness.

### Urgency Triggers
- Before any S4 code is written against `CorpusFS` (S4 is the first heavy consumer).
- Before the flag is defaulted on (the smoke doc names this as its own gate).

### Recommendation
**Recommendation:** Fix now

Correcting the docstrings is a trivial in-place fix. It removes the false assurance that the debt compounds on. The harness itself is a pre-S4 task. Adding fake-side cases for the divergences Stage-1 found is cheap and makes the fake fail loudly where OPFS would.

---

## Tech Debt Triage: TD2. The manifest codec is lenient but documented as fail-loud

**Severity:** Medium · **Confidence:** high (Stage-1 executed it 3/3) · **Legibility-target:** for-author
**Location:** `app/lib/corpus/manifest.ts:87,94,102-103,109-110`
**Evidence:**
```
87:    ? raw.sources.filter(isObject).map((s) => {
...
94:    ? raw.artifacts.filter(isObject).map((a) => {
...
102:  const customTypeIds: string[] = Array.isArray(raw.customTypeIds)
103:    ? raw.customTypeIds.filter((x): x is string => typeof x === "string")
...
109:    createdAt: typeof raw.createdAt === "string" ? raw.createdAt : new Date().toISOString(),
110:    updatedAt: typeof raw.updatedAt === "string" ? raw.updatedAt : new Date().toISOString(),
```
(excerpt; enclosing `parseManifest()` runs :74-115. Read in full.)
**Nature:** contract drift (code vs docstring). The codec has no consumer yet.
**Cost of Deferral:** `+0 — inert until S4; then +1 on-disk manifest format version per release that the strict parser must stay compatible with`
**Failure Cost:** Low × High once S4 ships. A partially corrupt `workspace.json` loads with entries silently missing, which is the "masks data loss" case the header warns about (E2).

### Carrying Cost: Low
No production code imports `manifest.ts`, so nothing depends on it today. The debt is that the docstring (`:10-14`) promises fail-loud and the tests (G11) only cover the top-level failures. Once manifests exist on users' disks, a stricter parser becomes a compatibility break, not just a refactor.

### Fix Cost
- **Scope:** localized (one function plus its test file)
- **Effort:** hours
- **Risk:** low. No consumers, no on-disk data yet.
- **Incremental?** yes

### Urgency Triggers
- The first S4 write of a real `workspace.json`. After that, tightening the parser needs a migration story.

### Recommendation
**Recommendation:** Fix opportunistically

It is cheapest now, while there is no consumer and no on-disk data. The hard deadline is S4's first manifest write, not this merge. The fix: throw instead of `filter`, validate `manifestVersion === MANIFEST_VERSION`, require positive integer `currentVersion`, and add the matching G11 cases. Do it in this branch or as the first S4 commit.

---

## Tech Debt Triage: TD3. The corpus-backed storage has no debounce and does not order its writes

**Severity:** Medium (dev-only today) · **Confidence:** medium (the ordering hazard is inferred from OPFS writable semantics and was not executed) · **Legibility-target:** for-author
**Location:** `app/lib/corpus/storeAdapter.ts:61-63`; `app/lib/corpus/opfsAdapter.ts:113-119`
**Evidence:**
```
61:    setItem: async (name, value) => {
62:      await fs.writeFile(pathFor(name), enc.encode(value));
63:    },
```
(excerpt; enclosing `createCorpusBackedStorage()` continues to :68. Read.)
```
113:        const w = await fh.createWritable();
114:        try {
115:          // Pass a fresh ArrayBuffer view; some implementations dislike shared buffers.
116:          await w.write(bytes);
117:        } finally {
118:          await w.close();
119:        }
```
(excerpt; enclosing `writeFile()` runs :108-124. Read.)
**Nature:** performance / correctness (concurrency).
**Cost of Deferral:** `+0 — inert while the flag is dev-only; becomes a must-fix the moment the flag is defaulted on`
**Failure Cost:** Low × Med today (dev data only). Once the flag is enabled for users it becomes Med × High: whole-state blobs are written on every keystroke, and nothing awaits or orders them, so an older blob's `close()` can land after a newer one's and roll the state back.

### Carrying Cost: Low
The default path keeps the 300 ms debounce (`createDebouncedLocalStorage`). The flag path re-serializes and writes the whole persisted state through a fresh writable on every `set()`, with nothing ordering the writes. In the store that never happens unless the dev flag is set. The extra failure path in `finally` (E5: a `close()` error can mask a quota error as `io`) belongs to the same code.

### Fix Cost
- **Scope:** localized (`storeAdapter.ts`, about 20 LOC: debounce plus a serialized write chain)
- **Effort:** hours
- **Risk:** low. The OFF path is untouched.
- **Incremental?** yes

### Urgency Triggers
- Anyone dogfooding with the flag on and editing quickly.
- Defaulting the flag on (S4) is a hard trigger.

### Recommendation
**Recommendation:** Defer and monitor

Revisit before the flag is enabled for anyone besides the author, or at the start of S4, whichever comes first. It is cheap to fix then, and S4 may replace blob mode entirely, so fixing it now could be wasted work.

---

## Tech Debt Triage: TD4. Flag-on rehydration still runs the localStorage v2 migration path

**Severity:** Medium · **Confidence:** medium (read, not executed; Stage-1 r2 only) · **Legibility-target:** for-author
**Location:** `app/lib/stores/workspaceStore.ts:533-539`
**Evidence:**
```
533:          if (typeof window !== "undefined" && localStorage.getItem(WORKSPACE_KEY)) {
534:            const zustandRaw = localStorage.getItem("workspace-zustand-v1");
535:            let hasZustandData = false;
536:            try { hasZustandData = !!(zustandRaw && JSON.parse(zustandRaw)?.state?.sourceText); }
537:            catch { /* corrupted localStorage — proceed with migration */ }
538:            if (!hasZustandData) {
539:              migrateFromV2();
```
(excerpt; enclosing `onRehydrateStorage` continues to :543. Read.)
**Nature:** structural. The seam is incomplete: the store still reaches past the storage abstraction to localStorage.
**Cost of Deferral:** `+0 — inert until S4 migration is designed; then the S4 author must rediscover this second persistence path`
**Failure Cost:** blank (dev-only, and the impact is confusing state rather than data loss)

### Carrying Cost: Low
With the flag on, `hasZustandData` reads localStorage, which the corpus path never writes. So a dev with legacy `workspace-v2` data gets `migrateFromV2()` on every reload, and the migrated state is then written into the corpus. That contradicts both "starts from an EMPTY corpus" (`flag.ts:4-6`) and "pure substrate swap" (`storeAdapter.ts:12`). It is harmless for the dev-only flag, but it is a hidden coupling S4 has to untangle.

### Fix Cost
- **Scope:** localized (gate the block on `!isCorpusEnabled()`, or read through the resolved storage)
- **Effort:** hours
- **Risk:** low (the OFF path is guarded by the characterization test, but note TD6)
- **Incremental?** yes

### Urgency Triggers
- Design of S4 localStorage-to-corpus migration (this block is the old migration path S4 will compete with).

### Recommendation
**Recommendation:** Fix opportunistically

A one-line gate fixes it now. Otherwise record it in the S4 plan as a known second persistence path. Either is acceptable. The thing to avoid is leaving it undocumented while the docstrings claim the swap is pure.

---

## Tech Debt Triage: TD5. Stale and incorrect comments in the new code

**Severity:** Low · **Confidence:** high · **Legibility-target:** for-author
**Location:** `app/lib/corpus/opfsAdapter.ts:14,115`; `app/lib/corpus/storeAdapter.ts:11`; `app/lib/stores/workspaceStore.ts:496-498`; `app/lib/corpus/flag.ts:4`
**Evidence:**
```
14: *    legacy localStorage adapter does (workspaceStore.ts:44-46).
```
```
115:          // Pass a fresh ArrayBuffer view; some implementations dislike shared buffers.
```
```
11: * the files-per-artifact folder layout (layout.ts/manifest.ts) is built but not
```
```
496:      // Storage seam is selected here (DD-009 S1): debounced localStorage by
497:      // default, or a CorpusFS-backed adapter when the dev flag is on. The seam
498:      // is typed as CorpusFS so the S3 worker-proxy is a drop-in.
```
**Nature:** documentation drift (Stage-1 Claims 2, 5, 7, 8, 11).
**Cost of Deferral:** `+0 — inert`, apart from misleading the next reader. The "dev-only" claim at `flag.ts:4` is the one that matters (E3).
**Failure Cost:** blank

### Carrying Cost: Low
Each comment is small, but together they describe a stronger design than the one that shipped. The seam is typed as zustand `StateStorage` and hard-wires `createOpfsCorpusFs()`. Nothing enforces dev-only. The file rename is not reflected. The write does not pass a fresh view.

### Fix Cost
- **Scope:** 4 files, comment-only (or one real copy: `bytes.slice()` at `:116`, if the comment is the intent)
- **Effort:** under an hour
- **Risk:** none
- **Incremental?** yes

### Urgency Triggers
- none identified (E3's enforcement question is a security call, routed separately)

### Recommendation
**Recommendation:** Fix now

These are trivial in-place edits under 50 LOC. Fix them in this branch before merge. Leaving them in makes the review findings recur in every later S-n review.

---

## Tech Debt Triage: TD6. The characterization test does not pin the behaviors this change moved

**Severity:** Low · **Confidence:** high · **Legibility-target:** for-author
**Location:** `app/lib/stores/__tests__/workspaceStore-characterization.test.ts:49-106` (whole `describe`); behaviors not pinned are at `app/lib/corpus/storeAdapter.ts:25-45`
**Evidence:**
```
51:    useWorkspaceStore.setState({ artifacts: { "causal-graph": threeVersionRecord() } });
52:    vi.advanceTimersByTime(300); // flush debounced write
```
(excerpt; the four tests in the enclosing `describe` (:49-106) each advance exactly 300 ms and assert on the persisted shape only. Read.)
**Nature:** testing (Stage-1 Claim 9).
**Cost of Deferral:** `+0 — inert`. The moved body is textually identical today (Claim 10).
**Failure Cost:** blank

### Carrying Cost: Low
The PR's central promise ("byte-for-byte the prior behavior, guarded by a characterization test") is only partly guarded. Nothing tests debounce coalescing (two writes within 300 ms produce one `setItem`), the quota `console.warn` swallow, or `removeItem` cancelling a pending write. Today the code is a verbatim move, so nothing has drifted. The gap matters only when someone edits `createDebouncedLocalStorage`, which is likely in S4.

### Fix Cost
- **Scope:** localized (one test file, 3 cases)
- **Effort:** about an hour
- **Risk:** none
- **Incremental?** yes

### Urgency Triggers
- The first edit to `createDebouncedLocalStorage` (the S4 migration is the likely one).

### Recommendation
**Recommendation:** Fix opportunistically

Add the three cases the next time anyone works in `storeAdapter.ts`. They cost little and make the "OFF path unchanged" claim true as stated.

---

## Tech Debt Triage: TD7. Speculative scaffolding: unused path builders, error kinds and the worker-error twin

**Severity:** Low · **Confidence:** high · **Legibility-target:** for-author
**Location:** `app/lib/corpus/types.ts:41-49,63-75`; `app/lib/corpus/paths.ts` (whole module); `app/lib/corpus/storeAdapter.ts:55`
**Evidence:**
```
55:  const pathFor = (name: string) => `state/${name}.json`;
```
(excerpt; enclosing `createCorpusBackedStorage()` runs :52-68. Read.)
A grep of `app/` finds no non-test importer of `paths.ts` or `manifest.ts`, and no use of `toWorkerError`, `isCorpusWorkerError`, or the `not-found` / `browser-storage-cleared` kinds outside `types.ts` (only a comment mention at `manifest.ts:12`).
**Nature:** structural (built-ahead API surface).
**Cost of Deferral:** `+0 — inert`. Slight risk of shape drift: S2-S4 may need different shapes from the ones guessed here.
**Failure Cost:** blank

### Carrying Cost: Low
This is intentional per the S0 plan, so it is not accidental debt. Two things deserve a note. First, `paths.ts:16-19` calls itself "the only source of corpus paths". That is false today (`storeAdapter.ts:55`), so the traversal choke point it claims to be does not exist yet. The blob name is a constant, so no traversal is reachable. Second, the `not-found` kind contradicts the interface's null-return convention (`types.ts` header), so it may never be produced.

### Fix Cost
- **Scope:** localized
- **Effort:** hours (route `state/` through a `paths.ts` builder; drop or document `not-found`)
- **Risk:** low
- **Incremental?** yes

### Urgency Triggers
- S3 (worker proxy) is the first real consumer of `CorpusWorkerError`. Reconcile the kind set then.

### Recommendation
**Recommendation:** Carry intentionally

It is built-ahead code from a staged plan. Carry it, but correct the "only source of paths" comment (folds into TD5), and revisit the kind set when S3 adds the first `switch` over it.

---

## Triage Summary

| # | Debt Item | Carrying Cost | Cost of Deferral | Failure Cost | Fix Cost | Urgency | Recommendation |
|---|-----------|:---:|:---:|:---:|:---:|:---:|---|
| TD1 | OPFS adapter not run against contract; fake diverges | Medium | +1 fake-trusting consumer per sub-task | Med × Med, S4 logic verified against wrong semantics | ~1 day | Before S4 | Fix now (docstrings now; harness pre-S4) |
| TD5 | Stale/incorrect comments (dev-only, seam type, rename, fresh view, line ref) | Low | +0 (inert) | | <1 hour | None | Fix now (trivial) |
| TD2 | Manifest codec lenient vs fail-loud contract | Low | +0 until S4, then format-compat cost | Low × High after S4 | Hours | S4 first write | Fix opportunistically |
| TD4 | Flag-on rehydrate still runs v2 localStorage migration | Low | +0 (inert) | | Hours | S4 migration design | Fix opportunistically |
| TD6 | Characterization test misses debounce/quota/removeItem | Low | +0 (inert) | | ~1 hour | First edit to debounced storage | Fix opportunistically |
| TD3 | Corpus storage: no debounce, unordered async writes | Low | +0 while dev-only | Low × Med now; Med × High if defaulted on | Hours | Flag default-on | Defer and monitor |
| TD7 | Built-ahead scaffolding (paths/manifest/worker error unused) | Low | +0 (inert) | | Hours | S3 | Carry intentionally |

### Recommended Order
1. **In this branch, before merge:** TD5 (comment fixes, including the "fake only" correction that is the cheap half of TD1) and the TD4 one-line gate if the author wants the "empty corpus" claim to hold. All are trivial and need no RPI.
2. **First task of S4 (or a pre-S4 chore):** the TD1 OPFS harness and fake-divergence cases, together with TD2's strict codec. Both protect the S4 data path, and both are cheapest before S4 code exists. TD1's harness meets the "non-trivial" bar, so route it through RPI. TD2 is small enough to do in place.
3. **Whenever `storeAdapter.ts` is next edited:** TD6, and TD3 if blob mode survives into S4.
4. **At S3:** reconcile TD7's error-kind set.

Overall: the change adds little *compounding* debt. The flag is off and most of the new modules have no consumers. The real cost is TD1 plus the TD5 comments: the code's own documentation claims assurances (contract-tested OPFS, fail-loud manifest, pure swap, dev-only) that later sub-tasks will build on. Fixing the claims is nearly free. Fixing the underlying gaps can wait until just before S4.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to the output path below, with `Commit: 2dc403e` as its first line, structured per the tech-debt-triage skill.
- Answered: yes
- Out of scope: whether "dev-only" must be enforced in code (E3) and the env-inlining question, which are security calls; anything needing a provisioned environment (vitest, build, real OPFS), which was not run (E6); the branch's docs files (context only).
- Escalate: (1) TD1. The OPFS success path is unverified, while four docstrings and a commit body claim otherwise; the orchestrator should make the correction a pre-merge item and the harness a pre-S4 gate. (2) TD3. If anyone proposes defaulting the flag on, the unordered whole-blob writes become a data-rollback risk and must be fixed first. (3) TD4. Flag-on rehydration runs `migrateFromV2` (corroborates Stage-1 E4), so architecture-review should own the call.
- Decisions I made: I treated built-ahead S0 scaffolding as intentional rather than accidental debt (TD7). I rated TD3's write-ordering hazard at medium confidence from OPFS writable semantics without executing it. I split TD1's fix into a trivial pre-merge docstring correction and a pre-S4 harness so that "Fix now" stays proportionate.
