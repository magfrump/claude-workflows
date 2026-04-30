# Skill Usage Pipeline Hypotheses

**Workflow:** divergent-design (epistemic variant)
**Created:** 2026-04-30
**Branch:** feat/r1-r1-skill-usage-epistemic-dd
**Parent context:** Round 2 / H-10 marked CONFIRMED on 2026-04-08; post-fix log has 261→2964 entries but H-05's reported skill use (`ui-visual-review` on Behemoth Arsenal) still does not appear.

## Observation being explained

The user reports a full day of `ui-visual-review` invocations on Behemoth Arsenal (docs/human-author/feedback.md:31). The H-10 fix (commit 26e8c41, 2026-04-08) corrected skill-name extraction, was verified to log 261 entries across 8 projects, and H-10 was marked CONFIRMED. After the fix, `~/.claude/logs/usage.jsonl` contains:

- **21 entries** with `project="Behemoth Arsenal"` — all of them either `agent` events (Explore, code-simplifier, general-purpose) or one `skill simplify`. Zero `ui-visual-review` events from this project.
- **61 `ui-visual-review` skill entries total** — every one of them attributed to `claude-workflows` or a `wt-*` worktree of this repo. Zero from any external project.
- **Zero Read events** from `Behemoth Arsenal` whose file path includes `*/skills/*` or `*/workflows/*` — i.e. no skill/workflow definition files were read by that session under classifier criteria.

So the question is: *why does the user-reported invocation pattern not produce log entries even with H-10's fix in place?* This is an epistemic question — the hook code is now arguably correct for the cases it was designed to handle, but reality contradicts the predicted output, so something about our model of how skills are invoked is wrong.

## Diverge — candidate explanations

Eight candidates generated. Numbers are for reference only; ranking comes after the evidence matrix.

1. **Skill tool expansion bypasses PreToolUse.** Claude Code expands `Skill` tool calls (turning `/ui-visual-review` into inline content) before the PreToolUse hook fires for the Skill tool, so neither a `Skill` nor a `Read` event reaches the hook. Already flagged as an open question in the H-10 commit message.
2. **Skills are auto-injected via system-reminder, never read as files.** The Claude Code runtime contextually activates skills by injecting their content into the prompt as system reminders — there is no tool call at all, so no PreToolUse hook fires for skill activation.
3. **External-project `.claude/settings.json` shadows the global hook config.** If Behemoth Arsenal's repo has a project-local `.claude/settings.json` defining `hooks.PreToolUse` (or merging override semantics replace the global hooks array rather than concatenating), the global `log-usage.sh` hook never runs there.
4. **Skill files are loaded from a path the classifier rejects.** A different installation surface (e.g. `~/.claude/plugins/<id>/<plugin>/SKILL.md`, depth ≥2 under `/skills/`, or paths like `/skill/` singular / `/agents/`) gets `extract_skill_name` to return empty, dropping the event silently.
5. **The reported sessions used Claude Desktop / web app / IDE extension, not Claude Code CLI.** PreToolUse hooks are a Claude Code feature; non-Code clients run no hooks at all.
6. **The "full day" pre-dates the H-10 fix and the active log file.** Behemoth Arsenal's heavy `ui-visual-review` work happened before 2026-04-08; pre-fix usage.jsonl was rolled (`usage.jsonl.pre-fix-2026-04-08` exists) and is no longer the file being inspected when "after the H-10 fix" data is checked.
7. **Skill is invoked under a non-canonical name (custom slash command or alias).** The user defined a project-local `.claude/commands/<name>.md` whose content embeds ui-visual-review steps; entries log as `event="command"` (we have only 1 such entry total) or as a different skill name entirely.
8. **Null hypothesis — measurement framing error.** "Full day of ui-visual-review" may be a recollection of a session with one or two invocations plus heavy follow-up edits; the entries are actually present but indexed under a project name we did not search (e.g. `""` empty when git fails, or a different folder basename than "Behemoth Arsenal").

### Generation health-check

