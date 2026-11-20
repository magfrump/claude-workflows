# Code Review Rubric

**Branch:** fix/lever3-followons (14d450d9..HEAD) · **Brief:** docs/working/briefs/2026-11-19-lever3-followons.md
**Passes:** round 1 at c8b5d77b, round 2 at 9c2a07a4 (one reviewer each: fact-check, consistency and test critic, no sub-agents); round 3 (7ec174d8 and after) closed on a mutation run and the final gate.
**Verdict:** approve. No Must-Fix in any round; every Must-Address row fixed.

Claims checked accurate (both rounds): the 9-of-9 A8 by-path read (`docs/working/research-2026-11-19-code-review-lever3-correction.md` :95-108); the cache-probe citation (`runs/review-arms/a8-2026-11-19/cache-probe.md` :69, :85, :94-95; merged 9e89a31e); decision-log row 35's counts (13 `@test` at 14d450d9 and HEAD, 10 at 65df1b84); `personas.md` beside the ai-personas-critique SKILL.md (its :58); the `#context-curation` anchor (orchestrated-review.md :145); the "Stage 1 step 3" cross-references. No refuted claim remains in the five target files.

## 🔴 Must Fix

None.

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | Draft-review's by-path steps left out code-review's "Read tool, not `cat`" clause (code-review `SKILL.md:468-469`), though A8 had 2 of 9 agents overflow the Bash cap with `cat`. Location: `skills/draft-review/SKILL.md:171-174`, `:233-235` | Docs | Medium | round 1, finding 1 | for-author | — | 🟢 Fixed in 9c2a07a4: both steps say "with the Read tool, not `cat`"; round 2 confirmed | — |
| A2 | The A7 note said d383a484 "replaced" contract test 10; it only retitled it, assertions unchanged. Location: `docs/reviews/code-review-rubric-2026-08-07-main.md:34` | Docs | Medium | round 1, finding 2 | for-author | — | 🟢 Fixed in 9c2a07a4: "retitled contract test 10 (its second-to-last framing dropped; assertions unchanged)"; round 2 confirmed against `git diff d383a484^1 d383a484` | — |
| A3 | The guard test's step-4 end-of-range check was not bound to its own section: with fact-check's step 4 removed it found the critic's step 4, and the range leaked into the critic section. Location: `test/skills/subagent-context-delivery.bats:53` | Test | Medium | round 2, finding 1 | for-author | — | 🟢 Fixed in 7ec174d8: guard and both extraction awks stop at the next heading; a mutant dropping fact-check's step 4 and its Read-tool clause now fails test 4 ("no step 4 after: For each fact-check agent, you MUST:") | — |

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | Test 4 checked the paste-only-when rule for the critic range only, and its range had no end guard. Location: `test/skills/subagent-context-delivery.bats:48-53` | round 1, nit 3 | Low | for-author | — | 🟢 Fixed in 9c2a07a4 (and see A3) |
| C2 | The claim regex missed "subagents" (no hyphen) and "can't read your files". Location: same file :35 | round 1, nit 4 | Low | for-author | — | 🟢 "subagents" fixed in 9c2a07a4; "can't read" left out on purpose: the guide's kept first exception uses it truthfully |
| C3 | The guide's kept first exception frames a conversation-only case as a filesystem limit. Location: `guides/sub-agent-briefing.md:78` | round 1, nit 5 | Low | for-author | — | Not changed: true as written and outside the brief's two claims |

## Tests

- `test/skills/subagent-context-delivery.bats`: 4/4; armed (tests 2-4 fail on the 14d450d9 text, per-file match counts 4, 2, 1, 1, 1); hermetic; no skip.
- Final gate after 7ec174d8: 77/77 across the eight bats files the research doc lists; round 1 also ran all 12 `test/skills/` files naming a changed doc, 164/164. `scripts/hermeticity-lint --root .` clean.

Outside scope, for the record: the old wording survives in historical records (decision-log row 35's body, decision 032 :106/:124, `docs/thoughts/code-review-evaluation-state.md:191`) and `docs/roadmap.md:110-120`, which the brief forbids editing.
