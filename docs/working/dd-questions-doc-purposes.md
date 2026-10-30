# DD: what docs/working/questions.md is for

**Goal:** Decide how to split or reorganize the purposes `docs/working/questions.md` currently serves, so the owner has one clear entry point to what is blocked on them.
**Project state:** design doc on main · standalone (owner feedback in `docs/human-author/answers-10-28-26.txt`, "general:") · not blocked
**Task status:** complete (Q-221 answered [14′] 2026-10-28; record docs/decisions/040-questions-doc-owner-only.md; build is a roadmap Now item)

Variant: Double Diamond. Entry condition (b), a prior attempt solved a nearby problem: the
2026-09-17 triage (`docs/working/triage-2026-09-17-backlog.md` §3.1) already said "AGENT —
never shown as an ask" and "a trigger is not a question and must not sit in a question
queue". The fix it produced was the `Needs:` route column, which labels items but keeps them
in the same file. Six weeks later the owner reports the same pain, so a second pass on the
same framing would likely repeat the miss.

## Evidence at the start (2026-10-28, after recording answers-10-28-26)

Open entries by route ([observed], `scripts/questions.sh open`): `you: judgment` 0,
`you: terminal` 2 (Q-084, Q-167), `agent` 11, `deferred` 2, `trigger` 2. The file is 17
entries, about 300 lines; 2 of them are the owner's.

- Four `agent` entries (Q-092, Q-096, Q-110, Q-160) end "Ready for you to set ANSWERED": the
  work landed, but the dev cycle may not close an entry, so finished agent work waits on the
  owner as a bookkeeping act. [observed]
- Six `agent` entries carry a "Stuck (dev cycle 2026-10-25)" note that names another entry or
  a branch as the blocker (Q-097, Q-108, Q-125, Q-147, Q-168, Q-173). Their state is also in
  `docs/roadmap.md` (Now / Next) and `docs/working/briefs/`. [observed]
- The roadmap's own header says "this file says *what* and *in what order*, the questions doc
  says *who has to decide*" (`docs/roadmap.md:5-7`): the agent entries contradict the split the
  roadmap already declares. [observed]
- Ordering: the index sorts by route then ID; the `## Open` body is in insertion order with
  newest merge entries on top and older ones interleaved (Q-220 … Q-217, Q-167, Q-168, Q-169,
  Q-173, Q-160, Q-161, Q-108 …), so the body and the index disagree. [observed]
- Q-074's trigger date (2026-10-26) has passed; the entry still reads as an unfired watch. [observed]
- Owner-facing entries are long: a merge entry is ~25 lines, most of it gate output for the
  orchestrator, not for the reader. [observed]

## Diamond 1 — Purpose

### 1a. Candidate framings

1. **Two audiences, one file.** The owner has to read past agent bookkeeping to find their asks; the file should hold only what the owner discharges.
2. **Ordering only.** The problem is that the body order is arbitrary and disagrees with the index; a stable order fixes readability.
3. **Agent state has no proper home.** `agent`/`trigger`/`deferred` items are a work tracker squeezed into a Q&A grammar, duplicating the roadmap and briefs; they need one home of their own.
4. **Closure authority is misallocated.** Agent entries pile up because only the owner may close an entry, so finished agent work becomes an owner chore.
5. **Owner entries are too long.** Even a pure owner file would be hard to read: each ask is a 25-line report whose gate output is for the orchestrator.
   *Owner correction (2026-10-28): misframed. The orchestrator notes are easy to spot and skip. The common cost is clarity: jargon and bare references (route IDs, rubric row names, Q-numbers given without what they were) that the owner has to rebuild context for. Fixing that often makes entries **longer**. Restated: **5′ Owner entries cost context to read**: each ask should be understandable without opening other entries or knowing internal shorthand.*
6. **Null: already solved.** The route column and the sorted index already separate the audiences; the owner can read the index's top rows and stop.
7. **Zoom out: the entry point is the interface, not the file.** The owner's real touchpoints are the end-of-run summary and the answers file; the problem is that no single surface lists exactly what is blocked on them, of which the file is one candidate.
8. **Zoom out: the protocol is global.** `questions.sh` and the grammar ship to every project via `global-instructions/CLAUDE.md`; any fix has to be a protocol change, not a repo-local tidy-up.
9. **Failure form: watched items rot unseen.** Triggers and deferrals sit where the owner skims and the agents re-read, so neither party owns watching them (Q-074 passed its date silently).

Health check: stakeholders covered are owner (1, 2, 5, 6, 7), maintainer/agent (3, 4, 9) and
other repos' users (8); scopes are sub-problem (2, 4, 5), system (1, 3, 6, 9) and
meta-problem (7, 8). No clustering past two near-variants (1 and 7).

### 2a. What each framing implies

