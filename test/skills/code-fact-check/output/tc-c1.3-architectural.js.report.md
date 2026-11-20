I couldn't save the report to `docs/reviews/code-fact-check-report.md` because this session has no file-writing tool. The full report is below.

# Code Fact-Check Report

**Repository:** /tmp/tmp.WUgTufCjEj
**Scope:** subject.js (scope given by the user)
**Checked:** 2026-11-19
**Total claims checked:** 3
**Summary:** 1 verified, 1 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

Lines 1–2 are labels for the test fixture, not claims about the code, so I skipped them. There was no `docs/reviews/hallucination-patterns.md` from earlier runs to compare against.

---

## Claim 1: "validateToken is the core auth check."

**Location:** `subject.js:4`
**Type:** Architectural / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether `validateToken` is the auth decision used by both auth entry points in `subject.js`. It does not establish that the function checks anything about the token beyond its prefix, or that it returns a strict boolean.

The structural part is correct: both auth paths depend on `validateToken`. The HTTP middleware branches on it (`if (validateToken(token)) {` — `subject.js:8`), and the WebSocket handler returns its result (`return validateToken(token);` — `subject.js:22`).

The phrase "auth check" is broader than what the function does. The whole body is:

```js
// subject.js:15-17
function validateToken(token) {
  return token && token.startsWith("Bearer ");
}
```

It only checks that the token is truthy and starts with `"Bearer "`. It does not check a signature, expiry, or any lookup, so any string like `"Bearer x"` passes. The return value is also not always a boolean. A missing header gives `undefined` and an empty string gives `""`, because `&&` short-circuits (paraphrased — no quote available because this follows from JavaScript `&&` semantics on the line quoted above, not from a separate line of code). A more accurate comment would be: "validateToken is the shared auth gate; it only checks for a `Bearer ` prefix."

**Evidence:** `subject.js:8`, `subject.js:15-17`, `subject.js:22`

---

## Claim 2: "This is the only caller of validateToken()."

**Location:** `subject.js:5`
**Type:** Architectural
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every call site of `validateToken` in the repository, found by searching the whole working tree. It does not establish what external code does with the exported symbol.

The comment sits above `authMiddleware`, which does call `validateToken` (`if (validateToken(token)) {` — `subject.js:8`). But it is not the only caller. `wsAuthHandler` calls it too:

```js
// subject.js:20-23
function wsAuthHandler(socket) {
  const token = socket.handshake.auth.token;
  return validateToken(token);
}
```

The function is also exported, so code outside this file can call it: `module.exports = { authMiddleware, validateToken, wsAuthHandler };` (`subject.js:25`). A repo-wide search for `validateToken` found matches only in `subject.js`: the definition at :15, calls at :8 and :22, the export at :25, and the comment lines (paraphrased — no quote available because this is the result of a search, not a single snippet). So there are at least two callers inside the repo. Anyone relying on this comment to change `validateToken` safely would miss the WebSocket path.

**Evidence:** `subject.js:5-13`, `subject.js:20-23`, `subject.js:25`

---

## Claim 3: "Second caller — contradicts the "only caller" claim above"

**Location:** `subject.js:19`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that `wsAuthHandler` calls `validateToken` and is a second caller after `authMiddleware`. It does not establish that these are the only two callers, since the export at :25 lets outside code call it as well.

`wsAuthHandler` calls `validateToken` directly (`return validateToken(token);` — `subject.js:22`). That makes it a second caller alongside `authMiddleware` (`subject.js:8`), so it does contradict the claim at :5.

**Evidence:** `subject.js:8`, `subject.js:20-23`

---

## Claims Requiring Attention

### Incorrect
- **Claim 2** (`subject.js:5`): `validateToken` also has a caller in `wsAuthHandler` (`subject.js:22`) and is exported. The "only caller" comment should be removed or corrected.

### Mostly Accurate
- **Claim 1** (`subject.js:4`): it is the shared auth gate, but it only checks for a `"Bearer "` prefix and can return non-boolean falsy values. The comment should say how little it checks.

---

**Hallucination log:** I made no entry. The one Incorrect claim gets the number of callers wrong; it doesn't invent a symbol or API, so it doesn't fit the log's criteria.
