# Security Review — fscompat-clean (d86d2dc..2cd3b67)

**Scope:** `git diff d86d2dc..2cd3b67` — extraction of `dataDir()` (Vercel → `/tmp`, else `<cwd>/data`), its adoption by `app/lib/analytics/persist.ts` and `app/lib/llm/cache.ts`, and the review-fix commit `2cd3b67` (per-instance docstring caveat, rest-args dropped, README ref dropped, `dataDir.test.ts` added).
**Date:** 2026-08-06
**Based on:** merged code fact-check (k=3, 0 Incorrect / 0 Stale) — documented behavior taken as foundation and not re-verified.
Commit: 2cd3b67

---

### Trust Boundary Map

The diff does not add a network surface; it **relocates the destination of every server-side write** from a repo-owned, single-purpose directory to a process-wide, platform-owned, conventionally-shared one. Every boundary below existed before the diff on the left-hand side; what changed is the right-hand side — the sink.

- **B1: Untrusted HTTP request body (`userContent`, `systemPrompt` inputs to `callLlm`) → `computeHash()` sha256 hex digest → filename component in `join(CACHE_DIR, `${hash}.json`)`** — attacker-controlled content reaches a filesystem path, but only after passing through a hex-digest chokepoint. The chokepoint is the whole defense here, and it holds: `createHash("sha256").digest("hex")` cannot emit `/`, `.`, or NUL, so no traversal or absolute-path escape is reachable from request content. What the attacker *does* retain across this boundary is the ability to mint an unbounded number of distinct, never-colliding filenames.
- **B2: Process environment (`process.env.VERCEL`) → truthiness test in `dataDir()` → root of every persistence path in the app** — a single unvalidated environment string, set by the platform and inherited by anything the process inherits from, decides whether writes land in a repo-private directory or in a shared, world-traversable one. This is a configuration-to-filesystem-authority boundary; nothing downstream re-checks it.
- **B3: Other local principals on the host (any process that can create entries in `/tmp`) → pre-created path at a fixed, predictable name (`/tmp/analytics.jsonl`, `/tmp/cache/`) → server-process write authority** — when the `/tmp` branch is taken, the app's write targets are name-guessable and unnamespaced, so a local actor who wins the race to create the name controls where the server's bytes go. On genuine Vercel Functions the instance is single-tenant and this boundary has no adversary; the code, however, does not encode that assumption anywhere except the `VERCEL` check itself.
- **B4: Cached LLM response file → later request from a different caller** — `getCachedResult` keys purely on `(model, systemPrompt, userContent, maxTokens)` with no session, tenant, or user identity. Before this diff, cache writes on Vercel targeted a read-only path and therefore silently failed, so this boundary was inert in production; after it, one caller's stored response is served to any other caller presenting identical inputs.

---

### Findings

#### F1 — Fixed, predictable `/tmp` paths make every write symlink-following on a multi-user host

**Severity:** Medium
**Location:** `app/lib/utils/dataDir.ts:15`; sinks at `app/lib/analytics/persist.ts:19,38` and `app/lib/llm/cache.ts:7,72`
**Boundary:** B3 (and B2 for whether B3 is reachable at all)
**Move:** Trace trust boundaries / TOCTOU
**Confidence:** Medium — the mechanism is certain; whether an adversarial local principal exists depends entirely on where `VERCEL` is truthy.
**Evidence:**

```
  return process.env.VERCEL ? "/tmp" : join(process.cwd(), "data");
```

and

```
const FILE_PATH = join(DATA_DIR, "analytics.jsonl");
```

**Legibility-target:** the `dataDir()` docstring — it currently documents *durability* semantics of `/tmp` but says nothing about *sharing* semantics, which is the property that makes this reachable.

