# Divergent Design: Feature Improvements for Workflow Repo

**Date:** 2026-03-23
**Scope:** Generate and evaluate feature improvement ideas across all workflows and skills in this repo.

---

## 1. Diverge — Candidate Feature Ideas

1. **Workflow chaining / composition syntax** — A way to declare that one workflow feeds into another (e.g., spike → RPI, onboarding → RPI) with explicit handoff points, rather than relying on prose cross-references.

2. **Session journal** — An append-only log file (`docs/working/session-journal.md`) that each session appends to with a timestamped entry: what was done, what decisions were made, what's left. Provides continuity across sessions without relying on memory or git log archaeology.

3. **Workflow self-evaluation skill** — A skill that applies the evaluation rubric (`docs/evaluation-rubric.md`) to a specified workflow or skill, producing a scored assessment. The rubric already notes this as a future possibility.

4. **Do nothing / status quo** — Keep the repo as-is, let usage patterns reveal what's actually missing before adding more.

5. **Diff-aware workflow selector** — A pre-step that looks at the current git state (branch, diff size, file types changed) and recommends which workflow to follow, reducing the "which workflow do I use?" decision cost.

6. **Plan diff tracking** — When a plan is revised during RPI step 4 (annotate), automatically produce a diff of the plan changes so the user can see exactly what shifted, rather than re-reading the whole plan.

7. **Workflow templates / scaffolding command** — A script or skill that creates the working doc stubs (e.g., `docs/working/research-{topic}.md` with section headers pre-filled) so you don't have to remember the format each time.

8. **Cross-session context snapshots** — At the end of a session, produce a structured "handoff document" that a fresh session can load to resume work. More structured than the session journal (idea 2) — contains specific file paths, open questions, and next steps.

9. **Retrospective workflow** — A structured post-mortem for completed features: what the plan predicted vs. what actually happened, which workflow steps were valuable vs. skipped, what to change next time. Feeds back into workflow improvement.

10. **Parallel session orchestrator skill** — Turn the human-oriented `guides/parallel-sessions.md` into an agent-invocable skill that sets up worktrees, dispatches tasks, and manages the merge sequence.

11. **Ideal-world: full pipeline visualization** — A generated diagram (mermaid or similar) showing how all workflows, skills, and patterns connect, auto-updated when files change. Would make the system legible at a glance.

12. **Confidence-calibrated gates** — Extend the DD 80% confidence threshold pattern to all workflow gates. Each gate gets a confidence annotation; gates below threshold pause for human input, gates above proceed. Makes the active/away mode distinction more granular.

13. **Skill composition / piping** — Allow skills to be chained in a Unix-pipe style: output of one skill becomes input to the next. E.g., `fact-check | cowen-critique | synthesize`. Currently only the orchestrator skills do this, and they're hardcoded.

14. **Research doc freshness tracking** — Add a "last verified" timestamp to research docs and onboarding docs. When the timestamp is older than N commits on the relevant files, flag the doc as potentially stale.

15. **Lightweight decision log** — A simpler alternative to full `docs/decisions/NNN-title.md` for small decisions that don't warrant a full DD pass. A single file with a table: date, decision, rationale, one line each.

---

## 2. Diagnose — Problems and Constraints

### Concrete problems these ideas address

**P1. Session continuity is fragile.** When starting a new session after context fills up, there's no structured way to resume. You rely on plan docs, git log, and memory — which works but has gaps. (Hard constraint: must not require the user to do manual bookkeeping.)

**P2. Workflow selection requires reading prose.** A user (or agent) facing a new task must scan 8 workflow descriptions to pick the right one. The CLAUDE.md and AGENTS.md summaries help, but there's still friction. (Soft constraint: the selection aid shouldn't be more complex than reading the summaries.)

**P3. No feedback loop from usage to workflow improvement.** Workflows evolve through manual observation, not structured reflection. There's no mechanism to capture "step 3 of RPI was useless for this task" or "the spike timebox was too short." (Soft constraint: should be lightweight enough to actually use.)

