# API Consistency Review — mfc-deploy Vercel-deploy documentation

**Commit:** 4329d6e
**Scope:** `git diff d86d2dc...HEAD` — `CLAUDE.md` (new Deployment section), `README.md` (Deploy-with-Vercel button, Deploy-to-Vercel section, Lean Verification Service edits)
**Date:** 2026-08-18
**Based on:** `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-deploy/code-fact-check-report.md` (merged k=2; its verdicts bind — behavior findings below cite, not re-verify)

This is a docs-only diff, but the docs are themselves the consumer-facing contract: the env-var tables, deploy flow, and fallback-semantics descriptions are what a deploying user binds to. The review audits that contract against the code surface (`callLlm.ts`, `streamLlm.ts`, `app/api/verification/lean/route.ts`, `persist.ts`, `cache.ts`) and audits README vs CLAUDE.md for self-consistency — a check the diff itself makes load-bearing by adding the rule "update both `README.md` … and this file."

## Baseline Conventions

- **Config surface:** all runtime configuration is flat `SCREAMING_SNAKE_CASE` env vars read server-side (`ANTHROPIC_API_KEY`, `OPENROUTER_API_KEY`, `LEAN_VERIFIER_URL` in `app/`; `PORT`, `LEAN_PROJECT_DIR` in `verifier/`; plus the dev-only `SIMULATE_STREAM_FROM_CACHE` in `app/lib/llm/streamLlm.ts:105`). No config files, no client-side keys (fact-check Claim 2, Verified).
- **Degradation convention:** the codebase's established failure pattern is *silent graceful degradation*, not hard failure — missing LLM keys → mock provider (`callLlm.ts:202-220`, `streamLlm.ts:137-158`); unreachable verifier → `{ valid: true, mock: true }` (`route.ts:37-40`); persistence failures swallowed (`callLlm.ts:91,94`).
- **Verifier route error convention:** three distinct response shapes — real verifier passthrough (`{valid, errors?}`), mock (`{valid: true, mock: true}`), and validation error (`{ error: "leanCode is required" }`, 400); non-OK verifier statuses are forwarded verbatim with their status code (`route.ts:32-34`).
- **Doc-sync convention (established by this diff):** README "Deploy to Vercel" and CLAUDE.md "Deployment" must describe the same contract.

## Name-Pattern Audit

The diff introduces no new code-level public names. Its new consumer-facing identifiers are the env-var table entries, the Vercel button's project/repo identifiers, and one section anchor:

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `ANTHROPIC_API_KEY` (table entry) | config/env var | `process.env.ANTHROPIC_API_KEY` | `app/lib/llm/callLlm.ts:112`, `streamLlm.ts:87` | Consistent — exact name the code reads |
| `OPENROUTER_API_KEY` (table entry) | config/env var | `process.env.OPENROUTER_API_KEY` | `app/lib/llm/callLlm.ts:113`, `streamLlm.ts:88` | Consistent — exact name the code reads |
| `LEAN_VERIFIER_URL` (table entry) | config/env var | `process.env.LEAN_VERIFIER_URL` | `app/api/verification/lean/route.ts:3-4` | Consistent — exact name the code reads |
| `project-name=metaformalism-copilot`, `repository-name=metaformalism-copilot` | deploy identifier | `meta-formalism-copilot` (source repo slug) | `README.md:5` (`repository-url` param), github.com/aditya-adiga/meta-formalism-copilot | Inconsistent — drops the hyphens the source repo uses (Finding 6) |
| `#deploy-to-vercel` anchor | doc anchor | `## Deploy to Vercel` heading | `README.md:98` | Consistent — matches heading slug (fact-check Claim 8, Verified) |

## Findings

#### 1. CLAUDE.md documents a fallback mechanism the route does not have — and contradicts the README it is required to stay in sync with

**Severity:** Breaking
**Location:** `CLAUDE.md:76`
**Move:** #3 (consumer contract / documentation drift)
**Confidence:** High

