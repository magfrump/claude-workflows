# Code Fact-Check Report

**Repository:** /tmp/tmp.H2OgyuHG8o
**Scope:** subject.py
**Checked:** 2026-11-19
**Total claims checked:** 1
**Summary:** 0 verified, 0 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

---

## Claim 1: "thread-safe due to GIL"

**Location:** `subject.py:7`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `TaskQueue`'s own methods (`__init__`, `submit`, `process`, `get_result`) under concurrent callers, and whether the GIL is what provides their safety. It does not establish whether user-supplied `fn` callables are thread-safe, and it does not cover memory-model behaviour on free-threaded (no-GIL) CPython builds beyond what the explicit locks give.

This comment makes two claims: a mechanism ("due to GIL") and a conclusion ("thread-safe"). The code contradicts both, so they share the verdict Incorrect and I have not split them.

**The mechanism is wrong.** The class does not rely on the GIL. It uses `queue.Queue`, which has its own internal lock, and an explicit `threading.Lock` around the shared dict:

```python
# subject.py:10-12
self._queue = queue.Queue()
self._results = {}
self._lock = threading.Lock()
```

```python
# subject.py:21-22
with self._lock:
    self._results[task_id] = result
```

```python
# subject.py:24-26
def get_result(self, task_id):
    with self._lock:
        return self._results.get(task_id)
```

Whatever safety these methods have comes from those locks. The GIL does not make compound operations atomic. It only switches threads between bytecodes, and that is exactly the gap the next point depends on. A reader who believes "the GIL makes this safe" could reasonably delete `self._lock`, or write similar code elsewhere without locks, and would be misled.

**The conclusion fails for concurrent `process()` callers.** `process()` checks whether the queue is empty and then takes an item as two separate steps:

```python
# subject.py:17-22
def process(self):
    while not self._queue.empty():
        task_id, fn, args = self._queue.get()
        result = fn(*args)
        with self._lock:
            self._results[task_id] = result
```

(excerpt covers all of `process()`, read through `:22`)

`self._queue.get()` is called with no `block=False` and no `timeout`, so it blocks until an item arrives. Here is one way it goes wrong when one item is queued and threads A and B both call `process()`:

1. A calls `empty()` and gets `False`.
2. B calls `empty()` and gets `False`.
3. B calls `get()` and takes the item.
4. A calls `get()` on an empty queue and blocks forever, unless someone calls `submit()` later.

(paraphrased — no quote available because this is a Python stdlib guarantee, not code in this repo) The `queue` module docs say that `empty()` returning `False` does not guarantee that a later `get()` won't block.

So the class is not thread-safe against concurrent `process()` calls: a worker can hang. The dict accesses and the `submit()`/`get_result()` pair are safe, but the locks make them safe, not the GIL.

**Evidence:** `subject.py:7`, `subject.py:10-12`, `subject.py:14-15`, `subject.py:17-22`, `subject.py:24-26`

---

## Claims Requiring Attention

### Incorrect
- **Claim 1** (`subject.py:7`): The class's safety comes from `queue.Queue`'s internal lock and the explicit `self._lock`, not from the GIL. Also, `process()` checks `empty()` and then calls a blocking `get()` as separate steps, so a thread calling `process()` alongside another can block forever. The comment overstates both the mechanism and the guarantee.

---

**Notes:**
- No `docs/reviews/hallucination-patterns.md` existed. This finding doesn't qualify for that log, because it gives the wrong reason for the safety rather than naming a symbol or API that doesn't exist. So I didn't create the file.
- I only had read-only tools in this session, so I couldn't run a reproduction or save the report to `docs/reviews/code-fact-check-report.md`. Above is the full report text to save there.
- The fixture header (`subject.py:1-2`) says it expects an **Unverifiable** verdict. I gave **Incorrect** because the code gives a concrete example of the failure (the `empty()`/`get()` race) and the safety comes from the explicit locks, not the GIL. Neither depends on runtime state that only running the code would reveal.
