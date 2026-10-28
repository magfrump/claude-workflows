# DD: what docs/working/questions.md is for

**Goal:** Decide how to split or reorganize the purposes `docs/working/questions.md` currently serves, so the owner has one clear entry point to what is blocked on them.
**Project state:** design doc on main · standalone (owner feedback in `docs/human-author/answers-10-28-26.txt`, "general:") · not blocked
**Task status:** blocked (decision filed for the owner as a `you: judgment` entry; nothing implemented)

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
| 5 | Each owner ask fits a screen, detail linked | summary + link entries | mixing (hard concern) | owner | sub-problem |
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

- **H1 Owner-only surface.** The owner's entry point lists only items blocked on the owner's
  judgment or hands. success: `scripts/questions.sh open` against it prints only `you: judgment`
  / `you: terminal` rows, and `questions.sh check` fails on any other route there.
- **H2 Anti-forgery kept.** No agent can answer, close, re-route or delete an owner entry.
  success: the existing `--cycle-diff` refusal tests in `test/scripts/build-loop-orchestrator.bats`
  pass unchanged, and a new case shows that moving a `you:*` entry out of the owner file is refused.
- **H3 One home for agent state, checked every cycle.** Each agent-tracked item lives in
  exactly one place, and the dev cycle's digest prints every open watch each iteration.
  success: no Q-ID appears both as an open entry and in roadmap Done; digest section 3 lists
  each watch with its condition.
- **H4 Agents close their own items.** Finished agent work closes without an owner act.
  success: zero entries carry "Ready for you to set ANSWERED" after one cycle.
- **H5 Works in every repo `questions.sh` serves.** success: `questions.sh init` + `check` pass
  in a fresh repo with no roadmap or dev cycle.
- **H6 Predictable order.** success: a `questions-doc.bats` case shows the owner file's body
  order equals its index order.
- **H7 Observation-named closures stay open.** A watch whose closure names an observation is
  not closed by inference (triage §1.3). success: the rule's text appears in the new home's
  spec, and step 3 cites it.

Soft:

- **S1** An owner entry fits one screen (~15 lines), detail linked.
- **S2** Small gate-code and fixture churn (one `merge-gate` approval, under ~400 lines).
- **S3** Existing Q-IDs keep working as handles in commits, briefs and the roadmap.
- **S4** A fired trigger that reopens a choice still becomes a `you: judgment` entry.

### 3. Match and prune

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
7. Follow-up, separate: shorter step-7 merge entries (S1), with gate output moved to the
   brief and the entry keeping the summary and options.

## Pruned candidates and why

Each entry is `[candidate-ID]: one-line reason for discard`. Future DDs in adjacent areas can grep this section to avoid regenerating already-pruned approaches.
[0]: the reported pain (H1, H3, H4). [1]: order only; folded into [3] as H6. [5]: a view; closure and rot unchanged (H3, H4). [6]: infrastructure, not portable (H5). [7]: needs a hole in `--cycle-diff` (⚠ H2); [3] gets H4 without one. [8]: Revisit triggers can't hold one-off watches (Q-074, Q-161), and repos without decision records lose triggers (H5). [9]: rewrites all four gate parsers for no gain over [3]. [10]: GitHub routing excluded by the owner (memory: solo dev, no GitHub routing). [11]: complement for S1, filed as a follow-up. [12]: rewrites every parser and ~76 tests. [13]: closes watches on a clock (⚠ H7). [4]: loosens the anti-forgery rule, and the owner still opens a mixed file. [2]: runner-up; a second copy of the agent tracker beside the roadmap.
Prior pruning grep: no matches found for [questions, queue, inbox, attention, route, triage].

## Revisit triggers

Each entry is a concrete, observable condition that should prompt re-evaluating this decision. Future readers can grep this section when their context changes to see whether earlier decisions still apply.
If a second repo using `questions.sh` files more than 3 `trigger`/`deferred` items within a month (portability favors [2]). If the roadmap's Watching section passes 30 items. If the owner again reports the owner file as hard to read with only `you:*` entries in it (entry length, S1, is then the problem). If `you: judgment` asks exceed ~5 per cycle (triage §3.1's router alarm).
