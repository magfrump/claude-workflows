# Code Fact-Check Report

**Repository:** /workspace/external/cc-review-eval/mfc-secdeps
**Commit:** 8bde50c
**Scope:** Submitted endorsement claims only (Stage 2.5) — 2 routed by security-reviewer, 1 by performance-reviewer, drawn from the diff files `.github/workflows/ci.yml`, `package-lock.json`. api-consistency-review.md and dependency-upgrade-review.md contained no `route: code-fact-check` / `[unverified — submitted as claim]` entries.
**Checked:** 2026-08-18
**Total claims checked:** 3
**Summary:** 3 verified, 0 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Numbering continues from the canonical merged report (`code-fact-check-report.md`, Claims 1–12). New evidence captures carry the `sc-` prefix in `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-secdeps/evidence/`; existing `r1-`/`r2-` captures from the merged report are cited where they already carry an executed verdict for the same subject (no re-runs). Audit-based citations consult the npm registry advisory database, a time-varying input, true as of 2026-08-18T06:11–06:14Z per the merged report.

---

## Submitted Claims

## Claim 13: "The audit gate passes `--omit=dev`, so advisories confined to devDependency trees do not contribute to the gate's exit code."

**Submitted by:** security-reviewer
**Location:** `.github/workflows/ci.yml:41,45-46`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--omit=dev` excluding devDependency trees from the audit report (and therefore from the exit-code determination) as demonstrated against the current advisory DB; does not establish that every audited production dep ships to users, nor the gate's behavior under a hypothetical dev-only-findings tree (no such tree state was constructed).

The gate command is:

```yaml
# .github/workflows/ci.yml:45-46
- name: Audit production dependencies
  run: npm audit --omit=dev --audit-level=high
```

This is already executed-verdicted by merged-report Claim 1 (Verified, executed, k=2). The `--omit=dev` run reported (cmd `npm audit --omit=dev --audit-level=high`, cwd `/workspace/external/cc-review-eval/mfc-secdeps`, exit 1; r1 2026-08-18T06:11:47Z, r2 2026-08-18T06:12:18Z):

```
// evidence/r1-audit-omit-dev-high.txt:74
6 vulnerabilities (1 moderate, 5 high)
```

versus 11 in the unrestricted run (`// evidence/r1-audit-full.txt` — `11 vulnerabilities (1 low, 1 moderate, 9 high)`, cmd `npm audit`, same cwd, exit 1, 2026-08-18T06:12:15Z). The five findings present only in the unrestricted run sit in devDependency trees (`@babel/core`, `brace-expansion` under `eslint-config-next`, `picomatch` under `vitest`, `undici`/`vite`) (paraphrased — no quote available because the comparison spans ~10 advisory blocks across two captured logs; see `r1-audit-full.txt` vs `r1-audit-omit-dev-high.txt`, corroborated by the `r2-` pair). Because `npm audit` derives its exit code from the findings it reports, advisories excluded from the `--omit=dev` report cannot contribute to the gate's exit code — the mechanism the claim asserts.

**Evidence:** `.github/workflows/ci.yml:41,45-46`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-secdeps/evidence/r1-audit-omit-dev-high.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-secdeps/evidence/r1-audit-full.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-secdeps/evidence/r2-audit-omit-dev-high.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-secdeps/evidence/r2-audit-full-high.txt`, merged report `code-fact-check-report.md` Claim 1

---

## Claim 14: "The two bumped pins (`@xmldom/xmldom` 0.8.11→0.8.13, `lodash` 4.17.23→4.18.1) move both packages off versions that carried high-severity advisories, and neither appears in the HEAD `--omit=dev` audit."

**Submitted by:** security-reviewer
**Location:** `package-lock.json:3857-3862,7336-7342`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exact version transitions in the lockfile diff and both packages' advisory status (high at old pins, absent from the HEAD `--omit=dev` audit) as of the advisory DB at 2026-08-18; does not establish API compatibility of the lodash minor bump (explicitly excluded by the submitting critic's own Not-verified line) or re-derive the integrity hashes.

The version transitions match the claim exactly — the captured lockfile diff (`sc-lockfile-diff.txt`, cmd `git diff d86d2dc...HEAD -- package-lock.json`, cwd `/workspace/external/cc-review-eval/mfc-secdeps`, exit 0, 2026-08-18T06:25:53Z) shows:

```
// evidence/sc-lockfile-diff.txt (package-lock.json:3857-3862)
-      "version": "0.8.11",
+      "version": "0.8.13",
```

```
// evidence/sc-lockfile-diff.txt (package-lock.json:7336-7342)
-      "version": "4.17.23",
+      "version": "4.18.1",
```

The advisory half is already executed-verdicted by merged-report Claim 10a (Verified, executed, k=2): auditing the base lockfile showed both packages high-severity at the old pins (`// evidence/r1-audit-base-lockfile.txt` — `@xmldom/xmldom  <=0.8.12 / Severity: high` and `lodash  <=4.17.23 / Severity: high`; cmd `npm audit --omit=dev --audit-level=high` against the base lockfile in a temp dir, exit 1, 2026-08-18T06:12:16Z), independently corroborated by r2's scratch-tree probe pinning the old versions (`r2-audit-old-versions-probe.txt`, `2 high severity vulnerabilities`, exit 1, 2026-08-18T06:13:47Z). Neither package appears among the six findings of the HEAD `--omit=dev` audit (paraphrased — no quote available because absence from a report cannot be quoted; the six flagged packages are `@anthropic-ai/sdk`, `nanoid`, `next`, `pdfjs-dist`, `postcss`, `sharp` per `r1-audit-omit-dev-high.txt` and `r2-audit-omit-dev-high.txt`).

