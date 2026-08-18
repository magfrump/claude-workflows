# Code Fact-Check Report

**Commit:** 8bde50c
**Repository:** /workspace/external/cc-review-eval/mfc-secdeps
**Scope:** Files changed in `git diff d86d2dc...HEAD` (`.github/workflows/ci.yml`, `eslint.config.mjs`, `package-lock.json`) plus the commit messages of the range (1efb6db, 8bde50c)
**Checked:** 2026-08-18 (UTC)
**Total claims checked:** 14
**Summary:** 10 verified, 2 mostly accurate, 1 stale, 1 incorrect, 0 unverifiable

Evidence log directory: `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-secdeps/evidence/` (files prefixed `r2-`). Executed verdicts consulting the npm advisory database are true as of the audit DB at 2026-08-18T06:12–06:14Z.

---

## Claim 1: "--omit=dev: only audit production deps (the ones that ship to users)."

**Location:** `.github/workflows/ci.yml:40`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the vulnerability set npm audit reports with vs. without `--omit=dev` in this repo's install tree; does not establish that every production dependency literally ships in the client bundle (some are server-side only).

Running the audit with and without the flag produces different vulnerability sets. With `--omit=dev`:

```
// r2-audit-omit-dev-high.txt (exit 1)
6 vulnerabilities (1 moderate, 5 high)
```

Without `--omit=dev` (dev deps included):

```
// r2-audit-full-high.txt (exit 1)
11 vulnerabilities (1 low, 1 moderate, 9 high)
```

The five extra findings in the full run come from devDependency trees and are excluded by the flag (paraphrased — no quote available because the comparison spans the two multi-page captured audit outputs; the per-package listings are in the evidence files).

Executions: `npm audit --omit=dev --audit-level=high`, cwd `/workspace/external/cc-review-eval/mfc-secdeps`, exit 1, 2026-08-18T06:12:18Z; `npm audit --audit-level=high`, same cwd, exit 1, 2026-08-18T06:12:52Z.

**Evidence:** `.github/workflows/ci.yml:40-43`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-secdeps/evidence/r2-audit-omit-dev-high.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-secdeps/evidence/r2-audit-full-high.txt`

---

## Claim 2: "--audit-level=high: fail only on high+ severity. Lower levels are informational and would otherwise make every fresh CVE break CI on branches that have nothing to do with security."

**Location:** `.github/workflows/ci.yml:41-43`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exit-code semantics of `--audit-level` (threshold controls failure, below-threshold findings still print); does not establish the current gate passes — it does not (see Claim 10).

The threshold semantics were tested directly by raising the level to `critical` against the same tree, which reports the same findings but exits 0:

```
// r2-audit-omit-dev-critical.txt (exit 0)
6 vulnerabilities (1 moderate, 5 high)
exit: 0
```

At `--audit-level=high` the identical finding set exits 1 (`r2-audit-omit-dev-high.txt`: `exit: 1`). So below-threshold vulnerabilities are indeed reported informationally without failing the command, and at-or-above-threshold ones fail it — exactly the claimed mechanism.

Executions: `npm audit --omit=dev --audit-level=critical`, cwd `/workspace/external/cc-review-eval/mfc-secdeps`, exit 0, 2026-08-18T06:12:47Z; `npm audit --omit=dev --audit-level=high`, same cwd, exit 1, 2026-08-18T06:12:18Z.

**Evidence:** `.github/workflows/ci.yml:41-43`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-secdeps/evidence/r2-audit-omit-dev-critical.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-secdeps/evidence/r2-audit-omit-dev-high.txt`

---

## Claim 3: "The XSS surface is already defensive (no dangerouslySetInnerHTML, no rehype-raw, KaTeX trust:false)."

**Location:** `eslint.config.mjs:29-30`
**Type:** Architectural / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers presence/absence of the three named mechanisms in app code and dependencies; does not establish the app has no other XSS vectors.

All three atoms hold, so the compound claim is not split. (1) `dangerouslySetInnerHTML` has zero occurrences in the repo outside the lint rule itself (paraphrased — no quote available because the claim covers absence of code: `rg -l dangerouslySetInnerHTML` excluding `node_modules` and `eslint.config.mjs` returns no hits). (2) `rehype-raw` is not a dependency in `package.json` and `node_modules/rehype-raw` does not exist (paraphrased — no quote available because the claim covers absence of code/packages; verified by dependency-list read and directory listing). (3) KaTeX runs untrusted: the only rehype-katex usage passes no options —