| # | Success criterion | Implied solutions | Leaves out | Stakeholder | Scope |
|---|---|---|---|---|---|
| 1 | The owner surface holds only `you:*` entries | split the file by route | where agent state goes; closure chore | owner | system |
| 2 | Body order equals index order | sort in `questions.sh index` | the mixing itself (owner still reads 15 non-owner entries) | owner | sub-problem |
| 3 | Each agent item has exactly one home | move agent items to roadmap / a tracker | the owner surface's length and order | maintainer | system |
| 4 | Zero entries wait on the owner only to be closed | let the cycle close entries whose closure condition is observed | mixing, order | owner + maintainer | sub-problem |
| 5′ | The owner can answer an ask without opening another entry or decoding shorthand | plain-language context in each entry, even at more length | mixing (hard concern) | owner | sub-problem |
| 6 | — | nothing | the owner's stated pain (hard concern) | — | system |
| 7 | One place lists exactly the owner's blocked items, in one step | a generated view, a file split, or a summary | how agent state is stored | owner | meta |
| 8 | The fix works in every repo `questions.sh` serves | change the global grammar and script | — (a constraint, not a problem) | other repos | meta |
| 9 | Every watch has one owner that checks it | give watches an agent-owned home | owner surface | maintainer | system |

Framing 6 leaves out the owner's report, which is the triggering situation: out. Framing 2
and 5 each leave out the mixing, the core complaint: they survive as constraints on the
chosen framing, not as framings. Framing 8 is a constraint on any solution. Framings 1 and 7
share a success criterion; 7 is the more general (it does not presume a file split).

### 3a. Chosen framing record

> **Chosen framing**: the owner needs one surface that lists exactly the items blocked on
> their judgment or their hands, in a predictable order, and nothing else; everything the
> agents track for themselves (work, triggers, deferrals, finished-but-unclosed entries)
> needs a home the agents own and check, so it neither crowds the owner's surface nor rots.
> We selected this (7, with 3, 4 and 9 folded in) over framing 1 because 1 presumes the
> answer is a file split and says nothing about where agent state goes or who closes it, and
> over framing 2 because ordering alone leaves the mixing in place. Diamond 2 generates
> solutions against this framing; ordering (2), entry length (5) and the global protocol (8)
> enter as constraints. Approaches that only reorder or only shorten are out of scope as
> complete answers.

### 3a′. Owner notes on the framing (2026-10-28, while reading)

- **Framings 7 and 8 are central.** The consequences reach every project the owner runs, not
  only this repo. Framing 8 is not just one constraint (H5).
- **1, 3, 4 and 9 matter for the specifics.** Framing 5 is relevant but was misframed; it is
  restated above as 5′, clarity rather than length.
- **Ordering (framing 2) is mostly a symptom of the mixing.** The owner scrolls past items not
  blocked on them to check whether they have answered everything. A stable order matters
  again at scale: confirming that 5–10 items are done is easy, but 100–1000 needs triage.
- **Scale across projects.** The ideal surface spans repositories and projects; the owner
  floated something like the threadwork wiki as an example. About 100 open owner items
  across projects is realistic in the short term.
- **Owner-blocked work that is not a question.** Product walkthroughs and playtest to-dos
  are easy for the owner to get blocked on and central to every project. The surface should
  point at them too.

- **A single cross-project surface is aspirational, not a next-release requirement.**
  Cross-project work brings a broader set of concerns, which are easier to answer in phases.
  This is not a reason to delay the per-repo work.

**Revised chosen framing (phased):** each project gives the owner one entry point that lists
exactly the work blocked on them: decisions, terminal pastes and, in time, hands-on tasks such
as walkthroughs and playtests. It must say at a glance whether anything is still unaddressed.
Each project's agent-internal state lives in a home the agents own and check, so it never
reaches that entry point. That per-repo split is the next release. It is also shaped so the
direction stays open: a later phase can aggregate every project's owner items into one
surface, triageable at ~100 items and beyond. The 2026-09-17 triage's "route, not rank" (§3.1)
was written for 19 items in one repo; ranking *within* the owner routes is a later-phase
concern, not this release's.

Phases, as the framing now implies (an outline, not a commitment):

1. **Per-repo split (this decision).** The owner file holds only owner items; agent state
   goes to an agent-owned home. Framings 1, 3, 4 and 9; 5′ (clarity) as a follow-up. Keep the
   entry grammar machine-readable, so phase 2 can read every repo's file without a migration.
2. **Read-only aggregation.** One command or generated page lists the open owner items of
   every project (the `questions.sh` repos), with a stable order and a count of what is
   still open. Candidate [6] (a hosted page) is revived here. It was pruned below for
   portability, but spanning repos is now the point.
3. **A home in the owner's own tooling.** Ranking at ~100 items belongs here. Threadwork's
   task-tree slice was retired on 2026-08-04 (`tasktree-slice.md:3-7`). Its "agency tiers"
   idea lives on as the wiki's `agency::` property (delegate / walk-me-through /
   do-it-myself; `src/wiki/server.py:125,130`). Its to-do list is a saved query over
   page properties. The interface vision (`interface-vision.md`) names dogfood testing as the
   clearest do-it-myself task. An owner item from any repo is an item whose agency is
   do-it-myself or decide; walkthroughs and playtests fit the same shape.

**Prior-art survey (2026-10-28; threadwork, dayplanner-web, meta-formalism-copilot).**
Ideas worth carrying:

- **Lists are queries over item fields, not separate objects** (threadwork wiki). If every
  owner item carries structured fields when it is filed (`kind`, who acts, project, opened
  date), phase 2 is a collect-by-query and phase-3 views are saved queries ("decisions",
  "hands-on", "open > 7 days").
- **Who acts as a first-class field.** The wiki's `agency::` maps onto decide /
  do-by-hand / agent-resumable.
- **Project comes from where the file is, not what an agent wrote.** The read-only analogue
  of the wiki stamping the project from the contribution token (`contrib.py`).
