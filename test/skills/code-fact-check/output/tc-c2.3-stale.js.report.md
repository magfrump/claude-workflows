# Code Fact-Check Report

**Repository:** /tmp/tmp.pfGH9UUSR8
**Scope:** subject.js
**Checked:** 2026-11-19
**Total claims checked:** 4
**Summary:** 1 verified, 1 mostly accurate, 1 stale, 0 incorrect, 1 unverifiable

I skipped the fixture header at `subject.js:1-2` because it describes the test, not the code. No hallucination pattern log was found (`docs/reviews/` is empty). My verdicts come from reading the code only. I had no shell tool, so I couldn't run anything.

---

## Claim 1a: "Retries the operation up to 5 times"

**Location:** `subject.js:5`
**Type:** Configuration / Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the retry limit inside `withRetry` (`subject.js:8-20`). It does not establish whether any caller expects 5 retries (there are no callers in the repo).

The limit is now 3:

```js
// subject.js:9
const MAX_RETRIES = 3; // changed from 5 in recent commit
```

The loop calls `fn` at most `MAX_RETRIES` times in total and throws on the last failure:

```js
// subject.js:11-16
while (attempt < MAX_RETRIES) {
  try {
    return await fn();
  } catch (err) {
    attempt++;
    if (attempt >= MAX_RETRIES) throw err;
```

So `fn` runs at most 3 times: the first try plus 2 retries. The comment beside the constant and the docstring note on line 6 both say the limit used to be 5, so this claim was probably true once. That makes it Stale rather than Incorrect.

**Evidence:** `subject.js:9`, `subject.js:11-19`

---

## Claim 1b: "with exponential backoff"

**Location:** `subject.js:5`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the delay formula between attempts. It does not cover jitter (there is none), a maximum delay (there is none), or any delay before the first attempt or after the last failure (neither exists).

```js
// subject.js:17
await new Promise((r) => setTimeout(r, 100 * Math.pow(2, attempt)));
```

`attempt` has already been incremented on line 15 when this runs, so the waits are 200 ms after the first failure and 400 ms after the second. The delay doubles each time, which is exponential. After the third failure, line 16 throws before reaching the sleep, so there is no final wait.

**Evidence:** `subject.js:15-17`

---

## Claim 2: "Now it only retries 3 times."

**Location:** `subject.js:6`
**Type:** Configuration / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers how many times `fn` is called in total and how many of those calls are retries. It does not establish what "retries" meant to the original author.

The number 3 matches `MAX_RETRIES = 3` (`subject.js:9`). But that constant limits the total number of attempts, not the retries:

```js
// subject.js:15-16
attempt++;
if (attempt >= MAX_RETRIES) throw err;
```

If `fn` keeps failing, it is called 3 times: the first try plus **2** retries. A more precise wording would be "makes up to 3 attempts (2 retries)". The constant's name has the same off-by-one.

**Evidence:** `subject.js:9`, `subject.js:11-16`

---

## Claim 3: "changed from 5 in recent commit"

**Location:** `subject.js:9`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers whether this repo's git history records a change from 5 to 3. It does not establish whether the change happened somewhere else (another repo, or history that was squashed before import).

The reflog has only one entry, the initial commit:

```
// .git/logs/HEAD:1
0000000… e1d6660… commit (initial): fixture
```

So no commit in this repo changes `MAX_RETRIES` from 5 to 3. The file was added with the value already set to 3. To verify this claim, you would need the original history where the change was made.

**Evidence:** `.git/logs/HEAD:1`, `subject.js:9`

---

## Claims Requiring Attention

### Stale
- **Claim 1a** (`subject.js:5`): The docstring says "up to 5 times", but the limit is now 3 total attempts (`MAX_RETRIES = 3`).

### Mostly Accurate
- **Claim 2** (`subject.js:6`): "retries 3 times" should be "up to 3 attempts (2 retries)", because `MAX_RETRIES` limits total calls.

### Unverifiable
- **Claim 3** (`subject.js:9`): The repo has one initial commit, so the change "from 5" can't be confirmed. You'd need the history from before the import.

---

There were no Incorrect verdicts, so nothing goes in the hallucination pattern log. I only had read-only tools in this session, so this report has not been saved to `docs/reviews/code-fact-check-report.md`.
