
## Stage-1 merged fact-check summary (k=3, most-severe-wins; full report has 25 claims, only non-Verified rows shown)

Full merged report: /workspace/.worktrees/wt-2026-11-19-a8-settling-runs/runs/review-arms/a8-2026-11-20/corpus/code-fact-check-report.md (replicates r1-r3 beside it). Replicates ran manifest.ts, paths.ts, types.ts and opfsAdapter.ts under `node --experimental-strip-types` (stubbed `navigator.storage`); none could run vitest, lint or `next build` (no `node_modules`, no network).

Incorrect:
- Claim 1 (`app/lib/corpus/__tests__/corpusFs.contract.test.ts:1-3`, `corpusFsContract.ts:4-7`, `inMemoryCorpusFs.ts:4-7`, `opfsAdapter.test.ts:4-7`, f6361a3 body): the OPFS adapter is not held to the contract suite; the only caller passes the in-memory fake, and `docs/spikes/corpus-opfs-smoke.md` is an unrun sketch. Fake and OPFS differ on file/dir name clashes and rm of a directory. 3/3.
- Claim 2 (`app/lib/corpus/flag.ts:4`): "DEV-ONLY" is not enforced; no NODE_ENV check. 3/3.
- Claim 3 (`app/lib/corpus/manifest.ts:10-14`): the codec is not fail-loud; malformed entries are filtered out (`:87,94,102-103`), timestamps default to now (`:109-110`), manifestVersion is never checked, negative currentVersion is accepted. Executed 3/3.
- Claim 4 (`manifest.ts:10-13`): only kind "io" is thrown; nothing produces "browser-storage-cleared". r1 Incorrect (compound), r2/r3 Mostly accurate.
- Claim 5 (`app/lib/corpus/opfsAdapter.ts:115`): "Pass a fresh ArrayBuffer view" but `w.write(bytes)` passes the caller's array (the fake copies). 3/3.
- Claim 6 (`app/lib/corpus/paths.ts:16-19`, ec7bbbc body): not the only source of corpus paths; `storeAdapter.ts:55` hand-builds `state/${name}.json`, and no production code imports paths.ts. 3/3.

Stale:
- Claim 7 (`opfsAdapter.ts:14`): cites `workspaceStore.ts:44-46`; the swallow moved to `storeAdapter.ts:34-36`. 3/3.
- Claim 8 (`storeAdapter.ts:11`): still says `layout.ts` (renamed to `paths.ts` in 122d70f). 3/3.

Mostly accurate:
- Claim 9 (characterization test docstring): pins persisted shape and round-trip, not debounce timing, the quota swallow or removeItem.
- Claim 10 (`storeAdapter.ts:21`, 00ba8c3 "moved verbatim"): body identical, but renamed, exported and retyped as StateStorage.
- Claim 11 (`storeAdapter.ts:5-8`, `workspaceStore.ts:496-498`): the store binds to zustand StateStorage; CorpusFS is one layer down; `resolveWorkspaceStorage` hard-wires `createOpfsCorpusFs()`.
- Claim 12 (`flag.ts:4-6` "starts from an EMPTY corpus"): with the flag on, `onRehydrateStorage` (`workspaceStore.ts:533-540`) can still copy legacy workspace-v2 localStorage into the store via `migrateFromV2` (r2 only).
- Claim 13 (`paths.ts:32` "strips unicode"): accented letters become hyphens (r2 only).
- Claim 14 (`storeAdapter.ts:5-8,12` "pure substrate swap"): the store still reads localStorage directly at `workspaceStore.ts:534` (r2 only).

Unverifiable: Claim 22 (test counts; static counts match), Claim 23 (lint/build/324 tests; a static count finds 317), Claim 24 (`flag.ts:16` `process.env?.NEXT_PUBLIC_CORPUS_FS`: the optional chain may defeat Next's inlining), Claim 25 (layout.ts reserved-name build failure).

Verified with a caveat:
- Claim 15 (`opfsAdapter.ts`, unavailable guard): r1: "if getDirectory exists but throws (SecurityError), it maps to io".
- Claim 16 (`opfsAdapter.ts`, quota reification): r1 probe: "if write() hits quota and close() in the finally throws a different error, the result is io".
- Claim 18 (flag-off path unchanged): one new side effect, a localStorage read of the flag key at store init.

### Escalations (routing contract)
- E1 `app/lib/corpus/__tests__/corpusFsContract.ts:4-7` — OPFS success path has no executed coverage despite four docstrings and a commit. Addressee: test-strategy, architecture-review.
- E2 `app/lib/corpus/manifest.ts:87,94,102-110` — codec silently drops malformed entries, defeating its fail-loud contract; its tests miss it. Addressee: api-consistency-reviewer, test-strategy.
- E3 `app/lib/corpus/flag.ts:4,16` — "dev-only" not enforced; env route may not inline. Addressee: security-reviewer.
- E4 `app/lib/stores/workspaceStore.ts:533-540` — with the flag on, rehydration can run migrateFromV2 over the corpus-backed store. Addressee: architecture-review.
- E5 `app/lib/corpus/opfsAdapter.ts` (write/close in finally) — a close() error can mask a quota error as "io". Addressee: security-reviewer, performance-reviewer.
- E6 build, lint, vitest and env-route inlining need a provisioned environment. Addressee: orchestrator.