`/tmp` is the canonical shared, world-writable, sticky directory, and the code writes to two entirely guessable names inside it: `/tmp/analytics.jsonl` and `/tmp/cache/<sha256>.json`. None of `appendFileSync`, `writeFileSync`, or `fs/promises.writeFile` pass `O_NOFOLLOW` or an exclusive-create flag, so if a local principal pre-creates `/tmp/analytics.jsonl` as a symlink, the server's appends land in the target file and `clearAnalyticsEntries()`'s `writeFileSync(FILE_PATH, "")` truncates it — with the server process's privileges, reachable through an unauthenticated `DELETE /api/analytics`. The same holds for `/tmp/cache` pre-created as a symlink to a directory, since `mkdir(..., { recursive: true })` succeeds against an existing symlink-to-dir and subsequent writes follow it. On real Vercel Functions the instance is single-tenant, so today the exposure is theoretical; the risk is that the `/tmp` branch is selected by an environment variable rather than by a platform capability check, so any host that sets `VERCEL` — a CI runner, a shared build box, a container with `/tmp` bind-mounted from the host — inherits the branch without inheriting the single-tenancy that makes it safe.

**Recommendation:** Namespace the `/tmp` branch to an unguessable, process-owned directory created with restrictive permissions rather than writing to fixed names — e.g. `mkdtemp` once at module init, or at minimum `join("/tmp", "<app-name>-" + process.pid)` created with `{ mode: 0o700 }`. If a stable path is required across the instance lifetime, create the directory with `mode: 0o700` and verify with `lstat` that it is a real directory owned by the current uid before first use.

---

#### F2 — Unbounded growth against a fixed `/tmp` quota, with every write failure silently swallowed

**Severity:** Medium
**Location:** `app/lib/llm/cache.ts:7,70-77`; `app/lib/analytics/persist.ts:17-20`; failure handling at `app/lib/llm/callLlm.ts:84-95`
**Boundary:** B1
**Move:** Million-of-these / error paths
**Confidence:** High for the mechanism and the silence; Medium for exploitation cost, which depends on whether LLM calls are rate-limited upstream.
**Evidence:**

```
const CACHE_DIR = join(dataDir(), "cache");
```

and, from the failure path that consumes it:

```
  } catch { /* persistence failure must not break LLM calls */ }
```

**Legibility-target:** an operational signal — a counter or log line on persistence failure — since by construction no user, test, or type check can observe this failing.

`computeHash` is a sha256 over the full request content, so every distinct `userContent` produces a distinct cache filename and nothing ever evicts them: `removeCachedResult` is invoked only explicitly from `artifactRoute.ts`, and there is no size cap, TTL, or LRU. `analytics.jsonl` is likewise append-only with no rotation. Redirecting both into `/tmp` moves them from a directory bounded by the host disk to one bounded by the Function's fixed ephemeral quota, so a caller who can drive LLM calls with varying content fills the quota on a warm instance at attacker-chosen cost. The consequence is not a crash — every write site is wrapped in `catch {}` precisely so persistence never breaks a call — which is what makes it worth flagging: once `ENOSPC` is reached, analytics silently stop recording and every cache write silently fails, so the instance degrades into permanent cache misses (unbounded upstream LLM spend) and blind cost accounting, and emits no signal that this has happened. The pre-diff behavior was different in kind: writes to a read-only `data/` failed immediately and consistently, so nothing accumulated.

**Recommendation:** Bound both stores and make failure observable. For the cache: cap entry count or total bytes with an eviction pass, or move to the KV backend the author has already deferred to. For analytics: rotate or cap `analytics.jsonl`. Independently, replace the bare `catch {}` at the three persistence call sites with a counter or a rate-limited `console.warn` so exhaustion is visible in logs — the "must not break LLM calls" property is preserved either way.

---

#### F3 — Cached LLM response bodies land in a world-readable directory at default permissions, and cross-caller cache sharing becomes live for the first time

**Severity:** Low
**Location:** `app/lib/llm/cache.ts:7,70-77` (write); `app/lib/llm/cache.ts:38-45` (read)
**Boundary:** B3 (confidentiality at rest) and B4 (cross-caller reuse)
**Move:** Follow the secrets / invert access control
**Confidence:** Medium — the permission defaults are certain; the sensitivity of cached response text depends on what callers submit.
**Evidence:**

```
  await writeFile(filePath, JSON.stringify(result, null, 2), "utf-8");
```

**Legibility-target:** a one-line note in `dataDir()`'s docstring stating that the `/tmp` branch is readable by other principals on the host, so future callers know not to route secrets through it.

