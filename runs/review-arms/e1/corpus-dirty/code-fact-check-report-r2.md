# Code Fact-Check Report

**Repository:** meta-formalism-copilot (worktree /workspace/runs/review-arms/e1/wt-corpus-dirty, detached)
**Scope:** `git diff dc6dfb0..2dc403e -- app/` (corpus S0/S1 changeset: `app/lib/corpus/**`, `app/lib/stores/workspaceStore.ts` + tests) plus commit messages ec7bbbc, 3da6747, f6361a3, 00ba8c3, 122d70f. `docs/working/**` planning files used as evidence only, not verdicted.
**Checked:** 2026-08-06
**Total claims checked:** 28
**Summary:** 19 Verified, 4 Mostly accurate, 3 Stale, 1 Incorrect, 1 Unverifiable. The corpus module's documentation is unusually accurate — all commit-message test counts reconstruct exactly from static counts, and the "moved verbatim" debounce claim survives a line-by-line diff. The genuine problems are: one incorrect comment in `opfsAdapter.writeFile` describing a defensive copy the code does not perform; the `paths.ts` "only source of corpus paths" invariant, which `storeAdapter.ts` quietly violates with a hand-built `state/` path added later in the same range; two stale file/line references left behind by the layout.ts→paths.ts rename and the debounce-adapter move; and a fail-loud manifest codec that is loud at the manifest level but silently defaults/drops at the field level.

**Commit:** 2dc403e

---

## Claim 1: flag is DEFAULT OFF

**Location:** `app/lib/corpus/flag.ts:4`
**Type:** Behavioral / configuration
**Verdict:** Verified
**Confidence:** High — the whole function is 10 lines and every path was read.
**Legibility-target:** for-orchestrator-synthesis

> "DEFAULT OFF and DEV-ONLY." (flag.ts:4)

`isCorpusEnabled()` returns `true` only when the env var equals `"1"` or the localStorage key equals `"1"`; every other path returns `false`, including the localStorage-throw path:

**Evidence:**
```ts
if (typeof process !== "undefined" && process.env?.NEXT_PUBLIC_CORPUS_FS === "1") return true;
if (typeof window !== "undefined") {
  try {
    return window.localStorage.getItem(CORPUS_FLAG_KEY) === "1";
  } catch {
    return false;
  }
}
return false;
```
(flag.ts:16-24). The sole consumer is `resolveWorkspaceStorage()` (`storeAdapter.ts:72`), which falls back to `createDebouncedLocalStorage()` when false — confirmed by the G13 test asserting `getDirectory` is never called by default (`workspaceStore-corpus-flag.test.ts:36`).

---

## Claim 2: flag is "DEV-ONLY" / enabled "at runtime in a dev browser"

**Location:** `app/lib/corpus/flag.ts:4, 9-10`
**Type:** Configuration / invariant
**Verdict:** Mostly accurate
**Confidence:** High — the enforcement absence is directly visible in the 10-line implementation.
**Legibility-target:** for-author

> "DEFAULT OFF and DEV-ONLY." (flag.ts:4)
> "or, at runtime in a dev browser, `localStorage.setItem("corpus-fs-enabled", "1")`." (flag.ts:9-10)

"DEV-ONLY" is policy, not mechanism. Nothing in `isCorpusEnabled()` checks `process.env.NODE_ENV` or any dev-mode signal — the localStorage gate works identically in a production deployment's browser. Any end user who sets `localStorage["corpus-fs-enabled"]="1"` on a production build flips their persistence to an empty OPFS corpus, which is exactly the data-abandonment scenario the header warns about ("enabling this starts from an EMPTY corpus", flag.ts:5-6). The claim is accurate as a statement of intent and of default behavior, but "dev browser" describes the expected operator, not an enforced constraint.

**Evidence:** flag.ts:15-25 quoted in Claim 1 — no `NODE_ENV` or dev gate appears. `rg -n 'NODE_ENV' app/lib/corpus/` returns nothing (paraphrased — no quote available because the search returned zero matches).

---

## Claim 3: build-time env `NEXT_PUBLIC_CORPUS_FS=1` enables the flag (client-bundle inlining)

**Location:** `app/lib/corpus/flag.ts:9, 16`
**Type:** Configuration / behavioral
**Verdict:** Unverifiable
**Confidence:** Medium — the code and Next version are known, but only inspecting a built client bundle would settle whether the access pattern is inlined.
**Legibility-target:** for-orchestrator-synthesis

> "Enable via either the build-time env `NEXT_PUBLIC_CORPUS_FS=1`" (flag.ts:9)

The access pattern is `process.env?.NEXT_PUBLIC_CORPUS_FS` (flag.ts:16) — an *optional-chained* member access. Next.js inlines `NEXT_PUBLIC_*` vars by rewriting the exact member expression `process.env.NEXT_PUBLIC_X`; whether the optional-chained form is rewritten depends on the bundler's define handling (webpack 5's DefinePlugin added optional-chaining support, and Next 16 may compile with either webpack or Turbopack — `"next": "^16.2.6"`, package.json:23). If the expression is *not* rewritten, client bundles still see Next's `process.env` shim, so the guard won't crash — the env half of the flag would just silently never activate in the browser, leaving only the localStorage gate. 122d70f's "npm run build passes" does not discriminate between these outcomes. No test exercises the env path (`workspaceStore-corpus-flag.test.ts` covers only the localStorage gate, lines 25-37 and 61-82). Paraphrased — no quote available for the bundler's rewrite behavior because node_modules is not installed in this worktree and the claim concerns build output, not source.

**Evidence:** flag.ts:16 (`if (typeof process !== "undefined" && process.env?.NEXT_PUBLIC_CORPUS_FS === "1") return true;`); package.json:23 (`"next": "^16.2.6"`).

