I couldn't save the report: there's no file-writing tool in this session, so it's below in full instead of at `docs/reviews/code-fact-check-report.md`. Also, `docs/reviews/hallucination-patterns.md` doesn't exist, so there were no earlier patterns to compare against.

# Code Fact-Check Report

**Repository:** /tmp/tmp.WbVprb9dy8
**Scope:** subject.js
**Checked:** 2026-11-19
**Total claims checked:** 7
**Summary:** 4 verified, 2 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

Line 1 (`// Test fixture for TC-C5.2: ...`) is a label for the test fixture, so it wasn't checked.

---

## Claim 1: "Docstring says retries 3 times"

**Location:** `subject.js:2`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers only what the docstring at `subject.js:4-7` says; does not establish whether that statement is true of the code (see Claim 4a).

The docstring says this word for word:

```js
// subject.js:6
 * Retries 3 times before giving up.
```

**Evidence:** `subject.js:6`

---

## Claim 2: "but code retries 2 times (off-by-one)"

**Location:** `subject.js:2`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers how many times the loop in `fetchWithRetry` runs; does not establish any behavior when the `fetch` call succeeds but returns an error status code.

The loop runs for `attempt = 1` and `attempt = 2`, which is two passes:

```js
// subject.js:11
  for (let attempt = 1; attempt < 3; attempt++) {
```

Each pass calls `fetch` once (`subject.js:13`: `const response = await fetch(url);`). So `fetch` is called at most **2 times in total**. That is the first request plus **1 retry**, not 2 retries. The comment counts every attempt as a "retry". The off-by-one point is right, but the precise version is: "code makes 2 total attempts (1 retry)."

**Evidence:** `subject.js:11-18`

---

## Claim 3: "Fetches data from the API with retry logic."

**Location:** `subject.js:5`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the function fetches `url`, parses the body as JSON, and tries again when something throws. It does not establish retries on HTTP error statuses (4xx/5xx), because `fetch` doesn't throw on those, so the response is parsed and returned without a retry. It also doesn't establish any delay or backoff between attempts, because there isn't one.

The function fetches the URL and returns the parsed JSON:

```js
// subject.js:13-14
      const response = await fetch(url);
      return await response.json();
```

Errors are caught and the loop moves on to the next attempt:

```js
// subject.js:15-17
    } catch (err) {
      lastError = err;
    }
```

A failure in either the `fetch` call or in `response.json()` triggers a retry, since both sit inside the same `try` block. There is no code that checks `response.ok` or adds a delay between attempts (paraphrased — no quote available because the claim is about code that's missing: `subject.js:8-20` has no status check and no `setTimeout` or sleep).

**Evidence:** `subject.js:8-20`

---

## Claim 4a: "Retries 3 times"

**Location:** `subject.js:6`
**Type:** Configuration / Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the number of attempts the loop allows; does not establish which errors cause a retry (see Claim 3).

The loop bounds allow only two passes:

```js
// subject.js:11
  for (let attempt = 1; attempt < 3; attempt++) {
```

That means at most 2 calls to `fetch`, which is 1 retry. The docstring is wrong whichever way you read it. "3 retries" would mean 4 total attempts, and even the loose reading of "3 attempts" doesn't match the 2 that happen. Someone relying on this docstring would expect more attempts than the code makes.

**Evidence:** `subject.js:11-18`

---

## Claim 4b: "before giving up."

**Location:** `subject.js:6`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the function throws the last error it caught once all attempts fail; does not establish how callers handle that rejection, since no callers were read.

Once the loop runs out of attempts, the function throws the most recent error:

```js
// subject.js:19
  throw lastError;
```

`lastError` is always set by the time this line runs. The loop runs at least once, and the only way out of the loop without returning is through the `catch` that assigns `lastError` (paraphrased — no quote available because this conclusion comes from following control flow across `subject.js:11-19` rather than from a single line). The caller sees the failure as a rejected promise.

**Evidence:** `subject.js:9`, `subject.js:11-19`

---

## Claim 5a: "Off-by-one: starts at 1, so it tries at 1 and 2"

**Location:** `subject.js:10`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the loop's start value and the values `attempt` takes; does not establish what the "intended" bound was meant to be.

```js
// subject.js:11
  for (let attempt = 1; attempt < 3; attempt++) {
```

`attempt` starts at 1, takes the values 1 and 2, and the loop ends when it reaches 3. Starting at 0 with the same `< 3` bound would give three passes, so calling this an off-by-one fits.

**Evidence:** `subject.js:11`

---

## Claim 5b: "= only 2 retries"

**Location:** `subject.js:10`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the count of attempts and retries; does not establish retry behavior for non-throwing HTTP errors (see Claim 3).

The two loop passes (`subject.js:11`: `for (let attempt = 1; attempt < 3; attempt++)`) are two **attempts** in total. The first is the initial request, so there is only **1 retry**. The comment uses "retries" to mean "attempts". The precise version is: "only 2 attempts (1 retry)." This is the same issue as Claim 2.

**Evidence:** `subject.js:11-18`

---

## Claims Requiring Attention

### Incorrect
- **Claim 4a** (`subject.js:6`): The docstring says "Retries 3 times", but the loop allows only 2 total attempts (1 retry).

### Mostly Accurate
- **Claim 2** (`subject.js:2`): "retries 2 times" should say "2 total attempts (1 retry)".
- **Claim 5b** (`subject.js:10`): "only 2 retries" should say "only 2 attempts (1 retry)".

---

**Hallucination pattern log:** No update needed. The one Incorrect verdict (4a) is a wrong count, not a made-up symbol, API or option, so it doesn't belong in the log.
