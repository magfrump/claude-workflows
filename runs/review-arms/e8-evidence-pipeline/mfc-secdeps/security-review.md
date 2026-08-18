# Security Review — mfc-secdeps (eslint guardrails + npm audit gate + dep bumps)

**Commit:** 8bde50c
**Scope:** `git diff d86d2dc...HEAD` — `.github/workflows/ci.yml`, `eslint.config.mjs`, `package-lock.json`
**Date:** 2026-08-17
**Based on:** code-fact-check report at `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-secdeps/code-fact-check-report.md` (k=2, commit 8bde50c). Its refuted/incorrect verdicts (Claims 4b, 10c) and stale verdict (10b) are treated as binding; documented behavior is not re-verified.

No HALT-escalation pattern matched: the diff adds no plaintext secrets, no unauthenticated privileged endpoint, no injection sink, no TLS-disabling flag, and no hardcoded key. It is a hardening change, so the findings below are almost all *guardrail-efficacy gaps* — ways the newly added defenses fail to do what their comments claim — rather than live vulnerabilities the diff introduces.

## Trust Boundary Map

```
B1: [LLM/markdown output] → [react-markdown + rehype pipeline; KaTeX] → [rendered DOM]   (protected surface — not modified this diff)
B2: [future developer-authored source] → [eslint guardrails: no-restricted-imports / no-restricted-syntax / react/no-danger] → [merged code on B1]   (new)
B3: [npm registry + advisory DB (time-varying)] → [npm audit --omit=dev --audit-level=high gate] → [CI pass/fail → merge]   (new)
B4: [npm registry package contents] → [package-lock.json version+integrity pins] → [installed node_modules]   (moved — two pins bumped)
```

The diff does not touch the runtime XSS surface (B1) itself. It adds a *meta*-boundary B2: lint rules whose job is to stop a future change from re-opening B1 (adding `rehype-raw`, setting KaTeX `trust:true`, or introducing `dangerouslySetInnerHTML`). It adds a supply-chain gate B3 that couples merge-ability to an external, time-varying advisory database, and it moves two version pins at B4. Every finding below sits on B2, B3, or B4. The security value of this change rests almost entirely on whether the B2 guardrails actually catch what their comments promise — so B2 is where I spent move #11.

## Findings

#### `no-restricted-imports` guardrail catches only the exact static specifier; dynamic import, `require`, and subpath imports all reach `rehype-raw`

**Severity:** Medium
**Location:** `eslint.config.mjs:35-45`
**Boundary:** B2
**Move:** #11 (enumerate bypasses)
**Confidence:** Medium

The rule blocks `import rehypeRaw from "rehype-raw"` (fact-check Claim 4a, Verified). But `no-restricted-imports` with a bare `paths[].name` matches only the exact static module specifier. I linted a fixture exercising three bypasses and the guardrail reported **zero problems, exit 0** (`evidence/sec-bypass-imports.txt`): (b1) `await import("rehype-raw")` dynamic import; (b2) `require("rehype-raw")`; (b3) `import sub from "rehype-raw/lib/index.js"` subpath. Any of these re-enables the exact XSS vector the comment at `eslint.config.mjs:29-31` says is guarded (raw HTML in markdown rendering as live DOM on B1), while passing lint and therefore CI. The comment "fail loudly if a future change tries to weaken any of those" overstates the coverage — the guard is a partial static-specifier filter, not a barrier against importing the package.

**Recommendation:** Add `patterns` covering `rehype-raw` and `rehype-raw/**` to `no-restricted-imports`, and pair with `no-restricted-syntax`/`no-restricted-properties` selectors for `import()` and `require("rehype-raw")` call expressions, or gate at the bundler/`package.json` level (e.g., forbid the dependency outright). Soften the comment to state the residual gaps.

#### `no-restricted-syntax` trust selector misses the KaTeX-supported callback form and every non-identifier-literal shape

**Severity:** Medium
**Location:** `eslint.config.mjs:50-56`
**Boundary:** B2
**Move:** #11 (enumerate bypasses)
**Confidence:** Medium

The selector `Property[key.name='trust'][value.value=true]` matches only an identifier key with a boolean-literal `true` value. My fixture (`evidence/sec-bypass-trust.txt`) confirms it fires on the control `{ trust: true }` (line 10) and **nothing else** — exit 1 with a single error. The following all evade: `{ trust: () => true }`, `{ trust: 1 }`, `{ trust: SOME_IDENTIFIER }`, `{ ["trust"]: true }` (computed key), and `obj.trust = true` (post-construction assignment). The fact-check independently documented the string-literal-key evasion `{ "trust": true }` (Claim 6, Mostly accurate). The callback form is the sharpest miss: KaTeX's `trust` option is documented to accept a function (`node_modules/katex/types/katex.d.ts`), so `trust: () => true` is a *fully functional, idiomatic* way to enable trusted rendering on B1 — active links / raw HTML in math output — that the guardrail does not see. The comment's claim of being "broad enough to catch `{ trust: true }` elsewhere too" is true only for the identifier-keyed literal.

