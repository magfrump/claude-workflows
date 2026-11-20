Commit: 2dc403e

# Security Review — meta-formalism-copilot dc6dfb0..2dc403e (`app/` only)

**Scope:** `git diff dc6dfb0..2dc403e -- app/` (15 files, +1166/-33). Partial scope: the branch's 13 docs/config files are context only.
**Date:** 2026-11-19
**Based on:** Stage-1 merged code-fact-check report (`corpus/code-fact-check-report.md`, k=3); escalations E3 and E5 are addressed below.
**Threat model:** the reviewed repo has no constraints doc stating one, so every attacker the diff exposes is in scope.

## Trust Boundary Map

```
B1 (new):   [same-origin localStorage key "corpus-fs-enabled" / build env NEXT_PUBLIC_CORPUS_FS] → [isCorpusEnabled() flag.ts:15-25] → [storage-substrate selection, storeAdapter.ts:71-76]
B2 (moved): [persisted blob from OPFS file state/workspace-zustand-v1.json (or localStorage)] → [createJSONStorage parse → merge/coercePersistedState workspaceStore.ts:504-507] → [Zustand workspace state]
B3 (new):   [OPFS substrate (navigator.storage, DOMException failures)] → [opfsAdapter.ts wrap()/isQuota()/isNotFound()] → [typed CorpusError consumed by store/UI]
B4 (new):   [workspace titles / source, artifact, custom-type ids (future S2/S4: FSA folder, git remote)] → [workspaceSlug()/safeSegment()/safeExt() paths.ts:36-64] → [CorpusFS path sink]
B5 (new):   [workspace.json bytes (future: user-chosen FSA folder / git-pulled)] → [parseManifest() manifest.ts:71-111] → [WorkspaceManifest in-memory model]
```

Input-source classification:

```
S1: localStorage "corpus-fs-enabled"   — runtime-mutable (any same-origin script, devtools, user)
                                         — UNTRUSTED for the storage-selection sink; trusted for nothing
S2: NEXT_PUBLIC_CORPUS_FS env           — deploy-time — trusted (all sinks)
S3: OPFS file state/<name>.json bytes   — runtime-mutable (same origin) — UNTRUSTED for deserialize/state-merge sinks
                                         (same trust as the localStorage blob it replaces)
S4: persist `name` "workspace-zustand-v1" — code-constant — trusted (path sink)
S5: workspace title / ids / ext          — request-time (user-typed; S2+ from FSA/git) — UNTRUSTED for the path sink
S6: workspace.json bytes                 — runtime-mutable (S2+: external folder / remote) — UNTRUSTED for deserialize and,
                                         via its ids, the path sink
S7: DOMException names from OPFS         — browser-supplied — trusted for classification only
```

What enters from outside: a runtime toggle (S1) that any same-origin code can set now decides the persistence substrate in production builds; persisted state (S3) still reaches the store through the pre-existing `coercePersistedState` merge, so the deserialization boundary is unchanged in strength. The path builders (B4) and manifest codec (B5) have no production caller yet (fact-check Claim 6), so their boundaries are latent until S2/S4 wires them.

## Findings

#### "Dev-only" corpus flag is enforceable in production via a runtime localStorage key (E3)

**Severity:** Medium
**Location:** `app/lib/corpus/flag.ts:15-25`
**Boundary:** B1
**Move:** 5 (invert the access control model), 1 (runtime-mutable ⇒ compromise-reachable)
**Confidence:** High (mechanism); Medium (impact, which depends on user data in legacy keys)
**Legibility-target:** for-author

Evidence (flag.ts:15-25, whole function):
```ts
export function isCorpusEnabled(): boolean {
  if (typeof process !== "undefined" && process.env?.NEXT_PUBLIC_CORPUS_FS === "1") return true;
  if (typeof window !== "undefined") {
    try {
      return window.localStorage.getItem(CORPUS_FLAG_KEY) === "1";
    } catch {
      return false;
    }
  }
  return false;
}
```

