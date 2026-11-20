# Security Review: subject.go

**Scope:** `subject.go` (handler `CommitStat` in package `repoview`)
**Date:** 2026-11-20
Commit: ce4a8bb4969f076cb9df74236d4dd8138bdfbfe8
**User goal:** Check `subject.go` for security vulnerabilities and print the report to stdout. No file is saved.

> ⚠️ **No code fact-check report provided.** Claims about security properties in comments and documentation have not been independently verified. For full verification, run the `code-fact-check` skill first or use the code-review orchestrator.

No `docs/constraints.md` exists in the repo, so every attacker the code exposes is in scope. `SessionFrom` is defined outside the scope (it is not in the repo), so its behavior is assumed, not verified.

## Trust Boundary Map

```
B1: [HTTP request ctx]            → [SessionFrom(r.Context()) presence check] → [CommitStat body]
B2: [query param "sha"]           → [commitSHA regex ^[0-9a-f]{40}$]          → [git argv (exec, no shell)]
B3: [git repo objects in RepoDir] → [git show --stat output, unfiltered]      → [HTTP response body, text/plain]
B4: [authenticated caller]        → [none: no rate/concurrency limit]         → [git subprocess spawn, 5s timeout]
```

**Input sources:**

```
S1: r.URL.Query()["sha"]         — request-time    — UNTRUSTED (all sinks)
S2: session from r.Context()     — request-time    — trusted only as "some session exists";
                                                      carries no authorization for this repo
S3: Handler.RepoDir              — deploy-time     — trusted for path/exec sinks (set at construction)
S4: commit/blob contents in repo — runtime-mutable if anyone can push — UNTRUSTED toward
                                    HTML sinks; this handler only emits text/plain
S5: "git" binary name, fixed args — code-constant — trusted
```

The only value an attacker controls directly is `sha` (S1). It is checked against an anchored regex before it reaches `exec.CommandContext`, which takes a list of arguments and does not use a shell. Repository content (S4) goes back to the client unchanged. The handler checks that a session exists. It does not check what that session is allowed to see.

## Findings

#### 1. Authentication without authorization: any session can read any object in RepoDir

**Severity:** Medium
**Location:** `subject.go:18-21, 32`
**Boundary:** B1, B3
**Move:** #5 (Invert the access control model)
**Confidence:** Medium

The guard only checks `ok` from `SessionFrom`. The session value is thrown away (`_`), and nothing ties the user to `h.RepoDir`. Also, `git show <sha>` is not limited to commits. Given a 40-character blob or tree id, it prints the raw file contents or a tree listing. Any logged-in user who knows or obtains an object id can read files at any revision, including content from branches they shouldn't see. In a single-tenant deployment where every user may read the whole repo, this is fine. In a multi-tenant setup, or one with access controlled per branch or per repo, it is an access bypass. Which case applies depends on how the routing registers `Handler` and on what `SessionFrom` returns, and neither is in scope.

**Recommendation:** Check the session's permission for this repo. Limit the lookup to commits, either with `sha + "^{commit}"` or by checking `git cat-file -t` first. If access is controlled per ref, also check that the commit is reachable from a ref the user may read.

#### 2. No rate or concurrency limit on spawning a subprocess per request

**Severity:** Medium
**Location:** `subject.go:29-33`
**Boundary:** B4
**Move:** #8 ("What if there are a million of these?")
**Confidence:** Medium

Each authenticated request that passes the regex forks a `git` process. That process can run for up to 5 seconds, and `cmd.Output()` holds all of its stdout in memory with no size cap. One low-privilege user can send many requests at once, each naming a large commit (or a large blob, see Finding 1). That can use up process slots, CPU and memory, because nothing limits how many run at the same time. The 5-second timeout limits how long each request lasts, but not how many requests run together.

**Recommendation:** Put a semaphore or worker pool around the exec and add a per-session rate limit. Stream stdout through an `io.LimitReader` instead of buffering it all with `Output()`.

#### 3. Response lacks `X-Content-Type-Options: nosniff`

**Severity:** Informational
**Location:** `subject.go:39-40`
**Boundary:** B3
**Move:** #2 (Implicit sanitization assumption)
**Confidence:** Low