- **"All addressed" is a count reaching zero.** Use per-project open counts, grouped and
  collapsible (wiki "All pages" by first category; meta-formalism's processed/total bar), and
  review one project's batch at a time (the wiki's one-proposal-per-contribution;
  dayplanner's "Apply N").
- **Resolution is soft and kept.** An archive, never a delete (wiki trash and kept
  rejections; `questions-archive.md` already does this).

Evidence against some phase-2 shapes:

- Every server-backed tool here stalled on adoption. The wiki's contribution endpoint is
  built and tested (~50 tests) with **no project connected** (`docs/wiki-status.md`).
  dayplanner and meta-formalism need a running server too. A generated markdown rollup fits
  the owner's VSCode + git-status workflow. The wiki's one-`.md`-per-page backend shows the
  files can stay the source of truth with tooling layered on later.
- Hand-maintained tags rot. dayplanner's own live-with note says the tag UX was "bad enough
  I won't maintain filters". Grouping fields must be written by the agent that files the
  item, never curated by the owner.
- Aggregating every project in one place makes a single high-value target
  (`wiki-multi-project.md` S1). A local, uncommitted rollup avoids that; committing it to a
  shared remote does not, if any source repo is private.
- Markdown cannot filter. At 100+ items, phase 3 needs a query or saved-view generator over
  the same files, not a new store.

Implication for phase 1: give the owner-entry grammar the fields that make phase 2 a pure
read (a kind field that admits hands-on tasks, and a stable opened date). It is already
almost there: `**Needs:**` is the who-acts field, and `**Opened:**` is the date.

**Owner's actual interface (note, 2026-10-28):** VSCode with the Claude CLI, chosen over
their own tools for file navigation, git status, tight integration with running code, and
markdown reading panels. Prior interface work they liked lives in
`external/threadwork` (`src/wiki/`: a page wiki with derived to-dos and token-gated
cross-project contributions, `src/tasktree`), `external/dayplanner-web` and
`external/meta-formalism-copilot`. Implication: a phase-2 surface should read well as a
markdown file in that editor before it is a web page. A hosted page (revived [6]) has to beat
"a generated `.md` the owner opens next to git status".

Consequence for Diamond 2 below: it answers phase 1. Two additions carry phase 1 → 2: entry
grammar stays parseable across repos (soft, S5), and IDs eventually need a project qualifier
(e.g. `herald:Q-012`) when aggregated, which phase 1 need not build. Whether hands-on tasks
(walkthroughs, playtests) get a `you:` route of their own in phase 1 or wait for phase 3 is an
open question for the owner.

## Diamond 2 — Solution

### Consumer map (from a read-only survey, 2026-10-28)

- Four parsers hardcode exactly `questions.md` + `questions-archive.md`: `scripts/questions.sh`,
  `scripts/lib/dev-cycle-read.sh` (`check_answer`, :2189), `scripts/build-loop.sh`
  (`--approved` :1490-1511, `--main-log` answers class :180-187, `--cycle-diff`/`--land-cycle`
  :198-253) and `scripts/dev-cycle.sh` (section 3 parses `questions.sh open`, :391-418). All
  four are gate code (`merge-gate-*` approval).
- `--cycle-diff` refuses any change to an entry's heading, `**Needs:**` line or answer lines
  unless the user's in-session `--answered` names it (`build-loop.sh:209-215`,
  `SKILL.md:749-755`). This is the anti-forgery rule: no agent closes an owner's ask. It is
  also why finished `agent` entries wait on the owner, and it makes step 3's own instruction
  "change its route" (`SKILL.md:447`) a refusal: the route is on the `**Needs:**` line.
- `questions.sh` sorts the index and `open` by route then ID (:209-217); `## Open` is never
  sorted (:439). Tests pin the index order (`test/questions-doc.bats:139`, `:231`).
- About 76 tests build questions fixtures (questions-doc 20, dev-cycle ~26, orchestrator ~13,
  build-loop-check 6, merge 6, others 5).
- Duplicated state: Q-092, Q-110, Q-160 are in roadmap Done and still open here; Q-168/Q-173
  are a roadmap Now item, a brief, and two entries.
- No decision record or log row covers the doc's structure; it dates from e96912de
  (2026-09-17) and the triage doc §3.1.

### 1. Diverge

Prior pruning grep: no matches found for [questions, queue, inbox, attention, route, triage]
in `docs/decisions/*` Pruned-candidates sections. Candidate 0 is the 2026-09-17 status quo.

