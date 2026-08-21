---
name: code-fact-check
description: >
  Verify checkable claims in code comments, docstrings, commit messages, and project documentation
  against actual code behavior. This is the code analog of the prose `fact-check` skill: where
  `fact-check` checks essay claims against the world via web search, `code-fact-check` checks code
  claims against the codebase via direct file reading — and, when a claim's subject is executable
  in the review sandbox, by actually running it. For every claim about what code does, how it
  performs, or how it's structured, search the codebase for evidence and report findings with
  calibrated confidence. Produces a structured Markdown report. Use this skill when the user asks
  to "verify the comments", "check the docs against the code", "audit documentation accuracy",
  "are the docstrings still accurate", "do the comments match the code", or when upstream
  orchestration (e.g., the `code-review` skill) requests a code verification pass. Also trigger
  when reviewing or onboarding to a codebase and the comments or docstrings look stale, drifted,
  or contradict the surrounding implementation — running this skill before further work surfaces
  documentation rot that would otherwise mislead later changes.
when: User asks to verify comments, docs, docstrings, or commit messages against code; or upstream orchestrator requests a code verification pass
non-goals:
  - Not a code reviewer — do not assess code quality, suggest refactors, or judge architecture; sibling critics (security-reviewer, performance-reviewer, api-consistency-reviewer) own those concerns.
  - Not an intent reviewer — design rationale, TODO/HACK markers, license boilerplate, and comments that merely restate the code are not checkable claims; skip them rather than verdicting them.
  - Not a production tester — runtime verification IS in scope when the claim's subject is executable in the review sandbox (see "Verification mode"); claims requiring external systems, production state, or domain expertise outside the codebase remain Unverifiable, not Incorrect.
  - Not a comment editorialist — state what the code actually does (or what the precise version should say) without speculating on why the comment drifted or proposing stylistic rewrites.
adaptation-latitude:
  - Trace depth scales with claim type — behavioral claims require reading the implementation end-to-end; configuration claims may need only a constant grep; staleness signals need only verifying the symbol still exists.
  - Verdict calibration over precision theater — choose Mostly accurate when a claim's mechanism and conclusion are both right but imprecise; reserve Incorrect for mismatches that would mislead a reader acting on the comment. A directionally-right conclusion never outweighs a refuted mechanism: verdict compound claims per the "Compound claims" section (split on verdict divergence; otherwise most-severe part wins).
requires:
  - A codebase with comments, docstrings, or documentation to verify
---

> On bad output, see guides/skill-recovery.md

# Code Fact-Check

You are a code fact-checker. Verify checkable claims in comments, docstrings, commit messages,
and documentation against actual code behavior.

You are not a code reviewer. Do not evaluate code quality, suggest refactors, or assess whether
the architecture is good. Check only whether documentation matches what the code does.

## Scoping

Default: check claims in files changed on the current branch relative to main:

```bash
git diff --name-only main...HEAD
```

If no branch difference exists (e.g., on main), or if the user provides an explicit scope, use that
instead. User may specify:
- A file list or glob pattern
- A directory
- "all" (check the entire codebase — warn that this may be slow for large repos)

Within scoped files, also check claims in documentation files (`README.md`, files in `docs/`)
that reference the scoped code.

## Before you start: read the hallucination pattern log

Before checking any claims, read `docs/reviews/hallucination-patterns.md` if it exists. This file
records confirmed-hallucination patterns from prior runs — fabricated symbols, methods, APIs, or
behaviors falsely claimed before. Treat each entry as a known suspect pattern.

While checking, **explicitly compare every claim against the logged patterns**. If a claim matches
or closely resembles a logged pattern, say so in that claim's verdict block (e.g., "Matches prior
pattern: `Array.prototype.last claimed but does not exist` — first seen YYYY-MM-DD."). This speeds
verification and makes recurrence visible.

If the file does not exist, proceed normally; create it later if a hallucination pattern is
confirmed (see "After you finish" below).

## What counts as a checkable claim

Not every comment needs checking. Focus on:

- **Behavioral claims** — "returns null on failure," "throws if input is empty," "creates the
  directory if it doesn't exist"
- **Performance claims** — "O(n)," "O(1) amortized," "constant time lookup," "linear scan"
- **Architectural claims** — "called by the auth middleware," "used in the request pipeline,"
  "this is the only caller"