---

## Claim 4: no localStorage→corpus migration in S1 (that is S4)

**Location:** `app/lib/corpus/flag.ts:4-7`
**Type:** Reference / architectural
**Verdict:** Verified
**Confidence:** High — the range contains no migration code, and the planning docs assign migration to S4.
**Legibility-target:** for-orchestrator-synthesis

> "In S1 there is no localStorage->corpus migration (that is S4), so enabling this starts from an EMPTY corpus" (flag.ts:4-6)

No file in `app/lib/corpus/` reads the legacy localStorage keys; `createCorpusBackedStorage` reads only `state/<name>.json` from the injected `CorpusFS` (storeAdapter.ts:57-59), so a fresh OPFS root yields `getItem → null` → the store renders defaults. The plan confirms the assignment: "plan + CLAUDE.md state explicitly that S1 flag-ON starts clean and migration is S4" (docs/working/plan-corpus-s1.md:75). The existing `migrateFromV2()` path migrates workspace-v2→zustand *within* localStorage and is untouched by the range (present identically at dc6dfb0).

**Evidence:** storeAdapter.ts:57-59 (`const bytes = await fs.readFile(pathFor(name)); return bytes ? dec.decode(bytes) : null;`).

---

## Claim 5: manifest parsing is FAIL-LOUD, surfacing kind "io" or "browser-storage-cleared"

**Location:** `app/lib/corpus/manifest.ts:10-13`
**Type:** Behavioral / invariant
**Verdict:** Mostly accurate
**Confidence:** High — every throw site in the codec was read; the kind is hardcoded in one place.
**Legibility-target:** for-author

> "parsing is FAIL-LOUD. A malformed or absent manifest must surface as a typed `CorpusError` of kind 'io' or 'browser-storage-cleared', never a silent default-empty manifest" (manifest.ts:10-13)

Two inaccuracies. First, the codec can only ever emit kind `"io"` — the single failure helper hardcodes it:

```ts
function fail(reason: string): never {
  throw new CorpusError({ kind: "io", path: "workspace.json", reason }, `invalid workspace.json: ${reason}`);
}
```
(manifest.ts:64-67). `"browser-storage-cleared"` is emitted nowhere in the repo — `rg -n 'browser-storage-cleared' app/` matches only its declaration (types.ts:48) and message (types.ts:86) and this docstring. If a caller is meant to translate absence into `browser-storage-cleared`, no such caller exists yet. Second, the core promise holds: `parseManifest(null)` throws (manifest.ts:75), non-JSON throws (manifest.ts:80), a missing `title`/`manifestVersion`/`sources`/`artifacts`/`customTypeIds` throws (manifest.ts:83-84, 91, 100, 104), and the G11 test asserts `detail.kind === "io"` (manifest.test.ts:39). So "never a silent default-empty manifest" is true at the whole-manifest level; the kind enumeration overstates the codec's range.

**Evidence:** quoted above; types.ts:48 (`| { kind: "browser-storage-cleared" }`).

---

## Claim 6: `parseManifest` "Throws a `CorpusError` on any malformation"

**Location:** `app/lib/corpus/manifest.ts:69-73`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High — every field of the return object was traced to its validation (or lack of one).
**Legibility-target:** for-author

> "Parse + validate manifest bytes. Throws a `CorpusError` on any malformation" (manifest.ts:70)

Structural malformations throw, but several field-level malformations are silently defaulted or dropped, which sits uneasily beside the module's fail-loud framing:

- **Non-object entries in `sources`/`artifacts` are silently discarded**, not rejected: `raw.sources.filter(isObject).map(...)` (manifest.ts:87) and `raw.artifacts.filter(isObject).map(...)` (manifest.ts:94). A manifest whose `sources` array is `["garbage", 42]` parses successfully as having zero sources — a per-entry version of exactly the "masquerade as no work" failure the header warns against.
- **Non-string `customTypeIds` entries silently dropped:** `raw.customTypeIds.filter((x): x is string => typeof x === "string")` (manifest.ts:103).
- **Silent defaults applied:** `label` defaults to `id` (manifest.ts:89, `label: typeof s.label === "string" ? s.label : s.id`); `createdAt`/`updatedAt` default to `new Date().toISOString()` (manifest.ts:109-110).
- **`manifestVersion` is type-checked but never range-checked** against `MANIFEST_VERSION` (manifest.ts:84 checks `typeof raw.manifestVersion !== "number"` only) — a future v2 manifest parses as v1 without complaint.

Present-object-but-missing-field entries do throw (`fail("source entry missing id/ext")`, manifest.ts:88; `fail("artifact pointer missing type/currentVersion")`, manifest.ts:96), and the docstring correctly assigns null-handling to the caller. "Any malformation" is an overstatement at the entry/field level.

**Evidence:** quoted inline above.

---

## Claim 7: paths.ts layout diagram matches the builders

**Location:** `app/lib/corpus/paths.ts:4-13`
**Type:** Architectural / reference
**Verdict:** Verified
**Confidence:** High — every builder output was compared to the diagram, and the test file pins exact strings.
**Legibility-target:** for-orchestrator-synthesis

> "`<corpus-root>/ ├── settings.json └── workspaces/<slug>/ ├── workspace.json ├── sources/<source-id>.<ext> ├── artifacts/<type>/v####.md (+ meta.json per type) ├── custom-types/<custom-type-id>.json └── decomposition/...`" (paths.ts:6-13)