**Evidence:** `package-lock.json:3857-3862`, `package-lock.json:7336-7342`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-secdeps/evidence/sc-lockfile-diff.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-secdeps/evidence/r1-audit-base-lockfile.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-secdeps/evidence/r2-audit-old-versions-probe.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-secdeps/evidence/r1-audit-omit-dev-high.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-secdeps/evidence/r2-audit-omit-dev-high.txt`, merged report `code-fact-check-report.md` Claim 10a

---

## Claim 15: "The lockfile diff touches only the version/resolved/integrity fields of two already-installed transitive packages, so `npm ci` in CI resolves and installs the same package count and its duration is materially unchanged by this diff."

**Submitted by:** performance-reviewer
**Location:** `package-lock.json:3857-3862,7336-7342` (CI install step: `.github/workflows/ci.yml:26-27`)
**Type:** Performance / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the lockfile-diff shape, package-count equality (753 lockfile entries / 659 installed packages on both sides), and comparative `npm ci --ignore-scripts` wall-clock in this sandbox; does not reproduce GitHub Actions runner conditions (network, `cache: npm` restore, lifecycle scripts such as sharp's install hook — which run identically on both sides since the package set is identical) and does not measure absolute CI duration.

All three parts hold. First, the diff shape: the full lockfile diff is exactly two `version`/`resolved`/`integrity` triples (14 changed lines total — `evidence/sc-lockfile-diff.txt`, quoted under Claim 14; cmd `git diff d86d2dc...HEAD -- package-lock.json`, exit 0, 2026-08-18T06:25:53Z). Both packages are transitive — neither appears in `package.json` (paraphrased — no quote available because absence from the manifest cannot be quoted; `rg '"lodash"|"@xmldom/xmldom"' package.json` returns no hits, and merged-report Claim 10a traces them via dagre/graphlib and mammoth) — and both exist in the base lockfile, i.e. were already installed.

Second, package-count equality, verified programmatically (`sc-lockfile-package-counts.txt`, cmd: node key-count comparison of the `packages` maps, cwd `/workspace/external/cc-review-eval/mfc-secdeps`, exit 0, 2026-08-18T06:26:20Z):

```
// evidence/sc-lockfile-package-counts.txt
base package entries: 753
head package entries: 753
keys only in head: []
keys only in base: []
entries with differing content: ["node_modules/@xmldom/xmldom","node_modules/lodash"]
```

Third, the duration probe: `npm ci --ignore-scripts --no-audit --no-fund` was timed in scratch dirs holding the same `package.json` with the HEAD vs base lockfile, two rounds each with a shared npm cache (`sc-npm-ci-timing.txt`, cwd `/tmp/claude-1000/sc-probe/{head,base}` — scratch, deleted after; node v20.20.2 / npm 10.8.2; runs 2026-08-18T06:26:44Z–06:27:19Z; all four exits 0):

```
// evidence/sc-npm-ci-timing.txt
--- head run 1 ... exit=0 duration_s=6.7 installed=added 659 packages in 7s
--- base run 1 ... exit=0 duration_s=9.5 installed=added 659 packages in 9s
--- head run 2 ... exit=0 duration_s=10.4 installed=added 659 packages in 10s
--- base run 2 ... exit=0 duration_s=6.9 installed=added 659 packages in 7s
```

Both sides install exactly 659 packages ("same package count"), and the duration spread (6.7–10.4 s) is dominated by run-to-run noise, not lockfile side — the HEAD lockfile produced both the fastest and the slowest run. No systematic duration difference is attributable to the diff, supporting "materially unchanged."

**Evidence:** `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-secdeps/evidence/sc-lockfile-diff.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-secdeps/evidence/sc-lockfile-package-counts.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-secdeps/evidence/sc-npm-ci-timing.txt`, `package-lock.json:3857-3862`, `package-lock.json:7336-7342`, `.github/workflows/ci.yml:26-27`

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- None.

### Mostly Accurate
- None.

### Unverifiable
- None.

All three submitted endorsement claims verdicted Verified with executed verification mode; each is admissible backing for a Confirmed-Good row per Stage 2.5 rule 5.
