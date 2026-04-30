# R2 Token Tracking (Narrow) — Research + Plan

## Goal

Capture actual token usage from each implementer agent and surface it in
round reports + morning summary. Re-attempt of R1's token-tracking task
which was rejected for file-scope sprawl.

## Spike outcome (5 minutes)

**Q: Where does the claude CLI persist session logs?**

A: `~/.claude/projects/<encoded-cwd>/<session-id>.jsonl`

- Encoded cwd: every `/` becomes `-`. So `/home/magfrump/wt-foo` becomes
  `-home-magfrump-wt-foo`.
- Each `.jsonl` line is one event; `type == "assistant"` entries carry
  `.message.usage` with `input_tokens`, `output_tokens`,
  `cache_read_input_tokens`, `cache_creation_input_tokens`.
- Sums work cleanly with `jq -s`.

No stdout/stderr capture wrapper needed. Pivot avoided.

## What we know about the existing pipeline

- `scripts/self-improvement.sh` step 3 launches each implementer agent in
  a worktree at `$WT_DIR = ~/wt-<task_id>` (lines 686-707).
- Step 4 validates each launched task in a per-task loop (lines 729-947);
  this is where we read the now-quiescent session log.
- Per-task validation results are recorded into `$ROUND_LOG_FILE` via
  `record_gate` / `record_gate_detail`, then flushed to
  `$WORKING_DIR/round-${round}-report.json` by `finalize_round_log`.
- `scripts/lib/si-morning-summary.sh::generate_morning_summary` consumes
  the per-round reports and emits `morning-summary.md`.

## Invariants to preserve

- Implementer agent is unchanged — no `--session-id`, no
  `--output-format=json`. Token tracking is post-invocation only.
- File scope: `scripts/lib/si-token-tracking.sh`,
  `scripts/self-improvement.sh`, `scripts/lib/si-morning-summary.sh`.
  Anything else is a scope exception.
- No new dependencies. `jq` is already required.

## Plan

### 1. New helper `scripts/lib/si-token-tracking.sh`

One function:

```
record_implementer_tokens <task_id> <wt_dir> <round_log_file>
```

Steps:
1. Encode `<wt_dir>` to project-dir name (`s|/|-|g`).
2. Find the most-recently-modified `*.jsonl` under
   `~/.claude/projects/<encoded>/`. If none, write
   `tokens_in = 0, tokens_out = 0, source = "missing"` and return.
3. Use `jq -s` to sum:
   - tokens_in = Σ (input_tokens + cache_read_input_tokens +
     cache_creation_input_tokens) across `assistant` entries.
   - tokens_out = Σ output_tokens.
4. Write into the round log under
   `.validation[task_id].tokens_in` / `.tokens_out`.

### 2. One-line wire-up in `scripts/self-improvement.sh`

- Add a `source` near the existing `source "$SCRIPT_DIR/lib/..."` block.
- Inside the validation loop (`for TASK_ID in $LAUNCHED_TASKS`), after
  `echo "  Checking: $TASK_ID"` — call
  `record_implementer_tokens "$TASK_ID" "$WT_DIR" "$ROUND_LOG_FILE"`.
  This runs before any reject-cleanup so the worktree path is still the
  one that hosted the agent (the encoded project dir lives under
  `~/.claude/projects` anyway, but doing it early keeps things simple).

### 3. Round mean in `scripts/lib/si-morning-summary.sh`

In `_summary_header`, after the existing approval-pct line, compute
mean tokens_in / tokens_out across launched tasks for the run and emit
one line. Per-round detail in `_summary_whats_new` heading line.

### 4. Out of scope

- No estimation (R1's hypothesis-first task gate already estimates).
- No cost calculation (tokens only).
- No per-gate breakdown.
- No rolling history beyond round-N-report.json.

## Verification

1. Inspect token-tracking helper with shellcheck.
2. Source helper, call it against a known session log, confirm
   tokens_in/tokens_out match `jq -s` reference numbers.
3. Run a small SI round (or simulate by hand-injecting a recorded
   session log) and confirm round-N-report.json has the new fields.
4. Generate morning-summary.md and confirm the mean line renders.
