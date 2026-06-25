# Spike: Hook point for the invocation logger (decision 012 pillar 4)

Date: 2026-05-14
Branch: none (read-only investigation)
Time spent: ~25 min

**Last verified:** 2026-06-24
**Relevant paths:** hooks/log-usage.sh, hooks/log-usage-post.sh, scripts/lib/si-morning-summary.sh, docs/decisions/012-hypothesis-grammar-for-user-surfaced-evaluation.md

- **Goal**: Determine whether an existing or extendable hook point in Claude Code can supply the invocation log decision 012 pillar 4 requires (skill/workflow invocations, timestamps, args, duration), with minimal new infrastructure.
- **Project state**: investigation for decision 012 pillar 4 · part of the SI hypothesis-grammar rewrite · not blocked
- **Task status**: complete

## Answer

> **Status update (2026-06-24):** The RPI this spike seeded has since shipped. Gaps #1 (duration), #2 (real-use vs consult), and #5 (metric stream) below are now implemented: `hooks/log-usage-post.sh` emits paired `skill_completed`/`agent_completed` events with `duration_ms`/`total_tokens`, and `hooks/log-usage.sh` tags each pre-event with a `via` field (`skill_tool` vs `file_read`) instead of splitting event types. `scripts/lib/si-morning-summary.sh` consumes both as METRIC rows for script-evaluator precondition gating (decision 012). The findings below are preserved as the original investigation record; per-finding resolution is noted inline.

**Yes.** A working `PreToolUse` hook already exists at `~/.claude/hooks/log-usage.sh`, wired in `~/.claude/settings.json` for `Skill`, `Read`, and `Agent` tools, writing to `~/.claude/logs/usage.jsonl`. It already captures ~80% of what decision 012 pillar 4 specifies: timestamp, name, args, project, branch. The remaining gaps (duration, "real use vs consult" distinction, plugin-skill coverage) close with two small additions and one clarification — not a rewrite. The recent SKILL.md-directory migration was the structural change that makes plugin-skill capture work via the same path-matching code that already handles local skills.

## Key findings

### What's already working

- **4,645 log entries over ~2 months** in `~/.claude/logs/usage.jsonl`. Top names match real usage (`self-eval`, `code-review`, `divergent-design`, `research-plan-implement`, `draft-review`, `pr-prep`).
- **Three event types are captured**: `skill` (2,707), `workflow` (1,486), `agent` (447). Plus `agent_skill` (4) and `command` (1).
- **The hook path matching handles three skill-file layouts cleanly** (`extract_skill_name`, since extracted to `scripts/lib/skill-paths.sh` and shared with the hooks):
  - Old: `skills/<name>.md` → `<name>`
  - New: `skills/<name>/SKILL.md` → `<name>` (the migration the user mentioned)
  - Rejected: deeper paths like `skills/<name>/references/foo.md` → no log entry (correct)
- **Plugin skills work via the same path matching** when their SKILL.md is read. `skill-creator` (plugin) shows 7 entries; `simplify` shows 15. The path `~/.claude/plugins/cache/.../skills/skill-creator/SKILL.md` matches the same `*/skills/<name>/SKILL.md` pattern as local skills.
- **Project + branch context** is captured from `git rev-parse --show-toplevel`, so per-project filtering works.
- **Failure is graceful**: `trap 'exit 0' ERR` ensures a logging failure never blocks tool execution.

### What's broken or missing

1. **No duration capture.** `PreToolUse` fires before invocation; there's no end-time, no token count, no success/failure signal. Script-evaluator preconditions like "p95 latency under N" or "average duration" can't be computed from current data. *(Resolved 2026-06-24: `hooks/log-usage-post.sh` PostToolUse hook now emits `skill_completed`/`agent_completed` with `duration_ms` and `total_tokens`.)*

2. **No "real use vs consult" distinction.** The hook treats `Skill` tool invocations and `Read` of SKILL.md identically (both produce `event: skill`). Reading a SKILL.md to inspect it counts as "skill usage" — conflating consultation with use inflates invocation counts, which directly breaks decision 012's `requires: invocations: N` precondition gating. *(Resolved 2026-06-24: the pre-hook keeps `event: skill` but adds a `via` field — `skill_tool` for real use, `file_read` for consultation — so consumers filter on `via == "skill_tool"`.)*

3. **Plugin coverage is partial — only ~7 entries for `skill-creator` despite the user invoking it more often.** The hook fires when SKILL.md is *read*, but if Claude Code loads plugin skill metadata directly (without reading SKILL.md), no event fires. Today's plugin installs (`frontend-design`, `claude-md-improver`) have **0 entries** despite presumably being available. Coverage depends on whether the runtime always reads SKILL.md or sometimes loads from a metadata index.

