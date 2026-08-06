# Security Review — fscompat-dirty (d86d2dc..b64c1ca)

**Scope:** `git diff d86d2dc..b64c1ca` — extraction of a `dataDir()` helper (`app/lib/utils/dataDir.ts`, new) resolving the server-side persistence root, and rewiring of analytics persistence (`app/lib/analytics/persist.ts`) and the LLM response cache (`app/lib/llm/cache.ts`) onto it. 3 files, +21/-2. Consumers of the rewired modules (`callLlm.ts`, `streamLlm.ts`, `api/analytics/route.ts`, `artifactRoute.ts`) are read as context for reachability, not reviewed themselves.
**Date:** 2026-08-06
**Based on:** merged code fact-check (k=3), treated as foundation — documented behavior is not re-verified here.
Commit: b64c1ca

---

### Trust Boundary Map

B1: Unauthenticated HTTP client → `GET`/`DELETE /api/analytics` route handler → `readAnalyticsEntries()` / `clearAnalyticsEntries()` reading and truncating `${dataDir()}/analytics.jsonl`
B2: Application process (running as the deploy user) → `dataDir()` path resolution → host filesystem namespace — either `/tmp` (a *shared* namespace on a conventional multi-user host, an *isolated per-instance* namespace on Vercel Functions) or `<cwd>/data` (process-owned, gitignored)
B3: User-supplied source document → LLM prompt (`systemPrompt` + `userContent`) → sha256 filename → cache file `${dataDir("cache")}/<hash>.json` → `JSON.parse` on read → returned as trusted model output into the artifact pipeline
B4: Deployment environment configuration (`process.env.VERCEL`) → truthy test → selection of the persistence root for both B2 destinations

The security-relevant substance of this diff is entirely in B4 and B2: a single environment variable now decides whether the application's two persistent data stores live in a private, process-owned directory or in `/tmp`. That is a boundary *relocation*, and the properties of the destination differ on three axes the code does not account for: who else can read the directory, who else can write it, and whether writes are quota-bounded.

Vercel's `/tmp` is per-invocation-container and not shared with other tenants, so on the intended deployment target B2's shared-namespace concerns do not apply — but its quota concerns do (F4). The shared-namespace concerns (F1, F2, F3) apply wherever `VERCEL` is set on a host whose `/tmp` is a conventional shared mount, which F5 shows is easier to reach than intended. B1 is pre-existing and unchanged by the diff; it is reported because the diff changes what its data store is and where it lives.

---

### Findings

#### F1. LLM cache — content derived from user documents relocated to a world-readable directory

**Severity:** Medium
**Location:** `app/lib/utils/dataDir.ts:13`; `app/lib/llm/cache.ts:7,68`
**Boundary:** B2, B3
**Move:** Follow the secrets / trace trust boundaries
**Confidence:** High on mechanism; Medium on reachability (requires `VERCEL` set on a host with a shared `/tmp`)
**Evidence:**

```ts
const base = process.env.VERCEL ? "/tmp" : join(process.cwd(), "data");
```

```ts
const CACHE_DIR = dataDir("cache");
...
  await writeFile(filePath, JSON.stringify(result, null, 2), "utf-8");
```

**Legibility-target:** The reviewer sees `/tmp` as "a scratch directory" rather than "a directory every local principal can read."

Cache files hold `{ text, usage }`, where `text` is the model's response to `userContent` — which, for this application, is the user's uploaded or pasted source document run through formalization/decomposition. Off-Vercel the destination is `<cwd>/data`, which is gitignored and inherits the deploy directory's permissions; `/tmp` is mode `1777` and files written there under a default umask land at `0644`, readable by every local account and every other process on the box. The diff moves user-derived content across that line on the strength of one env var, and the filenames are deterministic sha256 of the prompt tuple, so an observer who can guess a prompt can confirm its presence rather than merely browse. On Vercel proper this is contained by per-instance isolation; on a self-hosted container, CI runner, or shared VM where `VERCEL` happens to be set (see F5), it is not.

