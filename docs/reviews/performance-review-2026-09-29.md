Commit: 5ee8315

# Performance Review — fix/agents-md-no-imports

**Scope:** `git diff main...HEAD` (AGENTS.md, docs/decisions/log.md, scripts/health-check.sh, test/agents-gemini-sync.bats)
**Date:** 2026-09-29
**Based on:** Stage-1 code-fact-check (merged k=3, most-severe-wins), via the shared critic brief

## Data Flow and Hot Paths

The "hot path" here is session start-up context. AGENTS.md is loaded as this repo's project instructions on every Claude Code session in the repo, and on every subagent a session spawns. Before this branch, Claude Code expanded AGENTS.md's nine `@./workflows/*.md` imports inline. The nine files total 358,414 bytes (`wc -c`, measured on this worktree, 2026-09-29). The fact-check counted 355,598 characters, about 89K tokens at 4 chars/token. After the branch, AGENTS.md is 7,815 bytes with no imports; it was 7,932 bytes on main before expansion. So per-session instruction cost for this file drops by about 98%.

The load multiplies by fan-out. A `code-review` run starts ~3 fact-check replicates plus 3–6 critics, and each is a fresh context that loads the project instructions. This reviewer's own system context (a subagent spawned from the `/workspace` main checkout) contains the full text of all nine workflow files under "Contents of /workspace/workflows/…". That shows the multiplication happens today: roughly 89K tokens per agent, times about 6–10 agents per review.

Test runtime: `bats test/agents-gemini-sync.bats` runs in 0.063 s wall (measured with `time`, 2026-09-29). The new guard adds one `grep` over a 7.8 KB file, which is negligible.

## Findings

#### Guard regex misses import forms that would restore the ~89K-token load

**Severity:** Medium
**Location:** `test/agents-gemini-sync.bats:34`
**Move:** 3 (work moved to the wrong place) / 1 (hidden multiplication)
**Classification:** Macro (whole-file expansion per agent) / Hot path (every session and every subagent start)
**Confidence:** High (the regex behaviour is fact-checked). Medium on Claude Code expanding the bare `@workflows/x.md` form, which is documented import syntax but was not run here.
**Legibility-target:** the next editor of AGENTS.md
**Baseline:** 358,414 bytes of workflow text per expansion (`wc -c` on the nine files, 2026-09-29)

Evidence (verbatim):
```
  if matches=$(grep -nE '(^|[[:space:]*`])@\.{0,2}/' "$AGENTS"); then
```
The guard exists to stop the context regression from coming back, but it only matches `@/`, `@./` and `@../`. A probe line `x @workflows/spike.md` produced 0 matches (run in the scratchpad, 2026-09-29). The fact-check also found misses for `@docs/x.md`, `@~/x.md`, and `@./x` after `(`, `"` or `[`. Claude Code's import syntax allows paths without a `./` prefix. So an editor who writes `@workflows/pr-prep.md` would silently re-add about 11K tokens per agent for that one file, and the test would stay green. The same mismatch is the fact-check's INCORRECT verdict on log row 65 ("fails on any `@path` import").

**Recommendation:** Widen the pattern to any `@` followed by a path-like token ending in a file extension, e.g. `(^|[^[:alnum:]_.+-])@[~./[:alnum:]_-][^[:space:]]*\.[[:alnum:]]+`, and add a negative case for emails. Or narrow log row 65's wording to what the regex actually catches. Widening matches the test's stated purpose.

#### Only AGENTS.md is guarded; other always-loaded instruction files are not

**Severity:** Low
**Location:** `test/agents-gemini-sync.bats:33-40`
**Move:** 10 (price the deployment environment)
**Classification:** Macro / Hot path (conditional: only if an import is ever added)
**Confidence:** Medium
**Legibility-target:** maintainers of global-instructions/
**Baseline:** no baseline available — flagged as speculative

Evidence (verbatim):
```
@test "AGENTS.md has no @-imports" {
```
`global-instructions/CLAUDE.md` (35,413 bytes) is installed as every project's global instructions. An `@` import added there would cost more than the one this PR removes, because it would load in every project, not just this repo. A scan of that file today finds no imports, so this is a coverage gap, not a current cost.

**Recommendation:** Optional: loop the same guard over `global-instructions/CLAUDE.md`. Otherwise record in row 65 that the guard covers AGENTS.md only.

#### Shared sections stay loaded twice per session (accepted tradeoff)

**Severity:** Informational
**Location:** `AGENTS.md:41-end` (Context Packing, Shared Thoughts, General Principles)
**Move:** 6 (serialization tax: the same content crosses into context twice)
**Classification:** Micro / Hot path
**Confidence:** High
**Legibility-target:** decision-log readers
**Baseline:** 2,995 bytes from `## Context Packing` to end of AGENTS.md (`awk | wc -c`, 2026-09-29)

About 3 KB (~750 tokens) of AGENTS.md repeats sections of the global instructions, so Claude Code sessions here load it twice. Log row 65 keeps this on purpose so non-Claude agents that read only AGENTS.md still get it. The cost is about 0.8% of what the PR saves. No action needed; noted so the tradeoff has a price on it.

## Endorsements

- Removing the nine `@./workflows/*.md` imports cuts the per-agent instruction load by about 358 KB, roughly 89K tokens, and the cut applies again for every subagent in fan-out workflows. [read: AGENTS.md:9-18 on 5ee8315 vs main] (load-mechanism claim: [unverified — submitted as claim] that Claude Code expands `@./` imports in AGENTS.md; this reviewer's own system context is consistent with it)
- Dropping `sed 's|@\./workflows/||g'` from the sync test leaves a single `tail` per file, which is simpler and no slower. [read: test/agents-gemini-sync.bats:15-27]
- `extract_workflows` returns the same 9 names for old AGENTS.md, new AGENTS.md and GEMINI.md, so health-check work is unchanged. [fact-check: extract_workflows parity — VERIFIED]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Guard regex misses `@workflows/x.md` and similar forms that would restore the load | Medium | `test/agents-gemini-sync.bats:34` | High |
| 2 | Global instructions file not covered by the guard | Low | `test/agents-gemini-sync.bats:33-40` | Medium |
| 3 | ~3 KB of shared sections loaded twice (accepted) | Informational | `AGENTS.md:41-end` | High |

## Overall Assessment

This is a large performance win for very little code. It removes about 89K tokens from every session and every subagent in this repo, and in orchestrated reviews that multiplies to hundreds of thousands of tokens per run. The only real performance concern is durability. The regression guard is narrower than its stated purpose, so the common `@workflows/x.md` form would slip back in with the test still passing. Fix it in place by widening the regex, or at least correct log row 65's claim. No benchmarking is needed. The byte counts are measured, and the token figure is a standard chars/4 estimate.

## Goal-Alignment Note

- **Answered:** Performance review of the full `main...HEAD` diff at 5ee8315, covering per-session context cost (measured byte counts, fan-out multiplication) and test runtime (0.063 s). Every finding has severity, location, verbatim evidence, confidence, legibility target and baseline.
- **Out of scope:** Whether Claude Code expands un-prefixed `@path` forms was not tested by starting a live session (sandbox, no nested CLI run). It rests on documented import syntax and is marked Medium confidence.
- **Escalate:** Finding 1 overlaps the fact-check's INCORRECT verdict on log row 65. Synthesis should merge the two rather than count them twice.