- **Clustering:** Candidates 1, 2, 4 share an underlying assumption that *the hook code itself is correct, but no PreToolUse event reaches it*. They differ in mechanism (Skill expansion vs. system-reminder vs. path classifier). Kept distinct because each implies a different fix surface.
- **Missing perspectives:** Added candidate 6 (timing/null-result), candidate 5 (different client), and candidate 8 (pure null hypothesis on the measurement) to balance the cluster.
- **Vagueness:** All candidates are testable with concrete experiments under 30 minutes. None say "something about how skills load."

## Diagnose — observations and distinguishing evidence

Evidence labeled **[observed]**, **[inferred]**, or **[assumed]** per the convention from RPI's research phase.

| Tag | Evidence | Source |
|-----|----------|--------|
| O1 | usage.jsonl has 2964 entries; 1575 `skill`, 1035 `workflow`, 351 `agent`, 3 `agent_skill`, 1 `command` events. **[observed]** | `jq` over `~/.claude/logs/usage.jsonl` |
| O2 | 21 Behemoth-Arsenal entries: only `agent` (Explore/code-simplifier/general-purpose) + 1 `skill simplify`. Zero `ui-visual-review`, zero Read-classified skill/workflow events. **[observed]** | same |
| O3 | All 61 `ui-visual-review` skill entries originate from `claude-workflows` or `wt-*` worktrees of this repo. **[observed]** | same |
| O4 | 1235 entries have empty `project` field — happens when `git rev-parse --show-toplevel` fails (PWD outside a git repo or git unavailable). **[observed]** | hook source `hooks/log-usage.sh:31` |
| O5 | The H-10 fix commit message itself flags: *"The Skill tool handler is preserved but may not fire if Claude Code expands skills before PreToolUse hooks run. Debug logging will confirm this in normal use."* **[observed]** | git show 26e8c41 |
| O6 | `~/.claude/hooks/log-usage.sh` is a symlink to `/home/magfrump/claude-workflows/hooks/log-usage.sh`; `trap 'exit 0' ERR` means any failure (including a broken symlink) silently no-ops. **[observed]** | `ls -la`, hook source |
| O7 | `~/.claude/settings.json` has the hook entry `bash $HOME/.claude/hooks/log-usage.sh` registered three times under PreToolUse. **[observed]** | settings.json |
| O8 | `usage.jsonl.pre-fix-2026-04-08` (77 KB) exists alongside the active log; the active log's earliest entry is 2026-04-09T02:43:57Z, ~20 min before the H-10 fix commit (2026-04-09T03:02:36Z UTC). **[observed]** | ls + jq |
| O9 | Behemoth Arsenal sessions logged through PreToolUse for `Agent` and `Skill simplify` but produced zero `Read` events matching `*/skills/*` or `*/workflows/*`. **[inferred]** from O2 | absence of records |
| O10 | The `extract_skill_name` classifier accepts only depth-0 (`skills/x.md`) or depth-1 (`skills/x/SKILL.md`) under the last `/skills/` segment. Plugin-style installs deeper than that are dropped silently. **[observed]** | hooks/log-usage.sh:51-72 |
| O11 | User explicitly invokes `ui-visual-review` by name (workflow-selection.md:35 lists it as an explicit recommendation). **[assumed]** that this maps to a Skill-tool invocation rather than file Read. |
| O12 | Project-local `.claude/settings.json` files are not present in this worktree, but exist in some external repos in the user's history. **[assumed]** — not directly checked for Behemoth Arsenal. |

## Match and prune — evidence matrix

