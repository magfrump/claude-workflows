---
name: api-consistency-reviewer
description: >
  Review code changes for API design consistency across the surfaces that consumers actually
  bind to: HTTP/REST endpoints, gRPC services, GraphQL schemas, SDK methods, exported library
  functions, CLI commands and flags, configuration schemas, event payloads, and any other
  interface that internal or external callers depend on. Catches the bugs and usability
  problems that come from APIs evolving inconsistently — mixed naming conventions
  (snake_case vs camelCase, get vs fetch, plural vs singular), inconsistent error response
  formats, breaking changes disguised as additions, divergent pagination/filtering patterns,
  request/response field asymmetries, and interfaces that quietly violate the expectations
  the rest of the codebase has already established. Produces a structured Markdown critique
  of code diffs with a name-pattern audit that compares every new public name against its
  closest existing neighbors. Use this skill when the user asks to "check API consistency",
  "review the interface", "does this match our conventions", "will this break clients",
  "is this a good API", "audit endpoint naming", "check the SDK surface", or "compare to
  sibling endpoints". Also trigger whenever a diff adds or modifies a public endpoint,
  exported function/method/class, SDK method, CLI command or flag, config field, event
  schema, or any consumer-facing contract — even when the user did not explicitly ask for
  an API review. Distinct from architecture-review (which evaluates SOLID, dependency
  direction, and module boundaries) and security-reviewer (which evaluates trust boundaries
  and exploitability) — this skill evaluates whether the new surface matches the conventions
  consumers have already learned. NOTE: This skill can be invoked standalone or by a
  code-review orchestrator. If a code-fact-check report is provided, use it as your
  foundation for understanding what the code actually does and do not re-verify documented
  behavior.
when: Code adds or modifies APIs, endpoints, or public interfaces
requires:
  - name: code-fact-check
    description: >
      A code fact-check report covering claims in comments, docstrings, and documentation
      against actual code behavior. Typically produced by the code-fact-check skill. Without
      this input, the consistency review proceeds on code analysis only — documentation
      claims about API behavior are not independently verified.
---

> On bad output, see guides/skill-recovery.md

# API Consistency Code Review

Reviewing code changes for API design consistency. Don't evaluate whether the API is the best
possible design — check whether the changed API is consistent with patterns already established
in the codebase and whether it honors the contracts existing consumers depend on.

API inconsistency creates consumer cognitive load, causes integration bugs, and makes the
codebase harder to learn. Linters and type checkers can't see these problems — they require
understanding the codebase's conventions and applying them to new code.

Below: cognitive moves for API consistency analysis. Not all apply to every diff — judge by
what the code does.

## Scoping

By default, review files changed on the current branch relative to main:

```bash
git diff main...HEAD
```

If the user provides explicit scope, use that instead. For each changed file, read enough
surrounding codebase to understand existing conventions — the diff alone cannot tell you
whether a naming choice is consistent. Read sibling endpoints, adjacent modules, and existing
tests to establish the baseline.

## Using the Code Fact-Check Report

If provided a code-fact-check report, treat it as your foundation for understanding what the
code actually does.

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

Before evaluating the diff, survey the existing codebase for its API patterns. Read 3-5
sibling endpoints, modules, or interfaces analogous to the changed code. Note:
- Naming conventions (camelCase vs snake_case, verb-noun patterns, pluralization)
- Parameter ordering conventions (required before optional, resource ID first)
- Response/return value structure (envelope pattern, flat, paginated)
- Error handling patterns (exception types, error codes, error response format)
- Authentication/authorization patterns
- Versioning conventions

The baseline is what existing consumers expect. The changed code should match it unless
there's a documented decision to evolve the convention.

### 2. Check naming against the grain

For every new name the diff introduces — endpoint paths, function names, type/class names,
parameter names, field names, error codes, event names, enum variants — ask: "does this
follow the pattern established by the nearest neighbors?"

Specific checks:
- Does the endpoint path follow the same noun/verb structure as sibling endpoints?
- Are field names consistent? (If existing endpoints use `created_at`, does the new one
  use `createdAt` or `creation_date`?)
- Do boolean parameters follow the same convention? (`is_active` vs `active` vs `enabled`)
- Are collection endpoints consistently pluralized?
- Do similar operations have similar names? (If existing code uses `get`/`list`/`create`,
  does the new code use `fetch`/`find`/`new`?)
- Do new types follow existing suffix/prefix conventions? (If existing types are bare
  nouns like `User`, `Session`, does the new one introduce `UserDTO` or `IUser`?)