**P4. Orchestrator skills are hardcoded pipelines.** `draft-review` and `code-review` each define a fixed pipeline. Adding a new critic or changing the pipeline order requires editing the orchestrator skill. (Soft constraint: any composition mechanism must not sacrifice the reliability of explicit orchestration.)

**P5. Plan revisions are invisible.** During RPI step 4, the plan gets edited, but there's no record of what changed or why. The user has to re-read the whole plan to verify revisions. (Soft constraint: must not add overhead to the revision process itself.)

**P6. The evaluation rubric is unused in practice.** It exists as a reference document but has no trigger — nobody invokes it unless they remember it exists. (Soft constraint: a self-evaluation skill would need to produce actually useful signal, not just fill in a template.)

**P7. Research and onboarding docs go stale silently.** There's no mechanism to flag that the code has changed significantly since the doc was written. (Soft constraint: staleness detection must be cheap — can't re-read the whole codebase to check.)

**P8. Small decisions have no home.** The `docs/decisions/` format is great for significant choices but overkill for "I chose library X over Y because of Z." These small decisions get lost in commit messages. (Soft constraint: must not dilute the signal of the full decision records.)

### Non-obvious constraints

- **Context budget**: Features that add ceremony (more files to read, more steps to follow) eat into the agent's context window. The memory feedback note says not to over-optimize on this, but it's still a real cost.
- **Agent tool limitations**: Sub-agents can't read the orchestrator's files directly — prompts must be self-contained. Any composition mechanism must account for this.
- **Multi-agent compatibility**: Workflows need to work across Claude Code, Copilot (via AGENTS.md), and Gemini (via GEMINI.md). Features that depend on Claude-specific tools (Task, Agent) need graceful degradation.
- **Single maintainer**: This repo is maintained by one person. Features that require ongoing maintenance (keeping diagrams updated, curating decision logs) compete for attention.

---

## 3. Match and Prune

| # | Idea | P1 Session continuity | P2 Workflow selection | P3 Feedback loop | P4 Hardcoded pipelines | P5 Plan revisions | P6 Unused rubric | P7 Stale docs | P8 Small decisions |
|---|------|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| 1 | Workflow chaining syntax | ~ | ✓ | ✗ | ~ | ✗ | ✗ | ✗ | ✗ |
| 2 | Session journal | ✓ | ✗ | ~ | ✗ | ✗ | ✗ | ✗ | ✗ |
| 3 | Self-evaluation skill | ✗ | ✗ | ✓ | ✗ | ✗ | ✓ | ✗ | ✗ |
| 4 | Do nothing | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |
| 5 | Diff-aware workflow selector | ✗ | ✓ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |
| 6 | Plan diff tracking | ✗ | ✗ | ✗ | ✗ | ✓ | ✗ | ✗ | ✗ |
| 7 | Workflow templates | ~ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |
| 8 | Cross-session handoff doc | ✓ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |
| 9 | Retrospective workflow | ✗ | ✗ | ✓ | ✗ | ✗ | ✗ | ✗ | ✗ |
| 10 | Parallel session orchestrator | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |
| 11 | Pipeline visualization | ✗ | ✓ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |
| 12 | Confidence-calibrated gates | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |
| 13 | Skill piping | ✗ | ✗ | ✗ | ✓ | ✗ | ✗ | ✗ | ✗ |
| 14 | Research doc freshness | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✓ | ✗ |
| 15 | Lightweight decision log | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✓ |

### Notes on partial matches

- **#1 (chaining syntax)**: Partially helps P2 by making workflow relationships explicit, but the relationships are already documented in prose. Partially helps P4 but doesn't generalize composition — it just makes the existing handoffs more formal. Doesn't solve enough problems to justify a new abstraction.
- **#7 (templates)**: Slightly helps P1 by reducing the friction of starting a new session's docs, but the format is simple enough that agents generate it from the workflow description. Low incremental value.
- **#12 (confidence gates)**: Interesting idea but solves a problem that doesn't clearly exist yet — the active/away distinction already handles this at a coarser grain, and making it more granular adds complexity without demonstrated need.
- **#13 (skill piping)**: Addresses P4 but the agent tool limitation (sub-agents can't read files) makes generic piping impractical. The orchestrator pattern works precisely because it handles prompt assembly manually. A piping abstraction would either leak that complexity or hide it poorly.

