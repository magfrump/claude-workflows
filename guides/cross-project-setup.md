# Cross-Project Adoption Guide

How to adopt workflows, skills, and conventions from this repo in other projects.

## A) Full workflow section

Copy the **Workflow & Skill Activation** section from `CLAUDE.md` into your target project's `CLAUDE.md`. This includes the workflow decision tree, debugging defaults, skill routing table, and composition notes.

**Dependencies:** Copy the `workflows/` and `skills/` directories in full, or selectively (see option B). Any workflow referenced in the decision tree that isn't present will silently fail to activate.

**Adapt:** Replace repo-specific paths (e.g., `docs/working/hypothesis-log.md`) with equivalents or remove references. Update the skill routing table if your project doesn't have the file types listed.

## B) Individual skills with dependencies

Each skill in `skills/` is a self-contained prompt file. To adopt one:

1. Copy the skill `.md` file into your target project's `skills/` directory.
2. Check the skill for cross-references — some skills invoke others (e.g., `code-review` may call `code-fact-check`, `security-reviewer`, `ui-visual-review`). Copy those too.
3. Add a routing entry to your `CLAUDE.md` skill table so it activates on the right triggers.
4. If the skill writes output to `docs/reviews/`, create that directory.

**Standalone skills** (no sub-skill dependencies): `fact-check`, `self-eval`, `security-reviewer`, `ui-visual-review`, `cowen-critique`, `yglesias-critique`.

**Skills with dependencies**: `code-review` → `code-fact-check` + optionally `security-reviewer`, `ui-visual-review`. `draft-review` → `fact-check` + persona critics.

## C) Artifact directory convention

Create these directories in your project root:

- `docs/working/` — RPI research docs, plans, summaries, and checkpoint files. Ephemeral per-task artifacts live here.
- `docs/reviews/` — Outputs from review skills (fact-checks, critic critiques, verification rubrics). Versioned alongside the content they review.
- `docs/decisions/` — Architecture decision records (`NNN-title.md`) and a `log.md` for lightweight entries.

Add corresponding sections to your `CLAUDE.md` (see "Review Artifacts" and "Shared Thoughts" in this repo's `CLAUDE.md` for the exact text).

## What to skip

These are specific to this repo's self-improvement loop and should **not** be copied:

- **`scripts/`** — Hypothesis tracking (`hypothesis-review.sh`, `hypothesis-calibration.sh`, `evaluate-hypotheses.sh`, `hypothesis-screen.sh`), health checks (`health-check.sh`), self-improvement automation (`self-improvement.sh`, `flag-removal-candidates.sh`), and round management scripts.
- **`docs/working/hypothesis-log.md`** and **`docs/working/hypothesis-backlog.md`** — Hypothesis tracking infrastructure for this repo's iterative development process.
- **`guides/validation-gates.md`** and **`guides/subtraction-checklist.md`** — Tied to this repo's merge-gate and self-improvement loop, not general-purpose.
- **`docs/working/ideas-backlog.md`** and round-tracking files — Internal roadmap artifacts.

## Verification

After setup, run these smoke tests to confirm workflows and skills activate correctly. If any fail, the most likely cause is a missing file reference in `CLAUDE.md` or a workflow/skill `.md` not copied to the target project.

1. **RPI activation.** Describe a multi-file bug to Claude (e.g., "Fix the login timeout bug"). Verify that Claude activates the research-plan-implement workflow — you should see it begin a research phase and reference `docs/working/` for artifacts.

2. **Code-review skill.** Ask Claude to review a diff or prepare a PR (e.g., "review this diff" or "open PR"). Verify the `code-review` skill triggers and produces output in `docs/reviews/`. If it invokes sub-critics (`security-reviewer`, `ui-visual-review`), those dependencies were copied correctly.

3. **Divergent-design activation.** Ask a design question with multiple viable approaches (e.g., "which approach should we use for caching — Redis, Memcached, or local LRU?"). Verify Claude activates the divergent-design workflow and evaluates candidates before committing to one.

4. **Artifact directories.** After completing any of the above, check that the expected directories exist and contain output:
   - `docs/working/` — research doc or plan from the RPI run
   - `docs/reviews/` — review output from the code-review run
   - `docs/decisions/` — decision record or `log.md` entry from the DD run

   If a directory is empty, the workflow ran but its output path may not match your `CLAUDE.md` configuration. Check the "Review Artifacts" and "Shared Thoughts" sections.

**Tracking adoption issues:** If a smoke test catches a setup problem, note it briefly (what failed, what was missing) so you can assess whether the checklist is catching real issues. This helps evaluate whether verification steps are worth maintaining.
