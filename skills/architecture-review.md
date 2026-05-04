---
name: architecture-review
description: >
  Review code changes for structural integrity — SOLID principle violations, dependency direction
  problems, module boundary breaches, and coupling issues. This is not a code review for
  implementation quality (security, performance, API consistency) — it focuses on whether a change
  maintains or improves the system's architectural health. Produces a structured Markdown critique
  of code diffs. Invoke this skill ONLY when the diff changes one or more of: (1) module
  structure (new modules, renames, moves, package/directory layout), (2) public APIs (new or
  changed exported types, functions, or interfaces; abstract classes/protocols), (3) data models
  (schemas, DTOs, persisted contracts, message formats consumers depend on), or (4) cross-cutting
  concerns (dependency injection wiring, middleware, auth/authz pipelines, logging/tracing setup,
  caching layers, error-handling pipelines). SKIP this skill when the diff only modifies
  implementation inside an existing module without touching its public surface — internal
  refactors, bug fixes, perf tweaks, test additions, doc updates, and dependency-version bumps
  alone are out of scope. Use this skill when the user asks to "review the architecture", "check
  dependencies", "is this well-structured", "review module boundaries", "SOLID review", "coupling
  analysis", or "dependency direction check". NOTE: This skill can be invoked standalone or by a
  code-review orchestrator. If a code-fact-check report is provided, use it as your foundation
  for understanding what the code actually does and do not re-verify documented behavior.
when: >
  Diff changes module structure, public APIs, data models, or cross-cutting concerns. Skip when
  the diff only modifies implementation inside an existing module.
requires:
  - name: code-fact-check
    description: >
      A code fact-check report covering claims in comments, docstrings, and documentation
      against actual code behavior. Typically produced by the code-fact-check skill. Without
      this input, the architecture review proceeds on code analysis only — architectural claims
      in documentation are not independently verified.
---

> On bad output, see guides/skill-recovery.md

