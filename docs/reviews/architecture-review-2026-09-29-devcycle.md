Commit: 89a3d3b

# Architecture Review — feat/dev-cycle

**Scope:** `git diff main...HEAD` in `.claude/wt-devcycle` (8 files: `scripts/dev-cycle.sh`, `skills/dev-cycle/SKILL.md`, `docs/roadmap.md`, `test/dev-cycle.bats`, `global-instructions/CLAUDE.md` row 12, `docs/decisions/log.md` row 67, `README.md`, `guides/skill-creation.md`)
**Date:** 2026-09-29
**Based on:** shared critic brief (critic-brief-c.md); no code-fact-check report

> ⚠️ **No code fact-check report provided.** Architectural claims in comments and documentation
> have not been independently verified. For full verification, run the `code-fact-check` skill
> first or use the code-review orchestrator.

Scope check: in scope. The diff adds a new module (script + skill + a persisted plan doc), a new data contract (`docs/working/cycles/cycle-YYYY-MM-DD.md` filenames that the script reads back as state), and a new cross-cutting entry in the global decision tree. No `docs/reviews/security-review-*.md` for this commit was consulted; trust-boundary cross-reference is a no-op here.

## Dependency Map

- `skills/dev-cycle/SKILL.md` (judgment, installed to every project) → `scripts/dev-cycle.sh` (mechanical digest) → `scripts/questions.sh open` (via `$SCRIPT_DIR` or `~/.claude/scripts/`), `git log`, `docs/decisions/*.md`, `docs/decisions/log.md`, `docs/roadmap.md`, `docs/working/cycles/*.md` (its window anchor).
- The skill also calls, by name: `questions.sh init|archive|index`, `scripts/health-check.sh` (claude-workflows only), `scripts/archive-working-docs.sh -n` (claude-workflows only), pr-prep step 5a (triage rules, by reference), `code-fact-check` (k=1), `divergent-design` (hand-off for 3+-option ideas), and the global "Running questions document" grammar.
- Write-back loop: skill step 7 writes `docs/working/cycles/cycle-<date>.md`; the script reads the newest such filename as the next window's start. Skill step 6 writes `docs/roadmap.md`; the script reads its `## Next` section.
- Dependencies flow the right way overall: the volatile, judgment-heavy layer (skill) depends on the stable, testable layer (script, questions.sh), and the script never depends on the skill. The one reversal is the state anchor noted in finding 1.

## Findings

#### 1. The script's window anchor is written only by a prose step, and silently falls back to 14 days

**Severity:** Coupling
**Location:** `scripts/dev-cycle.sh:44-52`; `skills/dev-cycle/SKILL.md` step 7
**Move:** 1 (dependency direction), 7 (coupling surface)
**Confidence:** High
**Legibility-target:** the next agent running a cycle after a skipped Close, or after a >14-day gap

Evidence (script): `SINCE="${last:-$(date -d '14 days ago' +%F)}"` — the default when no `docs/working/cycles/cycle-*.md` exists. Evidence (skill): "### 7. Close — Write `docs/working/cycles/cycle-YYYY-MM-DD.md`". Evidence (log row 67): "Revisit … if the gap between cycles passes a month twice".

The script header justifies the split by "steps only prose asks for do not run (… Q-074)", yet the script's only persistent state is produced by the last prose step. If step 7 is skipped (context runs out, the cycle is abandoned mid-way) or this is the first cycle, the next digest silently uses a 14-day window; merges older than that never appear in Activity or the spot-check sample, and the digest does not say it fell back. The decision row explicitly anticipates month-long gaps, which this default truncates. The contract (a date encoded in a filename in a disposable directory) is also untyped: nothing but the glob ties writer and reader.

**Recommendation:** Print the anchor's source in the digest ("since 2026-09-15 (last cycle record)" vs "(no cycle record: 14-day default; pass --since)"), and either let the script write the record stub itself (e.g. `dev-cycle.sh --close`) or default to the last cycle's merge commit / roadmap change rather than a fixed 14 days.

#### 2. Step 1 delegates "archive merged working docs" to a tool with different, SI-run-scoped semantics

**Severity:** Coupling
**Location:** `skills/dev-cycle/SKILL.md` step 1 (Stale working docs bullet); `scripts/archive-working-docs.sh:1-20, 38-49, 110-140`
**Move:** 2 (responsibility boundaries), 7 (coupling)
**Confidence:** High
**Legibility-target:** an agent executing step 1 in claude-workflows

Evidence (skill): "in claude-workflows, `scripts/archive-working-docs.sh -n` lists what would move. Archive working docs whose task has merged; leave anything still cited." Evidence (script header): "Archive docs/working/ artifacts from a completed self-improvement run … Moves all non-permanent files … with an optional prefix (defaults to the run id in docs/working/si-run-id.txt".

