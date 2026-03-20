# Decision 001: Code Fact-Checking Skill Design

## Context

The cross-analysis matrix (Theme 9) identified that FC's methodology (claim identification → evidence search → confidence rating) could be adapted for code. Comments, docstrings, commit messages, and architecture docs make checkable claims about code behavior — "This function is O(n)," "This cache invalidates every 5 minutes" — that may be incorrect or stale. No existing workflow systematically verifies these; RPI research catches mismatches incidentally but doesn't produce structured verdicts.

## Options considered

1. **Direct port of FC to code** — Same skill structure, swap web search for code reading tools. Low effort, proven format.
2. **Stale comment detector** — Lightweight heuristic: flag comments referencing nonexistent symbols or significantly changed code. High precision for drift, misses semantic incorrectness.
3. **Code review critic (CC/YC pattern)** — Full code-review persona with verification as one cognitive move among many. Broader but dilutes the fact-checking focus.
4. **DR pipeline stage** — Add code-FC as a stage in draft-review for technical content. Only works within DR, not standalone.
5. **Hybrid claim routing** — Extract claims, classify by type, route to specialized verifiers. Highest theoretical coverage but over-engineered for v1.

Also considered: commit message auditor, performance claim verifier, architecture doc validator (all narrow-scope variants subsumed by #1), annotation-driven checker (cold start problem), full semantic verification (infeasible with current tools), living documentation generator (inverts the problem but doesn't verify existing claims).

## Decision

**Build approach #1: Direct port of FC as a standalone skill (`code-fact-check`).** Design it so it can later be composed into a code-review critic (#3), DR stage (#4), or hybrid router (#5) as the ecosystem evolves.

## Rationale

- Reuses FC's proven structure — claim extraction → evidence search → verdict — minimizing design risk
- Low effort: single `.md` skill file, mirrors existing FC patterns
- High coverage: handles behavioral, performance, architectural, invariant, and configuration claims through the same methodology
- Actionable output: same verdict format developers already understand from FC
- Composable: standalone invocation works for any use case; later integration into DR or PP is additive, not structural

The stale comment detector (#2) is valuable but orthogonal — it could become a lightweight preprocessing step that prioritizes targets for code-fact-check, but it doesn't replace semantic verification.

## Consequences

**Makes easier:**
- Systematic verification of documentation/comment accuracy during PR prep or code review
- Structured output that can be tracked across revisions (like FC's report)
- Future composition: code-review critic skills, DR integration for technical docs, hybrid routing

**Makes harder:**
- Nothing significant. The main risk is that the skill produces noisy output on large scopes. Mitigated by scoping to changed files by default.

## Key design decisions for implementation

**Claim types:** Behavioral, performance, architectural, invariant, configuration, and staleness signals.

**Evidence tools (replaces FC's web search):** Read implementations, grep for callers/callees, check test coverage, read git history, run code via Bash when safe.

**Verdict scale:** Verified, Mostly accurate, Stale, Incorrect, Unverifiable (adapted from FC's five-tier system, with "Stale" replacing "Disputed" and "Unverifiable" replacing "Unverified" to reflect code-specific semantics).

**Scoping:** Default to files changed in current branch vs main. Override with explicit file list or directory.

**Output:** Markdown report in `docs/reviews/code-fact-check-report.md`, same structure as FC report (header, summary tallies, claims ordered by file/line, actionable checklist).