A single inconsistency is a bug. Multiple inconsistencies suggest the developer didn't read
the existing code.

#### Precedent citation requirement (every naming finding)

A naming finding is only meaningful if there's an established pattern to be inconsistent
with. To make every naming finding auditable from the report content alone, each one
**must** include one of these two literal lines in its body:

- `Precedent: <pattern> used in <file path or path glob>` — the established pattern and
  where a reader can verify it (concrete path like `src/api/users.ts:42` or a glob like
  `src/api/**/*.ts`). Cite at least one; cite more when multiple sibling files reinforce
  the pattern.
- `No existing precedent in <searched scope>` — explicit statement that you looked and
  found no analog. The `<searched scope>` must name what you actually grepped or listed
  (e.g., `src/api/`, `all *.proto files`, `exported names in lib/`). Vague scopes like
  "the codebase" are not acceptable.

A naming finding lacking both lines is malformed. A reader must be able to grep for
either `^Precedent:` or `^No existing precedent in` in the finding to confirm the rule
was followed.

**Severity downgrade when no precedent exists.** If a finding uses the `No existing
precedent in ...` line, drop its severity by one tier from what move #2 or the audit
table would otherwise have assigned:

- Breaking → Inconsistent
- Inconsistent → Minor
- Minor → Informational
- Informational → Informational (already at the floor; keep, but note the floor was hit)

Rationale: without a precedent, the strongest claim available is "this is establishing a
new convention" — which is informational at best, not a violation of existing
expectations. The downgrade keeps the finding in the report (so the author can be
deliberate about the convention being set) without overstating its severity.

Findings that surface via move #7 (asymmetry) and are naming-shaped — e.g., "request
field is `userId` but response field is `user_id`" — are also naming findings and must
follow this rule. Non-naming findings (error envelope structure, pagination semantics,
nullability) are governed by their own moves and do not require the precedent line.

#### Name-pattern audit (required)

For every new public name in the diff, run this concrete procedure and surface the results
in your critique:

1. **Enumerate the new names**, grouped by category — routes, functions/methods, types/classes,
   enum variants, fields, parameters, error codes, event names. Skip purely private locals.
2. **Find the 2-3 closest existing names** in the same category. "Closest" means: same
   subsystem, same kind of operation, same domain noun, or otherwise the most analogous
   names a future reader would reach for first. Use the codebase's index — grep for sibling
   files, list exports from the same module, search for the same domain noun across the
   repo. If the category has no existing members (this is the first of its kind), say so
   explicitly.
3. **Record the precedent path** for each row — the file path or path glob where the
   closest existing names live. This is the same citation that will appear in any Finding
   expanded from the row, so capturing it here once avoids re-doing the search. If no
   neighbors exist, record `none — searched <scope>` instead.
4. **Render the comparison as a table** so the inconsistency is visible at a glance. Each
   row pairs one new name with its closest existing neighbors, the precedent path, and a
   one-line verdict.

The audit goes in its own output section (see "How to Structure the Critique" below) and is
expected for any diff introducing new public names. If the diff genuinely introduces no new
public names (e.g., an internals-only refactor that still touches a file under review), state
that explicitly under the Name-Pattern Audit heading rather than skipping the section.
Inconsistencies surfaced here become Findings under the rules in move #2; consistent names get
a brief acknowledgment under "What Looks Good".

**Example output block:**