The skill's intent is selective (task merged), but the only tool it points to is bulk: every top-level non-permanent, uncited file moves, with no notion of "merged". An agent that runs it without `-n` (the skill says "Archive …" but gives no command for the selective version) archives in-flight plan docs, prefixes them with a stale SI run id if `si-run-id.txt` exists, and moves them into the gitignored `archive/` — i.e. removes tracked files from version control. So dev-cycle now depends on an SI-loop implementation detail (PERMANENT list, run-id prefix) that was never designed for this caller; a future change to the archiver for SI's sake changes dev-cycle behavior with no test catching it.

**Recommendation:** Either give the selective operation a mechanical home (a `--merged` / file-list mode in `archive-working-docs.sh`, with a test, and an explicit date prefix from the cycle) or change the skill to "list candidates with `-n`, then `git mv` the chosen files to `archive/docs/`" and never run the bulk mode from a cycle.

#### 3. The roadmap duplicates questions.md state, and a third idea store sits beside feature-ideas.md

**Severity:** Coupling
**Location:** `docs/roadmap.md:1-40` (header, Next 1–3, Ideas); `skills/dev-cycle/SKILL.md` steps 5–6; `docs/working/feature-ideas.md`; `scripts/self-improvement.sh:38, 646-682`
**Move:** 2, 7
**Confidence:** Medium
**Legibility-target:** whoever answers a Q-NNN or resumes the self-improvement loop

Evidence (roadmap header): "this file says *what* and *in what order*, the questions doc says *who has to decide*." Evidence (Next): "1. **Q-075 — evidence that the self-improvement loop is safe to resume.** … 2. **Q-088 — spike …** 3. **Q-089 — host-tool trust category.**" Ideas: "**Q-079 — canon-instance script …**".

The stated split is clean, but the seed content restates open questions (with motive and first step) rather than pointing at them, so answering Q-088 in questions.md leaves the roadmap stale until the next cycle — two sources of truth for the same item's status. Separately, idea generation now has three homes: the SI loop's DD brainstorm (`feature-ideas-round-N.md`, plus the permanent `feature-ideas.md`), the SI loop's `completed-tasks.md` memory, and dev-cycle step 5 → roadmap Ideas. The skill's brainstorm does not read the SI outputs and SI does not read the roadmap, while roadmap Next #1 is resuming SI. When SI resumes, its ideas and completions will bypass the roadmap and vice versa.

**Recommendation:** Make roadmap entries that are questions a bare reference (`Q-088` + one-line motive) and have `dev-cycle.sh` print each referenced Q-ID's current status next to the Next list so drift shows in the digest. Name one owner for ideas: either step 5 reads `feature-ideas*.md` / `completed-tasks.md` as signal inputs, or the roadmap is declared the sink SI writes to; say which in the skill.

#### 4. An installed, every-project skill depends on a repo-local template

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md` step 6; `devcontainer-config/install.sh:135`
**Move:** 3 (module boundary)
**Confidence:** High
**Legibility-target:** an agent running the cycle in a project other than claude-workflows

Evidence (skill): "Update `docs/roadmap.md` (create it from its own template if missing)". Evidence (installer): `CLAUDE_HOME_SRC=(global-instructions/CLAUDE.md skills workflows guides patterns hooks scripts)` — `docs/` is not installed.

The skill ships globally, but "its own template" exists only as this repo's `docs/roadmap.md`, which is not installed. In any other project the instruction has no referent, so each cycle invents a format and the script's `## Next` parse may miss. Compare `questions.sh init`, which carries its template in the installed script. The skill otherwise handles the repo boundary well ("in claude-workflows: …"), so this is the one leak.

**Recommendation:** Inline the four-section skeleton in the skill (it is ~6 lines), or add `dev-cycle.sh --init-roadmap` mirroring `questions.sh init`.

#### 5. Skill-vs-workflow placement: defensible under the gray-area rule, but the stated reason is not a guide criterion

**Severity:** Minor
**Location:** `guides/skill-creation.md:137` (new row); `global-instructions/CLAUDE.md` row 12
**Move:** 2, 8 (extension points)
**Confidence:** Medium
**Legibility-target:** the next person adding an outer-loop process

Evidence: "`dev-cycle` | **Adequate** | Workflow-shaped (seven ordered steps, triage output) but user-started and single-session, so a skill". The guide's decision table (lines ~95-105) uses "human judgment at intermediate checkpoints", "single pass", and "composes horizontally"; "user-started" and "single-session" are not in it (every workflow is user-started). On those criteria dev-cycle is mixed: it composes horizontally (pr-prep 5a, code-fact-check, DD hand-off) and has no mid-run human gate (judgment is deferred to questions.md), so the guide's "Gray area → prefer a skill" does support the choice.

The structural consequence is that row 12 is the first decision-tree row whose target is a skill that *contains* a procedure, whereas row 66 just established "workflow docs stay the single source of the procedure; skills route to them". Dev-cycle is the "orchestrator wearing a skill's frontmatter" case the guide already calls strained, without the workflow conventions (Done-when checklists, When to pivot) and outside `workflow-routers.bats`. That is acceptable at 95 lines; it becomes a problem if the cycle grows the per-step detail other workflows carry.

