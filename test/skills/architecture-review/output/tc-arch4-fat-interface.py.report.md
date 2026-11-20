# Architecture Review — subject.py (media library storage port and clients)

**Scope:** `subject.py`, a concatenation of five modules: `media/ports/storage.py`, `media/application/thumbnails.py`, `media/application/archive_browser.py`, `media/infrastructure/mirror_store.py`, `media/main.py`
**Date:** 2026-11-19
**User goal:** Judge whether this change keeps the codebase structurally sound.

> ⚠️ **No code fact-check report provided.** Architectural claims in comments and documentation have not been independently verified. For full verification, run the `code-fact-check` skill first or use the code-review orchestrator.

**Scope check:** In scope. The change adds a new port (public API / abstract protocol), new application and infrastructure modules (module structure), and a composition root (cross-cutting DI wiring).

**Trust-boundary cross-reference:** Not active. There is no `docs/reviews/security-review-*.md` in the repository.

---

## Dependency Map

```
media/main.py  (composition root)
   ├──► media/application/archive_browser.py ──► media/ports/storage.py (BlobStore)
   └──► media/infrastructure/mirror_store.py      (satisfies BlobStore structurally; no import)

media/application/thumbnails.py ──► media/ports/storage.py (BlobStore)
```

Dependencies point the right way. Application modules import only the port. The infrastructure adapter imports nothing from the application or port layers (it matches `Protocol` structurally). Only `main.py` knows about concrete adapters. No cycles. The problems are in the **shape of the port**, not in which way the imports point.

| Consumer / implementor | BlobStore methods actually used or supported |
|---|---|
| `ArchiveBrowser` | `list`, `get` (2 of 15) |
| `ThumbnailGenerator` | `get`, `put` (2 of 15) |
| `ReadOnlyMirrorStore` | implements `get`, `exists`, `list`; 12 of 15 raise `NotImplementedError` |

---

## Findings

#### 1. `BlobStore` is a 15-method fat interface that no consumer needs and the only shown adapter can't fulfil

**Severity:** Coupling
**Location:** `subject.py:16-31` (`media/ports/storage.py`)
**Move:** #5 Interface segregation
**Confidence:** High

Each of the two use cases needs only two methods, yet both depend on a port with fifteen: ACLs, presigned URLs, multipart upload, lifecycle rules and usage accounting. As a result, every new adapter (an in-memory test fake, a local filesystem store, a CDN-backed reader) has to provide all fifteen methods or stub them out. `ReadOnlyMirrorStore` stubs twelve of them with `NotImplementedError` (`subject.py:91-125`), which is exactly the sign of an interface that is too broad. It also means a change to any rarely-used method, such as adding a `storage_class` parameter to `start_multipart`, touches every implementor and every test double, even though nothing in the application calls it.

**Recommendation:** Split the port into small role protocols: `BlobReader` (`get`, `exists`, `list`) and `BlobWriter` (`put`, `delete`), plus separate optional capabilities (`AclManager`, `PresignedUrls`, `MultipartUploads`, `LifecyclePolicy`, `UsageReporter`). Introduced only when a use case needs them. Then `ArchiveBrowser` depends on `BlobReader`, and `ThumbnailGenerator` on a combined `class ReadWriteBlobStore(BlobReader, BlobWriter, Protocol)`.

#### 2. `ReadOnlyMirrorStore` passes type checks as a `BlobStore` but isn't substitutable for one

**Severity:** Coupling
**Location:** `subject.py:73-125` (`media/infrastructure/mirror_store.py`), interacting with `subject.py:38-47`
**Move:** #6 Substitutability
**Confidence:** High

Because `BlobStore` is a structural `Protocol` and the mirror defines every method, a type checker treats `ReadOnlyMirrorStore` as a full `BlobStore`. But it weakens the contract: `put`, `delete` and ten other methods always throw. Nothing in the types stops someone from writing `ThumbnailGenerator(ReadOnlyMirrorStore(...), resize)` in `main.py`. That code type-checks cleanly and fails only at runtime, the first time `generate()` calls `put`. Read-only is a real property of this adapter, but the type system has been told the opposite. Today the composition root happens to wire it only into `ArchiveBrowser`, so correctness depends on a convention rather than on the structure.

**Recommendation:** After splitting the port (Finding 1), have `ReadOnlyMirrorStore` implement only `BlobReader` and delete the twelve stubs. Passing it to a writer-requiring use case then becomes a type error instead of a runtime crash.

#### 3. The port is shaped like the S3 adapter, not like what the application needs

**Severity:** Coupling
**Location:** `subject.py:24-31`
**Move:** #1 Dependency direction / #3 Module boundary
**Confidence:** Medium

