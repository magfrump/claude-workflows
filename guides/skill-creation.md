# Creating a New Skill

How to write a skill from scratch and register it. For copying existing skills into another project, see [cross-project-setup.md](cross-project-setup.md).

## 1. Frontmatter

Every skill is a directory `skills/<name>/` whose entry point is `skills/<name>/SKILL.md` (supporting files such as `references/` or `personas.md` sit alongside it). `SKILL.md` starts with YAML frontmatter:

```yaml
---
name: my-skill
description: >
  What this skill does and when to use it.
when: Trigger condition (e.g., "Diff touches auth or crypto code")
requires:          # optional — omit if standalone
  - name: code-fact-check
    description: >
      Verifies code comments match implementation before analysis.
---
```

- **name**: lowercase, hyphenated identifier.
- **description**: explains purpose and scope — this is what Claude reads to decide relevance.
- **when**: heuristic trigger condition Claude evaluates against the current task.
- **requires**: list dependencies by skill name. See `security-reviewer` (one dependency) vs `code-review` (multiple).
- **non-goals** (optional): list of short phrases stating what the skill should *not* do — useful for critics whose scope abuts other critics or tools; see `security-reviewer` for the worked example, alongside its companion **adaptation-latitude** field which lists signals for scaling rigor by context.

## 2. Prompt structure

After frontmatter, structure the prompt body consistently:

1. **Goal statement** — one paragraph: what the skill does, what it does *not* do, key principles.
2. **Scoping** — how to determine what files/content to analyze; default behavior; user overrides.
3. **Cognitive moves** — numbered reasoning steps (typically 5-9). Each move is a specific analytical pattern. See `security-reviewer` for standalone moves, `performance-reviewer` for a similar pattern.
4. **Output format** — exact structure for findings. Standard fields: title, severity, location, move, confidence, recommendation. See any reviewer skill for the template.
5. **Output location** — where to save results (typically `docs/reviews/{skill-name}-review.md`).
6. **Tone and constraints** — guidance on writing style; mandatory rules (e.g., "read implementations, not just signatures").

Orchestrator skills (like `code-review`, `draft-review`) replace cognitive moves with **stage definitions** — which sub-skills to spawn, in what order, and how to synthesize results.

## 3. Routing entry

Register the skill in CLAUDE.md's skill routing table so it activates proactively:

```markdown
| Trigger | Skill | When |
|---------|-------|------|
| Diff touches **[your trigger pattern]** | `my-skill` | [Phase: during impl, before PR, etc.] |
```

Triggers are heuristic — Claude interprets them, not a regex engine. Write them as natural-language conditions a developer would recognize.

## 4. Test fixtures (optional)

Create `test/skills/{skill-name}/` with:

- `eval-criteria.md` — describes what good output looks like for this skill.
- `fixtures/tc-{N}.{variant}.{ext}` — test inputs exercising different cases (e.g., `tc-1.1-clean.py`, `tc-2.1-vulnerable.py`).

Two automated layers exist under `test/skills/`:

- **Format contracts** — `{skill-name}-format.bats` suites validate the structure of a generated report (set `REPORT_PATH` and run `bats test/skills/{skill-name}-format.bats`). Add one for any skill with a fixed output format.
- **Report generation** — `test/skills/generate-reports.bash <skill> [fixture-prefix]` runs `claude -p` against each fixture and writes `test/skills/<skill>/output/*.report.md` with a provenance `.stamp` (hashes of the skill directory, its `runner.bash` and the fixture, not the shared harness); reports and their sidecars are meant to be committed once generated (none are yet; `.gitignore` admits them), and a report whose stamp no longer matches fails its suite until regenerated. The `*-eval.bats` suites then score those reports against `expected-verdicts.bash` (today wired for `fact-check` and `code-fact-check`).

Judging output against `eval-criteria.md` beyond what those suites assert is still manual.

## When to create a workflow vs. a skill

### The original distinction

**Workflows** (`workflows/*.md`) are multi-step processes orchestrated by the human or by Claude following explicit decision gates. They use `value-justification` frontmatter, have "When to use" / "When to pivot" sections, and compose horizontally — RPI invokes DD as a sub-procedure, spike results feed back into RPI, etc. The human decides when to enter a workflow and often when to proceed past checkpoints.

