# Iterative spec discovery as a workstream

**Last updated:** 2026-05-18
**Status:** Observation captured; no plan yet. Decision deferred per `docs/superpowers/plans/2026-05-18-superpowers-integration.md` Phase 4 discussion.

## The problem

When implementation complexity exceeds what fits in head at one time, the spec is genuinely not writable upfront. The working pattern is:

1. Write functional tests for the desired end result.
2. Run them against the in-progress (wrong) implementation.
3. Watch them fail in informative ways — the failure shape pins down what's incorrect.
4. Iterate: tighten assertions, add tests, watch new failures, fix.
5. The cumulative test set *becomes* the spec.

The drift is not "the spec was wrong." Each test was locally correct when written. Drift emerges from the collection: no one (including the author) holds the union in their head, so the implementation can diverge from the *aggregate* intent of N tests written at different times.

## Why this is not a verification-gate problem

The twelve paths in the Phase 4 divergence doc all assume a spec exists and verification checks against it. Here, verification (running the tests) works fine — the tests pass when the implementation matches them. The problem is one level up: are the tests collectively asserting what was intended?

This is closer to a *coverage* or *spec-completeness* problem than a verification problem. Path 11 (independent verifier subagent) was the closest match, but it needs a spec to give the verifier; in this setup the tests *are* the spec.

## Two candidate interventions (seeds, not decisions)

### Angle A — Promote TDD as the routing default for this kind of work
Superpowers ships `test-driven-development` and `writing-plans` already enforces red-green discipline in task steps. Promote TDD to a first-class routing entry in CLAUDE.md so the agent surfaces "is this a TDD-shaped task?" as a decision, not an implicit assumption.

### Angle B — Test-intent annotations as a first-class artifact
Each test gets a `# Intent:` one-liner stating what it asserts and what failure-shape it's designed to catch. Tooling (grep, summarize) can roll these up into a "spec coverage" view at PR time. Surfaces ambiguity when intents are vague or duplicated.

### Possible composition
A could establish the workflow shape; B could provide the legibility artifact within that workflow. They are not mutually exclusive.

## Next step

Not now. When picked up:
- Read this doc.
- Read the Phase 4 divergence doc for context on why this was separated out.
- Brainstorm with `superpowers:brainstorming` rather than jumping to writing-plans — the problem framing is not yet stable enough for a plan.
- The two angles above are seeds, not the candidate set. Real divergence should expand from "what does iterative spec discovery actually need?" — annotations and TDD promotion are two answers among many.

## Triggering examples (cite as motivation in the future plan)

- Functional tests written for end-result correctness, but full implementation spec couldn't be held in head simultaneously.
- Test-writing process worked by staging: establishing tests against the wrong implementation to specify what was incorrect, then iterating.
- "Effectively surfacing questions about test intentions" was a recurring concern.