`writeFile` with no `mode` yields 0644 under a typical umask, and `mkdir` yields a similarly permissive directory, so cached files are readable by any principal on the host — the same conditional single-tenancy caveat as F1 applies. Content-wise this is bounded: `CachedResult` stores only `{ text, usage }`, so the *prompt* is never written to disk, only the model's response text keyed by an opaque digest, and an attacker who cannot guess the input cannot even determine which file corresponds to what. The second half is subtler and is a genuine behavior change rather than a latent one: because the pre-diff `CACHE_DIR` sat under a read-only path on Vercel, cache writes always failed there, so `getCachedResult` never hit and B4 was inert in production. After this diff it is live, and the cache key contains no session or tenant identity — two different callers submitting byte-identical `(model, systemPrompt, userContent, maxTokens)` now share a response. That is defensible for a deterministic content-addressed cache and the author has explicitly deferred the related cache-hit-collapse concern, so this is recorded as a risk-profile change to be aware of, not a defect.

**Recommendation:** Pass `{ mode: 0o600 }` to `writeFile` and `{ mode: 0o700 }` to `mkdir` in `cache.ts` (cheap, no behavior change). Separately, when the deferred KV migration happens, decide explicitly whether the cache key should carry a tenant/session component — the current answer is "no identity" by omission rather than by decision.

---

#### F4 — `dirEnsured` memoization plus `/tmp` reaping can silently disable cache writes for an instance's remaining lifetime

**Severity:** Low
**Location:** `app/lib/llm/cache.ts:29-35`
**Boundary:** B3
**Move:** TOCTOU / error paths
**Confidence:** Medium — the code path is certain; `/tmp` reaping does not occur on Vercel Functions, so reachability again depends on where the `/tmp` branch is taken.
**Evidence:**

```
let dirEnsured = false;
async function ensureCacheDir() {
  if (dirEnsured) return;
  await mkdir(CACHE_DIR, { recursive: true });
  dirEnsured = true;
}
```

**Legibility-target:** the same persistence-failure counter proposed in F2 — this failure mode is indistinguishable from F2's from the outside, and one signal covers both.

`ensureCacheDir` records "the directory exists" once and never rechecks, which was a safe assumption when `CACHE_DIR` lived under the repo's `data/` but is a time-of-check/time-of-use gap once it lives under `/tmp` — the one directory on a Unix host whose contents are conventionally reaped out from under long-lived processes (`systemd-tmpfiles`, cron tmpwatch). If the directory disappears after the flag is set, every subsequent `writeFile` fails with `ENOENT`, is swallowed by the caller's `catch`, and the instance never attempts to recreate the directory. Note the asymmetry with the analytics path, which calls `ensureDir()` on every append and therefore self-heals; the cache path does not. This is pre-existing code that the diff did not touch, but the diff is what places it in an environment where the assumption can break, so it belongs in this review.

**Recommendation:** Drop the memo flag (recursive `mkdir` on an existing directory is a cheap syscall and the analytics path already pays it per write), or retry once on `ENOENT` in `setCachedResult` before giving up.

---

#### F5 — `process.env.VERCEL` is trusted by JavaScript truthiness, so `VERCEL=0` selects the Vercel branch

**Severity:** Low
**Location:** `app/lib/utils/dataDir.ts:15`; semantics pinned by `app/lib/utils/dataDir.test.ts:23-26`
**Boundary:** B2
**Move:** Implicit sanitization assumptions
**Confidence:** High — this is a direct reading of the operator's semantics, confirmed by the test the diff adds.
**Evidence:**

```
  it("treats any truthy VERCEL value as Vercel", () => {
    vi.stubEnv("VERCEL", "preview");
    expect(dataDir()).toBe("/tmp");
  });
```

**Legibility-target:** the test file, which is the right place — the concern is that it currently pins the permissive reading as intended rather than flagging it.

Every non-empty string is truthy in JavaScript, so `VERCEL=0` and `VERCEL=false` — the two values an operator would most naturally reach for to mean "not Vercel" — both route all persistence into `/tmp`, silently trading durable storage for ephemeral storage and, per B3/F1, moving writes into a shared namespace. The new test deliberately encodes this as the contract, which is a reasonable reading of Vercel's own convention (the platform sets `VERCEL=1` and unsets it otherwise) and does make the branch refactor-proof, which is the stated purpose. The residual concern is that this makes an unvalidated environment string the sole switch controlling where the application writes, with no downstream re-check and no startup assertion — as the fact-check notes, if a presence check ever replaces the truthiness check, the `VERCEL=""` stub in the third test diverges from its own title and the branch silently flips. This is a footgun rather than an attack: an adversary who can set environment variables on the server already has more direct options.

