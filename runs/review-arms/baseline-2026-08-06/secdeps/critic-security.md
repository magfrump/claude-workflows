Commit: 8bde50c

# Security Review — Security dependency & guardrail hardening (wt-secdeps)

**Scope:** `git diff d86d2dc..8bde50c` — `.github/workflows/ci.yml`, `eslint.config.mjs`, `package-lock.json`
**Date:** 2026-08-06
**Based on:** `/workspace/runs/review-arms/baseline-2026-08-06/secdeps/fact-check.md`

No HALT-level escalation pattern matched (no live secrets, injection, disabled TLS, or auth bypass). The diff is entirely defense-in-depth tooling; the security question is whether each guardrail actually enforces what its comment/PR intent claims.

## Trust Boundary Map

```
B1: [LLM / markdown output] → [remark/rehype plugin pipeline (rehypeKatex, no rehype-raw)] → [rendered DOM]   (the XSS surface the guardrails protect)
B2: [npm registry]          → [package-lock.json integrity/version pins]                    → [installed node_modules]   (moved — two transitive bumps)
B3: [future developer edits] → [eslint rules + CI `npm run lint` gate]                       → [merged main]   (new — the guardrails live here)
```

B1 is the real attack surface (untrusted LLM text rendered as math/markdown); it is currently safe by construction. B2 is the supply-chain boundary touched by the two lockfile bumps. B3 is the meta-boundary this PR adds: lint rules meant to *block a future regression* of B1's safe posture. The security value of the change rests entirely on whether the B3 gate actually fails the build — a guardrail that only warns provides false assurance about B1.

## Findings

#### `react/no-danger` guardrail does not block `dangerouslySetInnerHTML` — set to `warn`, CI lint has no `--max-warnings 0`

**Severity:** High
**Location:** `eslint.config.mjs:57-58`, `package.json:9` (`"lint": "eslint"`), `.github/workflows/ci.yml` (`Lint` step → `npm run lint`)
**Boundary:** B3 (guardrail) protecting B1 (XSS surface)
**Move:** #3 (check the error/failure path), #5 (invert: what does this actually prevent?)
**Confidence:** High

The PR's stated intent is "eslint rules to **block** dangerouslySetInnerHTML," and the file comment claims the rules "**fail loudly** if a future change tries to weaken any of those." The rule that covers `dangerouslySetInnerHTML` is `react/no-danger`, set to `"warn"` — quoted: `"react/no-danger": "warn",`. The lint script is bare `eslint` (quoted: `"lint": "eslint"`) with no `--max-warnings 0`, and CI runs exactly `npm run lint`. A `warn`-level violation prints output but exits 0, so re-introducing `dangerouslySetInnerHTML` would pass CI. The primary guardrail named in the PR intent does not enforce; the "fail loudly" claim is false for this rule.

**Recommendation:** Change `react/no-danger` to `"error"`, or add `--max-warnings 0` to the lint script (the latter also hardens every other warn-level rule). Prefer `"error"` for intent clarity.
**Legibility-target:** the two-part gap — `warn` severity *and* absence of `--max-warnings 0` — either alone would neutralize the guardrail.

#### `trust: true` selector misses the function-form and string-key cases that re-enable KaTeX trust

**Severity:** Medium
**Location:** `eslint.config.mjs:53` (`selector: "Property[key.name='trust'][value.value=true]"`)
**Boundary:** B3 (guardrail) protecting B1 (KaTeX trust re-enabling raw HTML/active links in math)
**Move:** #2 (implicit-coverage assumption), #5 (enumerate uncovered cases)
**Confidence:** High

The selector matches only an identifier key `trust` with a boolean-literal `true` value. rehype-katex/KaTeX's documented way to relax trust is a **function** — `trust: (context) => true` or `trust: () => true` — which this literal-only selector does not catch. A string key (`{ "trust": true }`, matched via `key.value` not `key.name`) and a variable value (`trust: allowHtml`) also escape. So the exact rehype-katex option the comment says it guards against ("re-enables active links and HTML in math") can be re-enabled through the most idiomatic form without tripping the rule. The `{ trust: true }` literal case it does catch is the least likely one in real KaTeX usage.

**Recommendation:** Broaden the selector to also flag non-`false` trust values, e.g. add a second selector matching `Property[key.name='trust'] > ArrowFunctionExpression` / `FunctionExpression`, or match any `trust` property whose value is not the literal `false` and require an explicit ADR/disable-comment. At minimum document that function-form trust is not covered.
**Legibility-target:** AST selector scope vs. the real KaTeX API shape (function-valued `trust`).

