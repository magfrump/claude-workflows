**User goal:** A security review of `subject.py` (the whole file), with the report printed here and not saved. The request was clear, so I didn't ask any questions.

---

Commit: a1154a77d1737fd49219ca24a77ca3e686e90e8e
**User goal:** Run a security review of subject.py and print the report to stdout. Scope: subject.py.

# Security Review: subject.py

**Scope:** `subject.py` (whole file, 43 lines). Explicit file scope, not a branch diff.
**Date:** 2026-11-19

> ⚠️ **No code fact-check report provided.** Claims about security properties in comments and documentation have not been independently verified. For full verification, run the `code-fact-check` skill first or use the code-review orchestrator.

> 🚨 **HALT: ESCALATE TO HUMAN**
>
> **Pattern:** Command injection in user-facing code. This is unauthenticated `pickle.loads` on a client-supplied cookie, which lets an attacker run any code they like, the same as command injection.
> **Location:** `subject.py:17`
> **Detail:** `load_prefs()` base64-decodes the `prefs` cookie and passes it straight to `pickle.loads`. Any anonymous client can send a crafted cookie to `GET /dashboard` or `POST /prefs` and run arbitrary code as the Flask process.
>
> This finding needs a human to look at it now, before the rest of the review is useful.
> Do not merge or deploy until this is fixed.

## Trust Boundary Map

```
B1: [HTTP Cookie "prefs" (client)] → [base64 decode → pickle.loads, load_prefs():17] → [Python object in server process]
B2: [HTTP form fields theme/page_size] → [allowlist / range checks, update_prefs():37-41] → [prefs dict]
B3: [prefs object (from B1)] → [render_template("dashboard.html"), :31] → [HTML response to browser]
B4: [prefs dict (server)] → [pickle.dumps → set_cookie, save_prefs():23-24] → [client-held cookie, re-enters at B1]
```

| Label | Source | Mutability | Trust classification |
|---|---|---|---|
| S1 | `request.cookies["prefs"]` | request-time | UNTRUSTED for all sinks. The client fully controls it; it is not signed or encrypted. |
| S2 | `request.form["theme"]`, `request.form["page_size"]` | request-time | UNTRUSTED for all sinks. They are narrowed by the allowlist and range checks before being stored. |
| S3 | `DEFAULT_PREFS`, `PREFS_COOKIE` | code-constant | Trusted for all sinks. |
| S4 | `time.time()` | runtime (server clock) | Trusted for all sinks. |

What comes in from outside is the `prefs` cookie (S1) and two form fields (S2). The design assumes that a cookie the server wrote earlier (B4) comes back unchanged at B1. Nothing enforces that: the cookie is plain base64-encoded pickle with no integrity protection. Whatever object comes out of S1 also goes straight into the template (B3).

## Findings

#### 1. Pickle deserialization of an attacker-controlled cookie gives unauthenticated remote code execution

**Severity:** Critical
**Location:** `subject.py:12-19` (sink at `:17`). Reachable from `subject.py:30` (`GET /dashboard`) and `subject.py:36` (`POST /prefs`).
**Boundary:** B1 (re-entry of B4)
**Move:** #7 Test the serialization boundary; #1 Trace the trust boundaries
**Confidence:** High

