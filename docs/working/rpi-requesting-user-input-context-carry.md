# RPI: Add a fourth "context continuity" property to requesting-user-input.md

Status: complete
Relevant paths: patterns/requesting-user-input.md

## Research

### Task
`patterns/requesting-user-input.md` ships a checklist that any workflow consults before it
stops to ask the user a question. Today it encodes **three** Don Norman–derived usability
properties: **signifier**, **conceptual model**, **error recoverability**. Add a **fourth**
property — drawn from `property-tests.json`'s `state-preservation-across-transitions` and
`feedback-continuity-across-transitions` — requiring the prompt to **restate the carried
context** (what's already been decided and what state the answer operates on) so the user can
answer without re-reading prior output. This is the property the "adapting the CLI interface
when requesting user input" pointer asks for and the current 3-property checklist omits.

### Prior art / context
- The pattern intro (line 9) names "three usability properties … Don Norman's vocabulary."
  The three existing properties each map a Norman concept onto a text prompt.
- The fourth property maps the usability principle of **keeping system status visible across a
  transition** (Nielsen heuristic #1 "visibility of system status"; the two source
  property-test names both share `…-across-transitions`) onto the prompt. Named **context
  continuity** to sit alongside the Norman trio.
- `property-tests.json` is conceptual source material named by the task; it is not a tracked
  file in this repo. The two property names supply the *content* of the fourth checklist item,
  not a file to read.
- Structure to mirror: each existing property has (a) a checklist bullet, (b) a `### Name`
  subsection with a bulleted elaboration and a "The test:" line, (c) a clause in the worked
  example's good/bad analysis, (d) an anti-pattern entry.

### Invariants to preserve
- Additive only. The three existing properties keep their wording.
- Keep the document internally coherent: every "three" count reference becomes "four."

### Known out-of-scope consequence (follow-up)
- Two existing call-sites — `workflows/research-plan-implement.md` step 4 and
  `workflows/branch-strategy.md` step 7 — have `Done when…` items asserting the prompt carried
  "all three properties." After this change the pattern has four. Those callers are **out of
  the file scope for this round** (scope = `patterns/requesting-user-input.md` only) and will
  read as slightly stale until a follow-up round updates their `Done when…` wording to four.
  Recorded here so the drift is intentional and auditable, not silent.

## Plan
1. Intro paragraph (line 9): three → four; add the fourth property name and its one-line
   failure-mode clause.
2. Checklist (lines 13, 17): "all three" → "all four"; add the **Context continuity** bullet
   after error recoverability.
3. Section heading "## The three properties" → "## The four properties"; add a
   `### Context continuity` subsection after error recoverability.
4. Worked example: add a context-continuity clause to both the bad-analysis (line 63) and
   good-analysis (line 80).
5. Anti-patterns: add a "context amnesia" entry.
6. "Using this pattern" step 2 (line 94): "all three properties" → "all four properties."

## Verification
- The four checklist bullets, four `###` subsections, and four property names in the intro all
  agree; no stray "three" remains in the pattern file.
