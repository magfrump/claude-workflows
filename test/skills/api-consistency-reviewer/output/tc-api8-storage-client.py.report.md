# API Consistency Review: `subject.py` (`StorageClient` object methods)

**Scope:** `subject.py`. The diff is lines 54–76, the `BEGIN/END CHANGE UNDER REVIEW` block that adds `get_object`, `list_objects` and `delete_object`. Everything else in the file is the baseline.
**Date:** 2026-11-19

> ⚠️ **No code fact-check report provided.** The API documentation claims haven't been checked against the implementation separately. For full verification, run the `code-fact-check` skill first or use the code-review orchestrator.

> **Limit on what I could check:** The repository contains only `subject.py`. The modules it imports (`blobkit._transport`, `blobkit.errors`) aren't in the repo, and there are no tests, docs or callers to trace. So the baseline below comes only from the existing `Bucket`, `BlobObject` and `StorageClient` bucket methods in this file, and I couldn't check how `Transport.request` or `Transport.paginate` behave.

## Baseline Conventions

The existing code in `subject.py` (lines 1–53) sets these conventions:

- **Method naming:** `<verb>_<resource>` in snake_case. The verbs are `get_` for one resource, `list_` for a collection and `delete_` for removal: `get_bucket`, `list_buckets`, `delete_bucket`. `list_` takes the plural noun; `get_` and `delete_` take the singular.
- **Parameter ordering:** the identifying arguments come first and are positional (`name: str`). Filter and paging options are keyword-only after `*`: `prefix: Optional[str] = None`, `page_size: int = 100`.
- **Return types:**
  - `get_*` returns a frozen dataclass built with `Model(**resp.json())`.
  - `list_*` returns an `Iterator[Model]` by yielding items from `self._transport.paginate(...)`. Paging is hidden from the caller.
  - `delete_*` returns `None`.
- **Routes:** REST-style, plural collection paths. Collection: `/buckets`. Item: `/buckets/{name}`.
- **Errors:** a 404 raises `NotFoundError` with a message like `f"<resource> {id!r} not found"`. No other status codes are handled explicitly (that is left to the transport). Docstrings state "Raises NotFoundError if absent."
- **Data models:** the existing `BlobObject` dataclass (fields `bucket`, `key`, `size_bytes`, `etag`, `created_at`) refers to its parent bucket as `bucket` and its identifier as `key`.
- **Exports:** `__all__` lists the models and the client class. Methods are reached through `StorageClient`.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `get_object` | method | `get_bucket` | `subject.py:36` | Consistent: same `get_<singular>` pattern |
| `list_objects` | method | `list_buckets` | `subject.py:43` | Consistent: same `list_<plural>` pattern |
| `delete_object` | method | `delete_bucket` | `subject.py:48` | Consistent: same `delete_<singular>` pattern |
| `bucket` (param) | parameter | `BlobObject.bucket` field; `name` in bucket methods | `subject.py:25`, `subject.py:36,48` | Consistent: matches the `BlobObject.bucket` field name. Using `name` only in the bucket's own methods makes sense because there it names the resource itself |
| `key` (param) | parameter | `BlobObject.key` field | `subject.py:26` | Consistent: same as the model field |
| `prefix` (kw-only param on `list_objects`) | parameter | `list_buckets(prefix=...)` | `subject.py:43` | Consistent: same name, type, default and keyword-only placement |
| `page_size` (kw-only param on `list_objects`) | parameter | `list_buckets(page_size=100)` | `subject.py:43` | Consistent: same name, type and default (100) |
| `GET/DELETE /buckets/{bucket}/objects/{key}` | route | `GET/DELETE /buckets/{name}` | `subject.py:38,50` | Consistent: plural collection with an ID segment, nested under the parent resource |
| `/buckets/{bucket}/objects` (paginated) | route | `/buckets` (paginated) | `subject.py:45` | Consistent: same collection-path shape and `paginate` call |