**Recommendation:** Do not rely on the directory's default mode. Create the cache root with an explicit restrictive mode (`mkdir(CACHE_DIR, { recursive: true, mode: 0o700 })`) and write files with `{ mode: 0o600 }`. Better, when the base is `/tmp`, namespace it per-process/per-deployment (e.g. `/tmp/<app>-<uid>/cache`) rather than writing into the shared root.

#### F2. `/tmp` path pre-creation (symlink TOCTOU) yields writes through an attacker-chosen link

**Severity:** Medium
**Location:** `app/lib/llm/cache.ts:28-32,68`; `app/lib/analytics/persist.ts:11-15,19,39`
**Boundary:** B2
**Move:** TOCTOU / error paths
**Confidence:** High on mechanism; Medium on reachability (same precondition as F1)
**Evidence:**

```ts
function ensureDir() {
  if (!existsSync(DATA_DIR)) {
    mkdirSync(DATA_DIR, { recursive: true });
  }
}
```

```ts
async function ensureCacheDir() {
  if (dirEnsured) return;
  await mkdir(CACHE_DIR, { recursive: true });
  dirEnsured = true;
}
```

**Legibility-target:** `mkdir({recursive:true})` reads as "make sure it exists," which hides that it silently accepts a path component that already exists as a symlink.

Every write path here (`appendFileSync`, `writeFileSync`, `writeFile`, `unlink`) follows symlinks, and neither `existsSync`-then-`mkdirSync` nor `mkdir` with `recursive: true` rejects a pre-existing symlinked component — `recursive` treats "already exists" as success. In a shared `/tmp`, an unprivileged local user can create `/tmp/cache` or `/tmp/analytics.jsonl` as a symlink before the app's first write and thereby redirect writes to any path the app's user can write, or read back content the app appends. `existsSync` → `mkdirSync` in `persist.ts` is additionally a check-then-act pair with a window between the two calls, though pre-creation makes the race unnecessary. This is the classic shared-`/tmp` hazard, and the previous code (`<cwd>/data`) was not exposed to it because that directory is not in a shared namespace.

**Recommendation:** Pair with F1's per-process namespaced directory, created with `mode: 0o700` and owned by the app — a private parent removes the pre-creation opportunity for every child path. Where feasible, open files with `O_NOFOLLOW`/`O_EXCL` semantics rather than the symlink-following convenience wrappers.

#### F3. Cache read deserializes and trusts file contents with no shape validation

**Severity:** Low
**Location:** `app/lib/llm/cache.ts:43-59`
**Boundary:** B3
**Move:** Serialization boundaries
**Confidence:** High

**Evidence:**

```ts
    const data = JSON.parse(await readFile(filePath, "utf-8")) as CachedResult;
    // Override usage to reflect cache hit
    return {
      text: data.text,
```

**Legibility-target:** The `as CachedResult` assertion looks like a type guarantee; it is a compile-time assertion that erases at runtime and validates nothing.