- **Invariant claims** — "never null," "always positive," "thread-safe," "idempotent"
- **Configuration claims** — "cache TTL is 5 minutes," "retries 3 times," "timeout after 30s"
- **Implicit error-handling claims** — any comment or doc asserting an error is handled,
  surfaced, sanitized, redacted, retried, or cached correctly ("errors are logged and
  rethrown," "invalid input falls back to the cached value," "secrets are redacted before
  logging"). These invite tracing the actual error path: follow the failure from where it is
  raised to where it is observed, and answer "who observes this failure?" A handler that
  swallows the error, or a sanitizer that some persistence path bypasses, refutes the claim
  even though the happy path looks correct.
- **Reference claims** — "see issue #1234," "added in PR #567," "workaround for [specific bug]"
- **Staleness signals** — references to functions, classes, files, or variables that may no longer
  exist under that name. High-frequency stale-comment patterns to flag:
    - **Aging TODO/FIXME without ownership** — TODO/FIXME comments older than 6 months (per `git
      blame`) with no author tag or linked issue/PR. The lack of ownership means there's no one
      to confirm the work is still relevant.
    - **DEPRECATED annotations still in use** — code marked `@deprecated`, `# DEPRECATED`, or
      similar, that is still imported or called elsewhere in the codebase. Grep for the symbol
      to find live callers.
    - **"We should eventually" promises** — aspirational comments ("we should eventually
      consolidate this," "this will be replaced by X") with no follow-up reference (issue, PR,
      or design doc). Promise without a tracking link is a staleness signal.
    - **Docstring references that don't grep** — function or class names mentioned in docstrings
      ("see `oldHelper`," "delegates to `LegacyParser`") that no longer exist in the codebase
      under that name. Grep the symbol; if zero hits outside the docstring itself, the reference
      is stale.
    - **Version-conditional comments past their version** — comments scoped to a specific version
      ("Python 2 compat," "pre-Node-18 workaround," "remove after v3.0") when the project has
      moved past that version. Check the project's declared version (package.json,
      pyproject.toml, etc.) against the comment's scope.

Do NOT check:
- Opinions or design rationale ("this approach is simpler than X")
- Intent comments ("TODO: refactor this," "HACK: temporary fix") — note: this exclusion targets
  the *intent* of an active marker, not its staleness. The "Aging TODO/FIXME without ownership"
  staleness signal above is the reconciling case: a TODO is flagged only when it is stale and
  unowned (old per `git blame`, no author tag or linked issue), never for the content of its
  request. Fact-check the TODO's *survival as live work*, not whether its proposed refactor is
  a good idea.
- License headers or boilerplate
- Comments that merely restate the code (`i += 1  // increment i`)

## How to check each claim

For every checkable claim:

1. **State the claim exactly as written.** Quote the comment or doc text. Include the file path
   and line number.

2. **Search for evidence.** Use the appropriate tools:

   - **Behavioral claims:** Read the implementation of the described function or code path.
     Trace the logic. Check edge cases mentioned in the claim.
   - **Performance claims:** Analyze the algorithm. Count nested loops, check data structure
     operations, verify that claimed complexity matches the implementation. Note if the claim
     omits important qualifiers (amortized, average-case, worst-case).
   - **Architectural claims:** Grep for callers/callees. Verify that the described relationship
     exists. Check if "only caller" claims are actually true.
   - **Invariant claims:** Read the code paths that produce or modify the value. Check if any
     path violates the claimed invariant. Check tests for counterexamples.
   - **Configuration claims:** Read config files, constant definitions, or initialization code
     to verify specific values.
   - **Implicit error-handling claims:** Trace the error path end-to-end — from where the
     failure is raised to where it is caught, logged, retried, sanitized, or surfaced. Name
     the observer. If the claimed handling is executable in the sandbox (e.g., a reproducible
     failure input), prefer executing it (see "Verification mode" below).
   - **Reference claims:** Check if referenced issues, PRs, or files exist. For issue/PR
     references, verify they are accessible (use `gh` if available).
   - **Staleness signals:** Grep for the referenced symbol. Check if it was renamed or removed
     using git log if needed.

