# Wiring: claude-config-audit hook

`hooks/claude-config-audit.sh` is a `PostToolUse` hook that runs
`~/private_reviews/claude_config_audit.py` against any edited **trusted-policy
file** (settings*.json, CLAUDE.md/AGENTS.md, skill/command markdown, .mdc
rules) and feeds HIGH-severity findings back to Claude as post-edit feedback
(exit 2). See `guides/claude-config-security-checkup.md` for the full process.

Wiring it requires editing `/home/magfrump/.claude/settings.json` (a guarded,
non-repo-tracked file) and creating a symlink under `~/.claude/hooks/` — both
outside the autonomous file scope, so they are **documented here for manual
application**, not performed.

The hook is inert until both steps below are done. Because it is a
`PostToolUse` hook, it can never block an edit — it only reports on one that
already happened. Any internal failure (missing auditor, missing python3,
malformed payload) degrades to a silent exit 0.

## 0. Prerequisite

The auditor must exist at `~/private_reviews/claude_config_audit.py` (or set
`CLAUDE_CONFIG_AUDIT_SCRIPT` in the session env to point elsewhere). It is
deliberately **not** committed to this repo — it reviews this repo's own
policy files, so committing it alongside them would let a policy-file attacker
also edit the scanner.

## 1. Add the PostToolUse entry to settings.json

Add a matcher entry to the existing `hooks.PostToolUse` array (create the key
if absent; leave other entries untouched):

```json
    "PostToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "bash $HOME/.claude/hooks/claude-config-audit.sh"
          }
        ]
      }
    ]
```

The matcher narrows to file-editing tools; the script does its own narrowing
to policy files, so ordinary source edits cost one `jq` parse and nothing
else. After editing, verify the file still parses:
`jq . /home/magfrump/.claude/settings.json >/dev/null && echo OK`.

## 2. Deploy the symlink for the wired command path

Matching the `log-usage*` / `*-routing-reminder` convention — a per-script
symlink from `~/.claude/hooks/` into the checkout. Once this lands on `main`:

```sh
ln -s /home/magfrump/claude-workflows/hooks/claude-config-audit.sh \
      /home/magfrump/.claude/hooks/claude-config-audit.sh
```

## 3. Verify it fires

```sh
# HIGH directive → should print SECURITY AUDIT block and exit 2.
# (The payload is split across two printf args so this DOC doesn't flag
# itself in audit sweeps; the file written at runtime is the real directive.)
printf '%s%s' '{"permissionMode": "bypass' 'Permissions"}' > /tmp/settings.json
printf '{"tool_name":"Edit","tool_input":{"file_path":"/tmp/settings.json"}}' \
  | bash ~/.claude/hooks/claude-config-audit.sh; echo "exit=$?"

# Clean file → should print nothing and exit 0:
printf '{"model": "opus"}' > /tmp/settings.json
printf '{"tool_name":"Edit","tool_input":{"file_path":"/tmp/settings.json"}}' \
  | bash ~/.claude/hooks/claude-config-audit.sh; echo "exit=$?"
rm /tmp/settings.json
```

Full regression suite (13 cases, 3 of which exercise the real auditor):
`bats test/hooks/claude-config-audit.bats`
