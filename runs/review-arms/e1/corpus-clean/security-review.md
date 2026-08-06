# Security Review — corpus-clean (dc6dfb0..4de2b00, app/ only)

**Scope:** `git diff dc6dfb0..4de2b00 -- app/` — the DD-009 S0/S1 corpus filesystem substrate (`app/lib/corpus/**`) plus the storage-seam swap in `app/lib/stores/workspaceStore.ts`, and the review-fix commit 4de2b00 (A1 vocabulary rename, A2 state-blob path routed through `stateBlobPath()`, A3 stale-ref fixes, A4 manifest docstring correction, C1 `splitPath` segment rejection, C2 production hard-refuse). `docs/**` is context, not under review.
**Date:** 2026-08-06
**Based on:** merged code fact-check (k=3), `/workspace/runs/review-arms/e1/code-fact-check-report.md`
Commit: 4de2b00

---

### Trust Boundary Map

- **TB-1 — Untrusted names → path construction → OPFS handle API.** User-supplied workspace titles and externally-sourced ids (source ids, artifact type ids, custom-type ids) cross into filesystem path segments via `app/lib/corpus/paths.ts` (`workspaceSlug`, `safeSegment`, `safeExt`), then into `app/lib/corpus/opfsAdapter.ts` `splitPath` → `walkDir` → `getDirectoryHandle`/`getFileHandle`. `paths.ts` declares itself the single choke point; `splitPath` is the defense-in-depth backstop added by C1.
- **TB-2 — Build/deploy configuration + same-origin runtime state → persistence-substrate selection.** `app/lib/corpus/flag.ts` `isCorpusEnabled()` reads two inputs of very different trust: build-time `process.env.NODE_ENV` / `process.env.NEXT_PUBLIC_CORPUS_FS` (trusted, set by the deploy pipeline) and `window.localStorage["corpus-fs-enabled"]` (writable by any same-origin script). The output of this boundary decides where all user work is persisted, so a wrong answer is a data-availability event, not a cosmetic one.
- **TB-3 — In-memory application state → serialized bytes on disk → back into the store.** The Zustand persist blob crosses into OPFS through `app/lib/corpus/storeAdapter.ts` `createCorpusBackedStorage`, and `workspace.json` manifests cross back in through `app/lib/corpus/manifest.ts` `parseManifest`. Anything that has ever been written to OPFS — including by a previous build, a corrupted write, or (in S2/S3) a synced folder or a git remote — is untrusted input on the way back.
- **TB-4 — Test doubles → shipped behavior (assurance boundary).** `app/lib/corpus/__tests__/inMemoryCorpusFs.ts` and the stubbed `navigator.storage` objects in `opfsAdapter.test.ts` stand in for OPFS in CI. Every security property asserted against a double is only as strong as the double's fidelity; divergences here are silent gaps in the guarantee, not test bugs.

The interesting property of this diff is that TB-1 is well-defended and TB-2/TB-3 are not. The path layer has a sanitizer, a backstop, and tests; the substrate-selection guard and the deserialization/error paths have neither tests nor consumers. Findings below reference these labels.

---

### Findings

#### F1 — C2's production hard-refuse is skipped entirely in the one environment where it matters most, while the enable path below it stays live

**Severity:** High
**Location:** `app/lib/corpus/flag.ts:21-30`
**Boundary:** TB-2
**Move:** Invert access control (what does the guard *not* cover?)
**Confidence:** High that the code has this shape and this failure mode; Medium that a real Next 16 production bundle reaches it (the fact-check could not statically confirm the inlining).

**Evidence:**
```ts
  if (typeof process !== "undefined" && process.env?.NODE_ENV === "production") return false;

  if (typeof process !== "undefined" && process.env?.NEXT_PUBLIC_CORPUS_FS === "1") return true;
  if (typeof window !== "undefined") {
    try {
      return window.localStorage.getItem(CORPUS_FLAG_KEY) === "1";
    } catch {
      return false;
    }
  }
```

