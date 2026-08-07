Commit: 8bde50c
# Architecture Review — secdeps (Security dependency & guardrail hardening)

**Scope:** `git diff d86d2dc..8bde50c` — `.github/workflows/ci.yml`, `eslint.config.mjs`, `package-lock.json`
**Date:** 2026-08-06
**Based on:** `/workspace/runs/review-arms/baseline-2026-08-06/secdeps/fact-check.md` (11 claims; used as behavioral foundation, not re-verified)
**PR intent:** Security dependency & guardrail hardening via eslint rules + dependency bumps.

Trust-Boundary Cross-Reference: no `docs/reviews/security-review-*.md` present in this worktree — the security-reviewer integration is a **no-op** for this pass. Module-boundary findings below stand on their own.

## Scope Check

In scope under trigger category #4 (**cross-cutting concerns**): the new `eslint.config.mjs` block is a defense-in-depth *policy pipeline* — a control that spans the whole tree and whose coherence/coverage determines whether XSS-surface regressions are caught. The CI `npm audit` step is likewise cross-cutting infra config. The `package-lock.json` bumps alone are dependency-version bumps (out of scope for architecture per the skill; deferred to security-reviewer). This review evaluates the guardrail rule set as a cross-cutting control: **is the policy coherent and complete?**

## Dependency Map

No module-graph edges change. `eslint.config.mjs` composes `eslint-config-next` presets and appends an anonymous rules block; the new rules apply globally except where `globalIgnores([... "verifier/**"])` excludes the CommonJS verifier subtree. The stated protected surface is the markdown/LaTeX render path (`app/components/features/output-editing/LatexRenderer.tsx`, plugin set `remarkGfm/remarkMath` + `rehypeKatex`). The policy is the "stable core" here; the render components are the "volatile" consumers it guards. Direction is sound — a tooling/policy layer sitting above app code, not reaching into it.

## Findings

#### Guardrail policy is internally incoherent: one of three "fail loudly" rules cannot fail

**Severity:** Coupling
**Location:** `eslint.config.mjs:57` + `package.json:9`
**Move:** #2 (responsibility boundaries) / cross-cutting-control coherence
**Confidence:** High

The policy block's own comment states these rules "fail loudly if a future change tries to weaken any of those." Two rules are `"error"`, but the third is `"react/no-danger": "warn"`, and the lint entrypoint is bare `"lint": "eslint"` with no `--max-warnings 0`. A `warn`-level rule under bare eslint exits zero, so re-introducing `dangerouslySetInnerHTML` prints a warning and CI stays green. The control's three surfaces are heterogeneous in enforcement while presenting as uniform — a downstream maintainer reading the comment will trust a guardrail that does not hold. This is the central coherence gap in the cross-cutting policy: the `dangerouslySetInnerHTML` vector (the one the comment leads with) is the *unenforced* one.

**Recommendation:** Promote `react/no-danger` to `"error"`, or set `--max-warnings 0` on the lint script so warn-level policy rules block. Make enforcement level uniform across the three guardrails or document per-rule why it differs.

#### `trust: true` selector under-covers the vector it names (string keys and function values escape)

**Severity:** Coupling
**Location:** `eslint.config.mjs:50-55`
**Move:** #3 (module boundary / control coverage)
**Confidence:** Medium

The selector `"Property[key.name='trust'][value.value=true]"` matches only an identifier key with a literal boolean `true`. rehype-katex/KaTeX accept `trust` as a **function** (`trust: () => true`) — the documented way to selectively re-enable links/HTML — and a string-keyed `{ "trust": true }` uses `key.value`, not `key.name`. Both bypass the guardrail while achieving exactly the weakening the comment warns against ("re-enables active links and raw HTML in math output"). The rule covers the least-likely literal form and misses the idiomatic function form, so the control's coverage does not match its stated intent.