**Skills** (`skills/<name>/SKILL.md`) are single-pass, agent-invocable tools. They use `name` / `description` / `when` frontmatter, activate based on code context (diff touches auth → `security-reviewer`) or explicit request, and produce a self-contained output (a review, a critique, a fact-check report). Skills compose hierarchically — `code-review` dispatches `security-reviewer`, `performance-reviewer`, and others in parallel.

In short: workflows describe *how to work*; skills describe *what to analyze*.

### How the boundary has shifted

Practice has blurred the original line in two directions:

1. **Workflows shrinking into skills.** `bug-diagnosis` was once a standalone workflow with a structured diagnosis log, hypothesis tracking, and explicit pivot gates. In practice, most bugs didn't need that ceremony — pasting the error into Claude and following the 5-step debugging defaults (reproduce → read error → hypothesize → test → fix) was sufficient. The workflow was first deprecated in favor of a local inline skill, then both were removed in favor of the externally-shipped `superpowers:systematic-debugging` skill — and when that plugin was itself uninstalled (2026-07-09, security-audit flags), the loop completed its shrink: the entire diagnostic practice now lives inline in CLAUDE.md's Debugging defaults section, no skill or workflow at all.

2. **Skills growing workflow-like behavior.** `code-review` is a skill, but it orchestrates multiple sub-skills in stages, synthesizes results, and can trigger a review-fix loop. It has more internal structure than some workflows. Similarly, `draft-review` spawns parallel critic skills and produces a synthesis — it's an orchestrator wearing a skill's frontmatter.

3. **Workflows used like skills.** Divergent Design is defined as a workflow, but it's most often invoked *within* RPI as a sub-procedure — RPI's research surfaces 3+ approaches, DD runs, the decision feeds back into RPI's plan. The user rarely triggers DD directly; it's summoned by workflow logic, much like how skills are summoned by diff context.

### Routers: how workflows reach the skill layer (2026-09-29)

The difference that shows up in practice is not content but discovery. Claude Code lists every skill's `description` in every session and starts one with a single Skill call; a workflow is reached only if instruction prose sends the model to read it. So every workflow now ships a **router skill** of the same name (`skills/<name>/SKILL.md`): a stub whose description says when the workflow applies and when a sibling applies instead, and whose body hands off to `~/.claude/workflows/<name>.md`. The workflow stays the only copy of the procedure. A workflow that only runs inside another one opts out with `router: "none — <reason>"` in its frontmatter (today: `review-fix-loop`). `test/skills/workflow-routers.bats` enforces both directions. Decision log row 66.

When adding a workflow, add its router in the same change, keeping the description's "Not for X (Y)" clause and triggers within 250 characters.

### Decision criteria for new additions

When proposing a new workflow or skill, ask:

| Question | If yes → | If no → |
|----------|----------|---------|
| Does it require human judgment at intermediate checkpoints? | Workflow | Skill |
| Can Claude complete it in a single pass given the right context? | Skill | Workflow |
| Does it compose horizontally with other processes (hand-off, pivot)? | Workflow | Either |
| Is it triggered by code context (diffs, file types) rather than task description? | Skill | Either |
| Does it produce a self-contained artifact (review, report, critique)? | Skill | Either |

