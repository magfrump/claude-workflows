# Code Fact-Check — Submitted Claims (Stage 2.5)

**Commit:** 2dc403e
**Scope:** `git diff dc6dfb0...HEAD` — DD-009 corpus storage seam (`app/lib/corpus/*.ts`, `app/lib/stores/workspaceStore.ts`)
**Clone:** `/workspace/external/cc-review-eval/mfc-corpus` (branch `review`, HEAD `2dc403e`, working tree clean)
**Date:** 2026-08-18
**Intake:** 3 routed endorsement claims — 1 from security-reviewer (`route: code-fact-check`), 2 from performance-reviewer (`[unverified — submitted as claim]`). api-consistency, architecture, and tech-debt-triage reports carried no routing tags (swept — none present).

---

## Submitted Claims

### SC1 — OPFS unavailable-guard throws typed `CorpusError` before raw property access

**Submitting critic:** security-reviewer (Endorsement Claim 1, `route: code-fact-check`)
**Claim:** The OPFS unavailable-guard throws a typed `CorpusError{kind:"unavailable"}` from `getRoot()` before any raw property access on `navigator.storage`, so a read in an SSR/unsupported-browser context fails with a typed error rather than a raw `TypeError`.
**Location:** `app/lib/corpus/opfsAdapter.ts:49-55,85-105`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed (covered by merged-report verdict)
**Scope:** This claim is the CorpusFS null/throw contract already verdicted in the canonical merged report as **Claim 8 (Verified, executed)**. The guard at `opfsAdapter.ts:50-53` reads `navigator.storage` behind a `typeof navigator !== "undefined"` check and validates `typeof storage.getDirectory === "function"` before any use, throwing `CorpusError{kind:"unavailable"}` prior to any raw property dereference. Verified breadth: `readFile` was **executed** under jsdom (no `navigator.storage`) and rejected with `{kind:"unavailable"}`, not a `TypeError`. The same `getRoot()` front guards `writeFile`/`readdir`/`rm`/`stat`, so the contract generalizes by static inspection — but only `readFile` was actually exercised (the security critic's own "Not verified" note is preserved: the other four methods share the front but were not each run). Not covered: whether the store consumer surfaces the typed error rather than dropping it (a separate downstream error-handling finding, out of this claim's scope).
**Evidence:** merged `code-fact-check-report.md` Claim 8; captured executed output `./evidence/r1-scratch-vitest.txt` (`R1_OPFS_ERR`). No new execution needed — cited and scoped to the existing executed verdict.

---

### SC2 — persist middleware does not await the prior async `setItem` → concurrent OPFS writes in flight (D5 write-race)

**Submitting critic:** performance-reviewer (Submitted claim 1, `[unverified — submitted as claim]`; backbone of Finding 2, the lost-update ordering hazard)
**Claim:** The zustand persist middleware dispatches `setItem` on each persisted-state mutation without awaiting the prior async `setItem`, so two OPFS writes to the same key can be in flight simultaneously.
**Location:** `node_modules/zustand/esm/middleware.mjs:358-374` (persist wiring); `app/lib/corpus/storeAdapter.ts:61-63` (adapter `setItem`); `app/lib/corpus/opfsAdapter.ts:107-123` (`writeFile`)
**Type:** Concurrency / performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed (+ corroborating static trace)
**Scope:** Covers that zustand@**5.0.13** persist fires `storage.setItem` fire-and-forget with no cross-call await, queue, or lock, so two `set()` calls issued closer together than one `writeFile` round-trip overlap against the same key. Does not (and need not) reproduce a *real* OPFS lost update in a browser — the interleave is the necessary-and-sufficient condition and it is demonstrated directly.

**Static trace (decisive on its own):** persist wraps `set` at `middleware.mjs:365-377`:
```js
const setItem = () => { const state = options.partialize({ ...get() });
  return storage.setItem(options.name, { state, version: options.version }); };
const savedSetState = api.setState;
api.setState = (state, replace) => { savedSetState(state, replace); return setItem(); };
config((...args) => { set(...args); return setItem(); }, get, api);
```
Each `set()` synchronously mutates state then calls `setItem()` → `storage.setItem(...)`, **returning** the async storage promise but never awaiting the prior one and never chaining successive calls. The app's adapter `setItem` is `await fs.writeFile(...)` (`storeAdapter.ts:62`), and `writeFile` is a 6-await OPFS sequence (`getRoot`→`getDirectoryHandle`→`getFileHandle`→`createWritable`→`write`→`close`) with no per-key lock. Two back-to-back `set()` calls therefore launch two overlapping `writeFile` sequences on the same `state/workspace-zustand-v1.json`; completion order is not guaranteed to match issue order → classic lost update.

