**User goal:** Run a security review of `subject.go` and print the report here, without saving a file.

Commit: 7dace286a0b3d071ae3b15cc4b4ff64155dd47d0

# Security Review: subject.go

**Scope:** `subject.go` (a single file; `SessionFrom` and the code that builds `Handler` aren't in the repo)
**Date:** 2026-11-19

> ⚠️ **No code fact-check report provided.** Claims in comments and documentation about security properties haven't been checked independently. For full verification, run the `code-fact-check` skill first or use the code-review orchestrator.

No HALT patterns matched. There are no hardcoded secrets or keys, and TLS is never disabled. Authentication is present. The command is built from an argument vector, not a shell string, and its user-supplied argument has to match a strict regex.

## Trust Boundary Map

```
B1: [HTTP request: session ctx]    → [SessionFrom(r.Context()) check, :18]  → [handler body]
B2: [HTTP query param "sha"]       → [commitSHA regex ^[0-9a-f]{40}$, :24]  → [git argv, :32]
B3: [git object DB in RepoDir]     → [git show --stat (child process), :32] → [HTTP response body, :40]
B4: [server process env/RepoDir]   → [exec.CommandContext (inherits env)]   → [git child process]
```

```
S1: query param "sha"          — request-time    — UNTRUSTED (all sinks)
S2: session from r.Context()   — request-time    — trusted for authN only if SessionFrom is sound (not visible)
S3: Handler.RepoDir            — deploy-time (assumed; not visible where it's set) — trusted for path/exec sinks
S4: repo object contents       — runtime-mutable (anyone who can push) — UNTRUSTED for HTML/output sinks
                                 and for driver/config-triggered exec
S5: server process env (GIT_*) — deploy-time     — trusted
S6: timeout 5s / regex consts  — code-constant   — trusted
```

The only value the user controls directly is `sha` (S1). It's checked against a strict 40-hex regex and then passed as a separate argv element to `git`, so no shell ever sees it. The output of `git` (S4) can contain commit authors and messages written by whoever pushed to the repo. It goes back to the client unchanged. The code assumes that a valid hex ID always refers to a commit, and nothing enforces that.

## Findings

#### 1. The endpoint returns any object type, not just commits: a blob ID dumps the whole file

**Severity:** Medium
**Location:** `subject.go:24-40`
**Boundary:** B2, B3
**Move:** #2 (implicit sanitization assumption), #5 (invert the access model)
**Confidence:** Low. This only matters if the endpoint is meant to expose less than the full repo; see below.

The regex checks that `sha` looks like an object ID, not that it names a commit. `git show` takes any object ID. Given a blob it prints the raw file contents, given a tree it lists the tree, and given an annotated tag it shows the tag and its target. Any authenticated user who knows or learns a blob ID can therefore read the whole file through an endpoint called `CommitStat`. This includes objects that no branch points to anymore, such as a secret that was force-pushed out but not yet garbage-collected. If every session holder is already allowed to read the entire repo, this is only a contract mismatch. If the endpoint is meant to expose commit summaries only, or if sessions are scoped per user or per repo, it breaks that read boundary.

**Recommendation:** Pass `sha+"^{commit}"`, which makes git fail on anything that isn't a commit or doesn't peel to one. Or run `git cat-file -t` first and require the output `commit`. If any repo-level authorization exists, apply it here too; `SessionFrom` only checks that a session exists.

#### 2. No limit on concurrent work or output size per request

**Severity:** Medium
**Location:** `subject.go:29-40`
**Boundary:** B1, B3
**Move:** #8 (a million of these)
**Confidence:** Medium

Each authenticated request starts a `git` process. Nothing limits how many run at once or how often one user can call the endpoint. `cmd.Output()` keeps all of stdout in memory before writing it out. The 5-second timeout limits how long each request runs but not how much memory it uses. A large commit `--stat`, or a large blob reached through Finding 1, can push a lot of data into memory within those 5 seconds. Many parallel requests multiply both the process count and the memory. Exploiting this needs a valid session, so the attack surface is limited to authenticated users.

**Recommendation:** Add a per-session rate limit or a semaphore that caps concurrent `git` processes. Read stdout through `io.LimitReader` instead of `Output()`, or stream it with a size cap. Fixing Finding 1 also removes the large-blob case.

#### 3. The timeout may not end the request if git starts child processes (`WaitDelay` not set)

**Severity:** Low
**Location:** `subject.go:29-33`
**Boundary:** B4
**Move:** #3 (error path)
**Confidence:** Low

`CommandContext` kills only the direct `git` process. If git starts children that keep the stdout pipe open, `Output()` can block after the context expires. Examples are diff/textconv drivers configured in the repo or system git config, or an external diff helper. Since Go 1.20, setting `cmd.WaitDelay` caps this wait. Plain `git show --stat` with a default config usually doesn't start such helpers, so this depends on config that isn't visible here.

**Recommendation:** Set `cmd.WaitDelay` (for example 1s) and add `--no-ext-diff --no-textconv` to the git argv. That also stops attribute-selected drivers from running when commits are viewed.

#### 4. Repo content returned without `X-Content-Type-Options: nosniff`

**Severity:** Informational
**Location:** `subject.go:39-40`
**Boundary:** B3
**Move:** #2
**Confidence:** Medium

Author names, commit subjects and, through Finding 1, blob contents are written by whoever pushes, and they're reflected to the client. The response is `text/plain; charset=utf-8`, which current browsers don't sniff into HTML. Adding `nosniff` is a cheap extra layer, which matters most if blob output stays reachable.

**Recommendation:** Add `w.Header().Set("X-Content-Type-Options", "nosniff")`.

## Untested bypass candidates

None. Every regex bypass candidate was checked by reading the code (see Endorsement Claims).

## Endorsement Claims

- **Claim:** The `sha` regex rejects values with a leading `-`, a trailing newline, uppercase hex or a different length. So `sha` can't be read as a git option and can't carry extra content.
  **Location:** `subject.go:11, 24`
  **Evidence:** read-static
  **Verified:** The pattern is `^[0-9a-f]{40}$`, compiled with no `(?m)` flag. In Go RE2, `$` without `m` matches only at the end of the text, so `"<40hex>\n"` fails. `-` isn't in the character class. Percent-encoded input such as `%0a` is decoded by `Query()` before the match, so it's still rejected. For repeated `?sha=` parameters, `Get` returns the first value, and that same value is the one checked and then used (no check/use gap).
  **Not verified:** How git resolves a 40-hex string when a ref with that exact name also exists. Git prefers the object ID and warns, but this wasn't run. Not executed against a test suite.
  **route: code-fact-check**

- **Claim:** The user input reaches `git` as one argv element, with no shell interpolation.
  **Location:** `subject.go:32`
  **Evidence:** read-static
  **Verified:** It uses `exec.CommandContext` with fixed literal arguments, plus `h.RepoDir` and `sha` as separate elements. No `sh -c`.
  **Not verified:** Where `h.RepoDir` is assigned (the constructor or wiring isn't in scope), and whether it could ever come from a runtime-mutable source.
  **route: code-fact-check**

- **Claim:** The handler stops before any work when there's no session.
  **Location:** `subject.go:18-21`
  **Evidence:** read-static
  **Verified:** If `!ok`, it calls `http.Error` and then `return`. Nothing falls through.
  **Not verified:** How `SessionFrom` is implemented: what sets that context value and whether it checks expiry or revocation. It isn't in the repo.
  **route: code-fact-check**

- **Claim:** A failed git call doesn't send stderr or partial output to the client.
  **Location:** `subject.go:33-37`
  **Evidence:** read-static
  **Verified:** If `err != nil`, the response is the fixed string "commit not found" and `out` is thrown away.
  **Not verified:** Whether the server logs elsewhere capture `*exec.ExitError.Stderr` (no logging appears in this file).

## Primitive sweep

```
Primitive: os/exec process execution
| Call site          | Source             | Guard                          | Disposition |
|--------------------|--------------------|--------------------------------|-------------|
| `subject.go:32`    | S1 sha, S3 RepoDir | 40-hex regex; argv (no shell)  | Cleared for injection. Findings 1, 2, 3 (object-type, resource, timeout) |
```

This is the only process-exec call in scope. There's no SQL, deserialization, HTML templating, path join from user input, or URL fetch.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Any object type accepted; blob ID dumps file contents | Medium | B2, B3 | `subject.go:24-40` | Low |
| 2 | No concurrency, rate or output-size limit | Medium | B1, B3 | `subject.go:29-40` | Medium |
| 3 | `WaitDelay` not set; timeout may not end the request | Low | B4 | `subject.go:29-33` | Low |
| 4 | No `nosniff` header on repo-content response | Informational | B3 | `subject.go:39-40` | Medium |

## Overall Assessment

The basic protections are in place. The command-injection and option-injection guard holds up against every bypass I tried, there's no shell, the authentication check returns early, and errors don't leak details. The issues left are about scope and resources, not injection, and each can be fixed in a line or two without changing the design. The most important fix is to restrict the lookup to commits with `sha+"^{commit}"`, so this endpoint can't read arbitrary files or unreferenced objects. Whether that matters depends on whether every session holder is supposed to see the whole repo. That can't be told from this file, and neither can how `SessionFrom` works. No findings within the code paths read are severe enough to block a merge. The endorsement claims are still waiting on execution-backed verification.