**Gray area guidance:** If something could be either, prefer a skill. Skills are easier to invoke, test, and compose as sub-components. A skill can always be wrapped in a workflow later (as `code-review` is wrapped in `pr-prep`'s review-fix loop), but extracting a skill from a workflow is harder (as `bug-diagnosis` showed).

### Current inventory

The table below captures the current state of all workflows and skills, noting where the form factor fits naturally and where it's strained. This is descriptive, not prescriptive — the boundary should evolve based on usage.

#### Workflows

| Name | Form factor fit | Notes |
|------|----------------|-------|
| `research-plan-implement` | **Strong** | Multi-step with research → plan → review gate → implement. Human gates are load-bearing. |
| `divergent-design` | **Adequate** | Often used as sub-procedure within RPI rather than standalone. Could work as a skill, but benefits from the structured candidate-evaluation steps. |
| `codebase-onboarding` | **Strong** | Exploratory, multi-phase, feeds into downstream workflows. |
| `spike` | **Strong** | Timeboxed with explicit go/no-go decision. Human judgment at the boundary. |
| `pr-prep` | **Strong** | Orchestrates review-fix loop with human approval gates. |
| `task-decomposition` | **Strong** | Decomposes into sub-tasks that each follow their own workflow. |
| `branch-strategy` | **Strong** | Coordinates across multiple branches; inherently multi-session. |
| `user-testing-workflow` | **Strong** | Plans, executes, and analyzes usability tests across phases. |
| `review-fix-loop` | **Adequate** | Sub-procedure of `pr-prep`, not invoked standalone. More of a protocol than a workflow. |

#### Skills

| Name | Form factor fit | Notes |
|------|----------------|-------|
| `code-review` | **Adequate** | Orchestrator — more structured than typical skills. Fits because it produces a single artifact. |
| `security-reviewer` | **Strong** | Standalone reviewer, single-pass, diff-triggered. Canonical skill pattern. |
| `performance-reviewer` | **Strong** | Same pattern as `security-reviewer`. |
| `ui-visual-review` | **Strong** | Diff-triggered, single-pass review. |
| `api-consistency-reviewer` | **Strong** | Single-pass, diff-triggered. |
| `code-fact-check` | **Strong** | Single-pass verification. |
| `fact-check` | **Strong** | Prose fact-checking, single-pass. |
| `draft-review` | **Adequate** | Orchestrator dispatching critics in parallel. Similar to `code-review`. |
| `dev-cycle` | **Adequate** | Workflow-shaped (steps 0–7 plus conditional 4b and 5 and the 6b handoff) but, by the criteria above, a skill: Claude completes it in one pass given the digest, with no human checkpoint mid-run beyond the Operating Modes rule (under /active the user confirms the handoff queue, as for any launch; decisions go to questions.md), and it produces a self-contained artifact (the cycle record). Its mechanical parts live in `scripts/dev-cycle.sh`. Promote it to a workflow with a router if a cycle ever needs a human gate mid-run. |
| `self-eval` | **Strong** | Single-pass scoring against rubric. |
| `test-strategy` | **Strong** | Single-pass analysis producing a test plan. |
| `tech-debt-triage` | **Strong** | Single-pass prioritization. |
| `dependency-upgrade` | **Strong** | Single-pass assessment. |
| `architecture-review` | **Strong** | Single-pass review. |
| `matrix-analysis` | **Strong** | Single-pass comparison across criteria. |
| `what-if-analysis` | **Strong** | Single-pass consequence exploration. |
| `cowen-critique` | **Strong** | Single-pass persona critique. |
| `yglesias-critique` | **Strong** | Single-pass persona critique. |
| `ai-personas-critique` | **Strong** | Multi-persona critique, single artifact. |
| `business-plan-critique-moat` | **Strong** | Single-pass lens critique of business-plan-shaped drafts. |
| `business-plan-critique-unit-economics` | **Strong** | Same pattern as `business-plan-critique-moat`. |
| `business-plan-critique-market-sizing` | **Strong** | Same pattern as `business-plan-critique-moat`. |
| `pre-mortem` | **Strong** | Single-pass retrospective failure narratives. |
| `design-space-situating` | **Strong** | Single-pass situating record for a decision. |
| `arithmetic-eval` | **Strong** | Utility tool — runs calculations in python3 rather than producing a review. |
| `divergent-design` | **Adequate** | Thin router into `workflows/divergent-design.md`; the process lives in the workflow. |

### Evaluating this section's usefulness

This section was added to help make more deliberate form-factor choices when proposing new skills or workflows. If you're reading this while deciding whether to create a workflow or a skill, note it in the relevant working doc (e.g., `docs/working/research-*.md`) — that trail helps evaluate whether the reference is actually consulted in practice.

## Models to study

| Pattern | Example skill | What to learn |
|---------|--------------|---------------|
| Standalone reviewer | `security-reviewer` | Frontmatter with one dependency, cognitive moves, finding format |
| Orchestrator | `code-review` | Multi-stage agent spawning, severity mapping, synthesis |
| Fact-checker | `code-fact-check` | Claim-by-claim verification, verdict system |
