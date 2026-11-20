# Security Review: subject.go

**Scope:** `subject.go` (single file, as you specified)
**Date:** 2026-11-20
Commit: c1e3cc9f0bb581630b5ede184d4186ac5f7993e9

**User goal:** Find the security flaws in the `subject.go` export-download handler and print the report to stdout.

> ⚠️ **No code fact-check report provided.** Claims about security properties in comments and
> documentation have not been independently verified. For full verification, run the
> `code-fact-check` skill first or use the code-review orchestrator.

*(Note: `userKey`, `User` and the middleware that sets the request context are defined outside this file and were not read. The repo contains only `subject.go`, and there's no `docs/constraints.md`, so every attacker the code exposes is treated as in scope.)*

## Trust Boundary Map

```
B1: [HTTP request context (auth middleware)] → [type assertion r.Context().Value(userKey).(*User)] → [user.ID used as path segment]
B2: [query param ?file= (attacker-controlled)] → [HasSuffix(".csv") check + filepath.Join]       → [os.Open on server filesystem]
B3: [server filesystem contents]             → [io.Copy / Content-Disposition]                  → [HTTP response to client]
```

| Label | Source | Mutability | Trust classification |
|---|---|---|---|
| S1 | `r.URL.Query().Get("file")` | request-time | UNTRUSTED for all sinks (path construction, response headers) |
| S2 | `user.ID` from request context | runtime-mutable (comes from the user store or session, set by middleware not shown here) | Trusted to identify the user only if the middleware is sound. UNTRUSTED for path construction unless the ID format is enforced (not visible here) |
| S3 | `s.ExportDir` | deploy-time | trusted for all sinks |
| S4 | File contents under `ExportDir` | runtime-mutable (export jobs write them) | UNTRUSTED for HTML sinks. Here it only reaches a CSV attachment body |

The handler takes an attacker-controlled filename (S1) and joins it into a filesystem path under a per-user directory. The only check is that the name ends in `.csv`. The code assumes that `filepath.Join` plus a suffix check keeps the path inside `ExportDir/<user.ID>`. It doesn't: `filepath.Join` cleans `..` segments, it doesn't stop them.

## Findings

#### 1. Path traversal lets a user read other users' exports and any `.csv` file on the host

**Severity:** High
**Location:** `subject.go:22-29`
**Boundary:** B2
**Move:** #2 (implicit sanitization assumption), #5 (invert the access control model), #11 (guardrail bypass)
**Confidence:** High

The per-user directory is supposed to keep each user to their own exports, but nothing enforces that. `filepath.Join(ExportDir, user.ID, name)` calls `Clean`, which resolves `..` instead of rejecting it. Two examples:

- `?file=../victim-id/payroll.csv` resolves to `ExportDir/victim-id/payroll.csv`. Any logged-in user can read any other user's export if they know or guess the user ID. This is an IDOR (insecure direct object reference) that bypasses the per-user isolation entirely.
- `?file=../../../../srv/app/secrets.csv` escapes `ExportDir` altogether and reads any file ending in `.csv` that the process can read.

`Query().Get` percent-decodes the value first, so `..%2F` behaves exactly like `../`. The `.csv` suffix check limits which files can be read, but it doesn't confine the path.

**Recommendation:** Reject any `name` that isn't a single plain path element: `name != filepath.Base(name)`, or a name containing `/`, `\` or `..`. Better still, use an allowlist regex like `^[A-Za-z0-9._-]+\.csv$`. Then check that the resolved path is still inside `filepath.Join(ExportDir, user.ID)`. On Go 1.24+, open the user directory with `os.OpenRoot` and call `root.Open(name)`, which rejects escapes and symlinks that leave the root. Ideally, look exports up by an opaque ID with an ownership check in the database instead of a filename.

#### 2. `user.ID` goes into the path without validation

**Severity:** Medium
**Location:** `subject.go:16, 28`
**Boundary:** B1, B2
**Move:** #1 (trust boundaries, runtime-mutable ⇒ compromise-reachable)
**Confidence:** Low

`user.ID` is used directly as a path segment. If an ID can ever be empty, `.`, contain `/`, or contain `..`, the per-user directory collapses or shifts. For example, an empty ID resolves to `ExportDir/<name>`, which could expose shared exports. Whether this can happen depends on how IDs are generated or set (for instance, a user-chosen username used as the ID). That code isn't in scope, so this finding depends on it.

**Recommendation:** Check that `user.ID` matches a strict format (UUID or numeric) before using it in a path, or map users to directories through a server-generated key.

#### 3. `Content-Disposition` filename isn't escaped

**Severity:** Low
**Location:** `subject.go:37`
**Boundary:** B2, B3
**Move:** #2
**Confidence:** Medium

`filepath.Base(full)` comes from the attacker-supplied name and is put inside a quoted header value without escaping. A name like `a";x=y.csv` breaks out of the quoted string and injects extra header parameters. Go's `net/http` replaces CR/LF in header values, so this doesn't give header splitting. The impact is limited to a mangled or attacker-chosen download filename, and since the attacker is the one downloading, it mostly matters if a crafted link is sent to a victim.

**Recommendation:** Build the header with `mime.FormatMediaType("attachment", map[string]string{"filename": base})`, or apply the strict filename allowlist from Finding 1. The allowlist fixes this as well.

#### 4. Non-regular files aren't rejected

**Severity:** Informational
**Location:** `subject.go:29-38`
**Boundary:** B3
**Move:** #8
**Confidence:** Low

`os.Open` succeeds on directories, FIFOs and device nodes. Combined with Finding 1, a `.csv`-named FIFO or special file anywhere readable could make a request block forever, holding a goroutine and file descriptor. This needs such a file to exist, which is unlikely. Fixing Finding 1 removes most of the exposure.

**Recommendation:** After opening, call `f.Stat()` and require `Mode().IsRegular()`.

## Untested bypass candidates

These apply to the guard on S1 (the `.csv` suffix check plus `filepath.Join`):

| Candidate | Status |
|---|---|
| `../<other-id>/x.csv` | **Tested** (traced): `Join`/`Clean` resolves it to another user's directory. This is Finding 1. |
| `..%2F..%2Fetc%2Fx.csv` | **Tested** (traced): `Query().Get` decodes it to `../../etc/x.csv`, which escapes. Same as Finding 1. |
| `/etc/x.csv` (absolute) | **Tested** (traced): `Join` treats it as relative, giving `ExportDir/<id>/etc/x.csv`. No escape. |
| `x.csv\x00.txt` / NUL injection | **Tested** (traced): the suffix check fails, and Go's `os.Open` rejects NUL anyway. No bypass. |
| `..\\other\\x.csv` on a Windows host | **Listed**: on Windows `\` is a path separator, so traversal works the same way. Not checked here because the deployment OS is unknown. |
| A symlink inside `ExportDir/<id>` pointing outside | **Listed**: `os.Open` follows symlinks. This depends on whether the export writer can be made to create symlinks, and that code isn't in scope. |

## Primitive sweep

Primitive: filesystem path construction / `os.Open`

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `subject.go:28` `filepath.Join(s.ExportDir, user.ID, name)` | S3, S2, S1 | `.csv` suffix only | Finding 1 (traversal), Finding 2 (ID segment) |
| `subject.go:29` `os.Open(full)` | S1 via `full` | none beyond the above | Finding 1, Finding 4 |
| `subject.go:37` `filepath.Base(full)` → header | S1 | none | Finding 3 |

The file has no other dangerous primitives (exec, SQL, deserialization, HTML).

## Endorsement Claims

- **Claim:** Requests with no `*User` in the context get a 401 and return before touching the filesystem.
  **Location:** `subject.go:16-20`
  **Evidence:** read-static
  **Verified:** The type assertion's `!ok` branch calls `http.Error` and then `return`.
  **Not verified:** Whether the middleware that fills `userKey` is mounted on this route and authenticates the user properly. That code is outside `subject.go`.
  **route: code-fact-check** (*pending execution verification*)

- **Claim:** `os.Open` errors return a generic "not found" without the path or error text.
  **Location:** `subject.go:30-32`
  **Evidence:** read-static
  **Verified:** The error branch writes the fixed string `"not found"`.
  **Not verified:** Whether a 404 vs. 200 response lets an attacker probe which `.csv` files exist, once combined with Finding 1. It does, until Finding 1 is fixed.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Path traversal via `?file=` gives cross-user and host `.csv` reads | High | B2 | `subject.go:22-29` | High |
| 2 | `user.ID` used in path without validation | Medium | B1, B2 | `subject.go:28` | Low |
| 3 | Unescaped `Content-Disposition` filename | Low | B2, B3 | `subject.go:37` | Medium |
| 4 | Non-regular files can be opened | Informational | B3 | `subject.go:29-38` | Low |

## Overall Assessment

This handler isn't safe to merge. The core problem (Finding 1) is that the code treats `filepath.Join` as if it confined the path, when it only cleans it. Any logged-in user can read other users' exports and any `.csv` file the process can read. The fix belongs in this handler and is small: allow only a plain filename (which also fixes Finding 3), then open it inside the user's directory with `os.OpenRoot` or with an explicit check that the path stays inside it. Longer term, serving exports by an opaque database ID with an ownership check would remove the need to trust filenames at all. The single most important fix is to reject `..` and path separators in `file`, or to use `os.OpenRoot`.