```tsx
// app/components/features/output-editing/LatexRenderer.tsx:10
const rehypePlugins = [rehypeKatex];
```

— and KaTeX's `trust` setting defaults to falsy, with the gate coercing it to `false`:

```js
// node_modules/katex/dist/katex.mjs:349-350
var trust = typeof this.trust === "function" ? this.trust(context) : this.trust;
return Boolean(trust);
```

Precisely: `trust: false` is the effective default, not an explicit configuration anywhere in the repo — but a reader acting on the comment (KaTeX renders untrusted) is not misled.

**Evidence:** `eslint.config.mjs:29-30`, `app/components/features/output-editing/LatexRenderer.tsx:1-42`, `package.json:12-34`, `node_modules/katex/dist/katex.mjs:263-275`, `node_modules/katex/dist/katex.mjs:341-350`

---

## Claim 4a: "These rules are guardrails that … [fire] if a future change tries to weaken any of those" (the three rules fire on violations)

**Location:** `eslint.config.mjs:31-32`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that each of the three rules reports on a violating fixture under the repo's lint config; does not establish that every syntactic variant of a violation is caught (see Claim 6).

A scratch fixture (`app/__cfc_r2_fixture__.tsx`, deleted after the run) containing a `rehype-raw` import, a `{ trust: true }` literal, and a `dangerouslySetInnerHTML` usage triggered all three rules:

```
// r2-eslint-fixture.txt (exit 1)
2:1   error    'rehype-raw' import is restricted from being used. ...  no-restricted-imports
4:23  error    trust: true on KaTeX/rehype-katex (or anywhere similar) ...  no-restricted-syntax
8:15  warning  Dangerous property 'dangerouslySetInnerHTML' found  react/no-danger
```

Execution: `npx eslint app/__cfc_r2_fixture__.tsx`, cwd `/workspace/external/cc-review-eval/mfc-secdeps`, exit 1, 2026-08-18T06:13:08Z (fixture contents captured at the top of the evidence file).

**Evidence:** `eslint.config.mjs:33-59`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-secdeps/evidence/r2-eslint-fixture.txt`

---

## Claim 4b: "…guardrails that fail loudly if a future change tries to weaken any of those"

**Location:** `eslint.config.mjs:31-32`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether each rule's violation fails the `npm run lint` gate; does not establish CI-workflow-level handling beyond eslint's exit code.

Two of the three guardrails fail the lint; the third only warns. `no-restricted-imports` and `no-restricted-syntax` are `"error"` level and drove the fixture run's exit 1 (quoted in Claim 4a). But the dangerouslySetInnerHTML guardrail is:

```js
// eslint.config.mjs:58
"react/no-danger": "warn",
```

and eslint exits 0 on warnings alone — the full repo lint exited 0 while emitting warnings:

```
// r2-npm-run-lint.txt
✖ 2 problems (0 errors, 2 warnings)
exit: 0
```

So a future `dangerouslySetInnerHTML` introduction would print a warning but would NOT fail `npm run lint` or the CI lint step — "fail loudly" holds for two of the three protected surfaces; the precise version would say the third guardrail is advisory only.

Executions: `npx eslint app/__cfc_r2_fixture__.tsx`, exit 1, 2026-08-18T06:13:08Z; `npm run lint`, cwd `/workspace/external/cc-review-eval/mfc-secdeps`, exit 0, 2026-08-18T06:13:12Z.

**Evidence:** `eslint.config.mjs:31-58`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-secdeps/evidence/r2-eslint-fixture.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-secdeps/evidence/r2-npm-run-lint.txt`

---

## Claim 5: "rehype-raw lets raw HTML in markdown render as live DOM, which defeats sanitization on LLM output."

**Location:** `eslint.config.mjs:41`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the documented purpose of rehype-raw within the react-markdown pipeline this repo uses; does not establish runtime rendering behavior, since the package is not installed and was not executed.

react-markdown (the renderer used in `LatexRenderer.tsx`) documents rehype-raw as exactly the plugin that turns raw HTML in markdown into rendered output:

```md
// node_modules/react-markdown/readme.md:655-670
[`rehype-raw`][github-rehype-raw]:
...
import rehypeRaw from 'rehype-raw'
...
  <Markdown rehypePlugins={[rehypeRaw]}>{markdown}</Markdown>
```

