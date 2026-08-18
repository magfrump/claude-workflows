# Performance Review — mfc-secdeps (npm audit gate + defensive lint rules)

**Commit:** 8bde50c
**Scope:** `git diff d86d2dc...HEAD` — `.github/workflows/ci.yml`, `eslint.config.mjs`, `package-lock.json` (commits 1efb6db, 8bde50c)
**Date:** 2026-08-17
**Based on:** `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-secdeps/code-fact-check-report.md` (k=2 merged, executed verdicts, checked 2026-08-18)

## Data Flow and Hot Paths

Nothing in this diff executes in the application's request path. The three changed surfaces are:

1. **CI workflow** (`.github/workflows/ci.yml`): a new `npm audit --omit=dev --audit-level=high` step appended after install → lint → tsc → build. Runs once per CI invocation (every push/PR run), so its cost multiplies by CI-run frequency, not by user traffic. Cold path in application terms; the "hot loop" here is the development pipeline itself.
2. **Lint config** (`eslint.config.mjs`): three rules added to the existing eslint invocation — two error-level (`no-restricted-imports`, `no-restricted-syntax` with an AST selector) and one warn-level (`react/no-danger`). Executed only inside `npm run lint` in CI and locally.
3. **Lockfile** (`package-lock.json`): version/resolved/integrity bumps for two production transitives — `@xmldom/xmldom` 0.8.11 → 0.8.13 (patch) and `lodash` 4.17.23 → 4.18.1 (minor, per fact-check Claim 10c). `lodash` reaches the app via dagre/graphlib and `@xmldom/xmldom` via mammoth (fact-check Claim 10a), so these *do* sit in production code paths, though the diff itself changes no call sites.

No measured CI-duration, latency, or throughput baselines exist anywhere in the repo or the fact-check report; the only real measurements available are the fact-check's executed audit/lint runs (exit codes and finding counts). Findings below use those where applicable and are otherwise flagged speculative.

## Findings

#### Audit gate is ordered last in the pipeline and currently fails — every CI run pays full install/lint/tsc/build before dying

**Severity:** Medium
**Location:** `.github/workflows/ci.yml:39-46`
**Move:** Find the work that moved to the wrong place (fail-slow step ordering)
**Classification:** Macro (structural pipeline ordering) / Cold path (CI, but executed once per push/PR)
**Confidence:** High
**Baseline:** `npm audit --omit=dev --audit-level=high` exits 1 at HEAD, executed 2026-08-18T06:11Z (fact-check Claim 10b, both replicates; `evidence/r1-audit-omit-dev-high.txt`)

The audit step is appended after Build, but it depends only on the installed tree and lockfile — nothing produced by lint, typecheck, or build. Ordering it last means that whenever the gate is red, CI spends the entire install + lint + tsc + `npm run build` budget before failing at the final step. This is not hypothetical: the fact-check's execution verdict shows the gate exits 1 at HEAD (5 high-severity production advisories in nanoid/next/pdfjs-dist/postcss/sharp), so as merged, *every* CI run on every branch pays the full pipeline cost and then fails. The wasted minutes per run are unmeasured (no CI timing baseline exists), so the dollar/latency magnitude is speculative even though the failure itself is execution-verified.

**Recommendation:** Move the audit step immediately after `npm ci` (it needs nothing later), so a red advisory DB fails the run in seconds instead of after the build. Separately resolve the current red state (see next finding) — a permanently failing terminal step is the worst-case ordering.

#### CI outcome is now gated on a time-varying external input, and the chosen threshold does not deliver the isolation the comment prices in

**Severity:** Medium
**Location:** `.github/workflows/ci.yml:41-46`
**Move:** Price the deployment environment
**Classification:** Macro (fleet-wide CI availability coupled to an external, uncontrolled input) / Cold path (per-CI-run)
**Confidence:** High
**Baseline:** 6 vulnerabilities (1 moderate, 5 high) reported by the gate at HEAD, all from advisories published after the 2026-04-27 commit — npm advisory DB as of 2026-08-18T06:11Z (fact-check Claims 10b, 1)

The comment justifies `--audit-level=high` as preventing "every fresh CVE" from breaking unrelated branches, and the fact-check verified the threshold mechanism works (Claim 2, executed). But the threshold only shields *low/moderate* advisories; any fresh **high** advisory in the production tree still turns every branch red simultaneously — which is exactly what has happened since the commit landed (Claim 10b: green-when-written, red now, with zero code changes). The cost model under load: N open branches × M CI runs/day all fail together on advisory-DB churn, and each failure costs a full pipeline run (compounded by the ordering finding above) plus developer re-run/triage time. There is no caching, pinning, or advisory-snapshot mechanism, so the gate also adds one uncached npm-registry round trip per run and couples CI availability to registry availability.

**Recommendation:** Decide the intended failure domain explicitly: either accept fleet-wide red on fresh high CVEs (and add an allowlist/exception file such as `audit-ci` or `npm audit --json` + known-advisory filter so unrelated branches can keep merging while a fix lands), or move the audit to a scheduled/nightly workflow that files an issue instead of blocking every branch. Whichever is chosen, the current always-red state must be cleared or the gate is pure cost.

