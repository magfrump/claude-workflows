# Security Review: subject.py

**Scope:** `subject.py` (whole file, as requested)
**Date:** 2026-11-20
**User goal:** Find security vulnerabilities in `subject.py` and print the report to stdout.
Commit: bfe6771986a64e4f7cb03b84aa96f9acd6b5d87b

> ⚠️ **No code fact-check report provided.** Claims about security properties in comments and
> documentation have not been independently verified. For full verification, run the
> `code-fact-check` skill first or use the code-review orchestrator.

> 🚨 **HALT: ESCALATE TO HUMAN**
>
> **Pattern:** Command injection in user-facing code. This is unsafe deserialization that gives arbitrary code execution, which covers everything command injection can do.
> **Location:** `subject.py:17`
> **Detail:** `pickle.loads()` runs on the raw `prefs` cookie, which the client fully controls. Anyone can send a crafted cookie to `GET /dashboard` or `POST /prefs`, with no login, and run any code as the Flask process (for example, `__reduce__` → `os.system`).
>
> This finding requires immediate human attention before the remaining review is actionable.
> Do not merge or deploy until this is resolved.

## Trust Boundary Map

```
B1: [HTTP Cookie "prefs" (client)]  → [base64 decode → pickle.loads, subject.py:17] → [prefs dict in app]
B2: [HTTP form fields theme/page_size] → [allowlist / range check, subject.py:37-41] → [prefs dict → Set-Cookie]
B3: [prefs dict (origin: B1)]       → [render_template, subject.py:31]               → [HTML response to browser]
```

**Input sources**

```
S1: request.cookies["prefs"]   — request-time  — UNTRUSTED (all sinks; the client writes it, and it is unsigned)
S2: request.form["theme"]      — request-time  — UNTRUSTED (all sinks)
S3: request.form["page_size"]  — request-time  — UNTRUSTED (all sinks)
S4: DEFAULT_PREFS / PREFS_COOKIE — code-constant — trusted (all sinks)
```

All the state is kept on the client in a cookie with no signature. The code checks form input before writing it to the cookie (B2), then trusts whatever comes back in the cookie when reading it (B1). It assumes "we wrote it, so it's safe." Nothing backs that up: the client can replace the cookie with anything. The B2 checks are therefore one-way, and B1 is the real entry point.

## Findings

#### 1. Unauthenticated RCE through pickle deserialization of the cookie

**Severity:** Critical
**Location:** `subject.py:12-19` (sink at line 17)
**Boundary:** B1
**Move:** #7 Serialization boundary, #2 Implicit sanitization assumption
**Confidence:** High

`load_prefs()` base64-decodes the `prefs` cookie and passes it straight to `pickle.loads`. Pickle can run code while it loads: an object's `__reduce__` can return `(os.system, ("cmd",))`, and that call runs inside `loads`. The client sets cookies, so an attacker without an account can build the payload offline and send it with `curl -b prefs=<b64>` to either route. Both call `load_prefs()` before doing anything else. The `except Exception` on line 18 gives no protection, because the payload has already run by the time any exception could be raised. The result is full server compromise at the Flask process's privilege level: secrets, database credentials, lateral movement.

**Recommendation:** Don't unpickle client data. Store prefs as JSON in Flask's signed `session`, or sign with `itsdangerous`, or keep them server-side keyed by user ID. Validate the shape after decoding either way (see Finding 2).

#### 2. Values read from the cookie skip the write-side checks (unvalidated prefs reach the template)

**Severity:** Medium
**Location:** `subject.py:30-31`, `36-41`
**Boundary:** B1, B3
**Move:** #2 Implicit sanitization assumption, #11 Bypass enumeration
**Confidence:** Low. The impact depends on `templates/dashboard.html`, which is not in scope and not in the repo.

The `theme` allowlist and the `page_size` range only apply on the `POST /prefs` path. Even with pickle replaced by plain JSON, a client can set the cookie directly to `{"theme": "\"><script>…", "page_size": 10**9, "pinned": [...]}`. Those values go to `render_template` and any later code without being checked. If the template writes `prefs.theme` into a `<style>` or `<script>` context, uses `|safe`, or uses `page_size` as a query `LIMIT`, you get XSS (cookie tossing from a sibling subdomain makes it more than self-XSS) or unbounded queries. The value can also be a non-dict (for example, a list). Then `prefs["theme"] = …` on line 38 raises `TypeError` and returns a 500.

**Recommendation:** Check the cookie on read: require a dict, compare `theme` against the allowlist, clamp `page_size`, check element types in `pinned`, and fall back to defaults if anything fails. Signing the cookie (Finding 1 fix) stops tampering, but read-time checks are still needed for schema changes.

#### 3. Prefs cookie has no `Secure` or `HttpOnly` flag

**Severity:** Low
**Location:** `subject.py:24`
**Boundary:** B1
**Move:** #6 Follow the secrets
**Confidence:** Medium