The guard and the env-var enable path are both gated on `typeof process !== "undefined"`, but the localStorage enable path is not. That asymmetry inverts the intent: in any runtime where `process` is absent or not inlined, the refuse-in-production check silently evaluates to "not production" and falls through to the localStorage check, which still works because `window` is always defined in a browser. The guard fails open on exactly the input it was written to constrain. The fact-check already flagged that the guarantee rides on Turbopack inlining the optional-chained `process.env?.NODE_ENV` form, which is off Next's documented `process.env.X` pattern; combined with the asymmetric gating, "not inlined" does not degrade to a warning, it degrades to the original C2 footgun — a production user with `corpus-fs-enabled=1` in localStorage gets persistence swapped to an empty corpus with no migration (S1 has none), and their work appears to vanish. The guard is also entirely untested: `workspaceStore-corpus-flag.test.ts` runs under vitest where `NODE_ENV === "test"`, so no test ever exercises the production branch.

**Legibility-target:** A reviewer reading `flag.ts` sees three sequential checks and reads them as a priority list with the refusal first. The control-flow fact that the first check can be skipped while the third still fires is invisible at that reading; making the guard's precondition and the enable path's precondition the same would restore the reading.

**Recommendation:** Make the refusal unconditional on `process` presence — compute `const isProd = typeof process === "undefined" || process.env?.NODE_ENV === "production"` (fail *closed* when the environment is unknown), or move the whole flag behind a single build-time constant. Use the plain `process.env.NODE_ENV` form so the bundler's documented inlining applies. Add a test that stubs `process.env.NODE_ENV = "production"` plus a set localStorage key and asserts `isCorpusEnabled() === false`.

---

#### F2 — `writeFile` commits a truncated or empty file when the write fails, and masks the original error

**Severity:** Medium
**Location:** `app/lib/corpus/opfsAdapter.ts:122-128`
**Boundary:** TB-3
**Move:** Error paths
**Confidence:** High

**Evidence:**
```ts
        const w = await fh.createWritable();
        try {
          // Pass a fresh ArrayBuffer view; some implementations dislike shared buffers.
          await w.write(bytes);
        } finally {
          await w.close();
        }
```

`FileSystemWritableFileStream.close()` is the *commit* operation — it swaps the staged contents over the existing file. Calling it from `finally` means that when `write()` rejects (the quota case this module explicitly advertises it handles), the adapter still commits, replacing a good file with a zero-length or partially-written one. The state blob is the entire workspace, so the failure mode is "quota exceeded" turning into "workspace destroyed" rather than "workspace not updated". Secondarily, if `close()` itself rejects inside `finally`, its error replaces the original `write()` error, so a quota failure can surface as an unrelated i/o error and the `{kind:"quota-exceeded"}` reification the file's header promises is lost. Note the existing quota test only stubs `createWritable()` throwing — it never exercises a failure *after* the writable is open, so this path is untested.

**Legibility-target:** `finally { await w.close() }` reads as ordinary resource cleanup, which is what it would be if `close()` were a release. That `close()` is a commit and `abort()` is the release is a File System Access API fact a reader may not carry; the code should name it.

**Recommendation:** `catch` the write error, `await w.abort()` (best-effort, in its own try/catch), and rethrow the original; only `close()` on the success path. Add a comment stating that `close()` commits.

---

#### F3 — Corpus-backed persistence has no error handling and no consumer catches `CorpusError` anywhere in `app/`

**Severity:** Medium
**Location:** `app/lib/corpus/storeAdapter.ts:59-71` (vs. `:32-42`)
**Boundary:** TB-3
**Move:** Error paths (unhandled corpus-write rejections)
**Confidence:** High on the code shape and the absence of consumers; Medium on the precise runtime symptom, which depends on Zustand v5 persist's internal floating-promise handling.

**Evidence:**
```ts
    setItem: async (name, value) => {
      await fs.writeFile(pathFor(name), enc.encode(value));
    },
```
compared with the OFF path in the same file:
```ts
          localStorage.setItem(name, value);
        } catch (e) {
          console.warn("Failed to persist workspace (localStorage quota exceeded):", e);
        }
```

