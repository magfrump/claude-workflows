# Performance Review — corpus-dirty (dc6dfb0..2dc403e, app/ only)

**Scope:** `git diff dc6dfb0..2dc403e -- app/` — the DD-009 corpus S0/S1 layer (`app/lib/corpus/**`) plus the `workspaceStore.ts` storage-seam extraction. `docs/working/**` is context, not under review. Commits outside the range are context only.
**Date:** 2026-08-06
**Based on:** merged code-fact-check (k=3), treated as foundation — documented behavior is not re-verified.
**Commit:** 2dc403e

---

### Data Flow and Hot Paths

The write path under review is a single chain, and everything in this report hangs off it:

```
<textarea onChange>                      app/components/features/source-input/TextInput.tsx:17
  → onSourceTextChange                   app/page.tsx:814
  → setSourceText: (v) => set({...})     app/lib/stores/workspaceStore.ts:321
  → zustand persist subscriber (per set)
      → partialize(state)                app/lib/stores/workspaceStore.ts:511-527
      → createJSONStorage.setItem        app/lib/stores/workspaceStore.ts:496
          → JSON.stringify(whole blob)
          → StateStorage.setItem         app/lib/corpus/storeAdapter.ts:29 (localStorage branch)
                                      or app/lib/corpus/storeAdapter.ts:61 (corpus branch)
```

**Temperature calls used throughout this report:**

- **HOT — `set` → `partialize` → `JSON.stringify`.** Confirmed per-keystroke: `TextInput.tsx:17` calls `onChange` on every `input` event, which is bound to `setSourceText` at `page.tsx:814`, which is `set({ sourceText: v })`. The same holds for `contextText` (`page.tsx:818`) and `semiformalText`. The store's own comment at `workspaceStore.ts:510` — "save the allocation on every set() call" — is in-repo confirmation that the authors understand `partialize` runs per `set`.
- **HOT — the `localStorage` branch** (`storeAdapter.ts:25-46`). This is the default for every user (`flag.ts:15-25` is default-off), so its per-`set` cost is the cost every user pays.
- **COLD (today) — the corpus/OPFS branch** (`storeAdapter.ts:52-68`, `opfsAdapter.ts:85-176`). Reached only when `NEXT_PUBLIC_CORPUS_FS=1` or the dev sets `localStorage["corpus-fs-enabled"]="1"` (`flag.ts:13-25`). Per the merged fact-check, this branch is dev-opt-in today. **But S4 intends to make it the default**, at which point every corpus finding below re-tempers to HOT and its severity escalates one tier. Each corpus finding states its escalated severity explicitly.
- **WARM — hydration** (`page.tsx:83`, `persist.rehydrate()`): once per page load.
- **COLD — `manifest.ts`, `paths.ts`.** Built in S0 but, per `storeAdapter.ts:10-12`, "not used by the store until S4." No live caller in this range.

The single structural fact that generates most of this report: **the persist blob is one whole-workspace JSON document**, so every write is O(total workspace bytes) regardless of how small the edit was, and there is no per-artifact granularity to write instead.

---

### Findings

#### F1 — `partialize` + `JSON.stringify` of the whole workspace run on every keystroke, outside the 300ms debounce

**Severity:** High
**Location:** `app/lib/corpus/storeAdapter.ts:20-46` (the moved debounce), `app/lib/stores/workspaceStore.ts:496` (`createJSONStorage(resolveWorkspaceStorage)`), `app/lib/stores/workspaceStore.ts:511-527` (`partialize`)
**Move:** (6) serialization tax — where the debounce boundary sits relative to the serialization work.
**Classification:** Macro / Hot — confirmed hot path: `TextInput.tsx:17` → `page.tsx:814` → `workspaceStore.ts:321` `set(...)`, one `set` per keystroke, on the default (flag-off) storage branch every user gets.
**Confidence:** Medium-High. The per-`set` `partialize` call is confirmed in-repo by the store's own comment (`workspaceStore.ts:510`). The claim that `createJSONStorage` stringifies *before* delegating to `StateStorage.setItem` is a zustand-v5 internals claim I could not verify in this worktree — `node_modules/` is not present at 2dc403e's checkout, and `package.json:33` only pins `"zustand": "^5.0.13"`. Verifying it is a one-line read of `zustand/middleware` `createJSONStorage`.
**Baseline:** no baseline available — flagged as speculative. No profile, no measured serialize time, no measured workspace-blob size distribution exists in the repo.
**Evidence:** verbatim, `storeAdapter.ts:20-24`:
> `// Default: debounced localStorage (moved verbatim from workspaceStore.ts so the`
> `// OFF path is byte-for-byte the prior behavior — see the characterization test).`
> `// Reads are synchronous (instant); writes are debounced by 300ms.`