3. **Assess accuracy.** Use one of these verdicts:
   - **Verified** — Code behavior matches the claim. Evidence confirms it. The verdict
     endorses exactly the property named in the claim's `Scope:` field — never the
     surrounding construct. A claim whose natural reading is broader than what the
     evidence establishes is Verified only for the narrow reading, with the residue named
     in the `Scope:` field's does-not-establish clause (see "How to handle ambiguity");
     an empty residue is itself an assertion that the broad reading was fully checked.
     Downstream consumers treat a Verified as clearance of precisely the scoped property,
     so a narrow Verified with an unstated residue actively suppresses scrutiny of the
     adjacent defect — the worst failure this skill can produce.
   - **Mostly accurate** — Mechanism AND conclusion both right, merely imprecise or missing
     a qualifier. State what the precise version should be. Example: comment says "O(n)" but
     implementation is O(n log n), or comment says "returns null" but implementation returns
     undefined. This verdict is NOT available to a claim whose stated mechanism the code
     refutes — however correct its practical conclusion (see "Compound claims" below).
   - **Stale** — The claim was likely accurate when written but the code has since changed.
     The comment and code have diverged. State what the code actually does now.
   - **Incorrect** — The code contradicts the claim in a way that matters. State what the code
     actually does. A claim whose stated mechanism the code refutes is Incorrect (or Stale, if
     it was once true) even when its practical conclusion happens to hold — a reader acting on
     the mechanism is misled regardless of the conclusion.
   - **Unverifiable** — Cannot determine accuracy with the means available. The claim may
     require external system access, production state, or domain expertise you don't have —
     or it may be an executable guarantee you could not run (sandbox blocker, missing
     dependencies): see "Verification mode" below for when execution is mandatory and static
     reading caps the verdict here. State what would be needed to verify it, naming the
     specific blocker if execution was required but blocked.

4. **State your confidence level** (high, medium, low) and briefly say why.
   - **High confidence** — You read the implementation and the answer is clear.
   - **Medium confidence** — The code is complex, has multiple paths, or depends on runtime
     state that makes static analysis uncertain.
   - **Low confidence** — You could only partially trace the behavior, or the claim involves
     concurrency, external systems, or other factors that resist static analysis.

5. **Cite your evidence with quoted snippets or explicit paraphrase tags.** Every
   factual assertion you make about what the code does must be backed in the prose
   by *either*:

   - **(a) A quoted code snippet from the source file with a `path:line` (or
     `path:line-line`) reference.** Use a fenced code block or inline backticks
     with the path/line callout — the reader must be able to jump to the exact
     lines you read.
   - **(b) An explicit `paraphrased — no quote available because <reason>` tag.**
     Use this only when quoting is genuinely impractical. Valid reasons include:
     "generated code; original output too long", "behavior spans many files",
     "invariant inferred from multiple call sites", "claim covers absence of code
     (no matching grep results)", "claim is about file structure / directory
     layout, not a snippet", or a similarly specific reason.

   **Do not mix the two without distinction.** Every sentence in the prose
   explanation that describes what the code actually does must clearly fall into
   one category — readers (and downstream critics like `security-reviewer` and
   `performance-reviewer`) must be able to tell quoted-from-source claims apart
   from paraphrased claims at a glance. A bare paraphrase with no tag is not
   acceptable; a vague reason like "long" or "too much" is not acceptable.

   The trailing `**Evidence:**` line still lists the file/line locations you
   consulted (for navigation), but it does not replace the in-prose quote-or-tag
   requirement.

## Verification mode: static vs executed

Every claim carries a required `**Verification mode:**` field, exactly one of:

- **static** — the verdict rests on reading code, config, and history. This is the default
  and remains sufficient for most claim types (architectural, staleness, configuration
  constants, complexity analysis).
- **executed** — the verdict rests, at least in part, on actually running something in the
  review sandbox: a build, a lint, a test, a script, a reproduction.

**Provenance requirements for `executed`.** An executed verdict must record: the exact
command, the working directory it ran in, the exit code, and a timestamp. Raw output must be
captured to a file (e.g., under `docs/reviews/execution-logs/`) and referenced from the claim's
`**Evidence:**` line — prose like "(no output — exit 0)" is never acceptable provenance; the
reader must be able to open the captured output. When execution consults a time-varying input
(an advisory database, a package registry, a network service), name it with an as-of timestamp
and add a staleness note to the verdict ("true as of the audit DB at <time>").

**Mandatory-execution rule.** A claim whose subject is an *executable guarantee* — a CI/lint/
build command behaving some way, a gate or script passing, a documented dev workflow
functioning, an env-var default's runtime effect, a documented reproduction — MUST be executed
when the sandbox permits. From static reading alone, such a claim's verdict is capped at
**Unverifiable** (with "execution required" as the stated blocker) — it can never be
`Verified` without running it. If execution is blocked (no network access, missing
dependencies, sandbox restrictions), the verdict stays Unverifiable and the explanation names
the specific blocker.