The readme's surrounding section presents this as the way to enable HTML-in-markdown support, which react-markdown otherwise does not render (paraphrased — no quote available because the safety discussion spans several readme sections; see also `node_modules/rehype-katex/readme.md:215-220` on trusting content). Confidence is Medium because the package itself is absent from the tree, so the claim rests on the consuming library's documentation rather than executed behavior.

**Evidence:** `eslint.config.mjs:35-44`, `node_modules/react-markdown/readme.md:655-670`, `app/components/features/output-editing/LatexRenderer.tsx:3-10`

---

## Claim 6: "Catches `trust: true` on object literals — most common in rehype-katex's options … Broad enough to catch `{ trust: true }` elsewhere too; that's intended."

**Location:** `eslint.config.mjs:46-49`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the AST selector matches and one demonstrated miss (string-literal keys); does not enumerate all evadable forms (computed keys, `trust: someVar`, spread objects were not tested).

The selector is:

```js
// eslint.config.mjs:53
selector: "Property[key.name='trust'][value.value=true]",
```

The fixture confirmed it catches the identifier-keyed form `{ trust: true }` anywhere, not just in rehype-katex options (error at `4:23` in `r2-eslint-fixture.txt`, quoted in Claim 4a). However, the fixture's line 5, `export const optsStringKey = { "trust": true };`, produced no report — the eslint output lists findings only at 2:1, 4:23, and 8:15:

```
// r2-eslint-fixture.txt (exit 1)
✖ 3 problems (2 errors, 1 warning)
```

A string-literal key has no `key.name` in the AST, so `{ "trust": true }` — equally an object-literal `trust: true` — evades the rule. The mechanism and intent are right; the precise version would say "catches identifier-keyed `trust: true`; quoted-key and computed-key forms are not caught."

Execution: `npx eslint app/__cfc_r2_fixture__.tsx`, cwd `/workspace/external/cc-review-eval/mfc-secdeps`, exit 1, 2026-08-18T06:13:08Z.