and the claim this comment inherited, verbatim from the deleted block in `workspaceStore.ts` (visible in the diff):
> `// Debounced localStorage adapter — avoids JSON.stringify on every keystroke.`

**Legibility-target:** a future reader who reads "avoids JSON.stringify on every keystroke" and concludes the serialization tax is bounded at ~3.3/sec, when the debounce only defers the `localStorage.setItem` syscall and not the stringify that produced its argument.

The debounce at `storeAdapter.ts:31-38` wraps only `localStorage.setItem`. Everything upstream of it — `partialize` (which shallow-copies twelve fields and calls `sanitizeVerificationStatus` and `sanitizeDecomposition`) and the `JSON.stringify` of the resulting object — runs unconditionally once per `set`. The scaling factor is therefore *keystrokes × total persisted workspace bytes* on the main thread, not *debounce ticks × bytes*: a user typing at 8 chars/sec into a workspace whose persisted blob is B bytes does ~8·O(B) serialization work per second, and B grows monotonically as artifacts, versions, and decomposition nodes accumulate. The `sanitizeDecomposition` memo at `workspaceStore.ts:292-308` is a targeted fix for exactly this class of problem, which shows the cost was recognized for one field but not for the whole-blob stringify. This finding is pre-existing behavior that the diff *relocated* rather than introduced; it is in scope because the diff moved both the code and the claim into a new file, and the move is the moment to correct the comment.
**Recommendation:** Move the debounce boundary above the serializer rather than below it — debounce at the `persist` level (e.g. a custom `storage` whose `setItem` accepts the already-partialized object and defers both stringify and write), or accept the current behavior and fix the comment to say "defers the localStorage write by 300ms; the JSON.stringify still runs per set." Do not leave the comment as-is; it is the load-bearing claim a future perf investigation will start from. Before optimizing, measure: instrument `JSON.stringify` duration and blob size on a realistically-full workspace, since the fix is only worth doing if B is large.

---

#### F2 — Corpus branch writes the full blob to OPFS on every `set` with no debounce at all

**Severity:** Medium (escalates to **High** the moment S4 makes the corpus branch the default)
**Location:** `app/lib/corpus/storeAdapter.ts:61-63`
**Move:** (1) hidden multiplications — per-`set` writes; (6) serialization tax, asymmetric between the two branches of one seam.
**Classification:** Macro / Cold (evidence: reachable only via `flag.ts:15-25`, which requires `NEXT_PUBLIC_CORPUS_FS=1` or a manually-set `localStorage["corpus-fs-enabled"]`; merged fact-check confirms dev-opt-in-only today)
**Confidence:** High — this is direct from the merged fact-check, which records that the corpus-backed branch writes on every `set` with NO debounce while the localStorage branch keeps the 300ms debounce.
**Baseline:** no baseline available — flagged as speculative. No OPFS write-latency measurement exists in the repo; the OPFS success path isn't even covered by Vitest (`CLAUDE.md`: "jsdom has no OPFS", verified via an out-of-CI Playwright smoke).
**Evidence:** verbatim, `storeAdapter.ts:61-63`:
> `    setItem: async (name, value) => {`
> `      await fs.writeFile(pathFor(name), enc.encode(value));`
> `    },`

**Legibility-target:** a developer who reads `resolveWorkspaceStorage` (`storeAdapter.ts:71-76`) as "same storage semantics, different substrate" and does not notice that flipping the flag also removes the write-rate limiter — the two branches differ on debounce, and nothing in the seam's type or docstring says so.