0. Status quo: one file, the `Needs:` route column labels the audience.
1. Minimal: sort the `## Open` body to match the index (route, then ID).
2. Watch file: `questions.md` holds `you:*` only; a second file (`docs/working/watching.md`) in the same entry grammar holds `agent`/`trigger`/`deferred`, served by `questions.sh`.
3. Roadmap home: `questions.md` holds `you:*` only; `agent` items become roadmap Now/Next/Done lines (most already are) and `trigger`/`deferred` items move to a new roadmap `## Watching` section the dev cycle checks.
4. Two sections, one file: `## For you` on top, `## Agent-tracked` below, index split into two tables, plus a `--cycle-diff` exemption so agents can close entries in the lower section.
5. Generated inbox: the store stays mixed; `questions.sh inbox` writes or prints a `you:*`-only view that the owner reads.
6. Web page: an Artifact or dashboard renders the owner's queue from the files; the files become internal.
7. Closure only: let the cycle archive an `agent` entry whose closure condition is an observed landing on main.
8. Abolish non-owner routes: triggers go back into decision records' Revisit triggers (step 2 already reads them), deferrals into roadmap Next, agent work into roadmap/briefs; no new section anywhere.
9. One file per entry (`docs/working/questions/Q-NNN.md`) with a generated owner index.
10. GitHub issues with labels as the owner queue.
11. Short ask cards: an owner entry is a ≤10-line card (question, options table, interim); orchestrator detail such as gate output moves to the brief.
12. Ideal if free: a structured store (one JSON/YAML record per item) with the owner view and the agent view both generated.
13. Volume: enforce a one-cycle lifetime on `agent` entries (done or deleted) so few ever accumulate.

Health check: candidates 2, 3, 4, 5 and 8 all move one lever, *where an item is stored*
(clustering on storage location). Added 7 (closure authority), 11 (entry shape) and 13
(volume) after the check, as they move other dimensions. 1 is the minimal option, 12 the
ideal-if-free, 6, 9 and 10 the ones that feel wrong.

### 2. Diagnose

Hard:

Owner review of this list (2026-10-28) revised H1, H2, H3, H5 and H6; the earlier wording is
in git history.

- **H1 Owner-only surface, owner-addressed routes.** The owner's entry point lists only items
  addressed to the owner, and nothing the agents track for themselves. The owner routes are
  four: `you: judgment` (a decision), `you: terminal` (a paste on their machine),
  `you: walkthrough` (hands-on product use: a walkthrough or playtest only the owner can do;
  new) and `you: fyi` (a quick read that needs acknowledging, not deciding; new; answered
  `seen`, which can be batched, e.g. `Q-230–Q-235: seen`). success: `questions.sh check`
  accepts exactly these four routes in the owner file and fails on `agent`, `trigger` or
  `deferred` there; `questions.sh open` sorts the four owner routes ahead of nothing else.
- **H2 The owner answers in free text and never maintains the file.** The owner writes answers
  wherever is natural (today a `docs/human-author/answers-*.txt` file, or chat). An agent
  session transcribes them into the entries, archives them and commits. The owner is never
  expected to edit `questions.md`, keep its format, or pass its lint. Agents still may not
  answer, close, re-route or delete an owner entry on their own initiative (the anti-forgery
  rule), but the rule binds agents only; it must not push formatting work onto the owner.
  success: no workflow or spec step tells the owner to edit `questions.md`; the existing
  `--cycle-diff` refusal tests pass unchanged; a new case shows that moving a `you:*` entry
  out of the owner file is refused.
  *Finding (2026-10-28):* no script ingests answers files today. `rg 'answers-' scripts/`
  finds nothing, and this session recorded answers-10-28-26 by hand with an ad hoc script.
  Transcription is unscripted agent work, which a `questions.sh record <answers-file>` could
  make repeatable. That is a candidate, not a constraint.
- **H3 One home for agent state, checked every cycle.** Each agent-tracked item lives in
  exactly one place, and the dev cycle's digest prints every open watch each iteration.
  success: no Q-ID appears both as an open entry and in roadmap Done; digest section 3 lists
  each watch with its condition. *Owner note:* audit existing projects for the ways this
  already fails before relying on it (see "H3 audit" below).
- **H4 Agents close their own items.** Finished agent work closes without an owner act.
  success: zero entries carry "Ready for you to set ANSWERED" after one cycle.
- **H5 Portability, stated as failure modes.** The change fails in another repo if any of
  these happen; each is a hard constraint with its own check:
  - **H5a No agent-state home** (no `docs/roadmap.md`, no dev cycle). An agent tries to file
    a trigger, `check` refuses it, and the item is dropped silently. success: the refusal
    names the fallback home, and `questions.sh init` creates it.
  - **H5b Version skew.** A session in another repo runs an older installed `questions.sh` or
    reads older global instructions that still list `agent` routes. Its filings then fail or
    drift. success: `check` on an owner file holding old routes says how to migrate rather
    than only failing, and a `migrate` subcommand moves them.
  - **H5c Existing mixed file.** A repo already has `agent`/`trigger` entries in its
    questions doc. success: `migrate` leaves the owner file with only owner routes and moves
    every other entry, with no entry lost (counts before and after match).
  - **H5d No cycle reads the watches.** In a repo where no dev cycle runs, triggers rot
    unread. success: the fallback home is something a plain session's start-of-session reading
    already covers, or the global spec says who checks it.
  - **H5e The agent-state home is an owner document.** A repo's roadmap is owner-written
    prose, and agents appending to it edit the owner's document. success: agents write only
    a section the spec marks as agent-owned (`## Watching`), or a separate file when the repo
    has none.
  - **H5f Other agents follow old text.** `AGENTS.md` / `GEMINI.md` and other tools carry the
    protocol separately. success: `test/agents-gemini-sync.bats` (or its equivalent) covers
    the new route list.
- **H7 Observation-named closures stay open.** A watch whose closure names an observation is
  not closed by inference (triage §1.3). success: the rule's text appears in the new home's
  spec, and step 3 cites it.

