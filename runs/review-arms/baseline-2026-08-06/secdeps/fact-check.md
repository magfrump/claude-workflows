Commit: 8bde50c
# Code Fact-Check Report

**Repository:** meta-formalism-copilot (worktree `wt-secdeps`, reviewed at 8bde50c)
**Scope:** git diff d86d2dc..8bde50c (full-branch changeset: ci.yml, eslint.config.mjs, package-lock.json)
**Checked:** 2026-08-06
**Total claims checked:** 11
**Summary:** 5 verified, 4 mostly accurate, 0 stale, 0 incorrect, 2 unverifiable

---

## Claim 1: "--omit=dev: only audit production deps (the ones that ship to users)."

**Location:** `.github/workflows/ci.yml:41`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High

The step runs `npm audit` with the flag exactly as commented:

```yaml
# .github/workflows/ci.yml:45-46
- name: Audit production dependencies
  run: npm audit --omit=dev --audit-level=high
```

`npm audit --omit=dev` excludes the `dev` dependency group from the audit, leaving only production dependencies (paraphrased — no quote available because this is documented npm CLI behavior, not code in this repo). The flag matches the comment.

**Evidence:** `.github/workflows/ci.yml:41-46`

---

## Claim 2: "--audit-level=high: fail only on high+ severity. Lower levels are informational..."

**Location:** `.github/workflows/ci.yml:42-44`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High

The command uses `--audit-level=high`:

```yaml
# .github/workflows/ci.yml:46
run: npm audit --omit=dev --audit-level=high
```

`--audit-level=high` makes `npm audit` exit with a non-zero (CI-failing) code only when a vulnerability of severity high or critical is present; low/moderate findings are reported but do not fail the command (paraphrased — no quote available because this is documented npm CLI behavior, not repo code). Matches the comment.

**Evidence:** `.github/workflows/ci.yml:41-46`

---

## Claim 3: "The XSS surface is already defensive (no dangerouslySetInnerHTML ...)"

**Location:** `eslint.config.mjs:29-30`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High

A tree-wide grep for `dangerouslySetInnerHTML` at 8bde50c returns exactly one hit — the eslint comment itself (`eslint.config.mjs:30`) — and no usages in any `app/**` component (paraphrased — no quote available because the claim covers absence of code; `git grep -cn dangerouslySetInnerHTML 8bde50c` yields only `eslint.config.mjs:1`). No live `dangerouslySetInnerHTML` usage exists.

**Evidence:** `eslint.config.mjs:30` (only occurrence in tree)

---

## Claim 4: "... no rehype-raw ..."

**Location:** `eslint.config.mjs:30`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High

`rehype-raw` appears only inside `eslint.config.mjs` (the restriction rule and its comments) and is not present in `package.json` as a dependency, nor imported anywhere (paraphrased — no quote available because the claim covers absence of code; `git grep rehype-raw 8bde50c` hits only `eslint.config.mjs:30,40,41`, and it is absent from `package.json`). The markdown renderer confirms the safe plugin set:

```tsx
// app/components/features/output-editing/LatexRenderer.tsx:9-10
const remarkPlugins = [remarkGfm, remarkMath];
const rehypePlugins = [rehypeKatex];
```

**Evidence:** `app/components/features/output-editing/LatexRenderer.tsx:9-10`, `eslint.config.mjs:40`

---

## Claim 5: "... KaTeX trust:false)."

**Location:** `eslint.config.mjs:30`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High

The effective posture is `trust=false`, but it is *not explicitly set* — `rehypeKatex` is registered with no options object, so it relies on KaTeX's default (`trust` defaults to `false`):

```tsx
// app/components/features/output-editing/LatexRenderer.tsx:10
const rehypePlugins = [rehypeKatex];
```