The legacy path at least degrades loudly-ish; the corpus path lets every `quota-exceeded`, `unavailable`, and `io` rejection escape into `zustand/persist`, which invokes storage `setItem` as a fire-and-forget side effect of `setState`. A search across `app/` for `CorpusError` finds it only inside `app/lib/corpus/**` and its tests — nothing in the store, no UI, no error boundary consumes it. So the module header's "failure reification" claim (`opfsAdapter.ts:11-15`) is accurate about the *producer* and hollow about the *system*: typed errors are minted and then dropped on the floor. The user-visible result of a quota or SSR-adjacent failure with the flag on is that edits stop persisting with no indication, which is the same silent-data-loss class C2 was written to prevent — just reached by a different route.

**Legibility-target:** DD-009's "failure-driven UI" mandate and the exhaustive `CorpusErrorKind` union both signal that failures are handled. A reader has to grep for consumers to discover there are none. A `// TODO(S4): no consumer surfaces these yet` at the seam would make the gap legible without changing behavior.

**Recommendation:** Wrap `setItem`/`getItem`/`removeItem` in a handler that at minimum logs the typed kind, and thread a persistence-failure signal into the store so a later sub-task can surface it. Until then, document explicitly that the corpus path is dev-only *because* failures are invisible, not only because migration is missing.

---

#### F4 — `readdir` bypasses the C1 segment check; the C1 guard covers 4 of 5 methods

**Severity:** Medium
**Location:** `app/lib/corpus/opfsAdapter.ts:137` (guard at `:58-71`)
**Boundary:** TB-1
**Move:** Implicit sanitization assumptions
**Confidence:** High

**Evidence:**
```ts
        const dirs = path.replace(/^\/+|\/+$/g, "").split("/").filter(Boolean);
```
versus the guarded form in `splitPath`:
```ts
    if (seg === "." || seg === ".." || seg.includes("\\")) {
      throw new CorpusError({ kind: "io", path, reason: `unsafe path segment: ${seg}` });
    }
```

`readdir` re-implements the split inline because it has no filename component, and in doing so drops the segment validation that `readFile`/`writeFile`/`rm`/`stat` all get. A `..` or backslash segment reaches `getDirectoryHandle` directly. In practice the browser rejects such names with a `TypeError`, so this is very unlikely to be an actual escape — but it means (a) the C1 defense-in-depth property is stated more broadly than it holds, (b) the failure surfaces as a generic `{kind:"io"}` with a browser message instead of the module's own `unsafe path segment` diagnostic, and (c) the one method whose safety depends entirely on the browser is the one method whose behavior is *not* covered by the C1 test, which only exercises `writeFile`. The residual risk grows in S2/S3, where the same `CorpusFS` interface is implemented over FSA and a worker proxy that may not share OPFS's name restrictions.

**Legibility-target:** The `splitPath` comment says "the adapter must not trust callers" — a property statement that a reader will reasonably assume applies to the adapter, not to four of its five methods.

**Recommendation:** Extract the segment check into a `assertSafeSegments(path, parts)` helper and call it from both `splitPath` and `readdir`. Extend the C1 test to assert the same rejection for `readdir`, `rm`, `stat`, and `readFile`.

---

#### F5 — Manifest codec silently drops malformed elements and ignores `manifestVersion`

**Severity:** Medium
**Location:** `app/lib/corpus/manifest.ts:87-107`
**Boundary:** TB-3
**Move:** Serialization boundaries
**Confidence:** High

**Evidence:**
```ts
  if (typeof raw.manifestVersion !== "number") fail("missing required field: manifestVersion");

  const sources: SourceRef[] = Array.isArray(raw.sources)
    ? raw.sources.filter(isObject).map((s) => {
```
and
```ts
    ? raw.customArtifactTypeIds.filter((x): x is string => typeof x === "string")
```

Two distinct gaps at the same boundary. First, `filter(isObject)` and `filter(...typeof x === "string")` run *before* the fail-loud `map`, so any element that is not an object (or not a string) is removed without error — a `sources` array of `["evil", null, 42]` parses as a manifest with zero sources and no complaint. The file's own header claims "every content field (title, sources, artifacts, customArtifactTypeIds) fails loud if missing or malformed", which is true at the array level and false at the element level; a workspace whose index has been partially corrupted comes back looking like a workspace that simply has no sources — precisely the "masquerade as 'this workspace has no work in it'" outcome the docstring says it prevents. Second, `manifestVersion` is checked for *type* but never compared against `MANIFEST_VERSION`, so a manifest written by a future schema (v2, where field meanings may differ) is parsed with v1 semantics and silently downgraded. Both matter more in S2/S3 than today, because that is when manifests start arriving from a user-chosen folder or a git remote rather than only from this code.