**Repo constraints (`docs/constraints.md`) that bind this decision.** This DD was not seeded
from that file at first: `workflows/divergent-design.md` never names it, although the
constraints-builder skill says DD passes are seeded with it. Checked 2026-10-28 at the owner's
prompt. The lines that apply:

- **H1 (gates run from a copy the change can't edit).** The route check, `migrate` and any
  `record` command live in `scripts/questions.sh`, which is gate code. A roadmap `## Watching`
  section that `dev-cycle.sh` parses is *input* to the cycle, not logic. That is allowed, but
  the parser must treat it as untrusted text.
- **H2 (fail closed and loudly).** This is the repo-level form of H5a and H5b. A refused agent
  filing must name where the item goes instead; it must never drop it. A missing Watching
  home must print "watches NOT checked" in the digest rather than read as zero watches.
- **H3 (hermetic tests).** Every option is testable in the sandbox. The H3 audit's host paste
  adds evidence; it does not replace tests.
- **S1 (gates defend against honest slips by a same-uid loop, not a hostile one).** This backs
  the owner's note that the anti-forgery rule (our H2) may be too strict. Its job is to stop
  an agent from *accidentally* answering or closing an owner entry, not to resist a
  determined one.
- **S2 (≤ ~30 lines added to always-loaded context).** The global instructions' "Running
  questions document" section loads in every session. The new route list and the agent-state
  home must fit within that budget, or state the measured delta.
- **S3 (one source of truth per grammar, never restated).** Today the route list is stated in
  `questions.sh`, the global instructions, the triage doc and `AGENTS.md`/`GEMINI.md`. The
  change should make the script the source and have the prose point at it (also H5f). This
  counts against [2], which adds a second file in the same grammar beside a roadmap that
  already tracks the same work.
- **S4 (mechanical steps in tested scripts).** Supports scripting answer transcription
  (`questions.sh record <answers-file>`) and the migration, rather than leaving them as
  unscripted agent work.
- **S6 (a new step needs a call site something runs).** The Watching home needs a reader in
  repos with no dev cycle (H5d). `record` needs a call site, such as the recording session's
  documented first step.
- **S8 (units under ~400 lines, revertible).** The build splits into units: routes and check;
  migrate; the Watching home and digest; record.
- **S10 (spend the user's attention last; no new recurring chore).** `you: fyi` is a new
  recurring acknowledgement chore, so it must stay cheap: batch acks, and a rule for when an
  agent may use it. `you: walkthrough` is real owner work, not a chore. The H3 audit is held
  to one host paste.
- **S11 (portable, pure text).** Favors markdown homes over a server, consistent with the
  survey's evidence for phase 2.

**H3 audit (to run before building).** Only `external/threadwork` among the mounted repos has
a questions doc (4 entries, all `you:*`). The owner's other projects (herald, android and the
rest) are not mounted here, so the audit needs either those checkouts or a host-side paste
that counts, per repo, open entries by route, entries duplicated in a roadmap or tracker, and
`trigger`/`deferred` entries past their own date.

Soft:

- **S1** An owner entry is self-explaining: each internal reference it uses (a Q-ID, rubric row, route or residual name) comes with a plain-language gloss of what it is. Length is not the measure (owner correction to framing 5, 2026-10-28).
- **S2** Small gate-code and fixture churn (one `merge-gate` approval, under ~400 lines).
- **S3** Existing Q-IDs keep working as handles in commits, briefs and the roadmap.
- **S4** A fired trigger that reopens a choice still becomes a `you: judgment` entry.
- **S5** (phase 1 → 2) The owner file's grammar stays the same in every repo, so a later
  aggregator can read all of them without a migration.
- **S6 Predictable order** (was H6; demoted by the owner, 2026-10-28). Order mainly hurts
  through the mixing and matters again at scale. success: a `questions-doc.bats` case shows
  the owner file's body order equals its index order.

### 3. Match and prune

#### Rescore after the owner's constraint review (2026-10-28)

The first matrix and step-4 table further down are superseded by this one. That matrix
assumed one undivided "agent state" and a single portability check; H5a–f split both apart.
The rescore turned up a split the first pass missed. Agent state is two different things:

- **Agent work** (`agent` route): a task an agent will do. Dev-cycle repos already track it in
  the roadmap and briefs, and every one of today's 11 `agent` entries duplicates a roadmap
  line, a brief or a branch.
- **Watches** (`trigger` / `deferred`): a condition someone must check later. Nothing else
  tracks these.

That split gives a new candidate:

14. **Watch file plus the work tracker.** Watches go to `docs/working/watching.md`, an
    agent-owned file in the questions entry grammar that `questions.sh` creates (`init`),
    checks and lists (`watches`), with closed watches kept in its own `## Closed` section.
    Agent work gets no queue entry at all: an agent does it now, or writes it in the
    project's work tracker. That is the roadmap where the dev cycle keeps one, and
    `watching.md`'s `## Agent work` section where none exists. The owner file takes only the
    four `you:` routes.

Hard constraints now: H1–H4, H5a–f, H7, plus repo H2 (fail loud). Repo H1/H3 and S11 are
met by every survivor and left out.

| # | H1 | H2 | H3 | H4 | 5a | 5b | 5c | 5d | 5e | 5f | H7 | rH2 | notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 Roadmap home | ✓ | ✓ | ✓ | ✓ | ~ | ✓ | ✓ | ~ | ✗? | ✓ | ✓ | ~ | 5e fails wherever a roadmap is the owner's prose; parsing a prose section is weaker than a grammar check (rH2) |
| 2 Watch file (all agent state) | ✓ | ✓ | ~ | ✓ | ✓ | ✓ | ✓ | ~ | ✓ | ✓ | ✓ | ✓ | in dev-cycle repos agent work sits in both the watch file and the roadmap (H3 ~, repo S3) |
| 14 Watch file + work tracker | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ~ | ✓ | ✓ | ✓ | ✓ | two homes for agent work by repo type: one rule, two places |
| 4 Two sections | ~ | ⚠ | ✗ | ~ | ✓ | ✓ | ✓ | ✗ | ✓ | ✓ | ✓ | ✓ | owner still opens a mixed file; exemption loosens the anti-forgery rule |

5d (who reads watches in a repo with no dev cycle) is ~ for every option. Its fix is shared:
one line in the global instructions' questions section telling a session to run
`questions.sh watches` at start, which prints only due or overdue watches. That costs one line
of always-loaded context (repo S2) and gives one call site (repo S6).

Pruned in the rescore: [4] (⚠ H2, ✗ H3, ✗ 5d).

| # | Approach | Effort | Risk | Hard met | Key downside |
|---|---|---|---|---|---|
| 14 ★ | Watch file + work tracker | ~1.5 days; 4 units of ~100 lines (routes+check · migrate · watches+digest · global text) | low | 14/15 (5d ~, shared) | agent work has one rule but two possible places, depending on whether the repo runs a dev cycle |
| 1 | Roadmap home | ~1 day; 3 units | med | 12/15 (5a ~, 5e ✗?, rH2 ~) | puts agents into a document that is the owner's in some repos; prose parsing |
| 2 | Watch file, all agent state | ~1.5 days; 4 units | low-med | 13/15 (H3 ~) | duplicates the roadmap in dev-cycle repos, the same duplication the owner sees today |

Hypotheses:

- [14] If chosen, within 3 dev-cycle iterations after landing, the owner file holds only the
  four `you:` routes; no Q-ID is open in both `watching.md` and the roadmap; and every watch
  past its date appears in the next session's `questions.sh watches` output. Counter-evidence
  is a watch passing its date unprinted (as Q-074 did), or an `agent` item filed in
  `watching.md` in a repo that has a roadmap.
- [1] Same window. Counter-evidence is an agent edit inside an owner-written roadmap section,
  or a malformed Watching bullet that the digest silently skips.
- [2] Same window. Counter-evidence is the same work item open in `watching.md` and in roadmap
  Now/Next.

Stress tests:

- *Boring alternative* ([14] vs [1]): [1] is still less code. But it buys that by parsing
  prose and writing into a file that may be the owner's, and those are the two failure modes
  the owner asked to be stated (5e, rH2).
- *Invert the thesis* ([14]): "two places for agent work" could become the next mixing
  complaint. It doesn't reach the owner's surface, though, and a repo has exactly one of
  the two. That residual is acceptable.
- *Failure-driven* ([14]): a closed watch must not go to `questions-archive.md`, since
  `--cycle-diff` refuses a new entry filed answered there. Its own `## Closed` section keeps
  it out of the anti-forgery rule's scope, and also out of its protection, which is right for
  agent-owned items (repo S1).
- *Push to extreme* ([14]): at 100 watches across a repo, `questions.sh watches` prints only
  due and overdue ones, so the session-start cost stays flat.

**Would the H3 audit change the answer?** Only in one direction. [14] scores the same whatever
the audit finds. [1] overtakes it only if every one of the owner's repos with agent state has
a dev-cycle-maintained roadmap (5e ✓ and 5a ✓ everywhere). In that case [1] is slightly
cheaper and the two places for agent work collapse to one. The audit result that would flip
the recommendation is therefore "every repo's roadmap is agent-maintained, and no repo without
one files watches". The audit is also the input for sizing the migration (5c) whichever option
is chosen.

▶ recommend [14] Watch file + work tracker · confidence ~75% · runner-up [1], axis = fewer
moving parts vs. no agent writes into owner documents

#### Owner premise (2026-10-28): every project follows the dev cycle

The owner: "it's safe to assume that all projects will follow the dev-cycle." That settles
the audit's flip condition by premise. Every repo has a roadmap the cycle maintains, and a
cycle that reads the watches. Consequences:

- 5a (no home for agent items) and 5e (the agent home is an owner document) are ✓ for [1].
- 5d (nothing reads the watches) is ✓ for both: the dev cycle reads them, so the
  session-start `questions.sh watches` line in the global instructions is unneeded (and its
  always-loaded context cost goes with it).
- [14]'s "no tracker" branch never fires, so it simplifies to **[14′]**: watches go in
  `watching.md` (entry grammar, checked by `questions.sh`, closed ones kept in `## Closed`),
  and agent work goes in the roadmap only. Agent work now has one home in every repo.
- The H3 audit is no longer needed for the decision. It stays as input for migration sizing
  (5c).

| # | Approach | Effort | Risk | Hard met | Key downside |
|---|---|---|---|---|---|
| 14′ ★ | Watches in `watching.md`, agent work in the roadmap | ~1 day; 3 units (routes+check · watching.md+migrate · cycle steps 2/3 + global text) | low | 15/15 | one more file in `docs/working/` |
| 1 | Watches in a roadmap `## Watching` section, agent work in the roadmap | ~1 day; 3 units | low-med | 14/15 (rH2 ~) | watches become prose bullets with a new ad hoc format, which a parser reads leniently, not checked against the entry grammar (repo S3: a second grammar; repo H2: a malformed bullet can be skipped silently) |
| 2 | Everything in a watch file | — | — | — | dominated by 14′ now that every repo has a roadmap |

Remaining axis: *one file fewer* ([1]) vs *watches keep the entry grammar that `questions.sh`
already checks, IDs and closure criteria included* ([14′]). The tiebreaker is repo S3 (one
grammar, one checker), together with H7: a watch's observation-named closure criterion is a
field in the entry grammar, and only a convention in a bullet.

▶ recommend [14′] · confidence ~65% · runner-up [1], axis = one file fewer vs. one checked
grammar

New revisit trigger: if a project that does not run the dev cycle adopts `questions.sh`, then
5a, 5d and 5e return; re-run this rescore with [14]'s fallback branch.

*(Original first-pass matrix, superseded, kept for the record:)*

| # | H1 | H2 | H3 | H4 | H5 | H6 | H7 | notes |
|---|---|---|---|---|---|---|---|---|
| 0 | ✗ | ✓ | ✗ | ✗ | ✓ | ✗ | ✓ | the reported pain |
| 1 | ✗ | ✓ | ✗ | ✗ | ✓ | ✓ | ✓ | fold into survivors |
| 2 | ✓ | ✓ | ~ | ✓ | ✓ | ✓ | ✓ | watch file outside `--cycle-diff`; duplicates roadmap for agent work |
| 3 | ✓ | ✓ | ✓ | ✓ | ~ | ✓ | ✓ | repos without a roadmap need a fallback |
| 4 | ~ | ⚠ | ✗ | ~ | ✓ | ✓ | ✓ | exemption by section lets a re-route close an owner ask |
| 5 | ✓ | ✓ | ✗ | ✗ | ✓ | ✓ | ✓ | view only; closure and rot unchanged |
| 6 | ✓ | ✓ | ✗ | ✗ | ✗ | ✓ | ✓ | infra, not portable |
| 7 | ✗ | ⚠ | ~ | ✓ | ✓ | ✗ | ~ | needs a cycle-diff hole |
| 8 | ✓ | ✓ | ~ | ✓ | ✗ | ✓ | ~ | Revisit triggers can't hold one-off watches like Q-074 |
| 9 | ✓ | ~ | ~ | ~ | ✓ | ✓ | ✓ | rewrites all four parsers |
| 10 | ✓ | ✗ | ✗ | ✗ | ✗ | ~ | ~ | memory: no GitHub routing |
| 11 | ✗ | ✓ | ✗ | ✗ | ✓ | ✗ | ✓ | complement (S1), not an answer |
| 12 | ✓ | ~ | ✓ | ✓ | ~ | ✓ | ✓ | rewrites every parser, ~76 tests |
| 13 | ✗ | ✓ | ~ | ~ | ✓ | ✗ | ⚠ | forces closing watches on a clock |

Survivors: [3], [2], [4] (with a fix). Fixes: [3] in a repo without `docs/roadmap.md`, the
global spec names the fallback home: create `docs/roadmap.md` with only `## Watching`.
[4] needs a second rule: `--cycle-diff` refuses any route change *away from* `you:*`, so the
exemption can't be used to launder an owner ask. That rule is more gate code on the
anti-forgery path. [1] and [11] fold into whichever wins: sort the owner body (H6), and
shorter merge entries are a separate step-7 change (S1, filed as a follow-up).

### 4. Tradeoff matrix

| # | Approach | Effort | Risk | Hard met | Key downside |
|---|---|---|---|---|---|
| 3 | Roadmap home | ~1 day; ~250 lines incl. tests; 1 merge-gate | low | 7/7 (H5 with fallback) | the roadmap gains a machine-read section; one-off watches lose the Q grammar |
| 2 | Watch file | ~1.5–2 days; ~400 lines; 1 merge-gate | med | 6.5/7 (H3 ~) | a second queue in the questions grammar; agent work is still duplicated in the roadmap |
| 4 | Two sections + exemption | ~1.5 days; edits `--cycle-diff` | med-high | 5/7 | owner still opens a file that is mostly not theirs; loosens the anti-forgery rule |

Hypotheses:

- [3] If chosen, within 3 dev-cycle iterations after landing `questions.md` holds only `you:*`
  entries, no Q-ID is open both there and in the roadmap, and every watch shows a dated check
  line in the cycle record; counter-evidence = `questions.sh check` refuses a cycle's
  agent-route filing, or a watch passes its date with no note (as Q-074 did on 2026-10-26).
- [2] If chosen, within 3 iterations the owner file holds only `you:*`; counter-evidence = the
  same Q-ID sits in `watching.md` and roadmap Now/Done, or `watching.md` keeps a finished item
  past one cycle.
- [4] If chosen, within 3 iterations the owner reads only the top section; counter-evidence =
  the owner again reports the file as hard to read, or a closure needs the exemption on an
  entry that was once `you:*`.

Stress tests:

- *Revealed preferences* ([3], [2]): the agents already use the roadmap as their tracker; Q-092,
  Q-110 and Q-160 reached roadmap Done while their entries stayed open. [3] removes the copy
  the agents keep forgetting; [2] builds a new one beside the copy they already keep. Raised
  [2]'s risk to med.
- *Boring alternative* ([2] vs [3]): [3] is the boring one. It adds no file, no grammar and no
  archive semantics. [2] would also need a closed-item rule: closed watch entries can't go to
  `questions-archive.md`, because `--cycle-diff` refuses a new entry filed answered.
- *Invert the thesis* ([3]): the case for [2] is portability. Every repo gets `questions.sh`,
  and few have a roadmap. That holds only if other repos actually file `agent`/`trigger`
  entries; the global spec's fallback covers it at a one-section cost. Kept [3]'s H5 at ~.
- *Failure-driven* ([4]): a re-route from `you: judgment` to `agent` followed by a close is a
  forged answer. The fix rule exists, but it puts new code on the gate path the owner relies
  on most. Risk stays med-high.
- *Push to extreme* ([3]): at 30 watches the roadmap's Watching section is still one list the
  digest prints. The roadmap is 274 lines today, 150 of them Ideas. Fine.

### Decision (Path C: away mode, filed as a `you: judgment` entry)

Recommend [3] at ~70%. Runner-up [2]; the axis is *reuse the tracker the agents already keep*
vs *one generic script-served home that works in every repo*. No stated preference was found.
Tiebreaker: the owner's stated goal is a single entry point, and [3] adds no new file anywhere.

### What [3] would change (the plan, if chosen)

1. `scripts/questions.sh`: the live file accepts only `you: judgment` / `you: terminal`
   (`check` errors on other routes there; the archive keeps accepting all routes for
   history). `index` also rewrites the `## Open` body into index order (H6).
2. `docs/roadmap.md` gains `## Watching`: one bullet per watch, as
   `- **Q-074 · failure-pattern-writer-trigger** — condition · check · if met → action`.
   Existing IDs are kept as labels (S3). New watches take the next Q-ID from `next-id`, so IDs
   stay unique across both homes.
3. `scripts/dev-cycle.sh` section 3 prints the roadmap's Watching section instead of filtering
   `questions.sh open`. The dev-cycle skill's step 2 files a fired trigger as a roadmap
   Now/Next line when its response is named, and as a `you: judgment` entry when it reopens a
   choice (S4). Step 3 reads Watching, notes each check, moves a met watch to Now, and keeps
   the H7 rule. Step 6 owns Done.
4. Migration in one cycle commit, with an `--answered` list the owner gives in-session:
   - The 4 finished `agent` entries close as done.
   - The 7 stuck `agent` entries become roadmap lines; most already are, so only the IDs are
     added.
   - Q-067, Q-098, Q-074 and Q-161 move to Watching.
   - Q-074's passed date is acted on in the same cycle.
5. The global instructions' "Running questions document" section: the file is the owner's
   queue only. `agent`, `trigger` and `deferred` leave the route list, and the spec points at
   the project tracker (`docs/roadmap.md` `## Watching`, created if absent).
   `workflows/divergent-design.md` Path C is unchanged.
6. Tests: `questions-doc.bats` (route refusal, body order), `dev-cycle.bats` section-3
   fixtures, plus an orchestrator case showing a `you:*` entry moved out is refused (H2).
7. Follow-up, separate: entry clarity (S1). Each entry writer (dev-cycle step 7's merge
   entries, step 2/3 filings, Path C) glosses every internal reference it uses, even when
   that makes the entry longer. Moving gate output out of the entry is optional, since the
   owner can skim it.

## Pruned candidates and why

Each entry is `[candidate-ID]: one-line reason for discard`. Future DDs in adjacent areas can grep this section to avoid regenerating already-pruned approaches.
[0]: the reported pain (H1, H3, H4). [1]: order only; folded into [3] as H6. [5]: a view; closure and rot unchanged (H3, H4). [6]: infrastructure, not portable (H5). [7]: needs a hole in `--cycle-diff` (⚠ H2); [3] gets H4 without one. [8]: Revisit triggers can't hold one-off watches (Q-074, Q-161), and repos without decision records lose triggers (H5). [9]: rewrites all four gate parsers for no gain over [3]. [10]: GitHub routing excluded by the owner (memory: solo dev, no GitHub routing). [11]: aimed at length, which the owner says is the wrong measure; replaced by the clarity follow-up (S1). [12]: rewrites every parser and ~76 tests. [13]: closes watches on a clock (⚠ H7). [4]: loosens the anti-forgery rule, and the owner still opens a mixed file. [2]: runner-up; a second copy of the agent tracker beside the roadmap.
Prior pruning grep: no matches found for [questions, queue, inbox, attention, route, triage].

## Revisit triggers

Each entry is a concrete, observable condition that should prompt re-evaluating this decision. Future readers can grep this section when their context changes to see whether earlier decisions still apply.
If a project that does not run the dev cycle adopts `questions.sh` (the 2026-10-28 owner premise breaks; 5a/5d/5e return). If a second repo using `questions.sh` files more than 3 `trigger`/`deferred` items within a month (portability favors [2]). If the roadmap's Watching section passes 30 items. If the owner again reports the owner file as hard to read with only `you:*` entries in it (entry length, S1, is then the problem). If `you: judgment` asks exceed ~5 per cycle (triage §3.1's router alarm).