The docstring (`:4-7`) says the flag is "DEFAULT OFF and DEV-ONLY" and "must not be turned on for end users until S4 ships migration", but nothing checks `NODE_ENV` or a build constant: the localStorage branch is live in every production bundle (fact-check Claim 2, 3/3). Anyone who can run one line of same-origin script, or get a user to paste `localStorage.setItem("corpus-fs-enabled","1")` into the console (a common "fix your app" social-engineering lure), switches that user to the OPFS substrate. Their existing work stays in localStorage and vanishes from view. New writes go to a file the legacy code never reads, so switching back loses them as well. Combined with the next finding, every reload can also revert the corpus state to the legacy v2 snapshot. The impact is integrity and availability of the user's work, not disclosure: an XSS attacker can already read localStorage, so the flag adds a persistent data-hiding and data-loss lever, not a read primitive. The floor rule applies: a dev-only flag that can be enforced in production names a concrete mechanism, so this cannot rate below Medium.

**Recommendation:** Gate the runtime branch at build time, for example `if (process.env.NODE_ENV !== "production" && …localStorage…)`, written in the literal non-optional form so Next inlines it and dead-code-eliminates the branch. Alternatively drop the localStorage route and keep only the deploy-time env. Add a test that the production build ignores the key.

#### Env route uses `process.env?.` and may not be inlined by Next (E3, second half)

**Severity:** Informational
**Location:** `app/lib/corpus/flag.ts:16`
**Boundary:** B1
**Move:** 11 (bypass enumeration on the guard)
**Confidence:** Low (unexecuted; fact-check Claim 24 is Unverifiable)
**Legibility-target:** for-orchestrator-synthesis

Evidence (flag.ts:16; excerpt ends :16, enclosing isCorpusEnabled() continues to :25, read in full above):
```ts
  if (typeof process !== "undefined" && process.env?.NEXT_PUBLIC_CORPUS_FS === "1") return true;
```

Next replaces the literal text `process.env.NEXT_PUBLIC_X` at build time. The optional-chain form may escape that replacement. If it does, the client sees no value and the env route silently does nothing in the browser. That fails closed (the flag stays off), so it is not a security hole by itself. It does mean the only route that works in a browser is the runtime localStorage key from the finding above, the one that cannot be controlled. Server-side evaluation can disagree with client-side evaluation, but persist is client-only (`skipHydration`), so no hydration-mismatch sink was found. A `next build` with the env set and a grep of the client chunk would settle it (E6).

**Recommendation:** Write `process.env.NEXT_PUBLIC_CORPUS_FS` without `?.`. The `typeof process` guard is unnecessary once the expression is inlined.

#### Flag-on rehydration can overwrite corpus state with the legacy v2 snapshot on every load

**Severity:** Low
**Location:** `app/lib/stores/workspaceStore.ts:528-543` (with `migrateFromV2` `:251-285`)
**Boundary:** B2
**Move:** 3 (error/alternate path), 4 (check/use on different substrates)
**Confidence:** Medium (traced statically, not executed)
**Legibility-target:** for-author

Evidence (workspaceStore.ts:533-540; excerpt ends :540, enclosing onRehydrateStorage callback continues to :543, read):
```ts
          if (typeof window !== "undefined" && localStorage.getItem(WORKSPACE_KEY)) {
            const zustandRaw = localStorage.getItem("workspace-zustand-v1");
            let hasZustandData = false;
            try { hasZustandData = !!(zustandRaw && JSON.parse(zustandRaw)?.state?.sourceText); }
            catch { /* corrupted localStorage — proceed with migration */ }
            if (!hasZustandData) {
              migrateFromV2();
            }
```

