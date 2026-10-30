# 040 — The questions doc holds only owner items

**Goal:** Decide where agent-internal items (`agent`, `trigger`, `deferred`) live, so `docs/working/questions.md` is the owner's single entry point to work blocked on them.
**Project state:** decision record on main · phase 1 of a phased plan (cross-project aggregation later) · not blocked
**Task status:** complete (decided 2026-10-28, Q-221 [14′]; build is a roadmap Now item)

## Context

The owner reported (`docs/human-author/answers-10-28-26.txt`, "general:") that user-facing
and agent-internal entries share one file. That hurts readability, and the ordering of open
items is unclear. On 2026-10-28, 2 of 17 open entries were the owner's. Four `agent` entries
were finished work that only the owner could close, because the `--cycle-diff` anti-forgery
rule stops agents closing any entry in the questions files. The 2026-09-17 triage
(`docs/working/triage-2026-09-17-backlog.md` §3.1) had already said agent items and triggers
do not belong in a question queue; its fix, the `Needs:` route label, kept them in one file.

The full Double Diamond, the owner's framing and constraint notes, and every rescore are in
`docs/working/dd-questions-doc-purposes.md`.

Chosen framing (phased): each project gives the owner one entry point listing exactly the
work blocked on them (decisions, terminal pastes, hands-on walkthroughs/playtests, quick
reads). Agent-internal state lives in homes the agents own and check. The format stays
readable by a later cross-project aggregator; a single cross-project surface is a later
phase, not this decision.

## Options considered

- **[14′] Watch file + roadmap** (chosen): watches in `docs/working/watching.md` in the
  questions entry grammar; agent work in the roadmap.
- **[1] Roadmap only:** watches as bullets in a roadmap `## Watching` section.
- **[2] Watch file for all agent state:** dominated by [14′] once every repo has a roadmap.
- **[4] Two sections in one file:** pruned.
- Ten more in the working doc's step 1.

## Decision and rationale

[14′]. `questions.md` accepts four owner routes:

- `you: judgment`
- `you: terminal`
- `you: walkthrough` (new)
- `you: fyi` (new; answered `seen`, acknowledgements can be batched)

`questions.sh check` refuses `agent`, `trigger` and `deferred` there and names their home.
Watches (`trigger`/`deferred`) go to the agent-owned `docs/working/watching.md`, in the same
entry grammar, with closed watches kept in its `## Closed` section. Agent work goes only in
`docs/roadmap.md`, which already tracks it. The owner answers in free text and never edits
or lints the questions file.

Why: [14′] and [1] cost about the same. [14′] keeps one grammar and one checker (repo S3)
and keeps a watch's observation-named closure criterion as a field rather than a convention
(triage §1.3). It also fails loudly on a malformed entry (repo H2), where a prose bullet
parser can skip one silently.

Premise: every project follows the dev cycle (owner, 2026-10-28). See alternatives considered →

## Pruned candidates and why

Each entry is `[candidate-ID]: one-line reason for discard`. Future DDs in adjacent areas can grep this section to avoid regenerating already-pruned approaches.

- [1]: runner-up; a second, loosely parsed format for watches.
- [2]: duplicates the roadmap for agent work.
- [4]: exemption loosens the anti-forgery rule; the owner still reads a mixed file.
- [5] generated view: closure and rot unchanged.
- [6] hosted page: deferred to the cross-project phase.
- [7] closure-only: needs a `--cycle-diff` hole.
- [8] abolish routes: one-off watches have no home.
- [9] per-entry files: rewrites four parsers.
- [10] GitHub issues: excluded.
- [11] shorter entries: wrong measure (clarity, not length).
- [12] structured store: rewrites everything.
- [13] lifetime cap: closes watches on a clock.

Prior pruning grep: no matches found for [questions, queue, inbox, attention, route, triage].

## Consequences

**Easier:**
- The owner reads only their items, and "all answered" is the file being empty.
- Agents close their own watches and work without an owner act.
- A later aggregator reads one grammar across repos.

**Harder:**
- One more file in `docs/working/`.
- The dev cycle reads two files at step 3.
- Gate code changes in three units, each needing owner merge approval.
- `you: fyi` adds a recurring acknowledgement; keep it rare (repo S10).

## Revisit triggers

Each entry is a concrete, observable condition that should prompt re-evaluating this decision. Future readers can grep this section when their context changes to see whether earlier decisions still apply.

- A project that does not run the dev cycle adopts `questions.sh`.
- `watching.md` passes 30 open watches.
- The owner again reports the questions file as hard to read while it holds only owner routes (then entry clarity is the problem).
- `you:` asks exceed ~5 per cycle for 3 cycles.
- The cross-project phase starts (aggregation, or the threadwork wiki as the owner's surface).