| # | Hypothesis | O2 (Behemoth has only agent/skill events, no skill-Reads, no ui-visual-review) | O3 (all ui-visual-review entries from this repo) | O5 (commit warns about Skill expansion) | O8 (pre-fix log archived 2026-04-08) | O9 (no skill-Read events from Behemoth) |
|---|-----------|---|---|---|---|---|
| 1 | Skill tool expansion bypasses PreToolUse | ✓ explains absence of ui-visual-review and absence of skill-file Reads if Claude Code expands skills inline | ✓ explains why only "Skill simplify" (one explicit `Skill` invocation) shows up | ✓ explicitly predicted by author | ~ | ✓ |
| 2 | Skills auto-injected via system-reminder, no tool call | ✓ same effect — no tool call at all | ~ — would expect zero `Skill` events from any external project, but we have one (`skill simplify`); needs both this and #1 to fully fit | ~ adjacent mechanism | ~ | ✓ |
| 3 | External-project settings.json shadows global hooks | ✗ contradicted — Behemoth *does* produce hook output (21 entries), so its hook is firing for some tools | ~ | ~ | ~ | ✗ |
| 4 | Skill file path rejected by classifier | ~ would explain missing Read events but only if Claude Code is reading skill files at all | ~ would predict claude-workflows entries also drop, but they don't | ~ | ~ | ✓ partial — only if the path is unusual |
| 5 | Reported sessions used Claude Desktop/web/IDE, not Code | ✗ contradicted — Behemoth Arsenal entries DO exist in the log, so at least some sessions used Code | ~ | ~ | ~ | ✗ |
| 6 | "Full day" pre-dates H-10 fix and active log was rolled | ~ partially — but Behemoth entries continue through 2026-04-10, so the project is post-fix-active | ~ | ~ | ✓ archive file exists | ~ |
| 7 | Custom slash command alias | ~ would log as `event="command"`; only 1 command entry exists in entire log | ~ | ~ | ~ | ~ |
| 8 | Null hypothesis — measurement/recollection error | ~ requires the entries to exist under a different project name; possible but no evidence yet | ~ | ✗ — author is highly confident (≥99% on H-04, similar tone on H-05) | ~ | ~ |

**Pruned:**
- **#3 (settings shadowing)** is contradicted by O2 — Behemoth Arsenal's hook *is* firing for Agent dispatches and at least one Skill, so the hook config is not absent in that project. Dropped.
- **#5 (non-Code client)** similarly contradicted — Behemoth entries exist and PreToolUse hooks only run in Claude Code. Dropped.
- **#7 (custom slash command alias)** has only 1 command-event in the entire 2964-row log, no Behemoth-Arsenal command entries. Possible but very low prior; demote to footnote.

## Rank and identify evidence gaps

| Rank | Hypothesis | Confidence | Key supporting evidence | Critical evidence gap | Cheapest experiment (<30 min) |
|------|-----------|------------|------------------------|----------------------|-------------------------------|
| 1 | **#1 Skill tool expansion bypasses PreToolUse before the hook can fire** | **High** | O5 (author's own caveat on the H-10 commit), O2/O9 (no skill-Read events from Behemoth match the prediction that Skill calls are inlined), O3 (the only ui-visual-review entries come from sessions where the user opens the skill file directly while editing this repo, generating Read events) | Whether Claude Code emits a PreToolUse event for the `Skill` tool *at all* in any session | Set `USAGE_LOG_DEBUG=1`, then in any session run `Skill(skill="fact-check", args="...")` explicitly. Inspect `~/.claude/logs/usage-debug.jsonl` for tool_name="Skill" entries. Present → hook receives it; absent → hook never sees Skill calls. ~10 min. |
| 2 | **#2 Skills are auto-activated via system-reminder injection, never as a tool call** | **Medium-high** | O3 (ui-visual-review only appears when the *file* is being edited in this repo, not when used as a skill in another repo); O2 (Behemoth has agent dispatches but no skill-name reads — consistent with auto-activation injecting content directly into the prompt); the "available-skills" system-reminder block in current sessions (visible in conversation context) lists skills without ever invoking a tool | Whether contextually-activated skills generate any PreToolUse event, or whether activation is silent end-to-end | Open a fresh session in any non-claude-workflows repo; type a request that should trigger `ui-visual-review` (e.g. modify a TSX file). After the session, grep `~/.claude/logs/usage.jsonl` and the debug log for that session's timestamp range for any ui-visual-review entry. ~20 min including session warmup. |
| 3 | **#4 Skill file path is rejected by `extract_skill_name`** | **Medium-low** | O10 (classifier drops depth ≥2 paths and any non-`SKILL.md` file in a skill subdir). Possible variants: plugin-installed skills under `~/.claude/plugins/<author>/<plugin>/skills/<name>/SKILL.md` (depth 1 — should pass), or marketplace-style installs at depth ≥2 (would fail) | Whether any external-project session is reading skill definition files at all, and what paths those reads use | Set `USAGE_LOG_DEBUG=1`, ask Claude Code to "use ui-visual-review on this CSS file" in any non-workflows repo, then `jq '.tool_name=="Read" | .tool_input.file_path' ~/.claude/logs/usage-debug.jsonl`. Inspect actual paths. ~15 min. |
| 4 | **#6 The "full day" pre-dates the H-10 fix; only post-fix log is being inspected** | **Medium-low** | O8 (`usage.jsonl.pre-fix-2026-04-08` exists and is non-empty); user reported the observation on 2026-04-08, the same day the fix landed | Whether the user's reported "full day" timestamp falls before or after the fix commit (2026-04-09T03:02:36Z UTC) | `jq '.event=="skill" and .name=="ui-visual-review"' usage.jsonl.pre-fix-2026-04-08` and check Behemoth-Arsenal commit timestamps in that repo for evidence of UI work that day. ~10 min. Disconfirms cleanly: any pre-fix Behemoth-ui-visual-review entry would be a smoking gun. |
| 5 | **#8 Null hypothesis — entries exist under a name/project we did not search** | **Low** | O4 (1235 empty-project entries; some ui-visual-review entries with empty project may actually be Behemoth sessions where git rev-parse failed) | Whether any of the 32 empty-project ui-visual-review entries align temporally with known Behemoth Arsenal work | `jq` empty-project ui-visual-review entries' timestamps; cross-reference with Behemoth Arsenal git log. If a tight overlap exists, the entries are present but mis-attributed. ~15 min. |