**Recommendation:** Either keep truthiness and say so explicitly in the docstring ("any non-empty `VERCEL` selects `/tmp`; the platform sets `VERCEL=1`"), or tighten to an explicit comparison and update the tests to match. Prefer whichever, but make the choice explicit — the current state is a convention inherited by accident of operator semantics.

---

#### F6 — `/api/analytics` exposes read and destructive-clear with no authentication (pre-existing; risk profile changed by the diff)

**Severity:** Informational
**Location:** `app/api/analytics/route.ts:5-13`
**Boundary:** B3
**Move:** Invert access control
**Confidence:** High for the absence of auth (no `middleware.ts` exists in the repo); Informational because the diff does not introduce it.
**Evidence:**

```
export async function DELETE() {
  clearAnalyticsEntries();
  return NextResponse.json({ ok: true });
}
```

**Legibility-target:** the project's deployment checklist — this is a "do not expose this route publicly" fact that lives nowhere in the repo today.

The route has no auth check and the repo has no middleware, so any unauthenticated caller can read the full analytics history (endpoint names, models, token counts, per-call USD cost) and wipe it. This predates the diff entirely and is out of scope as a finding against these commits, but it is recorded here because it is what makes F1's truncation primitive remotely reachable: `DELETE` is the caller that invokes `writeFileSync(FILE_PATH, "")`, which is the symlink-following truncate. The diff also changes what backs the route — on Vercel it now returns one Function instance's view rather than nothing, which is an improvement in function and an increase in what an unauthenticated read yields.

**Recommendation:** Out of scope for this change. Track separately: gate `DELETE` (and likely `GET`) behind an auth check or restrict the route to non-production builds.

---

#### F7 — `existsSync` → `mkdirSync` check-then-act in `ensureDir` (benign)

**Severity:** Informational
**Location:** `app/lib/analytics/persist.ts:11-15`
**Boundary:** B3
**Move:** TOCTOU
**Confidence:** High
**Evidence:**

```
function ensureDir() {
  if (!existsSync(DATA_DIR)) {
    mkdirSync(DATA_DIR, { recursive: true });
  }
}
```

**Legibility-target:** none needed — recorded for completeness so a future reader does not re-raise it.

This is the classic check-then-act shape and is worth naming explicitly so it can be dismissed on the record rather than re-litigated. It is harmless as written: `recursive: true` makes `mkdirSync` idempotent and non-throwing when the directory already exists, so losing the race between the `existsSync` and the `mkdirSync` produces no error and no different outcome. The `existsSync(FILE_PATH)` → `readFileSync(FILE_PATH)` pair in `readAnalyticsEntries` has the same shape with a slightly worse failure mode — the file can vanish between the two calls, throwing `ENOENT` out of an unguarded `GET` handler — but that is a robustness nit, not a security consequence.

**Recommendation:** None required. If touched for other reasons, drop the `existsSync` guard and call `mkdirSync` unconditionally.

---

### What Looks Good

- **The hash chokepoint on B1 is the right design and is correctly implemented.** Attacker-controlled request content reaches a filesystem path, but only as `createHash("sha256")...digest("hex")` — an alphabet that cannot express traversal, absolute paths, or NUL. This is the single highest-risk trust boundary in the diff and it is closed by construction rather than by filtering, which is the durable way to close it.
- **sha256 is the correct primitive for the job.** It is used for content addressing, not authentication, so there is no HMAC-vs-hash confusion to raise and no key to manage.
- **Persistence failures cannot break the request path.** Every write site — `callLlm.ts`, `streamLlm.ts` (both the completion and the streaming branch), and `artifactRoute.ts`'s cache invalidation — wraps its persistence call in a `catch` with an explanatory comment. This is a deliberate and correct availability decision; F2's recommendation is to add a signal alongside it, not to remove it.
- **Centralizing the path decision in one function reduced the security surface.** Before the diff there were two independent `join(process.cwd(), "data", ...)` constructions to keep in sync; now there is one place to audit, one place to fix F1 and F5, and one docstring where the `/tmp` caveats belong. The rest-args drop in `2cd3b67` reinforces this — both consumers now compose paths with a plain `join(dataDir(), ...)` at the call site, so `dataDir()` has exactly one job.
- **The added test pins an otherwise-invisible deploy invariant.** The Vercel branch cannot be exercised in local dev, so a refactor deleting or inverting it would pass lint, types, and build; `dataDir.test.ts` closes that gap for both branches, and its comment explains why the test exists rather than what it does.