CLAUDE.md states "When `LEAN_VERIFIER_URL` is unset **or unreachable**, `app/api/verification/lean/route.ts` falls back to a mock `{ valid: true, mock: true }` response." The fact-check's only **Incorrect** verdict (Claim 4a, executed twice independently) refutes the "unset" half: unset substitutes the default `http://localhost:3100` and performs a real request; the mock fires only when the fetch throws (`route.ts:3-4`, `:37-40`). In the documented dev setup the default port is exactly where the real verifier runs, so "unset → mock" is wrong precisely where a CLAUDE.md consumer (a coding agent writing tests or debugging verification) would rely on it. The same diff got this right in README.md:88 ("When the verifier is unreachable, the route falls back…") — so the two files the diff explicitly orders kept in sync ("update both `README.md` … and this file") disagree on fallback semantics from the moment the sync rule was introduced. Severity is Breaking in doc-contract terms: the documented behavioral contract is false, not merely imprecise, per executed refutation.

**Recommendation:** Rewrite CLAUDE.md:76 to the README:88 form: "the route reads `LEAN_VERIFIER_URL` (default `http://localhost:3100`); when the verifier is unreachable, it falls back to a mock `{ valid: true, mock: true }` response." Drop "unset or" from the mock condition.

#### 2. "Required" env var is not required — and the LLM mock fallback is disclosed nowhere in the deploy contract, unlike the analogous verifier mock fallback

**Severity:** Inconsistent
**Location:** `README.md:102-106` (Required environment variable table), `README.md:117-120` (Limitations on Vercel)
**Move:** #7 (asymmetry) / #3 (consumer contract)
**Confidence:** High

The deploy button and README table present `ANTHROPIC_API_KEY` as "Required", but the code enforces nothing: with no keys set, every LLM route silently degrades to the mock provider and returns `text: ""` with mock usage (`callLlm.ts:202-220`, `streamLlm.ts:137-158`; fact-check Claim 1b caveat notes a keyless deployment "behaves demo-like via the mock-LLM fallback"). The diff documents the app's *other* silent-degradation path in detail — the verifier mock, with an explicit "reported as valid without actually being type-checked" warning (README:64) and a "Limitations on Vercel" bullet — but the exactly analogous LLM mock fallback appears neither in the env-var tables nor in the limitations list. A user whose key is missing, mistyped, or later deleted gets a deployed app that appears to work while producing mock content, and the deploy docs give them no contract for that state. Two same-shaped fallback behaviors, one disclosed and one not, is the asymmetry.

**Recommendation:** Either state in the required-variable row (or Limitations) that without a valid key the app runs but returns mock LLM output, mirroring the verifier-mock disclosure; or make the key genuinely required at the deploy boundary.

#### 3. CLAUDE.md's persistence note describes a `/tmp` failure mode that doesn't match where the code writes — and understates the actual on-Vercel failure shape

**Severity:** Inconsistent
**Location:** `CLAUDE.md:77`
**Move:** #3 (consumer contract), building on fact-check Claim 7
**Confidence:** Medium

CLAUDE.md:77 says "The LLM cache and analytics log write to the local filesystem in dev. Vercel Functions can only write to `/tmp` and that lasts only as long as the warm container." The juxtaposition implies the writes land somewhere ephemeral-but-writable. The code writes to `<cwd>/data`, not `/tmp` (`persist.ts:5-6`, `cache.ts:6`; fact-check Claims 6/18a, Verified) — so if the platform claim holds (Unverifiable, Claim 7), the writes *fail* rather than persist briefly. The fact-check already notes the guard asymmetry: failures are swallowed inside `callLlm`/`streamLlm`'s `recordAndCache`, but `clearAnalyticsEntries` (called by `DELETE /api/analytics`, `app/api/analytics/route.ts:9-12`) writes with no guard, so the documented "best-effort persistence" would surface as a 500 on that route, not a silent no-op. A CLAUDE.md consumer planning "don't add features that assume durable filesystem state" is given the wrong mental model of the failure mode (ephemeral success vs. thrown error on an unguarded path).