With the flag on, the store hydrates from OPFS, but the "do we already have data?" check still reads the localStorage key. The flag-on path never writes that key. `migrateFromV2` (`:251-285`) does not remove `workspace-v2`. So for a user who has `workspace-v2` and no v1 `sourceText` in localStorage, every reload calls `setState` with the legacy snapshot over the freshly hydrated OPFS state, and persist then writes it back to OPFS. Work done in the corpus mode is silently reverted on each load. Combined with the first finding, an outside party can trigger this. It also contradicts the `flag.ts:5` "starts from an EMPTY corpus" claim (fact-check Claim 12 / E4, which belongs to architecture-review; recorded here for the integrity angle).

**Recommendation:** Make the has-data check read through the selected storage, for example by using the `_state` argument the callback already receives, or skip v2 migration when the corpus flag is on.

#### Corpus-backed persistence: write errors become unhandled rejections, and concurrent un-debounced writes can commit an older state last

**Severity:** Low
**Location:** `app/lib/corpus/storeAdapter.ts:52-68`
**Boundary:** B2, B3
**Move:** 3 (error path), 4 (TOCTOU / ordering), 8 (a million of these)
**Confidence:** Medium (zustand v5 persist internals recalled from its source, not executed here; no `node_modules`)
**Legibility-target:** for-author

Evidence (storeAdapter.ts:52-68, whole function):
```ts
export function createCorpusBackedStorage(fs: CorpusFS): StateStorage {
  const enc = new TextEncoder();
  const dec = new TextDecoder();
  const pathFor = (name: string) => `state/${name}.json`;
  return {
    getItem: async (name) => {
      const bytes = await fs.readFile(pathFor(name));
      return bytes ? dec.decode(bytes) : null;
    },
    setItem: async (name, value) => {
      await fs.writeFile(pathFor(name), enc.encode(value));
    },
    removeItem: async (name) => {
      await fs.rm(pathFor(name));
    },
  };
}
```

Zustand persist calls `setItem` as `void setItem()` after every `set()`. Three consequences follow:
1. The typed `quota-exceeded` CorpusError that the adapter promises to "not swallow" ends as an unhandled promise rejection that no UI sees. That is the same practical outcome as the `console.warn` it replaces.
2. There is no debounce, unlike the localStorage path's 300 ms. Each keystroke runs a full stringify and an OPFS `createWritable`/`close`. Each writable commits on its own `close()`, so overlapping writes can complete out of order, and an older snapshot can be the last one committed (lost update on reload).
3. If `getItem` rejects transiently (for example an OPFS `NoModificationAllowedError` or a `SecurityError` mapped to `io`), hydration fails, the store keeps its defaults, and the next `set()` writes defaults over the stored file.

None of these needs an attacker. They are integrity failures of user data on the substrate this diff introduces, and they stay unexercised because the dev flag is off by default.

**Recommendation:** Serialize writes (a single in-flight promise plus a latest-value slot, or reuse the 300 ms debounce). Surface setItem rejections through a store-level error channel. Refuse to persist until a hydration has succeeded.

#### Quota error masked as `io` when `close()` in the `finally` throws (E5)

**Severity:** Low
**Location:** `app/lib/corpus/opfsAdapter.ts:107-123`
**Boundary:** B3
**Move:** 3 (check the error path)
**Confidence:** Medium (fact-check Claim 16 r1 probe reproduced the masking with a stub; real-browser close() behaviour after a failed write not executed)
**Legibility-target:** for-author

Evidence (opfsAdapter.ts:107-123, whole method):
```ts
    async writeFile(path, bytes) {
      try {
        const root = await getRoot();
        const { dirs, name } = splitPath(path);
        const dir = await walkDir(root, dirs, true);
        const fh = await dir!.getFileHandle(name, { create: true });
        const w = await fh.createWritable();
        try {
          // Pass a fresh ArrayBuffer view; some implementations dislike shared buffers.
          await w.write(bytes);
        } finally {
          await w.close();
        }
      } catch (e) {
        wrap(path, e);
      }
    },
```