**Recommendation:** Rewrite the guide row's rationale in the guide's own terms ("no intermediate human gate; judgment is deferred to questions.md; gray area → skill"), and note a revisit condition: promote to `workflows/dev-cycle.md` + router if the skill body passes ~150 lines or gains a human checkpoint.

#### 6. The digest parses questions.sh's human-oriented column output

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:95-105`; `scripts/questions.sh:408-414`
**Move:** 7 (coupling surface)
**Confidence:** Medium
**Legibility-target:** whoever next edits `cmd_open`'s printf

Evidence: `printf '%s  %-14s  %s\n' "$id" "$route" "$slug"` (questions.sh) consumed by `awk -F'  +' '$2 == "trigger" || $2 == "deferred"'` (dev-cycle.sh), with the comment explaining the two-space assumption. This is stamp coupling to a display format: it works today (a padded route is always followed by two literal spaces), but a cosmetic change to `cmd_open` breaks the digest silently (routes vanish → "None open."). The bats test covers the current format, which helps.

**Recommendation:** Add a machine format to questions.sh (`open --tsv`, or a `watched` subcommand) and consume that; keep the display output free to change.

#### 7. Test file placement departs from the scripts convention

**Severity:** Informational
**Location:** `test/dev-cycle.bats`
**Move:** 3
**Confidence:** High
**Legibility-target:** someone looking for script tests

Script contract tests live in `test/scripts/` (`archive-working-docs.bats`, `health-check.bats`, `skill-usage-report.bats`, …); this one sits at `test/` top level. Move it to `test/scripts/dev-cycle.bats` for consistency.

## What Looks Good

- The script/skill split is the right cut: everything countable (window, merges, trigger text, watched routes, seeded sample, roadmap Next) is in a read-only, tested script; everything requiring a verdict is in the skill. The script never depends on the skill, and it is portable (acts on `$PWD`'s repo, finds questions.sh locally or installed).
- Composition by reference rather than duplication: failure triage points at pr-prep 5a, questions go through `questions.sh` and the global entry grammar, audits reuse `code-fact-check`, 3+-option ideas hand off to `divergent-design`. No existing procedure is copied.
- Output is routed through the existing attention mechanism (questions.md routes) instead of a new report channel; branch deletion correctly stays a `you: terminal` entry.
- The same-day seeded `shuf` makes the spot-check sample reproducible, and `docs/working/cycles/` is a subdirectory, so `archive-working-docs.sh` (top-level files only) will not sweep the cycle records the script depends on.
- Log row 67 carries falsifiable revisit triggers (three empty cycles; month-long gaps twice).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Window anchor written only by prose step 7; silent 14-day fallback | Coupling | `scripts/dev-cycle.sh:44-52` | High |
| 2 | Step 1 points at the bulk, SI-scoped archiver for a selective job | Coupling | `skills/dev-cycle/SKILL.md` step 1 | High |
| 3 | Roadmap restates Q-NNN state; third idea store beside SI's | Coupling | `docs/roadmap.md` | Medium |
| 4 | Global skill references a template that is not installed | Minor | `skills/dev-cycle/SKILL.md` step 6 | High |
| 5 | Skill-vs-workflow rationale not in the guide's terms | Minor | `guides/skill-creation.md:137` | Medium |
| 6 | Digest parses questions.sh display columns | Minor | `scripts/dev-cycle.sh:95-105` | Medium |
| 7 | Test lives outside `test/scripts/` | Informational | `test/dev-cycle.bats` | High |

## Overall Assessment

The change is structurally sound at its core: the mechanical/judgment split is well placed and dependencies point from the volatile skill to the stable script and existing tools, with no duplicated procedure and no Structural finding. The issues are at the seams with existing modules and are fixable in place. The most important is finding 1: the script's own rationale is that prose steps do not run, yet its only state is written by the last prose step, and when that step is skipped the digest silently narrows to 14 days. Finding 2 is the most likely to cause real damage on a first run (bulk-archiving tracked working docs under a stale SI prefix). Finding 3 is a design choice worth settling before the roadmap accumulates: decide whether the roadmap references questions and SI outputs or restates them.

## Goal-Alignment Note

- **Answered:** All four structural questions in the brief: script/skill split (sound; finding 1 on the state seam), composition with health-check / questions.sh / archive-working-docs.sh / SI / code-fact-check / pr-prep (findings 2, 3, 6; no duplication found), skill vs workflow under guides/skill-creation.md and row 66 (finding 5: skill defensible, rationale mis-stated), roadmap vs questions.md and feature-ideas.md (finding 3).
- **Out of scope:** Security of printing decision text verbatim into an agent-consumed digest and of autonomous archive/prune actions (security-reviewer); per-session description cost (performance); whether the steps actually execute (behavioral, raised only where it creates a structural seam in finding 1). No scripts were executed; findings rest on reading the code.
- **Escalate:** Finding 3's ownership question (roadmap as reference vs sink for SI ideas) is a design choice for the user, not a mechanical fix.