4. **Misclassification leaks through.** A handful of entries have `name: "SKILL"`, `"advanced"`, `"patterns"`, `"parsing-techniques"`, `"skill-development"`, `"cross-skill-eval"` — all from past audit branches. These are sub-directories or unrelated files matching the path pattern. Low volume (~10 total) but they pollute aggregations.

5. **No metric stream for script-eval hypotheses.** Decision 012's `requires: metric_logged: latency_p95` implies a *named metric* exists somewhere queryable. Today there's no such stream — only invocation events. *(Resolved 2026-06-24: `duration_ms`/`total_tokens` on the completion events now feed METRIC rows that `scripts/lib/si-morning-summary.sh` aggregates for precondition gating.)*

### Skill-format-update observation

The user's intuition was right: the SKILL.md-directory migration is what enables uniform plugin coverage. Before the migration, plugin skills shipped under varied paths; the move to `skills/<name>/SKILL.md` everywhere means the *same* `extract_skill_name` function captures local, plugin, and (presumably) marketplace skills with no per-source code. The hook is already migration-aware. The remaining plugin-coverage gap (#3 above) is about *whether SKILL.md is read at all*, not about path parsing.

## Recommendation

**Proceed to RPI.** The hook point question is settled — extend the existing hook, don't build new infrastructure. The implementation is small (one new PostToolUse hook, one event-type split, one config knob), and it can ship before the rest of decision 012 since later pillars depend on this substrate.

## RPI seed

> **Implemented 2026-06-24.** This seed has been built out. Note one deviation from the plan below: delta #2 proposed splitting `event: skill` into `skill_invoked`/`skill_consulted`; the shipped implementation instead keeps `event: skill` and adds a `via` field (`skill_tool`/`file_read`), preserving backward compatibility with `scripts/skill-usage-report.sh`. The post-hook (delta #1) shipped as `hooks/log-usage-post.sh`.

- **Scope for RPI**: Extend the existing invocation logger to capture duration, distinguish skill *use* from skill *consult*, and verify plugin-skill coverage — without adding new logging streams or rewriting `log-usage.sh`.

- **Known invariants** (from this spike):
  - Hook must never block tool execution (`trap 'exit 0' ERR` pattern).
  - Path-matching code in `extract_skill_name` is correct as-is; don't refactor it for this work.
  - Project + branch context comes from `git rev-parse --show-toplevel` and must be preserved.
  - The same hook handles local, plugin, and (eventually) marketplace skills — keep it source-agnostic.
  - `USAGE_LOG_FILE` env var override exists for test isolation; preserve it.

- **Concrete deltas to implement**:
  1. **Add a `PostToolUse` hook on `Skill` and `Agent`** that writes a paired completion event with `event: skill_completed` / `event: agent_completed`, including `duration_ms` (from the tool result, if exposed) and any failure indication. Pair via a generated `invocation_id`. New file: `~/.claude/hooks/log-usage-post.sh` (separate from the pre-hook to keep each script focused).
  2. **Split the `skill` event type** into `skill_invoked` (from the `Skill` tool — actual use) and `skill_consulted` (from `Read` of SKILL.md — exploration). Same change for workflows. Backwards-compat: keep writing the old `event: skill` for one rollover, then switch.
  3. **Verify plugin coverage** by invoking each newly installed plugin skill (`frontend-design`, `claude-md-improver`) once and checking that the log captures it. If it doesn't, investigate whether plugin-skill loading bypasses SKILL.md reads entirely — if so, the `Skill` tool path (now logged) is the fallback.
  4. **Tighten path matching** to exclude paths under `wt-*` / `worktree-*` directories from hook-test-pollution if needed (low priority — small volume).

- **Out of scope for this RPI** (separate work):
  - Named metric stream for `requires: metric_logged: ...` preconditions — this is a workflow-instrumentation concern, not a hook concern.
  - User-reaction capture (thumbs-up/down) — handled by the morning summary asking the user, per decision 012 pillar 1. The hook should not try to capture this.
  - Aggregation / precondition-checking logic — lives in the morning summary or a sibling script that reads `usage.jsonl`. Not part of the hook itself.

- **Relevant files for RPI research phase** (read first):
  - `~/.claude/hooks/log-usage.sh` (the existing pre-hook)
  - `~/.claude/settings.json` (hooks wiring — needs a `PostToolUse` array added)
  - `~/.claude/logs/usage.jsonl` (sample current shape; check the `.pre-fix` and `.bak` backups for prior schema migrations)
  - `docs/decisions/012-hypothesis-grammar-for-user-surfaced-evaluation.md` (pillar 4 requirements)
  - `hooks/log-usage.sh` (the repo's copy; check whether it's authoritative or a snapshot)