**Executed (mandatory execution):** probe `./evidence/sc-writerace-probe.mjs` builds a real persist store on the clone's zustand, backs it with a `StateStorage` whose `setItem` mirrors `createCorpusBackedStorage` (async, multi-await slow body, no queue), fires two synchronous `set()` calls with no await between them (two keystrokes), and instruments in-flight overlap. Output `./evidence/sc-writerace-probe.txt`:
```
ENTER writeFile #1 value=1 inFlight=1
ENTER writeFile #2 value=2 inFlight=2      <- #2 enters before #1 exits
EXIT  writeFile #1 value=1 inFlight=1
EXIT  writeFile #2 value=2 inFlight=0
maxConcurrent writeFile sequences in flight: 2
VERDICT: CONFIRMED — persist does NOT await the prior setItem before firing the next.
```
`maxConcurrent = 2` confirms the overlap. **The D5 / write-race claim verifies.**
**Evidence:** `middleware.mjs:358-377`, `storeAdapter.ts:56-63`, `opfsAdapter.ts:107-123`; executed `./evidence/sc-writerace-probe.mjs` → `./evidence/sc-writerace-probe.txt` (exit 0).

---

### SC3 — one editor keystroke produces one persist `setItem`

**Submitting critic:** performance-reviewer (Submitted claim 2, `[unverified — submitted as claim]`; the frequency multiplier in Finding 1, write amplification)
**Claim:** In the editor panels, a single keystroke mutates a persisted field (`sourceText`/`semiformalText`), producing one persist `setItem` per keystroke.
**Location:** `app/components/features/source-input/TextInput.tsx:17`; `app/components/panels/{InputPanel,SourcePanel}.tsx`; `app/page.tsx:105,814`; `app/lib/stores/workspaceStore.ts:321,324,511-526`; `node_modules/zustand/esm/middleware.mjs:366-374`
**Type:** Data-flow / performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static (full path traced; complete and decisive)
**Scope:** Traces the controlled-input keystroke chain end to end. `TextInput` is an uncontrolled-per-keystroke textarea: `onChange={(e) => onChange(e.target.value)}` (`TextInput.tsx:17`) — fires every keystroke, no editor-level debounce/throttle/deferral (grepped: none). `InputPanel`/`SourcePanel` forward it as `onChange={onSourceTextChange}`; `page.tsx:814` binds `onSourceTextChange={setSourceText}` where `setSourceText = useWorkspaceStore((s) => s.setSourceText)` (`page.tsx:105`). The store setter is `setSourceText: (v) => set({ sourceText: v })` (`workspaceStore.ts:321`); `setSemiformalText` similarly at `:324`. Both `sourceText` and `semiformalText` are in `partialize` (`:512,515`), so each `set()` triggers the persist wrapper (`middleware.mjs:373`) → exactly one `setItem` per keystroke. On the ON path that `setItem` is one un-debounced `writeFile` (no coalescing, contrast the OFF-path 300 ms debounce at `storeAdapter.ts:29-39`). The chain is a couple of hops outside the reviewed diff (editor components, `page.tsx`) but is fully readable and unbroken; no execution was required to close it.
**Evidence:** `TextInput.tsx:17`, `InputPanel.tsx:63`, `SourcePanel.tsx:19`, `page.tsx:105,814`, `workspaceStore.ts:321,324,511-526`, `middleware.mjs:366-374`.

---

## Verdict summary

| Claim | Submitting critic | Verdict | Mode |
|---|---|---|---|
| SC1 — unavailable-guard throws typed `CorpusError` before raw access | security-reviewer | Verified | executed (via merged Claim 8) |
| SC2 — persist un-awaited `setItem` → concurrent OPFS writes (D5 write-race) | performance-reviewer | Verified | executed (+ static) |
| SC3 — one keystroke = one persist `setItem` | performance-reviewer | Verified | static (complete chain) |

All three routed endorsement claims are **Verified** — admissible as backing for ✅ rows per provenance rule 5, each carrying its verification mode and scope. None refuted; none unverifiable. The **D5 / un-awaited-setItem write-race claim verifies** by executed probe (`maxConcurrent=2`) corroborated by the zustand@5.0.13 persist source trace.

**Clone left pristine:** `git status` clean; all new artifacts written only under `runs/review-arms/e8-evidence-pipeline/mfc-corpus/evidence/` (`sc-` prefix).
