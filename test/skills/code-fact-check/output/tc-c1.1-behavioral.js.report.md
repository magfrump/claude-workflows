I can't save files in this session, so the report is below in full instead of at `docs/reviews/code-fact-check-report.md`. There was no `docs/reviews/hallucination-patterns.md` to check against, and I didn't create one because none of the findings is a made-up symbol or API.

# Code Fact-Check Report

**Repository:** /tmp/tmp.MCYTK9kvCG
**Scope:** subject.js
**Checked:** 2026-11-19
**Total claims checked:** 4
**Summary:** 2 verified, 1 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

---

## Claim 1: "The comment says "returns null" but the code returns undefined"

**Location:** `subject.js:2`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the claim that the docstring says "null" and the falsy-`id` branch returns `undefined`; does not establish what happens on truthy input, which returns an object rather than either value.

The docstring says `* Returns null on empty input.` (`subject.js:6`), and the falsy branch returns `undefined`:

```js
// subject.js:9-11
if (!id) {
  return undefined; // <-- contradicts docstring
}
```

I read the whole function (`subject.js:8-13`). The only other path is `return { id, name: "test" };` at `subject.js:12`, which doesn't affect this claim.

**Evidence:** `subject.js:6`, `subject.js:8-13`

---

## Claim 2: "Looks up a user by ID."

**Location:** `subject.js:5`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the whole body of `getUser` (`subject.js:8-13`); does not establish whether a caller or a later version swaps in a real lookup. Confidence is Medium because this may be a deliberate stub in a test fixture.

The function doesn't look anything up. It checks whether `id` is falsy and otherwise builds a fixed object from its argument:

```js
// subject.js:8-13
function getUser(id) {
  if (!id) {
    return undefined; // <-- contradicts docstring
  }
  return { id, name: "test" };
}
```

There's no data source, map, or query. Every truthy `id`, including IDs that don't exist anywhere, returns `{ id, name: "test" }`. Someone relying on "looks up" would expect unknown IDs to come back as not-found, and they never do.

**Evidence:** `subject.js:8-13`

---

## Claim 3: "Returns null on empty input."

**Location:** `subject.js:6`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the return value of the falsy-`id` branch. It does not cover callers that compare strictly against `null` (`=== null`): for them, `undefined` breaks the check. It also does not cover what counts as "empty input".

The branch returns `undefined`, not `null`:

```js
// subject.js:9-11
if (!id) {
  return undefined; // <-- contradicts docstring
}
```

A more precise version would be: "Returns `undefined` when `id` is falsy." Two details matter here:

- **Strict null checks fail.** Code that tests `getUser(x) === null` gets `false`. Loose checks (`== null`) and plain truthiness checks still work.
- **"Empty" is broader than it sounds.** The test is `!id` (`subject.js:9`), so it catches every falsy value, not just missing or `""` input. That includes `0`, `false` and `NaN`. A user with ID `0` gets `undefined` back instead of a user object.

**Evidence:** `subject.js:9-11`

---

## Claim 4: "<-- contradicts docstring"

**Location:** `subject.js:10`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the mismatch between `return undefined;` and the docstring's "Returns null" (`subject.js:6`); does not establish that the docstring's other sentence ("Looks up a user by ID") is accurate. See Claim 2.

`return undefined; // <-- contradicts docstring` (`subject.js:10`) does contradict `* Returns null on empty input.` (`subject.js:6`).

**Evidence:** `subject.js:6`, `subject.js:10`

---

## Claims Requiring Attention

### Incorrect
- **Claim 2** (`subject.js:5`): `getUser` doesn't look anything up. It returns `{ id, name: "test" }` for any truthy `id`, so it never reports "not found".

### Mostly Accurate
- **Claim 3** (`subject.js:6`): It returns `undefined`, not `null`, and does so for any falsy `id` (including `0`), not only empty input. A precise version: "Returns `undefined` when `id` is falsy."
