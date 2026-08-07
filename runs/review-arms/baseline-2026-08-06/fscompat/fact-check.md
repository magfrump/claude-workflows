Commit: b64c1ca

# Code Fact-Check Report

**Repository:** meta-formalism-copilot (worktree wt-fscompat @ b64c1ca)
**Scope:** branch diff `d86d2dc..b64c1ca` (full-branch changeset)
**Checked:** 2026-08-06
**Total claims checked:** 5
**Summary:** 3 verified, 0 mostly accurate, 0 stale, 1 incorrect, 1 unverifiable

---

## Claim 1: "On Vercel, analytics history doesn't persist across cold starts — see Deploy to Vercel in README."

**Location:** `app/lib/analytics/persist.ts:6-7`
**Type:** Reference / Behavioral
**Verdict:** Incorrect
**Confidence:** High

The comment directs the reader to a "Deploy to Vercel" section in the README, but no such section exists. The README's headings run straight from "Available Scripts" to "How to Contribute", and a case-insensitive search for `vercel`/`deploy` across `README.md` returns zero matches (paraphrased — no quote available because the claim covers the *absence* of a README section; there is nothing to quote). README headings observed:

```
## Available Scripts        (README.md:94)
## How to Contribute        (README.md:104)
## Project Documentation    (README.md:108)
```

The behavioral half of the comment ("analytics history doesn't persist across cold starts") is consistent with the code — `DATA_DIR` resolves via `dataDir()`, which returns `/tmp` on Vercel (see Claim 3):

```ts
// app/lib/analytics/persist.ts:8
const DATA_DIR = dataDir();
```

The dead cross-reference is the misleading part: a reader following "see Deploy to Vercel in README" finds nothing.

**Evidence:** `app/lib/analytics/persist.ts:6-8`, `README.md:94-108` (no Vercel/Deploy section)

---

## Claim 2: "See dataDir() for the underlying rationale."

**Location:** `app/lib/analytics/persist.ts:7`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High

`dataDir` exists, is imported, and carries the referenced rationale in its docstring:

```ts
// app/lib/analytics/persist.ts:4
import { dataDir } from "@/app/lib/utils/dataDir";
```

```ts
// app/lib/utils/dataDir.ts:12
export function dataDir(...subpaths: string[]): string {
```

**Evidence:** `app/lib/analytics/persist.ts:4`, `app/lib/utils/dataDir.ts:3-15`

---

## Claim 3: "In dev and self-hosted deployments we write to the repo's `data/` dir for durable cross-restart storage."

**Location:** `app/lib/utils/dataDir.ts:9-10`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

When the `VERCEL` env var is unset (dev / self-hosted), the base resolves to `<cwd>/data`; the code matches the docstring exactly:

```ts
// app/lib/utils/dataDir.ts:13-14
const base = process.env.VERCEL ? "/tmp" : join(process.cwd(), "data");
return subpaths.length > 0 ? join(base, ...subpaths) : base;
```

This preserves the pre-diff behavior of both call sites: `persist.ts` previously used `join(process.cwd(), "data")` and now uses `dataDir()` (same result off-Vercel), and `cache.ts` previously used `join(process.cwd(), "data", "cache")` and now uses `dataDir("cache")` → `join(<cwd>/data, "cache")` (same result off-Vercel).

```ts
// app/lib/llm/cache.ts:7
const CACHE_DIR = dataDir("cache");
```

**Evidence:** `app/lib/utils/dataDir.ts:13-14`, `app/lib/llm/cache.ts:7`, `app/lib/analytics/persist.ts:8`

---

## Claim 4: "On Vercel, only `/tmp` is writable" — code selects `/tmp` when running on Vercel.

**Location:** `app/lib/utils/dataDir.ts:7,13`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High

The docstring's operative code decision — write to `/tmp` when on Vercel — is faithfully implemented via the `process.env.VERCEL` guard:

```ts
// app/lib/utils/dataDir.ts:13
const base = process.env.VERCEL ? "/tmp" : join(process.cwd(), "data");
```

`VERCEL` is the environment variable the Vercel platform sets automatically on its Functions runtime, so the ternary selects the `/tmp` branch precisely in the deployment the docstring describes. The code-behavior claim (branch selection) is verified here; the underlying platform-filesystem assertion is assessed separately in Claim 5.

**Evidence:** `app/lib/utils/dataDir.ts:7-10,13`

---

## Claim 5: "On Vercel Functions only `/tmp` is writable, and it lives only as long as the warm container — so persistence does not survive cold starts."

**Location:** `app/lib/utils/dataDir.ts:7-9`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium

This is a claim about the Vercel platform's filesystem semantics (read-only FS except an ephemeral `/tmp` scoped to the warm container), not about anything in this codebase. It cannot be confirmed from static analysis of the repo alone — it would require the Vercel runtime environment to verify (paraphrased — no quote available because the claim is about external platform behavior, not repo code). It is consistent with widely documented Vercel Functions behavior, and the code's `/tmp` branch (Claim 4) is written on that premise, but the assertion itself is external to the codebase.

**Evidence:** `app/lib/utils/dataDir.ts:7-9` (rationale docstring); external Vercel platform behavior — not verifiable in-repo

---

## Claims Requiring Attention

### Incorrect
- **Claim 1** (`app/lib/analytics/persist.ts:6-7`): Comment says "see Deploy to Vercel in README" but the README has no such section; either add the section or drop the reference. Behavioral half is accurate.

### Stale
- None.

### Mostly Accurate
- None.

### Unverifiable
- **Claim 5** (`app/lib/utils/dataDir.ts:7-9`): Vercel-platform filesystem/cold-start semantics — requires the Vercel runtime to confirm; consistent with documented platform behavior but external to the repo.