### Discarded

- **#1** — Mostly ✗, partially addresses P2 and P4 but not convincingly.
- **#4** — The "do nothing" option. Reasonable if usage hasn't revealed pain, but several problems (P1, P3, P6) are real.
- **#5** — Solves P2 only, and the summaries in CLAUDE.md/AGENTS.md already do this adequately.
- **#6** — Solves P5 only. Plan diffs can be achieved with `git diff docs/working/plan-*.md` — doesn't need a feature.
- **#7** — Low incremental value; agents already generate the format.
- **#10** — Interesting but changes the repo's role from "workflow docs" to "automation tool." Also, git worktree setup is inherently interactive and project-specific.
- **#11** — Maintenance burden (keeping diagram in sync) outweighs benefit for a single maintainer. The prose cross-references are sufficient.
- **#12** — No demonstrated need beyond what active/away already provides.
- **#13** — Agent tool limitations make this impractical without significant infrastructure.

### Survivors

- **#2 Session journal** — Strong on P1.
- **#3 Self-evaluation skill** — Strong on P3 and P6.
- **#8 Cross-session handoff doc** — Strong on P1, more structured than #2.
- **#9 Retrospective workflow** — Strong on P3.
- **#14 Research doc freshness** — Strong on P7.
- **#15 Lightweight decision log** — Strong on P8.

### Fixing weaknesses

- **#2 vs #8**: These overlap on P1. #8 is more structured (specific format for file paths, open questions, next steps) while #2 is more flexible (append-only, captures the narrative). They could be combined: the handoff doc IS the latest session journal entry, just with a required structure.
- **#3 (self-eval)**: Risk of producing boilerplate assessments. Fix: require it to cite specific usage evidence or concrete examples, not just rate dimensions abstractly.
- **#9 (retrospective)**: Risk of being skipped because it happens after the work is done and the motivation is gone. Fix: make it a lightweight appendix to the pr-prep workflow rather than a standalone workflow.

---

## 4. Tradeoff Matrix

| Approach | Effort | Risk | Core problem coverage | Key downside |
|----------|--------|------|----------------------|--------------|
| **#8 Cross-session handoff doc** (merged with #2) | ~2 hours: add a section to RPI describing the handoff format and when to produce it | Low — it's documentation, not code | P1 (primary), P3 (minor — handoff docs reveal which steps were useful) | Yet another doc to produce; could feel like busywork if sessions are short |
| **#3 Self-evaluation skill** | ~3 hours: write the skill, run it on 2-3 existing skills as validation | Medium — risk of producing generic assessments that don't surface real issues | P6 (primary), P3 (secondary — evaluations reveal which skills work) | If the skill produces boilerplate, it's noise. Needs real usage data to be valuable. |
| **#9 Retrospective appendix to pr-prep** | ~1 hour: add a section to pr-prep.md | Low — small addition to existing workflow | P3 (primary) | Easy to skip; requires discipline to fill in honestly |
| **#14 Research doc freshness** | ~2 hours: define a staleness heuristic, add a "last verified" field to research/onboarding doc templates | Low | P7 (primary) | The heuristic might flag too aggressively or not aggressively enough; tuning needed |
| **#15 Lightweight decision log** | ~1 hour: define the format, add a `docs/decisions/log.md` template | Low | P8 (primary) | Risk of becoming a dumping ground; may dilute the signal of full decision records |

### Stress-test pass

**#8 Cross-session handoff doc — Boring alternative:**
The boring alternative is "just read the plan doc and git log at the start of the next session." This already works for well-defined tasks where the plan is the complete picture. The handoff doc adds value specifically when: (a) the session ended mid-implementation with partial progress not yet committed, (b) the session revealed open questions that aren't captured anywhere, or (c) context was built up during research that isn't fully captured in the research doc. If these situations are rare, the handoff doc is unnecessary. If they're common (and P1 suggests they are), it earns its keep.