---

### Summary Table

| ID | Severity | Finding | Boundary | Move | Confidence |
|----|----------|---------|----------|------|------------|
| F1 | Medium | Fixed, predictable `/tmp` paths → symlink-following append/truncate on a multi-user host | B3 | Trust boundaries / TOCTOU | Medium |
| F2 | Medium | Unbounded cache + analytics growth against a fixed `/tmp` quota; failures silently swallowed | B1 | Million-of-these / error paths | High (mechanism) |
| F3 | Low | Cached response bodies at 0644 in world-readable `/tmp`; identity-free cross-caller cache sharing now live | B3 / B4 | Follow the secrets / invert access control | Medium |
| F4 | Low | `dirEnsured` memo + `/tmp` reaping permanently disables cache writes, silently | B3 | TOCTOU / error paths | Medium |
| F5 | Low | `process.env.VERCEL` truthiness: `VERCEL=0` selects `/tmp` | B2 | Implicit sanitization assumptions | High |
| F6 | Informational | Unauthenticated `GET`/`DELETE` on `/api/analytics` (pre-existing) | B3 | Invert access control | High |
| F7 | Informational | `existsSync` → `mkdirSync` check-then-act (benign under `recursive: true`) | B3 | TOCTOU | High |

---

### Overall Assessment

No high-severity or critical issues. The change's core security property — that attacker-controlled request content reaching a filesystem path passes through a sha256 hex digest — is sound, and the review-fix commit `2cd3b67` improved the change on every axis it touched (accurate per-instance docstring, single-responsibility `dataDir()`, both branches pinned by test).

The two Medium findings share one root cause worth stating plainly: `/tmp` was adopted for the one property Vercel forces (it is the only writable path) while its other three properties came along unexamined — it is *shared*, it is *permission-permissive*, and it is *quota-bounded*. The docstring documents the ephemerality caveat carefully and is silent on all three. F1 and F3 are conditional on a multi-tenant host and therefore inert on genuine Vercel Functions; F2 is unconditional, because the quota is fixed on Vercel specifically, and its consequence — silent analytics loss plus permanent cache misses driving unbounded upstream LLM spend, with no log line — is an operational blind spot rather than a breach. If only two things are done here: namespace the `/tmp` directory with `mode: 0o700` (closes F1 and F3 together, a few lines in `dataDir.ts`), and put a counter or rate-limited warning behind the persistence `catch {}` blocks (makes F2 and F4 observable instead of silent).

---

## Goal-Alignment Note

- **Answered:** All nine security cognitive moves applied to the `d86d2dc..2cd3b67` range, with the brief's named focus areas covered explicitly — shared/world-readable `/tmp` semantics (F1, F3), `process.env.VERCEL` truthiness as an env-var trust boundary (F5, B2), symlink-following writes (F1), and unbounded growth against a fixed quota (F2). Trust boundary map supplied with four labeled boundaries; every finding references one. Seven findings reported at all severities down to Informational, each with a verbatim evidence quote from the commit-`2cd3b67` state.
- **Out of scope:** Non-security review dimensions (performance, API consistency, architecture, test strategy) — separate critics own those. The unauthenticated `/api/analytics` route (F6) and the `existsSync`/`mkdirSync` shape (F7) predate the range and are recorded as Informational context, not as findings against these commits. The deferred cache-hit-collapse concern is acknowledged per the author note and treated only where it intersects a security boundary (F3/B4); no attempt was made to reopen it. Per the merged fact-check foundation, documented behavior was not re-verified. This is a measurement-run pass-1 with no fix loop, so no code was changed.
- **Escalate:** Nothing. None of the five canonical HALT-ESCALATE patterns is present — no credential exposure, no authentication bypass, no remote code execution, no injection reaching an interpreter, and no cryptographic failure. F1's symlink primitive is the closest call and does not qualify: it requires a local co-tenant on a host that sets `VERCEL`, a precondition that does not hold on the deployment target this change was written for.
