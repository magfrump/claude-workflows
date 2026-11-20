# Security Review: subject.js

**Scope:** `subject.js` (whole file; user-specified scope)
**Date:** 2026-11-20
Commit: ab1a7fe75eedf38e2ac14b0b2f4632a63c507899
**User goal:** Run a security review of `subject.js` (the password forgot/reset router) and print the report to stdout.

> ⚠️ **No code fact-check report provided.** Claims about security properties in comments and
> documentation have not been independently verified. For full verification, run the
> `code-fact-check` skill first or use the code-review orchestrator.

*Context note:* `./store` and `./mailer` are not in the repository, and there is no `docs/constraints.md`, so every attacker this code exposes is in scope. Wherever a finding depends on how the store behaves, the finding says so.

## Trust Boundary Map

```
B1: [POST /password/forgot body.email (anonymous)] → [String().toLowerCase() → users.findByEmail] → [user record / token issuance]
B2: [makeToken() output]                           → [resetTokens.put + email link]            → [bearer credential for account takeover]
B3: [POST /password/reset body.token (anonymous)]  → [resetTokens.get + expiresAt check]       → [users.setPassword(entry.userId, …)]
B4: [POST /password/reset body.password (anon.)]   → [none]                                    → [users.setPassword]
B5: [route handler]                                → [sendMail(user.email, …)]                 → [external mail system / victim inbox]
```

```
S1: req.body.email       — request-time — UNTRUSTED (all sinks)
S2: req.body.token       — request-time — UNTRUSTED (all sinks; type is not guaranteed to be a string)
S3: req.body.password    — request-time — UNTRUSTED (all sinks; type/length unvalidated)
S4: user.email / user.id — runtime-mutable (DB) — trusted as mail recipient (it came from the account); untrusted toward HTML sinks (none here)
S5: Math.random() output — runtime — NOT suitable for security tokens (predictable PRNG)
S6: TOKEN_TTL_MS, reset URL host — code-constant — trusted (all sinks)
```

All three inputs come from anonymous requests, and the code assumes `body.token` and `body.password` are strings. The code also treats a `Math.random()` token as an unguessable credential. The reset link's host is a code constant, not the `Host` header, and the mail goes to the stored address rather than the submitted one. Both choices are good.

## Findings

#### 1. Reset tokens come from `Math.random()` and can be predicted, which allows account takeover

**Severity:** Critical
**Location:** `subject.js:8-15, 20`
**Boundary:** B2
**Move:** #9 (cryptographic choices), #6 (follow the secrets)
**Confidence:** Medium

`makeToken` builds the reset credential from `Math.random()`. In V8 that is xorshift128+, which is not a cryptographic generator. Its internal state can be recovered from a modest number of observed outputs, and published SMT-solver attacks do this even when outputs are truncated, as they are here (`floor(r*62)` leaks about 5.95 bits per character). The attack: request resets for an account you control, collect the tokens from your inbox to recover the PRNG state, then trigger a reset for the victim and compute their token. That is unauthenticated account takeover. How easy it is depends on deployment details (one process or several, other `Math.random` consumers moving the state forward), which is why confidence is Medium rather than High.

**Recommendation:** Use `crypto.randomBytes(32).toString("base64url")` (or `crypto.randomInt` per character). Also consider storing only a SHA-256 hash of the token, so a leaked store does not yield usable tokens.

#### 2. A non-string `token` passes the lookup but skips the delete, so the token stays reusable

**Severity:** Medium
**Location:** `subject.js:28, 33`
**Boundary:** B3
**Move:** #2 (implicit sanitization), #11 (bypass enumeration)
**Confidence:** Medium (depends on the store)

The lookup uses `String(req.body.token)`, but the delete uses the raw `req.body.token`. With `express.json()`, sending `{"token":["<tok>"]}` makes `get("<tok>")` succeed. If the store is `Map`-backed, `delete(["<tok>"])` then removes nothing. The token stays valid for its full 30 minutes, so anyone who saw it (logs, Referer, a shared machine) can reset the password again after the legitimate user has. If the store is a plain object, the key is coerced and the delete happens to work.