Whatever JSON sits at `<hash>.json` becomes `text`, and `callLlm`/`streamLlm` return it to the artifact pipeline as if the model had produced it — so anyone who can write that file controls model output for that prompt, which is a prompt-injection/content-forgery primitive rather than merely a corrupt-data problem. The `catch` guards only parse and I/O failure, not well-formed-but-hostile content: a valid JSON object with an attacker-chosen `text` and a missing `usage` passes through, and the spread `...data.usage` on a non-object would throw into the same silent catch. On its own this requires write access to the cache directory (i.e. F1/F2's precondition or a compromised co-process), which is why it is Low standalone — but it is the payoff that makes F2 worth an attacker's effort.

**Recommendation:** Validate the parsed object before use — check `typeof data.text === "string"` and that `data.usage` is an object with the expected numeric fields, and treat a mismatch as a miss. If cache integrity matters beyond shape, store an HMAC over the content keyed by a server secret and verify on read.

#### F4. Unbounded cache growth against a fixed ephemeral-storage quota

**Severity:** Medium
**Location:** `app/lib/llm/cache.ts:62-69`; `app/lib/analytics/persist.ts:17-20`
**Boundary:** B2, B3
**Move:** Million of these
**Confidence:** High on the unbounded-growth mechanism; Medium on the exact quota figure

**Evidence:**

```ts
export async function setCachedResult(
  hash: string,
  result: CachedResult
): Promise<void> {
  await ensureCacheDir();
  const filePath = join(CACHE_DIR, `${hash}.json`);
  await writeFile(filePath, JSON.stringify(result, null, 2), "utf-8");
}
```

**Legibility-target:** The move to `/tmp` reads as "unblock writes on Vercel," and the fact that it also enrolls those writes in a *capped shared budget* is not visible at any call site.

This is the finding that applies to the intended deployment, without any misconfiguration. Every distinct prompt tuple writes one cache file and nothing ever removes it — the only deletion path, `removeCachedResult`, is called from a single artifact-regeneration path and is keyed to one specific entry. Analytics appends grow the same way in the same directory. Vercel's `/tmp` is bounded ephemeral storage (documented on the order of 512 MB per instance) shared with everything else the function writes, so a caller issuing many distinct prompts — trivially, varying one character of `userContent` — fills it. Note the change in failure posture: before this diff, writes on Vercel targeted a read-only path and failed immediately; now they succeed until the quota is exhausted, at which point cache and analytics writes fail into the existing silent catches while other consumers of `/tmp` on that instance start failing too. `readAnalyticsEntries()` compounds it by reading the whole grown file into memory on every unauthenticated `GET` (B1).

**Recommendation:** Bound the cache — an entry count or byte cap with LRU eviction, or a TTL sweep on write. At minimum, skip cache writes when the base is `/tmp` and treat the cache as opt-in for durable-filesystem deployments, which matches the "no durable persistence on Vercel anyway" rationale the helper's own docblock gives.

#### F5. Env gate is a bare truthiness test, so `VERCEL=0` and `VERCEL=false` select `/tmp`

**Severity:** Low
**Location:** `app/lib/utils/dataDir.ts:13`
**Boundary:** B4
**Move:** Invert access control (what makes the check decide the wrong way?)
**Confidence:** High

**Evidence:**

```ts
  const base = process.env.VERCEL ? "/tmp" : join(process.cwd(), "data");
```

**Legibility-target:** An operator who writes `VERCEL=0` to mean "not Vercel" gets `/tmp`, because every non-empty string is truthy in JS.

Environment variables are strings, so `"0"`, `"false"`, and `"no"` are all truthy and all route persistence to `/tmp`. This is the precondition that makes F1 and F2 reachable outside Vercel: the gate is likeliest to misfire exactly in the environments where `/tmp` is shared — a self-hosted container or CI runner where someone copied Vercel-flavored env config or set the flag defensively to the wrong value. There is also no way to override the choice deliberately (no explicit `DATA_DIR` escape hatch), so an operator who wants a durable path on a Vercel-like host has no supported lever. The value is also read at module scope (`const DATA_DIR = dataDir()`), fixing the decision at import time.

**Recommendation:** Test explicitly — `process.env.VERCEL === "1"` (the value Vercel actually sets) — and add an explicit `DATA_DIR` env override that takes precedence, so the destination can be stated rather than inferred.

#### F6. `dataDir(...subpaths)` joins caller-supplied segments with no containment check

**Severity:** Low
**Location:** `app/lib/utils/dataDir.ts:12-14`
**Boundary:** B2
**Move:** Implicit sanitization assumptions
**Confidence:** High on the property; the traversal is latent, not currently reachable

**Evidence:**

```ts
export function dataDir(...subpaths: string[]): string {
  const base = process.env.VERCEL ? "/tmp" : join(process.cwd(), "data");
  return subpaths.length > 0 ? join(base, ...subpaths) : base;
}
```

**Legibility-target:** A variadic path helper named for a directory reads as "safe path builder," and callers will reasonably assume it keeps them inside that directory. It does not.

`join` normalizes `..` rather than rejecting it, so `dataDir(userId)` with `userId = "../../etc"` resolves outside the base, and an absolute segment would discard the base entirely. Today the only call sites are `dataDir()` and `dataDir("cache")` — both literals — so nothing is exploitable at this commit. The finding is that this is the moment the escape becomes cheap: the helper's whole purpose is to be the shared entry point for future persistence, its signature invites passing an identifier, and nothing in the name, docblock, or types warns against untrusted input. Flagging it now costs three lines; flagging it after the first user-keyed caller costs an incident.

**Recommendation:** Reject traversal at the helper — after joining, verify the result is still within `base` (`resolve(result).startsWith(resolve(base) + sep)`) and throw otherwise. Document in the docblock that segments must not be attacker-controlled unless that check is in place.

#### F7. Analytics read and destructive clear are unauthenticated

**Severity:** Low (pre-existing; route unchanged by this diff)
**Location:** `app/api/analytics/route.ts:4-12`; `app/lib/analytics/persist.ts:37-40`
**Boundary:** B1
**Move:** Invert access control
**Confidence:** High

**Evidence:**

```ts
export async function GET() {
  const entries = readAnalyticsEntries();
  return NextResponse.json({ entries });
}

export async function DELETE() {
  clearAnalyticsEntries();
  return NextResponse.json({ ok: true });
}
```

**Legibility-target:** The diff's framing is "where does the file live," which draws attention away from who can reach the file through the app.

Any client can enumerate the deployment's full LLM usage history — endpoints, models, per-call token counts, costs, latencies, timestamps — and any client can wipe it with a single unauthenticated `DELETE`. The stored shape (`AnalyticsEntry`) is metadata only, with no prompt or document content, which caps the confidentiality impact; the integrity impact is that cost and prior-estimation data (`EndpointPrior`, used for the cost-estimation tooltips) is attacker-erasable. Two diff-adjacent notes: per the fact-check, `clearAnalyticsEntries()` is the one unguarded call path, so an `ensureDir`/`writeFileSync` failure surfaces as a 500 rather than being swallowed — which under F2's symlink scenario becomes an oracle for whether a redirected write succeeded; and on Vercel a `DELETE` clears only the instance that serves it, leaving other warm instances' data intact, so the endpoint no longer does what its name promises.

**Recommendation:** Gate both methods behind whatever authentication the deployment uses, or at minimum restrict `DELETE` to non-production. Reported for completeness given the diff rewires this module's storage; fixing it is not this PR's job.

#### F8. Operators have no documentation that `/tmp` is now a data destination

**Severity:** Informational
**Location:** `app/lib/analytics/persist.ts:6-7`
**Boundary:** B4
**Move:** Trace trust boundaries (the human half)
**Confidence:** High (fact-check finding, adopted)

**Evidence:**

```ts
// On Vercel, analytics history doesn't persist across cold starts — see
// Deploy to Vercel in README. See dataDir() for the underlying rationale.
```

**Legibility-target:** The comment points at documentation that would explain the deployment's data-handling posture; the fact-check confirms no such README section exists, and no file outside these two source comments mentions Vercel.

The security consequence of a dangling doc reference here is narrow but real: the only description of where user-derived cache content lands, and of the `VERCEL` flag that decides it, lives in source comments that operators configuring a deployment will not read. That is the same gap F5 exploits — the flag's effect is undocumented, so setting it wrongly has no visible warning.

**Recommendation:** Either add the referenced README section, covering the `VERCEL` gate, the `/tmp` destination, its non-durability, and the per-instance isolation caveat, or drop the reference and inline the explanation.

---

### What Looks Good

- **Off-Vercel path equivalence is exact.** The refactor preserves `join(process.cwd(), "data")` and `join(process.cwd(), "data", "cache")` byte-for-byte, so the default deployment's security posture is genuinely unchanged — no accidental widening on the common path.
- **Cache keys are a sound construction.** `createHash("sha256")` over a `JSON.stringify` of the full `{model, systemPrompt, userContent, maxTokens}` tuple is collision-resistant and covers every input that affects the response, so unrelated prompts cannot alias onto one another's cache entries. No home-rolled or truncated hashing.
- **The write paths that must not break requests are guarded.** Analytics appends and cache writes in `callLlm`/`streamLlm` are wrapped in try/catch with explicit non-fatal comments, so a persistence failure — including the quota exhaustion of F4 — degrades rather than failing the user's request.
- **Centralizing the path decision is the right structural move.** One helper is the correct place to add the mode, containment, and override fixes above; the pre-diff state had the same decision duplicated in two modules, where a fix would have had to be made twice.

---

### Summary Table

| ID | Finding | Severity | Boundary | Confidence |
|----|---------|----------|----------|------------|
| F1 | User-derived cache content relocated to world-readable `/tmp` | Medium | B2, B3 | High mech. / Med. reach |
| F2 | `/tmp` symlink pre-creation redirects app writes (TOCTOU) | Medium | B2 | High mech. / Med. reach |
| F4 | Unbounded cache + analytics growth against fixed `/tmp` quota | Medium | B2, B3 | High |
| F3 | Cache read trusts `JSON.parse` output with no shape validation | Low | B3 | High |
| F5 | `process.env.VERCEL` truthiness gate misfires on `0`/`false` | Low | B4 | High |
| F6 | `dataDir(...subpaths)` has no traversal containment (latent) | Low | B2 | High |
| F7 | Unauthenticated analytics read and destructive clear (pre-existing) | Low | B1 | High |
| F8 | `/tmp` data destination undocumented for operators | Informational | B4 | High |

---

### Overall Assessment

The refactor itself is clean and the off-Vercel path is provably unchanged, so this is not a diff that introduces a vulnerability into the running deployment on the strength of its own logic. What it does is move two data stores across a filesystem trust boundary on the authority of one loosely-tested environment variable, without carrying any of the properties the old location supplied implicitly — private ownership, non-shared namespace, unbounded space. F4 is the finding that lands on the intended target with no misconfiguration required, and it is the one worth fixing in this PR: writes that previously failed fast now succeed into a capped shared budget with no eviction. F1/F2/F3 form one chain — shared-directory exposure, pre-creation redirect, and an unvalidated read that turns the redirect into control over model output — and all three are neutralized by the same fix, a per-process `0700` directory, which is a few lines in `dataDir()`. F5 is what makes that chain reachable at all, and it costs one `=== "1"` to close.

Nothing here rises to HALT-ESCALATE. Suggested order: F4 and F5 in this PR, F1/F2 together as the directory-hardening follow-up, F3 and F6 as small hardening on the helper and the cache read, F7 tracked separately as pre-existing.

---

## Goal-Alignment Note

- **Answered:** Whether the `dataDir()` extraction and the `/tmp` redirect change the application's exposure — the trust boundaries the diff crosses (B1–B4), the confidentiality, integrity, and availability consequences of `/tmp` as a destination, the safety of the env gate, path-traversal properties of the new helper's variadic signature, the cache's deserialization boundary, and unbounded-growth behavior under the `/tmp` quota.
- **Out of scope:** LLM provider selection and API-key handling in `callLlm.ts`/`streamLlm.ts` (unchanged, keys never touch these files); the correctness of usage/cost accounting; client-side persistence (`workspacePersistence.ts`, localStorage); the other seven API routes; commits outside `d86d2dc..b64c1ca`; and the documented-behavior claims settled by the merged fact-check, which were adopted rather than re-verified. F7 is pre-existing and reported for context only. Exact Vercel `/tmp` quota figures were not verified against vendor documentation and are hedged in F4.
- **Escalate:** None. No finding matches a canonical HALT-ESCALATE pattern — no credential exposure, no authentication bypass on a protected surface, no remote code execution, no cryptographic failure, no unbounded-privilege path. F2's arbitrary-write primitive is the closest, and it is gated behind a deployment misconfiguration plus local shared-host access, which keeps it a normal-severity finding.