#### lodash minor bump entered the production tree under a refuted "patch-only" classification — runtime characteristics unassessed

**Severity:** Low
**Location:** `package-lock.json:7338-7342`
**Move:** Using the fact-check report (building on a refuted mechanism)
**Classification:** Micro (per-call library internals, unknown delta) / Hot path *potentially* — lodash is a production transitive via dagre/graphlib (fact-check Claim 10a), which typically executes in graph-layout code paths
**Confidence:** Medium
**Baseline:** no baseline available — flagged as speculative

The commit message's "only patch upgrades, no API changes" was verdicted **Incorrect** (fact-check Claim 10c): lodash 4.17.23 → 4.18.1 is a minor bump, and the "no API changes" half was judged only via the refuted patch mechanism, not a source diff. That refutation binds this review: I cannot treat the bump as behavior-preserving, and nobody has assessed what 4.18.x changes at runtime. Minor releases can alter internal algorithms and allocation patterns of heavily-called utilities. lodash's realistic call frequency here (graph layout via dagre) is likely bursty rather than per-request-hot, and semver minors are presumptively non-breaking, so impact is probably nil — but "probably nil" is exactly the class of claim this diff's own commit message got wrong.

**Recommendation:** Run the dependency-upgrade review the "patch-only" framing skipped: skim the lodash 4.18.0/4.18.1 changelog for algorithmic changes to functions dagre/graphlib actually call, and correct the commit-message record so downstream tooling doesn't inherit the patch-only assumption.

#### Added lint rules cost one AST-selector match per node per lint run — negligible at this repo's scale

**Severity:** Informational
**Location:** `eslint.config.mjs:29-58`
**Move:** Count the hidden multiplications
**Classification:** Micro (constant per-node selector matching) / Cold path (lint step only)
**Confidence:** High
**Baseline:** repo-wide `npm run lint` completed with 2 warnings, exit 0, executed 2026-08-18T06:12:58Z (fact-check Claim 8, `evidence/r1-npm-run-lint.txt` — finding counts only; no duration was captured)

`no-restricted-syntax` with `Property[key.name='trust'][value.value=true]` is evaluated against every `Property` node in every linted file, and `no-restricted-imports` against every import. This multiplies by file count × node count per lint run, but esquery selector matching is what eslint is built for, the rules ride the existing `npm run lint` invocation (no new process, no new CI step), and the fact-check's executed repo-wide lint completed normally. This is Micro × Cold: recorded only so the calibration is auditable, not as something to act on.

**Recommendation:** None needed.

## Endorsements (evidence-gated)

- The `--omit=dev` scoping demonstrably halves the audited surface (6 findings vs 11 unrestricted), keeping the CI gate's work and failure noise proportional to what actually deploys. [fact-check: claim 1 — Verified]
- The `--audit-level=high` threshold mechanism works as priced in the comment: below-threshold advisories are printed but non-failing, so low/moderate advisory churn cannot consume CI capacity — the executed runs show exit 0 at a raised threshold with the same advisories printed. [fact-check: claim 2 — Verified]
- The two error-level guardrails fail the existing `npm run lint` CI step on a violating fixture (exit 1), so enforcement adds zero new CI steps or tool invocations — detection cost is folded into work CI already does. [fact-check: claim 4a — Verified]
- The eslint additions and the audit step are the diff's only executable changes; the lint rules are appended to the existing `defineConfig` array and the workflow adds exactly one step, so no per-request or application-runtime cost is introduced by the config surfaces themselves. [read: eslint.config.mjs:29-58; .github/workflows/ci.yml:39-46]
- The lockfile diff touches only the version/resolved/integrity fields of two already-installed transitive packages, so `npm ci` in CI resolves and installs the same package count and its duration is materially unchanged by this diff. [unverified — submitted as claim]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Audit gate ordered last; currently red, so every CI run pays full build before failing | Medium | `.github/workflows/ci.yml:39-46` | High |
| 2 | CI gated on time-varying advisory DB; high-severity churn reds all branches at once | Medium | `.github/workflows/ci.yml:41-46` | High |
| 3 | lodash minor bump in production tree under refuted "patch-only" claim; runtime delta unassessed | Low | `package-lock.json:7338-7342` | Medium |
| 4 | New lint rules add per-node selector matching in lint step only | Informational | `eslint.config.mjs:29-58` | High |

## Overall Assessment

The application's runtime performance posture is untouched by this diff — every executable change lives in the development pipeline, and the only production-tree changes are two transitive version bumps. The performance story is therefore a CI-economics story, and there the change has a real structural problem: it installs a gate whose failure condition is an external, time-varying input (the npm advisory DB), places that gate at the *end* of the pipeline, and — per the fact-check's execution verdicts — the gate is already red at HEAD, meaning every CI run on every branch currently burns a full install/lint/typecheck/build and then fails. Both Medium findings are fixable in place (reorder the step; choose an explicit failure-domain policy with an exception mechanism), and fixing them should precede any celebration of the gate's security value, because a permanently red gate trains developers to ignore it. The lodash item needs a changelog skim, not benchmarking. No profiling is required to confirm any finding here; the load-bearing facts (gate exits 1, threshold semantics, dev-tree exclusion) are already execution-verified by the fact-check report.