**Recommendation:** Normalize once (`const token = typeof req.body.token === "string" ? req.body.token : null`), reject anything else, and use the same variable for both `get` and `delete`.

#### 3. Prototype-key token values may pass the check and call `setPassword(undefined, …)`

**Severity:** Medium
**Location:** `subject.js:28-32`
**Boundary:** B3
**Move:** #11 (bypass enumeration), #5 (invert access control)
**Confidence:** Low (depends entirely on how `./store` is built)

If `resetTokens` is a plain object (`obj[key]`), then `token = "__proto__"` or `"constructor"` returns a truthy entry with no `expiresAt`. `undefined < Date.now()` is `false`, so the expiry check passes and the handler calls `users.setPassword(undefined, password)`. Some query builders drop `undefined` filters, and in that case this could update every user's password or the first row. The expiry check fails open when the field is missing.

**Recommendation:** Back the store with `Map` or `Object.create(null)`. Make the check fail closed: `if (!entry || typeof entry.expiresAt !== "number" || entry.expiresAt < Date.now() || !entry.userId)`.

#### 4. The new password is not validated

**Severity:** Medium
**Location:** `subject.js:32`
**Boundary:** B4
**Move:** #2, #7 (type confusion)
**Confidence:** Medium

`req.body.password` reaches `setPassword` with no type, presence, or length check. A missing field gives `undefined`. Depending on `setPassword`, that could be stored as `"undefined"` or as a null hash, which may mean an empty or known password. The token is also consumed, so the user loses access. Objects, arrays, and very large strings can also get through (bcrypt silently truncates at 72 bytes, and a slow hash on a multi-MB input costs CPU).

**Recommendation:** Require `typeof password === "string"` with minimum and maximum length (for example 8–128) before using the token.

#### 5. `/password/forgot` has no rate limit, so it can be used to flood inboxes and grow the token store

**Severity:** Medium
**Location:** `subject.js:17-25`
**Boundary:** B1, B5
**Move:** #8 (a million of these)
**Confidence:** High

Any anonymous caller can trigger unlimited emails to any registered address, which harasses users and damages the sender's reputation. Each request also writes a new token. Old tokens are never invalidated, and this file never purges expired ones, so the store grows without bound and many valid tokens per user exist at once.

**Recommendation:** Rate-limit per IP and per target account. Invalidate a user's earlier tokens when issuing a new one. Use a store with a TTL, or purge expired entries.

#### 6. Response timing and error behavior reveal whether an account exists

**Severity:** Medium
**Location:** `subject.js:18-24`
**Boundary:** B1, B5
**Move:** #3 (error path)
**Confidence:** Medium

The constant `202` body is good, but for existing users the handler awaits `resetTokens.put` and `sendMail` before responding, so their requests are measurably slower. If `sendMail` rejects, the async handler throws. Under Express 4 that is an unhandled rejection and the request hangs; under Express 5 it becomes a 500. Both outcomes only happen for real accounts. Either way, attackers can enumerate registered emails.

**Recommendation:** Respond first and send the mail asynchronously (a queue, or fire-and-forget with `.catch` logging). Wrap the work in `try/catch` so the response is identical either way.

#### 7. The token is not consumed atomically, and a failed reset leaves it valid

**Severity:** Low
**Location:** `subject.js:28-33`
**Boundary:** B3
**Move:** #4 (TOCTOU), #3 (error path)
**Confidence:** High

`get` → `setPassword` → `delete` is not atomic, so concurrent requests with the same token can all succeed, and the last write wins. If `setPassword` throws, `delete` never runs and the token stays live. Only someone who already holds the token can exploit this, which limits the impact.

**Recommendation:** Consume first with an atomic get-and-delete (for example Redis `GETDEL`), then set the password.

#### 8. A reset does not revoke existing sessions, and the token travels in a URL query string

**Severity:** Low
**Location:** `subject.js:22, 32-34`
**Boundary:** B2, B3
**Move:** #6
**Confidence:** Medium

After a reset, an attacker's existing sessions stay valid, which defeats the main reason a user resets. `?token=` can also leak through Referer headers, proxy or access logs, and browser history if the reset page loads third-party resources.