When `write()` rejects with `QuotaExceededError`, the stream is errored and `close()` on an errored stream rejects with its own error. An exception thrown in a `finally` replaces the pending one, so `wrap()` sees the close error and produces `{kind:"io"}`, not `quota-exceeded`. The failure-driven UI that DD-009 mandates would then show "I/O error" where it should offer "free space". I found no partial-commit risk: an OPFS writable commits only on a successful `close()`. Security impact is limited to misclassification. No performance-specific hazard was found beyond the un-debounced write volume in the previous finding.

**Recommendation:** On a write failure call `w.abort()` (not `close()`) and rethrow the original error. Call `close()` only on the success path. Add a unit test where both `write` and `close` throw.

#### Slug sanitization is lossy: distinct titles collide on one workspace directory

**Severity:** Low
**Location:** `app/lib/corpus/paths.ts:36-47`
**Boundary:** B4
**Move:** 11 (bypass enumeration)
**Confidence:** High (executed)
**Legibility-target:** for-author

Evidence (paths.ts:36-47, whole function):
```ts
export function workspaceSlug(title: string): string {
  const slug = title
    .normalize("NFKD")
    .replace(SAFE_SEGMENT, "-")
    .replace(/-{2,}/g, "-")
    .replace(/^-+|-+$/g, "")
    .toLowerCase();
  if (!slug) {
    throw new Error(`workspace title produced an empty slug: ${JSON.stringify(title)}`);
  }
  return slug;
}
```

Executed under `node --experimental-strip-types`: `"My WS"`, `"my-ws"` and `"my  ws!"` all map to `my-ws`, and `"x́"` maps to `x`. When S4 creates workspaces by title, a second workspace whose title is crafted or accidentally similar (an imported one, for example) will read and overwrite the first one's folder. Today no production code imports `paths.ts`, so this is latent. That is why it is Low, not Medium: the mechanism is real but has no reachable caller in this diff. `safeSegment` keeps case, so on a case-insensitive FSA mirror (S2, on macOS or Windows) ids differing only in case collide too. Slugs like `con` and `nul` are not reserved-name-checked for a Windows FSA mirror.

**Recommendation:** Key directories by a stable generated id (keep the title in `workspace.json`), or detect collisions at create time and add a suffix. Treat case-folded ids as the uniqueness key.

#### Manifest codec silently drops malformed entries (security angle on E2)

**Severity:** Informational
**Location:** `app/lib/corpus/manifest.ts:86-103`
**Boundary:** B5
**Move:** 7 (serialization boundary)
**Confidence:** High (fact-check Claim 3, executed 3/3)
**Legibility-target:** for-orchestrator-synthesis

Evidence (manifest.ts:86-90; excerpt ends :90, enclosing parseManifest() continues to :111, read):
```ts
  const sources: SourceRef[] = Array.isArray(raw.sources)
    ? raw.sources.filter(isObject).map((s) => {
        if (typeof s.id !== "string" || typeof s.ext !== "string") fail("source entry missing id/ext");
        return { id: s.id, label: typeof s.label === "string" ? s.label : s.id, ext: s.ext };
      })
```

Shape checking is real: the parser builds a new object field by field, and `__proto__` keys from `JSON.parse` stay own properties and are not copied. No prototype-pollution path was found. Ids and ext reach paths only through `safeSegment`/`safeExt`. The lossy filtering (non-object entries and non-string `customTypeIds` dropped, `manifestVersion` unchecked) belongs to api-consistency and test-strategy (E2). The security note is for S2/S3: once `workspace.json` comes from a user-picked folder or a git pull (S6, untrusted), silent filtering lets a tampered manifest hide sources or artifacts without any error. The design's fail-loud contract is the right guard and should be made true before that wiring lands.

**Recommendation:** Reject (not filter) malformed entries, and check `manifestVersion === MANIFEST_VERSION`, before any S2/S3 caller exists.