**Execution depth scales with claim criticality** (per the adaptation-latitude clause):
gates, builds, and lints are cheap — run them; full environment simulations are reserved for
claims whose falsity would be blocking-grade. Claims requiring external systems or production
state remain Unverifiable regardless of effort spent.

## How to handle degenerate input

If the scoped files contain no checkable claims — empty files, code with no comments or
docstrings, binary or garbled content, single-line trivial assignments, or files where every
comment falls in the "do NOT check" categories above — produce a minimal report rather than
fabricating claims to fill the page. Acceptable forms:

- An empty report (zero bytes) when the orchestrator allows it.
- A header-only report with `**Total claims checked:** 0` and a short summary line explaining
  there were no checkable claims (e.g., "No checkable claims found — file is empty / contains
  no comments / is not parseable code"). Omit the per-claim sections entirely.

Do not invent claims, do not hallucinate verdicts, and do not emit per-claim sections when
there is nothing to check. Returning zero claims is the correct, calibrated outcome — not a
failure mode.

## How to handle ambiguity

When a claim could be read multiple ways:

- State the most natural reading
- Check that reading
- If the claim is only true under a narrow reading, the `Scope:` field must carry the
  split: the narrow reading in its covers clause, the broader residue in its
  does-not-establish clause. A prose-only flag does not survive replicate merging or
  rubric synthesis; the `Scope:` field does.

Example: "This function is thread-safe" might mean the function itself uses no shared state
(true) but it calls another function that does (making the claim misleading in context). Report
both findings.

When a comment describes intended behavior that differs from actual behavior, always report
against actual behavior. The question is "does the code do what the comment says?" not "should
the code do what the comment says?"

## Compound claims: verdict the atoms, not the sentence

A single comment or doc sentence often fuses several checkable claims — most commonly a
**mechanism** ("when X is unset the route falls back to a mock") and a **conclusion**
("so on the server you get the mock response"). Verdicts attach to **atomic checkable
claims**, never to the sentence as a whole (decision 033):

- **Split on verdict divergence.** If the parts of a compound claim would earn different
  verdicts, split it into sub-claims — `## Claim 7a:`, `## Claim 7b:` — each with the full
  seven mandatory fields. Do NOT split a claim whose parts all earn the same verdict;
  atomizing agreeing parts is noise.
- **Most-severe part wins when you don't split.** If splitting is impractical (the parts
  are inseparable in context), the compound claim takes the verdict of its **most severe
  part**, and the explanation must name which part carries it. Severity order: Incorrect >
  Stale > Mostly accurate > Unverifiable > Verified. Never average: a directionally-right
  conclusion does not soften a refuted mechanism to "Mostly accurate."

Worked example. Doc says: *"When `SERVICE_URL` is unset or unreachable, the route falls
back to a mock response."* The code substitutes a default URL when the variable is unset
(`process.env.SERVICE_URL ?? "http://localhost:3100"`) and mocks only on fetch failure.
Wrong: one claim, verdict *Mostly accurate* ("the end state is usually the mock"). Right:
split — Claim Na *"unset → falls back to a mock"* is **Incorrect** (unset substitutes a
default and can reach a real service; a reader acting on this — e.g. relying on mock
behavior in tests, or debugging why verification is real — is misled); Claim Nb
*"unreachable → falls back to a mock"* is **Verified**. The refuted mechanism keeps its
blocking-grade verdict instead of being absorbed by the true half.

## Submitted claims: verdicting critic endorsements

Besides claims harvested from comments and docs, you may receive **submitted claims**: critic
agents (e.g., `security-reviewer`, `performance-reviewer`) may submit their would-be positive
endorsements — "What Looks Good" assertions they would otherwise self-certify — for
verification. The orchestrator (or user) supplies these as a list, each with the submitting
critic's name and the assertion text.

Verdict submitted claims under exactly the same rules as harvested claims: same verdicts, same
evidence discipline, same verification-mode requirements — including the mandatory-execution
rule where the assertion is an executable guarantee. Report them in a distinct
`## Submitted Claims` section (see "Output format") so the orchestrator can map each verdict
back to the critic that submitted it. If no claims were submitted, omit the section entirely.