> ## ⚠️ Standalone invocation only — skip if dispatched by an orchestrator
>
> If you were invoked directly by the user (not via `code-review` or another orchestrator
> that prepends a [goal preamble](../patterns/orchestrated-review.md#goal-preamble) with
> `User goal:` / `Current task:` / `Success criterion:` lines), do this **before**
> producing the critique:
>
> 1. **Capture the user's goal in 1-2 sentences.** State it back to confirm; ask one
>    clarifying question only if the request is genuinely ambiguous.
> 2. **Record it verbatim at the top of the report** as a `**User goal:**` line, above
>    the Dependency Map section at the top of the saved artifact. The User-goal anchor
>    must persist in the saved file so downstream readers and tools see what frame the
>    review was produced under.
>
> When an orchestrator has already supplied the goal preamble in your dispatch context,
> skip this section entirely — the User-goal anchor is already pinned upstream.

# Architecture Review

You are reviewing code changes for structural integrity. The point is not to evaluate whether
the code is correct, secure, or performant — those are handled by other critics. Your job is
to apply architectural reasoning to find dependency direction violations, coupling problems,
module boundary breaches, and structural decisions that will make the system harder to change
over time.

Good architecture makes future changes cheaper. Bad architecture makes them expensive even when
every line of code is individually correct. A codebase where every function is well-tested and
secure can still be a nightmare to extend if modules are tightly coupled, dependencies flow in
the wrong direction, and abstractions leak implementation details.

What follows is a set of cognitive moves for architectural analysis. Not all will apply to every
diff — exercise judgment based on what the code does. These are reasoning lenses, not a
compliance checklist.

## Scoping

By default, review files changed on the current branch relative to main:

```bash
git diff main...HEAD
```

If the user provides an explicit scope (file list, directory, or PR number), use that instead.
For each changed file, also read enough surrounding context to understand the module structure,
dependency graph, and architectural layers — a diff alone rarely reveals structural problems.
Read import statements, module boundaries, and the directory structure around changed files.

## Scope Check (run before producing a critique)

Architecture review is a structural lens, not a general code review. Before applying the
cognitive moves, confirm the diff actually changes structure. If none of the four trigger
categories below apply, **skip the review** and emit a short skip note instead (see "Skip path"
below).

### Trigger categories

Invoke this skill only when the diff changes at least one of:

1. **Module structure** — new modules or packages added; existing modules moved, renamed, split,
   or merged; directory/package layout reorganized; new top-level subsystems introduced.
2. **Public APIs** — new exported types, functions, classes, or constants; changes to the
   signatures, contracts, or visibility of existing exports; new or modified abstract classes,
   interfaces, traits, protocols, or other extension points; changes that widen or narrow a
   module's public surface.
3. **Data models** — schema changes (database tables, migrations, ORM models); new or modified
   DTOs, request/response shapes, message/event formats, or other persisted/serialized contracts
   that downstream consumers depend on; changes to identifier semantics, field nullability, or
   cardinality.
4. **Cross-cutting concerns** — dependency injection wiring or composition roots; middleware
   chains; authentication/authorization pipelines; logging, tracing, or telemetry plumbing;
   caching layers; error-handling and retry pipelines; framework lifecycle hooks; configuration
   loading. These are concerns that span multiple modules and whose changes propagate widely.

If at least one category applies, proceed with the review.

### Skip path

If the diff only modifies implementation **inside an existing module** without touching any of
the four trigger categories, skip the review. Examples of work that should be skipped:

- Internal refactors that preserve the public surface (renaming a private helper, extracting a
  local function, inlining a private method).
- Bug fixes that change behavior but not structure or contracts.
- Performance tweaks confined to an algorithm body.
- Test additions, test fixture changes, or test refactors that don't change production code.
- Documentation, comment, or formatting changes.
- Dependency-version bumps without accompanying code changes (these may warrant
  `security-reviewer`, not architecture review).
- Localization, copy, or static-asset changes.

When skipping, output a brief note in place of the full critique:

```
# Architecture Review — Skipped

**Reason:** The diff does not change module structure, public APIs, data models, or
cross-cutting concerns. All changes are implementation-only inside existing modules.

**Files reviewed for scope:** [list]

**Trigger categories evaluated:**
- Module structure: no
- Public APIs: no
- Data models: no
- Cross-cutting concerns: no

If the orchestrator or user believes a structural review is still warranted, re-invoke with
an explicit scope or rationale.
```

Save the skip note to the same path the full critique would have used.

### Edge cases

- **Mixed diffs** — if some files are in scope and others are not, review only the in-scope
  files and note the scoped exclusions in the skip note section of the report.
- **Ambiguous changes** — when uncertain whether a change touches a public API (e.g., a
  package-private symbol that's used across submodules), treat it as in-scope and proceed.
- **New module that is internal-only** — still in scope under "module structure," even if no
  public API is exposed yet; the structural decision is what's being reviewed.

## Using the Code Fact-Check Report

If you have been provided a code-fact-check report alongside the diff, treat it as your
foundation for understanding what the code actually does.

Instead of re-verifying behavior:
- **Reference the fact-check findings** where relevant. If a comment claims "this module has no
  external dependencies" and the fact-check says that's stale, that's an architecture-relevant
  finding you should build on.
- **Focus on structural implications** of fact-check findings. A "mostly accurate" claim about
  module boundaries might indicate architectural drift.
- **Prioritize your cognitive moves**, which are what this skill uniquely provides.

If no fact-check report is provided, **emit the following warning at the top of your output:**

> ⚠️ **No code fact-check report provided.** Architectural claims in comments and documentation
> have not been independently verified. For full verification, run the `code-fact-check` skill
> first or use the code-review orchestrator.

Then proceed with architecture analysis based on reading the actual code.

## The Cognitive Moves

### 1. Map the dependency direction

Before analyzing individual changes, understand which way dependencies flow. In well-structured
systems, dependencies point from volatile (UI, controllers, adapters) toward stable
(domain logic, core abstractions). The Dependency Inversion Principle says high-level modules
should not depend on low-level modules — both should depend on abstractions.

For each changed file, trace its imports and determine:
- What does this module depend on? Are those dependencies more stable or more volatile?
- What depends on this module? Will the change force those dependents to change too?
- Does the change introduce a dependency that flows in the wrong direction — from stable core
  toward volatile periphery, or from domain logic toward infrastructure?

The most damaging architectural changes are ones that reverse dependency direction — making
the core depend on details rather than the other way around. A new import in a domain module
that pulls in a database driver, HTTP client, or UI framework is a red flag regardless of
how cleanly the code is written.

### 2. Assess responsibility boundaries

Each module should have one reason to change (Single Responsibility). When a diff modifies a
module, ask: what is this module's responsibility, and does the change stay within it or expand
it?

Specific checks:
- Does the change add a new concern to a module that previously had a focused responsibility?
  (e.g., adding caching logic to a business rules module, adding logging configuration to a
  domain entity)
- Does the change mix infrastructure concerns with domain logic? (e.g., SQL queries in a module
  that defines business rules, HTTP response formatting in a service layer)
- Does the change make a module depend on information it shouldn't need to know about? (e.g., a
  payment processor that now needs to understand user preferences)

A module accumulating responsibilities is often the first sign of architectural erosion — each
addition seems small, but the compound effect is a module that changes for many unrelated
reasons.

### 3. Audit the module boundary

Every module has a public surface — the set of types, functions, and constants it exposes to
the rest of the system. Changes to this surface ripple outward. For each module touched by the
diff:

- Is the public surface intentional and minimal? Or does the change expose internal details
  that consumers shouldn't depend on?
- Does the change widen the module's interface in a way that increases coupling? (e.g., exposing
  a concrete implementation type instead of an interface)