No new types, enum variants, error codes or events are introduced. `BlobObject` and `NotFoundError` already existed.

## Findings

#### Object keys are put into the URL path without encoding

**Severity:** Informational
**Location:** `subject.py:57`, `subject.py:67`, `subject.py:73`
**Move:** 3 (Trace the consumer contract)
**Confidence:** Low

The new methods build paths with `f"/buckets/{bucket}/objects/{key}"`. This copies the baseline (`f"/buckets/{name}"`, which doesn't encode either), so it is consistent. The difference is that object keys in blob stores often contain `/`, `?`, `#`, `%` or spaces, which bucket names usually don't. A key like `photos/2026/a.jpg` would produce a path with extra segments, and `?` or `#` would cut the path short.

Callers will reasonably expect `get_object(b, "a/b.txt")` to work. Whether it does depends on whether `Transport.request` encodes path segments, and I couldn't check that because `blobkit/_transport.py` isn't in the repo. This is a contract question, not a style difference.

**Recommendation:** Confirm whether `Transport` encodes path segments. If it doesn't, encode `key` with something like `urllib.parse.quote(key, safe="")` in the object methods. Also state in the `get_object` and `delete_object` docstrings that any string is accepted as a key.

#### `delete_object` raises on 404, so a retried delete fails

**Severity:** Informational
**Location:** `subject.py:71-75`
**Move:** 9 (Idempotency and safety)
**Confidence:** Medium

`delete_object` raises `NotFoundError` when the object is missing. That matches `delete_bucket` (`subject.py:48-52`), so it is consistent and correctly documented. The catch: if a delete succeeds on the server but the response is lost and the caller retries, the retry gets `NotFoundError`. This matters more for objects, which tend to be deleted in bulk or retry loops, than for buckets.

I'm not suggesting a change, since the code matches the baseline. I'm noting it so the team decides it on purpose.

**Recommendation:** Keep the behaviour the same as `delete_bucket`. If retry-safe deletes are wanted later, add the option to both methods together (for example a `missing_ok: bool = False` keyword) so they stay consistent.

## What Looks Good

- **Naming is consistent:** the three methods follow the existing `get_` / `list_` / `delete_` verbs and singular/plural rules exactly.
- **The signatures follow the baseline:**
  - Identifying arguments are positional and come first, parent before child (`bucket, key`).
  - `prefix` and `page_size` are keyword-only, with the same types and defaults as `list_buckets`.
- **Parameter names match the model:** `bucket` and `key` are the same as the `BlobObject` field names, so the request and response use the same terms.
- **Error handling matches:** a 404 raises `NotFoundError`, and the message has the same shape (`object 'k' not found in bucket 'b'` next to `bucket 'n' not found`). The docstrings use the same "Raises NotFoundError if absent." wording.
- **Pagination matches:** it goes through the same `Transport.paginate` call and is exposed as an `Iterator`, so callers see one paging model.
- **Routes match:** object routes are nested under the bucket path using the same plural-collection style.
- **Nothing breaks:** these are purely additive methods on an existing class. No existing signature, return type or exported name changes, so no version bump is needed. `BlobObject` was already exported, so `__all__` doesn't need updating.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Object keys are put into the URL path without encoding | Informational | `subject.py:57,67,73` | Low |
| 2 | `delete_object` raises on 404, so a retried delete fails | Informational | `subject.py:71-75` | Medium |

## Overall Assessment

The change is fully consistent with the client's existing API patterns. `get_object`, `list_objects` and `delete_object` copy their bucket counterparts in:

- method naming
- parameter order and keyword-only options
- defaults
- return types
- pagination
- 404 handling and error messages
- docstring wording

Their parameter names also match the existing `BlobObject` fields. There are no breaking changes, and there are no naming problems that would need a cited precedent. The two findings are informational. Finding 1 is worth a quick check before release, because the transport code needed to settle it isn't in the repo.