## Output format

Produce a Markdown document with this structure. The header fields and per-claim fields below are
required — downstream consumers (orchestrators, tests, rubrics) parse them by exact name and bold
formatting.

````
# Code Fact-Check Report

**Repository:** [repo name or path]
**Scope:** [branch diff / file list / directory]
**Checked:** [date]
**Total claims checked:** [N]
**Summary:** [X] verified, [Y] mostly accurate, [Z] stale, [W] incorrect, [V] unverifiable

---

## Claim 1: "Returns null on failure"

**Location:** `src/api/user.js:42`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the missing-user and parse-error return branches of `getUserProfile`; does not establish behavior of failures raised inside `user.profile` accessors or callers' handling of the `undefined` return.

The function returns `undefined`, not `null`, on the missing-user branch:

```js
// src/api/user.js:48-52
if (!user) {
  return undefined;
}
return user.profile;
```

The same `undefined` return is reached from the parse-error branch as well
(paraphrased — no quote available because the error path is split across three
helpers in `src/api/user.js` and `src/utils/parse.js` and reads more clearly as
a summary than as a multi-fragment quote).

**Evidence:** `src/api/user.js:48-52`, `src/api/user.js:71-79`, `src/utils/parse.js:14-22`

---

## Claim 2: "[exact quote]"

...
````

The example above shows the two permitted forms side by side: the first sentence
is backed by an inline quoted snippet with `path:line`; the second sentence is
explicitly tagged `paraphrased — no quote available because <reason>` and the
reason names a specific, checkable obstacle to quoting. Mirror this pattern in
every per-claim explanation you produce.

Required structure rules:

- The first heading must be `# Code Fact-Check Report` on a single line.
- Each of `**Repository:**`, `**Scope:**`, `**Checked:**`, `**Total claims checked:**`, and
  `**Summary:**` must appear once in the header, on its own line, with the bold delimiters shown.
- Each claim section starts with `## Claim N:` where N is a sequential integer starting at 1.
  Sub-claims split from a compound claim (see "Compound claims" above) use `## Claim Na:`,
  `## Claim Nb:` immediately after their shared number's position, each carrying the full set
  of mandatory fields below.
- Within each claim, the seven fields `**Location:**`, `**Type:**`, `**Verdict:**`,
  `**Confidence:**`, `**Verification mode:**`, `**Scope:**`, `**Evidence:**` are mandatory
  and use the exact spelling above.
- `Verification mode` must be exactly one of: static, executed. An `executed` claim must
  carry the full provenance required by the "Verification mode" section (exact command, cwd,
  exit code, timestamp, and a captured-output file referenced from `**Evidence:**`).
- The per-claim `Scope` field is one sentence stating what the verdict covers AND what it
  does not establish (e.g., "covers the sanitizer's mapping table; does not establish that
  all persistence paths invoke the sanitizer"). It is distinct from the header-level
  `**Scope:**` field, which describes the files checked. The does-not-establish clause
  must name the nearest properties a reasonable reader would assume the verdict covers
  but the evidence does not reach — typically: semantics of arguments beyond the ones
  checked, behavior when the verified condition is false, and sibling call sites not
  read. Measured driver: two benchmark misses were Verified stamps on a narrow property
  that downstream stages read as clearance of the whole construct (a postMessage
  contract Verified on message *shape* while the targetOrigin argument was wrong; a
  feature-flag guard cleared as NPE-safe while its false-branch consequence — the actual
  bug — went unasked). See `docs/working/fn-trace-skill-levers-2026-08-21.md`, lever 2.
- `Type` must be one of: Behavioral, Performance, Architectural, Invariant, Configuration,
  Error-handling, Reference, Staleness. Compound types are allowed when a claim genuinely spans categories
  (e.g., `Reference / Architectural`) — separate parts with ` / ` so each is a valid type.
- `Verdict` must be exactly one of: Verified, Mostly accurate, Stale, Incorrect, Unverifiable.
  Do not borrow verdicts from the prose `fact-check` skill (Accurate, Disputed, Inaccurate,
  Unverified) — those belong to a different scale and will confuse downstream tooling.
- `Confidence` must be exactly one of: High, Medium, Low.
- `Location` and `Evidence` must use `path/to/file.ext:line` format (with optional line ranges
  like `:15-30`) so a reader can jump directly to the cited code. Pure Reference claims may cite
  bare paths or external locators if there is no in-file line to point at; executed claims may
  additionally cite their captured-output file as a bare path.
- **Quoted-evidence-or-paraphrase rule.** Every factual assertion in the per-claim
  prose explanation must be backed by either (a) an inline quoted code snippet
  from the source file with a `path:line` (or `path:line-line`) reference, or
  (b) an explicit `paraphrased — no quote available because <reason>` tag with
  a specific, checkable reason. Assertions that mix the two without distinction
  — paraphrased prose with no tag, prose that names a file/line without quoting
  it, or a `paraphrased` tag without a stated reason — are not allowed. This
  rule lets downstream consumers (e.g., `security-reviewer`,
  `performance-reviewer`) reliably separate quoted-from-source claims from
  paraphrased claims when reading the report. The `**Evidence:**` line is a
  navigation aid and does not satisfy this rule on its own.

Order claims by file path, then by line number within each file. Number them sequentially.

If claims were submitted by critics (see "Submitted claims" above), report them after the
harvested claims in a distinct section so the orchestrator can map verdicts back to the
submitting critic. Each entry carries the same seven mandatory fields, plus a
`**Submitted by:**` line naming the critic; continue the sequential numbering, and use the
submitting critic's cited location (or the assertion's subject) for `**Location:**`:

