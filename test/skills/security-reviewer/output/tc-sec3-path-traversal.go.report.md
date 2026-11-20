**User goal:** Run a security review of `subject.go` and print the report to stdout. I won't save it to `docs/reviews/`.

---

Commit: 0856184281b5df5294e7c7d77abe11249f487c3c

# Security Review: subject.go

**User goal:** Security review of `subject.go`, printed to stdout.
**Scope:** `subject.go` (single file, `HandleDownload` handler)
**Date:** 2026-11-19

> ⚠️ **No code fact-check report provided.** Claims about security properties in comments and documentation have not been independently verified. For full verification, run the `code-fact-check` skill first or use the code-review orchestrator.

No HALT patterns matched. The main finding is path traversal, which is Critical, but path traversal isn't on the escalation list.

## Trust Boundary Map

```
B1: [HTTP query param `file`]          → [strings.HasSuffix(".csv") check] → [filepath.Join → os.Open]
B2: [auth middleware ctx value userKey] → [type assertion to *User]         → [path component user.ID]
B3: [filesystem under ExportDir]        → [os.Open / io.Copy]               → [HTTP response body + Content-Disposition]
```

**Input-source classification:**

```
S1: r.URL.Query().Get("file") — request-time    — UNTRUSTED (all sinks; path construction especially)
S2: user.ID (from ctx userKey) — request-time    — trusted for identity *if* middleware is sound (not in scope);
                                                   UNVERIFIED for path construction (format/charset of ID not visible)
S3: s.ExportDir               — deploy-time (assumed; set at struct construction) — trusted (all sinks)
S4: file names/contents on disk — runtime-mutable — untrusted toward response headers (filename interpolation)
```

The handler takes a filename from the attacker (S1) and builds a filesystem path from it. The only check is that the name ends in `.csv`. The code assumes that adding `user.ID` to the path confines the read to that user's directory, but nothing enforces that. `filepath.Join` resolves `..` segments, so the joined path can leave both the user directory and `ExportDir`.

## Findings

#### 1. Path traversal lets any user read other tenants' exports and any `.csv` file on the host

**Severity:** Critical
**Location:** `subject.go:22-29`
**Boundary:** B1 (with B3 as the exfiltration path)
**Move:** #2 (implicit sanitization assumption), #5 (invert access control), #11 (bypass enumeration)
**Confidence:** High

The `HasSuffix(name, ".csv")` check only looks at the file extension. It doesn't stop `name` from containing `/` or `..`. `filepath.Join(s.ExportDir, user.ID, name)` calls `Clean` on the result, which resolves `..` segments. Two examples:
- `?file=../victim-id/report.csv` resolves to `ExportDir/victim-id/report.csv`, which is another tenant's export.
- `?file=../../../../srv/app/data/customers.csv` resolves to a path outside `ExportDir` altogether.

Percent-encoded input (`%2e%2e%2f`) works the same way because `Query().Get` decodes it first. Any logged-in user can therefore read every tenant's exports, which is the whole dataset this endpoint is meant to protect. They can also read any `.csv` file the process can access. The per-user directory scoping is the only access control on this path, and it can be bypassed completely.

**Recommendation:** Treat `name` as a single path component. Reject it unless `filepath.IsLocal(name)` is true and `name` contains no separator (or `name == filepath.Base(name)`). If you're on Go ≥1.24, it's better to open through `os.OpenRoot(filepath.Join(s.ExportDir, user.ID))` and call `root.Open(name)`. That enforces confinement at the syscall level and also blocks escapes through symlinks.

#### 2. `user.ID` is used as a path component without validation

**Severity:** Medium
**Location:** `subject.go:16, 28`
**Boundary:** B2
**Move:** #1 (per-consequence trust), #5
**Confidence:** Low. This depends on how `User.ID` is populated, which is outside the scope.

`user.ID` may be trustworthy as an identity, but it isn't validated for use in a path. If it's empty, the path becomes `ExportDir/<name>` and the user can read shared top-level files. If it can contain `/` or `..` (for example, a username or an IdP-supplied subject such as `auth0|abc` or `a/b`), the per-user boundary moves or falls apart. Fixing Finding 1 doesn't fix this.

**Recommendation:** Require `user.ID` to be non-empty and to match a strict pattern (such as `^[A-Za-z0-9_-]+$`) before using it in the path. Alternatively, build the directory from an opaque, server-generated key.

#### 3. Filesystem-derived filename is interpolated into `Content-Disposition` unescaped

**Severity:** Low
**Location:** `subject.go:37`
**Boundary:** B3
**Move:** #2
**Confidence:** Medium

