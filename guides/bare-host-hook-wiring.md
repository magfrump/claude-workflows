# Wiring the hooks on a bare host

**Scope.** Inside the `cc-isolated` devcontainer none of this is needed: at every
container start `devcontainer-config/link-claude-home.sh` merges `hooks/wiring.json`
into `~/.claude/settings.json` (decision 023 and its amendments). This guide is the
procedure for a **bare host**, meaning a plain checkout symlinked into `~/.claude` as in the
README's Linux/macOS setup. There the wiring is a manual edit of a guarded file that no
repo artifact tracks.

It replaces the three `docs/working/wire-*.md` docs, archived 2026-08-06. Their JSON
snippets were superseded by `hooks/wiring.json`. The bare-host notes below were carried
over from them.

## 1. Install the hook scripts

The README's setup block does this. There are two conventions, on purpose:

- **Symlinks** for the non-blocking hooks (`log-usage.sh`, `log-usage-post.sh`,
  `dd-routing-reminder.sh`, `batch-feedback-routing-reminder.sh`,
  `claude-config-audit.sh`). Repo edits take effect immediately.
- **Copies** for the hooks on the permission path (`guard-trusted-writes.py`,
  `web-taint-mark.py`, `auto-approve-allowed-commands.sh`, `live-verify-gate.sh`).
  `permissions.deny` protects `~/.claude/hooks/**`, but the checkout is an ordinary
  writable directory. A symlink would let an unguarded repo edit change live
  security-hook behavior, while a copy only changes when you deliberately re-copy it
  after pulling. `claude-config-audit.sh` has the same exposure and is still a
  symlink, which is an open follow-up.

Every hook `wiring.json` names must be installed before you wire it. A wired
`bash <missing path>` exits 127, which Claude Code shows as a non-blocking error on
every matching tool call.

## 2. Merge `hooks/wiring.json` into `~/.claude/settings.json`

`hooks/wiring.json` is the canonical wiring. It has two sections, `hooks` (event,
matcher, command) and `permissions.deny`. Print it with the `{{CLAUDE_DIR}}` token
resolved and the comment dropped:

```sh
jq --arg dir "$HOME/.claude" \
  'del(._comment) | walk(if type == "string" then gsub("\\{\\{CLAUDE_DIR\\}\\}"; $dir) else . end)' \
  ~/claude-workflows/hooks/wiring.json
```

Merge the output into `~/.claude/settings.json` by hand:
- For each event key under `hooks`, add these matcher groups beside any you already
  have.
- Add the `permissions.deny` rules to your existing list.

Then check that the file still parses: `jq . ~/.claude/settings.json >/dev/null && echo OK`.

The deny rules are not optional. On its HARD tier (`~/.claude/settings*.json`,
`~/.claude/hooks/**`, `~/.claude/CLAUDE.md`, `~/CLAUDE.md`), `guard-trusted-writes.py`
defers for the file tools instead of returning "ask", because a hook "ask" silently
overrides `permissions.deny` (Claude Code issue #39344). Wire the hook without these
rules and that tier does nothing for Edit/Write (decision 023 amendment B). The guard's
matcher must include `Bash`, or its Bash write-detection branch never runs.

When you pull a change to `wiring.json`, redo the merge and remove the entries it
replaced. Your hand-merged copy will not notice the change on its own.

## 3. Hardening that `wiring.json` does not carry (still manual)

These were applied on 2026-07-09 and are recorded here because `settings.json` has
no history:

- **`permissions.allow`:** remove prefixes that allow arbitrary execution: `find:*`,
  `fd:*`, `wsl:*`, `hyperfine:*`, `sed -n:*`, `terraform plan:*`. The allowed
  substitutes are in `guides/sandbox-tool-map.md`.
- **`sandbox`:** enable it. Set `denyRead` to mirror the credential deny list, and
  `denyWrite` to `~/.claude`, `~/CLAUDE.md` and the auditor script. The sandbox is
  deliberately broader than the Edit/Write deny rules: memories stay writable with the
  file tools, while Bash sees `~/.claude` as read-only.
- **WSL2 prerequisite:** bwrap needs
  `C:\Program Files\ClaudeCode\managed-settings.json` (containing `{}`) and
  `managed-settings.d\` to exist. Create both as a Windows admin, or **every** Bash call
  fails at sandbox setup.
- **Config auditor location:** `claude-config-audit.sh` resolves its own symlink, so on a
  bare host it runs the checkout's `scripts/claude_config_audit.py` with no extra step.
  The resolution order is `CLAUDE_CONFIG_AUDIT_SCRIPT`, then `<hook dir>/../scripts/`,
  then `~/private_reviews/`. If it finds none, the hook does nothing. Add the auditor's
  path to sandbox `denyWrite` (above): a policy-file attacker who can edit the scanner
  can blind it. See `guides/claude-config-security-checkup.md`.

## 4. Verify

```sh
# Guard: inside a session, this must be denied before it runs (no file created):
#   echo canary > ~/.claude/hooks/CANARY-delete-me.txt

# Taint marking (simulated payload, outside a session):
printf '{"session_id":"testsid","tool_name":"WebFetch"}' \
  | python3 ~/.claude/hooks/web-taint-mark.py && ls /tmp/cc-web-taint/testsid

# Tainted session + write to a soft policy path -> permissionDecision "ask":
printf '{"session_id":"testsid","tool_name":"Write","tool_input":{"file_path":"%s/.claude/skills/x/SKILL.md"}}' "$HOME" \
  | python3 ~/.claude/hooks/guard-trusted-writes.py
rm -f /tmp/cc-web-taint/testsid

# Config audit: a HIGH directive prints a SECURITY AUDIT block and exits 2.
# (The payload is split across two printf arguments so this guide doesn't flag itself.)
T="${TMPDIR:-/tmp}"
printf '%s%s' '{"permissionMode": "bypass' 'Permissions"}' > "$T/settings.json"
printf '{"tool_name":"Edit","tool_input":{"file_path":"%s/settings.json"}}' "$T" \
  | bash ~/.claude/hooks/claude-config-audit.sh; echo "exit=$?"
rm "$T/settings.json"
```

The hook test suites cover the same ground offline: `bats test/hooks/` and
`bats test/auto-approve-allowed-commands.bats`.

## Known accepted gaps

- Taint marking covers only `WebSearch|WebFetch`. MCP web tools have to be added to the
  matcher by name.
- Taint does not pass between a parent session and its subagents.
- The guard's Bash write detection is regex heuristics, not a shell parse, so an
  obfuscated write can get past it. The backstops are sandbox `denyWrite ~/.claude` and
  the PostToolUse config audit.
- **False positive:** the guard scans prose inside a command as if it were shell. A
  heredoc commit message that names a hard policy path is denied, because the
  `Co-Authored-By: ... <noreply@anthropic.com>` trailer's closing `>` matches the
  redirect regex. Write the message to a file and use `git commit -F <file>`.
- `auto-approve-allowed-commands.sh` has filter-coverage gaps: arithmetic expansion,
  heredoc bodies, `VAR=` prefixes and redirect targets. They are accepted as risk in
  decision log row 53. Commands it cannot parse fall through to the normal prompt.