### Discarded with reasons

- **#3 External-project settings shadowing** — refuted by O2 (hook *is* firing in Behemoth). Don't pursue further.
- **#5 Non-Code client** — refuted by O2. Don't pursue further.
- **#7 Custom slash-command alias** — only 1 command-event in 2964-entry log; insufficient prior to investigate.

## Recommended next investigation steps

Ordered by information value — what would most efficiently distinguish between the top hypotheses:

1. **Run experiment #1 first** (10 min, cheapest, highest information value). It directly tests whether `Skill` tool calls reach PreToolUse at all. The result splits the top 3 hypotheses cleanly:
   - **Skill events present in debug log** → #1 refuted; pursue #2 (auto-activation) or #4 (path classifier).
   - **Skill events absent in debug log** → #1 strongly supported; the H-10 "fix" did not actually close the gap for `Skill`-tool-invoked skills. Next step is a data-pipeline change: either capture Skill activations via a different mechanism (e.g. parse system-reminder content from a UserPromptSubmit hook, or instrument the available-skills list at session start) or accept that Skill-tool usage is unloggable and reframe the metric.

2. **Run experiment #2 in parallel** with #1 (single session covers both). If Read events appear for skill files during contextual activation in an external repo, hypothesis #2 is refuted and the gap narrows. If they don't appear, #2 is the actual root cause and the data-pipeline fix needs to add a UserPromptSubmit-hook (or equivalent) that scrapes the available-skills system reminder.

3. **Run experiment #4 as a quick disconfirmation** before further design work. A pre-fix ui-visual-review entry from Behemoth would partially explain the discrepancy (and would suggest that the fix itself is sufficient going forward). Absence of such entries strengthens the case that the gap is structural, not historical.

## Implications for next round's data-pipeline maintenance task

If experiment #1 confirms that Skill tool expansion bypasses PreToolUse (high prior), the H-10 fix is **architecturally insufficient**: it patched skill-name extraction inside a hook that only sees Read/Agent events for skills, not the actual Skill-tool invocation path. The next-round task should:

- Stop treating `usage.jsonl`'s skill events as a complete record of skill use.
- Add a complementary capture mechanism — likely a `UserPromptSubmit` or `SessionStart` hook that records the available-skills block from system reminders, OR parse the conversation transcript directly.
- Re-evaluate H-10's CONFIRMED status. The fix corrected *false positives* (SKILL.md misnaming) and added new event types (commands, agent_skill); it did not necessarily reduce *false negatives* for the externally-invoked-skill case that motivated the hypothesis.
- Update H-05's evidence summary: structural data limitations are more severe than "single-day coverage" — they include a category-level gap for Skill-tool invocations regardless of date range.