Where the localStorage branch collapses a burst of keystrokes into one write per 300ms idle window, the corpus branch issues one full OPFS write per `set`. The multiplication is *keystrokes × (TextEncoder.encode(B) + a five-step OPFS handle dance + a writable-stream commit)*, against *≈3.3 writes/sec × the same* for the default branch — roughly a 2-3× rate increase at typing speed, on a substrate whose per-write cost is materially higher than `localStorage.setItem` because `createWritable`/`close` commits through a swap file. The severity is held at Medium only by the flag: the path is genuinely cold today. At S4 the same code becomes the every-user keystroke path and this is the first thing that will show up in a profile.
**Recommendation:** Give the corpus branch a debounce (or, better, a coalescing single-flight writer — see F3) before S4 flips the default, and make the seam's contract state the write-rate guarantee so both implementations are held to it. This is cheap to do now and expensive to retrofit under a regression report later.

---

#### F3 — No write serialization: concurrent async `setItem` calls race on the same OPFS file

**Severity:** Medium (escalates to **High** at S4)
**Location:** `app/lib/corpus/storeAdapter.ts:56-67`, `app/lib/corpus/opfsAdapter.ts:107-123`
**Move:** (7) contention; (4) memory/resource lifecycle — a writable stream is opened and committed per call with no mutual exclusion.
**Classification:** Macro / Cold (evidence: same flag gate as F2)
**Confidence:** Medium-High on the mechanism (the code plainly has no queue); Medium on the concrete OPFS failure mode, which is browser-implementation-dependent and untested here.
**Baseline:** no baseline available — flagged as speculative.
**Evidence:** verbatim, `opfsAdapter.ts:112-119`:
> `        const fh = await dir!.getFileHandle(name, { create: true });`
> `        const w = await fh.createWritable();`
> `        try {`
> `          // Pass a fresh ArrayBuffer view; some implementations dislike shared buffers.`
> `          await w.write(bytes);`
> `        } finally {`
> `          await w.close();`
> `        }`

**Legibility-target:** a reader who sees `await` on every line and infers the writes are therefore ordered. They are ordered *within* one call; nothing orders one call against the next, because `setItem` returns a promise that the persist subscriber fires and forgets.

Combined with F2's un-debounced firing, keystroke N+1's `setItem` starts while keystroke N's writable stream is still open on the same path. Two effects follow, and both scale with typing speed × blob size (the bigger B is, the longer each write stays in flight and the more overlap there is): first, wasted throughput — several full-blob writes to the same file are in flight where only the last one's content matters; second, an ordering hazard, since which payload wins is decided by `close()` completion order, not by call order, so a stale blob can commit last. Some OPFS implementations will additionally reject the second `createWritable` on a locked file, which under this code surfaces as a `CorpusError{kind:"io"}` from `wrap` (`opfsAdapter.ts:79-83`) — a persist failure, not a slow persist.
**Recommendation:** Put a single-flight coalescing writer in front of `CorpusFS.writeFile` in `createCorpusBackedStorage`: keep at most one write in flight per path and one pending payload, dropping superseded payloads. That fixes F2 and F3 together and is the natural place for the S3 worker proxy to inherit the same guarantee.

---

#### F4 — Whole-blob storage: every write is O(entire workspace), and there is no partial-write path

**Severity:** Medium
**Location:** `app/lib/corpus/storeAdapter.ts:9-12` and `:52-68`; read side `app/lib/corpus/opfsAdapter.ts:100-101`
**Move:** (2) size of N; (9) asymptotics; (4) memory lifecycle on the read side.
**Classification:** Macro / Cold for the corpus branch as shipped; the identical asymptotic applies to the Hot default branch via F1.
**Confidence:** High — stated outright by the module docstring.
**Baseline:** no baseline available — flagged as speculative. Nothing in the repo bounds workspace blob size: `partialize` (`workspaceStore.ts:511-527`) persists `sourceText`, `extractedFiles`, `contextText`, `semiformalText`, `leanCode`, `artifacts`, the full `decomposition` node graph, `customArtifactTypes`, and `customArtifactData`, and `sourceText` can be the extracted text of an uploaded PDF.
**Evidence:** verbatim, `storeAdapter.ts:10-12`:
> ` * In S1 the persist blob is stored as a SINGLE file via CorpusFS (blob mode) —`
> ` * the files-per-artifact folder layout (layout.ts/manifest.ts) is built but not`
> ` * used by the store until S4. This keeps S1 a pure substrate swap.`

