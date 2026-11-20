# Code Fact-Check Report

**Repository:** /tmp/tmp.d0Nev9eHlp
**Scope:** subject.js (explicit user scope)
**Checked:** 2026-11-19
**Total claims checked:** 2
**Summary:** 2 verified, 0 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

There was no `docs/reviews/hallucination-patterns.md` file, so I had no earlier patterns to compare against. I skipped line 1 (`// Test fixture for TC-C1.5: Configuration claim`) because it's a label, not a checkable claim.

---

## Claim 1: "Comment says 5 minutes, config says 300 seconds — these match"

**Location:** `subject.js:2`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what the comment at line 6 says, what the literal at line 7 is, and whether the two agree arithmetically; does not establish that the value is actually used as seconds at runtime (no code in the repo reads it as a duration — see Claim 2).

The comment and the value both appear as described:

```js
// subject.js:6-7
    // cache TTL is 5 minutes
    ttl: 300, // seconds
```

300 seconds ÷ 60 = 5 minutes, so the comment and the config value agree.

**Evidence:** `subject.js:2`, `subject.js:6-7`

---

## Claim 2: "cache TTL is 5 minutes" / "seconds"

**Location:** `subject.js:6-7`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the configured value of `config.cache.ttl` (300) and that `getCacheTTL()` returns it unchanged; does not establish that any consumer reads the value as seconds (the unit comes only from the inline comment, and nothing in the repo applies it), and does not establish that a cache actually expires entries after 5 minutes.

The configured value is 300, and the inline comment gives the unit as seconds:

```js
// subject.js:5-8
  cache: {
    // cache TTL is 5 minutes
    ttl: 300, // seconds
  },
```

The only accessor returns the raw value without converting it:

```js
// subject.js:15-17
function getCacheTTL() {
  return config.cache.ttl;
}
```

Nothing in the repository uses this value besides its definition and export (paraphrased — no quote available because the claim is about missing code: searching for `getCacheTTL|cache\.ttl|ttl` matched only `subject.js:7`, `:15`, `:16`, `:19`). The "seconds" unit is therefore stated only in the comment. If a consumer outside the repo treated the number as milliseconds, for example, the real TTL would be 0.3 s rather than 5 minutes. Within this file, 300 s = 5 min is consistent.

The two comments are reported together because they get the same verdict, so splitting them would add nothing.

**Evidence:** `subject.js:5-8`, `subject.js:15-17`, `subject.js:19`

---

## Claims Requiring Attention

None. Both claims are verified. The only caveat is the one in Claim 2: nothing in the repo uses the TTL, so the "seconds" unit is stated only in the comment.

---

**Notes:**
- I couldn't save the report to `docs/reviews/code-fact-check-report.md` because I don't have a file-writing tool in this session. It's included above in full, so you can save it there.
- No claims were Incorrect, so there's nothing to add to the hallucination pattern log, and I didn't create the file.
