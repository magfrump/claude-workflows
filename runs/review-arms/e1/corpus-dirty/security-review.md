# Security Review — corpus-dirty (dc6dfb0..2dc403e, app/ only)

**Scope:** `git diff dc6dfb0..2dc403e -- app/` — the DD-009 S0/S1 corpus foundation: `app/lib/corpus/{types,flag,paths,manifest,opfsAdapter,storeAdapter}.ts`, the corpus test suite, and the storage-seam change in `app/lib/stores/workspaceStore.ts`. `docs/working/**` in the range is context, not under review.
**Date:** 2026-08-06
**Based on:** merged code fact-check (k=3), treated as foundation and not re-verified.
**Commit:** 2dc403e

---

## Trust Boundary Map

This change introduces a new persistence substrate and a new runtime switch that decides which substrate the application writes to. Both are trust boundaries, and the second is novel to this PR — before it, there was exactly one place workspace state could live.

- **B1: Untrusted document content → persisted blob.** User-supplied source text, extracted file records, context text, semiformal text, and Lean code (`workspaceStore.ts:511-520` `partialize`) are serialized by zustand and handed to the selected `StateStorage`. Nothing in the corpus layer treats this content as untrusted; it is opaque bytes. The boundary matters because the *volume* and *durability* of this content changes when the substrate changes.
- **B2: Same-origin script / user console → substrate selection.** `flag.ts:15-25` reads `localStorage["corpus-fs-enabled"]` at store-init time. Anything that can run script in the origin — an XSS payload, a pasted console snippet, a malicious extension content script — can flip the application's entire persistence target. There is no `NODE_ENV` gate, no build-time constraint, and no confirmation step. This is the weakest boundary in the change.
- **B3: Persisted bytes (OPFS / localStorage) → in-memory application state.** `storeAdapter.ts:57-60` reads bytes back and `manifest.ts:parseManifest` decodes and validates the manifest form. Persisted bytes are attacker-influenceable via B2 (script can write directly to OPFS or localStorage), so this is a deserialization boundary, not a trusted-round-trip.
- **B4: Application-supplied names/titles → OPFS path segments.** `paths.ts` sanitizes workspace titles and ids into path segments; `opfsAdapter.ts:splitPath` splits an arbitrary path string into directory-handle calls. The documented invariant is that `paths.ts` is the sole producer of corpus paths, making `workspaceSlug`/`safeSegment` the single choke point.
- **B5: Browser storage manager → application data.** OPFS lives in the origin's evictable storage bucket. The browser, not the application, decides when that data is discarded. `types.ts` anticipates this (`browser-storage-cleared` kind) but nothing in the change requests persistence or handles the event.

Findings below reference these labels.

---

## Findings

#### 1. Persistence substrate is switchable by any same-origin script, with no environment gate

**Severity:** Medium
**Location:** `app/lib/corpus/flag.ts:15-25`; `app/lib/corpus/storeAdapter.ts:71-76`
**Boundary:** B2
**Move:** Invert access control
**Confidence:** High
**Evidence:**
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
**Legibility-target:** The header comment asserts "DEFAULT OFF and DEV-ONLY"; a reader should not have to derive that "dev-only" is enforced by nothing.

Inverting the control question — *who is allowed to turn this on?* — the answer is "anyone who can execute one line of JavaScript in the origin, in any build, including production." The fact-check already established that "DEV-ONLY" is policy rather than mechanism: there is no `NODE_ENV`/`process.env.NODE_ENV !== "production"` guard anywhere in the function, so the localStorage branch is live in a production bundle. Combined with the documented fact that S1 has no localStorage→corpus migration, flipping this flag does not merely change where data goes — it makes all existing workspace content invisible on the next load, because the corpus path never reads the localStorage key. An XSS payload that sets one localStorage key therefore inflicts a persistent, hard-to-diagnose loss of the user's working state that outlives the payload itself and survives a page reload, which is a materially better outcome for an attacker than a transient script injection.

