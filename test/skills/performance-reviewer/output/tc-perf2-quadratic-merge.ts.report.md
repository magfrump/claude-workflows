> ⚠️ **No code fact-check report provided.** Performance claims in comments and documentation have not been independently verified. For full verification, run the `code-fact-check` skill first or use the code-review orchestrator.

# Performance Review: `subject.ts` (`importContacts` handler)

**Scope:** `subject.ts`, the whole file (37 lines), as the user asked
**Date:** 2026-11-19
**Based on:** Reading the code only. `./contactsRepo` is not in the repository, so I could not read how `listForUser` and `replaceForUser` work inside.

## Data Flow and Hot Paths

`POST /api/contacts/import` is an Express request handler. It:
1. Takes `incoming` (I rows parsed from a CSV the user exported from their CRM).
2. Loads all of the user's `existing` contacts (E rows) with `contactsRepo.listForUser`.
3. Merges the two lists in memory, matching on email with case ignored.
4. Writes the whole merged set back with `contactsRepo.replaceForUser`.

**Path temperature:** The endpoint runs for each request, but probably not often for any one user. Imports are occasional. What matters more is that the merge loop (lines 22–32) is synchronous CPU work on the Node event loop. While it runs, every other request served by that process waits. So its cost is paid by all traffic, not just the importer. I treat the merge loop as **hot** for that reason, and the repo round-trips as **warm**: they happen per request, at low frequency.

**Data sizes:** No size is enforced anywhere in this file. I depends on the body-parser `limit`, which isn't visible here. Express's `express.json()` defaults to 100 kB, which is roughly 1–2k contacts. CSV-import endpoints often raise that limit, though. **Verify data size.** E grows with every import and has no visible upper bound. CRM exports of 10k–100k contacts are realistic.

No measurements (profiles, dashboards, load tests) were provided, and none exist in the repo. **Every finding below is speculative.**

## Findings

#### 1. Quadratic merge: linear `findIndex` with per-comparison `toLowerCase()` inside the import loop

**Severity:** High (escalate to Critical if the body limit allows large uploads)
**Location:** `subject.ts:22-32` (specifically line 24)
**Move:** Count the hidden multiplications; Check the asymptotic behavior
**Classification:** Macro (O(I·(E+I)) algorithm) / Hot path (synchronous CPU that blocks the shared event loop)
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative

For each incoming contact, `merged.findIndex` does a linear scan of `merged`. Every new contact is pushed onto `merged`, so the array grows during the loop. The total work is about I·E + I²/2 comparisons. Each comparison also calls `c.email.toLowerCase()`, which allocates a new string. The same existing emails therefore get lowercased again and again, up to I times each, creating a lot of garbage-collection work.

Rough sizes:
- E = 20k, I = 20k: about 600M comparisons and string allocations. That is seconds to tens of seconds of blocked event loop.
- E = I = 100k: tens of billions of operations. The request effectively never finishes, and all other requests on that worker stall.

There is no cap on either input, so one large upload (malicious or not) can freeze a worker.

**Recommendation:** Before the loop, build a `Map<string, number>` from normalized email to index in `merged`. Normalize once per existing contact with `trim().toLowerCase()`. Look up incoming emails with `map.get`, and call `map.set` when you push a new contact. This makes the merge O(E + I). Also set an explicit maximum row count and body size for this endpoint, and reject larger requests with 413 or route them to a background job.

#### 2. Full read and full rewrite of the user's whole contact set on every import

**Severity:** Medium
**Location:** `subject.ts:16`, `subject.ts:34`
**Move:** Check the database interaction pattern (overfetching / write amplification); Trace the memory lifecycle
**Classification:** Macro (cost grows with E, not with the number of changes) / Warm path (per request, infrequent per user)
**Confidence:** Medium. I couldn't read `contactsRepo`, so the database-side cost depends on how `replaceForUser` is implemented.
**Baseline:** no baseline available — flagged as speculative

Every import loads all E existing contacts into memory and then writes all E + added rows back. This happens even when the import changes nothing, or changes one row. If `replaceForUser` is a delete-all plus bulk-insert (common for "replace" APIs), each import costs O(E) row writes, index updates, and log volume. Memory also holds `existing`, a shallow copy in `merged`, and new spread objects for every updated row. All of that is held across two awaits.

Because this is a read-modify-write with no locking or version check, two concurrent imports for the same user also race. Whichever finishes last wins, and the other import's changes are lost. If `replaceForUser` runs in a transaction, that transaction holds locks across a write the size of the full set. **Verify how `replaceForUser` is implemented.**

**Recommendation:** Track only the rows that were added or changed in the merge. Write them with a bulk upsert keyed on `(user_id, lower(email))`, backed by a unique index. That makes writes O(changes) and lets the database handle concurrent imports. Ideally, push the whole merge into the database (`INSERT ... ON CONFLICT ... DO UPDATE WHERE excluded.updated_at > contacts.updated_at`), so `existing` never needs to be loaded at all.

#### 3. Existing emails are lowercased but not trimmed, so the merge can miss matches and duplicates accumulate

**Severity:** Low
**Location:** `subject.ts:23-24`
**Move:** Ask "what's the size of N?" (growth rate of E)
**Classification:** Macro (E grows without bound over repeated imports) / Warm path
**Confidence:** Medium
**Baseline:** no baseline available — flagged as speculative

Incoming emails are trimmed and lowercased (line 23). Existing emails are only lowercased (line 24). Any stored email with surrounding whitespace, for example from rows written by another code path, will never match. Each re-import then adds a duplicate. This is mainly a correctness bug, but it also makes E grow with every import, which feeds the cost in Findings 1 and 2.

**Recommendation:** Use one `normalizeEmail` function on both sides, which the Map from Finding 1 does naturally. Enforce uniqueness in the database with a unique index on the normalized email.

## Endorsements

None. Nothing in this diff is a performance pattern I can endorse with evidence.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Quadratic `findIndex` + per-comparison `toLowerCase()` in merge loop blocks event loop | High (→ Critical if body limit is large) | `subject.ts:22-32` | High |
| 2 | Full read + full rewrite of user's contacts on every import; lost-update race | Medium | `subject.ts:16,34` | Medium |
| 3 | Inconsistent email normalization causes duplicate growth of E | Low | `subject.ts:23-24` | Medium |

## Overall Assessment

The handler is fine for small inputs, but it will hit a performance cliff. The main problem is Finding 1: an O(I·(E+I)) merge that runs synchronously on the event loop with no size limit on the input. A single large CRM export can freeze a Node worker and delay every request it serves. The fix is local and cheap: build a Map keyed on normalized email, and cap the upload size. Finding 2 is a structural problem: the endpoint rewrites the entire contact set. Moving to an upsert of only changed rows would fix the write amplification and the concurrent-import race together.

None of these findings have been measured. Before and after the fix, time one import with realistic E and I (say 10k × 10k) and record event-loop lag, for example with `perf_hooks.monitorEventLoopDelay`. Also check the configured body-parser limit and how `contactsRepo.replaceForUser` is implemented, since both change the severity of Findings 1 and 2.