```markdown
### Name-Pattern Audit

| New name                       | Category | Closest existing                                    | Precedent path                              | Verdict      |
|--------------------------------|----------|-----------------------------------------------------|---------------------------------------------|--------------|
| `fetchUserProfile`             | function | `getUserById`, `getUser`, `loadUserSettings`        | `src/services/users/*.ts`                   | Inconsistent — existing read functions use `get`/`load`, not `fetch` |
| `POST /users/sign_up`          | route    | `POST /users`, `POST /sessions`, `POST /orgs`       | `src/routes/{users,sessions,orgs}.ts`       | Inconsistent — existing creates POST to the bare collection; no action-verb sub-paths |
| `UserDTO`                      | type     | `User`, `UserProfile`, `UserSession`                | `src/types/user*.ts`                        | Inconsistent — existing types are bare nouns, no `DTO` suffix |
| `ORDER_STATUS_PENDING_REVIEW`  | enum     | `ORDER_STATUS_PENDING`, `ORDER_STATUS_SHIPPED`, `ORDER_STATUS_CANCELLED` | `src/domain/orders/status.ts:12-24` | Consistent — matches `ORDER_STATUS_<STATE>` shape |
| `idempotency_key`              | param    | `request_id`, `client_token` (closest two; no third analog found) | `src/middleware/dedupe.ts`, `src/api/v2/*.ts` | Inconsistent — existing dedupe params use `_id`/`_token`, not `_key` |
| `WorkflowRunStarted`           | event    | _(no existing workflow events found — first of its kind)_ | none — searched `src/events/**` and `*.proto` | New category — note the convention being established |
```

A single row should fit on one line where possible; wrap the verdict if needed. If the diff
introduces more than ~15 new names, group by category and audit the most public/visible ones
first (routes > exported types > exported functions > internal helpers).

### 3. Trace the consumer contract

For every change to a public interface, ask: who calls this? What do they expect? Trace
consumers — internal callers (grep the codebase) and external consumers (API docs, SDKs, tests
that mock this interface).

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

The changed code's error handling and reporting should match the rest of the codebase. Check:
- Do error responses use the same structure? (If existing errors return
  `{ "error": { "code": "...", "message": "..." } }`, does the new code match?)
- Are HTTP status codes used consistently? (404 for not found, 422 for validation, etc.)
- Are error codes from the same namespace? (If existing codes are `RESOURCE_NOT_FOUND`,
  not `resource.notFound` or `404`)
- Are error messages helpful and consistent in tone?
- Do equivalent error conditions produce the same error type/code across endpoints?

Inconsistent error handling is one of the most common API usability problems, because each
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

For every field the diff adds or modifies, check the same field is handled consistently
across all operations that touch it (CRUD, list, search).

### 8. Verify the nullability contract

Unclear nullability is one of the most persistent sources of consumer bugs. For every field
in the diff:
- Can it be null/undefined/absent? Under what conditions?
- Is this consistent with how similar fields behave in existing endpoints?
- Does the documentation (if any) match the actual nullability?
- Are new nullable fields in responses safe for existing consumers who may not check for null?

Special attention: fields present in some responses but absent in others (e.g., `expanded`
fields that only appear with certain query parameters). Fine if documented, dangerous if
implicit.

### 9. Check the idempotency and safety semantics

If the diff adds or modifies write operations (create, update, delete, or any side-effecting
endpoint):
- Are retry-safe operations actually idempotent? (Can a consumer safely retry a failed request?)
- Do GET/HEAD requests remain side-effect-free?
- Are create operations using POST (not idempotent) or PUT (idempotent) appropriately?
- Is there a mechanism for consumers to detect duplicate processing (idempotency keys,
  conditional requests)?

If the codebase has existing patterns for idempotency, check the new code follows them.

## How to Structure the Critique

Output your critique as a Markdown document.

### Title and Header

Open with a top-level title including "API Consistency Review" so the report is discoverable.
Follow with these header fields so readers know what was reviewed and when:

```markdown
# API Consistency Review — [short scope label, e.g., PR #347 or branch name]

**Scope:** [branch diff / file list / directory under review]
**Date:** [YYYY-MM-DD]
```

If given a fact-check report or other upstream artifact, add a `**Based on:**` line naming it.
Keep the header to 3–5 lines; the substance belongs in the sections below.

### Baseline Conventions
Summarize the API conventions you observed in the existing codebase (move #1). This makes
explicit what "consistent" means for this review and lets the author verify your baseline.

### Name-Pattern Audit
Render the table from move #2. Every new public name in the diff appears as a row with its
2-3 closest existing neighbors and a one-line verdict. This section is required even when
all names are consistent — the table is the evidence that you actually surveyed neighbors
rather than eyeballing. Inconsistent rows get expanded into Findings below.

### Findings

For each finding, use this structure:

```
#### [Finding title]

**Severity:** [Breaking / Inconsistent / Minor / Informational]
**Location:** `path/to/file.ext:42-58`
**Move:** [Which cognitive move surfaced this]
**Confidence:** [High / Medium / Low]

[For naming findings only — pick exactly one of:]
Precedent: <pattern> used in <file path or path glob>
[— OR —]
No existing precedent in <searched scope>

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

**Naming finding precedent rule.** Every naming finding (move #2, or naming-shaped
findings surfaced via move #7) must include one of the two literal lines shown in the
template — `Precedent: ...` or `No existing precedent in ...`. When the no-precedent
line is used, downgrade the severity by one tier (Breaking → Inconsistent → Minor →
Informational; Informational stays at the floor). See the "Precedent citation
requirement" sub-section under move #2 for the full rule. A naming finding missing both
lines is malformed and must be fixed before the report is delivered.

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
