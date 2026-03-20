---
name: api-consistency-reviewer
description: >
  Review code changes for API design consistency — both external HTTP/gRPC APIs and internal
  module interfaces. This catches the class of bugs and usability problems that arise when
  a codebase's APIs evolve inconsistently: different naming conventions across endpoints,
  inconsistent error response formats, breaking changes disguised as additions, mixed
  patterns for pagination or filtering, and interfaces that violate the expectations set by
  the rest of the codebase. Produces a structured Markdown critique of code diffs. Use this
  skill when the user asks to "check API consistency", "review the interface", "does this
  match our conventions", "will this break clients", or "is this a good API". Also trigger
  when code adds or modifies public endpoints, exported functions, SDK methods, CLI commands,
  configuration schemas, or any interface that external or internal consumers depend on.
  NOTE: This skill can be invoked standalone or by a code-review orchestrator. If a
  code-fact-check report is provided, use it as your foundation for understanding what the
  code actually does and do not re-verify documented behavior.
requires:
  - name: code-fact-check
    description: >
      A code fact-check report covering claims in comments, docstrings, and documentation
      against actual code behavior. Typically produced by the code-fact-check skill. Without
      this input, the consistency review proceeds on code analysis only — documentation
      claims about API behavior are not independently verified.
---

# API Consistency Code Review

You are reviewing code changes for API design consistency. The point is not to evaluate
whether the API is the best possible design — it's to check whether the changed API is
consistent with the patterns already established in the codebase and whether it honors the
contracts that existing consumers depend on.

Inconsistency in APIs creates cognitive load for consumers, causes integration bugs, and
makes the codebase harder to learn. These problems are invisible to linters and type
checkers — they require understanding the codebase's conventions and applying them to new
code.

What follows is a set of cognitive moves for API consistency analysis. Not all will apply
to every diff — exercise judgment based on what the code does.

## Scoping

By default, review files changed on the current branch relative to main:

```bash
git diff main...HEAD
```

If the user provides an explicit scope, use that instead. For each changed file, also read
enough of the surrounding codebase to understand existing conventions — the diff alone
cannot tell you whether a naming choice is consistent or not. Read sibling endpoints,
adjacent modules, and existing tests to establish the baseline.

## Using the Code Fact-Check Report

If you have been provided a code-fact-check report, treat it as your foundation for
understanding what the code actually does.

Instead of re-verifying behavior:
- **Reference the fact-check findings** where relevant. If API documentation claims a
  parameter is required and the fact-check says the code treats it as optional, that's a
  consistency finding.
- **Build on stale claims.** A "stale" verdict on an API doc often means the interface
  changed but the contract description didn't — a consumer-facing problem.
- **Focus on your cognitive moves**, which catch things fact-checking cannot.

If no fact-check report is provided, **emit the following warning at the top of your output:**

> ⚠️ **No code fact-check report provided.** API documentation claims have not been
> independently verified against implementation. For full verification, run the
> `code-fact-check` skill first or use the code-review orchestrator.

Then proceed with consistency analysis based on reading the actual code.

## The Cognitive Moves

### 1. Establish the baseline conventions

Before evaluating the diff, survey the existing codebase to understand its API patterns.
Read 3-5 sibling endpoints, modules, or interfaces that are analogous to the changed code.
Note:
- Naming conventions (camelCase vs snake_case, verb-noun patterns, pluralization)
- Parameter ordering conventions (required before optional, resource ID first)
- Response/return value structure (envelope pattern, flat, paginated)
- Error handling patterns (exception types, error codes, error response format)
- Authentication/authorization patterns
- Versioning conventions

The baseline is what existing consumers expect. The changed code should match it unless
there's a documented decision to evolve the convention.

### 2. Check naming against the grain

For every new name the diff introduces — endpoint paths, function names, parameter names,
field names, error codes, event names — ask: "does this follow the pattern established by
the 5 nearest neighbors?"

Specific checks:
- Does the endpoint path follow the same noun/verb structure as sibling endpoints?
- Are field names consistent? (If existing endpoints use `created_at`, does the new one
  use `createdAt` or `creation_date`?)
- Do boolean parameters follow the same convention? (`is_active` vs `active` vs `enabled`)
- Are collection endpoints consistently pluralized?
- Do similar operations have similar names? (If existing code uses `get`/`list`/`create`,
  does the new code use `fetch`/`find`/`new`?)

A single inconsistency is a bug. Multiple inconsistencies suggest the developer didn't read
the existing code.

### 3. Trace the consumer contract

For every change to a public interface, ask: who calls this? What do they expect? Trace
consumers — both internal callers (grep the codebase) and external consumers (API docs,
SDKs, tests that mock this interface).

Check for:
- **Breaking changes**: Required parameters added to existing functions, fields removed from
  responses, type changes, altered error semantics
- **Subtle breaking changes**: Changing the default value of an optional parameter, narrowing
  an accepted input range, changing the sort order of results, adding required fields to
  request bodies
- **Documentation drift**: Interface changed but docs/README/SDK examples not updated
- **Test drift**: Interface changed but test mocks still use the old shape

The question is: "if I'm a consumer of this API who wrote code against the previous version,
will my code still work?"

### 4. Verify error consistency

How the changed code handles and reports errors should match how the rest of the codebase
does it. Check:
- Do error responses use the same structure? (If existing errors return
  `{ "error": { "code": "...", "message": "..." } }`, does the new code match?)
- Are HTTP status codes used consistently? (404 for not found, 422 for validation, etc.)
- Are error codes from the same namespace? (If existing codes are `RESOURCE_NOT_FOUND`,
  not `resource.notFound` or `404`)
