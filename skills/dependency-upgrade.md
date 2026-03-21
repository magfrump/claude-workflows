---
name: dependency-upgrade
description: >
  Evaluate a dependency upgrade by reviewing the changelog, identifying breaking changes,
  assessing migration effort, and producing a go/no-go recommendation with a concrete
  migration plan. Use this skill when the user asks "should we upgrade X", "what changed in
  X v2", "is this upgrade safe", "review this dependency bump", or when Dependabot or
  Renovate opens a PR that needs human judgment. Also trigger when a dependency is known to
  have a security vulnerability or is approaching end-of-life. Can evaluate a single upgrade
  or compare alternatives (e.g., "should we upgrade or switch to a different library").
---

# Dependency Upgrade Evaluation

You are evaluating whether and how to upgrade a dependency. The goal is to surface the risks,
breaking changes, and migration effort so the user can make an informed decision — not to
rubber-stamp or block the upgrade reflexively.

## Scoping

Determine what you're evaluating:

1. **If the user names a specific upgrade** (e.g., "upgrade React from 17 to 18"): Evaluate
   that specific version transition.
2. **If the user asks about a dependency generally** (e.g., "should we upgrade lodash"): Check
   the current version in use, the latest version available, and evaluate the gap.
3. **If evaluating a security advisory**: Focus on the vulnerability, affected versions, and
   the minimum upgrade path to resolve it.

### Gather information

For the dependency in scope:

**Current state in the project:**
- What version is currently used? (Check package.json, go.mod, requirements.txt, Cargo.toml,
  etc.)
- How is it used? Search the codebase for imports/requires of the dependency. Note which APIs
  and features are actually used — this determines which breaking changes matter.
- Are there any version pins, overrides, or resolutions that constrain the upgrade?

**Upgrade target:**
- What's the target version? (Latest stable, a specific version, or the minimum version that
  fixes a vulnerability)
- What versions are between current and target? (Major version jumps may require stepping
  through intermediate versions)

**Changelog and migration guides:**
- Use web search to find the dependency's changelog, release notes, and migration guides.
- Focus on breaking changes, deprecations, and new requirements (minimum runtime version,
  peer dependency changes, dropped platform support).

## Analysis

### 1. Breaking changes impact

For each breaking change between current and target version:

- **Does it affect this project?** Check whether the project uses the changed API. Many
  breaking changes are irrelevant to a specific codebase.
- **What's the migration path?** Is it a mechanical rename, a behavioral change, or a
  conceptual redesign?
- **Is there a codemod or migration tool?** Many major upgrades provide automated migration.

Rate the overall breaking change impact: **None** (no relevant breaking changes),
**Mechanical** (find-and-replace or codemod), **Moderate** (requires thoughtful changes but
straightforward), **Significant** (requires rethinking how the dependency is used).

### 2. Transitive dependency effects

Check whether the upgrade changes transitive dependencies:

- Will it force upgrades of other dependencies? (Peer dependency changes)
- Does it conflict with other dependencies in the project? (Version resolution conflicts)
- Does it change the minimum runtime or platform requirements?

### 3. Risk assessment

**What could go wrong?**
- Subtle behavioral changes that aren't breaking in the API sense but change outcomes
- Performance regressions (especially for core dependencies like ORMs, HTTP clients, bundlers)
- Compatibility issues with the project's runtime environment
- Incomplete migration leaving the codebase in a half-upgraded state

**How detectable are problems?**
- Does the project have tests that would catch behavioral regressions?
- Are there type checks that would surface API changes at compile time?
- Would problems manifest immediately or only under specific conditions?

### 4. Urgency

**Why upgrade now (or not)?**
- Security vulnerability with known exploits → urgent
- Security advisory without known exploits → soon, not emergency
- End-of-life / no longer receiving patches → plan the upgrade
- New feature the project needs → upgrade when the feature is needed
- Keeping up with latest → low urgency; evaluate cost/benefit
- Dependency of a dependency requires it → check if avoidable

## Output

```markdown
## Dependency Upgrade Evaluation: {package} {current} → {target}

### Summary
**Recommendation:** {Upgrade now / Upgrade soon / Defer / Don't upgrade}
**Breaking change impact:** {None / Mechanical / Moderate / Significant}
**Estimated effort:** {minutes / hours / days}
**Risk:** {Low / Medium / High}

### Motivation
{Why is this upgrade being considered? Security? New features? Staying current?}

### Breaking Changes That Affect This Project

| Change | Affected code | Migration |
|--------|--------------|-----------|
| {API removed/renamed/changed} | {files in this project that use it} | {what to do} |

{If no relevant breaking changes: "No breaking changes affect this project's usage."}

### Breaking Changes That Don't Affect This Project
{List briefly, so the user knows they were checked and dismissed, not overlooked.}

### Transitive Effects
- {Peer dependency changes, version conflicts, runtime requirements, or "None identified"}

### Risk Factors
- {Behavioral changes, performance concerns, compatibility issues, or "Low risk — well-tested upgrade path"}

### Migration Plan
{If recommending upgrade, provide concrete steps:}
1. {Step 1 — e.g., "Update version in package.json"}
2. {Step 2 — e.g., "Run codemod: npx @org/migrate"}
3. {Step 3 — e.g., "Update `createClient()` calls to pass config object instead of positional args (3 call sites)"}
4. {Step 4 — e.g., "Run tests, check for deprecation warnings"}
5. {Step 5 — e.g., "Remove compatibility shim added in v3 migration"}

### If Not Upgrading
{If recommending deferral, note what would change the recommendation — e.g., "Revisit when
we start the API v3 work, which will require the new streaming API in this dependency."}
```

## Output Location

Present the evaluation in chat. If the user requests a persisted artifact, save to
`docs/working/dep-upgrade-{package}-{version}.md`.

## Important

- **Search the codebase for actual usage.** Don't evaluate breaking changes in the abstract —
  check whether the project uses the affected APIs. A "major breaking change" that the project
  doesn't touch is irrelevant.
- **Read the migration guide, not just the changelog.** Changelogs list what changed; migration
  guides explain how to adapt. The effort estimate should be based on the migration path, not
  the length of the changelog.
- **Check for codemods.** Many libraries provide automated migration tools. A breaking change
  with a codemod is mechanical work, not a design challenge.
- **Don't recommend upgrading just to be current.** Every upgrade has nonzero risk and effort.
  The benefit should justify the cost. "It's the latest version" is not sufficient motivation.
- **For security upgrades, check the actual advisory.** Is the vulnerability exploitable in
  this project's usage? A vulnerability in a feature the project doesn't use may not require
  an emergency upgrade.
- **When the upgrade path is unclear, recommend a spike.** If you can't confidently estimate
  the effort, say so and suggest a timeboxed investigation using the spike workflow.
