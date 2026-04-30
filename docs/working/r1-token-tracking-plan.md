# R1 Token Tracking — Plan

Capture actual token usage per implementer agent invocation in
`round-N-report.json` and surface round means in `morning-summary.md`.

## Data source

Each `claude -p` call writes a session log to
`~/.claude/projects/-{cwd-with-dashes}/{session-id}.jsonl`. Every assistant
message row has a `message.usage` object:

```
{
  "input_tokens": <int>,
  "cache_creation_input_tokens": <int>,
  "cache_read_input_tokens": <int>,
  "output_tokens": <int>,
  ...
}
```

A single API turn produces multiple rows (text, tool_use, etc.) all sharing
the same `requestId`. The `usage` totals are repeated across these rows, so
we dedupe by `requestId` before summing to avoid double counting.

## Linking sessions to tasks

`claude -p` accepts `--session-id <uuid>`. Generate a UUID per implementer
launch and pass it through, then read the resulting file directly. This
avoids globbing or diffing the project directory.

The cwd for each implementer is the worktree dir, so:

    project_dir = ~/.claude/projects/{cwd | tr '/' '-'}
    session_file = {project_dir}/{uuid}.jsonl

## Schema additions

Add a top-level `tokens` map to each round report:

```
{
  "round": 1,
  "tokens": {
    "<task-id>": {"tokens_in": 12345, "tokens_out": 678}
  },
  "validation": {...}
}
```

Stored at the top level (not inside `validation`) so the existing gate-stats
machinery (which iterates validation entries) is unaffected.

## Morning summary

In each round's section header, append `— mean tokens: Xk in / Yk out`
computed across launched tasks (i.e., everything in `.tokens`). When the
field is absent (older reports), the suffix is omitted.

## Files touched

- `scripts/lib/si-functions.sh` — add `sum_session_tokens`
- `scripts/self-improvement.sh` — wire UUID + post-launch sum into the
  implementer loop; extend `init_round_log` and add `record_task_tokens`
- `scripts/lib/si-morning-summary.sh` — round-mean helper, header suffix
