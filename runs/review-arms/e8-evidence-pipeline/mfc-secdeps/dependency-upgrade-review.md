# Dependency Upgrade Review — mfc-secdeps

**Commit:** 8bde50c
**Diff:** `git diff d86d2dc...HEAD` (`.github/workflows/ci.yml`, `eslint.config.mjs`, `package-lock.json`)
**Reviewer:** dependency-upgrade critic (consume-only mode — code-fact-check report at `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-secdeps/code-fact-check-report.md` is the sole source of execution results; claim IDs below refer to it)

This change bundles two things: (A) lockfile-only security bumps of two transitive production dependencies, and (B) a new CI gate `npm audit --omit=dev --audit-level=high`. They are evaluated separately below, then combined into one verdict.

---

## Dependency Upgrade Evaluation: lodash 4.17.23 → 4.18.1 (transitive, via dagre → graphlib)

### Summary
**Recommendation:** Upgrade now
**Breaking change impact:** None
**Estimated effort:** minutes (already done in lockfile; residual effort is fixing the commit message)
**Risk:** Low
**Audit state:** Consumed from code-fact-check report, claims 10a, 10b, 1 — advisory-DB state as of 2026-08-18T06:11–06:14Z; re-run the gate at merge if >24h old or lockfile changed.

### Motivation
Security. lodash `<=4.17.23` carried a high-severity advisory at the base lockfile (claim 10a, Verified, executed: base-lockfile audit shows `lodash <=4.17.23 / Severity: high`, evidence `r1-audit-base-lockfile.txt`; independently reproduced via a pinned scratch tree, `r2-audit-old-versions-probe.txt`). The bump clears it: the HEAD production audit lists no lodash finding (claim 10a, evidence `r1-audit-omit-dev-high.txt`, `r2-audit-omit-dev-high.txt`).

### Breaking Changes That Affect This Project
No breaking changes affect this project's usage. 4.17.23 → 4.18.1 is a **minor** bump under semver — additive API surface, no removals expected on the 4.x line. The project does not import lodash directly (`package.json:14-33` dependencies block contains no lodash entry; it enters only as a transitive of `dagre`/`graphlib`, per claim 10a), so any additive API changes are invisible to first-party code — only graphlib's existing call sites matter, and semver-minor guarantees those keep working.

