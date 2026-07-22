---
name: dependency-upgrade
description: >
  Evaluate a dependency upgrade by reviewing the changelog, identifying breaking changes,
  assessing migration effort, and producing a go/no-go recommendation with a concrete
  migration plan. Use this skill when the user asks "should we upgrade X", "what changed in
  X v2", "is this upgrade safe", "review this dependency bump", "review this dep bump PR",
  "is bumping X v1 to v2 risky", or when Dependabot or Renovate opens a PR that needs human
  judgment. Also trigger when a dependency has a known security advisory or CVE, is
  approaching end-of-life, or when a transitive dep is forcing a version bump. Can evaluate
  a single upgrade or compare alternatives (e.g., "should we upgrade X or switch to a
  different library"). When in doubt and the work involves a dependency manifest change
  (package.json, go.mod, requirements.txt, Cargo.toml, Gemfile, pyproject.toml, etc.),
  prefer running this skill over skipping it.
when: User asks whether to upgrade a dependency or reviews a dep bump
---

> On bad output, see guides/skill-recovery.md

# Dependency Upgrade Evaluation

Surface risks, breaking changes, and migration effort so the user can decide. Do not rubber-stamp or block reflexively.

## Scoping

Determine what you're evaluating:

1. **User names a specific upgrade** (e.g., "upgrade React from 17 to 18"): evaluate that version transition.
2. **User asks generally** (e.g., "should we upgrade lodash"): check current version, latest version, evaluate the gap.
3. **Security advisory**: focus on the vulnerability, affected versions, and minimum upgrade path to resolve it.

### Gather information

**Current state in the project:**
- Current version? (Check package.json, go.mod, requirements.txt, Cargo.toml, etc.)
- How used? Search codebase for imports/requires. Note which APIs/features are actually used — this determines which breaking changes matter.
- Any version pins, overrides, or resolutions constraining the upgrade?

**Upgrade target:**
- Target version? (Latest stable, specific version, or minimum version fixing a vulnerability)
- Versions between current and target? (Major jumps may require stepping through intermediate versions)

**Changelog and migration guides:**
- Use web search to find the changelog, release notes, and migration guides.
- Focus on breaking changes, deprecations, new requirements (minimum runtime version, peer dependency changes, dropped platform support).

## Analysis

### 1. Breaking changes impact

For each breaking change between current and target:

- **Affects this project?** Check whether the project uses the changed API. Many breaking changes are irrelevant to a codebase.
- **Migration path?** Mechanical rename, behavioral change, or conceptual redesign?
- **Codemod or migration tool?** Many major upgrades provide automated migration.

Rate overall impact: **None** (no relevant breaking changes), **Mechanical** (find-and-replace or codemod), **Moderate** (thoughtful but straightforward changes), **Significant** (rethink how the dependency is used).

### 2. Transitive dependency effects

- Will it force upgrades of other dependencies? (Peer dependency changes)
- Does it conflict with other dependencies? (Version resolution conflicts)
- Does it change minimum runtime or platform requirements?

### 3. Risk assessment

**What could go wrong?**
- Subtle behavioral changes — not breaking in the API sense but changing outcomes
- Performance regressions (especially core deps: ORMs, HTTP clients, bundlers)
- Compatibility issues with the runtime environment
- Incomplete migration leaving the codebase half-upgraded

**How detectable are problems?**
- Tests that would catch behavioral regressions?
- Type checks that would surface API changes at compile time?
- Would problems manifest immediately or only under specific conditions?

### 4. Urgency

- Security vulnerability with known exploits → urgent
- Security advisory without known exploits → soon, not emergency
- End-of-life / no longer patched → plan the upgrade
- New feature the project needs → upgrade when needed
- Keeping up with latest → low urgency; evaluate cost/benefit
- Dependency of a dependency requires it → check if avoidable

### 5. Rollback rehearsal (precondition)

Before starting the migration, the rollback procedure must be **documented** and **rehearsed**. An upgrade you don't know how to undo isn't safe to start.

- **Documented** means writing the exact commands that revert the change: lockfile/version pin restoration, the install command, and any data/config changes to unwind. Vague intent ("revert the commit") doesn't count — write the literal commands.
- **Rehearsed** means running those commands once and confirming a **verification step** passes afterward. Keep it small but real: a smoke test, an app boot, a focused test exercising the dependency's primary use. Pick something that would *fail* if the rollback left the project broken.
- Rehearse on a scratch branch (or equivalent) so the rehearsal doesn't destabilize ongoing work. The artifact is the "rehearsed on {date/branch}, verification passed" line in the output template.

Why a precondition, not a follow-up: rehearsing after a problem occurs is when you discover the lockfile doesn't fully revert, a database migration was one-way, or the install command needs a forgotten flag. Find those problems while the upgrade hasn't shipped yet.

## Output

````markdown
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

### Rollback Plan (precondition — complete before starting Migration Plan)

**Exact rollback commands:**
```
{e.g.,
git checkout -- package.json package-lock.json
npm ci
# if a data/config change was applied:
{exact undo command}
}
```

**Verification step** (run after rollback; must pass to confirm rollback worked):
{e.g., `npm test -- src/payments` — exercises the dependency's primary use in this project; would fail if the lockfile didn't fully revert.}

**Rehearsal status:** [ ] Rehearsed on {YYYY-MM-DD} on branch `{scratch-branch-name}`; verification step passed.

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
````

### Comparison mode

When the user compares 2+ options ("should we upgrade or switch to a different library"), produce one evaluation block per option using the template above, then add a final comparison block:

````markdown
## Comparison Summary

| Option | Recommendation | Breaking change impact | Effort | Risk | Why |
|--------|---------------|------------------------|--------|------|-----|
| {dep@target} | Upgrade now | Mechanical | hours | Low | {1-line reason} |
| {alternative-dep} | Defer | Significant | weeks | Medium | {1-line reason} |

**Recommended option:** {which one and why — reference the rows above}
````

Keep each per-option evaluation complete (header, Summary, Breaking Changes…, Migration Plan, etc.) so reviewers see the full reasoning behind each row, not just the verdict.

## Output Location

Present the evaluation in chat. If the user requests a persisted artifact, save to `docs/working/dep-upgrade-{package}-{version}.md`.

## Important

- **Search the codebase for actual usage.** Don't evaluate breaking changes in the abstract — check whether the project uses the affected APIs. A "major breaking change" the project doesn't touch is irrelevant.
- **Read the migration guide, not just the changelog.** Changelogs list what changed; migration guides explain how to adapt. Base the effort estimate on the migration path, not the changelog length.
- **Check for codemods.** Many libraries provide automated migration tools. A breaking change with a codemod is mechanical work, not a design challenge.
- **Don't recommend upgrading just to be current.** Every upgrade has nonzero risk and effort. The benefit should justify the cost. "It's the latest version" is not sufficient motivation.
- **For security upgrades, check the actual advisory.** Is the vulnerability exploitable in this project's usage? A vulnerability in a feature the project doesn't use may not require an emergency upgrade.
- **Run the security-reviewer skill on the resulting diff before recommending merge** when the upgrade is motivated by a CVE, replaces a security-relevant package, or bumps crypto/auth dependencies. This is the symmetric counterpart to security-reviewer's own dep-manifest trigger — that flags risks at manifest-change time; this catches issues introduced by the call-site migration itself.
- **When the upgrade path is unclear, recommend a spike.** If you can't confidently estimate the effort, say so and suggest a timeboxed investigation using the spike workflow.
- **Don't start the migration until the rollback is documented and rehearsed.** A rollback that's never been executed is not a rollback plan — it's a hope. Rehearse on a scratch branch and confirm a verification step passes before touching the real upgrade.