Each line has a corresponding builder producing exactly that shape: `SETTINGS_PATH = "settings.json"` (paths.ts:68), `workspaceManifestPath` → `workspaces/<slug>/workspace.json` (paths.ts:74-76), `sourcePath` (paths.ts:78-80), `artifactVersionPath` zero-padded to 4 via `VERSION_PAD = 4` (paths.ts:23, 88-94), `artifactMetaPath` (paths.ts:96-98), `customTypePath` (paths.ts:100-102), `decompositionGraphLayoutPath` (paths.ts:108-110). Pinned by paths.test.ts:47-66, e.g. `expect(artifactVersionPath(s, "semiformal", 1)).toBe("workspaces/my-slug/artifacts/semiformal/v0001.md")` (paths.test.ts:55).

**Evidence:** quoted above.

---

## Claim 8: "The only source of corpus paths is this module — callers must never hand-concatenate"

**Location:** `app/lib/corpus/paths.ts:16-19`
**Type:** Invariant / architectural
**Verdict:** Stale
**Confidence:** High — the counterexample is a literal template string in a sibling corpus module.
**Legibility-target:** for-author

> "The only source of corpus paths is this module — callers must never hand-concatenate, so the traversal guard in `workspaceSlug` is the single choke point that keeps untrusted workspace titles inside `workspaces/`." (paths.ts:16-19)

True when written (ec7bbbc, no other corpus module existed), invalidated one commit later in the same range: 00ba8c3's `storeAdapter.ts` hand-concatenates a corpus path that goes through no builder in this module:

```ts
const pathFor = (name: string) => `state/${name}.json`;
```
(storeAdapter.ts:55). This is a real write path — `createCorpusBackedStorage` writes the entire persist blob there (storeAdapter.ts:61-63), and the G14 test confirms bytes land at `state/workspace-zustand-v1.json` (workspaceStore-corpus-flag.test.ts:49). The `state/` prefix also does not appear in the documented folder layout (paths.ts:6-13, Claim 7). The narrow security half of the claim survives: `name` is the store's constant `"workspace-zustand-v1"` (workspaceStore.ts:495), not untrusted user input, so `workspaceSlug` remains the only choke point that handles untrusted *titles*. But the categorical "only source of corpus paths" statement is false at 2dc403e, and the drift matters because S2's FSA mirror will replay whatever paths exist — an undocumented top-level `state/` directory would silently appear in the user's mirrored folder.

**Evidence:** quoted above.

---

## Claim 9: slug/segment sanitization guarantees

**Location:** `app/lib/corpus/paths.ts:26-35, 49-51`
**Type:** Behavioral / invariant
**Verdict:** Verified
**Confidence:** High — regex read directly; behavior pinned by tests including the throw-on-empty edge.
**Legibility-target:** for-orchestrator-synthesis

> "Everything else is collapsed to a hyphen so a value can never contain '/', '\\', '.' runs, or control characters" (paths.ts:27-28); "Throws if nothing safe remains (an all-unsafe title must not silently become \"\")" (paths.ts:34)

`SAFE_SEGMENT = /[^a-zA-Z0-9_-]+/g` (paths.ts:28) excludes `/`, `\`, `.` and all control characters from the allowed set, so `workspaceSlug` (paths.ts:36-47) and `safeSegment` (paths.ts:52-58) replace them; both throw on an empty result (paths.ts:43-45, 54-56). Pinned by tests: `expect(workspaceSlug("../etc/passwd")).not.toContain("..")` (paths.test.ts:17) and `expect(() => workspaceSlug("////")).toThrow(/empty slug/)` (paths.test.ts:30). One nuance not contradicting the claim: single hyphen-adjacent dots collapse into the same hyphen run, so no `.` can survive at all — stronger than "no `.` runs".

**Evidence:** quoted above.

---

## Claim 10: storeAdapter seam — localStorage default, CorpusFS-typed injection

**Location:** `app/lib/corpus/storeAdapter.ts:4-8`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High — signatures and both selection branches read directly; routing pinned by G13/G14/G15 tests.
**Legibility-target:** for-orchestrator-synthesis

> "`resolveWorkspaceStorage()` returns the zustand persist storage: the existing debounced localStorage adapter by default, or a CorpusFS-backed storage when the dev flag is on. The injection seam is typed as `CorpusFS`" (storeAdapter.ts:4-7)

`resolveWorkspaceStorage()` branches exactly so (storeAdapter.ts:71-76), and the seam signature is `export function createCorpusBackedStorage(fs: CorpusFS): StateStorage` (storeAdapter.ts:52) — the interface type, not `createOpfsCorpusFs`'s return. The G14 test injects the in-memory fake through the same seam (workspaceStore-corpus-flag.test.ts:42-43), demonstrating the drop-in property the comment promises for the S3 worker proxy.

**Evidence:**
```ts
export function resolveWorkspaceStorage(): StateStorage {
  if (isCorpusEnabled()) {
    return createCorpusBackedStorage(createOpfsCorpusFs());
  }
  return createDebouncedLocalStorage();
}
```
(storeAdapter.ts:71-76).

---

## Claim 11: S1 stores the persist blob as a SINGLE file (blob mode); folder layout built but unused until S4

**Location:** `app/lib/corpus/storeAdapter.ts:10-13`
**Type:** Behavioral / architectural
**Verdict:** Verified
**Confidence:** High — the corpus-backed storage has exactly one path and no imports from paths.ts/manifest.ts.
**Legibility-target:** for-orchestrator-synthesis

> "In S1 the persist blob is stored as a SINGLE file via CorpusFS (blob mode) — the files-per-artifact folder layout (layout.ts/manifest.ts) is built but not used by the store until S4." (storeAdapter.ts:10-12)

`createCorpusBackedStorage` reads/writes/removes only `state/<name>.json` (storeAdapter.ts:55-67); storeAdapter.ts imports nothing from `paths.ts` or `manifest.ts` (imports at storeAdapter.ts:15-18 are zustand types, `CorpusFS`, the OPFS adapter, and the flag). Grep confirms no caller of the paths.ts builders exists outside tests: the only importers of `../paths` / `./paths` are `paths.test.ts` (paraphrased — no quote available because the assertion is about an absence of matches). The behavioral claim is fully accurate; the stale `layout.ts` filename in it is verdicted separately as Claim 12.

**Evidence:** storeAdapter.ts:55 (`const pathFor = (name: string) => \`state/${name}.json\`;`).

