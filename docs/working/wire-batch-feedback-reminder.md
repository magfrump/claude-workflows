# Wiring: batch-feedback-routing-reminder hook

`hooks/batch-feedback-routing-reminder.sh` is a `UserPromptSubmit` hook that
escalates decision-tree **row 2** ("Message bundles 2+ independent tasks") into a
harness-injected, non-blocking reminder to fan work out to parallel subagents.
Wiring it requires editing `/home/magfrump/.claude/settings.json` (a guarded,
non-repo-tracked file) and creating a symlink under `~/.claude/hooks/` — both
outside the autonomous file scope, so they are **documented here for manual
application**, not performed.

The hook is inert until both steps below are done. Because the wired command is
`bash <path>`, a missing target yields a non-zero (127) exit, which is a
**non-blocking** error — it can never block prompt submission.

> **Note:** As of this writing the sibling `dd-routing-reminder.sh` was committed
> but never actually wired live (`.hooks.UserPromptSubmit` is absent from
> `settings.json` and no `~/.claude/hooks/dd-routing-reminder.sh` symlink exists).
> The block below wires **both** reminders at once. Drop the dd entry if you only
> want the batch reminder.

## 1. Add the UserPromptSubmit block to settings.json

`UserPromptSubmit` is currently absent. Add it as a new key inside the existing
`hooks` object (leave `PreToolUse`/`PostToolUse` untouched). A single
`UserPromptSubmit` entry can run multiple commands — both reminders go in one
array:

```json
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash $HOME/.claude/hooks/batch-feedback-routing-reminder.sh"
          },
          {
            "type": "command",
            "command": "bash $HOME/.claude/hooks/dd-routing-reminder.sh"
          }
        ]
      }
    ]
```

`UserPromptSubmit` hooks take no `matcher` (they fire on every submit); each
*script* does its own narrowing, and each prints at most one line, so a prompt
that somehow matches both prints two independent reminders. After editing, verify
the file still parses:
`jq . /home/magfrump/.claude/settings.json >/dev/null && echo OK`.

## 2. Deploy symlinks for the wired command paths

The wired commands reference `$HOME/.claude/hooks/<script>.sh`, matching the
convention the `log-usage*` hooks use — each is a per-script **symlink** from
`/home/magfrump/.claude/hooks/` into the checkout `/home/magfrump/claude-workflows/hooks/`.
Once this branch merges to `main`, create the symlink(s):

```sh
ln -s /home/magfrump/claude-workflows/hooks/batch-feedback-routing-reminder.sh \
      /home/magfrump/.claude/hooks/batch-feedback-routing-reminder.sh
# (optional, if also wiring the dd reminder above)
ln -s /home/magfrump/claude-workflows/hooks/dd-routing-reminder.sh \
      /home/magfrump/.claude/hooks/dd-routing-reminder.sh
```

## 3. Verify it fires

```sh
# Should print the batch reminder:
printf '{"prompt":"A few things: export is broken, header overlaps, add CSV"}' \
  | bash ~/.claude/hooks/batch-feedback-routing-reminder.sh
# Should print nothing (single task):
printf '{"prompt":"fix the export button"}' \
  | bash ~/.claude/hooks/batch-feedback-routing-reminder.sh
```

Full regression suite (15 cases): `bash docs/working/verify-batch-feedback-reminder.sh`
