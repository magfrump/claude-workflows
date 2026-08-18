# Code Fact-Check Report

**Repository:** /workspace/external/cc-review-eval/mfc-secdeps
**Commit:** 8bde50c
**Scope:** Files changed in `git diff d86d2dc...HEAD` (`.github/workflows/ci.yml`, `eslint.config.mjs`, `package-lock.json`) plus the commit messages of the range (1efb6db, 8bde50c). No README/docs files reference the changed code (grep for `npm audit`, `audit-level`, `rehype-raw`, `no-danger` across `README.md`, `CONTRIBUTING.md`, `docs/`, `documentation/`, `CLAUDE.md` returned no hits).
**Checked:** 2026-08-18
**Total claims checked:** 15
**Summary:** 12 verified, 0 mostly accurate, 1 stale, 2 incorrect, 0 unverifiable

Evidence logs for executed verdicts: `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-secdeps/evidence/` (prefix `r1-`). All audit-based verdicts consult the npm registry advisory database, a time-varying input; they are true as of the advisory DB at 2026-08-18T06:11–06:13Z.

---

## Claim 1: "--omit=dev: only audit production deps (the ones that ship to users)."

**Location:** `.github/workflows/ci.yml:41`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the effect of `--omit=dev` on which dependency trees `npm audit` reports; does not establish that every production dep literally ships to end users (e.g., `next`/`sharp` are build/server-side).

The flag demonstrably excludes devDependency trees. `npm audit --omit=dev --audit-level=high` (cwd `/workspace/external/cc-review-eval/mfc-secdeps`, exit 1, 2026-08-18T06:11:47Z) reports:

```
// evidence/r1-audit-omit-dev-high.txt:74
6 vulnerabilities (1 moderate, 5 high)
```

while the unrestricted `npm audit` (same cwd, exit 1, 2026-08-18T06:12:15Z) reports:

```
// evidence/r1-audit-full.txt
11 vulnerabilities (1 low, 1 moderate, 9 high)
```

The extra findings in the full run sit in devDependency trees only — `@babel/core`, `brace-expansion` under `node_modules/eslint-config-next/`, `picomatch` under `node_modules/vitest/`, and `undici`/`vite` (paraphrased — no quote available because the comparison spans ~10 advisory blocks across two captured log files; the package lists are in `r1-audit-full.txt` vs `r1-audit-omit-dev-high.txt`). All six packages flagged in the `--omit=dev` run (`@anthropic-ai/sdk`, `nanoid`, `next`, `pdfjs-dist`, `postcss`, `sharp`) are in the `dependencies` block of `package.json:15-33` or their transitive trees.

**Evidence:** `.github/workflows/ci.yml:41`, `package.json:15-33`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-secdeps/evidence/r1-audit-omit-dev-high.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-secdeps/evidence/r1-audit-full.txt`

---

## Claim 2: "--audit-level=high: fail only on high+ severity. Lower levels are informational and would otherwise make every fresh CVE break CI on branches that have nothing to do with security."

**Location:** `.github/workflows/ci.yml:42-44`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--audit-level` gating the exit code by severity threshold (lower-severity findings still printed but non-failing); does not directly demonstrate a moderate-only baseline exiting 0 under `--audit-level=high`, since the current tree has high-severity production findings.

The threshold-gating behavior was demonstrated by varying the level against the same dependency tree. With high-severity findings present, `npm audit --omit=dev --audit-level=high` exits 1 (evidence file `r1-audit-omit-dev-high.txt`, `exit=1` on its last line, cwd `/workspace/external/cc-review-eval/mfc-secdeps`, 2026-08-18T06:11:47Z), while raising the threshold suppresses the failure even though the same high-severity advisories are printed:

```
// evidence/r1-audit-omit-dev-critical.txt (cmd: npm audit --omit=dev --audit-level=critical, 2026-08-18T06:12:15Z)
exit=0
```

Both runs print the moderate `@anthropic-ai/sdk` advisory in their reports regardless of threshold — i.e., below-threshold findings remain informational, matching the comment (paraphrased — no quote available because the point is the presence of the same advisory block in two log files; see lines 6-11 of each capture).

