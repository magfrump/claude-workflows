# Code Fact-Check Report

**Repository:** /tmp/tmp.uj0sc4xpdB
**Scope:** subject.py
**Checked:** 2026-11-19
**Total claims checked:** 4
**Summary:** 3 verified, 0 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

---

## Claim 1: "Function itself uses no shared state, but calls one that does"

**Location:** `subject.py:2`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the claim that `process_item`'s own body touches no module-level state and that its callee `increment_shared` changes a global. It does not say whether that pattern is unsafe (see Claim 2).

`process_item` only uses its parameter and a local:

```python
# subject.py:15-20
def process_item(item):
    """Process a single item. Thread-safe."""
    result = transform(item)
    # This call touches shared state — the claim is misleading in context
    increment_shared()
    return result
```

Its callee changes a module global:

```python
# subject.py:9-12
def increment_shared():
    global _shared_counter
    with _lock:
        _shared_counter += 1
```

`transform` (`subject.py:22-23`, `return item.upper()`) uses no module state.

**Evidence:** `subject.py:6-7`, `subject.py:9-12`, `subject.py:15-20`, `subject.py:22-23`

---

## Claim 2: "thread-safe" / "Process a single item. Thread-safe."

**Location:** `subject.py:14`, `subject.py:16`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `process_item` with `str` input: the only shared state it reaches (`_shared_counter`) is changed under `_lock`, and `transform` is pure. It does not cover inputs whose `.upper()` changes shared or mutable state, code outside `subject.py` that reads or writes `_shared_counter` without `_lock`, or making the transform and the counter increment happen as one atomic step.

The one shared-state change on this path is behind a lock:

```python
# subject.py:11-12
    with _lock:
        _shared_counter += 1
```

`_lock` is one module-level `threading.Lock()` (`subject.py:7`, `_lock = threading.Lock()`), so every caller uses the same lock. In this file, nothing touches `_shared_counter` outside that `with _lock:` block (paraphrased — no quote available because this is about missing code: the only references are the definition at `subject.py:6` and the locked increment at `subject.py:10-12`).

`transform` is `return item.upper()` (`subject.py:23`). For `str` this returns a new object and changes no state, so it is safe to run from many threads. If `item` is some other type, thread safety depends on that type's `.upper()`, which this file cannot show (paraphrased — no quote available because the caller decides the type of `item`, and this file has no type annotation or call site).

The fixture header (`subject.py:2`) and the comment at `subject.py:18` suggest the claim should fail because a shared-state callee is involved. But the callee guards its own change correctly, so calling it does not make `process_item` unsafe.

**Evidence:** `subject.py:6-7`, `subject.py:9-12`, `subject.py:14-20`, `subject.py:22-23`

---

## Claim 3a: "This call touches shared state"

**Location:** `subject.py:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the claim that `increment_shared()` changes module-level state. It does not say whether that change is synchronized (see Claim 3b).

`increment_shared` declares `global _shared_counter` and increments it (`subject.py:10-12`):

```python
# subject.py:10-12
    global _shared_counter
    with _lock:
        _shared_counter += 1
```

**Evidence:** `subject.py:9-12`, `subject.py:19`

---

## Claim 3b: "the claim is misleading in context"

**Location:** `subject.py:18`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the claim that touching shared state through `increment_shared` makes the "Thread-safe" docstring misleading. It does not cover non-`str` inputs to `transform` or unlocked access to `_shared_counter` from other modules, which are the leftover cases in Claim 2.

This comment says the "Thread-safe" claim is misleading because of the shared-state call. But that call does all its shared-state work inside `with _lock:`:

```python
# subject.py:11-12
    with _lock:
        _shared_counter += 1
```

The read-modify-write of `_shared_counter` is serialized across threads, so a race cannot happen through this path. Calling a function that touches shared state does not make the caller unsafe when the callee synchronizes properly. A reader who believes this comment might add locking to `process_item` that isn't needed, or treat it as unsafe when it isn't.

**Evidence:** `subject.py:7`, `subject.py:9-12`, `subject.py:16-19`

---

## Claims Requiring Attention

### Incorrect
- **Claim 3b** (`subject.py:18`): The comment says the "Thread-safe" docstring is misleading, but `increment_shared` changes `_shared_counter` under `_lock`, so the call doesn't break thread safety. The precise version: the call touches shared state, which is lock-protected.

---

**Notes:**
- The two "thread-safe" claims (lines 14 and 16) hold for `str` input. The comment at line 18 that calls them misleading is the one that's wrong.
- There was no `docs/reviews/hallucination-patterns.md` to check against. I didn't create one because the Incorrect finding isn't a made-up symbol or API.
- I couldn't save the report to `docs/reviews/code-fact-check-report.md` because I don't have a file-writing tool here, so it's only in this message.
- All verdicts come from reading the code. I had no way to run it.