**Recommendation:** Broaden the selector set to cover string/computed keys (`Property[key.value='trust']`), truthy non-`false` values, and member-assignment (`AssignmentExpression[left.property.name='trust']`); explicitly flag any function-valued `trust` for manual review since a callback cannot be statically proven safe. Or move the check to a typed lint rule / runtime assertion at the rehype-katex call site.

#### `react/no-danger` is warn-level and does not fail CI; `createElement` form evades it entirely

**Severity:** Medium
**Location:** `eslint.config.mjs:57-58`; `.github/workflows/ci.yml:29-30`; `package.json:9` (lint script)
**Boundary:** B2
**Move:** #3 (error/failure path), #11 (bypasses)
**Confidence:** High

This builds directly on fact-check **Claim 4b (Incorrect, binding)**: the rule is registered at `"warn"`, the CI lint step is plain `eslint` with no `--max-warnings 0`, and `eslint` exits 0 on warnings — so a future change reintroducing `dangerouslySetInnerHTML` (a direct XSS sink on B1) passes CI. The comment block at `eslint.config.mjs:29-32` groups this under rules that "fail loudly"; for this leg the guardrail does not fail at all. My fixture adds a second, independent gap (`evidence/sec-bypass-danger.txt`, exit 0): `React.createElement("div", { dangerouslySetInnerHTML: {...} })` produces no finding even at warn level (the rule only inspects JSX attributes), and a raw `el.innerHTML = html` assignment is covered by no rule in this config. So the sink is reachable through the JSX form (warns, still merges) and through two forms that are entirely invisible.

**Recommendation:** Promote to `"error"` and/or add `--max-warnings 0` to the lint script so the warn-level rules actually block CI; add a `no-restricted-properties`/`no-restricted-syntax` selector for `dangerouslySetInnerHTML` in `createElement` calls and for `.innerHTML =` assignments if that sink is in scope. At minimum, correct the "fail loudly" comment.

#### [Dependency change] Audit gate couples all-branch merge-ability to a time-varying external advisory DB

**Severity:** Low
**Location:** `.github/workflows/ci.yml:45-46`
**Boundary:** B3
**Move:** #8 (scale / availability), #10 (dependency changes)
**Confidence:** High

Per fact-check **Claim 10b (Stale, binding)**, the gate `npm audit --omit=dev --audit-level=high` already exits 1 at HEAD because of five high-severity production advisories (nanoid, next, pdfjs-dist, postcss, sharp) published after the 2026-04-27 commit — none related to the code on any given branch. The mechanism is intrinsic to auditing against a live DB in the merge gate: any newly published high-severity CVE in a shipped transitive dep blocks *every* open PR until someone bumps the dep, independent of what the PR changes. That is an availability property of the pipeline (a self-inflicted merge freeze), not a code vulnerability, hence Low. The `--omit=dev` and `--audit-level=high` choices themselves are reasonable and reduce false positives (fact-check Claims 1, 2, Verified).

**Recommendation:** Consider running the audit as a scheduled/non-blocking job, or pinning it to `continue-on-error` with a separate alerting path, so a fresh upstream CVE surfaces without freezing unrelated merges. If it must gate, pair it with a documented fast-path (allowlist / `npm audit --json` triage) for advisories with no available fix.

#### [Dependency change] lodash bump is a minor upgrade described as patch-only

**Severity:** Low
**Location:** `package-lock.json:7336-7342`
**Boundary:** B4
**Move:** #10 (dependency changes)
**Confidence:** High

Per fact-check **Claim 10c (Incorrect, binding)**, the commit message's "only patch upgrades, no API changes" is wrong for lodash: `4.17.23 → 4.18.1` is a semver *minor* bump (`@xmldom/xmldom 0.8.11 → 0.8.13` is indeed patch). Both bumps clear real high-severity advisories at their base versions (fact-check Claim 10a, Verified), so the change is a legitimate security fix — the issue is only that the minor bump carries added API surface a "patch-only" review policy would wave through unexamined. No CVE or malicious-version signal was found in the diff for either package. Low, informational-leaning.

**Recommendation:** Correct the commit-message classification; when a minor bump lands under a security-fix banner, note the added-surface risk so downstream reviewers don't skip it under a patch-only fast path.