**Legibility-target:** The header is the specification a later maintainer will trust instead of re-reading the parser. It should be corrected to say element-level malformations are dropped (or, preferably, the code changed to match the header).

**Recommendation:** Replace the pre-filters with an explicit per-element validation that calls `fail()` on any non-conforming element, and add `if (raw.manifestVersion !== MANIFEST_VERSION) fail(...)` (or an explicit, tested upgrade path). Validate `currentVersion` as a positive integer and `id`/`ext` as non-empty at parse time rather than deferring to `artifactVersionPath`'s throw much later.

---

#### F6 — Slug/segment sanitization collapses distinct names onto the same path

**Severity:** Medium
**Location:** `app/lib/corpus/paths.ts:36-58`
**Boundary:** TB-1
**Move:** Implicit sanitization assumptions
**Confidence:** High on the collision; Medium on impact, since no caller creates workspace directories yet in S1.

**Evidence:**
```ts
const SAFE_SEGMENT = /[^a-zA-Z0-9_-]+/g;
```
```ts
  const slug = title
    .normalize("NFKD")
    .replace(SAFE_SEGMENT, "-")
    .replace(/-{2,}/g, "-")
    .replace(/^-+|-+$/g, "")
    .toLowerCase();
```

The sanitizer is correctly *safe* — it cannot produce a traversal, and the empty-result case throws rather than silently yielding `""`, which is good. But it is not injective: `"A/B"`, `"A B"`, `"a-b"`, and `"a...b"` all map to `a-b`, and NFKD normalization folds additional distinct unicode titles together. Two workspaces with different titles therefore share `workspaces/a-b/workspace.json`, and whichever is written second overwrites the first — a silent cross-workspace data-loss primitive reachable by a user simply naming two workspaces similarly, and a mild integrity concern if titles ever become attacker-influenced (shared/imported workspaces in a later sub-task). The test suite asserts the safety property (`not.toContain("..")`) but never the uniqueness property.

**Legibility-target:** `workspaceSlug`'s docstring promises the slug "cannot escape `workspaces/`" — a containment guarantee. Readers routinely over-read containment as identity. Stating "slugs are not unique; callers must disambiguate" would close that gap.

**Recommendation:** Append a short deterministic suffix derived from the untruncated title (e.g. first 8 hex chars of a hash) to the slug, or maintain an id→slug allocation table in `settings.json`. At minimum, document the collision and have the S4 workspace-creation path detect an existing directory rather than overwrite.

---

#### F7 — Every store mutation rewrites the entire state blob to OPFS, undebounced and unbounded

**Severity:** Medium
**Location:** `app/lib/corpus/storeAdapter.ts:55-71`; `app/lib/stores/workspaceStore.ts:496`
**Boundary:** TB-3
**Move:** Million-of-these
**Confidence:** High

**Evidence:**
```ts
export function createCorpusBackedStorage(fs: CorpusFS): StateStorage {
```
with no debounce, against the OFF path's `}, 300);` and the store's own header claim:
```
 * - persist middleware handles serialization lifecycle; custom debounced storage adapter rate-limits writes
```

The fact-check already established the "debounced" header claim is false on the corpus path (author-acknowledged, dev-only). The security-relevant consequence is a resource one: with the flag on, every keystroke serializes the whole workspace — sources, all artifact version history up to `MAX_VERSIONS`, decomposition graph — and rewrites it as one OPFS file. OPFS writes stage through a swap file, so peak usage is roughly 2× the blob per write, and there is no size ceiling, no eviction, and no growth check anywhere in the corpus module. A workspace with a few large sources plus version history reaches storage pressure quickly under sustained editing; the terminal state is a persistent `quota-exceeded` on every write, which by F2 destroys the on-disk blob and by F3 does so invisibly. The three findings compose into a self-inflicted availability failure with no error signal.

**Legibility-target:** The store header's rate-limiting claim now covers only one of two branches; it should say which.