---

## Claim 12: reference to "layout.ts" in storeAdapter

**Location:** `app/lib/corpus/storeAdapter.ts:11`
**Type:** Reference / staleness signal
**Verdict:** Stale
**Confidence:** High — the referenced file does not exist at 2dc403e.
**Legibility-target:** for-author

> "the files-per-artifact folder layout (layout.ts/manifest.ts) is built but not used" (storeAdapter.ts:11)

`layout.ts` was renamed to `paths.ts` in 122d70f ("Rename app/lib/corpus/layout.ts -> paths.ts: Next.js App Router treats any app/**/layout.ts as a route layout"), a later commit in this same range, but this comment (written in 00ba8c3) was not updated. At 2dc403e the corpus directory contains `flag.ts manifest.ts opfsAdapter.ts paths.ts storeAdapter.ts types.ts` and no `layout.ts` (paraphrased — no quote available because this is a directory listing). Low-stakes but exactly the kind of pointer that misleads the S2 implementer the seam docs target.

**Evidence:** 122d70f commit message quoted above; directory listing.

---

## Claim 13: debounced localStorage "moved verbatim from workspaceStore.ts", OFF path byte-for-byte prior behavior, 300ms debounce

**Location:** `app/lib/corpus/storeAdapter.ts:21-23`
**Type:** Behavioral / invariant
**Verdict:** Verified
**Confidence:** High — line-by-line diff against the pre-range implementation at dc6dfb0.
**Legibility-target:** for-orchestrator-synthesis

> "Default: debounced localStorage (moved verbatim from workspaceStore.ts so the OFF path is byte-for-byte the prior behavior — see the characterization test). Reads are synchronous (instant); writes are debounced by 300ms." (storeAdapter.ts:21-23)

I diffed `createDebouncedLocalStorage` (storeAdapter.ts:25-46) against `createDebouncedStorage` in `git show dc6dfb0:app/lib/stores/workspaceStore.ts`. The function *body* is identical token-for-token — same `pending` timer, same `clearTimeout`/`setTimeout(..., 300)`, same `console.warn("Failed to persist workspace (localStorage quota exceeded):", e)`, same `removeItem` cancel-then-delete. The only differences are outside the body: the function name and the return-type annotation (old: inline object type; new: `StateStorage`) — type-level only, no behavioral delta. The 300ms figure matches both versions (`}, 300);`, storeAdapter.ts:38). `getItem` is a synchronous passthrough to `localStorage.getItem` (storeAdapter.ts:28). The characterization test referenced does exist and flushes the same 300ms debounce (`vi.advanceTimersByTime(300); // flush debounced write`, workspaceStore-characterization.test.ts:52).

**Evidence:** old body excerpt from dc6dfb0 (`pending = setTimeout(() => { try { localStorage.setItem(name, value); } catch (e) { console.warn("Failed to persist workspace (localStorage quota exceeded):", e); } pending = null; }, 300);`) — identical at storeAdapter.ts:31-38.

---

## Claim 14: storage "Selected once when the store's persist middleware initializes"

**Location:** `app/lib/corpus/storeAdapter.ts:70`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium — the call-site wiring is directly visible, but zustand's `createJSONStorage` internals could not be quoted (node_modules is not installed in this worktree); zustand v5's documented behavior is that `createJSONStorage(getStorage)` invokes the provider once, eagerly, when called.
**Legibility-target:** for-orchestrator-synthesis

> "Selected once when the store's persist middleware initializes." (storeAdapter.ts:70)

The wiring is `storage: createJSONStorage(resolveWorkspaceStorage)` inside the `persist` options of the module-level `create()` call (workspaceStore.ts:499), so selection happens at module evaluation of `workspaceStore.ts` and is never re-run — meaning a flag toggle takes effect only after a reload, consistent with the dev-only framing. Paraphrased — no quote available for `createJSONStorage`'s eager invocation because `node_modules/zustand` is absent from this worktree; the dependency is `"zustand": "^5.0.13"` (package.json:33).

**Evidence:** workspaceStore.ts:499 (`storage: createJSONStorage(resolveWorkspaceStorage),`).

---

## Claim 15: "Not found" is `null`/`[]`, everything else rejects with `CorpusError`, callers never see `undefined`

**Location:** `app/lib/corpus/types.ts:17-18` (and per-method docs at types.ts:113-124)
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High — both implementations read end-to-end; convention pinned by the shared contract suite.
**Legibility-target:** for-orchestrator-synthesis

> "'Not found' is `null` from `readFile`/`stat` and `[]` from `readdir`; everything else rejects with a `CorpusError`. Callers never see `undefined`." (types.ts:17-18)

OPFS adapter: `readFile` returns `null` for missing dir or file (opfsAdapter.ts:92, 97), `stat` likewise (opfsAdapter.ts:161, 166), `readdir` returns `[]` (opfsAdapter.ts:130), `rm` is an idempotent no-op on missing (opfsAdapter.ts:144, 148); every other failure funnels through `wrap()`, which always throws a `CorpusError` (opfsAdapter.ts:79-83). In-memory fake: `files.get(normalize(path)) ?? null` (inMemoryCorpusFs.ts:22) — the `?? null` is precisely what keeps `undefined` from leaking. The contract suite pins the convention for both (`expect(await fs.readFile("absent.txt")).toBeNull()`, corpusFsContract.ts:22; `expect(await fs.readdir("nope")).toEqual([])`, corpusFsContract.ts:27). "Implementations create intermediate directories on write" (types.ts:110) also holds: `walkDir(root, dirs, true)` (opfsAdapter.ts:111), implicit dirs in the fake (inMemoryCorpusFs.ts:8), pinned at corpusFsContract.ts:41-47.

