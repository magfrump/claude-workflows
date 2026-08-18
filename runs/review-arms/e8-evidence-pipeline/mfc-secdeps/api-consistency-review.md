# API Consistency Review — mfc-secdeps `d86d2dc...8bde50c`

**Commit:** 8bde50c
**Scope:** `git diff d86d2dc...HEAD` — `.github/workflows/ci.yml`, `eslint.config.mjs`, `package-lock.json` (commits 1efb6db, 8bde50c)
**Date:** 2026-08-18
**Based on:** `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-secdeps/code-fact-check-report.md` (k=2, canonical merged report; its verdicts are treated as binding)

The consumer-facing surfaces in this diff are not HTTP endpoints but contracts nonetheless: three eslint guardrail rules (a contract with every future contributor about what the linter will and won't let through), a CI audit gate (a contract with every PR author about what turns the build red), and two lockfile bumps described by a commit message that reviewers rely on.

## Baseline Conventions

- **CI steps** (`.github/workflows/ci.yml:26-39`): each step is `name:` + `run:` invoking either an npm script (`npm run lint`, `npm test`, `npm run build`) or a bare npx/npm command (`npx tsc --noEmit`, `npm ci`). Step names are short verb or verb-object phrases: "Install dependencies", "Lint", "Test", "Type check", "Build". Every pre-existing step is a hard gate — a nonzero exit fails the job.
- **eslint config** (`eslint.config.mjs:5-28`): flat-config array of objects, each preceded by a "why" comment (matching the repo CLAUDE.md guideline "Add comments explaining 'why'"). The lint script is bare `"lint": "eslint"` (`package.json:9`) — no `--max-warnings 0` — so only error-level rules affect exit status. `verifier/**` is globally ignored (`eslint.config.mjs:17`).
- **Escape-hatch convention:** both new rule messages instruct "write an ADR and disable this rule explicitly," consistent with CLAUDE.md's `docs/decisions/NNN-title.md` decision-record practice.
- **Commit messages:** conventional prefixes (`ci:`, `chore:`) with descriptive bodies — reviewers here demonstrably read commit bodies as contract descriptions.

## Name-Pattern Audit

The diff introduces no new exported functions, types, routes, or event schemas. The only new public names are the CI step name and the eslint rule-config entries (the rule IDs themselves are upstream eslint/plugin names, not names this diff coins).

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `Audit production dependencies` (step name) | CI step | `Install dependencies`, `Type check`, `Build` | `.github/workflows/ci.yml:26-39` | Consistent — verb-object phrase matching "Install dependencies" |
| `no-restricted-imports` / `no-restricted-syntax` / `react/no-danger` config entries | lint rule config | React-version settings block (only prior custom config object) | `eslint.config.mjs:22-28` | Consistent — same flat-config object shape, same why-comment convention |

No naming findings arise; no rows expand into Findings below.

## Findings

#### 1. Guardrail contract asymmetry: `react/no-danger` is warn-level while the shared comment promises all three rules "fail loudly"

**Severity:** Inconsistent
**Location:** `eslint.config.mjs:29-32` (comment), `eslint.config.mjs:58` (rule)
**Move:** #3 (consumer contract / documentation drift), #4 (error consistency)
**Confidence:** High

The fact-check report verdicts this directly (Claim 4b: **Incorrect**, executed evidence): a fixture whose only violation is `dangerouslySetInnerHTML` produces a warning and `eslint` exits 0, and with `"lint": "eslint"` carrying no `--max-warnings 0` (`package.json:9`), CI's Lint step passes. The block comment at lines 29-32 advertises one uniform contract for all three guardrails — "fail loudly if a future change tries to weaken any of those" — but the surface actually delivers two error-level gates and one advisory. A contributor who reads the comment (or the commit message's "all three rules verified to fire") will reasonably believe CI protects the `dangerouslySetInnerHTML` invariant; it does not. Within the rule block itself the asymmetry is also unexplained: the two rules guarding *potential* regressions are `"error"`, while the rule guarding the invariant the comment says currently holds ("Currently zero usages — keep it that way") is the one that can silently regress.

**Recommendation:** Promote `react/no-danger` to `"error"` (zero current usages means zero migration cost), or add `--max-warnings 0` to the lint script; alternatively soften the comment to state that this leg is advisory. The first option matches the documented contract; the last merely stops the drift.

#### 2. The audit gate's documented rationale doesn't hold for its own severity tier — and the "lands green" claim is already stale

**Severity:** Inconsistent
**Location:** `.github/workflows/ci.yml:41-46`; commit 1efb6db message
**Move:** #3 (consumer contract), #6 (versioning/compat impact on consumers of the CI contract)
**Confidence:** High

The step comment justifies `--audit-level=high` on the grounds that lower levels "would otherwise make every fresh CVE break CI on branches that have nothing to do with security." But that failure mode is not eliminated — it is only filtered by severity: every fresh **high/critical** CVE still breaks CI on unrelated branches, with no override, allowlist, or advisory-exception mechanism in the workflow. The fact-check demonstrates this is not hypothetical (Claim 10b: **Stale**): at HEAD the gate exits 1 with 5 high-severity production advisories (`nanoid`, `next`, `pdfjs-dist`, `postcss`, `sharp`) published after the commit date, so the commit-message promise "this branch lands green" no longer holds and every current PR author inherits a red build they didn't cause. As a contract with PR authors, the gate is non-deterministic over time in exactly the way its own comment says it was designed to avoid.

**Recommendation:** Decide the unblock path deliberately and document it in the step comment: e.g., pair the gate with a committed exception mechanism (`better-npm-audit`/`audit-ci` allowlist file, or a documented "bump-or-allowlist in a separate PR" procedure), and fix the current red state so the gate starts from green. At minimum, delete or amend the misleading rationale sentence.