**Legibility-target:** a reader deciding whether S1 is "just a substrate swap" for perf purposes as well as for behavior. It is for behavior; it is not for cost, because OPFS's per-write fixed cost is higher than localStorage's while the payload stayed whole-blob.

Editing one character of `leanCode` rewrites every persisted byte of every artifact, every decomposition node, and the full source text. The scaling factor is (bytes written per edit) = (total workspace size), so cost grows with *accumulated work* rather than with *edit size* — the users with the most to lose are the ones who pay the most per keystroke. On the read side, hydration materializes the blob three times concurrently: the `Uint8Array` view over the file's `ArrayBuffer` (`opfsAdapter.ts:101`), the decoded string (`storeAdapter.ts:59`), and the parsed object graph — a ~3×B peak at page load. The folder layout in `paths.ts` exists precisely to fix this, which makes this a deliberate, documented S1 deferral rather than an oversight; it is reported here so the cost is on the record when S4 scopes.
**Recommendation:** No action in S1 — the deferral is reasoned. Do capture, as an S4 acceptance criterion, that per-artifact writes replace whole-blob writes, and take a blob-size measurement on a real workspace now so S4 has a before-number to beat.

---

#### F5 — `CorpusFS` has no batch or recursive operation, so S4's folder layout costs one round trip per file