- Are there things being exported that should be private? Are there internal types leaking into
  public signatures?
- Does the change maintain encapsulation? Can consumers still treat this module as a black box,
  or do they now need to understand its internals?

The test: if you replaced this module's implementation entirely (same interface, different
internals), would the change in the diff make that replacement harder?

### 4. Check for layer violations

Most systems have implicit or explicit architectural layers (e.g., presentation → application →
domain → infrastructure). Each layer should only depend on adjacent layers or on layers below
it.

For each changed file, identify which layer it belongs to, then check:
- Does the change reach across layers? (e.g., a controller directly querying the database,
  a domain entity formatting an HTTP response, a UI component making raw SQL calls)
- Does the change bypass an intermediary layer? (e.g., presentation accessing domain logic
  directly, skipping the application/service layer)
- Does the change push behavior into the wrong layer? (e.g., business rules in a controller,
  validation in the database layer, presentation logic in a domain model)

If the codebase doesn't have explicit layers, identify the implicit layering from the directory
structure and module organization. Note whether the change respects or violates that implicit
structure.

### 5. Evaluate interface segregation

When a diff adds or modifies interfaces (traits, protocols, abstract classes, TypeScript
interfaces), check whether they are role-specific and minimal:

- Does the interface require implementors to provide methods they don't need? (e.g., a
  `Repository` interface with both read and write methods when some consumers only read)
- Does the change add methods to an existing interface that only some implementors will use?
  This forces all implementors to change even if the new method is irrelevant to them.
- Would the interface be better split into smaller, role-specific interfaces that consumers can
  compose?

The signal: if an implementor of this interface has methods that throw `NotImplemented` or
return dummy values, the interface is too broad.

### 6. Verify substitutability

When a diff introduces or modifies subtypes (classes extending a base, implementations of an
interface), check whether the subtype can stand in for the base without surprises (Liskov
Substitution):

- Does the subtype strengthen preconditions? (e.g., base accepts any string, subtype requires
  non-empty — callers that pass empty strings will break)
- Does the subtype weaken postconditions? (e.g., base guarantees sorted output, subtype doesn't
  — callers that depend on ordering will break)
- Does the subtype throw exceptions the base doesn't declare?
- Does the subtype have side effects the base's contract doesn't mention?

This move matters most when the codebase uses polymorphism — if code switches on concrete types
instead of relying on the interface contract, that's a separate finding (violation of OCP).

### 7. Measure the coupling surface

For each cross-module dependency in the diff, assess how tight the coupling is:

- **Data coupling** (good): modules share only simple data through well-defined interfaces
- **Stamp coupling** (acceptable): modules share composite data structures
- **Control coupling** (concerning): one module controls the behavior of another via flags or
  parameters that dictate internal logic
- **Content coupling** (bad): one module reaches into another's internals (accessing private
  state, depending on internal data structures, using reflection to bypass encapsulation)

For new dependencies, ask: if the depended-upon module changes its internals (not its interface),
will this module break? If yes, the coupling is too tight.

Also check for circular dependencies — modules that depend on each other directly or through a
chain. Circular dependencies are architectural debt that makes both modules impossible to
change, test, or deploy independently.

### 8. Evaluate extension points

When a diff adds new behavior or handles new cases, check whether it extends or modifies:

- Does the change add behavior by extending an existing abstraction (new implementation of an
  interface, new subclass, new handler in a registry)? This follows the Open/Closed Principle.
