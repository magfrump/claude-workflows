# Wiring the hooks on a bare host

**Scope.** Inside the `cc-isolated` devcontainer none of this is needed: at every
container start `devcontainer-config/link-claude-home.sh` merges `hooks/wiring.json`
into `~/.claude/settings.json` (decision 023 and its amendments). This guide is the
procedure for a **bare host**: a plain checkout whose global files `install.sh` has
copied into `~/.claude`, per the README's Claude Code setup (decision 037). There the
wiring is a manual edit of a guarded file that no repo artifact tracks.

It replaces the three `docs/working/wire-*.md` docs, archived 2026-08-06. Their JSON
snippets were superseded by `hooks/wiring.json`. The bare-host notes below were carried
over from them.

## 1. Install the hook scripts

`./devcontainer-config/install.sh` does this. Answer y to its `~/.claude` target after
reading the review. First close every Claude Code session and stop every
cc-isolated container. The installer checks for both at startup, again before the
`~/.claude` target stages, and after each y, and refuses while it finds either (Q-058; see
`install.sh --help` and decision 037, "Trust model"), since a running agent could
change what you review before it is installed. The checks are samples, not a lock,
so also stop any helper or loop an agent session left running. There is one convention: **every hook is a copy**. The installer
copies the whole `hooks/` directory (including `hooks/lib/`) and the whole `scripts/`
directory, so hooks that find their helpers by their own path (`log-usage.sh` →
`lib/usage-common.sh` and `../scripts/lib/`; `claude-config-audit.sh` →
`../scripts/claude_config_audit.py`) keep working.

This supersedes the old split, which used symlinks for the non-blocking hooks and copies
for the permission-path hooks, along with the open follow-up that `claude-config-audit.sh`
was still a symlink. The reason for copies is the one that used to apply to the security
hooks alone. `permissions.deny` and sandbox `denyWrite` protect `~/.claude`, but the
checkout is an ordinary writable directory. A link would let an unreviewed repo edit
change live behavior. A copy changes only when you rerun `install.sh` and answer y.
Rerun it after every pull.

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

**Still on the old symlink install? Its checkout copies can't be edited with Claude's file tools.**
While a global file is symlinked into `~/.claude` (the README's install before the
copy-based `install.sh`), the guard **denies** Claude's file tools on its checkout copy,
tainted session or not: `global-instructions/CLAUDE.md` behind a linked
`~/.claude/CLAUDE.md`, and every `hooks/<name>` linked one file at a time into
`~/.claude/hooks/`. No deny rule names the checkout path, so deferring would leave it
with no gate at all. A hook deny has no approve option, so make these edits outside
Claude (Q-050). Bash writes naming the checkout `global-instructions/CLAUDE.md` are
denied too; Bash writes to a linked hook's checkout path are NOT gated by this hook, a
pre-existing gap alongside N2/A8. Running `install.sh` replaces the links with copies,
after which no checkout file is a live global file and this restriction no longer applies.

When `wiring.json` changes, redo the merge and remove the entries it replaced. Your
hand-merged copy will not notice the change on its own. `install.sh` does not write
`settings.json`, but it prints a `REMINDER` pointing here whenever the installed
`hooks/wiring.json` is missing or differs from the repo's.

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
- **Config auditor location:** `claude-config-audit.sh` looks for the auditor at
  `CLAUDE_CONFIG_AUDIT_SCRIPT`, then `<hook dir>/../scripts/`, then `~/private_reviews/`.
  If it finds none, the hook does nothing. With the `install.sh` copy, the second of those
  is `~/.claude/scripts/claude_config_audit.py`, which the sandbox `denyWrite ~/.claude`
  (above) already covers. A policy-file attacker who can edit the scanner can blind it,
  so if you use the `~/private_reviews/` fallback, add that path to `denyWrite` too. See
  `guides/claude-config-security-checkup.md`.

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
  obfuscated write can get past it. The backstop is sandbox `denyWrite ~/.claude`, and
  only where a sandbox is actually configured. The PostToolUse config audit is wired
  for `Edit|Write|MultiEdit` only and exits early for Bash, so it does not cover this
  path. It also reports to the model, not to you.
- **False positive:** the guard scans prose inside a command as if it were shell. A
  heredoc commit message that names a hard policy path is denied, because the
  `Co-Authored-By: ... <noreply@anthropic.com>` trailer's closing `>` matches the
  redirect regex. Write the message to a file and use `git commit -F <file>`.
- `auto-approve-allowed-commands.sh` has filter-coverage gaps: arithmetic expansion,
  heredoc bodies, `VAR=` prefixes and redirect targets. They are accepted as risk in
  decision log row 53. Commands it cannot parse fall through to the normal prompt.
  It also checks `Bash(...)` deny rules, which makes it part of the credentials
  backstop where no sandbox runs (cc-isolated has none). That check is a string match
  with known residuals; the hook header's WHAT THE DENY CHECK GUARANTEES and RULE
  SYNTAX sections are the one statement of what it covers.
