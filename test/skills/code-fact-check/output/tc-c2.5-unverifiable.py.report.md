# Code Fact-Check Report

**Repository:** /tmp/tmp.NZImXKaOs8
**Scope:** subject.py
**Checked:** 2026-11-20
**Total claims checked:** 3
**Summary:** 1 verified, 0 mostly accurate, 0 stale, 0 incorrect, 2 unverifiable

---

## Claim 1a: "the compiled module is not in this repo"

**Location:** `subject.py:4`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether a `ringbuf` module or file exists anywhere in the working tree. It does not establish whether `ringbuf` is installed in any Python environment.

The import is `from ringbuf import SpscRing` (`subject.py:4`). The only file that mentions `ringbuf` or `SpscRing` is `subject.py` itself. A search for `**/*ringbuf*` found no files (paraphrased — no quote available because the claim is about something missing, shown by grep/glob returning nothing).

**Evidence:** `subject.py:4`; repo-wide grep for `ringbuf|SpscRing` and glob `**/*ringbuf*`

---

## Claim 1b: "vendored wheel"

**Location:** `subject.py:4`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers whether the repo contains a wheel file or a packaging manifest that refers to one. It does not establish where `ringbuf` actually comes from at runtime.

The repo has no `*.whl` file, `requirements*.txt`, `pyproject.toml`, `setup.py` or `setup.cfg` that would show where the wheel comes from or which version is used (paraphrased — no quote available because the claim is about something missing: the glob returned no files). To verify this you would need the wheel itself or the place it is installed from.

**Evidence:** glob `**/{requirements*.txt,pyproject.toml,setup.py,setup.cfg,*.whl}` (no matches)

---

## Claim 2: "SpscRing is lock-free and safe with one producer thread and one consumer thread running at the same time, so the ring needs no lock."

**Location:** `subject.py:9-10`
**Type:** Invariant / Behavioral
**Verdict:** Unverifiable
**Confidence:** High
**Verification mode:** static
**Scope:** Covers how `EventPump` uses `self._ring` (`subject.py:7-30`). It does not establish that `SpscRing` is actually lock-free or safe with one producer and one consumer. It also does not establish that callers stick to one thread calling `push` and one calling `drain`. Nothing in `EventPump` enforces that, and the repo has no callers to check.

Both parts of this sentence get Unverifiable, so I did not split it.

**Mechanism (what SpscRing guarantees):** `SpscRing` comes from a compiled module that is not in the repo (see Claim 1a), so I could not read or run its implementation. Checking lock-freedom and single-producer/single-consumer safety would need the `ringbuf` source or binary and a concurrency stress test. The blocker is that the dependency is missing.

**Conclusion ("the ring needs no lock"):** This only holds if `EventPump` really has one producer and one consumer. The class does not enforce that. Both ring operations are public methods with no lock around them:

```python
# subject.py:19-20
def push(self, payload: bytes) -> bool:
    return self._ring.try_push(payload)
```

```python
# subject.py:22-30
def drain(self) -> int:
    count = 0
    while (payload := self._ring.try_pop()) is not None:
        with self._handlers_lock:
            handlers = list(self._handlers)
        for handler in handlers:
            handler(payload)
        count += 1
    return count
```

`_handlers_lock` (`subject.py:13`) only protects the handler list, not `try_push` or `try_pop`. Several threads calling `push`, or several calling `drain`, would break the single-producer/single-consumer condition the comment depends on. The repo contains no callers of `EventPump`, `push` or `drain` (paraphrased — no quote available because the grep for those names returned only their definitions in `subject.py`), so I could not tell whether real usage meets that condition.

**Evidence:** `subject.py:4`, `subject.py:9-13`, `subject.py:19-30`; repo-wide grep for `EventPump|\.push\(|\.drain\(`

---

## Claims Requiring Attention

### Unverifiable
- **Claim 1b** (`subject.py:4`): there is no wheel or packaging manifest in the repo. Checking "vendored wheel" needs the wheel or the place it is installed from.
- **Claim 2** (`subject.py:9-10`): needs the `ringbuf`/`SpscRing` source or binary and a concurrency test. Even if `SpscRing` is safe, "needs no lock" only holds if callers use one thread for `push` and one for `drain`, and `EventPump` does not enforce this.

---

**Notes:**
- `docs/reviews/hallucination-patterns.md` does not exist. No claim was Incorrect, so there was nothing to add to it and I did not create it.
- I only had read/search tools, so I could not write the report to `docs/reviews/code-fact-check-report.md` or run any Python checks. The report above is the full output; save it to that path if you want it kept.
