# Security Review: subject.js

**User goal:** Run a security review of `subject.js` (the password forgot/reset routes) and print the report to stdout.

Commit: c564501ea5ef475a09a762d4d7cd59a6d3fb49dd
**Scope:** `subject.js` (explicit file scope; `./store` and `./mailer` are imported but aren't in the repository, so I could not read them)
**Date:** 2026-11-19

> ⚠️ **No code fact-check report provided.** Claims about security properties in comments and documentation have not been independently verified. For full verification, run the `code-fact-check` skill first or use the code-review orchestrator.

None of the HALT patterns match. The most serious finding (#1) is an account-takeover path, but it is not one of the five escalation patterns.

---

## Trust Boundary Map

```
B1: [req.body.email (anon)]     → [String() + toLowerCase()]          → [users.findByEmail]
B2: [req.body.token (anon)]     → [String() on get / RAW on delete]   → [resetTokens.get / resetTokens.delete]
B3: [req.body.password (anon)]  → [none]                              → [users.setPassword]
B4: [makeToken() secret]        → [resetTokens.put + email URL]       → [user inbox / bearer credential]
B5: [response timing/status]    → [/password/forgot handler]          → [anonymous client]
```

**Input-source classification**

```
S1: req.body.email          — request-time  — UNTRUSTED (all sinks)
S2: req.body.token          — request-time  — UNTRUSTED (all sinks); type not constrained (string/array/object via JSON)
S3: req.body.password       — request-time  — UNTRUSTED (all sinks); type not constrained
S4: resetTokens entry       — runtime (store) — trusted for userId/expiresAt *only if* the lookup key could not be steered (see untested candidate U1)
S5: user record (user.email)— runtime-mutable — trusted as a mail recipient (it is the account's own stored address)
S6: Math.random() output    — runtime PRNG  — NOT suitable for secret generation
S7: TOKEN_TTL_MS, base URL  — code-constant — trusted (all sinks)
```

All three inputs come from anonymous request bodies. The design treats one value as a bearer credential: whoever holds the reset token can set any user's password. So the token's unpredictability (B4) and the token check (B2) are the whole authentication boundary. Both are weak, and nothing validates the password value that crosses B3.

---

## Findings

#### 1. Reset tokens come from non-cryptographic `Math.random()`, so an attacker can predict them and take over accounts

**Severity:** Critical
**Location:** `subject.js:8-15`, `subject.js:20`
**Boundary:** B4
**Move:** #9 (cryptographic choices), #6 (follow the secrets)
**Confidence:** Medium

`makeToken` builds the reset token from `Math.random()`. In V8 that is xorshift128+, which is neither seeded nor designed for secrets. Each token character exposes about 5.95 bits of a PRNG output. An attacker can request resets for accounts they control, collect the tokens from their own inbox, and recover the generator state with known solver techniques (for example a z3-based xorshift128+ state recovery). They then call `/password/forgot` for the victim and predict that token. Since `/password/reset` only needs a valid token, the result is full account takeover with no access to the victim's mailbox. Exploitability depends on conditions outside this file. All requests must reach the same process/isolate. Other `Math.random()` consumers interleaving calls add noise, though not much protection. Multiple workers reduce reliability but don't remove the attack. That is why confidence is Medium and not High.

**Recommendation:** Generate tokens with `crypto.randomBytes(32).toString("base64url")` or `crypto.randomUUID()`. Also consider storing only a SHA-256 hash of the token in `resetTokens`, so a leak of the store doesn't hand out valid tokens.

#### 2. The token is coerced with `String()` for lookup but passed raw to `delete`, so it may not be consumed and can be replayed

**Severity:** Medium
**Location:** `subject.js:28`, `subject.js:33`
**Boundary:** B2
**Move:** #2 (implicit sanitization), #4 (TOCTOU)
**Confidence:** Medium

The lookup uses `String(req.body.token || "")`, but the delete uses `req.body.token` unchanged. With a JSON body of `{"token": ["<tok>"], ...}`, `String(["<tok>"])` returns `"<tok>"`, so the lookup succeeds and the password is set. Then `resetTokens.delete(["<tok>"])` runs with an array key. For a `Map` or similar keyed store that deletes nothing, so the token stays valid for the rest of its 30-minute TTL. Anyone holding the token (or sitting on the link path, see #6) can reset the password again after the legitimate user finishes. Whether this is exploitable depends on how `./store` handles keys, which I could not read.

**Recommendation:** Normalize once. Reject the request unless `typeof req.body.token === "string"`, and use that same variable for both `get` and `delete`.

#### 3. Check-then-delete race: one token can be redeemed by several concurrent requests

**Severity:** Medium
**Location:** `subject.js:28-33`
**Boundary:** B2
**Move:** #4 (TOCTOU)
**Confidence:** High

The token is checked at line 28, the password is set at line 32, and the token is deleted only at line 33, with two `await`s in between. Parallel requests carrying the same token all pass the check before any delete runs, and each sets a different password. Whichever write lands last wins. That could be an attacker who obtained the link racing the legitimate user. The token is meant to be single-use, and this breaks that.

**Recommendation:** Consume the token atomically before acting on it: an atomic `getAndDelete`/`DELETE … RETURNING`, or delete first and only then call `setPassword` with the returned entry.

#### 4. No validation of the new password (type, presence, strength)

**Severity:** Medium
**Location:** `subject.js:32`
**Boundary:** B3
**Move:** #2 (implicit sanitization)
**Confidence:** Medium

`req.body.password` goes straight to `users.setPassword` with no checks. It can be missing (`undefined`), `""`, a number, an array, or an object. Depending on `setPassword` (not readable), this could set an empty or literal `"undefined"` password. Those are trivially guessable, and a missing field from a client bug can lock the user into a known password. A non-string could also make the hashing function throw after the check passed, leaving behavior undefined. The token is deleted only after `setPassword` succeeds, so a throw at least leaves the token in place.

**Recommendation:** Require `typeof password === "string"`, enforce minimum and maximum length (the maximum also limits hashing cost, see #5), and hash with bcrypt, scrypt or argon2 inside `setPassword`. That last point needs confirming, since I couldn't read it.

#### 5. `/password/forgot` has no rate limit: mail bombing, unbounded token growth, and many live tokens per user

**Severity:** Medium
**Location:** `subject.js:17-25`
**Boundary:** B1, B4
**Move:** #8 (a million of these)
**Confidence:** High

An anonymous caller can POST any victim's email address repeatedly. Each request sends a mail, which can flood the victim's inbox and burn the sender reputation and mail quota. Each request also adds a new `resetTokens` entry, and earlier tokens are never invalidated. A user can therefore hold any number of simultaneously valid tokens, which widens the window for #1 and #2. The store also grows without limit unless `./store` evicts expired entries. A successful reset only deletes the token that was used, so other outstanding tokens stay valid after the password change. Nothing here limits brute-force attempts on `/password/reset` either. With a CSPRNG and 62^32 possible tokens that is fine, but today it relies entirely on #1 being fixed.

**Recommendation:** Rate-limit both endpoints per IP and per target account. Keep at most one active token per user, replacing the old one on each new request, and delete all of a user's tokens on a successful reset.

#### 6. Response timing reveals which emails are registered

**Severity:** Medium
**Location:** `subject.js:18-24`
**Boundary:** B5
**Move:** #3 (error path vs happy path)
**Confidence:** Medium

The response is always 202 with the same body, which is good, but the handler only `await`s `resetTokens.put` and `sendMail` when the account exists. A real SMTP or API send takes tens to hundreds of milliseconds, so registered emails respond measurably slower. That lets an attacker enumerate accounts. How large the gap is depends on `./mailer`: a queued, fire-and-forget send would make it smaller.

**Recommendation:** Send the 202 response before doing the work, for example by enqueuing token creation and mail as a background job, so response time doesn't depend on whether the user exists.

#### 7. Existing sessions are not revoked after a password reset

**Severity:** Low
**Location:** `subject.js:32-34`
**Boundary:** B3
**Move:** #6 (follow the secrets)
**Confidence:** Low

The reset handler doesn't invalidate the user's existing sessions or other credentials. If an account was compromised, resetting the password won't log the attacker out. `users.setPassword` might do this already, but I couldn't read it.

**Recommendation:** Revoke all sessions and refresh tokens for `entry.userId` on reset (or confirm that `setPassword` does), and email the account a "your password was changed" notice.

#### 8. Reset token sits in the URL query string

**Severity:** Informational
**Location:** `subject.js:22`
**Boundary:** B4
**Move:** #6 (follow the secrets)
**Confidence:** Low

`?token=` in the URL can leak through browser history, proxy and access logs, and the `Referer` header if the reset page loads third-party resources. The 30-minute TTL limits the exposure. The reset page itself is outside scope.

**Recommendation:** Serve the reset page with `Referrer-Policy: no-referrer`, keep tokens out of access logs, or use a URL fragment that the page posts back.

---

## Guardrail bypass enumeration (move #11)

The guard is the token check at line 29: `!entry || entry.expiresAt < Date.now()`.

| Candidate | Status | Outcome |
|---|---|---|
| Array token `["<valid>"]` | Tested (traced) | Passes the lookup via `String()`; `delete` gets an array, see Finding 2 |
| Concurrent duplicate requests | Tested (traced) | All pass before the delete, see Finding 3 |
| Object token `{}` | Tested (traced) | Becomes `"[object Object]"`; misses unless such a key exists. No bypass |

**Untested bypass candidates**

- **U1:** prototype keys such as `"constructor"`, `"__proto__"` or `"toString"`. If `resetTokens` is a plain object (`store[key]`), `get("constructor")` returns a function. That value is truthy, and `undefined < Date.now()` is `false`, so the guard passes and `setPassword(undefined, pw)` runs. I couldn't test this because `./store` isn't in the repo. If it is a plain object, this becomes a Critical finding.
- **U2:** an entry with no `expiresAt` field. The comparison with `undefined` is always `false`, so the entry never expires. I couldn't test whether `./store` can return such entries, for example from migrated or older records.

Because of these candidates, the token check does not appear in Endorsement Claims.

---

## Endorsement Claims

- **Claim:** The reset link's origin is a code constant (`https://app.example.com`) and doesn't come from the `Host` or `X-Forwarded-Host` header, so host-header poisoning of reset links is not possible on this line.
  **Location:** `subject.js:22`
  **Evidence:** read-static
  **Verified:** I read the template literal. Its only interpolated value is `token` from `makeToken()`.
  **Not verified:** how `./mailer`'s `sendMail` renders or rewrites the body (for example, link tracking that rewrites URLs).
  **route: code-fact-check** (*pending execution verification*)

- **Claim:** Mail goes to the address stored on the account (`user.email`), not the address the requester submitted, so a Unicode or case-variant email doesn't redirect the token to the attacker's address at this call.
  **Location:** `subject.js:18-22`
  **Evidence:** read-static
  **Verified:** I read that `sendMail`'s first argument is `user.email` from the record returned by `findByEmail`.
  **Not verified:** how `users.findByEmail` matches (normalization or collation in `./store`), which decides *which* account's record comes back.
  **route: code-fact-check** (*pending execution verification*)

- **Claim:** `/password/forgot` returns the same status and body (`202 {ok:true}`) whether or not the user exists.
  **Location:** `subject.js:19-24`
  **Evidence:** read-static
  **Verified:** I read the handler; there is a single response statement after the `if`.
  **Not verified:** whether timing differs (it likely does, see Finding 6), and what happens on the error path if `sendMail` or `put` rejects. An unhandled rejection in Express 4 would hang the request or return 500 only when the user exists.

---

## Primitive sweep

Primitive sweep: no dangerous primitives in scope. There's no SQL, exec, fetch, deserialization of untrusted formats, HTML interpolation, path construction or `eval` in `subject.js`. The only string interpolation into an outbound sink is the reset URL at line 22, and its only input is internally generated (S6), with no request data.

---

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Predictable `Math.random()` reset tokens, leading to account takeover | Critical | B4 | `subject.js:8-15` | Medium |
| 2 | `String()` on lookup but raw token on delete, so token may survive and be replayed | Medium | B2 | `subject.js:28,33` | Medium |
| 3 | Check-then-delete race lets one token be redeemed several times | Medium | B2 | `subject.js:28-33` | High |
| 4 | No type, presence or strength validation on the new password | Medium | B3 | `subject.js:32` | Medium |
| 5 | No rate limit; tokens pile up and survive a reset | Medium | B1, B4 | `subject.js:17-25` | High |
| 6 | Timing reveals registered emails | Medium | B5 | `subject.js:18-24` | Medium |
| 7 | Sessions not revoked after reset | Low | B3 | `subject.js:32-34` | Low |
| 8 | Token in URL query string | Informational | B4 | `subject.js:22` | Low |

---

## Overall Assessment

The flow has a reasonable outline: constant response, fixed link origin, mail to the stored address, a TTL. But its single authentication factor, the reset token, is generated with a non-cryptographic PRNG, so the security of every account depends on `Math.random()` being unpredictable. Fixing that is the most important change: switch to `crypto.randomBytes`. All the issues can be fixed in place; none points to an architectural problem.

Next priorities:
1. Validate the token as a string and consume it atomically (Findings 2 and 3).
2. Validate the password (Finding 4).
3. Add rate limiting and keep one active token per user, purged on reset (Finding 5).

This review is partial. `./store` and `./mailer` weren't available, and untested candidate U1 (prototype-key lookup) could become a Critical guard bypass depending on how `resetTokens` is implemented. Not safe to merge as written.