### Untested bypass candidates

- `flag.ts:16` env route: whether Next inlines `process.env?.NEXT_PUBLIC_CORPUS_FS` in the client chunk. Not tested because there is no `node_modules` or `next build` (E6).
- `opfsAdapter.ts` `getDirectoryHandle("..")` / names with `\` in real OPFS: the adapter does no segment validation of its own, so any future caller that hand-builds paths (as `storeAdapter.ts:55` already does with a constant) depends on the browser rejecting such names. Not tested because there is no real OPFS here.
- Two tabs with the flag on writing the same OPFS file: last-close-wins ordering across tabs. Not tested; needs a real browser.

Because of these candidates, the flag guard and the adapter's path handling are not endorsed below.

## Endorsement Claims

- **Claim:** `workspaceSlug` and `safeSegment` output only `[a-z0-9_-]` (respectively `[A-Za-z0-9_-]`), throw on empty results, and so a `..`, `/`, `\`, fullwidth-dot/slash or NUL-bearing title or id yields no traversal segment in the built path.
  **Location:** `app/lib/corpus/paths.ts:28-58`
  **Evidence:** executed
  **Verified:** ran `workspaceSlug` on `..`, `../x`, `．．／x`, `%2e%2e%2fx`, `a\..\b`, `\u0000..`, `‮..`; ran `sourcePath("s","../../a","../sh")` → `workspaces/s/sources/a.sh`; `artifactDir("s","..")` throws.
  **Not verified:** that every future S2/S4 caller routes through these builders (today `storeAdapter.ts:55` hand-builds `state/${name}.json` from a code constant).
  **route: code-fact-check**

- **Claim:** The corpus-backed path passes persisted state through the same `merge` → `coercePersistedState` validation as the localStorage path, because `createJSONStorage(resolveWorkspaceStorage)` is the only storage wired and `merge` is substrate-agnostic.
  **Location:** `app/lib/stores/workspaceStore.ts:499-507`
  **Evidence:** read-static
  **Verified:** read the persist options block `:493-545` and `coercePersistedState` `:66-120`.
  **Not verified:** zustand v5 `createJSONStorage` behaviour on an async `getItem` returning a non-JSON string (the parse-error path into `onRehydrateStorage`).
  **route: code-fact-check**

- **Claim:** `opfsAdapter.ts` `getRoot()` throws a typed `{kind:"unavailable"}` CorpusError when `navigator.storage.getDirectory` is absent, and every method's outer `catch` passes it through `wrap()` unchanged.
  **Location:** `app/lib/corpus/opfsAdapter.ts:49-55,79-83`
  **Evidence:** read-static (fact-check Claim 15 executed this with a stub)
  **Verified:** read `getRoot`, `wrap`, and all five methods `:85-176`.
  **Not verified:** a present-but-throwing `getDirectory()` (for example a Firefox private-mode `SecurityError`), which maps to `io`, not `unavailable`.
  **route: code-fact-check**

## Primitive sweep

Primitive: path construction (filesystem path join, CorpusFS path sink)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `app/lib/corpus/storeAdapter.ts:55` `state/${name}.json` | S4 persist name | none (code-constant) | cleared, constant `"workspace-zustand-v1"` |
| `app/lib/corpus/paths.ts:70-71` `workspaceDir` | S5 title/slug | `workspaceSlug` | cleared for traversal; collision is the slug-collision finding above |
| `app/lib/corpus/paths.ts:78-79` `sourcePath` | S5/S6 id, ext | `safeSegment`, `safeExt` | cleared (executed) |
| `app/lib/corpus/paths.ts:82-83` `artifactDir` (and `artifactVersionPath`, `artifactMetaPath`) | S5/S6 artifact type | `safeSegment` (+ integer check) | cleared |
| `app/lib/corpus/paths.ts:100-101` `customTypePath` | S5/S6 custom-type id | `safeSegment` | cleared |
| `app/lib/corpus/paths.ts:104-109` `decompositionDir` / `decompositionGraphLayoutPath` | S5 slug | `workspaceSlug` | cleared |
| `app/lib/corpus/opfsAdapter.ts:57-62,128` `splitPath` / readdir split | caller path | none (relies on browser name validation) | not analyzed in a real OPFS; listed under Untested bypass candidates |
| `app/lib/corpus/__tests__/inMemoryCorpusFs.ts:144-146` `normalize` | test-only | n/a | cleared, test fixture |

Primitive: deserialization (`JSON.parse` of persisted data)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| zustand `createJSONStorage` over `storeAdapter.ts:57-60` getItem | S3 OPFS blob | `merge` → `coercePersistedState` | cleared (endorsement claim 2, routed) |
| `app/lib/corpus/manifest.ts:76` `parseManifest` | S6 manifest bytes | field-by-field rebuild | the manifest-codec finding above (lossy, no pollution) |
| `app/lib/stores/workspaceStore.ts:536` `JSON.parse(zustandRaw)` | localStorage v1 key | try/catch | the rehydration finding above (wrong substrate under flag) |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Dev-only flag enforceable in production via localStorage | Medium | B1 | `app/lib/corpus/flag.ts:15-25` | High |
| 2 | Flag-on rehydrate re-runs migrateFromV2 over corpus state | Low | B2 | `app/lib/stores/workspaceStore.ts:528-543` | Medium |
| 3 | Unhandled write rejections, unordered un-debounced writes, defaults-over-file after failed hydrate | Low | B2, B3 | `app/lib/corpus/storeAdapter.ts:52-68` | Medium |
| 4 | close() in finally masks quota as io | Low | B3 | `app/lib/corpus/opfsAdapter.ts:107-123` | Medium |
| 5 | Lossy slug: distinct titles share a directory | Low | B4 | `app/lib/corpus/paths.ts:36-47` | High |
| 6 | Env route `process.env?.` may not inline | Informational | B1 | `app/lib/corpus/flag.ts:16` | Low |
| 7 | Manifest codec filters, does not fail (S2/S3 tamper angle) | Informational | B5 | `app/lib/corpus/manifest.ts:86-103` | High |

## Overall Assessment

The change adds no injection, authentication or crypto surface, and the traversal guard in the path builders holds against the bypasses I tried (run, not just read). The main issue is #1. A flag documented as dev-only and "must not be turned on for end users" can be switched on in production by any same-origin script or a pasted console line. Together with #2 and #3, that becomes silent loss of the user's work. The fix is small (a build-time `NODE_ENV` gate on the runtime branch) and should land before merge. #2 to #5 are integrity defects of the new substrate that the default-off flag keeps dormant. Fix them before the flag is ever enabled for anyone, not necessarily in this PR. No findings within the code paths read rise above Medium. The endorsement claims are pending execution verification, apart from the executed slug claim, which is still routed.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to the output path below, with `Commit: 2dc403e` as its first line, structured per the security-reviewer skill.
- Answered: yes
- Out of scope: the 13 non-`app/` branch files (context only). E2 and E4 correctness aspects belong to api-consistency, test-strategy and architecture, and are noted here only for their integrity angle.
- Escalate: (1) E6 — a provisioned `next build` with `NEXT_PUBLIC_CORPUS_FS=1`, to check whether `process.env?.` is inlined in the client chunk, plus a real-browser check of `close()` after a quota `write()` failure (E5 verdict confidence). (2) Finding 2 overlaps E4. Merge it with architecture-review's disposition so it is not double-counted.
- Decisions I made: rated #1 Medium under the floor rule even though the impact is integrity/availability only (XSS already reads localStorage). Rated #5 Low, not Medium, because no production caller of `paths.ts` exists in this diff. No HALT block: no escalation pattern matched.