`filepath.Base(full)` is placed directly inside a quoted `filename="..."`. A file whose name contains `"` or `;` on disk would let someone inject extra header parameters, such as a misleading download filename. Go's `net/http` replaces CR/LF in header values when it writes them, so this doesn't allow response splitting. The attacker would also need a file with that name to already exist. Once Finding 1 is fixed, the filename is basically the user's own input, so the impact is small.

**Recommendation:** Build the header with `mime.FormatMediaType("attachment", map[string]string{"filename": base})`.

#### 4. Only the extension is checked, not the file type

**Severity:** Informational
**Location:** `subject.go:23, 29-38`
**Boundary:** B1, B3
**Move:** #8
**Confidence:** Medium

The handler opens anything whose name ends in `.csv`, including directories, FIFOs and device nodes. A FIFO would make the request block until a writer appears, which ties up the goroutine. This only matters after Finding 1, or if attackers can create files inside the export directory. There's also no `X-Content-Type-Options: nosniff` header. With `attachment` set, the risk is minimal.

**Recommendation:** After opening, call `f.Stat()` and require `Mode().IsRegular()`. Add `nosniff` as defense in depth.

### Untested bypass candidates

These are guard bypasses for the `.csv` suffix check and the join:
- **Symlinks inside `ExportDir/<user.ID>/`.** Whether this works depends on how export files are created and whether a user can influence their names or targets. That code isn't in scope.
- **Case and Unicode variants (`.CSV`, fullwidth characters).** These are rejected by the case-sensitive suffix check, so they're a functional limitation, not a bypass. I worked this out from the code but didn't run it.
- **Windows-style `..\`.** This only matters if the service runs on Windows, where `filepath` treats `\` as a separator. The deployment platform is unknown, so I didn't test it.

Tested candidates, traced through the code: `../victim/x.csv` (bypass), `../../../../abs/x.csv` (bypass), percent-encoded `..%2f` (bypass, decoded by `Query().Get`), absolute `/etc/x.csv` (not a bypass: it's joined under the user directory), embedded NUL (not a bypass: `os.Open` rejects paths containing NUL).

## Endorsement Claims

- **Claim:** If the request context has no `*User` under `userKey`, the handler returns 401 before reading any input or touching the filesystem.
  **Location:** `subject.go:16-20`
  **Evidence:** read-static
  **Verified:** I read the type assertion and the early `return` on `!ok`.
  **Not verified:** The middleware that sets `userKey`, i.e. whether it ever stores a non-nil `*User` for an unauthenticated request. A typed-nil `*User` would pass `ok` and then panic at `user.ID`. `userKey` and `User` aren't defined in this file.
  **route: code-fact-check** (pending execution verification)

- **Claim:** When the file can't be opened, the response is a fixed `"not found"` body and doesn't include the path or the OS error.
  **Location:** `subject.go:30-32`
  **Evidence:** read-static
  **Verified:** I read the error branch. `err` isn't written to the response.
  **Not verified:** Whether a recovery or logging middleware upstream logs the request, including the `file` parameter, somewhere with broader access.

## Primitive sweep

Primitive: path construction / file open

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `subject.go:28` `filepath.Join` | S1 `file`, S2 `user.ID`, S3 `ExportDir` | `.csv` suffix only | Finding 1 (S1 traversal), Finding 2 (S2 unvalidated) |
| `subject.go:29` `os.Open(full)` | S1/S2 via `full` | none beyond the line 28 guard | Finding 1, Finding 4 (non-regular files) |

Primitive: header value interpolation

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `subject.go:37` `Content-Disposition` | S4 on-disk name (S1-derived) | `filepath.Base`; net/http CR/LF replacement | Finding 3 |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Path traversal enables cross-tenant / arbitrary `.csv` read | Critical | B1, B3 | `subject.go:22-29` | High |
| 2 | `user.ID` used as path component without validation | Medium | B2 | `subject.go:16,28` | Low |
| 3 | Unescaped filename in `Content-Disposition` | Low | B3 | `subject.go:37` | Medium |
| 4 | Non-regular files opened; no `nosniff` | Informational | B1, B3 | `subject.go:23,29-38` | Medium |

## Overall Assessment

**Do not merge this as it stands.** The per-user directory is the endpoint's only access control, and a single `../` gets around it. Any authenticated user can download every other tenant's exports and any `.csv` file the process can reach. The problem is a missing confinement check, not a design flaw, so it can be fixed inside this function. The most important fix is to open files through `os.OpenRoot` on the per-user directory, or at minimum to reject any `name` that isn't a single local path component. After that, validate `user.ID` (Finding 2), because the confinement fix only works if that path component is also well-formed. The review covers this file only. The auth middleware and the code that creates export files weren't read, and the endorsement claims are still waiting on execution verification.