**#8 — Push to extreme:**
If every session produces a handoff doc, the `docs/working/` directory accumulates many of them. But working docs are already disposable — old handoff docs can be deleted once their successor session has started. The risk is that the handoff doc becomes a crutch for sloppy research docs ("I'll just put it in the handoff"). Fix: the handoff doc should reference the research/plan docs, not replace them.

**#3 Self-evaluation skill — Invert the thesis:**
Argument against: The evaluation rubric is valuable as a *human* thinking tool precisely because it requires human judgment on dimensions like "user-specific fit" and "counterfactual gap." An automated evaluation would score these dimensions superficially, producing false confidence. The rubric itself notes that "user-specific fit and counterfactual gap probably don't" survive automation. Counter-argument: Even a partial automation (scoring the automatable dimensions — testability, trigger clarity, overlap — and flagging the human-judgment dimensions as "needs human input") would be useful as a screening tool. It surfaces the questions worth asking, even if it can't answer them.

**#3 — Organizational survival:**
Would the self-evaluation skill be maintained? It depends on the evaluation rubric, which is already maintained. The skill itself is a thin layer. Risk: if the rubric evolves, the skill needs to be updated to match. Fix: the skill should read the rubric at runtime rather than embedding it, so rubric updates propagate automatically.

**#9 Retrospective appendix — Boring alternative:**
The boring alternative is "just think about what went well after the PR and maybe update `docs/thoughts/`." The retrospective appendix adds structure: specific questions to answer (plan accuracy, skipped steps, time estimates vs. actual). Whether that structure produces better insights than unstructured reflection is unproven. On balance, the cost is so low (a few lines added to pr-prep.md) that even modest value justifies it.

**#14 Research doc freshness — Revealed preferences:**
In practice, do people actually check whether their research docs are stale before relying on them? The RPI workflow says "verify the docs are still current before proceeding" but doesn't provide a mechanism. A "last verified" field with a git-log-based staleness check would make this actionable. However, the heuristic ("relevant files changed since last verified") requires defining what "relevant files" means — which is task-specific and hard to automate well.

**#15 Lightweight decision log — Push to extreme:**
If every small decision goes in the log, it becomes a long, unsearchable list. If the threshold for "small" vs. "full decision record" is ambiguous, decisions end up in the wrong place. Fix: clear criteria — the log is for decisions that (a) took less than 5 minutes to make and (b) don't involve tradeoffs between multiple viable approaches. If there were tradeoffs, it's a DD candidate.

---

## Decision

No single approach clearly dominates. These are largely independent features addressing different problems. Recommended prioritization:

### Tier 1: Build now (high value, low effort)

1. **Cross-session handoff doc (#8, merged with session journal #2)** — Add to RPI as an optional step between "verify and loop" (step 6) and session end. Define a lightweight format: timestamp, what was accomplished, what's unfinished, open questions, file paths to load in next session. This is the highest-impact improvement because P1 (session continuity) is a daily pain point.

2. **Retrospective appendix to pr-prep (#9)** — Add 3-4 reflection questions to the end of pr-prep.md. Almost no cost, surfaces the feedback loop problem (P3) at the moment when the work is freshest in mind.

3. **Lightweight decision log (#15)** — Create `docs/decisions/log.md` with a clear scope boundary: one-line decisions that don't warrant a full decision record. Add a note to the DD workflow pointing to the log for sub-threshold decisions.

### Tier 2: Build after validation (moderate value, needs design)

4. **Self-evaluation skill (#3)** — Build after running the evaluation rubric manually on 2-3 more skills to validate that the automatable dimensions actually produce useful signal. The rubric already flags this as a future step; the validation work is the bottleneck, not the implementation.

5. **Research doc freshness (#14)** — Design the staleness heuristic first (spike candidate). The "last verified" timestamp is trivial to add; the question is whether the staleness check produces useful alerts or just noise.

### Not recommended

- Features that were discarded in the prune step remain discarded. The strongest rejected candidate was **#5 (diff-aware workflow selector)**, which addresses a real friction point (P2) but doesn't clearly improve on the existing CLAUDE.md summaries for the effort involved.