In ports-and-adapters, the application side owns the port and describes its needs in domain terms. Methods like `set_acl(key, acl: str)`, `presigned_url`, `start_multipart`/`upload_part`/`complete_multipart` with ETags, and `set_lifecycle_rule(prefix, expire_after_days)` are S3 concepts and S3 API shapes. Putting them in `media/ports/` lets infrastructure vocabulary leak into the stable layer. The imports point the right way, but the abstraction itself depends on details. Swapping S3 for GCS, Azure Blob or a database-backed store would mean either emulating S3 semantics (ETag lists, string ACLs) or changing the port and therefore every consumer. The S3 adapter mentioned in the header comment isn't in the reviewed file, so I'm inferring this from naming, hence Medium confidence.

**Recommendation:** Keep only the operations the use cases need in the core port(s). If upload chunking or access control becomes an application need, model it in domain terms (e.g. `put_stream(key, chunks)`, `make_public(key)`) and let the S3 adapter translate.

#### 4. `ThumbnailGenerator`'s `resize` dependency is untyped and implicit

**Severity:** Minor
**Location:** `subject.py:39-46`
**Move:** #3 Module boundary
**Confidence:** High

`BlobStore` is injected through an explicit port, but the image-resizing collaborator is an unannotated `resize` callable. Its contract (`(bytes, int) -> bytes`, output format JPEG) exists only in how it's called at line 46, and the hard-coded `"image/jpeg"` content type quietly couples the use case to whatever format the resizer emits. Replacing the resizer, for example with one that outputs WebP, would silently produce mislabelled blobs.

**Recommendation:** Define an `ImageResizer` protocol in `media/ports/` (e.g. `resize(data: bytes, max_px: int) -> tuple[bytes, str]` returning the content type), or at least annotate the parameter as `Callable[[bytes, int], bytes]`.

#### 5. Configuration is hard-coded in the composition root

**Severity:** Informational
**Location:** `subject.py:135-136`
**Move:** #2 Responsibility boundaries
**Confidence:** Medium

`build_archive_browser()` embeds `/srv/mirror`. Wiring belongs in the composition root, but a literal path means every environment (tests, staging, dev laptops) needs code changes or monkeypatching.

**Recommendation:** Pass the root path in (`build_archive_browser(mirror_root: Path)`) or read it from the app's config loader, keeping `main.py` as pure wiring.

*Out of scope, noted for other reviewers:* `ReadOnlyMirrorStore.get` joins untrusted keys onto `self._root` without containment checks (path traversal). That is a `security-reviewer` concern.

---

## What Looks Good

- **Correct dependency direction.** Application modules import only `media.ports.storage`. Neither use case knows about S3 or the filesystem.
- **Clean composition root.** `media/main.py` is the only place that names a concrete adapter, so swapping adapters is a one-line change.
- **Constructor injection everywhere.** Both use cases receive their collaborators, which makes them easy to test with fakes once the port is small enough to fake cheaply.
- **Infrastructure stays a leaf.** `mirror_store.py` imports only the standard library and doesn't depend on application code.
- **Use cases are focused.** `ThumbnailGenerator` and `ArchiveBrowser` each do one thing.

---

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `BlobStore` is a 15-method fat interface; consumers use 2 each | Coupling | `subject.py:16-31` | High |
| 2 | `ReadOnlyMirrorStore` type-checks as `BlobStore` but throws on 12/15 methods | Coupling | `subject.py:73-125` | High |
| 3 | Port is shaped like S3 (ACLs, multipart/ETags, lifecycle), not like application needs | Coupling | `subject.py:24-31` | Medium |
| 4 | `resize` dependency untyped; JPEG content type hard-coded | Minor | `subject.py:39-46` | High |
| 5 | Mirror path hard-coded in composition root | Informational | `subject.py:135-136` | Medium |

Rubric mapping: findings 1–3 → 🟡 Must Address; findings 4–5 → 🟢 Consider. No 🔴 Must Fix items.

---

## Overall Assessment

The overall structure is sound and the change mostly keeps it that way. The layers are real, dependencies point inward, and wiring stays in one composition root. The weak point is the port itself. `BlobStore` mirrors the S3 API instead of the application's needs, so the read-only mirror has to pretend it is a full store by stubbing twelve methods. That hides its read-only nature from the type system and invites runtime failures if someone miswires it. All of this can be fixed in place without restructuring. **The most important fix is to split `BlobStore` into role-specific protocols (at minimum `BlobReader` / `BlobWriter`).** That one change resolves Findings 1 and 2, mostly resolves Finding 3, and makes every future adapter and test double cheaper to write.