**Evidence:** `eslint.config.mjs:50-56`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-secdeps/evidence/r2-eslint-fixture.txt`

---

## Claim 7: "trust: true on KaTeX/rehype-katex (or anywhere similar) re-enables active links and raw HTML in math output."

**Location:** `eslint.config.mjs:54` (same mechanism asserted at `eslint.config.mjs:47-48`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers KaTeX's documented/implemented gating of HTML-producing commands behind the `trust` setting; does not establish the behavior by rendering actual math with `trust: true`.

KaTeX's own option schema describes `trust` this way:

```js
// node_modules/katex/dist/katex.mjs:208-209
type: ["boolean", "function"],
description: "Trust the input, enabling all HTML features such as \\url.",
```

and the parser consults it before emitting trusted output:

```js
// node_modules/katex/dist/katex.mjs:11227
if (!parser.settings.isTrusted(trustContext)) {
```

The trust contexts built around that check cover URL-taking commands (`\url`, `\href` — i.e. active links) and HTML-emitting commands (paraphrased — no quote available because the trustContext construction spans multiple command handlers around `node_modules/katex/dist/katex.mjs:11181-11227`). Confidence is Medium because the claim was verified from library source and docs, not by executing a render with `trust: true`.

**Evidence:** `eslint.config.mjs:46-55`, `node_modules/katex/dist/katex.mjs:207-211`, `node_modules/katex/dist/katex.mjs:11181-11227`, `node_modules/katex/dist/katex.mjs:341-350`

---

## Claim 8: "Currently zero usages — keep it that way." (react/no-danger, i.e. dangerouslySetInnerHTML)

**Location:** `eslint.config.mjs:57`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers first-party code in the repo at HEAD; does not cover dependencies' internal use of dangerouslySetInnerHTML.

Zero usages confirmed two ways. Statically, `dangerouslySetInnerHTML` greps to nothing outside `eslint.config.mjs` itself (paraphrased — no quote available because the claim covers absence of code: no matching grep results outside the lint config and node_modules). Dynamically, the full repo lint — with `react/no-danger` active — reported no such finding:

```
// r2-npm-run-lint.txt
✖ 2 problems (0 errors, 2 warnings)
exit: 0
```

Both warnings in that run are `react-hooks/exhaustive-deps`, not `react/no-danger` (visible in the captured output).

Execution: `npm run lint`, cwd `/workspace/external/cc-review-eval/mfc-secdeps`, exit 0, 2026-08-18T06:13:12Z.

**Evidence:** `eslint.config.mjs:57-58`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-secdeps/evidence/r2-npm-run-lint.txt`

---

## Claim 9: "Bundled an `npm audit fix` to clear the existing high-severity findings (@xmldom/xmldom, lodash)"

**Location:** commit 1efb6db (message); `package-lock.json:3860-3862`, `package-lock.json:7339-7341`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the two named packages were high-severity findings at their pre-bump versions and are cleared at the bumped versions; does not establish these were the *only* pre-existing findings at commit time.

The lockfile diff bumps exactly these two packages:

```
// git diff d86d2dc...HEAD -- package-lock.json (excerpt)
"node_modules/@xmldom/xmldom": ... "version": "0.8.13"   (was 0.8.11)
"node_modules/lodash": ... "version": "4.18.1"           (was 4.17.23)
```

To confirm the old versions were high-severity findings, a scratch package tree (outside the clone) pinning `lodash@4.17.23` and `@xmldom/xmldom@0.8.11` was audited:

```
// r2-audit-old-versions-probe.txt (exit 1)
@xmldom/xmldom  <=0.8.12
Severity: high
...
lodash  <=4.17.23
Severity: high
...
2 high severity vulnerabilities
```

The bumped versions (0.8.13, 4.18.1) sit above both vulnerable ranges, and neither package appears in the current production audit (`r2-audit-omit-dev-high.txt` lists only @anthropic-ai/sdk, nanoid, next, pdfjs-dist, postcss, sharp — paraphrased summary of the captured file's package headings; full text in the evidence file). Both are production transitives (`lodash` via dagre/graphlib, `@xmldom/xmldom` via mammoth — paraphrased — no quote available because the dependency edges were read programmatically from `package-lock.json`'s packages map).

Executions: scratch-dir `npm install --package-lock-only --ignore-scripts && npm audit`, cwd `/tmp/tmp.Hwb3CyAWFb` (scratch, deleted after), exit 1, 2026-08-18T06:13:47Z; `npm audit --omit=dev --audit-level=high`, cwd `/workspace/external/cc-review-eval/mfc-secdeps`, exit 1, 2026-08-18T06:12:18Z. Advisory-DB-dependent: true as of the audit DB at 2026-08-18T06:13Z.

**Evidence:** `package-lock.json:3860-3862`, `package-lock.json:7339-7341`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-secdeps/evidence/r2-audit-old-versions-probe.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-secdeps/evidence/r2-audit-omit-dev-high.txt`

---

## Claim 10: "…so this branch lands green"

**Location:** commit 1efb6db (message); gate at `.github/workflows/ci.yml:44-45`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the audit gate's result against today's advisory database; does not establish what the gate returned at commit time (the advisory DB is time-varying and its historical state is not reconstructable here).

The branch does NOT land green today. The exact CI command fails:

```
// r2-audit-omit-dev-high.txt
cmd: npm audit --omit=dev --audit-level=high
...
6 vulnerabilities (1 moderate, 5 high)
...
exit: 1
```

The five high-severity production findings are in nanoid, next, pdfjs-dist, postcss (nested under next), and sharp — none of which this branch touched (package names quoted from the captured output's severity headings; full advisory lists in the evidence file). The claim was plausibly true when written — the branch's own fixes (Claim 9) are confirmed effective, and several failing advisories cite 2026 CVEs (e.g. the sharp finding cites `CVE-2026-33327, CVE-2026-33328, CVE-2026-35590, CVE-2026-35591` at `r2-audit-omit-dev-high.txt` line 69) — so the divergence is between the commit-time and present advisory DB, hence Stale rather than Incorrect. Confidence Medium: the present-day failure is certain; the commit-time greenness is inferred, not observed. Staleness note: result is true as of the npm advisory DB at 2026-08-18T06:12Z; this is precisely the "fresh CVE breaks CI on unrelated branches" scenario the ci.yml comment describes for lower severities, occurring at high severity.

Execution: `npm audit --omit=dev --audit-level=high`, cwd `/workspace/external/cc-review-eval/mfc-secdeps`, exit 1, 2026-08-18T06:12:18Z.

**Evidence:** `.github/workflows/ci.yml:44-45`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-secdeps/evidence/r2-audit-omit-dev-high.txt`

---

## Claim 11: "only patch upgrades, no API changes"

**Location:** commit 1efb6db (message); `package-lock.json:3860`, `package-lock.json:7339`
**Type:** Reference / Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the semver classification of the two lockfile bumps; does not establish whether lodash 4.18.x actually changed any API this codebase's transitive consumers call.

One of the two upgrades is not a patch upgrade. The lockfile shows:

```
// package-lock.json:7339-7340 (post-change)
"version": "4.18.1",
"resolved": "https://registry.npmjs.org/lodash/-/lodash-4.18.1.tgz",
```

versus `4.17.23` before the change (per the range diff). 4.17.23 → 4.18.1 increments the minor version — a minor upgrade under semver, not a patch upgrade. The @xmldom/xmldom bump (0.8.11 → 0.8.13, `package-lock.json:3860`) is a genuine patch upgrade. The "only patch upgrades" mechanism is refuted for lodash, so the compound claim is Incorrect even if the practical conclusion ("no API changes" that matter to this app) may hold — the "no API changes" atom was not separately verifiable and is carried by the most-severe part. A reader acting on "only patch upgrades" (e.g., skipping upgrade review under a patch-only policy) would be misled.

**Evidence:** `package-lock.json:3860-3862`, `package-lock.json:7339-7341`, `git diff d86d2dc...HEAD -- package-lock.json`

---

## Claim 12: "All three rules verified to fire on a temporary fixture before commit."

**Location:** commit 1efb6db (message); rules at `eslint.config.mjs:33-59`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the substantive guarantee (all three rules fire on a violating fixture under this config at HEAD), independently reproduced; does not establish the historical act of the author running such a fixture pre-commit.

Independently reproduced: a fresh fixture violating all three rules produced one report per rule —

```
// r2-eslint-fixture.txt (exit 1)
2:1   error    'rehype-raw' import is restricted ...  no-restricted-imports
4:23  error    trust: true on KaTeX/rehype-katex ...  no-restricted-syntax
8:15  warning  Dangerous property 'dangerouslySetInnerHTML' found  react/no-danger
```

All three rules fire (the third at warning level, consistent with its configured `"warn"` — see Claim 4b).

Execution: `npx eslint app/__cfc_r2_fixture__.tsx`, cwd `/workspace/external/cc-review-eval/mfc-secdeps`, exit 1, 2026-08-18T06:13:08Z.

**Evidence:** `eslint.config.mjs:33-59`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-secdeps/evidence/r2-eslint-fixture.txt`

---

## Claim 13: "YAML hygiene only; no semantic CI change."

**Location:** commit 8bde50c (message); `.github/workflows/ci.yml:45`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the content of commit 8bde50c's diff; does not evaluate the CI workflow's behavior otherwise.

The commit's entire diff is the addition of a trailing newline to the last line:

```
// git diff 1efb6db 8bde50c
-        run: npm audit --omit=dev --audit-level=high
\ No newline at end of file
+        run: npm audit --omit=dev --audit-level=high
```

No token changes; YAML semantics identical.

**Evidence:** `.github/workflows/ci.yml:44-45`, `git diff 1efb6db 8bde50c`

---

## Claims Requiring Attention

### Incorrect
- **Claim 11** (commit 1efb6db / `package-lock.json:7339`): "only patch upgrades" — lodash 4.17.23 → 4.18.1 is a minor-version upgrade; only the @xmldom/xmldom bump (0.8.11 → 0.8.13) is a patch. Reword to "patch/minor upgrades" or note the lodash minor bump explicitly.

### Stale
- **Claim 10** (commit 1efb6db / `.github/workflows/ci.yml:44-45`): "this branch lands green" — the audit gate now exits 1 with 5 high-severity production findings (nanoid, next, pdfjs-dist, postcss, sharp) from advisories postdating the commit; true as of the audit DB at 2026-08-18T06:12Z.

### Mostly Accurate
- **Claim 4b** (`eslint.config.mjs:31-32`): "fail loudly" — `react/no-danger` is warn-level and does not fail `npm run lint` (observed exit 0 with warnings); only two of the three guardrails actually block.
- **Claim 6** (`eslint.config.mjs:46-49`): the `no-restricted-syntax` selector misses string-literal-keyed `{ "trust": true }` (demonstrated on the fixture); "catches trust: true on object literals" should be qualified to identifier-keyed properties.

### Unverifiable
- None.