**Recommendation:** Apply the same 300ms (or larger) debounce to the corpus path, and add a size check before write — e.g. refuse and reify a `quota-exceeded` when the encoded blob exceeds a configured ceiling, rather than discovering it at the OPFS layer. Correct the store docstring.

---

#### F8 — Caller's `Uint8Array` is handed to an async write; the comment claims a copy that isn't made

**Severity:** Low
**Location:** `app/lib/corpus/opfsAdapter.ts:123-125`
**Boundary:** TB-3
**Move:** TOCTOU
**Confidence:** High (fact-check confirmed the comment is incorrect)

**Evidence:**
```ts
          // Pass a fresh ArrayBuffer view; some implementations dislike shared buffers.
          await w.write(bytes);
```

No fresh view is constructed — the caller's array is passed through as-is, so the bytes are read by the implementation at some point after the call returns to the microtask queue. Any mutation of the caller's buffer between the `writeFile` call and the underlying write is observable in the persisted file, and a detached buffer (transferred to a worker, which is exactly S3's plan) would fail or write garbage. The in-memory fake does the opposite — `files.set(normalize(path), bytes.slice())`, explicitly copying — so the two implementations disagree on a semantic the shared contract suite never tests. Today's only caller passes a freshly-encoded array and never mutates it, which is why this is Low rather than higher; it becomes a live check-to-use gap the moment sources (PDF bytes from a `File`/`ArrayBuffer`) or a worker transport are wired up.

**Legibility-target:** The comment asserts a defense that does not exist. A reader auditing buffer aliasing will read this line, believe the copy is made, and stop looking.

**Recommendation:** Either make the comment true (`await w.write(bytes.slice())`) or delete it and state in `CorpusFS`'s docstring that `writeFile` does not copy and callers must not mutate the array until the promise settles. Add a contract-suite case that mutates the source array after `writeFile` resolves and asserts the stored bytes are unchanged — this is the case that currently lets the fake and the adapter diverge.

---

#### F9 — Persistence substrate is selected from an unauthenticated same-origin localStorage key

**Severity:** Low
**Location:** `app/lib/corpus/flag.ts:24-29`; `app/lib/corpus/storeAdapter.ts:74-79`
**Boundary:** TB-2
**Move:** Trace trust boundaries
**Confidence:** High

**Evidence:**
```ts
  if (typeof window !== "undefined") {
    try {
      return window.localStorage.getItem(CORPUS_FLAG_KEY) === "1";
```

Any code running same-origin — an XSS payload, a compromised dependency, a browser-extension content script, a stale devtools snippet — can set one localStorage key and redirect all subsequent persistence to an empty corpus. This is a low-privilege primitive with a disproportionate user-visible effect (all work appears to vanish), and it is the kind of thing that gets reached for as a nuisance/denial payload precisely because it looks harmless. Two things bound the severity: the prior localStorage blob is not deleted, so flipping the flag back recovers the data, and F1's guard is *supposed* to make this unreachable in production. It is Low rather than Informational only because F1 shows that guard can fail open.

**Legibility-target:** The flag docstring frames localStorage as a developer convenience. It is also an attack surface; naming it as one keeps the S4 "real rollout knob" conversation honest.

**Recommendation:** When S4 makes this a real flag, drive it from build config or a server-provided value, not from client-writable storage. Meanwhile, note in the docstring that the localStorage path is dev-only *and* untrusted.

---

#### F10 — CI's assurance rests on doubles that diverge from the adapter on the security-relevant behaviors

**Severity:** Low
**Location:** `app/lib/corpus/__tests__/inMemoryCorpusFs.ts`; `app/lib/corpus/__tests__/corpusFsContract.ts`
**Boundary:** TB-4
**Move:** Implicit sanitization assumptions
**Confidence:** High

**Evidence:**
```ts
    async writeFile(path, bytes) {
      // Copy so later mutation of the caller's array can't alter stored bytes.
      files.set(normalize(path), bytes.slice());
    },
```
against the contract suite's own claim:
```
 * out-of-CI Playwright (jsdom has no OPFS). Keeping the cases in one place means
 * the fake and the adapter are held to identical behavior (substitutability).
```

The fake performs no path-segment validation at all (`normalize` only strips leading/trailing slashes), so `writeFile("a/../../b")` succeeds against the fake and throws against the adapter; and it copies bytes where the adapter aliases (F8). The shared contract suite tests neither behavior, so the substitutability claim holds only over the cases it happens to cover. Since the corpus-flag test (`workspaceStore-corpus-flag.test.ts`) and every CI corpus test run against the fake or hand-rolled stubs, the C1 traversal guard, the quota-during-write path (F2), and the aliasing semantics are all effectively unverified in CI — the one C1 test that exists drives a stub whose `getDirectoryHandle` accepts any name and returns itself. This is an assurance finding, not a vulnerability: it is why F2, F4, and F8 could all land in a commit whose stated purpose was closing security review items.

**Legibility-target:** A reader sees a shared contract suite and a "substitutability is verified, not assumed" comment and concludes the fake is safe to reason from. Listing the deliberately-unmodeled behaviors in that header would make the residual risk visible.

**Recommendation:** Add contract cases for unsafe-segment rejection and post-write mutation, and make the fake enforce the same segment rules as `splitPath` (share the helper from F4's recommendation). Track the out-of-CI Playwright run as a gating step before the flag becomes user-reachable, not as a nice-to-have.

---

#### F11 — No secrets, no cryptography, and no at-rest protection in the corpus substrate

**Severity:** Informational
**Location:** `app/lib/corpus/**` (whole module)
**Boundary:** TB-3
**Move:** Follow secrets; cryptography
**Confidence:** High

**Evidence:** The only environment reads in the diff are
```ts
  if (typeof process !== "undefined" && process.env?.NEXT_PUBLIC_CORPUS_FS === "1") return true;
```
— a `NEXT_PUBLIC_`-prefixed, deliberately client-visible flag. No credentials, tokens, or keys appear anywhere in the range, and no cryptographic primitive is used or misused.

Recording this as a checked-and-clear result rather than an omission. Two things worth carrying forward rather than acting on now: workspace content is stored in OPFS in plaintext and is readable by any same-origin script (consistent with the localStorage baseline it replaces, so not a regression), and S3's git remote will introduce the module's first real credential — `CorpusErrorKind` already anticipates it with `{ kind: "remote-auth-expired" }`, which is the right place to make sure the token never lands in a `CorpusError` message or a serialized `CorpusWorkerError`.

**Legibility-target:** None needed; `toWorkerError` copying `detail` and `message` verbatim across the worker boundary is the line to revisit when secrets arrive.

**Recommendation:** No action in this range. When S3 lands, assert that no `CorpusError` message or `detail` can carry a credential across `toWorkerError`.

---

### What Looks Good

- **`paths.ts` as a declared choke point.** Having exactly one module build corpus paths, with the traversal defense stated in the file header and enforced in two functions, is the right shape. The decision to *throw* on an all-unsafe title rather than return `""` (`paths.ts:43-45`) closes the classic empty-segment escape, and it is tested.
- **C1's defense-in-depth reasoning.** `splitPath` rejecting `..` rather than resolving it — with the comment explaining that an adapter is the wrong layer to interpret traversal — is exactly the right call. The gap in F4 is coverage, not judgment.
- **Typed, exhaustive error model.** `CorpusErrorKind` as a discriminated union with `assertNever` means adding a failure mode forces every consumer to handle it at compile time. That is a genuinely stronger foundation than the `console.warn`-and-continue pattern it replaces; F3 is about the missing consumers, not the model.
- **SSR/unavailable guard.** `getRoot()` turning a missing `navigator.storage` into `{kind:"unavailable"}` instead of a raw `TypeError`, tested across all five methods, prevents the whole class of "storage silently absent" confusion.
- **Default OFF, with the reason documented.** The flag file states plainly that S1 has no migration and that enabling it starts from an empty corpus. Whatever F1 says about the guard's implementation, the intent behind C2 is correct and clearly recorded.
- **Explicit `state/` namespace fork.** Routing the blob path through `stateBlobPath()` (A2) so the S1/S4 namespace split is greppable, with a comment saying S4 must reconcile and retire it, is good debt hygiene.

---

### Summary Table

| ID | Severity | Finding | Boundary | Move |
|----|----------|---------|----------|------|
| F1 | High | C2 production guard skipped when `process` is undefined; localStorage enable path stays live | TB-2 | Invert access control |
| F2 | Medium | `finally { close() }` commits a truncated file on write failure and masks the error | TB-3 | Error paths |
| F3 | Medium | Corpus `setItem` has no error handling; no `CorpusError` consumer exists in `app/` | TB-3 | Error paths |
| F4 | Medium | `readdir` bypasses the C1 segment check (4 of 5 methods guarded) | TB-1 | Implicit sanitization |
| F5 | Medium | Manifest codec silently drops malformed elements; `manifestVersion` unchecked | TB-3 | Serialization boundaries |
| F6 | Medium | Slug sanitization is safe but not injective — distinct titles collide on one path | TB-1 | Implicit sanitization |
| F7 | Medium | Undebounced full-blob rewrite per mutation; no size bound on corpus growth | TB-3 | Million-of-these |
| F8 | Low | Caller's array passed to async write; "fresh ArrayBuffer view" comment is false | TB-3 | TOCTOU |
| F9 | Low | Substrate selected from a client-writable localStorage key | TB-2 | Trust boundaries |
| F10 | Low | Test doubles diverge from the adapter on segment rejection and byte copying | TB-4 | Implicit sanitization |
| F11 | Informational | No secrets or crypto in range; plaintext at rest; S3 credential noted | TB-3 | Secrets / crypto |

---

### Overall Assessment

This is a well-structured substrate with a security posture that is strong at TB-1 and thin at TB-2 and TB-3. The path layer — the part a reviewer instinctively checks first — has a sanitizer, a defense-in-depth backstop, and tests. The two places that actually decide whether user data survives are the substrate-selection guard (F1) and the write/error path (F2, F3, F7), and none of those has a test.

The single finding worth blocking on is F1. The guard added by C2 is the mitigation for the module's largest known risk — flipping persistence to an empty corpus with no migration — and its `typeof process !== "undefined"` precondition makes it fail *open* in the environment where the risk is real, while leaving the localStorage enable path underneath it fully functional. That is a one-line fix (fail closed when `process` is absent) plus a test, and it converts a guarantee that currently depends on unconfirmed bundler behavior into one that depends on nothing.

F2, F3, and F7 are individually Medium and jointly worse than that: unbounded undebounced writes drive toward quota, quota destroys the blob instead of preserving it, and nothing reports either. Whoever picks these up should fix them as one unit rather than three, because the composition is the interesting part. F5 and F6 are latent — they cost little today and cost real integrity in S2/S3 when manifests and titles start arriving from outside this code. F10 explains the pattern: the commit that was supposed to close security findings introduced two of them (F2, F8) in code paths that CI's doubles do not model, so tightening the contract suite is the leveraged move for the next round.

Nothing here is remotely exploitable by a remote attacker in the current shape — the flag is off, there is no server, and the substrate is origin-scoped. The realistic threat model is the user losing their own work, plus a low-privilege same-origin nuisance (F9). Judged against that model rather than a generic one, the diff is close to fine and one fix away from matching its own stated guarantees.

---

## Goal-Alignment Note

- **Answered:** All nine security cognitive moves applied to the `dc6dfb0..4de2b00` `app/` diff — trust boundaries (TB-1..TB-4 mapped, F9), implicit sanitization including what bypasses the C1 rejection (F4, F6), error paths and unhandled corpus-write rejections (F2, F3), TOCTOU (F8), inverted access control on the C2 production refuse and its inlining dependency (F1), secrets (F11), serialization boundaries including manifest silent filtering and version handling (F5), million-of-these / unbounded corpus growth and OPFS quota (F7), and cryptography (F11, no findings). Eleven findings reported at all severities down to Informational, each with verbatim evidence, a boundary label, and a legibility target.
- **Out of scope:** `docs/**` (context only, per brief); commits outside the range; performance, API-consistency, and architecture concerns except where they carry a security consequence; linter-level findings, deliberately excluded. The C2 inlining question is reported as a conditional risk rather than resolved — confirming it requires building the production bundle and inspecting output, which is outside a read-only review of this range and which the merged fact-check already recorded as statically unconfirmable. No fix loop was run; this is a pass-1 measurement report.
- **Escalate:** None. No HALT-ESCALATE canonical pattern was encountered.