## Untested bypass candidates

None outstanding for the guardrails — the three B2 guardrails each had ≥3 bypass candidates enumerated and **tested** via fixture lint runs (`evidence/sec-bypass-imports.txt`, `sec-bypass-trust.txt`, `sec-bypass-danger.txt`). For B3, transitive-dependency substitution / dependency-confusion vectors against the two bumped packages were **not** tested — out of scope per the skill's "not a full supply-chain audit" bound; the lockfile pins integrity hashes, which mitigates tampering of the pinned versions but was not independently re-derived here.

## Endorsement Claims

Per move #11, the three B2 lint guardrails have **tested-failing** bypass candidates and therefore may not be endorsed as effective — they are covered by the findings above, not here.

- **Claim:** The audit gate passes `--omit=dev`, so advisories confined to devDependency trees do not contribute to the gate's exit code.
  **Location:** `.github/workflows/ci.yml:41,45-46`
  **Evidence:** executed
  **Verified:** Fact-check Claim 1 (Verified, executed) — `npm audit --omit=dev --audit-level=high` reported 6 findings vs. 11 unrestricted, the delta being dev-tree packages (`@babel/core`, `brace-expansion`, `picomatch`, `undici`/`vite`).
  **Not verified:** Whether every package in the `dependencies` block literally reaches the browser bundle (server/build-only deps like `next`/`sharp` are still audited).
  **route: code-fact-check**

- **Claim:** The two bumped pins (`@xmldom/xmldom` 0.8.11→0.8.13, `lodash` 4.17.23→4.18.1) move both packages off versions that carried high-severity advisories, and neither appears in the HEAD `--omit=dev` audit.
  **Location:** `package-lock.json:3857-3862,7336-7342`
  **Evidence:** executed
  **Verified:** Fact-check Claim 10a (Verified, executed) — base-lockfile audit showed both as high-severity at old versions; HEAD audit lists neither.
  **Not verified:** Whether lodash 4.18.x introduces or changes any callable API surface relied on by first-party code (the "no API changes" half is unverified; fact-check judged only the semver class).
  **route: code-fact-check**

- **Claim:** The reviewed hunks are confined to CI config, additive lint rules, and two lockfile version/integrity fields — no credential literal, network endpoint, or auth-control edit appears in the diff.
  **Location:** `.github/workflows/ci.yml:38-46`, `eslint.config.mjs:29-60`, `package-lock.json:3857-3862,7336-7342`
  **Evidence:** read-static
  **Verified:** Read the full three-file diff; the only content is the audit step + comment, the defense-in-depth rules block, and two `version`/`resolved`/`integrity` triples.
  **Not verified:** The transitive install graph the two bumped pins pull (`npm ci` resolves integrity hashes not re-derived here).

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | `no-restricted-imports` bypassable via dynamic/require/subpath import | Medium | B2 | `eslint.config.mjs:35-45` | Medium |
| 2 | trust selector misses callback / non-literal forms | Medium | B2 | `eslint.config.mjs:50-56` | Medium |
| 3 | `react/no-danger` warn-only (no CI fail) + `createElement`/`innerHTML` evasion | Medium | B2 | `eslint.config.mjs:57-58` | High |
| 4 | [Dependency change] audit gate freezes all-branch merges on fresh upstream CVE | Low | B3 | `.github/workflows/ci.yml:45-46` | High |
| 5 | [Dependency change] lodash minor bump labeled patch-only | Low | B4 | `package-lock.json:7336-7342` | High |

## Overall Assessment

This is a net-positive hardening change: the dependency bumps clear real high-severity advisories, and the `--omit=dev`/`--audit-level=high` gate is a sensible signal-to-noise choice. The security concern is that the change over-claims its own defenses. All three B2 lint guardrails are advertised as failing "loudly" against any future re-opening of the XSS surface, but each has tested, idiomatic bypasses: the import guard sees only the exact static specifier, the trust selector sees only an identifier-keyed boolean literal (and misses KaTeX's own function form), and `react/no-danger` is warn-level so it never blocks CI. None of these introduces a live vulnerability today — they weaken the defense-in-depth story a future author would rely on. The single most important fix is to promote `react/no-danger` to `error` (or add `--max-warnings 0`) and broaden the two `no-restricted-*` rules so the guardrails match the coverage their comments promise; failing that, soften the comments so no one trusts a guard that a one-line variant walks through. No findings within the code paths read rise above Medium; all Medium findings are guardrail-efficacy gaps with tested mechanisms, and the two endorsement claims backed by execution are marked `route: code-fact-check` pending the orchestrator's verdict.