**Recommendation:** Broaden the selector to also match `key.value='trust'` (string keys) and non-literal/function values (e.g., `Property[key.name='trust']:not([value.value=false])`), or accept the narrow scope explicitly in the comment so the residual gap is legible.

#### Import guardrail is ESM-only and the verifier subtree is exempt — two silent bypass paths

**Severity:** Coupling
**Location:** `eslint.config.mjs:35-48` (rule) + `eslint.config.mjs:16` (`"verifier/**"` ignore)
**Move:** #3 (module boundary / control coverage)
**Confidence:** Medium

`no-restricted-imports` catches ES `import`/`import()` but not CommonJS `require("rehype-raw")`. Separately, `globalIgnores` excludes `verifier/**` — a Node/CommonJS subproject — so *none* of the three guardrails apply there. In this ESM Next.js app the main render path is well-covered, but the "fail loudly if a future change tries to weaken any of those" claim overstates reach: any code taking the CommonJS path, or living under `verifier/`, is uncovered. This is a coverage gap in a control whose value is precisely completeness.

**Recommendation:** Either scope the policy explicitly to the app render surface (`files:` on the block) so its boundary is honest, or extend coverage (e.g., a `no-restricted-modules`/require lint or a note that verifier is intentionally out of scope). Lead the comment with the actual coverage boundary.

#### Cross-cutting security policy has no decision record

**Severity:** Minor
**Location:** `eslint.config.mjs:28-58`
**Move:** #2 (responsibility placement)
**Confidence:** High

The guardrail messages instruct future authors to "write an ADR and disable this rule explicitly," but the policy that establishes these rules has no ADR of its own — its rationale, threat model, and coverage boundary live only in inline comments. For a cross-cutting security control that others are told to gate changes against via ADRs, the absence of a `docs/decisions/NNN` anchor makes the policy's intent and known gaps (Findings above) undiscoverable outside the config file.

**Recommendation:** Add a short decision record documenting the guardrail set, its threat model (LLM-output XSS via markdown/math), enforcement levels, and the known coverage gaps, and reference it from the config comment.

## What Looks Good

- Correct architectural placement: security guardrails as a tooling-layer policy above app code, not woven into render components — the render path stays a black box the policy observes from outside.
- The `no-restricted-imports` and `no-restricted-syntax` rules are `"error"` and genuinely block their (in-scope, ESM/literal) cases — the enforced portion of the control is real.
- CI `npm audit --omit=dev --audit-level=high` is well-scoped cross-cutting infra: production-only, high+ threshold, with a comment explaining why lower levels are non-blocking — avoids unrelated branches breaking on fresh CVEs.
- Escape hatch is designed in (ADR-gated rule disable), which keeps the guardrail from becoming an obstruction.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | One of three "fail loudly" rules is non-enforcing (warn + no --max-warnings) | Coupling | `eslint.config.mjs:57`, `package.json:9` | High |
| 2 | `trust:true` selector misses string-key and function-valued forms | Coupling | `eslint.config.mjs:50-55` | Medium |
| 3 | Import guardrail ESM-only; `verifier/**` subtree exempt | Coupling | `eslint.config.mjs:35-48,16` | Medium |
| 4 | No ADR/decision record for the cross-cutting policy | Minor | `eslint.config.mjs:28-58` | High |

## Overall Assessment

Structurally the change is sound and additive — it introduces a policy layer in the right place with no dependency-direction or layering harm, and the dep bumps are inert to architecture. The concern is not placement but **coherence and completeness of the cross-cutting control**: the policy presents three uniform "fail loudly" guardrails, but one cannot fail (warn), and the other two under-cover the very vectors they name (function-valued `trust`, CommonJS require, the exempt `verifier/**` tree). None rise to Structural — every gap is fixable in place by tightening a rule value, a selector, or the lint invocation. The single most important concern is Finding 1: a security guardrail that silently does not enforce is worse than none, because it manufactures false confidence. Close the enforcement gap and make the control's true coverage boundary legible (ideally via an ADR) and the policy becomes as coherent as it claims to be.