#### 3. Commit message misdescribes the dependency contract change: "only patch upgrades" but lodash moved a minor version

**Severity:** Minor
**Location:** commit 1efb6db message; `package-lock.json:7338-7340`
**Move:** #3 (documentation drift), #6 (versioning impact)
**Confidence:** High

Fact-check Claim 10c (**Incorrect**, both replicates): lodash 4.17.23 → 4.18.1 is a minor bump; only `@xmldom/xmldom` 0.8.11 → 0.8.13 is a patch. Minor releases exist to add API surface, so the message's "no API changes" rests on a refuted mechanism. The consumer here is the reviewer: a repo whose workflow leans on commit bodies ("Generate detailed PR descriptions… areas of uncertainty or risk", CLAUDE.md) is one where a patch-only claim invites skipping upgrade review that a minor bump warrants. The bump itself is very likely fine (lodash 4.x transitive); the description is what's wrong.

**Recommendation:** Nothing to change in code. For the record (PR description or follow-up note), correct the characterization to "one patch, one minor upgrade." Going forward, describe semver tiers accurately in dep-bump messages.

#### 4. The `trust: true` lint contract is narrower than its documentation: quoted-key `{ "trust": true }` evades the selector

**Severity:** Minor
**Location:** `eslint.config.mjs:46-53`
**Move:** #3 (documentation drift), #7 (asymmetry between documented and actual matching)
**Confidence:** High

Fact-check Claim 6 (**Mostly accurate**, executed): the selector `Property[key.name='trust'][value.value=true]` matches identifier-keyed properties only; r2's fixture demonstrated `{ "trust": true }` produces no report, because a string-literal key has no `key.name`. The comment sells the rule as "Catches `trust: true` on object literals … Broad enough to catch `{ trust: true }` elsewhere too," so a future reader will assume the guardrail covers all object-literal spellings when a semantically identical quoted-key form (which Prettier does not normalize away in all configs, and which TypeScript treats identically) passes silently. The contract as documented and the contract as enforced diverge.

**Recommendation:** Widen the selector to cover both key kinds, e.g. `Property[value.value=true]:matches([key.name='trust'], [key.value='trust'])` (verify against the installed eslint's esquery support), or qualify the comment to "identifier-keyed `trust:` only."

#### 5. Guardrail scope silently excludes the `verifier/**` tree

**Severity:** Informational
**Location:** `eslint.config.mjs:17` (globalIgnores) vs. new rules at `eslint.config.mjs:33-60`
**Move:** #1 (baseline scope), #3 (consumer contract)
**Confidence:** Medium

The three guardrails are added in a config object with no `files` key, so they apply to everything the linter sees — but `verifier/**` is globally ignored, so the "fail loudly" contract does not extend there. The fact-check's Claim 8 scope note flags the same boundary (its grep, not the lint run, covered `verifier/**`). Since the verifier is a server-side Node project with no React rendering, the practical XSS exposure is low; this is worth one line in the comment only so the boundary is deliberate rather than accidental.

**Recommendation:** Optionally note in the guardrail comment that the lint-ignored `verifier/**` tree is out of scope. No code change required.

## What Looks Good

- **CI step naming and shape** are fully consistent: "Audit production dependencies" matches the verb-object pattern of "Install dependencies", and the `name:`/`run:` structure matches every sibling step (`.github/workflows/ci.yml:26-39`).
- **The two error-level guardrails genuinely enforce their contract** — fact-check Claims 4a and 11 (Verified, executed): fixtures for `rehype-raw` imports and identifier-keyed `trust: true` fail `eslint` with exit 1, which fails the CI Lint step.
- **Rule messages are consistent with each other and with repo convention**: both name the concrete risk mechanism, both offer the same escape hatch ("write an ADR and disable this rule explicitly"), matching the `docs/decisions/` practice in CLAUDE.md. This is a well-designed error-message contract.
- **The why-comment convention** established by the earlier config objects (`eslint.config.mjs:8-21`) is carried through on every new block.
- **The lockfile changes are additive-safe in practice**: both bumps stay within the packages' existing major lines, and fact-check Claim 10a confirms they clear the two named high-severity advisories.
- **Commit 8bde50c** is exactly what it says (fact-check Claim 12): a trailing-newline hygiene fix, no contract impact.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `react/no-danger` warn-level contradicts "fail loudly" guardrail contract | Inconsistent | `eslint.config.mjs:29-32,58` | High |
| 2 | Audit gate's rationale defeated at its own tier; "lands green" already stale (gate red at HEAD) | Inconsistent | `.github/workflows/ci.yml:41-46` | High |
| 3 | Commit message "only patch upgrades" vs. lodash minor bump | Minor | commit 1efb6db; `package-lock.json:7338-7340` | High |
| 4 | `trust: true` selector misses quoted-key form despite "broad enough" comment | Minor | `eslint.config.mjs:46-53` | High |
| 5 | Guardrails don't reach lint-ignored `verifier/**` | Informational | `eslint.config.mjs:17,33-60` | Medium |

## Overall Assessment

Structurally, this change fits the codebase well: the CI step, config-object shape, comments, and error messages all match established conventions, and no naming inconsistencies exist. The problems are contract-fidelity problems — in three places the documented contract is stronger than the enforced one (findings 1, 3, 4), and in one place the enforced contract has a failure mode its own documentation claims to have designed away (finding 2, already manifest: the gate is red at HEAD). All are fixable in place with small edits — one severity promotion or `--max-warnings 0`, one selector widening, one comment/message correction, and a deliberate decision about the audit gate's unblock path. The consumer impact of leaving them: contributors and PR authors will trust guardrails and a green-CI promise that the pipeline does not actually deliver.