### Breaking Changes That Don't Affect This Project
- None identified. No changelog for 4.18.x is bundled in `node_modules/lodash` (only README/LICENSE present), so the "no API changes" half of the commit message could not be checked against release notes; it is judged via semver classification only (matching claim 10c's scope note).

### Transitive Effects
- None identified. Lockfile-only version move within the existing `^`-compatible range; no peer-dependency or runtime-requirement changes surfaced in the diff.

### Risk Factors
- **Commit-message inaccuracy (fix before merge):** commit 1efb6db says "only patch upgrades, no API changes" — **Incorrect** (claim 10c, both replicates, High confidence). lodash 4.17.23 → 4.18.1 is a minor bump. A reader operating a patch-only fast-track policy would be misled. Amend the message or note it in the PR description.
- Otherwise low risk — transitive-only, semver-minor, security-motivated.

---

## Dependency Upgrade Evaluation: @xmldom/xmldom 0.8.11 → 0.8.13 (transitive, via mammoth)

### Summary
**Recommendation:** Upgrade now
**Breaking change impact:** None (one theoretical behavioral edge, see below)
**Estimated effort:** minutes (already done in lockfile)
**Risk:** Low
**Audit state:** Consumed from code-fact-check report, claims 10a, 10b, 1 — advisory-DB state as of 2026-08-18T06:11–06:14Z; re-run the gate at merge if >24h old or lockfile changed.

### Motivation
Security. `@xmldom/xmldom <=0.8.12` carried a high-severity advisory at the base lockfile (claim 10a, Verified, executed — `r1-audit-base-lockfile.txt` shows `@xmldom/xmldom <=0.8.12 / Severity: high`); the 0.8.13 bump clears it (HEAD audit lists no xmldom finding, claim 10a). The bundled changelog (`node_modules/@xmldom/xmldom/CHANGELOG.md`, read statically) confirms 0.8.12 and 0.8.13 are security-fix patch releases: CDATA `]]>` injection hardening (GHSA-wh4c-j3r5-mjhp) and serializer/traversal fixes (GHSA-j759-j44w-7fr8, GHSA-x6wf-f3px-wcqx, GHSA-f6ww-3ggp-fr8h, GHSA-2v35-w6hq-6mfw).

### Breaking Changes That Affect This Project
No breaking changes affect this project's usage. The new `requireWellFormed` serializer option (0.8.13) is opt-in — default behavior unchanged. The project uses xmldom only through `mammoth` (.docx parsing in `FileUpload`), not directly (`package.json:14-33` has no xmldom entry; transitive edge per claim 10a).

### Breaking Changes That Don't Affect This Project
- **0.8.12: `createCDATASection` now throws `InvalidCharacterError` when data contains `"]]>"`** (changelog, spec-mandated). This only bites code that *creates* CDATA sections with attacker-ish data. Mammoth's use is parsing/reading .docx XML; first-party code never touches xmldom APIs. Checked and dismissed — though "mammoth never calls `createCDATASection` with `]]>` data" was not executed as a test; see Unverified row in Execution Evidence.
- **0.8.13: recursion → iteration in traversal** — behavior-preserving except that deeply nested documents no longer throw `RangeError`; strictly an improvement for .docx parsing robustness.

### Transitive Effects
- None identified. Patch bump inside mammoth's existing range; lockfile-only.

### Risk Factors
- Low risk — patch-level, security-only, upstream-spec-aligned. The one behavioral change (CDATA throw) sits on an API path this project does not exercise directly.

---

## The new CI gate: `npm audit --omit=dev --audit-level=high` (ci.yml:45-46)

Not a dependency bump, but it is the merge-blocking half of this diff, so it drives the verdict.

**Design: sound.** Both flag rationales in the ci.yml comments are Verified by execution (claim 1: `--omit=dev` demonstrably excludes devDependency trees — 6 findings vs 11 unrestricted; claim 2: `--audit-level=high` gates the exit code by severity while still printing lower-severity findings). The commit message accurately describes the step (claim 9, Verified). Scoping the gate to production deps at high+ severity is exactly the right noise/signal tradeoff for a CI gate.

**State: the gate fails at HEAD.** Claim 10b ("this branch lands green") is **Stale** (both replicates): `npm audit --omit=dev --audit-level=high` exits 1 at HEAD with **5 high-severity production findings in nanoid, next, pdfjs-dist, postcss, sharp** — none of them the packages this branch bumped — per the npm advisory DB as of 2026-08-18T06:11Z (evidence `r1-audit-omit-dev-high.txt`: `6 vulnerabilities (1 moderate, 5 high)`, `exit=1`; corroborated `r2-audit-omit-dev-high.txt`). The claim was plausibly true at commit time (2026-04-27); advisories published since (several 2026 CVEs, e.g. the sharp finding citing CVE-2026-33327/-33328/-35590/-35591) make the branch red under its own gate. This is precisely the time-varying-input hazard the skill's staleness rule exists for — and here it flips the merge outcome: **merging as-is turns main's CI red on the very first run.**

**Practical implication:** before merge, either (a) extend this branch (or land an immediate follow-up) resolving the 5 high production advisories — likely `npm audit fix` plus a Next.js/sharp/pdfjs-dist version review, which may not all be trivial (next is pinned at 16.2.4) — or (b) decide explicitly that a red gate on day one is acceptable pressure and merge with eyes open. Option (a) is strongly preferred; a gate that is born red trains everyone to ignore it.

Adjacent finding worth relaying (outside dep remit, from the fact-check): the "fail loudly" guardrail claim is **Incorrect** for the `react/no-danger` leg — it is warn-level and eslint exits 0 on warnings with no `--max-warnings 0` (claim 4b), and the `trust: true` selector misses string-literal-keyed `{ "trust": true }` (claim 6, Mostly accurate). Promote `react/no-danger` to `"error"` or add `--max-warnings 0` to the lint script.

---

## Execution Evidence

| Command | Exit | As-of | Evidence |
|---------|------|-------|----------|
| `npm audit --omit=dev --audit-level=high` (HEAD) | 1 | r1 2026-08-18T06:11:47Z, r2 06:12:18Z; npm advisory DB at that time | Claims 1, 10b; `evidence/r1-audit-omit-dev-high.txt`, `evidence/r2-audit-omit-dev-high.txt` |
| `npm audit` (HEAD, unrestricted) | 1 | r1 2026-08-18T06:12:15Z; same DB state | Claim 1; `evidence/r1-audit-full.txt` (r2 variant `r2-audit-full-high.txt`) |
| `npm audit --omit=dev --audit-level=critical` (HEAD) | 0 | r1 06:12:15Z, r2 06:12:47Z | Claim 2; `evidence/r1-audit-omit-dev-critical.txt`, `evidence/r2-audit-omit-dev-critical.txt` |
| `npm audit --omit=dev --audit-level=high` (base d86d2dc lockfile, temp dir) | 1 | 2026-08-18T06:12:16Z | Claim 10a; `evidence/r1-audit-base-lockfile.txt` |
| Scratch-tree audit pinning `lodash@4.17.23` + `@xmldom/xmldom@0.8.11` | 1 | 2026-08-18T06:13:47Z | Claim 10a; `evidence/r2-audit-old-versions-probe.txt` |
| `npm run lint` (repo-wide) | 0 | r1 06:12:58Z, r2 06:13:12Z | Claims 3, 8; `evidence/r1-npm-run-lint.txt`, `evidence/r2-npm-run-lint.txt` |
| `npx eslint <fixture>` (guardrail-fire checks) | 1 | r1 06:12:36Z, r2 06:13:08Z | Claims 4a, 6, 11; `evidence/r1-eslint-fixture.txt`, `evidence/r2-eslint-fixture.txt` |
| `npx eslint <danger-only fixture>` | 0 | 2026-08-18T06:12:47Z | Claim 4b; `evidence/r1-eslint-danger-only.txt` |
| Test suite against bumped lockfile (`npm test`) — exercises mammoth/dagre paths on new transitive versions | — | — | Unverified — recommended pre-merge check |
| Grep confirming no first-party direct imports of `lodash` / `@xmldom/xmldom` | — | — | Unverified — recommended pre-merge check (package.json:14-33 shows neither as a direct dependency, read statically; a call-site grep was not in the fact-check scope) |
| Rollback rehearsal verification | — | — | Unverified — rehearsal not performed; see Rollback Plan |

No cell above is filled from memory: every filled row cites a fact-check claim ID and its evidence file; everything else is marked Unverified.

## Rollback Plan (precondition — complete before merge)

**Exact rollback commands:**
```
git checkout d86d2dc -- package-lock.json
npm ci
# if reverting the gate too:
git checkout d86d2dc -- .github/workflows/ci.yml eslint.config.mjs
```

**Verification step:** `npm test` (Vitest; exercises the mammoth .docx-parsing and dagre graph paths that consume the reverted transitives) plus `npm run lint` — both would fail if the lockfile or config revert left the tree inconsistent.

**Rehearsal status:** [ ] Not rehearsed. This is an execution claim and no provenance exists — rehearse on a scratch branch and capture the verification output before starting any merge-day remediation of the 5 open advisories.

## Migration Plan

1. Keep the two lockfile bumps as-is (both Verified effective — claim 10a).
2. Amend/annotate the 1efb6db commit message or PR description: lodash is a **minor** bump, not patch (claim 10c).
3. Resolve the 5 high production advisories the gate currently trips on (nanoid, next, pdfjs-dist, postcss, sharp — claim 10b): run `npm audit fix`, review any remaining ones individually (next 16.2.4 is exact-pinned and may need a deliberate version decision).
4. Promote `react/no-danger` to `"error"` (or add `--max-warnings 0` to the lint script) so the "fail loudly" comment becomes true (claim 4b).
5. Re-run `npm audit --omit=dev --audit-level=high` at merge time — the consumed audit state is a snapshot of the advisory DB at 2026-08-18T06:11–06:14Z; re-run if >24h old or the lockfile changes.
6. Rehearse the rollback (above) once, on a scratch branch, before step 3's remediation lands.

## Verdict

**No-go as-is; go once the gate is green.** The two security bumps are correct and low-risk (upgrade now), and the audit-gate design is sound — but the branch fails its own new CI gate at HEAD (claim 10b: exit 1, 5 high production advisories post-dating the commit, as of advisory DB 2026-08-18T06:11Z), so merging today paints main red immediately; remediate the open advisories (or explicitly accept a red gate) and fix the "only patch upgrades" commit-message inaccuracy (claim 10c) first.