- Does the change modify existing code to handle a new case (adding branches to switch
  statements, if/else chains, special-case checks)? This violates OCP and suggests the code
  isn't structured for extension.
- If modification was necessary, is there a reasonable way the code could be restructured to
  support extension instead? Or is the modification pragmatically appropriate?

Not every OCP violation is worth fixing — be pragmatic. A two-case if/else doesn't need a
strategy pattern. But a switch statement that grows with every new feature type is a structural
problem worth flagging.

## How to Structure the Critique

Output your critique as a Markdown document.

### Dependency Map
Briefly describe the dependency relationships in the changed code (move #1). Which modules
depend on which? Which direction do dependencies flow? This frames the rest of the review.

### Findings

For each finding, use this structure:

```
#### [Finding title]

**Severity:** [Structural / Coupling / Minor / Informational]
**Location:** `path/to/file.ext:42-58`
**Move:** [Which cognitive move surfaced this]
**Confidence:** [High / Medium / Low]

[2-5 sentences: what the structural problem is, why it matters for the system's ability to
evolve, and what the downstream consequences would be if left unaddressed. Be specific about
which modules or boundaries are affected.]

**Recommendation:** [1-3 sentences: what to do about it.]
```

Severity guidelines:
- **Structural**: Dependency inversion violated (core depends on details), layer boundary
  broken, circular dependency introduced, module responsibility fundamentally misplaced.
  These affect the system's ability to evolve and are expensive to fix later.
- **Coupling**: Tight coupling to implementation details, leaky abstraction, module boundary
  violated in a way that increases change propagation, interface too broad. These increase the
  cost of future changes in adjacent modules.
- **Minor**: SRP stretch (responsibility slightly expanded but not fundamentally misplaced),
  interface could be narrower, extension point missed where modification was used. These are
  real but low-impact.
- **Informational**: Pattern observations, opportunities for structural improvement, conventions
  worth establishing. No immediate harm.

Order findings by severity (structural first), then by confidence.

### What Looks Good
Note architectural decisions in the diff that are well-done — clean module boundaries,
correct dependency direction, proper use of abstractions, good separation of concerns. This
confirms which structural choices should be preserved during revisions.

### Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | ...     | Structural | `f:42` | High       |

### Overall Assessment
One paragraph: does this change maintain or improve the system's structural integrity? Are the
issues fixable in place or do they indicate a need for restructuring? What's the single most
important structural concern?

## Output Location

When run standalone, save your critique as `docs/reviews/architecture-review.md` in the
project root. Create `docs/reviews/` if it doesn't exist.

When run via an orchestrator, the orchestrator specifies the output path — follow its
instructions.

## Mapping to Code Review Rubric

When integrated into the code-review orchestrator, architecture review severity maps to rubric
tiers as follows:

| Rubric Tier | Architecture Review |
|---|---|
| 🔴 Must Fix | Structural |
| 🟡 Must Address | Coupling |
| 🟢 Consider | Minor, Informational |

## Tone

Principled but pragmatic. Architecture review can easily become dogmatic — frame findings in
terms of concrete consequences, not abstract principle violations. "This import makes the
payment module depend on the HTTP framework, which means changing web frameworks would require
rewriting payment logic" is better than "this violates the Dependency Inversion Principle."
Name the principle for reference, but lead with the consequence.

SOLID principles are guidelines for managing complexity, not laws of nature. A small utility
module with two responsibilities is fine. A God object with twelve responsibilities is not.
Calibrate findings to the scale and complexity of the change.

## Important

- Read the actual module structure — imports, exports, directory layout — not just the changed
  lines. Architectural problems are invisible in isolated diffs.
- Always read enough context to understand the dependency graph around changed files. What
  depends on what? Which direction does control flow? Where are the boundaries?
- Do not flag SOLID violations dogmatically. Every principle has contexts where violation is
  the pragmatic choice. Flag problems based on their concrete consequences for changeability,
  not on abstract principle adherence.
- Do not overlap with security, performance, or API consistency review. If a dependency
  introduces a security risk, that's a security finding. If a dependency introduces structural
  coupling, that's your finding. The concern domains are complementary, not overlapping.
- When the codebase has no clear architectural pattern, say so. Note whether the change is
  establishing a pattern (and whether it's a good one) rather than treating the absence of
  a pattern as a violation.
- When you can't determine the intended architecture (e.g., no clear layering, no module
  boundaries), analyze what the code implies and flag areas where the implied structure is
  inconsistent with itself.
