# Scope exception + deploy steps: dd-brainstorm-routing-narrow-hook

The task authorized modifying exactly two files: `hooks/dd-routing-reminder.sh`
and `/home/magfrump/.claude/settings.json` (plus `docs/working/`). The hook
script is committed to the repo as planned. Two steps could **not** be applied
autonomously and are recorded here for a human (or a follow-up authorized run)
to apply. Both are operational/deploy actions, not changes to the committed
source.

## 1. settings.json wiring — blocked by the harness sensitive-file guard

`/home/magfrump/.claude/settings.json` is a **standalone live config file**: it
is not tracked in the `claude-workflows` repo and is not a symlink into it
(verified: `git ls-files | grep settings` → not tracked; `readlink -f` →
resolves to itself). The harness blocks autonomous writes to it as a sensitive
file — the same guard that, in round 1, prevented a direct edit to
`/home/magfrump/.claude/CLAUDE.md` (see
`scope-exception-dd-supersedes-brainstorm-routing.md`). In round 1 a
repo-tracked equivalent existed (the symlink target); here there is **no**
repo-tracked equivalent, so the wiring must be applied to the live file by an
authorized actor.

**The change is purely additive** — add a `UserPromptSubmit` key to the existing
`hooks` object, leaving `PreToolUse`/`PostToolUse` untouched. Apply by inserting
the block below immediately after the `PostToolUse` array's closing `]` (i.e.
change `    ]\n  },` that closes `PostToolUse`+`hooks` into `    ],` followed by
the `UserPromptSubmit` block, then `  },`):

```json
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash $HOME/.claude/hooks/dd-routing-reminder.sh"
          }
        ]
      }
    ]
```

UserPromptSubmit hooks take no `matcher` (they fire on every submit); the
*script* does the narrowing. After editing, verify the file still parses:
`jq . /home/magfrump/.claude/settings.json >/dev/null && echo OK`.

## 2. Deploy symlink for the wired command path

The wired command references `$HOME/.claude/hooks/dd-routing-reminder.sh`, matching
the convention used by the existing `log-usage*` hooks — each of which is a
per-script **symlink** from `/home/magfrump/.claude/hooks/` into the main checkout
`/home/magfrump/claude-workflows/hooks/`. Once this branch merges to `main`, the
committed `hooks/dd-routing-reminder.sh` lands at
`/home/magfrump/claude-workflows/hooks/dd-routing-reminder.sh`; create the matching
symlink so the command resolves:

```sh
ln -s /home/magfrump/claude-workflows/hooks/dd-routing-reminder.sh \
      /home/magfrump/.claude/hooks/dd-routing-reminder.sh
```

Creating this symlink touches a path outside the allowed file scope
(`/home/magfrump/.claude/hooks/...`), so it is documented rather than performed.
Until it exists the hook is inert; because the wired command is `bash <path>`, a
missing target yields a non-zero (127) exit, which is a **non-blocking** error —
it can never block prompt submission.

## Status

- Committed this round: `hooks/dd-routing-reminder.sh` (+ RPI working docs and the
  `docs/working/verify-dd-routing-reminder.sh` / `dd-hook-fixtures.txt` verification
  artifacts).
- Blocked / deferred to an authorized actor: the settings.json `UserPromptSubmit`
  insert (step 1) and the deploy symlink (step 2). Applying both makes the hook live.
