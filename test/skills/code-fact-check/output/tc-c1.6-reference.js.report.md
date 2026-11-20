I've checked the claims, but I couldn't save the report to `docs/reviews/code-fact-check-report.md` because I don't have a file-writing tool here. The full report is below. I also had no shell, so `gh` lookups and running the code weren't possible, and every verdict comes from reading the code.

# Code Fact-Check Report

**Repository:** /tmp/tmp.zDJKaJHLIA
**Scope:** subject.js (explicit user scope)
**Checked:** 2026-11-19
**Total claims checked:** 4
**Summary:** 1 verified, 0 mostly accurate, 0 stale, 0 incorrect, 3 unverifiable

No hallucination pattern log (`docs/reviews/hallucination-patterns.md`) existed, so there were no earlier patterns to compare against. Lines 1–2 of `subject.js` describe the test fixture itself, so they aren't claims about the code and were skipped.

---

## Claim 1: "Workaround for issue #1234"

**Location:** `subject.js:5`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether issue #1234 can be found from this repo; does not establish whether the issue exists in any external tracker or what it describes.

The comment doesn't name a tracker. The repo has no remote, so there's nowhere to look up the issue number. `.git/config` contains only the `[core]` section:

```
// .git/config:1-5
[core]
	repositoryformatversion = 0
	filemode = true
	bare = false
	logallrefupdates = true
```

The only mention of `1234` in the repo is the comment itself (paraphrased — no quote available because this is about missing code: grepping for `1234` found only `subject.js:5`). To verify it, you'd need to know which tracker is meant (for example, the upstream library's GitHub repo) and then run `gh issue view 1234 -R <owner/repo>`.

**Evidence:** `subject.js:5`, `.git/config:1-5`

---

## Claim 2: "The upstream library double-encodes UTF-8 strings in query parameters."

**Location:** `subject.js:6`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether the repo identifies the "upstream library"; does not establish how any external library actually encodes things.

The file doesn't import or require any library. Its only module statement is the export:

```js
// subject.js:17
module.exports = { sanitizeQuery };
```

There's also no dependency manifest (paraphrased — no quote available because this is about missing files: the repo contains only `subject.js` and `.git/`, with no `package.json`). The library isn't named, so its behavior can't be checked. You'd need the library's name and version, plus a test showing it double-encodes.

**Evidence:** `subject.js:1-17`

---

## Claim 3a: "This pre-decodes [the query]"

**Location:** `subject.js:7`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the fact that `sanitizeQuery` removes exactly one layer of percent-encoding and returns the input unchanged if decoding throws; does not establish that one layer is enough for every input, or that the silent fallback is the right behavior for malformed input.

The whole function (it's short enough to quote in full):

```js
// subject.js:9-15
function sanitizeQuery(query) {
  try {
    return decodeURIComponent(query);
  } catch {
    return query;
  }
}
```

`decodeURIComponent` removes one layer of percent-encoding, decoding UTF-8 byte sequences. On a double-encoded input such as `%25C3%25A9`, that leaves single-encoded `%C3%A9`, which is consistent with "pre-decoding" to undo one extra layer. If the sequence is malformed, `decodeURIComponent` throws a `URIError`. The bare `catch` then returns the original `query` without logging anything. The comment doesn't mention this fallback, but it doesn't contradict it either.

**Evidence:** `subject.js:9-15`

---

## Claim 3b: "...before passing to the library."

**Location:** `subject.js:7`
**Type:** Architectural
**Verdict:** Unverifiable
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what `sanitizeQuery` itself does with its result and whether it has any callers in the repo; does not establish what callers outside the repo do with the return value.

`sanitizeQuery` never passes anything to a library. It just returns the decoded string (`return decodeURIComponent(query);`, `subject.js:11`). Whether the decoding happens "before passing to the library" depends on the callers, and the repo has none (paraphrased — no quote available because this is about missing code: grepping for `sanitizeQuery` found only the definition at `subject.js:9` and the export at `subject.js:17`). You'd need to find the code that consumes it and confirm it calls `sanitizeQuery` before calling into the library.

**Evidence:** `subject.js:9-17`

---

## Claims Requiring Attention

### Incorrect
None.

### Stale
None.

### Mostly Accurate
None.

### Unverifiable
- **Claim 1** (`subject.js:5`): the comment doesn't say which tracker issue #1234 is in, and the repo has no remote. Name the tracker or link the issue.
- **Claim 2** (`subject.js:6`): the "upstream library" isn't named, imported or listed as a dependency. You'd need its name and version, plus a reproduction of the double-encoding.
- **Claim 3b** (`subject.js:7`): nothing in the repo calls `sanitizeQuery`, so whether it runs "before passing to the library" depends on code outside the repo.

---

No claim was verdicted Incorrect, so I didn't create a hallucination pattern log.