**Recommendation:** Revoke all of the user's sessions (and other reset tokens) on reset. Send `Referrer-Policy: no-referrer` on the reset page, or carry the token in the URL fragment.

## Untested bypass candidates

These are for the token/expiry guard at `subject.js:28-31`:
- **`token` = `"__proto__"` / `"constructor"` / `"toString"`:** traced as far as the guard (it fails open when `expiresAt` is missing). The store's actual implementation could not be read because `./store` is absent. This is Finding 3.
- **`token` as an array/object with a custom `toString`:** the get/delete mismatch was traced (Finding 2). What the store does with a non-string key on `delete` is unverified.
- **Expired token with a clock-skewed `expiresAt` (for example a string value from a JSON-backed store):** `"123" < Date.now()` coerces to a number, but a non-numeric string gives `NaN`, the comparison is `false`, and the token never expires. Untested because the store's serialization is unseen.

## Endorsement Claims

- **Claim:** The reset link's host is a hard-coded constant, not taken from the request's `Host` or `X-Forwarded-Host` header.
  **Location:** `subject.js:22`
  **Evidence:** read-static
  **Verified:** The template literal on line 22 uses the literal `https://app.example.com/reset`.
  **Not verified:** Whether `sendMail` rewrites links, or whether another route builds reset links differently.
- **Claim:** The reset email goes to the stored `user.email`, not the submitted `req.body.email`. This reduces the risk of Unicode/case-collision recipient attacks.
  **Location:** `subject.js:18, 22`
  **Evidence:** read-static
  **Verified:** Line 22 passes `user.email` from the `findByEmail` result.
  **Not verified:** How `users.findByEmail` matches (collation/normalization), because `./store` is unread.
- **Claim:** `/password/forgot` returns the same status and body whether or not the user exists.
  **Location:** `subject.js:24`
  **Evidence:** read-static
  **Verified:** Line 24 runs unconditionally with `202 {ok:true}` on the non-throwing path.
  **Not verified:** The throwing path when `put`/`sendMail` rejects, and timing (see Finding 6).

## Primitive sweep

Primitive sweep: no dangerous primitives in scope. There is no fetch/`open`, exec, deserialization of untrusted formats, raw SQL, path construction, or `eval` in `subject.js`. The only interpolation is the email body on line 22, which takes S5/S6 values (a generated alphanumeric token and a constant host). It contains no request data, so it is cleared. The store calls (`findByEmail`, `get`, `setPassword`, `delete`) may hide SQL or object-key sinks in `./store`, which is outside the scope that could be read.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Reset tokens from `Math.random()` are predictable | Critical | B2 | `subject.js:8-15` | Medium |
| 2 | Array `token` skips the delete, so the token stays reusable | Medium | B3 | `subject.js:28,33` | Medium |
| 3 | Prototype-key token fails open, giving `setPassword(undefined)` | Medium | B3 | `subject.js:28-32` | Low |
| 4 | New password not validated | Medium | B4 | `subject.js:32` | Medium |
| 5 | No rate limit on forgot (mail flood, store growth) | Medium | B1, B5 | `subject.js:17-25` | High |
| 6 | Account enumeration via timing/errors | Medium | B1, B5 | `subject.js:18-24` | Medium |
| 7 | Token consumption not atomic, and not consumed on failure | Low | B3 | `subject.js:28-33` | High |
| 8 | Sessions not revoked on reset; token in query string | Low | B2, B3 | `subject.js:22,32-34` | Medium |

## Overall Assessment

This file should not be merged as written. The most serious problem is Finding 1: the reset token is the only credential guarding account takeover, and it comes from a non-cryptographic PRNG. Switching to `crypto.randomBytes` is a one-line fix and the top priority. The other issues can all be fixed in place without redesign: normalize `token` and `password` to validated strings once, make the expiry check fail closed, consume the token atomically before setting the password, and add rate limiting and session revocation. Findings 2 and 3 depend on how `./store` is built, which could not be read, so this review is partial for those paths. The endorsement claims above are pending execution verification.