**Evidence:** quoted above.

---

## Claim 16: `CorpusErrorKind` is "the complete set of corpus failure kinds"; exhaustive switches bind to it

**Location:** `app/lib/corpus/types.ts:36-49`
**Type:** Invariant / architectural
**Verdict:** Verified
**Confidence:** High — every producer of `CorpusError` in the repo was enumerated.
**Legibility-target:** for-orchestrator-synthesis

> "The complete set of corpus failure kinds. Every exhaustive `switch` over a corpus error binds to this union; adding a kind here forces every consumer to handle it at compile time" (types.ts:37-39)

The union is the sole kind source: `describeCorpusError` switches over all eight kinds with an `assertNever` default (types.ts:78-90, 94-96) — the one exhaustive switch in the range, and it does bind to the union. Per-kind production audit (the brief's ask): **produced today** — `unavailable` (opfsAdapter.ts:52), `io` (opfsAdapter.ts:60, 82; manifest.ts:66), `quota-exceeded` (opfsAdapter.ts:81). **Declared but produced by no implementation** — `not-found`, `fsa-permission-revoked` (S2), `remote-auth-expired` (S3), `browser-storage-cleared`, `git-conflict` (S3). The forward declarations are consistent with the substrate-neutral design note (types.ts:31-33) and plan step 1. One tension worth the orchestrator's eye: the `not-found` kind is *unreachable by design* — the interface convention (Claim 15) returns `null`/`[]` instead of throwing it, and `isNotFound` in the adapter exists only to trigger those null returns (opfsAdapter.ts:42-44, 97), never to mint the kind. Dead union arm, not a false claim.

**Evidence:** quoted above; `throw new CorpusError({ kind: "quota-exceeded", substrate: "opfs" });` (opfsAdapter.ts:81).

---

## Claim 17: `CorpusWorkerError` is the serializable twin, differing "only in transport, never in the kind set"

**Location:** `app/lib/corpus/types.ts:27-28, 61-62`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High — both types are defined on the same page.
**Legibility-target:** for-orchestrator-synthesis

> "`CorpusError` is the thrown form; `CorpusWorkerError` is its postMessage-serializable twin. They differ only in transport, never in the kind set." (types.ts:27-28)

Both carry the identical `detail: CorpusErrorKind` (types.ts:53, 65); `toWorkerError` copies `detail` and `message` verbatim (types.ts:69-71), and the documented reconstruction `new CorpusError(payload.detail, payload.message)` (types.ts:62) round-trips them. The worker type is a plain object literal (no prototype), so it is structured-clone-safe as claimed. No worker exists yet (S3), so this is contract-only — consistent with its framing.

**Evidence:** types.ts:63-67, 69-71.

---

## Claim 18: SSR/unavailable guard — any call without `navigator.storage.getDirectory` rejects with typed `CorpusError`, never a raw `TypeError`

**Location:** `app/lib/corpus/opfsAdapter.ts:9-11`
**Type:** Behavioral / invariant
**Verdict:** Verified
**Confidence:** High — all five methods share the same guarded entry point; both stub scenarios are tested.
**Legibility-target:** for-orchestrator-synthesis

> "any call in an environment without `navigator.storage.getDirectory` rejects with a typed `CorpusError` ({kind:'unavailable'}), never a raw `TypeError`." (opfsAdapter.ts:9-11)

All five methods call `getRoot()` first, inside their `try` (opfsAdapter.ts:89, 109, 127, 141, 158), and `getRoot` throws the typed error before touching anything: `if (!storage || typeof storage.getDirectory !== "function") { throw new CorpusError({ kind: "unavailable", ... }) }` (opfsAdapter.ts:50-53). The guard covers both `navigator` absent (SSR) and `storage` present without `getDirectory`. Tests drive both shapes: `setStorage({})` asserts `detail.kind === "unavailable"` (opfsAdapter.test.ts:27-37) and `setStorage(undefined)` asserts all four remaining methods reject with `CorpusError` (opfsAdapter.test.ts:40-47).

**Evidence:** opfsAdapter.ts:50-53 quoted in-part above.

---

## Claim 19: quota failures are reified as `{kind:"quota-exceeded", substrate:"opfs"}`, not swallowed with console.warn

**Location:** `app/lib/corpus/opfsAdapter.ts:12-14`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High — single error funnel; test pins the exact detail shape.
**Legibility-target:** for-orchestrator-synthesis

> "a quota failure rejects with {kind:'quota-exceeded', substrate:'opfs'} — it is NOT swallowed with console.warn the way the legacy localStorage adapter does" (opfsAdapter.ts:12-14)

Every method's catch funnels into `wrap()`: `if (isQuota(e)) throw new CorpusError({ kind: "quota-exceeded", substrate: "opfs" });` (opfsAdapter.ts:81), where `isQuota` matches both `QuotaExceededError` and legacy `QUOTA_EXCEEDED_ERR` names (opfsAdapter.ts:45-47). No `console.warn` appears anywhere in the adapter (paraphrased — no quote available because the assertion is a zero-match grep). The G7 test throws a `DOMException("quota", "QuotaExceededError")` from `createWritable` and asserts `detail.kind === "quota-exceeded"` and `detail.substrate === "opfs"` (opfsAdapter.test.ts:59, 80-81). The legacy contrast is real: the localStorage adapter does `console.warn("Failed to persist workspace (localStorage quota exceeded):", e)` (storeAdapter.ts:35). The *line reference* attached to this claim is verdicted separately as Claim 20.

**Evidence:** quoted above.

---

## Claim 20: legacy console.warn swallow located at "workspaceStore.ts:44-46"

**Location:** `app/lib/corpus/opfsAdapter.ts:14`
**Type:** Reference / staleness signal
**Verdict:** Stale
**Confidence:** High — the cited lines now contain unrelated code.
**Legibility-target:** for-author

> "it is NOT swallowed with console.warn the way the legacy localStorage adapter does (workspaceStore.ts:44-46)." (opfsAdapter.ts:12-14)

Accurate when written (f6361a3): at that commit the debounced adapter with its `console.warn` sat at workspaceStore.ts:44-46. One commit later (00ba8c3) the adapter moved to `storeAdapter.ts` — the same range under review — and the pointer was not updated. At 2dc403e, workspaceStore.ts:44-46 is the middle of `coerceArtifactVersion` (`id: raw.id, content: raw.content, createdAt: ...`), and the console.warn swallow lives at storeAdapter.ts:33-36. A reader following the pointer lands on validation code with no console.warn in sight.

**Evidence:** storeAdapter.ts:35 (`console.warn("Failed to persist workspace (localStorage quota exceeded):", e);`); workspaceStore.ts:44-46 (fields of the returned `ArtifactVersion`).

---

## Claim 21: DOMException → kind mapping (`NotFoundError`/`TypeMismatchError` → not-found handling; `QuotaExceededError`/`QUOTA_EXCEEDED_ERR` → quota)

**Location:** `app/lib/corpus/opfsAdapter.ts:42-47`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High — both predicates and all their call sites read.
**Legibility-target:** for-orchestrator-synthesis

The two predicates are exactly as the surrounding docs imply: `isNotFound` matches `NotFoundError` or `TypeMismatchError` (opfsAdapter.ts:42-44) — the latter correctly treated as "not found for our purposes" since asking for a file handle where a directory sits raises it — and its call sites all resolve to the null/[]/no-op convention (opfsAdapter.ts:72, 97, 148, 166) rather than throwing. `isQuota` (opfsAdapter.ts:45-47) feeds only the `quota-exceeded` throw in `wrap`. Everything unmatched becomes `{kind:"io", path, reason}` with the original message preserved (opfsAdapter.ts:82). Consistent with Claims 15/16/19.

**Evidence:**
```ts
function isNotFound(e: unknown): boolean {
  return e instanceof DOMException && (e.name === "NotFoundError" || e.name === "TypeMismatchError");
}
function isQuota(e: unknown): boolean {
  return e instanceof DOMException && (e.name === "QuotaExceededError" || e.name === "QUOTA_EXCEEDED_ERR");
}
```
(opfsAdapter.ts:42-47).

---

## Claim 22: "Pass a fresh ArrayBuffer view; some implementations dislike shared buffers."

**Location:** `app/lib/corpus/opfsAdapter.ts:114-116`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High — the comment describes an operation the adjacent line does not perform.
**Legibility-target:** for-author

> "// Pass a fresh ArrayBuffer view; some implementations dislike shared buffers.
> await w.write(bytes);" (opfsAdapter.ts:115-116)

No fresh view is created — the caller's `Uint8Array` is passed through as-is. A fresh view would be `bytes.slice()` (a copy) or `new Uint8Array(bytes)` / re-viewing the buffer; the code does neither. Contrast with the in-memory fake, which really does copy and says so accurately: "Copy so later mutation of the caller's array can't alter stored bytes." → `files.set(normalize(path), bytes.slice())` (inMemoryCorpusFs.ts:26-27). If the "implementations dislike shared buffers" concern is real (e.g., a `Uint8Array` over a `SharedArrayBuffer` making `write()` throw, relevant once the S3 worker exists), the code does not defend against it; if it is not real, the comment is noise. Either way the comment asserts behavior the code lacks.

**Evidence:** quoted above.

---

## Claim 23: store header — "custom debounced storage adapter rate-limits writes"

**Location:** `app/lib/stores/workspaceStore.ts:5`
**Type:** Behavioral / staleness signal
**Verdict:** Mostly accurate
**Confidence:** High — both storage branches read.
**Legibility-target:** for-author

> "persist middleware handles serialization lifecycle; custom debounced storage adapter rate-limits writes" (workspaceStore.ts:5)

Unconditionally phrased, but only the default branch debounces. When the corpus flag is on, storage is `createCorpusBackedStorage(...)`, whose `setItem` awaits `fs.writeFile` immediately with no debounce or rate-limiting (storeAdapter.ts:61-63) — every zustand `set()` triggers an OPFS write. Accurate for the default path (the only user-facing one in S1), and the seam comment lower in the same file (workspaceStore.ts:496-498) states the two-branch reality correctly, but the header predates the seam and was not updated to match.

**Evidence:** storeAdapter.ts:61-63 (`setItem: async (name, value) => { await fs.writeFile(pathFor(name), enc.encode(value)); }`).

---

## Claim 24: seam comment + skipHydration/SSR-safety at the persist options

**Location:** `app/lib/stores/workspaceStore.ts:496-501`
**Type:** Architectural / behavioral
**Verdict:** Verified
**Confidence:** High — the referenced caller was located and reads as described.
**Legibility-target:** for-orchestrator-synthesis

> "Storage seam is selected here (DD-009 S1): debounced localStorage by default, or a CorpusFS-backed adapter when the dev flag is on. The seam is typed as CorpusFS so the S3 worker-proxy is a drop-in." (workspaceStore.ts:496-498)
> "// SSR safe: render defaults first, hydrate in useEffect via rehydrate()
> skipHydration: true," (workspaceStore.ts:500-501)

Seam selection matches Claim 10's verified wiring (`storage: createJSONStorage(resolveWorkspaceStorage)`, workspaceStore.ts:499). One shorthand: strictly, `resolveWorkspaceStorage` returns `StateStorage` — the *CorpusFS typing* lives on `createCorpusBackedStorage(fs: CorpusFS)` one level down (storeAdapter.ts:52), which is where the drop-in substitution happens; the claim's substance holds. The rehydrate promise is kept by the root page: "// --- SSR hydration: trigger Zustand rehydrate once on mount ---" (page.tsx:78) followed by `useWorkspaceStore.persist.rehydrate();` inside a mount effect (page.tsx:83).

**Evidence:** quoted above.

---

## Claim 25: merge validates deserialized data before merging into the store

**Location:** `app/lib/stores/workspaceStore.ts:502-507`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High — the merge function and the coercion helper it delegates to were read in full.
**Legibility-target:** for-orchestrator-synthesis

> "// Validate deserialized localStorage data before merging into the store.
> // Reuses coerceDecomposition from workspacePersistence for node-level field validation." (workspaceStore.ts:502-503)

`merge` guards with `isObject(persisted)` and routes everything through `coercePersistedState` (workspaceStore.ts:504-507), which type-checks every field before accepting it (workspaceStore.ts:68-119) and calls `coerceDecomposition` for decomposition (workspaceStore.ts:100). Minor wording drift only: with the flag on, the deserialized data comes from CorpusFS rather than localStorage, but the same merge path validates it identically — the validation claim, which is the checkable substance, holds for both substrates.

**Evidence:** workspaceStore.ts:504-507 (`merge: (persisted, current) => ({ ...current, ...(isObject(persisted) ? coercePersistedState(persisted as Record<string, unknown>) : {}) })`).

---

## Claim 26: commit ec7bbbc — "S0 contracts ... (per plan-corpus-s1 steps 1-3)"

**Location:** commit ec7bbbc (message)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High — plan steps exist and the commit's file list matches them one-for-one.
**Legibility-target:** for-orchestrator-synthesis

The plan's Steps section defines step 1 "`CorpusFS` interface + error types. New `app/lib/corpus/types.ts`" (plan-corpus-s1.md:21), step 2 "folder layout path builders. New `app/lib/corpus/layout.ts`" (plan-corpus-s1.md:22), step 3 "`workspace.json` manifest schema + codec. New `app/lib/corpus/manifest.ts`" (plan-corpus-s1.md:23) — exactly the three files the commit adds (types.ts, layout.ts, manifest.ts). The message's content bullets (single kind source / arch-review findings 1-2, traversal sanitization, fail-loud parse) all correspond to code verified in Claims 5, 9, 16. One deviation inside the *plan*, not the commit: plan step 6 says quota maps to `opfs-quota-exceeded` while step 1 and the shipped code use substrate-neutral `quota-exceeded {substrate:"opfs"}` — the commit followed step 1 and arch-review finding 1, and docs/working is out of verdict scope.

**Evidence:** plan lines quoted above; commit message: "types.ts: CorpusFS async bytes+paths interface; single substrate-neutral CorpusErrorKind ... layout.ts: DD-009 folder-layout path builders + slug/segment traversal sanitization ... manifest.ts: workspace.json schema + fail-loud parse".

---

## Claim 27: commit 3da6747 — "26 tests pass" (per plan steps 4-5)

**Location:** commit 3da6747 (message)
**Type:** Reference / test-count (static)
**Verdict:** Verified
**Confidence:** High for the static count; the count reconstructs exactly with no expansion ambiguity.
**Legibility-target:** for-orchestrator-synthesis

> "26 tests pass." (3da6747 message)

Static `it(` count across the four test files the commit adds: `corpusFsContract.ts` 7 (invoked once by `corpusFs.contract.test.ts`, which itself contains 0) + `layout.test.ts` 10 + `manifest.test.ts` 5 + `workspaceStore-characterization.test.ts` 4 = **26**. No `it.each` in these files, so static = runtime. Plan steps 4 ("characterization baseline", plan-corpus-s1.md:24) and 5 ("in-memory fake + contract/unit tests", plan-corpus-s1.md:25) match the delivered files, including the message's specific claims: the S4 30-small-files contract case exists ("handles the S4 access pattern: 30 small files in one artifact dir (arch-review finding 4)", corpusFsContract.ts:58) and the fail-loud parse test asserts the typed kind (`expect((caught as CorpusError).detail.kind).toBe("io")`, manifest.test.ts:39).

**Evidence:** per-file counts from `git show 3da6747:<file> | grep -c` (paraphrased — no quote available because the evidence is a count, not a line).

---

## Claim 28: commits f6361a3, 00ba8c3, 122d70f — test counts ("3", "69 corpus+store", "324 vitest"), step references, and the rename rationale

**Location:** commits f6361a3, 00ba8c3, 122d70f (messages)
**Type:** Reference / test-count (static) / behavioral
**Verdict:** Verified
**Confidence:** High for counts and step references (exact static reconstruction); Medium for the Next.js build-failure mechanism (rename and reserved-name convention confirmed; the actual build error was not reproduced).
**Legibility-target:** for-orchestrator-synthesis

**f6361a3 "3 tests pass"** — `opfsAdapter.test.ts` contains exactly 3 `it(` blocks. Steps "6,8a": plan step 6 is the OPFS adapter (plan-corpus-s1.md:26) and step 8 names both test files (plan-corpus-s1.md:28); the plan has no literal "8a/8b" split — the commits subdivide step 8's two files, a faithful refinement rather than a mismatch.

**00ba8c3 "69 corpus+store tests pass"** — static reconstruction: corpus (`corpusFsContract` 7 + `layout.test` 10 + `manifest.test` 5 + `opfsAdapter.test` 3 = 25) + stores (`workspaceStore.test` 17 + hydration 8 + characterization 4 + corpus-flag 3 + `artifactEditHandlers` 2 plain `it` + 2 `it.each` over the 5-element `KEYS` array = 12) = 25 + 44 = **69**, exact. The `KEYS` array has 5 entries (artifactEditHandlers.test.ts:6-12). The message's other claims verify: "moved here verbatim" (Claim 13), "one-line storage swap" (the only persist-options change is line 499), "net shrinks the store file" (range diffstat: workspaceStore.ts +5/−33).

**122d70f "324 vitest tests pass"** — static reconstruction over all test files at 2dc403e: 309 `it(`/`test(` occurrences in `*.test.*` files + 7 contract-suite `it`s living in the non-matching `corpusFsContract.ts` + `it.each` expansion (+8: two `it.each(KEYS)` × 5 keys replacing 2 occurrences) = 316 + 8 = **324**, exact. Rename rationale: layout.ts→paths.ts is confirmed in the range (`layout.test.ts` at 3da6747 vs `paths.test.ts` at 2dc403e; imports updated, paths.test.ts:13 `from "../paths"`), and CLAUDE.md independently records the mechanism ("`paths.ts` — **not** `layout.ts`, which is a reserved Next.js filename"). Next's App Router does treat `layout.*` as a reserved file convention in any `app/` subdirectory, making the claimed missing-default build failure plausible; the build itself was not re-run, hence Medium on that clause. The message's doc claims all check out: `docs/thoughts/corpus-fs-seam.md` and `docs/spikes/corpus-opfs-smoke.md` exist, and the `OpfsWritable.write` narrowing is present ("write(data: Uint8Array): Promise<void>", opfsAdapter.ts:28).

**Evidence:** counts assembled from `rg -c '\bit\(|\bit\.each\(|\btest\('` per file (paraphrased — no quote available because the evidence is arithmetic over grep counts); KEYS array at artifactEditHandlers.test.ts:6-12.

---

## Claims Requiring Attention

### Incorrect
- **Claim 22** — `opfsAdapter.ts:115` comment says "Pass a fresh ArrayBuffer view" but `writeFile` passes the caller's `Uint8Array` directly; no copy or re-view exists. Either add the copy (as `inMemoryCorpusFs.ts:27` does) or delete the comment.

### Stale
- **Claim 8** — `paths.ts:16-19` "The only source of corpus paths is this module": violated by `storeAdapter.ts:55` hand-building `state/${name}.json` (added later in the same range); `state/` is also absent from the documented folder layout.
- **Claim 12** — `storeAdapter.ts:11` references `layout.ts`, renamed to `paths.ts` in 122d70f.
- **Claim 20** — `opfsAdapter.ts:14` points to "workspaceStore.ts:44-46" for the legacy console.warn swallow; that code now lives at `storeAdapter.ts:33-36`, and the cited lines are unrelated validation code.

### Mostly Accurate
- **Claim 2** — flag.ts "DEV-ONLY"/"dev browser": policy only; no dev-mode enforcement exists, and the localStorage gate works in production browsers.
- **Claim 5** — manifest.ts header: codec can only emit kind `"io"`; `"browser-storage-cleared"` is emitted nowhere in the repo.
- **Claim 6** — `parseManifest` "throws on any malformation": non-object source/artifact entries and non-string customTypeIds are silently dropped; `label`/`createdAt`/`updatedAt` silently defaulted; `manifestVersion` never checked against `MANIFEST_VERSION`.
- **Claim 23** — workspaceStore.ts:5 header states debounced rate-limiting unconditionally; the corpus-backed branch writes on every set with no debounce.

### Unverifiable
- **Claim 3** — whether `process.env?.NEXT_PUBLIC_CORPUS_FS` (optional-chained) is actually inlined by Next 16's `NEXT_PUBLIC_*` replacement in client bundles; if not, the env half of the flag silently never activates in the browser. Needs a built-bundle inspection or a non-optional-chained access (`process.env.NEXT_PUBLIC_CORPUS_FS`).

## Goal-Alignment Note
- Answered: All eight briefed claim areas — flag header (Claims 1-4, incl. the NEXT_PUBLIC inlining pattern), manifest codec fail-loud/defaults (5-6), paths single-choke-point invariant checked against actual corpus write paths (7-9), storeAdapter moved-verbatim/debounce-parity diffed against dc6dfb0 (10-14), CorpusErrorKind per-kind production audit (15-17), opfsAdapter error mapping/SSR/invariants (18-22), workspaceStore seam comments (23-25), and all five commit messages with exact static test-count reconstruction (26-28).
- Out of scope: `docs/working/**` claims (used as evidence only, per scope note — including the plan's internal step-6 `opfs-quota-exceeded` vs step-1 naming inconsistency, noted in Claim 26); dynamic verification (running vitest/build) — worktree is read-only for this pass and the brief limited test counts to static; code-quality judgments (e.g., whether the corpus-backed storage *should* debounce — that's for the performance critic).
- Escalate: (a) Claim 2 + Claim 3 jointly: the flag's only *enforced* gate works in production browsers while its build-env gate may be a silent no-op — the reviewer deciding on the "default-off, dev-only" safety story should treat enforcement as localStorage-only; (b) Claim 8's undocumented `state/` path will be replayed by the S2 FSA mirror into user-visible folders if not routed through paths.ts first; (c) Claim 22 becomes load-bearing at S3 when a worker-shared buffer can actually reach `writeFile`.