The comment reads as if `trust:false` were a configured value; in reality no options are passed and the safe state is the library default (paraphrased — no quote available because `rehype-katex`'s default `trust: false` is documented library behavior, not repo code). The end state matches the claim, but a reader should know it is a default, not an explicit hardening.

**Evidence:** `app/components/features/output-editing/LatexRenderer.tsx:6,10`

---

## Claim 6: "These rules are guardrails that fail loudly if a future change tries to weaken any of those"

**Location:** `eslint.config.mjs:31-32`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High

Two of the three rules are `"error"` and will fail `npm run lint` (which runs `eslint`, `package.json:9`) — those "fail loudly." But the third, `react/no-danger`, is only `"warn"`:

```js
// eslint.config.mjs:58
"react/no-danger": "warn",
```

The lint script is bare `eslint` with no `--max-warnings 0`:

```json
// package.json:9
"lint": "eslint",
```

A `warn`-level rule does not produce a non-zero exit under plain `eslint`, so re-introducing `dangerouslySetInnerHTML` would print a warning but would NOT fail CI/lint — it does not "fail loudly." Additionally, `no-restricted-imports` catches ES `import`/`export from` and dynamic `import()` expressions but does NOT catch CommonJS `require("rehype-raw")` (paraphrased — no quote available because this is documented `no-restricted-imports` scope, not repo code); in this ESM/Next.js app that path is unlikely but is a real coverage gap for the "fail loudly on any weakening" claim.

**Evidence:** `eslint.config.mjs:35-58`, `package.json:9`

---

## Claim 7: "Catches `trust: true` on object literals ... Broad enough to catch `{ trust: true }` elsewhere too"

**Location:** `eslint.config.mjs:46-49`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium

The selector matches a property with an identifier key `trust` and a boolean-`true` literal value:

```js
// eslint.config.mjs:53
selector: "Property[key.name='trust'][value.value=true]",
```

This correctly catches `{ trust: true }` anywhere (any object literal), so the "broad enough elsewhere" claim holds. Two narrowing caveats a reader should note: (1) `key.name` matches only identifier keys, so a string key `{ "trust": true }` (which uses `key.value`, not `key.name`) is NOT caught; (2) KaTeX/rehype-katex also accept `trust` as a *function* (`trust: () => true`), which this literal-only selector does NOT catch — so it does not fully cover "KaTeX options re-enabling active links" as the surrounding comment implies. For the literal `trust: true` form the comment is accurate.

**Evidence:** `eslint.config.mjs:50-55`

---

## Claim 8: "Currently zero usages — keep it that way." (react/no-danger)

**Location:** `eslint.config.mjs:57`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High

`react/no-danger` flags `dangerouslySetInnerHTML`; as established in Claim 3, the only tree occurrence of that string is the eslint comment itself, so there are zero component usages (paraphrased — no quote available because the claim covers absence of code; confirmed via tree-wide grep returning only `eslint.config.mjs`). "Zero usages" is accurate. (Note the enforcement caveat in Claim 6: the rule is `warn`, so it does not block re-introduction.)

**Evidence:** `eslint.config.mjs:57-58`

---

## Claim 9: "Bundled an `npm audit fix` ... (@xmldom/xmldom, lodash) ... only patch upgrades, no API changes."

**Location:** commit `1efb6db` message body
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High

The lockfile diff shows the two named packages bumped:

```
# package-lock.json (@xmldom/xmldom)
-      "version": "0.8.11",
+      "version": "0.8.13",
# package-lock.json (lodash)
-      "version": "4.17.23",
+      "version": "4.18.1",
```

`@xmldom/xmldom` 0.8.11 → 0.8.13 is a patch bump, matching the claim. But `lodash` 4.17.23 → 4.18.1 crosses the minor version (17 → 18), i.e. a **minor** bump, not a patch — so "only patch upgrades" is imprecise. Both are transitive dependencies (neither appears in `package.json`), consistent with an `npm audit fix`. "No API changes" is not statically verifiable from the lockfile alone.

**Evidence:** `package-lock.json` (@xmldom/xmldom and lodash version lines), `package.json` (neither present as direct dep)

---

## Claim 10: "...to clear the existing high-severity findings (@xmldom/xmldom, lodash) so this branch lands green"

**Location:** commit `1efb6db` message body
**Type:** Configuration
**Verdict:** Unverifiable
**Confidence:** Low

Whether the bumped versions actually clear all high/critical advisories requires querying the npm advisory database and running `npm audit --omit=dev --audit-level=high` in the environment, which cannot be done from static analysis of this offline worktree (paraphrased — no quote available because verification requires runtime access to the npm advisory DB). The version bumps are present (Claim 9), but their sufficiency to make audit pass is not statically checkable. Note also that the named versions (lodash 4.18.1, @xmldom 0.8.13) do not correspond to real published releases as of the knowledge cutoff, suggesting a synthetic/benchmark lockfile.

**Evidence:** `package-lock.json` (version lines); external advisory DB (not accessible)

---

## Claim 11: "All three rules verified to fire on a temporary fixture before commit."

**Location:** commit `1efb6db` message body
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Low

No fixture file is present in the diff or tree (paraphrased — no quote available because the claim covers absence of code; the fixture was "temporary" and not committed). Static analysis can confirm the rule *definitions* are syntactically plausible (see Claims 6-7) but cannot confirm that a past manual run fired all three. Notably, the `react/no-danger: "warn"` rule under bare `eslint` would emit a warning, not an error — so "fires" is true only in the sense of producing lint output, not failing.

**Evidence:** commit `1efb6db` body; no fixture in tree

---

## Claims Requiring Attention

### Incorrect
- (none)

### Stale
- (none)

### Mostly Accurate
- **Claim 5** (`eslint.config.mjs:30`): "KaTeX trust:false" is the library default (no options passed), not an explicit configuration — comment/doc.
- **Claim 6** (`eslint.config.mjs:31-32`): "fail loudly" holds for the two `error` rules but not `react/no-danger` (`warn`, and `lint` has no `--max-warnings 0`), and `no-restricted-imports` misses `require()` — comment/doc vs. behavioral.
- **Claim 7** (`eslint.config.mjs:46-49`): selector catches literal `trust: true` (and string-keyed/function-valued forms escape it) — comment matches the narrow literal case; behavioral.
- **Claim 9** (`1efb6db` commit): "only patch upgrades" is wrong for lodash (4.17.23 → 4.18.1 is a minor bump) — comment/doc.

### Unverifiable
- **Claim 10** (`1efb6db` commit): needs npm advisory DB + runtime `npm audit` to confirm findings are cleared.
- **Claim 11** (`1efb6db` commit): fixture was temporary and not committed; past manual run not statically checkable.