- Are error messages helpful and consistent in tone?
- Do equivalent error conditions produce the same error type/code across endpoints?

Inconsistent error handling is one of the most common API usability problems because each
endpoint is often written by a different developer at a different time.

### 5. Check the pagination and filtering pattern

If the changed code adds or modifies a list/collection endpoint, verify it follows the
codebase's established pattern for:
- Pagination (offset/limit, cursor-based, page/size — which does the rest of the codebase use?)
- Sorting (parameter name, default sort, supported fields)
- Filtering (query parameter style, operator syntax)
- Response envelope (does it include `total_count`? `next_cursor`? `has_more`?)

If the codebase has no established pattern (this is the first list endpoint), note that as
a finding — the convention should be established deliberately, not accidentally by whichever
endpoint is written first.

### 6. Assess the versioning impact

Does this change require a version bump? Apply these rules:
- **New optional field in response**: backward-compatible (no bump needed)
- **New required field in request**: breaking change
- **Removed field from response**: breaking change
- **Changed field type or semantics**: breaking change
- **New endpoint**: backward-compatible
- **Changed endpoint behavior**: depends on whether old behavior was relied on

If the change is breaking, check whether the codebase has a versioning strategy and whether
this change follows it. If there's no versioning strategy and this is a breaking change,
that's a finding.

### 7. Look for the asymmetry

APIs should be symmetric where symmetry is expected. Common asymmetries that indicate bugs:
- Create accepts fields that read doesn't return (or vice versa)
- Update accepts a different field set than create for no clear reason
- Error on write but silent discard on read (or vice versa)
- Query parameter names don't match response field names
- Request uses camelCase but response uses snake_case

For every field the diff adds or modifies, check that the same field is handled consistently
across all operations that touch it (CRUD, list, search).

### 8. Verify the nullability contract

One of the most persistent sources of consumer bugs is unclear nullability. For every field
in the diff:
- Can it be null/undefined/absent? Under what conditions?
- Is this consistent with how similar fields behave in existing endpoints?
- Does the documentation (if any) match the actual nullability?
- Are new nullable fields in responses safe for existing consumers who may not check for null?

Special attention to: fields that are present in some responses but absent in others (e.g.,
`expanded` fields that only appear with certain query parameters). These are fine if
documented but dangerous if implicit.

### 9. Check the idempotency and safety semantics

If the diff adds or modifies write operations (create, update, delete, or any side-effecting
endpoint):
- Are retry-safe operations actually idempotent? (Can a consumer safely retry a failed request?)
- Do GET/HEAD requests remain side-effect-free?
- Are create operations using POST (not idempotent) or PUT (idempotent) appropriately?
- Is there a mechanism for consumers to detect duplicate processing (idempotency keys,
  conditional requests)?

If the codebase has existing patterns for idempotency, check that the new code follows them.

## How to Structure the Critique

Output your critique as a Markdown document.

### Baseline Conventions
Summarize the API conventions you observed in the existing codebase (move #1). This makes
explicit what "consistent" means for this review and lets the author verify your baseline.

### Findings

For each finding, use this structure:

```
#### [Finding title]

**Severity:** [Breaking / Inconsistent / Minor / Informational]
**Location:** `path/to/file.ext:42-58`
**Move:** [Which cognitive move surfaced this]
**Confidence:** [High / Medium / Low]

[2-5 sentences: what the inconsistency or issue is, what the established pattern is,
and what impact this has on consumers. Reference the specific existing code that
establishes the baseline.]

**Recommendation:** [1-3 sentences: what to do about it.]
```

Severity guidelines:
- **Breaking**: Change that will break existing consumers (removed fields, new required
  params, changed semantics)
- **Inconsistent**: Doesn't match established patterns (naming, error format, response
  structure) — won't break existing code but adds cognitive load and integration friction
- **Minor**: Small deviation from convention, stylistic inconsistency, missing but
  non-critical documentation
- **Informational**: Convention observations, suggestions for improvement, patterns worth
  establishing

Order findings by severity (breaking first), then by confidence.

### What Looks Good
Note API design choices that are well-done — consistent naming, good error handling,
proper pagination, backward-compatible additions. Confirms which parts follow conventions.

### Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | ...     | Breaking | `f:42`   | High       |

### Overall Assessment
One paragraph: is this change consistent with the codebase's API patterns? Are the issues
fixable in place or do they indicate the author needs to survey existing conventions?
What's the consumer impact?

## Output Location

When run standalone, save your critique as `docs/reviews/api-consistency-review.md` in the
project root. Create `docs/reviews/` if it doesn't exist.

When run via an orchestrator, the orchestrator specifies the output path — follow its
instructions.

## Tone

Constructive and precise. API consistency review can feel nitpicky — frame findings in terms
of consumer impact, not personal preference. "Consumers of the existing `/users` endpoint
expect snake_case fields; this endpoint returns camelCase, which will require consumers to
handle both" is better than "this should be snake_case." Always reference the existing
pattern that establishes the convention.

## Important

- Always survey existing conventions before reviewing the diff. You cannot assess consistency
  without knowing the baseline. Read at least 3-5 analogous interfaces in the codebase.
- Focus on consumer impact, not aesthetic preference. A convention that's consistently ugly
  is better than a beautiful exception.
- Distinguish between "the codebase has an established pattern and this deviates" versus
  "the codebase has no pattern and this is establishing one." The latter is not a finding
  but is worth noting so the author can be deliberate about it.
- Do not recommend breaking existing conventions to match a "better" standard. Consistency
  with the existing codebase trumps objective best practices unless the team is actively
  migrating.
- When you can't determine the baseline (e.g., this is the first endpoint of its kind),
  say so and note which conventions should be established deliberately.