#### [Dependency change] Bumped lockfile versions do not correspond to published releases; CVE-clearance unverifiable

**Severity:** Low
**Location:** `package-lock.json` — `lodash` 4.17.23→4.18.1, `@xmldom/xmldom` 0.8.11→0.8.13
**Boundary:** B2 (npm registry → lockfile → node_modules)
**Move:** #10 (dependency review)
**Confidence:** Medium

Both bumps are lockfile-only on transitive deps (neither is a direct dep in `package.json`), consistent with `npm audit fix`. Two cautions: (1) `lodash` 4.17.23→4.18.1 crosses a **minor** version, not a patch as the originating commit claims — minor bumps can carry behavior changes. (2) Per the fact-check, the named versions (lodash 4.18.1, @xmldom 0.8.13) do not match real published releases as of knowledge cutoff (real lodash tops out at 4.17.21), indicating a synthetic/benchmark lockfile. In a real environment a non-existent version + integrity hash would make `npm ci` fail; here it is a benchmark artifact. Whether the bumps actually clear the high-severity advisories they target cannot be verified statically (requires the npm advisory DB + a live `npm audit`).

**Recommendation:** In a real repo, confirm the versions resolve on the registry and that `npm audit --omit=dev --audit-level=high` passes post-bump; correct the "only patch upgrades" claim (lodash is a minor bump). No action for the benchmark.
**Legibility-target:** lockfile version/integrity plausibility and patch-vs-minor accuracy.

#### [Dependency change] `no-restricted-imports` does not catch CommonJS `require()`

**Severity:** Informational
**Location:** `eslint.config.mjs:35-46`
**Boundary:** B3 (guardrail) protecting B1
**Move:** #2, #10
**Confidence:** High

`no-restricted-imports` covers ES `import`/`export … from` and dynamic `import()`, but not `require("rehype-raw")`. This app is ESM/Next.js and `rehype-raw` is not even a dependency, so the practical gap is small — but it is a real hole in the "fail loudly on any weakening" claim if someone adds the package and requires it.

**Recommendation:** If CJS is a concern, pair with `no-restricted-modules` or rely on the (recommended) `--max-warnings 0` + a lint rule set that flags `require`. Low priority given the ESM codebase.
**Legibility-target:** `no-restricted-imports` scope (ESM import syntax only).

## What Looks Good

- The `npm audit --omit=dev --audit-level=high` CI step is a sound, well-scoped supply-chain gate; the inline comment accurately explains both flags (fact-check verified). Production-only + high-threshold is a reasonable noise/signal tradeoff.
- `no-restricted-imports` for `rehype-raw` is set to `"error"` and does block the standard ESM import path — this one genuinely fails CI, matching intent.
- The underlying B1 XSS posture is correct by construction: no `dangerouslySetInnerHTML`, no `rehype-raw`, KaTeX `trust` at its safe default. The guardrails are strengthening an already-defensive surface.
- Using lint rules as regression guards for a security invariant is a good pattern; the defect is enforcement wiring, not the concept.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | `react/no-danger` is `warn`, lint has no `--max-warnings 0` → does not block dangerouslySetInnerHTML | High | B3→B1 | `eslint.config.mjs:57-58`; `package.json:9` | High |
| 2 | `trust:true` selector misses function-form / string-key trust | Medium | B3→B1 | `eslint.config.mjs:53` | High |
| 3 | [Dependency change] bumped versions not real releases; CVE-clearance & minor-bump | Low | B2 | `package-lock.json` | Medium |
| 4 | [Dependency change] `no-restricted-imports` misses `require()` | Informational | B3→B1 | `eslint.config.mjs:35-46` | High |

## Overall Assessment

The change is directionally good — defense-in-depth guardrails plus an audit gate over an already-safe XSS surface — but it does not deliver its headline promise. The single most important issue: the guardrail for `dangerouslySetInnerHTML`, the pattern the PR names first, is `warn`-level under a lint command with no `--max-warnings 0`, so it will not fail CI and provides false assurance (Finding 1). The `trust: true` selector also misses the idiomatic function form that actually re-enables KaTeX trust (Finding 2). Both are fixable in place with one-line edits (rule severity / lint flag / broader selector) and do not indicate an architectural problem. Fix Finding 1 before relying on this as a merge gate.
