# Code Fact-Check Report

**Repository:** /tmp/tmp.moUThw1BFC
**Scope:** subject.js
**Checked:** 2026-11-19
**Total claims checked:** 1
**Summary:** 1 verified, 0 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

---

## Claim 1: "Throws TypeError if name is empty."

**Location:** `subject.js:5`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the empty string `""` passed as `name` to `greet`, which throws a `TypeError`. It does not establish that whitespace-only strings such as `"   "` throw (they don't; the guard is a plain truthiness check). It also doesn't cover the other falsy inputs (`undefined`, `null`, `0`, `false`, `NaN`), which throw the same `TypeError` even though the docstring doesn't mention them.

I read the whole function, from its signature to its last line:

```js
// subject.js:7-12
function greet(name) {
  if (!name) {
    throw new TypeError("name must not be empty");
  }
  return `Hello, ${name}!`;
}
```

`""` is falsy in JavaScript, so `!name` is `true` and the function reaches `throw new TypeError("name must not be empty")` (`subject.js:9`). The thrown type is `TypeError`, as the docstring says. On every other path the function returns `` `Hello, ${name}!` `` (`subject.js:11`), so nothing else throws.

What falls outside the narrow reading (paraphrased — no quote available because this is JavaScript truthiness semantics applied to the single guard at `subject.js:8`, not a separate code path):
- The guard throws for any falsy value, not only empty strings. Calling `greet()` with no argument also throws.
- Truthy values that a reader might call "empty" do not throw: `"   "` returns `"Hello,    !"`, and `[]` returns `"Hello, !"`.

The docstring's main claim holds. The residue only matters to a reader who assumes "empty" includes blank or whitespace-only strings.

**Evidence:** `subject.js:5`, `subject.js:7-12`

---

## Claims Requiring Attention

No claims need attention: there are no Incorrect, Stale, Mostly Accurate or Unverifiable verdicts.

---

**Notes:**
- **Header comments not checked:** I skipped `subject.js:1-2`. They describe the file's purpose as a test fixture and say nothing about how the code behaves.
- **No pattern log:** `docs/reviews/hallucination-patterns.md` doesn't exist, so there were no earlier patterns to compare against. Nothing was fabricated, so I didn't create the file.
- **Report not saved:** For standalone runs, the report should go to `docs/reviews/code-fact-check-report.md`, but I had no file-writing tool here. The report above is the full output and can be saved to that path as-is.
