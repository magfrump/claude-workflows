# Creating a New Skill

How to write a skill from scratch and register it. For copying existing skills into another project, see [cross-project-setup.md](cross-project-setup.md).

## 1. Frontmatter

Every skill file lives in `skills/` and starts with YAML frontmatter:

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

Run the skill against each fixture and compare output to eval criteria. This is manual today — there is no automated test harness.

## Models to study

| Pattern | Example skill | What to learn |
|---------|--------------|---------------|
| Standalone reviewer | `security-reviewer` | Frontmatter with one dependency, cognitive moves, finding format |
| Orchestrator | `code-review` | Multi-stage agent spawning, severity mapping, synthesis |
| Fact-checker | `code-fact-check` | Claim-by-claim verification, verdict system |