`pickle.loads` runs any callable named by a `__reduce__` payload while it decodes. An attacker builds an object whose `__reduce__` returns `(os.system, ("<cmd>",))`, pickles it, base64url-encodes it, and sends `Cookie: prefs=<blob>` to `/dashboard`. Neither route requires authentication. The `try/except Exception` at `:16-19` does not help (move #3): the payload runs during `loads`, before any exception could be raised, and it can return a valid dict so nothing goes wrong afterwards. The result is full compromise of the server process: secrets, the database, and lateral movement.

**Recommendation:** Stop using pickle for anything the client sends. Store prefs as JSON (`json.loads`) and validate the result against a strict schema: `theme` must be in the allowlist, `page_size` must be an int from 10 to 100, and `pinned` must be a bounded list of a fixed scalar type. To prevent tampering as well, use Flask's signed `session` or `itsdangerous`. Signing pickle is not enough, because a leaked key would then lead to RCE.

#### 2. A non-dict prefs object passes through without checks, so a forged cookie can make requests fail with a server error

**Severity:** Medium
**Location:** `subject.py:17`, `:30-31`, `:36-41`
**Boundary:** B1, B3
**Move:** #7 Type confusion on deserialization; #2 Implicit sanitization assumption
**Confidence:** Medium

This exists separately from the RCE and will remain after a naive switch to JSON unless the fix includes shape validation. `load_prefs` returns whatever object it decodes. If the cookie decodes to a list or string, `prefs["theme"] = ...` at `:38` raises `TypeError` and the request returns 500. `render_template` receives attacker-chosen values for `theme`, `page_size` and `pinned`. `dashboard.html` is not in scope. Jinja autoescaping is on by default for `.html` templates, but if the template uses `|safe`, puts `theme` into an attribute or `<style>` without quotes, or loops over `pinned` to build URLs, this becomes self-XSS or worse. Whether that happens depends on the template, which I did not read.

**Recommendation:** After deserializing, build a new dict from `DEFAULT_PREFS` and copy in only the fields that pass validation. Never pass the decoded object on directly.

#### 3. Prefs cookie has no `Secure` or `HttpOnly` flag

**Severity:** Low
**Location:** `subject.py:24`
**Boundary:** B4
**Move:** #6 Follow the secrets
**Confidence:** Medium

The cookie lasts a year and is sent over plain HTTP. Page script can also read and overwrite it. That matters only because of Finding 1: any XSS or network attacker who can set this cookie for a victim can plant a pickle payload. The payload still runs on the server, though, so this adds no new impact beyond Finding 1. Once Finding 1 is fixed, this is hardening.

**Recommendation:** Set `secure=True, httponly=True` on `set_cookie`.

## Endorsement Claims

- **Claim:** `POST /prefs` writes `prefs["theme"]` only when the submitted form value is exactly `"light"` or `"dark"`.
  **Location:** `subject.py:37-38`
  **Evidence:** read-static
  **Verified:** Read the membership test against the tuple `("light", "dark")` and the assignment that follows from `request.form["theme"]`.
  **Not verified:** The `theme` value that arrives through the cookie at `:36` (S1), which skips this check completely (see Finding 2).

- **Claim:** `POST /prefs` writes `prefs["page_size"]` only as an int from 10 to 100 inclusive, taken from the form field.
  **Location:** `subject.py:39-41`
  **Evidence:** read-static
  **Verified:** Read `str.isdigit()` followed by the `int()` range check. Unicode digit characters such as `"²"` pass `isdigit()`, but `int()` raises `ValueError` on them, so the result is an unhandled 500 and no bad value is stored. (This was checked by reading only, not by running it.)
  **Not verified:** The `page_size` value from the cookie (S1), and how `dashboard.html` uses it.

Move #11 bypass candidates for the form checks: `"²"` (traced: 500, nothing stored), `"0100"` (traced: equals 100, accepted, harmless), `" 50"` (traced: `isdigit` is False, rejected). Every bypass candidate was traced through the code. Even so, these checks are bypassed structurally by S1, so they are not offered as a security endorsement of the prefs data.

## Primitive sweep

Primitive: pickle deserialization / serialization
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `subject.py:17` `pickle.loads` | S1 cookie | none (base64 decode only) | Finding 1 (RCE) |
| `subject.py:23` `pickle.dumps` | S1-derived object + S2 | n/a (serialization of server-held object) | Cleared for code execution: dumping does not run untrusted code. It does re-emit whatever object came from S1. |

Primitive: HTML interpolation
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `subject.py:31` `render_template("dashboard.html", prefs=...)` | S1, S4 | Jinja autoescape (default for `.html`, not verified) | Finding 2. Template not in scope, so this is a partial disposition. |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Unauthenticated RCE via `pickle.loads` on cookie | Critical | B1 | `subject.py:17` | High |
| 2 | Decoded prefs never shape-validated; reaches template and handlers | Medium | B1, B3 | `subject.py:17,31,38` | Medium |
| 3 | Prefs cookie missing `Secure`/`HttpOnly` | Low | B4 | `subject.py:24` | Medium |

## Overall Assessment

This file is not safe to deploy. Any anonymous client can run code on the server with a single request, because a client-held cookie is decoded with `pickle`. The problem is the design choice to round-trip server objects through the client as pickle, not an off-by-one validation slip. It is still fixable in place: switch to JSON, rebuild a schema-validated dict starting from `DEFAULT_PREFS`, and optionally sign the cookie (or use Flask's `session`). Fixing Finding 1 is the one thing that matters most. Once that fix includes strict shape validation, it also takes care of Finding 2. The review is partial for B3, because I did not read `dashboard.html`.