`set_cookie` sets only `max_age` (1 year) and `samesite="Lax"`. Without `Secure`, the cookie goes out over plain HTTP. Without `HttpOnly`, any XSS (see Finding 2) can read or rewrite it. These are hardening gaps today. They matter more if the cookie later carries anything sensitive.

**Recommendation:** Add `secure=True, httponly=True`.

#### 4. `DEFAULT_PREFS` is copied shallowly, so the `pinned` list is shared across requests

**Severity:** Informational
**Location:** `subject.py:9`, `15`, `19`
**Boundary:** Internal (no boundary). This is process-wide state shared between users. No input crosses a boundary today, but the risk is cross-user data leakage.
**Move:** #8 "A million of these"

`dict(DEFAULT_PREFS)` copies only the top level, so every default prefs dict points to the same `pinned` list object. Nothing in this file changes `pinned`. If future code calls `prefs["pinned"].append(...)`, one user's pins would be written into the global default and shown to every user who has no cookie, for as long as the process runs.

**Recommendation:** Use `copy.deepcopy(DEFAULT_PREFS)`, or a factory function that builds a fresh dict each time.

#### 5. `page_size` check crashes on non-ASCII digits

**Severity:** Informational. The only effect is an error on the attacker's own request, so no security property is violated.
**Location:** `subject.py:39-41`
**Boundary:** B2
**Move:** #11 Bypass enumeration, #3 Error path

`str.isdigit()` is true for characters like `"²"`, but `int("²")` raises `ValueError`. That gives an unhandled 500 on this request only. Strings over 4300 digits also raise `ValueError` (the int/str conversion limit in Python 3.11+).

**Recommendation:** Use `size.isascii() and size.isdigit()`, or `try: int(size)`.

## Untested bypass candidates

Bypass candidates I traced for the B2 guards:
- `theme="Dark"` / `"dark "` / repeated `theme` fields: rejected. The check is an exact tuple match, and `form.get` returns the first value.
- `page_size="١٠"` (Arabic-Indic digits): accepted and stored as the int `10`, which is harmless.
- `page_size="²"`: raises a 500 (Finding 5).
- Writing the cookie directly instead of using the form: bypasses both guards completely (Finding 2).

Not tested:
- **Template-context injection through `prefs.*`:** `dashboard.html` is not in the repo, so I can't tell how the values are rendered (autoescape, `|safe`, script/style contexts).

## Endorsement Claims

- **Claim:** The prefs cookie is set with `SameSite=Lax`, so browsers will not send it on cross-site `POST /prefs` requests.
  **Location:** `subject.py:24`
  **Evidence:** read-static
  **Verified:** Read the `set_cookie` call arguments.
  **Not verified:** Browser handling of the `Set-Cookie` header in the 204 response to a cross-site top-level POST. A forged form submission still makes the server reply with a cookie built from defaults, which could reset the victim's prefs.

- **Claim:** On the form path, `prefs["theme"]` is assigned only from the literal values `"light"` or `"dark"`.
  **Location:** `subject.py:37-38`
  **Evidence:** read-static
  **Verified:** The membership test and the assignment that follows, including the multi-value form case.
  **Not verified:** The value of `prefs["theme"]` that was already in the cookie (line 36). It is never re-checked, per Finding 2.

## Primitive sweep

```
Primitive: pickle deserialization
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `subject.py:17` pickle.loads | S1 cookie | none (try/except only) | Finding 1 (RCE) |
| `subject.py:23` pickle.dumps | S2/S3 (+S1 carried over) | n/a (serialization out) | cleared: not a code-execution sink; resolved by Finding 1's fix |

Primitive: HTML interpolation
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `subject.py:31` render_template("dashboard.html") | S1 via prefs | Jinja autoescape (default for .html, not confirmed) | not analyzed: template not in repo; see Finding 2 |
```

The HTML-interpolation row is undisposed, so this review is **partial** on that sink.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Unauthenticated RCE via `pickle.loads` on the cookie | Critical | B1 | `subject.py:17` | High |
| 2 | Cookie-read values skip write-side checks | Medium | B1, B3 | `subject.py:30-41` | Low |
| 3 | Cookie lacks `Secure`/`HttpOnly` | Low | B1 | `subject.py:24` | Medium |
| 4 | Shallow copy shares the `pinned` list across requests | Informational | Internal | `subject.py:9,15,19` | High |
| 5 | `isdigit()`/`int()` mismatch causes a 500 | Informational | B2 | `subject.py:40` | High |

## Overall Assessment

This change is **not safe to merge**. Finding 1 lets anyone, without logging in, run code on the server with a single request. It comes from a design choice, using an unsigned pickled cookie as the client-side store, not a one-line slip. It can still be fixed without restructuring the app: switch to JSON in Flask's signed session, or to server-side storage. The secondary problem is the idea that checking values on write makes them safe on read. Anything the client stores has to be re-checked when it comes back (Finding 2). Fix first: remove `pickle.loads` on request data. The template sink was not reviewed because `dashboard.html` is not in the repo, so even after these fixes this review supports only *"no findings beyond those listed within the code paths read; endorsement claims pending execution verification."*
