# Research Scaffolds

Optional copy-paste templates for the RPI research phase (`docs/working/research-{topic}.md`). These pre-fill the required sections (Scope, What exists, Invariants, Prior art, Gotchas) with task-type-specific prompts to help you start writing faster.

**These are optional.** You can write research docs from scratch — the only requirement is that they cover the sections listed in step 2 of `workflows/research-plan-implement.md`. Use these when staring at a blank file feels slower than filling in prompts.

**Hypothesis traceability:** If you used a scaffold, note which one in your research doc's Scope section (e.g., "Scaffold: new-feature"). This makes it possible to track whether scaffolds are actually used in practice.

---

## Scaffold: New Feature

```markdown
# Research: {topic}

## Scope
{One sentence: what feature, for whom, what it enables.}
Scaffold: new-feature

## What exists
- Entry points: {Where does the user/caller interact with this area today?}
- Data flow: {How does data move through the relevant path?}
- Extension points: {Where is the natural place to add this feature?}

## Invariants
- {Existing APIs or contracts that callers depend on}
- {Auth/permission checks that must be preserved}
- {Performance expectations or SLAs}

## Prior art
- {Does the codebase solve a similar problem elsewhere? Describe it.}
- {If no prior art, state that explicitly.}

## Gotchas
- {Non-obvious coupling or side effects}
- {Known fragile areas near the change}
```

---

## Scaffold: Bug Investigation

```markdown
# Research: {topic}

## Scope
{One sentence: what's broken, what's the observed vs. expected behavior.}
Scaffold: bug-investigation

## What exists
- Reproduction: {Steps to trigger the bug, or link to failing test}
- Error output: {Stack trace, log line, or symptom}
- Code path: {Which files/functions are involved in the failing path?}

## Invariants
- {What correct behavior looks like — the contract being violated}
- {Adjacent behavior that must not change when fixing this}

## Prior art
- {Has this area been fixed before? Check git log for related fixes.}
- {Similar bugs elsewhere in the codebase?}

## Gotchas
- {Why the obvious fix might be wrong}
- {Upstream callers that could be the real source}
```

---

## Scaffold: Refactor

```markdown
# Research: {topic}

## Scope
{One sentence: what's being restructured and why (not changing behavior).}
Scaffold: refactor

## What exists
- Current structure: {How is the code organized today?}
- Callers/dependents: {What depends on the code being refactored?}
- Test coverage: {What tests exist? Are they testing behavior or implementation?}

## Invariants
- {Inputs, outputs, and side effects that must be preserved exactly}
- {Public API surface that external code depends on}

## Prior art
- {Target pattern — does the codebase already use the structure you're moving toward?}
- {If this is a migration, what's already been migrated?}

## Gotchas
- {Implicit dependencies (reflection, dynamic dispatch, config-driven behavior)}
- {Areas where tests cover implementation details, not behavior}
```