**Recommendation:** Gate the localStorage branch behind a build-time development check (`process.env.NODE_ENV !== "production"`) so the runtime switch does not exist in production bundles at all. Until S4 migration ships, that gate is the only thing standing between the flag and irreversible-looking data loss.

---

#### 2. Build-time flag path is likely inert, leaving the runtime flag as the sole mechanism

**Severity:** Low
**Location:** `app/lib/corpus/flag.ts:16`
**Boundary:** B2
**Move:** Invert access control / implicit assumptions
**Confidence:** Medium
**Evidence:**
```ts
  if (typeof process !== "undefined" && process.env?.NEXT_PUBLIC_CORPUS_FS === "1") return true;
```
**Legibility-target:** The doc comment offers the env var as a first-class enable path; if it never fires, the documented "safe" path is a decoy.

Next.js inlines `NEXT_PUBLIC_*` reads by literal textual substitution of `process.env.NEXT_PUBLIC_X`; the optional-chaining form `process.env?.NEXT_PUBLIC_CORPUS_FS` deviates from that pattern and is not guaranteed to be replaced in the client bundle. Where it is not replaced, `process` is undefined in the browser, the `typeof process !== "undefined"` guard short-circuits, and the branch can never return true client-side. The security consequence is not the dead branch itself but its interaction with finding 1: the one enable mechanism that *is* build-scoped and therefore safely absent from production is the one that does not work, while the one that works in production is the unguarded runtime switch.

**Recommendation:** Use the literal `process.env.NEXT_PUBLIC_CORPUS_FS === "1"` form and add a test asserting the env path activates in a built client bundle, so the build-time control is real before it is relied on.

---

#### 3. Corpus-backed writes have no rejection handler; quota and I/O failures become unhandled rejections

**Severity:** Medium
**Location:** `app/lib/corpus/storeAdapter.ts:56-67`
**Boundary:** B1, B5
**Move:** Trace error paths
**Confidence:** Medium-High
**Evidence:**
```ts
    setItem: async (name, value) => {
      await fs.writeFile(pathFor(name), enc.encode(value));
    },
    removeItem: async (name) => {
      await fs.rm(pathFor(name));
    },
```
**Legibility-target:** `opfsAdapter.ts` documents "Failure reification: a quota failure rejects with {kind:"quota-exceeded", substrate:"opfs"} — it is NOT swallowed with console.warn the way the legacy localStorage adapter does." A reader will conclude the failure is *handled better*; at this seam it is handled *less*.

The OPFS adapter faithfully reifies quota and I/O failures as typed `CorpusError`s, but nothing at the store seam consumes them. `createCorpusBackedStorage` has no `try`/`catch` and zustand's persist middleware invokes `setItem` without awaiting its result, so a rejected write surfaces as an unhandled promise rejection and nothing else — no UI signal, no retry, no fallback. Compare the OFF path (`storeAdapter.ts:31-35`), which at least emits a `console.warn` on quota exhaustion. The net effect for a user on the corpus path is that persistence stops working silently and every subsequent edit is lost on reload; the typed error contract that DD-009 built (`types.ts` §failure-driven-UI) is defeated at the first consumer, which is the worst place to defeat it because it establishes the pattern later sub-tasks will copy.