**Severity:** Medium
**Location:** `app/lib/corpus/types.ts:112-125`
**Move:** (1) hidden multiplications / N+1; (3) work in the wrong place — the per-file loop will live above the seam where it cannot be batched by the adapter.
**Classification:** Macro / Cold (evidence: no consumer of the folder layout exists in this range; `storeAdapter.ts:10-12` confirms it's unused until S4)
**Confidence:** Medium — this is a forward-looking judgment about a shape the interface locks in, not a measured cost of shipped code.
**Baseline:** no baseline available — flagged as speculative.
**Evidence:** verbatim, `types.ts:115-124`:
> `  readFile(path: string): Promise<Uint8Array | null>;`
> `  writeFile(path: string, bytes: Uint8Array): Promise<void>;`
> `  readdir(path: string): Promise<string[]>;`
> `  rm(path: string): Promise<void>;`
> `  stat(path: string): Promise<CorpusStat | null>;`

**Legibility-target:** the S4 author, who will write `for (const name of await fs.readdir(dir)) await fs.readFile(...)` because that is the only shape the interface offers, and will not see that this is the classic N+1 until it is a UI stall.

Opening a workspace under the `paths.ts` layout means: read `workspace.json`, then `readdir` `artifacts/`, then per artifact type a `readdir` plus a `readFile` of the current version plus a `readFile` of `meta.json`, then `readdir` + `readFile` per source and per custom type. That is O(number of artifact types + sources + custom types) sequential awaits where a batch API would be O(1) calls; with per-call overhead as measured in F6 (five handle resolutions each), the constant is not small. Because this is an *interface* decision, it is much cheaper to fix now than after S2/S3/S4 have all bound to it — and `types.ts:19-22` shows the authors are already thinking about which methods belong on this interface versus a sibling one.
**Recommendation:** Consider adding a batch read (`readFiles(paths: string[]): Promise<(Uint8Array|null)[]>`) or a recursive listing to `CorpusFS` now, so the OPFS adapter can parallelize internally and the S3 worker proxy can turn a workspace-open into one `postMessage` instead of N. If it is deliberately deferred, say so in the docstring next to the existing "GIT IS NOT PART OF THIS INTERFACE" note, which is exactly the right precedent for recording interface-scope decisions.

---

#### F6 — Every OPFS operation re-acquires the root handle and re-walks the full path; no handle cache

**Severity:** Informational (escalates to **Medium** at S4, when the per-op constant multiplies by file count)
**Location:** `app/lib/corpus/opfsAdapter.ts:49-55` (`getRoot`), `:66-77` (`walkDir`), called from all five methods at `:89, :109, :127, :141, :158`
**Move:** (5) storage access patterns — OPFS handle churn per op; (8) caches — the obvious cache is absent.
**Classification:** Micro / Cold (evidence: flag-gated, and in S1 the only path is `state/<name>.json`, i.e. one directory segment)
**Confidence:** High on the mechanism; the impact estimate is speculative.
**Baseline:** no baseline available — flagged as speculative.
**Evidence:** verbatim, `opfsAdapter.ts:49-55`:
> `async function getRoot(): Promise<OpfsDirHandle> {`
> `  const storage = typeof navigator !== "undefined" ? navigator.storage : undefined;`
> `  if (!storage || typeof storage.getDirectory !== "function") {`
> `    throw new CorpusError({ kind: "unavailable", reason: "navigator.storage.getDirectory is not available (SSR or unsupported browser)" });`
> `  }`
> `  return (await storage.getDirectory()) as unknown as OpfsDirHandle;`
> `}`

**Legibility-target:** a reader who counts the awaits. One S1 `writeFile` is five async round trips — `getDirectory`, `getDirectoryHandle("state", {create:true})`, `getFileHandle(create:true)`, `createWritable`, `close` — where a cached root and a cached directory handle would make it three.

The scaling factor is (operations) × (1 + path depth) handle resolutions. In S1 that is a small constant on a cold path, which is why this is Informational. Under the `paths.ts` layout the paths are four segments deep (`workspaces/<slug>/artifacts/<type>/v0001.md`), so writing M artifact files re-resolves the same three intermediate directories M times — 5M resolutions where a cached walk would be ~M+4. Note the `create: true` walk in `writeFile` (`opfsAdapter.ts:111`) pays this even when every directory already exists.
**Recommendation:** Cache the root handle in a module-level promise (it is stable for the origin's lifetime) and consider a small directory-handle map keyed by path prefix, invalidated on `rm`. Worth doing as part of S4's per-file layout work rather than now — the S1 payoff is a couple of round trips on a dev-only path.

---

#### F7 — `readdir` materializes and sorts every entry with no streaming or pagination

**Severity:** Informational
**Location:** `app/lib/corpus/opfsAdapter.ts:125-137`
**Move:** (2) size of N — the entry count is unbounded by the interface.
**Classification:** Micro / Cold (evidence: no caller in this range; flag-gated)
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative.
**Evidence:** verbatim, `opfsAdapter.ts:131-133`:
> `        const names: string[] = [];`
> `        for await (const key of dir.keys()) names.push(key);`
> `        return names.sort();`

**Legibility-target:** an S4 author listing `artifacts/<type>/` after a long editing session, where the entry count is one file per saved version and grows without bound.

Cost is O(k) allocations plus O(k log k) comparisons per call, k = entries in the directory. For settings, sources, and custom types k is small by construction. For versioned artifact directories k grows monotonically with edit history and the interface offers no way to ask for just the latest — which is why `manifest.ts:20-25` keeps a `currentVersion` pointer, so the common case never needs this call at all. The sort is a deliberate determinism choice and worth keeping.
**Recommendation:** No change. If version-directory listing ever becomes a hot call, use the manifest pointer instead of `readdir`, as `manifest.ts:6-8` already intends.

---

#### F8 — `serializeManifest` pretty-prints, inflating every manifest write

**Severity:** Informational
**Location:** `app/lib/corpus/manifest.ts:56-58`
**Move:** (6) serialization tax.
**Classification:** Micro / Cold (evidence: no caller in this range)
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative.
**Evidence:** verbatim, `manifest.ts:56-58`:
> `export function serializeManifest(m: WorkspaceManifest): Uint8Array {`
> `  return new TextEncoder().encode(JSON.stringify(m, null, 2));`
> `}`

**Legibility-target:** nobody is likely to be misled here; this is recorded for completeness because manifest writes will eventually be per-edit.

`null, 2` costs extra CPU in `stringify` and inflates the encoded byte count by roughly the indentation depth × line count — for a manifest with S sources plus A artifact pointers plus C custom-type ids, that is O(S+A+C) extra bytes written per manifest update. The scaling factor is small and the readability payoff is real: DD-009 puts this file in a git-tracked folder, where a pretty-printed manifest produces line-level diffs instead of one enormous changed line. That tradeoff is worth the bytes.
**Recommendation:** Keep it. The git-diff legibility is the right call for a file destined for version control.

---

#### F9 — `paths.ts` builders re-sanitize the slug on every call, with no memoization

**Severity:** Informational
**Location:** `app/lib/corpus/paths.ts:36-47` (`workspaceSlug`), `:70-72` (`workspaceDir`), `:82-98` (chained builders)
**Move:** (1) hidden multiplications; (8) caches.
**Classification:** Micro / Cold (evidence: no caller in this range)
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative.
**Evidence:** verbatim, `paths.ts:37-42`:
> `  const slug = title`
> `    .normalize("NFKD")`
> `    .replace(SAFE_SEGMENT, "-")`
> `    .replace(/-{2,}/g, "-")`
> `    .replace(/^-+|-+$/g, "")`
> `    .toLowerCase();`

**Legibility-target:** an S4 author building N artifact paths in a loop, who will not notice that `artifactVersionPath` → `artifactDir` → `workspaceDir` → `workspaceSlug` re-runs a Unicode NFKD normalization and four regex passes over the title on each of the N calls.

Per-call cost is O(title length) with a non-trivial constant (NFKD normalization is not cheap), multiplied by the number of path builds — so a workspace-open that constructs paths for M artifacts pays M normalizations of the same string to produce the same answer. The absolute numbers are tiny; the reason to note it is that the fix is trivial (a `Map<string,string>` memo, or hoisting the slug to the call site) and the sanitization is also the security choke point per `paths.ts:16-19`, so it must not be bypassed by hand-concatenation as a "faster" workaround.
**Recommendation:** If S4 builds paths in loops, compute the slug once and thread it through, or add a small memo inside `workspaceSlug` — never hand-concatenate to avoid the cost, since this function is the traversal guard.

---

#### F10 — `parseManifest` traverses `sources`/`artifacts` twice and reallocates every entry

**Severity:** Informational
**Location:** `app/lib/corpus/manifest.ts:86-104`
**Move:** (9) asymptotics — checked and found fine; recorded so a later reader does not have to re-derive it.
**Classification:** Micro / Cold (evidence: no caller in this range; parse happens at most once per workspace open)
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative.
**Evidence:** verbatim, `manifest.ts:86-88`:
> `  const sources: SourceRef[] = Array.isArray(raw.sources)`
> `    ? raw.sources.filter(isObject).map((s) => {`
> `        if (typeof s.id !== "string" || typeof s.ext !== "string") fail("source entry missing id/ext");`

**Legibility-target:** a reader auditing manifest parse cost, who should be able to stop here.

`filter(...).map(...)` is two passes plus two intermediate arrays over S sources and A artifact pointers, and each surviving entry is rebuilt as a fresh object. This is O(S+A) either way — a single `reduce` would halve the constant and save one array allocation. At one parse per workspace open with S and A in the tens, this is not worth changing; the two-pass form is meaningfully clearer, and clarity is the right trade on a fail-loud validation path.
**Recommendation:** No change.

---

### What Looks Good

- **`sanitizeDecomposition` memoization** (`workspaceStore.ts:288-308`): a reference-equality cache that skips re-mapping every decomposition node when an unrelated field changed. This is precisely the right instinct for a per-`set` code path, and the comment states the reason.
- **`partialize` avoids a defensive `.map()`** (`workspaceStore.ts:508-510`): the comment explains that non-serializable `File` references are dropped by `JSON.stringify` anyway, so the allocation is skipped — an intentional, documented per-`set` allocation saving.
- **`TextEncoder`/`TextDecoder` hoisted per adapter instance** (`storeAdapter.ts:53-54`): constructed once at storage creation, not per `setItem`. Contrast `manifest.ts:57` and `:78`, which construct them per call — fine there, since those are cold.
- **Storage resolved once** (`storeAdapter.ts:70-71`, `workspaceStore.ts:496`): `resolveWorkspaceStorage` runs at persist-middleware init, so neither the flag read (`flag.ts:19`, a synchronous `localStorage.getItem`) nor the adapter construction is on the per-`set` path.
- **`manifest.ts` keeps a `currentVersion` pointer** (`manifest.ts:20-25`, docstring `:6-8`): explicitly so "a consumer can open a workspace without scanning every file." That is the O(1)-instead-of-O(versions) design and it is the right one.
- **`walkDir` short-circuits on missing directories when `create` is false** (`opfsAdapter.ts:72`): read paths return `null`/`[]` without continuing to resolve deeper segments.
- **Async-everywhere interface** (`types.ts:13-16`): committing to async now means the S3 worker move is a transport swap, not an interface break — which keeps the eventual "get serialization off the main thread" fix cheap.

---

### Summary Table

| ID | Finding | Severity | Class | Temp | Confidence |
|----|---------|----------|-------|------|------------|
| F1 | `partialize` + `JSON.stringify` per keystroke, outside the debounce | High | Macro | Hot | Medium-High |
| F2 | Corpus branch writes full blob per `set`, no debounce | Medium (→High at S4) | Macro | Cold | High |
| F3 | No write serialization; concurrent OPFS writes race | Medium (→High at S4) | Macro | Cold | Medium-High |
| F4 | Whole-blob persistence: write cost = total workspace size | Medium | Macro | Cold | High |
| F5 | `CorpusFS` lacks batch ops → N+1 at S4 workspace open | Medium | Macro | Cold | Medium |
| F6 | Root handle + path re-walked every OPFS op | Informational (→Medium at S4) | Micro | Cold | High |
| F7 | `readdir` materializes + sorts all entries | Informational | Micro | Cold | High |
| F8 | `serializeManifest` pretty-prints | Informational | Micro | Cold | High |
| F9 | `paths.ts` re-sanitizes slug per builder call | Informational | Micro | Cold | High |
| F10 | `parseManifest` double-traverses entry arrays | Informational | Micro | Cold | High |

---

### Overall Assessment

For a substrate-seam extraction, this is careful work: the `CorpusFS` interface is async from the start (so the eventual worker move is free), the manifest carries a current-version pointer (so workspace-open is O(1) rather than O(versions)), and the store already has two deliberate per-`set` allocation optimizations with comments explaining them. The S1 deferrals — blob-mode persistence, unused folder layout — are documented as deferrals rather than hidden.

The one finding that touches shipping users is **F1**, and it is a comment-versus-code mismatch on the default path rather than a regression: the moved-verbatim debounce defers the `localStorage` write but not the `partialize`+`stringify` that produced its argument, so "avoids JSON.stringify on every keystroke" overstates what the 300ms window buys. It is pre-existing, but the diff relocated both the code and the claim, which makes this the moment to correct it. It needs a measurement before it needs a fix.

Everything else is cold today and held cold by one thing: `flag.ts` is default-off. **F2, F3, and F6 all re-temper to hot the day S4 flips that default**, and F2 in particular means the flip silently removes the write-rate limiter that the localStorage branch has always had. The asymmetry is invisible at the seam — `resolveWorkspaceStorage` presents two `StateStorage` values that differ in write-rate guarantee with nothing in the type or docstring saying so. A single-flight coalescing writer in `createCorpusBackedStorage` resolves F2 and F3 together, is small while the path is cold, and gives the S3 worker proxy the same guarantee for free. That is the one change I would make before S4 rather than during it.

No finding here justifies blocking this range.

## Goal-Alignment Note
- Answered: Performance review of `dc6dfb0..2dc403e` restricted to `app/`, all severities down to Informational, per the measurement-run brief (pass 1, no fix loop). Every finding states Macro/Micro, Hot/Cold with the evidence for the temperature call, and carries an explicit baseline line; where no measurement exists, the literal speculative flag is used. Hot-path gate respected: the single High is on a path confirmed hot by tracing `TextInput.tsx:17` → `page.tsx:814` → `workspaceStore.ts:321`, and no Critical is claimed since no Macro×Hot finding is unbounded.
- Out of scope: correctness, security, API design, and test coverage of the corpus layer (F3's lost-update hazard is noted only for its throughput cost; its data-integrity dimension belongs to another critic). `docs/working/**` treated as context. Behavior documented by the merged k=3 fact-check was taken as foundation and not re-verified. No fixes applied — this is a measurement run.
- Escalate: (1) **F1's zustand-internals claim is unverified** — `node_modules/` is absent at this checkout, so I could not read `createJSONStorage` to confirm `JSON.stringify` runs before `StateStorage.setItem`. That one read decides whether F1 is High or void; the per-`set` `partialize` half is independently confirmed. (2) **No baselines exist anywhere in this repo** — every finding is flagged speculative, so all severity ordering here is analytic, not measured. A single instrumented session capturing persist-blob size and per-`set` serialize duration would convert most of this report from argument to evidence. (3) **S4 is a severity cliff**: F2/F3/F6 escalate on the flag flip, and the pre-S4 gate is the natural place to require the coalescing writer.