**Recommendation:** State where the code actually writes (`<cwd>/data`) and that on a read-only/ephemeral function filesystem these writes fail — swallowed in the LLM paths, unguarded in `DELETE /api/analytics`.

#### 4. README's "when unset → mock-valid" and "runs only when" statements are Vercel-context shorthands that read as general route semantics

**Severity:** Minor
**Location:** `README.md:115` (LEAN_VERIFIER_URL row), `README.md:119` (Limitations bullet)
**Move:** #3 (consumer contract), citing fact-check Claims 16c and 17 (both Mostly accurate)
**Confidence:** High

Both statements are correct in the Vercel context but state the wrong mechanism as if general: unset does not select the mock — the route tries the default `localhost:3100` and mocks only on fetch failure; and real verification also runs when the var is unset and something listens on the default port (executed, Claims 4a/16c/17). Within the "Deploy to Vercel" section the conclusions hold (a function's own localhost has no verifier), but the row is the single reference table for the env var, and readers configuring local/dev/other hosts will read it as route semantics. This is the README-side echo of Finding 1, one notch milder because the fact-check graded these Mostly accurate rather than Incorrect.

**Recommendation:** Use the fact-check's tightened phrasings: "when unset, the route tries `localhost:3100` (unreachable on Vercel) and falls back to the mock-valid response," and "on Vercel, Lean verification runs only when `LEAN_VERIFIER_URL` points at a reachable verifier."

#### 5. Documented fallback contract presents a binary real/mock outcome; the route has a third, undocumented response class

**Severity:** Minor
**Location:** `README.md:64`, `README.md:88`; behavior at `app/api/verification/lean/route.ts:10-15,32-34`
**Move:** #4 (error consistency)
**Confidence:** Medium

The diff's descriptions ("When the service is not reachable, the verification API route returns a mock … response so the rest of the app keeps working") document exactly two outcomes: real verifier result or mock. The route has more surface: a non-OK verifier response is forwarded verbatim with its status code rather than mocked (`route.ts:32-34` — noted in the fact-check's Claim 4b/12 scope lines as explicitly out of the verified claims' scope), and a missing/non-string `leanCode` returns `{ error: "leanCode is required" }` with 400 (`route.ts:10-15`) — an error envelope shape (`{error}`) distinct from the verifier's `{valid, errors}` shape. Consumers of the documented contract (e.g., someone pointing `LEAN_VERIFIER_URL` at a proxy or misconfigured host that answers 502) will expect the mock and instead receive a forwarded error. Minor because the primary consumer (`verifyLean`, `api.ts:103-111`) tolerates it, but the docs are now the deploy-facing contract and the third class is invisible in them.

**Recommendation:** Add one clause to README:88: non-OK responses from the verifier are passed through with their status; only connection failures/timeouts produce the mock.

#### 6. Vercel button's project/repository names drop the hyphens used by the source repository

**Severity:** Minor
**Location:** `README.md:5` (`project-name=metaformalism-copilot&repository-name=metaformalism-copilot`)
**Move:** #2 (naming)
**Confidence:** Medium

Precedent: `meta-formalism-copilot` used in `README.md:5` (the same URL's `repository-url` parameter) and the GitHub repo slug `aditya-adiga/meta-formalism-copilot`

The clone flow will create each user's Vercel project and repo named `metaformalism-copilot` while the upstream it was cloned from is `meta-formalism-copilot`. Within a single URL the diff introduces two spellings of the project's identifier. Harmless functionally, but every deployed user ends up with a repo whose name doesn't match upstream, which adds friction when they later search for, fork-compare, or pull from the source.

**Recommendation:** Use `meta-formalism-copilot` for `project-name` and `repository-name` unless the hyphen-less form is deliberate (Vercel project-name constraints don't require it).

#### 7. Env-var tables become the config schema of record but omit one app-read variable

**Severity:** Informational
**Location:** `README.md:108-115` (Optional environment variables), `CLAUDE.md:73-77`
**Move:** #3 (consumer contract — config surface enumeration)
**Confidence:** Medium

The diff establishes, for the first time, authoritative env-var tables. The app also reads `SIMULATE_STREAM_FROM_CACHE` (`app/lib/llm/streamLlm.ts:105`), a dev-only knob that replays cached results as simulated token streams. Its omission from the *Vercel* table is defensible (dev-only), but it is now documented nowhere — including CLAUDE.md's Deployment section, whose audience is developers. Not a violation of an established pattern (these tables are establishing the pattern); flagged so the enumeration scope — "all vars" vs "deploy-relevant vars" — is chosen deliberately. (`PORT`/`LEAN_PROJECT_DIR` are verifier-container-side and reasonably out of scope.)

**Recommendation:** Add `SIMULATE_STREAM_FROM_CACHE` to a dev-configuration note (CLAUDE.md is the natural home), or explicitly scope the README tables as deploy-only.

## What Looks Good

- **Env-var names in the tables match the code exactly** (`ANTHROPIC_API_KEY`, `OPENROUTER_API_KEY`, `LEAN_VERIFIER_URL` — see audit table); the button's `env=` parameter names the key the code actually reads (fact-check Claim 8, Verified).
- **The OpenRouter row is accurate and admirably candid**: the fallback-order description matches the provider chain and the privacy note about prompts leaving for OpenRouter is executed-Verified (Claim 15). The "when `ANTHROPIC_API_KEY` is unset" condition is precisely the code's key-presence check, correctly implying (rather than misclaiming) that Anthropic *errors* do not fall back.
- **README:64's silent-pass warning** ("reported as valid without actually being type-checked") documents the codebase's most dangerous degradation honestly (Claims 9b/5, Verified) — a real improvement over the pre-diff text.
- **README:88 and README:96** state the unreachable-fallback mechanism correctly (Claims 12/13, Verified, executed).
- **The cross-doc sync rule** in CLAUDE.md is the right convention to establish — Finding 1 is its first violation, not an argument against it.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | CLAUDE.md "unset → mock" contradicts route behavior (fact-check Incorrect) and the README it must sync with | Breaking | `CLAUDE.md:76` | High |
| 2 | "Required" key not enforced; LLM mock fallback undisclosed while analogous verifier mock is disclosed | Inconsistent | `README.md:102-106,117-120` | High |
| 3 | `/tmp` persistence note mismatches actual write target `<cwd>/data` and the unguarded-write failure mode | Inconsistent | `CLAUDE.md:77` | Medium |
| 4 | "When unset → mock-valid" / "runs only when" are Vercel shorthands stated as general semantics | Minor | `README.md:115,119` | High |
| 5 | Third response class (non-OK passthrough, 400 `{error}`) absent from documented real/mock binary | Minor | `README.md:64,88` | Medium |
| 6 | `metaformalism-copilot` vs source slug `meta-formalism-copilot` in the deploy button | Minor | `README.md:5` | Medium |
| 7 | `SIMULATE_STREAM_FROM_CACHE` omitted from the newly authoritative env-var documentation | Informational | `README.md:108-115` | Medium |

## Overall Assessment

The diff substantially improves the deploy contract — the env-var names are exact, the verifier silent-pass is disclosed honestly, and most behavioral claims survived an executed fact-check. But the contract has one outright false statement (CLAUDE.md's "unset → mock", the fact-check's sole Incorrect verdict) sitting in the very file the diff nominates as half of a mandatory sync pair, plus a systematic asymmetry: the docs disclose one of the codebase's two silent-degradation paths (verifier mock) while presenting the other (LLM mock behind a "Required" key) as if it cannot occur. Both are fixable in place with the tightened phrasings the fact-check already supplies. Consumer impact concentrates on deployers and CLAUDE.md-driven agents reasoning about fallback behavior; no code contract changes, so nothing breaks running clients — the "Breaking" grade is doc-contract severity. Pre-existing and out of diff scope, but worth sweeping in the same pass: CLAUDE.md Prerequisites says Node v18+ while README says Node 20+.
