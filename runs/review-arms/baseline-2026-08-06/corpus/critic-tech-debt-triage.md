Commit: 2dc403e

# Tech-Debt Triage — Corpus FS/OPFS storage layer (advisory, green/Consider tier)

Scope: `git diff dc6dfb0..2dc403e -- app/` (15 files, all net-new corpus module + one workspaceStore seam swap). This is S1 of the multi-stage DD-009 corpus effort; several modules are intentionally built ahead of use. Findings below are ergonomic/legibility debt, not blockers. No High-severity carrying cost identified.

---

## Triage Summary

| # | Debt Item | Carrying Cost | Cost of Deferral | Failure Cost | Fix Cost | Urgency | Recommendation |
|---|-----------|:---:|:---:|:---:|:---:|:---:|---|
| 1 | Duplicated sanitization chain in `workspaceSlug`/`safeSegment` (path-safety guard) | Medium | +1 divergence risk per guard change | Low × High — traversal escape if the two copies drift | Hours | On next path-safety change | Fix opportunistically |
| 2 | Built-but-unused forward code (manifest.ts, most of paths.ts, worker-error + future error kinds) | Low | +0 — inert until S2/S4 | | Days (deletion not wanted) | S4 wires it in | Carry intentionally |
| 3 | Misleading `writeFile` comment — "fresh ArrayBuffer view" but no copy made | Low | +0 — inert | | Minutes | None | Fix now (trivial) |
| 4 | Stale cross-file line reference `workspaceStore.ts:44-46` in opfsAdapter header | Low | +1 stale ref per file move | | Minutes | None | Fix now (trivial) |
| 5 | Stale docstrings: `browser-storage-cleared` in manifest header; `layout.ts` in storeAdapter header | Low | +0 — inert | | Minutes | None | Fix opportunistically |
| 6 | Fail-loud codec silently `filter()`s malformed array entries before validating | Low | +0 — inert | Low × Med — silent data drop masks manifest corruption | Hours | None | Defer and monitor |

---

## Findings (tagged)

### 1. Duplicated path-safety sanitization logic
- **Severity:** Consider (green) — but the highest-value item here because it sits on the traversal-guard path.
- **Location:** `app/lib/corpus/paths.ts:34-50` (`workspaceSlug` and `safeSegment`).
- **Evidence:** Both run the same chain:
  `workspaceSlug`: `.normalize("NFKD").replace(SAFE_SEGMENT, "-").replace(/-{2,}/g, "-").replace(/^-+|-+$/g, "").toLowerCase()`
  `safeSegment`: `id.normalize("NFKD").replace(SAFE_SEGMENT, "-").replace(/-{2,}/g, "-").replace(/^-+|-+$/g, "")` — identical minus `.toLowerCase()` and the error message.
- **Confidence:** High.
- **Legibility-target:** Extract a shared `sanitizeSegment(input, { lowercase })` helper (or have `workspaceSlug` call `safeSegment` then lowercase) so the traversal guard lives in exactly one place. Today a hardening change to one must be manually mirrored to the other; the module docstring's "single choke point" claim (fact-check Claim 12) is already only true per-segment.

### 2. Forward-built, currently-dead code
- **Severity:** Consider (green).
- **Location:** `app/lib/corpus/manifest.ts` (entire file), most of `app/lib/corpus/paths.ts` builders (`sourcePath`, `artifactVersionPath`, `customTypePath`, `decomposition*`), and `app/lib/corpus/types.ts` future surface (`CorpusWorkerError`, `toWorkerError`, `isCorpusWorkerError`, error kinds `fsa-permission-revoked`/`remote-auth-expired`/`browser-storage-cleared`/`git-conflict`, substrates `"fsa"`/`"remote"`).
- **Evidence:** `storeAdapter.ts:10-12`: "the files-per-artifact folder layout (layout.ts/manifest.ts) is built but not used by the store until S4." S1 storeAdapter uses blob mode (`state/<name>.json`), not the folder layout.
- **Confidence:** High.
- **Legibility-target:** None required — this is deliberate seam-ahead-of-use with tests, `+0 inert`. Carry intentionally; do NOT delete. Flagged only so a future reviewer doesn't mistake it for accidental dead code. Revisit at S4.

### 3. Misleading `writeFile` comment (comment/code mismatch)
- **Severity:** Consider (green); matches fact-check Claim 8 (Incorrect).
- **Location:** `app/lib/corpus/opfsAdapter.ts:115-116`.
- **Evidence:** `// Pass a fresh ArrayBuffer view; some implementations dislike shared buffers.` immediately followed by `await w.write(bytes);` — `bytes` is the untouched parameter; no copy/slice/subarray. The in-memory fake copies via `slice()`, the OPFS adapter does not.
- **Confidence:** High.
- **Legibility-target:** Either drop the comment or actually pass `bytes.slice()` / a fresh view. As written it will mislead a future maintainer into believing shared-buffer safety is handled.

### 4. Stale cross-file line reference
- **Severity:** Consider (green); matches fact-check Claim 7 (Stale).
- **Location:** `app/lib/corpus/opfsAdapter.ts:13-14`.
- **Evidence:** Header says quota is "NOT swallowed with console.warn the way the legacy localStorage adapter does (workspaceStore.ts:44-46)." This same diff moved that `console.warn` to `storeAdapter.ts:35`; `workspaceStore.ts:44-46` now holds unrelated code.
- **Confidence:** High.
- **Legibility-target:** Repoint to `storeAdapter.ts:33-36`. Hard-coded line numbers in comments are a recurring drift source; prefer naming the function (`createDebouncedLocalStorage`) over line numbers.

### 5. Stale docstrings (nonexistent kind / nonexistent file)
- **Severity:** Consider (green); partly matches fact-check Claim 4.
- **Location:** `app/lib/corpus/manifest.ts:11-13` and `app/lib/corpus/storeAdapter.ts:10-11`.
- **Evidence:** manifest header claims parse errors surface as kind `"io" or "browser-storage-cleared"`, but `fail()` only ever throws `kind: "io"` (`manifest.ts:64-66`). storeAdapter header references `layout.ts` which does not exist in the tree (`git ls-tree` shows only flag/manifest/opfsAdapter/paths/storeAdapter/types).
- **Confidence:** High.
- **Legibility-target:** Drop `browser-storage-cleared` from the manifest contract note; drop or defer the `layout.ts` reference until that file exists.

### 6. Fail-loud codec silently drops malformed array entries
- **Severity:** Consider (green).
- **Location:** `app/lib/corpus/manifest.ts:88-108`.
- **Evidence:** The module docstring states parsing is "FAIL-LOUD ... never a silent default," yet `raw.sources.filter(isObject).map(...)`, `raw.artifacts.filter(isObject).map(...)`, and `raw.customTypeIds.filter((x): x is string => ...)` silently discard non-conforming entries before validating the survivors. A `sources` array of `[{valid}, 42]` parses to one source with no error, contradicting the fail-loud intent for the dropped element.
- **Confidence:** Medium (behavioral intent inferred from docstring).
- **Legibility-target:** Decide and document one policy — either fail on any non-conforming array element (consistent with the loud contract) or explicitly state in the docstring that non-object/non-string array entries are dropped. This file is unused until S4, so no urgency; note it before S4 wires the manifest into real reads.