**Recommendation:** Wrap the corpus `setItem`/`removeItem` bodies in a handler that surfaces `CorpusError` to an application-level error channel (at minimum matching the OFF path's `console.warn`, ideally a store field the UI can render), rather than letting the promise reject into nothing.

---

#### 4. No debounce on the corpus write path creates a concurrent-write lost-update window

**Severity:** Medium
**Location:** `app/lib/corpus/storeAdapter.ts:61-63`; `app/lib/corpus/opfsAdapter.ts:writeFile`
**Boundary:** B1
**Move:** TOCTOU / concurrency
**Confidence:** Medium
**Evidence:**
```ts
        const dir = await walkDir(root, dirs, true);
        const fh = await dir!.getFileHandle(name, { create: true });
        const w = await fh.createWritable();
        try {
          // Pass a fresh ArrayBuffer view; some implementations dislike shared buffers.
          await w.write(bytes);
        } finally {
          await w.close();
        }
```
**Legibility-target:** `workspaceStore.ts:5` states the storage adapter "rate-limits writes" unconditionally; the fact-check confirmed the corpus branch has no debounce, so a reader reasoning about write frequency from the header will be wrong by orders of magnitude.

The OFF path coalesces writes on a 300ms timer; the corpus path issues a full serialize-and-write on every `set()`, which for a text editor means per-keystroke. Each write is a multi-step, non-atomic sequence — walk directories, open handle, open writable, write, close — with `await` points between every step. Two writes started in quick succession interleave, and because a `FileSystemWritableFileStream` commits its accumulated contents at `close()`, the *last close to land* wins rather than the last write to start. Under load that ordering is not guaranteed to match edit order, so a stale snapshot can overwrite a newer one; the same window lets a `removeItem` land between a concurrent write's open and close, resurrecting deleted state. This is a data-integrity bug rather than a classic exploit, but it is triggerable by ordinary fast typing, not just by an adversary.

**Recommendation:** Apply the same debounce/coalescing to the corpus path (or serialize writes through a single-slot queue that drops superseded payloads), and record that the seam's contract is "last edit wins", not "last write to start wins".

---

#### 5. Manifest codec silently drops malformed entries despite documenting a fail-loud contract

**Severity:** Medium
**Location:** `app/lib/corpus/manifest.ts` — `parseManifest`, the `sources`/`artifacts`/`customTypeIds` branches
**Boundary:** B3
**Move:** Serialization boundaries
**Confidence:** High
**Evidence:**
```ts
  const sources: SourceRef[] = Array.isArray(raw.sources)
    ? raw.sources.filter(isObject).map((s) => {
        if (typeof s.id !== "string" || typeof s.ext !== "string") fail("source entry missing id/ext");
        return { id: s.id, label: typeof s.label === "string" ? s.label : s.id, ext: s.ext };
      })
    : fail("missing or invalid field: sources");
```
**Legibility-target:** The file header states "parsing is FAIL-LOUD… never a silent default-empty manifest that would masquerade as 'this workspace has no work in it' and mask data loss." The `.filter(isObject)` call does exactly the partial version of what the comment forbids.

`.filter(isObject)` removes any non-object array element before validation ever sees it, and the same shape applies to `customTypeIds`, whose `.filter((x): x is string => ...)` drops non-strings. A manifest whose `sources` array has been corrupted — or tampered with by same-origin script per B2 — into `["a", "b"]` parses successfully as a workspace with *zero* sources. The manifest is the index that tells consumers which files under `sources/` are live, so a silently-truncated index makes real bytes on disk unreferenced. That is exactly the "masquerades as no work in it" failure the header rules out, arriving through partial rather than total silence, and it becomes actively destructive the moment any later sub-task garbage-collects files the manifest does not reference.

**Recommendation:** Replace both `.filter(...)` calls with validation that calls `fail(...)` on the first non-conforming element, so a corrupt index is a loud `CorpusError` rather than a quiet truncation.

---

#### 6. `manifestVersion` is type-checked but never range-checked

**Severity:** Low
**Location:** `app/lib/corpus/manifest.ts` — `parseManifest` version check and returned object
**Boundary:** B3
**Move:** Serialization boundaries
**Confidence:** High
**Evidence:**
```ts
  if (typeof raw.manifestVersion !== "number") fail("missing required field: manifestVersion");
```
**Legibility-target:** `MANIFEST_VERSION = 1` implies a versioning scheme; a reader will assume the version is enforced somewhere.

The codec accepts any numeric `manifestVersion` — `0`, `2`, `99`, `NaN`, `-1` — and passes it through to the returned manifest unchanged. A manifest written by a future format version therefore parses under v1 semantics, and any subsequent write serializes it back with v1's field set, discarding whatever v2 added. This is the classic downgrade path for versioned on-disk formats, and OPFS makes it worse than usual because the same origin can be served by an older cached bundle (stale service worker, offline load) while newer data sits on disk. Establishing the range check now costs one line; retrofitting it after v2 data exists in the wild does not.

**Recommendation:** Reject `manifestVersion > MANIFEST_VERSION` with a distinct failure (a dedicated kind, or an `io` reason naming the version) and reject non-integer/negative values, before any field is read.

---

#### 7. Timestamps are silently fabricated when absent or malformed

**Severity:** Low
**Location:** `app/lib/corpus/manifest.ts` — `createdAt`/`updatedAt` in the `parseManifest` return
**Boundary:** B3
**Move:** Serialization boundaries
**Confidence:** High
**Evidence:**
```ts
    createdAt: typeof raw.createdAt === "string" ? raw.createdAt : new Date().toISOString(),
    updatedAt: typeof raw.updatedAt === "string" ? raw.updatedAt : new Date().toISOString(),
```
**Legibility-target:** Same fail-loud header as finding 5 — these two lines are silent defaults in a codec documented as having none.

A manifest missing timestamps, or carrying non-string ones, is repaired in place with the current time and reported as valid. `createdAt` in particular is the field that would otherwise reveal that a workspace index was reconstructed, replaced, or corrupted; overwriting it with "now" destroys that signal on the exact read where it would have been most useful. Note also that the check validates only the *type*, not the format, so `createdAt: "not a date"` round-trips untouched — the defaulting and the validation are inconsistent with each other. This is low severity because nothing currently makes a trust decision on these fields, but it is a forensics-integrity hole in a persistence layer whose whole purpose is durability.

**Recommendation:** Fail on absent `createdAt`/`updatedAt` rather than defaulting, and validate that the string parses as an ISO-8601 instant.

---

#### 8. `state/${name}.json` bypasses the documented single path choke point

**Severity:** Low
**Location:** `app/lib/corpus/storeAdapter.ts:55`
**Boundary:** B4
**Move:** Implicit sanitization assumptions
**Confidence:** High
**Evidence:**
```ts
  const pathFor = (name: string) => `state/${name}.json`;
```
**Legibility-target:** `paths.ts:16-19` asserts "The only source of corpus paths is this module — callers must never hand-concatenate, so the traversal guard in `workspaceSlug` is the single choke point that keeps untrusted workspace titles inside `workspaces/`." This line is a caller hand-concatenating.

The fact-check established this as an incorrect claim; the security framing is what the broken invariant costs. `name` here is zustand's persist key, a compile-time constant (`"workspace-zustand-v1"`), so there is no exploitable traversal *today* — and I want to be clear that I am not claiming one. The problem is that the invariant `paths.ts` documents is what future readers will rely on when deciding whether a new path needs sanitizing, and there is now a counterexample in the very first consumer. The `state/` prefix also sits outside the documented folder layout entirely, so a future recursive operation scoped to the documented tree will either miss the store blob or, if scoped to the root, encounter a directory it has no schema for.

**Recommendation:** Add a `statePath(name)` builder to `paths.ts` that runs `name` through `safeSegment`, document `state/` in the layout comment, and have `storeAdapter` call it — restoring the single-choke-point property before a caller with a non-constant name exists.

---

#### 9. `opfsAdapter.splitPath` performs no segment validation, relying entirely on the browser

**Severity:** Low
**Location:** `app/lib/corpus/opfsAdapter.ts` — `splitPath` and `readdir`'s inline split
**Boundary:** B4
**Move:** Implicit sanitization assumptions / defense in depth
**Confidence:** High
**Evidence:**
```ts
function splitPath(path: string): { dirs: string[]; name: string } {
  const parts = path.replace(/^\/+|\/+$/g, "").split("/").filter(Boolean);
  const name = parts.pop();
  if (!name) throw new CorpusError({ kind: "io", path, reason: "path has no file component" });
  return { dirs: parts, name };
}
```
**Legibility-target:** The adapter is the last code between a path string and the storage substrate; a reader auditing traversal will look here and find no check.

Segments such as `..` or `.` are passed through to `getDirectoryHandle` unmodified. In practice the OPFS specification requires implementations to reject those names, so containment holds — but it holds because of a browser guarantee this file neither states nor tests, and `wrap()` will convert that rejection into a generic `{kind:"io"}` error indistinguishable from a disk problem. Given finding 8 has already shown that the `paths.ts` choke point is bypassable, the adapter is the correct place for a cheap redundant check.

**Recommendation:** Reject any segment equal to `.` or `..`, or containing `\`, with an explicit `CorpusError` naming traversal as the reason, and add a contract test asserting it.

---

#### 10. Moving to OPFS reduces durability without requesting storage persistence

**Severity:** Low
**Location:** `app/lib/corpus/storeAdapter.ts:71-76`; `app/lib/corpus/opfsAdapter.ts` — `getRoot`
**Boundary:** B5
**Move:** Million-of-these / follow the resource
**Confidence:** Medium
**Evidence:**
```ts
export function resolveWorkspaceStorage(): StateStorage {
  if (isCorpusEnabled()) {
    return createCorpusBackedStorage(createOpfsCorpusFs());
  }
  return createDebouncedLocalStorage();
}
```
**Legibility-target:** `types.ts` declares a `browser-storage-cleared` error kind, which signals awareness of eviction; a reader will assume something acts on it.

Nothing in the change calls `navigator.storage.persist()`, so the corpus lands in the origin's *best-effort* bucket, which browsers evict under storage pressure without user interaction and without notifying the page. The `browser-storage-cleared` kind exists in the error union but is never constructed anywhere in this diff, so the anticipated failure has a type and no detector. Combined with finding 4 (a full blob rewritten per keystroke, which accelerates quota consumption) and finding 3 (quota failures reaching no handler), the flag-on path can exhaust its budget faster than the flag-off path and then fail silently when it does. Users are also less able to inspect or recover OPFS contents than localStorage, so the loss is both more likely and less recoverable.

**Recommendation:** Call `navigator.storage.persist()` when the corpus path initializes and record the result, and construct `browser-storage-cleared` on the read path when the corpus root exists but expected state is absent — so the declared kind has a producer.

---

#### 11. Slug sanitization is many-to-one with no collision detection, and rejects entirely non-Latin titles

**Severity:** Informational
**Location:** `app/lib/corpus/paths.ts` — `SAFE_SEGMENT`, `workspaceSlug`, `safeSegment`
**Boundary:** B4
**Move:** Implicit sanitization assumptions
**Confidence:** High
**Evidence:**
```ts
const SAFE_SEGMENT = /[^a-zA-Z0-9_-]+/g;
```
**Legibility-target:** The comment frames the regex purely as a containment guard; its collision and rejection behavior is unstated and will surprise.

Collapsing every non-`[A-Za-z0-9_-]` run to a single hyphen is sound for containment — traversal, control characters, and separators are all eliminated, and the empty-result throw correctly prevents `..` from degrading to `""`. The unaddressed consequence is that the mapping is many-to-one: `"Report/2024"`, `"Report 2024"`, and `"Report—2024"` all yield `report-2024`, and nothing in this module or its callers checks whether a slug is already taken. Once workspaces are stored per-slug (S4), one workspace silently occupies another's directory. Separately, a title composed entirely of non-Latin script (CJK, Cyrillic, Arabic) sanitizes to the empty string and throws, so such titles are not merely mangled but rejected — a correctness and inclusivity problem that will read as a crash to the user, since no caller in this diff catches it.

**Recommendation:** Treat the slug as a display-derived *hint* and store a generated unique id as the directory name, or add a collision check with a numeric suffix; and fall back to a generated id rather than throwing when a title sanitizes to empty.

---

#### 12. Error messages embed full paths and raw underlying error text

**Severity:** Informational
**Location:** `app/lib/corpus/opfsAdapter.ts` — `wrap`; `app/lib/corpus/types.ts` — `describeCorpusError`
**Boundary:** B3
**Move:** Trace error paths
**Confidence:** High
**Evidence:**
```ts
function wrap(path: string, e: unknown): never {
  if (e instanceof CorpusError) throw e;
  if (isQuota(e)) throw new CorpusError({ kind: "quota-exceeded", substrate: "opfs" });
  throw new CorpusError({ kind: "io", path, reason: (e as Error)?.message ?? String(e) });
}
```
**Legibility-target:** None needed — this is a deliberate design choice worth recording as accepted, not a defect.

Underlying `DOMException` messages and full corpus-relative paths flow into `CorpusError.message` and thence into `describeCorpusError` output. For a purely local, single-user, origin-private store this discloses nothing an attacker with script access does not already have, and the diagnostic value is high. I am flagging it only so the decision is explicit before S3 adds a remote/git substrate, where the same `wrap` pattern applied to network errors could carry endpoint URLs or auth failure details into user-visible strings.

**Recommendation:** No change now. When `remote` joins `CorpusSubstrate`, split the operator-facing detail from the user-facing message rather than reusing `describeCorpusError` for both.

---

#### 13. `dir!` non-null assertion in `writeFile`

**Severity:** Informational
**Location:** `app/lib/corpus/opfsAdapter.ts` — `writeFile`
**Boundary:** B4
**Move:** Implicit assumptions
**Confidence:** High
**Evidence:**
```ts
        const dir = await walkDir(root, dirs, true);
        const fh = await dir!.getFileHandle(name, { create: true });
```
**Legibility-target:** The assertion encodes "walkDir never returns null when create is true" without saying so.

The assertion is correct as written — `walkDir`'s only `null` return is guarded by `if (!create && isNotFound(e))` — but it is correct by a property of a different function, enforced by nothing. A future change to `walkDir`'s error handling that adds a `null` return under `create: true` would turn this into a runtime `TypeError`, which `wrap` would then report as an `io` error with a message about reading properties of null, sending the next debugger to the wrong file.

**Recommendation:** Give `walkDir` an overload (or a separate `ensureDir`) whose return type is non-nullable when `create` is true, so the invariant is checked by the compiler rather than asserted away.

---

## What Looks Good

- **The error model is genuinely well-designed.** A closed discriminated union (`CorpusErrorKind`) plus `assertNever` means adding a failure kind breaks the build at every consumer, which is the right shape for a failure-driven UI. Findings 3 and 10 are about consumers not using it — the model itself is sound.
- **`workspaceSlug`/`safeSegment` throw on empty rather than returning `""`.** This is the single most important decision in `paths.ts`: silently returning an empty segment for an all-unsafe title is how `..`-style inputs become root-relative writes. The explicit throw closes that.
- **`readFile`/`stat` return `null` for absent and reserve exceptions for real failures**, and `rm` is idempotent. Distinguishing "not there" from "could not tell" at the interface level is what makes the missing-vs-corrupt distinction expressible later.
- **The SSR/unavailability guard in `getRoot`** produces a typed `{kind:"unavailable"}` rather than letting a raw `TypeError` escape, so a server render or an unsupported browser is a handled state rather than a crash.
- **The OFF path was moved verbatim** and pinned by a characterization test, so the default configuration's behavior is unchanged by this PR — the correct risk posture for a substrate swap.
- **Git was deliberately kept off `CorpusFS`.** Resisting the urge to widen the interface now is what keeps the in-memory fake honest and the S3 worker swap a transport change.

---

## Summary Table

| # | Finding | Severity | Boundary | Move | Confidence |
|---|---------|----------|----------|------|------------|
| 1 | Substrate switchable by any same-origin script; no env gate | Medium | B2 | Invert access control | High |
| 3 | Corpus writes have no rejection handler | Medium | B1, B5 | Error paths | Medium-High |
| 4 | No debounce on corpus path → concurrent-write lost update | Medium | B1 | TOCTOU | Medium |
| 5 | Manifest codec silently drops malformed entries | Medium | B3 | Serialization | High |
| 2 | Build-time flag path likely inert | Low | B2 | Invert access control | Medium |
| 6 | `manifestVersion` never range-checked (downgrade) | Low | B3 | Serialization | High |
| 7 | Timestamps silently fabricated | Low | B3 | Serialization | High |
| 8 | `state/${name}.json` bypasses paths.ts choke point | Low | B4 | Implicit sanitization | High |
| 9 | `splitPath` does no segment validation | Low | B4 | Implicit sanitization | High |
| 10 | OPFS adopted without `storage.persist()`; eviction undetected | Low | B5 | Million-of-these | Medium |
| 11 | Slug collisions unchecked; non-Latin titles throw | Informational | B4 | Implicit sanitization | High |
| 12 | Paths and raw error text in messages | Informational | B3 | Error paths | High |
| 13 | `dir!` assertion encodes an unchecked invariant | Informational | B4 | Implicit assumptions | High |

No finding meets the HALT-ESCALATE bar.

---

## Overall Assessment

This is a careful foundation with a security posture that is better than most first-cut persistence layers — the closed error union, the throw-on-empty slug guard, and the null-vs-throw discipline at the `CorpusFS` interface are all deliberate choices that will pay off across S2–S4. The change is also default-off, which bounds today's exposure to developers who opt in.

The concerns cluster in two places. First, the flag: "dev-only" is asserted in a comment and enforced by nothing, while the one mechanism that *would* be build-scoped (`NEXT_PUBLIC_CORPUS_FS`) is written in a form that probably never fires. Because S1 has no migration, flipping the flag makes existing work invisible — which turns a single-line same-origin write into durable damage. Adding a `NODE_ENV` guard is the highest-value change in this review.

Second, a consistent gap between what the comments promise and what the code enforces — the manifest codec documented as fail-loud that filters silently, the "single choke point" for paths that its first consumer bypasses, the "rate-limits writes" header that the corpus branch does not honor, the reified quota error that no caller catches. Individually these are Low-to-Medium. Collectively they matter more than their sum, because this module is explicitly the pattern that four later sub-tasks will copy: a comment that overstates its enforcement is a defect that replicates. Tightening them now, while the only consumer is a feature-flagged dev path, is far cheaper than after S4 migration puts real user corpora behind them.

---

## Goal-Alignment Note

- **Answered:** Design-level security review of `dc6dfb0..2dc403e` (`app/` only) at commit 2dc403e — trust boundary map across the new persistence substrate, feature-flag access control, the manifest deserialization boundary, OPFS path construction and traversal containment, error-path handling and swallowed failures, write concurrency/TOCTOU, and storage-durability/quota exhaustion. Thirteen findings reported at all severities down to Informational, each with a boundary label, cognitive move, and verbatim evidence.
- **Out of scope:** Correctness/architecture/performance critique except where it created a security consequence; re-verification of the merged code fact-check (used as foundation); `docs/working/**` in the range; any commit outside `dc6dfb0..2dc403e`; linter-level findings; test-file quality except as evidence of missing coverage for a finding. No fix loop was run — this is a measurement pass, so no code was modified.
- **Escalate:** None. No finding matches the five canonical HALT-ESCALATE patterns; finding 1 is the one a maintainer should read first, but it is a default-off dev flag and is reportable through the normal channel.
