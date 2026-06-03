# RPI: divergent-design skill trigger shim

## Research

**Problem.** `superpowers:brainstorming` auto-fires before plan mode on any creative
task ("MUST use this before any creative work"). When the creative task is actually a
tradeoff-bearing decision among 3+ options, DD should win — but DD lives only in
`workflows/divergent-design.md` and CLAUDE.md prose, which the agent skims and which
do not compete at the *skill-selection* layer. Brainstorming has a SKILL.md and so
gets surfaced as a first-class option; DD does not.

**Goal.** Add a thin `skills/divergent-design/SKILL.md` whose `description` triggers on
the same tradeoff-decision phrasings brainstorming would catch (compare options, X vs Y,
which approach, pick between, design choice, tradeoff, pros and cons) so DD becomes a
selectable skill that competes head-to-head. The skill is a *router*: it delegates to
the existing `workflows/divergent-design.md`, it does not restate the workflow's content.

**Constraints / invariants.**
- Decision 004 anti-redundancy: do not duplicate workflow content into the skill.
  The skill points at the workflow and hands off.
- Match repo skill conventions: `name` / `description` / `when` frontmatter, a
  `> On bad output, see guides/skill-recovery.md` line (all 24 skills have it), and
  repo-relative `workflows/...` paths (as code-review/self-eval use).
- The precedence-over-brainstorming logic and the 3+-tradeoff-axis trigger test already
  live in `workflows/divergent-design.md` (When-to-use bullet + precedence callout) and
  in CLAUDE.md row 2. The shim restates only the *routing test*, then defers.

**Prior art.** `design-space-situating/SKILL.md` is the closest analog — a decision-helper
skill with a long, trigger-phrase-dense description and a short body. Mirror its shape.

## Plan

Single file: `skills/divergent-design/SKILL.md`.

1. Frontmatter:
   - `name: divergent-design`
   - `description`: lead with the trigger phrasings that overlap brainstorming, state the
     precedence ("supersedes superpowers:brainstorming when the task is a choice among 3+
     tradeoff-bearing options"), and the mechanical trigger test (name 3+ viable options on
     a tradeoff axis → DD). Dense with the exact phrasings so the selector ranks it.
   - `when`: one-line summary.
2. Body (thin, ~25 lines): announce it is a router, run the trigger test, then instruct the
   agent to read and follow `workflows/divergent-design.md` (and where to write output). No
   restatement of the diverge→diagnose→match→decide process.

## Verification

- `name:` matches directory.
- Description contains the overlap phrasings and the precedence/trigger test.
- Body delegates to the workflow with no process duplication.
- Frontmatter parses (YAML) like sibling skills.