**Evidence:** `.github/workflows/ci.yml:42-45`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-secdeps/evidence/r1-audit-omit-dev-high.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-secdeps/evidence/r1-audit-omit-dev-critical.txt`

---

## Claim 3: "The XSS surface is already defensive (no dangerouslySetInnerHTML, no rehype-raw, KaTeX trust:false)."

**Location:** `eslint.config.mjs:29-30`
**Type:** Architectural / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers absence of the three patterns in first-party source at HEAD; does not establish that `trust: false` is explicitly configured (it holds by KaTeX default), nor the XSS posture of dependencies themselves.

All three legs hold. `rg -n "dangerouslySetInnerHTML|rehype-raw|rehypeRaw" --glob '!node_modules'` matches only the new lint config's own comment and rule strings, and `rehype-raw` is absent from `package.json` dependencies (paraphrased — no quote available because the claim covers absence of code: the grep's only hits are `eslint.config.mjs:30,40,41` and it is not installed — `ls node_modules/rehype-raw` fails). The repo-wide lint run with `react/no-danger` enabled produced zero `no-danger` findings (`evidence/r1-npm-run-lint.txt`, exit 0; its only 2 warnings are `react-hooks/exhaustive-deps` in `app/page.tsx`).

For the KaTeX leg, the only rehype-katex usage passes no options:

```js
// app/components/features/output-editing/LatexRenderer.tsx:6-10
import rehypeKatex from "rehype-katex";
import "katex/dist/katex.min.css";

const rehypePlugins = [rehypeKatex];
```

and KaTeX coerces an unset `trust` to `false`:

```js
// node_modules/katex/dist/katex.mjs:349-350
var trust = typeof this.trust === "function" ? this.trust(context) : this.trust;
return Boolean(trust);
```

So `trust` is effectively `false` — by default rather than by explicit configuration.

**Evidence:** `eslint.config.mjs:29-30`, `app/components/features/output-editing/LatexRenderer.tsx:6-10`, `node_modules/katex/dist/katex.mjs:349-350`, `package.json:15-33`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-secdeps/evidence/r1-npm-run-lint.txt`

---

## Claim 4a: "These rules are guardrails that fail loudly if a future change tries to weaken any of those" — the `no-restricted-imports` (rehype-raw) and `no-restricted-syntax` (`trust: true`) legs

**Location:** `eslint.config.mjs:30-32`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two error-level rules failing `eslint` (and hence the CI `npm run lint` step) on a violating fixture; does not cover the `react/no-danger` leg (see Claim 4b) or bypasses via eslint-disable comments.

A scratch fixture containing `import rehypeRaw from "rehype-raw"` and `{ trust: true }` was linted (cmd `npx eslint app/r1-scratch-lint-fixture.tsx`, cwd `/workspace/external/cc-review-eval/mfc-secdeps`, exit 1, 2026-08-18T06:12:36Z; fixture deleted afterward):

```
// evidence/r1-eslint-fixture.txt
2:1   error    'rehype-raw' import is restricted from being used. ...  no-restricted-imports
4:31  error    trust: true on KaTeX/rehype-katex (or anywhere similar) re-enables active links ...  no-restricted-syntax
✖ 3 problems (2 errors, 1 warning)
exit=1
```

CI runs `npm run lint` as a step (`.github/workflows/ci.yml:26-27`, `run: npm run lint`), and `package.json:9` defines `"lint": "eslint"`, so these errors fail the build — "fail loudly" holds for these two rules.

**Evidence:** `eslint.config.mjs:33-56`, `.github/workflows/ci.yml:26-27`, `package.json:9`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-secdeps/evidence/r1-eslint-fixture.txt`

---

## Claim 4b: "These rules are guardrails that fail loudly if a future change tries to weaken any of those" — the `react/no-danger` (dangerouslySetInnerHTML) leg

**Location:** `eslint.config.mjs:30-32` (rule at `eslint.config.mjs:58`)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exit-code behavior of `eslint` on a file whose only violation is `dangerouslySetInnerHTML`; does not assess whether warn-level was a deliberate choice, only whether it matches "fail loudly."

The rule is registered at warn level:

```js
// eslint.config.mjs:57-58
// Currently zero usages — keep it that way.
"react/no-danger": "warn",
```

A scratch fixture whose only violation is `dangerouslySetInnerHTML` produces a warning and a passing exit code (cmd `npx eslint app/r1-scratch-danger-only.tsx`, cwd `/workspace/external/cc-review-eval/mfc-secdeps`, 2026-08-18T06:12:47Z; fixture deleted afterward):

```
// evidence/r1-eslint-danger-only.txt
2:15  warning  Dangerous property 'dangerouslySetInnerHTML' found  react/no-danger
✖ 1 problem (0 errors, 1 warning)
exit=0
```

Since `eslint` exits 0 on warnings and the CI lint step is plain `"lint": "eslint"` with no `--max-warnings 0` (`package.json:9`), a future change reintroducing `dangerouslySetInnerHTML` passes CI. For this leg the guardrail warns; it does not fail, loudly or otherwise.

**Evidence:** `eslint.config.mjs:57-58`, `package.json:9`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-secdeps/evidence/r1-eslint-danger-only.txt`