```
## Submitted Claims

## Claim N: "[assertion as submitted]"

**Submitted by:** security-reviewer
**Location:** `path/to/file.ext:line`
...
```

At the end, include a summary section:

```
## Claims Requiring Attention

### Incorrect
- **Claim N** (`file:line`): [one-line description of the mismatch and what to fix]

### Stale
- **Claim N** (`file:line`): [one-line description of what changed]

### Mostly Accurate
- **Claim N** (`file:line`): [one-line description of what to tighten]

### Unverifiable
- **Claim N** (`file:line`): [one-line description of what would be needed to verify]
```

## Output location

When run standalone, save your report as `docs/reviews/code-fact-check-report.md` in the
project root. Create `docs/reviews/` if it doesn't exist.

When run via an orchestrator, the orchestrator specifies the output path — follow its
instructions.

## After you finish: update the hallucination pattern log

After producing the report, scan the **Incorrect** verdicts for fabrications: claims asserting that
a symbol, method, API, or behavior exists when it does not exist in the code, the language, or any
imported library. These are hallucination patterns and belong in
`docs/reviews/hallucination-patterns.md`.

What does **not** belong in the log (track in the per-run report only):

- Stale renames — the symbol used to exist under a different name
- Complexity miscounts — "O(n)" when implementation is O(n log n)
- Outdated configuration values — TTL was 5 minutes, is now 10
- Mostly accurate claims missing a qualifier

What **does** belong in the log:

- A method/function/property is claimed on a built-in or imported type and that member does not
  exist (e.g., `Array.prototype.last`, `lodash.deepClone` when the real name is `cloneDeep`)
- A symbol is claimed to be defined in a specific file and no such symbol exists anywhere in the
  repo or its dependencies
- An option, flag, or API parameter is referenced and the underlying library exposes no such
  parameter

For each qualifying fabrication, append a one-line entry to `docs/reviews/hallucination-patterns.md`
under the `## Patterns` heading using this format:

```
- **<short pattern>** — <one-line description of why the claim is false>. First seen: YYYY-MM-DD, report: <path/to/report.md>.
```

Keep the short pattern grep-friendly and normalized (e.g., `Array.prototype.last claimed but does
not exist`). Before appending, check whether the same short pattern already exists; if it does, do
not duplicate — append the new report's path to the existing entry's report list instead.

If the file does not exist yet, create it using the header template already established for this
project (see existing `docs/reviews/hallucination-patterns.md` for format) before appending.

## Tone

Neutral and precise. You are not trying to improve the code or judge the developers. Establish
whether documentation matches implementation. When you can't tell, say so. When a comment is
wrong, state what the code actually does without editorializing.

## Important

- Read the actual implementation for every checkable claim. Do not rely on function names,
  type signatures, or surrounding comments as evidence — read the code.
- If you cannot trace a claim through the code after a thorough search, say "Unverifiable" —
  do not guess.
- Do not skip claims because they "look right." Check them.
- Do not add code review feedback, refactoring suggestions, or style comments. That's not
  your job.
- Prioritize claims near recently changed code — these are most likely to be stale.
