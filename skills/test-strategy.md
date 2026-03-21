---
name: test-strategy
description: >
  Given a feature, module, or change, recommend what kinds of tests to write, where to put them,
  and what to prioritize. Analyzes the code's risk profile, existing test patterns, and
  architecture to produce a concrete testing plan — not generic advice, but specific test cases
  mapped to specific files. Use this skill when the user asks "what tests should I write",
  "how should I test this", "what's missing from our test coverage", or when an RPI plan needs
  a testing strategy. Also trigger when a feature is implemented but has no tests, or when
  the user is unsure whether unit, integration, or end-to-end tests are appropriate.
---

# Test Strategy

You are producing a concrete testing plan for a specific piece of code. The goal is not to
recommend "more tests" generically — it's to identify which tests provide the most value for
this specific code, given its risk profile and the project's existing testing patterns.

## Scoping

Determine what code you're analyzing. In priority order:

1. **If the user specifies files or a feature**: Use that scope.
2. **If there's a recent implementation (current branch vs main)**: Analyze the diff.
3. **If the user asks about a module or subsystem**: Read the module and its existing tests.

For the scoped code, read:
- The implementation (not just signatures — you need to understand branching logic, error paths,
  and edge cases)
- Any existing tests for this code
- Tests for adjacent/similar code in the project (to understand conventions)
- The test configuration (test framework, test runner, fixtures, helpers)

## Analysis

### 1. Classify the risk profile

For each function or component in scope, assess:

**What can go wrong?**
- Incorrect business logic (wrong calculations, wrong state transitions)
- Integration failures (API contracts, database queries, external service calls)
- Edge cases (empty inputs, boundary values, concurrent access, large inputs)
- Security issues (input validation, authorization checks, data leakage)
- User-facing regressions (UI behavior, error messages, response formats)

**What's the blast radius of a bug?**
- Data corruption (high — hard to recover)
- User-facing error (medium — visible but recoverable)
- Internal logging gap (low — invisible to users)
- Silent wrong answer (critical — may not be caught for a long time)

**What's the change frequency?**
- Code that changes often needs tests that catch regressions without being brittle.
- Code that rarely changes but is load-bearing needs thorough tests that serve as documentation.

### 2. Survey existing coverage

Before recommending new tests, understand what exists:
- Which functions/paths already have tests?
- What testing patterns does the project use? (Arrange-act-assert? Given-when-then? Table-driven?)
- What test infrastructure exists? (Factories, fixtures, mocks, test databases, API stubs)
- Are there gaps in the existing tests that matter more than testing the new code?

### 3. Determine the test types needed

For each piece of code in scope, recommend the appropriate test type(s):

**Unit tests** — when the logic is self-contained and the value is in verifying correctness
of a specific algorithm, transformation, or decision. Good for: pure functions, business
logic, data transformations, state machines, validators.

**Integration tests** — when the value is in verifying that components work together correctly.
Good for: database queries, API endpoint handlers, service-to-service calls, middleware chains,
message queue consumers. These test real interactions, not mocked ones.

**End-to-end tests** — when the value is in verifying a complete user workflow. Good for:
critical user paths (signup, checkout, data export), flows that cross many subsystems. Use
sparingly — these are slow and brittle.

**Property-based tests** — when the code should satisfy invariants across a wide range of
inputs. Good for: serialization/deserialization roundtrips, parsers, mathematical operations,
data structure invariants.

**Snapshot/golden tests** — when the output is complex and correctness is "it matches the
expected output." Good for: serializers, renderers, code generators, API response shapes.

**Contract tests** — when two systems must agree on an interface. Good for: API boundaries
between services, shared library interfaces, database schema expectations.

Not every test type applies to every codebase. Recommend only types that fit the project's
existing infrastructure or that are worth adding.

### 4. Prioritize by value

Rank your test recommendations by the ratio of risk-reduced to effort-required:

1. **High value**: Tests for code with high blast radius, no existing coverage, and
   straightforward test setup. Write these first.
2. **Medium value**: Tests for code with moderate risk or code that already has partial
   coverage. Write these if time permits.
3. **Low value**: Tests for low-risk code, code with existing coverage, or code where
   test setup is disproportionately expensive. Skip or defer these.

Be honest about tests that aren't worth writing. A unit test for a trivial getter wastes
time. An integration test for a function that's already covered by an end-to-end test adds
maintenance burden without new information.

## Output

Produce a testing plan with this structure:

### Test Conventions
Brief summary of the project's existing test patterns: framework, file locations, naming
conventions, available test infrastructure. This section ensures the recommended tests will
be consistent with the codebase.

### Recommended Tests

For each recommended test, specify:

```
#### [Test name/description]

**Type:** [unit / integration / e2e / property / snapshot / contract]
**Priority:** [high / medium / low]
**File:** [where to put this test — follow project conventions]
**What it verifies:** [one sentence — the specific behavior or invariant]
**Key cases:**
- [case 1: specific input → expected output or behavior]
- [case 2: edge case or error path]
- [case 3: ...]

**Setup needed:** [any fixtures, mocks, or test infrastructure required]
```

### What NOT to Test
Explicitly list code in scope that you're recommending against testing, and why. This is
as important as the test recommendations — it prevents wasted effort and shows that the
plan is intentional, not just "test everything."

### Coverage Gaps Beyond Current Scope
If you noticed untested code outside the current scope that represents significant risk,
note it briefly. This feeds into future test strategy sessions.

## Output Location

When run standalone, present the testing plan in chat. If the user requests a persisted
artifact, save to `docs/working/test-strategy-{topic}.md`.

When used as part of RPI, the testing strategy section of the plan doc should follow this
skill's structure rather than generic "add tests" bullets.

## Important

- **Follow existing conventions.** If the project puts tests in `__tests__/` with `.test.ts`
  suffixes, don't recommend a `tests/` directory with `.spec.ts` files.
- **Be specific about test cases.** "Test the happy path" is not useful. "Test that
  `createUser({email: 'a@b.com', name: 'Test'})` returns a user with a generated UUID and
  `createdAt` within 1 second of now" is useful.
- **Don't recommend mocking everything.** If the project has test database infrastructure,
  recommend integration tests that use it. Mock only at boundaries you can't control
  (external APIs, time, randomness).
- **Consider test maintenance cost.** Brittle tests that break on every refactor are worse
  than no tests. Prefer testing behavior over implementation details.
- **Read the actual code.** A test strategy based on function signatures will miss the
  important edge cases that live in the implementation.