---

## Claim 5: "rehype-raw lets raw HTML in markdown render as live DOM, which defeats sanitization on LLM output." (rule message)

**Location:** `eslint.config.mjs:41`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the documented behavior of `rehype-raw` in the react-markdown pipeline this repo uses; does not execute the library (it is not installed) or establish the specific XSS payloads it would admit.

The library is not installed, but the markdown renderer this repo uses documents exactly this behavior — react-markdown escapes HTML by default and names `rehype-raw` as the opt-in that turns raw HTML back on:

```
// node_modules/react-markdown/readme.md:650-655
`react-markdown` typically escapes HTML (or ignores it, with `skipHtml`)
because it is dangerous and defeats the purpose of this library.

However, if you are in a trusted environment (you trust the markdown), and
can spare the bundle size (±60kb minzipped), then you can use
[`rehype-raw`][github-rehype-raw]:
```

The repo renders LLM output through react-markdown (`app/components/features/output-editing/LatexRenderer.tsx:3`, `import ReactMarkdown from "react-markdown"`), so adding rehype-raw there would render raw HTML from that output as live DOM, matching the message.

**Evidence:** `eslint.config.mjs:38-42`, `node_modules/react-markdown/readme.md:648-661`, `app/components/features/output-editing/LatexRenderer.tsx:3-10`

---

## Claim 6: "Catches `trust: true` on object literals — most common in rehype-katex's options ... Broad enough to catch `{ trust: true }` elsewhere too; that's intended."

**Location:** `eslint.config.mjs:46-49`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the selector matching identifier-keyed `trust: true` properties anywhere, not only in rehype-katex options; does not cover evasions the selector cannot see (string-keyed `{"trust": true}`, `trust: someVariableThatIsTrue`, or spread-in options).

The selector is:

```js
// eslint.config.mjs:53
selector: "Property[key.name='trust'][value.value=true]",
```

The fixture's `trust: true` was in a plain exported object (`export const katexOptions = { trust: true, strict: false }` — fixture content preserved in the capture), i.e. not a rehype-katex call at all, and the rule fired on it at error level (cmd `npx eslint app/r1-scratch-lint-fixture.tsx`, exit 1, 2026-08-18T06:12:36Z):

```
// evidence/r1-eslint-fixture.txt
4:31  error    trust: true on KaTeX/rehype-katex (or anywhere similar) re-enables active links ...  no-restricted-syntax
```

This confirms both the mechanism (AST property match on object literals) and the claimed breadth.

