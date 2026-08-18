# Code Review Rubric

**Commit:** 8bde50c
**Scope:** `d86d2dc..8bde50c` (`.github/workflows/ci.yml`, `eslint.config.mjs`, `package-lock.json`; commits 1efb6db, 8bde50c) | **Reviewed:** 2026-08-18 | **Status: 🔴 DOES NOT PASS** — 2 red item(s) unresolved

**Inputs:** merged code-fact-check report (k=2, 15 claims: 11 Verified, 1 Mostly Accurate, 1 Stale, 2 Incorrect — Fact-Check Gate applies, 2 Incorrect at High confidence), Stage-2.5 submitted-claims report (3 claims, all Verified/executed), security-review, performance-review, api-consistency-review, dependency-upgrade-review (contextual, advisory).

---

## 🔴 Must Fix

Issues that must be resolved before merge. Draft cannot pass review with any red items unresolved.

| # | Finding | Domain | Severity | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|
| R1 | `react/no-danger` is warn-level and the lint script has no `--max-warnings 0`, so a future change reintroducing `dangerouslySetInnerHTML` (a direct XSS sink on the LLM-output rendering path) passes lint and CI — while the shared comment (`eslint.config.mjs:29-32`) and commit message promise all three guardrails "fail loudly". Executed proof: danger-only fixture → 1 warning, exit 0 (`evidence/r1-eslint-danger-only.txt`). The comment documents a security contract future changes would bind to and be misled by → behavioral 🔴 per decision 031. Security additionally proved the sink is reachable invisibly via `React.createElement("div", {dangerouslySetInnerHTML})` (no finding even at warn level — rule inspects JSX attributes only) and raw `.innerHTML =` assignment (no rule at all) (`evidence/sec-bypass-danger.txt`, exit 0). Fix: promote to `"error"` and/or add `--max-warnings 0`; optionally add selectors for the createElement/innerHTML forms; at minimum correct the comment. Convergence: fact-check (Claim 4b, Incorrect High, executed) + security (#3) + api-consistency (#1); relayed by dependency-upgrade. | Security / API Consistency / Fact-Check | Incorrect–High (FC) · Medium–High conf (Sec) · Inconsistent–High conf (API) | `eslint.config.mjs:57-58`; `package.json:9`; `.github/workflows/ci.yml:26-27` | for-author | — | 🔴 Unresolved |
| R2 | The new audit gate `npm audit --omit=dev --audit-level=high` **fails at HEAD**: exit 1 with 5 high-severity production advisories (nanoid, next, pdfjs-dist, postcss, sharp — none touched by this branch), published after the 2026-04-27 commit; the commit-message claim "this branch lands green" is Stale. Merging as-is turns main's CI red on the first run, and the gate design has no allowlist/exception path, so every fresh high CVE freezes all branches — the exact failure mode the step comment claims the threshold was chosen to avoid (it only filters low/moderate). Fix: clear the 5 advisories (or explicitly accept a born-red gate on the record) and decide/document the unblock path (allowlist file, scheduled non-blocking job, or documented bump-or-allowlist procedure). Base tier 🟡 (FC Stale / Perf Medium / API Inconsistent), **escalated 🟡→🔴 per the Escalation Rule**: 2+ core critics converge (performance #2 + api-consistency #2 + security #4) with executed corroboration — gate exit 1 at HEAD captured by both replicates (`evidence/r1-audit-omit-dev-high.txt`, `evidence/r2-audit-omit-dev-high.txt`, as of advisory DB 2026-08-18T06:11Z). Dependency-upgrade (advisory, non-counting) independently verdicts "no-go as-is; go once the gate is green". | Performance / API Consistency / Security / Fact-Check | Stale–Medium conf (FC) · Medium–High conf (Perf) · Inconsistent–High conf (API) · Low–High conf (Sec) | `.github/workflows/ci.yml:41-46`; commit 1efb6db message | for-author | — | 🔴 Unresolved |

---

## 🟡 Must Address

Issues that must be fixed or acknowledged by the author with justification for why they stand. Each must carry a resolution or author note.

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | `no-restricted-imports` guardrail matches only the exact static specifier `"rehype-raw"`: dynamic `await import("rehype-raw")`, `require("rehype-raw")`, and subpath `"rehype-raw/lib/index.js"` all linted clean (zero problems, exit 0 — `evidence/sec-bypass-imports.txt`), each re-enabling the raw-HTML-in-markdown XSS vector the comment claims is guarded. Add `patterns` (`rehype-raw`, `rehype-raw/**`) plus selectors for `import()`/`require()` call forms, or gate at the dependency level; soften the comment to state residual gaps. | Security | Medium (conf: Medium) | security-reviewer #1 | for-author | — | 🟡 Open | — |
| A2 | The `trust: true` selector `Property[key.name='trust'][value.value=true]` catches only an identifier-keyed boolean literal. Tested evasions: `{ "trust": true }` (string key — no `key.name`; demonstrated independently by FC r2 fixture and security fixture), `{ trust: () => true }` (KaTeX's own documented, fully functional callback form — the sharpest miss), `{ trust: 1 }`, computed keys, and post-construction `obj.trust = true` (`evidence/sec-bypass-trust.txt`). The comment's "broad enough to catch `{ trust: true }` elsewhere too" holds only for the identifier-keyed literal. Widen the selector set (e.g. `Property[value.value=true]:matches([key.name='trust'], [key.value='trust'])`, assignment/callback selectors) or qualify the comment. Convergence: security #2 + fact-check (Claim 6, Mostly Accurate, executed) + api-consistency #4. Not escalated: the executed fixture evidence is what produced the Mostly-Accurate/Medium tier, not independent corroboration of a higher one — no live `trust:true` exists at HEAD. | Security / API Consistency / Fact-Check | Medium–Medium conf (Sec) · Mostly Accurate–High conf (FC) · Minor–High conf (API) | for-author | — | — | 🟡 Open | — |
| A3 | Audit step is ordered last in the CI pipeline but depends only on the installed tree — whenever the gate is red (which it is at HEAD, per R2), every CI run pays full install + lint + tsc + build before failing at the final step. Move it immediately after `npm ci` so advisory-DB failures fail in seconds. | Performance | Medium (conf: High) | performance-reviewer #1 | for-author | — | 🟡 Open | — |
| A4 | Commit 1efb6db's "only patch upgrades, no API changes" is wrong: lodash 4.17.23 → 4.18.1 is a semver **minor** bump (only @xmldom/xmldom 0.8.11 → 0.8.13 is a patch), and "no API changes" rests on the refuted patch mechanism. A reader operating a patch-only fast-track review policy would be misled. Doc-only Incorrect (code/bumps themselves are correct and clear real advisories) → 🟡 per decision 031; commit is on the unmerged branch, so the message is still amendable (immutable-history exception not applicable). Amend the message or correct the record in the PR description. Convergence: fact-check (Claim 10c, Incorrect High) + security #5 + api-consistency #3; dependency-upgrade flags "fix before merge" (advisory). Not escalated: the FC Incorrect verdict is the finding itself, already tier-scoped by 031, not independent corroboration. | Fact-Check / Security / API Consistency | Incorrect–High (FC, doc-only) · Low–High conf (Sec) · Minor–High conf (API) | for-author | — | — | 🟡 Open | — |

---

## 🟢 Consider

Advisory findings from contextual critics, single-critic suggestions, and improvement opportunities. Not required to pass review.

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | lodash 4.18.x entered the production tree (transitive via dagre/graphlib — graph-layout paths) under the refuted "patch-only" classification with runtime characteristics unassessed; no bundled changelog exists in `node_modules/lodash` to check. Skim the 4.18.0/4.18.1 release notes for algorithmic changes to functions graphlib calls. | performance-reviewer #3 + dependency-upgrade | Low (conf: Medium) | for-author | — | 🟢 Open |
| C2 | The three added lint rules cost one AST-selector match per node per lint run — Micro × Cold, rides the existing `npm run lint` invocation, executed repo-wide lint completed normally. Recorded for calibration auditability; no action needed. | performance-reviewer #4 | Informational (conf: High) | for-orchestrator-synthesis | — | 🟢 Open |
| C3 | The guardrail config object has no `files` key so it applies linter-wide, but `verifier/**` is globally ignored (`eslint.config.mjs:17`) — the "fail loudly" contract does not extend there (FC Claim 8's grep, not the lint run, covered that tree). Practical XSS exposure is low (server-side Node, no React rendering); add one comment line so the boundary is deliberate. | api-consistency-reviewer #5 | Informational (conf: Medium) | for-author | — | 🟢 Open |
| C4 | Pre-merge checks recommended by dependency-upgrade (advisory): (a) run `npm test` against the bumped lockfile to exercise the mammoth/.docx and dagre paths on the new transitive versions; (b) rehearse the documented rollback (`git checkout d86d2dc -- package-lock.json && npm ci`) once on a scratch branch — currently unrehearsed; (c) re-run `npm audit --omit=dev --audit-level=high` at merge time (consumed advisory-DB state is a 2026-08-18T06:11–06:14Z snapshot; stale if >24h old or lockfile changes). | dependency-upgrade | Advisory | for-author | — | 🟢 Open |

---

## ↩️ Considered Overrides

No prior overrides matched this diff. (No override log exists within this instance's blinded scope; none consulted.)

---

## ✅ Confirmed Good

Patterns, implementations, or claims confirmed correct by fact-check and/or critics. Every row carries `Evidence` backed by an executed-mode fact-check verdict or a static Verified verdict whose Scope covers the row (provenance rule 5), and passed the Confirmed-Good cross-check against both replicate reports.

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| The audit gate's `--omit=dev` excludes devDependency-tree advisories from the report and hence the exit code: 6 findings vs 11 unrestricted, delta all dev-tree packages (`@babel/core`, `brace-expansion`, `picomatch`, `undici`/`vite`). (Does not establish every production dep literally ships to users — `next`/`sharp` are build/server-side.) | ✅ Confirmed | `.github/workflows/ci.yml:41,45-46` — `run: npm audit --omit=dev --audit-level=high`; `evidence/r1-audit-omit-dev-high.txt` vs `r1-audit-full.txt` (+ r2 pair) — FC claim 1 (executed, k=2) + FC submitted claim 13 (executed) | Fact-check + security-reviewer endorsement (verified Stage 2.5) | for-orchestrator-synthesis |
| `--audit-level=high` gates the exit code by severity threshold as the comment claims: same tree exits 1 at `high`, exits 0 at `critical` while still printing the below-threshold advisories (informational, non-failing). | ✅ Confirmed | `.github/workflows/ci.yml:42-45`; `evidence/r1-audit-omit-dev-critical.txt` — `exit=0`; `r2-audit-omit-dev-critical.txt` — `6 vulnerabilities … exit: 0` — FC claim 2 (executed, k=2) | Fact-check; endorsed by performance-reviewer | for-orchestrator-synthesis |
| The two error-level guardrails (`no-restricted-imports` on the static `"rehype-raw"` specifier; `no-restricted-syntax` on identifier-keyed `{ trust: true }`) fire as errors and fail `eslint` (exit 1), which fails the CI Lint step — for exactly the forms the fixtures exercised. (Narrowed per FC scope lines: does not cover the bypass forms in A1/A2 or the `react/no-danger` leg, R1.) | ✅ Confirmed | `eslint.config.mjs:33-56`; `.github/workflows/ci.yml:26-27`; `package.json:9` — `"lint": "eslint"`; `evidence/r1-eslint-fixture.txt` (2 errors, exit=1) + `r2-eslint-fixture.txt` — FC claim 4a (executed, k=2) + FC claim 11 (executed, k=2) | Fact-check; endorsed by api-consistency-reviewer + performance-reviewer | for-orchestrator-synthesis |
| The two lockfile bumps (`@xmldom/xmldom` 0.8.11→0.8.13, `lodash` 4.17.23→4.18.1) move both packages off versions carrying high-severity advisories at the base lockfile, and neither appears in the HEAD `--omit=dev` audit — the commit message's named findings were real and are cleared. (As of advisory DB 2026-08-18; API compatibility of the lodash minor is explicitly not covered — see A4/C1.) | ✅ Confirmed | `package-lock.json:3857-3862,7336-7342` — `"version": "0.8.13"` / `"version": "4.18.1"`; `evidence/r1-audit-base-lockfile.txt` — `@xmldom/xmldom <=0.8.12 / Severity: high`, `lodash <=4.17.23 / Severity: high`; `r2-audit-old-versions-probe.txt` — FC claim 10a (executed, k=2) + FC submitted claim 14 (executed) | Fact-check + security-reviewer endorsement (verified Stage 2.5) | for-orchestrator-synthesis |
| The lockfile diff is exactly two version/resolved/integrity triples for already-installed transitives: identical package counts both sides (753 lockfile entries / 659 installed), and timed `npm ci` runs show no systematic duration difference attributable to the diff. (Sandbox measurement; does not reproduce GitHub Actions runner conditions.) | ✅ Confirmed | `evidence/sc-lockfile-diff.txt` (14 changed lines); `sc-lockfile-package-counts.txt` — `keys only in head: []`; `sc-npm-ci-timing.txt` — 659 packages both sides, 6.7–10.4 s spread dominated by noise — FC submitted claim 15 (executed) | performance-reviewer endorsement (verified Stage 2.5) | for-orchestrator-synthesis |
| The XSS surface is defensive in first-party source at HEAD: zero `dangerouslySetInnerHTML` usages (repo-wide lint with `react/no-danger` active → 0 findings; grep matches only the lint config's own comment), `rehype-raw` neither imported nor installed, and KaTeX `trust` is effectively false (by library default — `rehypePlugins = [rehypeKatex]` passes no options; not by explicit configuration). Enumeration-backed; covers HEAD state only — future-change protection is the guardrails' job (see R1/A1/A2). `verifier/**` covered by grep only, not lint (C3). | ✅ Confirmed | `evidence/r1-npm-run-lint.txt` (exit 0, only 2 unrelated `react-hooks/exhaustive-deps` warnings) + `r2-npm-run-lint.txt`; `app/components/features/output-editing/LatexRenderer.tsx:6-10` — `const rehypePlugins = [rehypeKatex];`; `node_modules/katex/dist/katex.mjs:349-350` — FC claim 3 (executed, k=2) + FC claim 8 (executed, k=2) | Fact-check | for-orchestrator-synthesis |
| Commit 8bde50c is exactly what it claims: a single trailing-newline hunk on ci.yml, no semantic CI change. | ✅ Confirmed | `git show 8bde50c` — sole hunk re-adds the final line with a newline — FC claim 12 (static Verified; Scope: "covers the content of commit 8bde50c's diff" — covers the row's full breadth) | Fact-check | for-orchestrator-synthesis |

Dropped candidates (provenance rule 5): the security-reviewer's third endorsement (diff confined to CI config/lint rules/lockfile fields, no credential or auth edit) is `read-static` and unrouted — not admissible backing for a ✅ row; it stands only as scoped prose in `security-review.md`. api-consistency's naming/convention "What Looks Good" items carry no fact-check verdict and are likewise not promoted.

---

## ⚠️ Unverified Findings

All findings' evidence resolved. (Every 🔴/🟡 row cites executed evidence captures under `evidence/` and/or fact-check verdicts with file:line quotes; per this run's synthesis-only mandate, grounding was checked against the artifacts' quoted evidence, not by re-reading the target repo.)

---

## ⏭️ Skipped Core Critics

All core critics ran; no skips applied. (security-reviewer, performance-reviewer, api-consistency-reviewer all reported; dependency-upgrade ran as the auto-selected contextual critic for the manifest/lockfile change.)

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or carry an author note. 🟢 items are optional.