The handler writes author names, commit subjects and (via Finding 1) blob contents taken from S4, and labels them `text/plain; charset=utf-8`. Current browsers don't sniff `text/plain` into HTML when a charset is set, so I don't know of a working attack. Adding `nosniff` is cheap protection if anyone can push to the repo.

**Recommendation:** Set `X-Content-Type-Options: nosniff`. Consider adding `Content-Disposition: inline` with a sandboxed CSP if blobs stay reachable.

## Untested bypass candidates

Guardrail: the `commitSHA` regex (B2). Candidates and what happened to each:

- **Tested: `"<40 hex>\n"` (trailing newline).** Go RE2's `$` matches only at the end of the text when the `m` flag is off, so this is rejected.
- **Tested: leading `-` / option injection (`--output=/tmp/x`).** The character class `[0-9a-f]` doesn't allow `-`, so this is rejected. No shell is involved because `exec.CommandContext` passes the arguments directly.
- **Tested: uppercase hex, or a short or abbreviated SHA.** Both are rejected by the character class and the `{40}` count.
- **Tested: a 40-hex blob or tree id instead of a commit.** It passes the regex and `git show` prints the object. This is Finding 1.
- **Listed: a ref whose name is 40 hex characters.** Git resolves a full 40-hex string as an object id first and only warns if a ref has the same name. I didn't run this to confirm it has no effect.
- **Listed: repo-local config or attributes that run code during `git show --stat` (`diff.*.textconv`, `core.fsmonitor`).** Only relevant if untrusted parties can write RepoDir's `.git/config` or `info/attributes`. That ownership is outside the scope, so I didn't test it.

Guardrail: the `SessionFrom` presence check (B1). I didn't test it because `SessionFrom` isn't in scope, so I can't tell whether an expired or forged session yields `ok == true`.

## Endorsement Claims

Neither guardrail can be endorsed because both have untested bypass candidates. Scoped observations only:

- **Claim:** The `sha` value reaches `git` as a single argument with no shell in between.
  **Location:** `subject.go:32`
  **Evidence:** read-static
  **Verified:** I read the `exec.CommandContext` call. It uses a fixed binary name and a literal argument list, and contains no `sh -c`.
  **Not verified:** whether a `git` wrapper on the server's `PATH` re-parses its arguments.
  **route: code-fact-check** (*pending execution verification*)

- **Claim:** Error responses don't include git's stderr or the error text.
  **Location:** `subject.go:34-36`
  **Evidence:** read-static
  **Verified:** I read the error branch. It writes a fixed "commit not found" string, and `cmd.Output()` captures stderr into `err` without echoing it.
  **Not verified:** whether middleware upstream logs or returns `err`. Nothing here passes it on, but the server's panic and recovery handling wasn't read.

## Primitive sweep

```
Primitive: os/exec (process exec)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `subject.go:32` | S1 sha, S3 RepoDir | anchored hex regex; argument list, no shell | cleared for injection (bypass candidates above); Findings 1 and 2 for object scope and DoS |
```

There are no other dangerous primitives (SQL, deserialization, path joins with request data, HTML templating, or `eval`) in scope.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Authentication without authorization; blob or tree ids readable | Medium | B1, B3 | `subject.go:18-21,32` | Medium |
| 2 | Unbounded subprocess spawning and output buffering | Medium | B4 | `subject.go:29-33` | Medium |
| 3 | Missing `nosniff` on repo-derived output | Informational | B3 | `subject.go:39-40` | Low |

## Overall Assessment

The command-injection surface is handled well. The anchored regex blocks option injection and trailing-newline tricks, and the argument-list form of `exec` avoids shell parsing. No HALT pattern applies. The two real issues can be fixed in this file and don't point to a design problem. The more important one is Finding 1: the handler confirms someone is logged in but never asks what they may see, and `git show` will print any object, not just commits. How serious that is depends on whether the deployment controls access per user or per ref, which this file doesn't show. Fix it first by checking the session's permission and adding `^{commit}`. Then add concurrency and output limits for Finding 2. No findings within the code paths read beyond these; endorsement claims pending execution verification.