**Evidence:** `eslint.config.mjs:50-56`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-secdeps/evidence/r1-eslint-fixture.txt`

---

## Claim 7: "trust: true on KaTeX/rehype-katex (or anywhere similar) re-enables active links and raw HTML in math output." (rule message)

**Location:** `eslint.config.mjs:54`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers KaTeX's documented meaning of `trust: true` (enabling URL/HTML commands in rendered math); does not execute a rendering to demonstrate a live payload, and "anywhere similar" outside KaTeX is a hedge, not a checkable mechanism.

KaTeX's bundled type documentation states the option's effect:

```
// node_modules/katex/types/katex.d.ts:176-179
* If `false` (do not trust input), prevent any commands like
* `\includegraphics` that could enable adverse behavior, rendering them
* instead in `errorColor`.
* If `true` (trust input), allow all such commands.
```

and the runtime option description reads `"Trust the input, enabling all HTML features such as \\url."` (`node_modules/katex/dist/katex.mjs:209`). Active links (`\url`, `\href`) and HTML-emitting commands are exactly what `trust: true` enables, matching the message.

**Evidence:** `eslint.config.mjs:50-55`, `node_modules/katex/types/katex.d.ts:173-186`, `node_modules/katex/dist/katex.mjs:207-211`

---

## Claim 8: "Currently zero usages — keep it that way." (react/no-danger / dangerouslySetInnerHTML)

**Location:** `eslint.config.mjs:57`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers first-party source at HEAD (lint-covered files plus a repo-wide grep excluding node_modules); does not cover the lint-ignored `verifier/**` tree beyond the grep, or future changes.

The repo-wide lint with the rule active reports no `react/no-danger` findings — its only output is two unrelated warnings:

```
// evidence/r1-npm-run-lint.txt (cmd: npm run lint, cwd: /workspace/external/cc-review-eval/mfc-secdeps, exit 0, 2026-08-18T06:12:58Z)
app/page.tsx
  209:6  warning  React Hook useCallback has missing dependencies: ...  react-hooks/exhaustive-deps
  271:6  warning  React Hook useCallback has missing dependencies: ...  react-hooks/exhaustive-deps
✖ 2 problems (0 errors, 2 warnings)
```

A grep for `dangerouslySetInnerHTML` outside `node_modules` matches only the lint config's own comment at `eslint.config.mjs:30` (paraphrased — no quote available because the claim covers absence of code: no other grep results).

**Evidence:** `eslint.config.mjs:57-58`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-secdeps/evidence/r1-npm-run-lint.txt`

---

## Claim 9: "New step: npm audit --omit=dev --audit-level=high. Audits only what ships to users, fails only on high+ severity ..." (commit message)

**Location:** commit 1efb6db (`.github/workflows/ci.yml:45-46`)
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the commit message accurately describing the step added to ci.yml; the flag semantics themselves are verdicted separately in Claims 1-2.

The step exists exactly as described:

```yaml
# .github/workflows/ci.yml:45-46
- name: Audit production dependencies
  run: npm audit --omit=dev --audit-level=high
```

The behavioral characterizations ("only what ships to users", "fails only on high+") are the same assertions as the ci.yml comments, verified by execution in Claims 1 and 2.

**Evidence:** `.github/workflows/ci.yml:45-46`, commit 1efb6db message

---

## Claim 10a: "Bundled an `npm audit fix` to clear the existing high-severity findings (@xmldom/xmldom, lodash)" (commit message)

**Location:** commit 1efb6db (`package-lock.json:3859-3862`, `package-lock.json:7338-7342`)
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the two named packages carried high-severity advisories at the base lockfile versions and carry none at the bumped versions, per the advisory DB as of 2026-08-18; does not establish they were the *only* high findings at commit time (the DB is time-varying).

Auditing the base commit's lockfile (copied to a temp dir; cmd `npm audit --omit=dev --audit-level=high`, exit 1, 2026-08-18T06:12:16Z) shows both packages as high-severity at their old versions:

```
// evidence/r1-audit-base-lockfile.txt
@xmldom/xmldom  <=0.8.12
Severity: high
...
lodash  <=4.17.23
Severity: high
```

The HEAD lockfile bumps them past those ranges (`package-lock.json:3860` — `"version": "0.8.13"`; `package-lock.json:7339` — `"version": "4.18.1"`), and the HEAD audit (`evidence/r1-audit-omit-dev-high.txt`) lists neither package. The findings named in the commit message were real and are cleared by the bump.

**Evidence:** `package-lock.json:3859-3862`, `package-lock.json:7338-7342`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-secdeps/evidence/r1-audit-base-lockfile.txt`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-secdeps/evidence/r1-audit-omit-dev-high.txt`

---

## Claim 10b: "... so this branch lands green" (commit message)

**Location:** commit 1efb6db (`.github/workflows/ci.yml:45-46`)
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the audit gate's exit status at HEAD against the advisory DB as of 2026-08-18T06:11Z; does not establish the gate's status against the DB as it stood at commit time (2026-04-27), which cannot be reconstructed.

The gate the branch adds fails at HEAD today. `npm audit --omit=dev --audit-level=high` (cwd `/workspace/external/cc-review-eval/mfc-secdeps`, 2026-08-18T06:11:47Z) exits 1 with:

```
// evidence/r1-audit-omit-dev-high.txt:74,81
6 vulnerabilities (1 moderate, 5 high)
exit=1
```

The five high findings are in `nanoid`, `next`, `pdfjs-dist`, `postcss`, and `sharp` — none of them the packages this commit bumped (paraphrased — no quote available because the finding spans six advisory blocks in the captured log). The @xmldom/xmldom and lodash findings the commit cleared are indeed gone (Claim 10a), so the claim was plausibly true against the advisory DB on the commit date (2026-04-27, per `git log`), but advisories published since make the branch red under its own gate now. This is staleness against a time-varying external input rather than a code change; verdict is true-when-written / false-now.

**Evidence:** `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-secdeps/evidence/r1-audit-omit-dev-high.txt`, `.github/workflows/ci.yml:45-46`

---

## Claim 10c: "only patch upgrades, no API changes" (commit message)

**Location:** commit 1efb6db (`package-lock.json:7338-7342`)
**Type:** Reference / Configuration
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the semver classification of the two version bumps in the lockfile diff; does not establish whether lodash 4.18.x in fact changes or adds any API surface (the "no API changes" half is judged via the refuted "patch" mechanism, not a lodash source diff).

The lockfile diff contradicts "only patch upgrades." `@xmldom/xmldom` 0.8.11 → 0.8.13 is a patch bump, but lodash moved a minor version:

```
// package-lock.json:7338-7340 (HEAD; base d86d2dc had "version": "4.17.23")
"node_modules/lodash": {
  "version": "4.18.1",
```

4.17.23 → 4.18.1 is a **minor** upgrade under semver, and minor releases exist precisely to add API surface, so the stated mechanism backing "no API changes" is refuted even though the bump is presumably non-breaking. Per the compound-claims rule, the refuted "only patch upgrades" mechanism carries the verdict.

**Evidence:** `package-lock.json:7338-7342`, `git diff d86d2dc...HEAD -- package-lock.json`

---

## Claim 11: "All three rules verified to fire on a temporary fixture before commit." (commit message)

**Location:** commit 1efb6db (`eslint.config.mjs:33-58`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the substantive assertion — the three rules fire on a fixture at HEAD, reproduced in this run; does not establish the historical act of the author running such a fixture pre-commit (no fixture exists in the tree, consistent with "temporary").

Reproduced: a fixture containing all three patterns triggers all three rules (cmd `npx eslint app/r1-scratch-lint-fixture.tsx`, cwd `/workspace/external/cc-review-eval/mfc-secdeps`, exit 1, 2026-08-18T06:12:36Z):

```
// evidence/r1-eslint-fixture.txt
2:1   error    'rehype-raw' import is restricted ...   no-restricted-imports
4:31  error    trust: true on KaTeX/rehype-katex ...   no-restricted-syntax
7:15  warning  Dangerous property 'dangerouslySetInnerHTML' found  react/no-danger
✖ 3 problems (2 errors, 1 warning)
```

All three fire; note that "fire" for `react/no-danger` means a warning, not a failure (see Claim 4b).

**Evidence:** `eslint.config.mjs:33-58`, `/workspace/runs/review-arms/e8-evidence-pipeline/mfc-secdeps/evidence/r1-eslint-fixture.txt`

---

## Claim 12: "chore: add trailing newline to ci.yml — YAML hygiene only; no semantic CI change." (commit message)

**Location:** commit 8bde50c (`.github/workflows/ci.yml:46`)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the content of commit 8bde50c's diff; does not cover any other commit.

`git show 8bde50c` contains exactly one hunk, replacing the final line with itself plus a newline:

```
// git show 8bde50c
-        run: npm audit --omit=dev --audit-level=high
\ No newline at end of file
+        run: npm audit --omit=dev --audit-level=high
```

No other lines change; the commit is a trailing-newline fix with no semantic effect, as claimed.

**Evidence:** `.github/workflows/ci.yml:45-46`, commit 8bde50c diff

---

## Claims Requiring Attention

### Incorrect
- **Claim 4b** (`eslint.config.mjs:30-32,58`): "fail loudly" does not hold for the `react/no-danger` leg — it is warn-level and `eslint` exits 0 on warnings (no `--max-warnings 0` in the lint script), so reintroducing `dangerouslySetInnerHTML` passes CI. Either promote to `"error"` or soften the comment.
- **Claim 10c** (`package-lock.json:7338-7342`): commit message says "only patch upgrades," but lodash 4.17.23 → 4.18.1 is a minor bump; only @xmldom/xmldom's bump is a patch.

### Stale
- **Claim 10b** (`.github/workflows/ci.yml:45-46`): "this branch lands green" no longer holds — the new audit gate exits 1 at HEAD (5 high-severity production advisories in nanoid/next/pdfjs-dist/postcss/sharp published since the 2026-04-27 commit), as of the npm advisory DB at 2026-08-18T06:11Z.

### Mostly Accurate
- (none)

### Unverifiable
- (none)
