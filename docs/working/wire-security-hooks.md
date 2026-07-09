# Wiring: web-taint-mark + guard-trusted-writes (session taint gating)

Status: **wired live and verified 2026-07-09** (canary `echo x > ~/.claude/hooks/...`
denied pre-execution). This doc records the wiring for re-application after a
settings reset or on a new machine.

The pair implements session-level taint tracking:

- `hooks/web-taint-mark.py` — `PostToolUse` on `WebSearch|WebFetch`. Marks the
  current session as having ingested untrusted web content (touch file named by
  session id under `CC_WEB_TAINT_DIR`, default `/tmp/cc-web-taint`, chmod 0700).
  Never blocks; exit 0 always.
- `hooks/guard-trusted-writes.py` — `PreToolUse` on `Edit|Write|MultiEdit|Bash`.
  Two tiers of trusted-policy path:
  - **HARD** (`~/.claude/hooks/**`, `~/.claude/settings*.json`,
    `~/.claude/CLAUDE.md`, `~/CLAUDE.md`, `managed-settings.json`): for file
    tools it *defers* so the `permissions.deny` rules do the blocking (a hook
    "ask" would silently override deny — Claude Code issue #39344); for Bash
    write-primitives (`>`/`>>`, `tee`, `sed -i`, `dd of=`, `cp/mv/rsync`,
    inline interpreters) targeting these paths it returns **deny** outright,
    since deny rules don't see inside Bash commands.
  - **SOFT** (skills / memories / commands / agents / project CLAUDE.md /
    AGENTS.md / .mdc): returns **ask** only when the session is web-tainted;
    otherwise defers.
  - "No opinion" is exit 0 with **no output** — do not emit
    `permissionDecision: "defer"`, which is not a documented value.

## settings.json entries

`~/.claude/settings.json` is guarded and not repo-tracked; apply manually.

```json
"PreToolUse": [
  {
    "matcher": "Edit|Write|MultiEdit|Bash",
    "hooks": [
      { "type": "command",
        "command": "python3 \"$HOME/.claude/hooks/guard-trusted-writes.py\"" }
    ]
  }
],
"PostToolUse": [
  {
    "matcher": "WebSearch|WebFetch",
    "hooks": [
      { "type": "command",
        "command": "python3 \"$HOME/.claude/hooks/web-taint-mark.py\"" }
    ]
  }
]
```

Note the guard's matcher **must include `Bash`** — without it the entire Bash
write-detection branch is dead code (this was the state between the v2 rewrite
and 2026-07-09). If an auto-approve hook also matches Bash, precedence is safe:
deny > ask > allow.

## Deployment: copies, not symlinks (deliberate exception)

The other repo hooks follow a symlink convention
(`~/.claude/hooks/x.sh -> <checkout>/hooks/x.sh`). These two are deployed as
**independent copies**. Rationale: `permissions.deny` protects
`~/.claude/hooks/**`, but the repo checkout is an ordinary writable project
directory — a symlink would let an unguarded repo edit alter live security-hook
behavior. Copies mean repo changes take effect only after a deliberate,
user-mediated re-copy:

```sh
cp <checkout>/hooks/guard-trusted-writes.py <checkout>/hooks/web-taint-mark.py \
   ~/.claude/hooks/
```

(The same argument applies to the symlinked `claude-config-audit.sh`; converting
it to a copy is an open follow-up.)

## Related settings hardening (2026-07-09, manual, not repo-tracked)

Applied alongside this wiring, recorded here since settings.json has no history:

- `permissions.deny`: added `Read(~/.config/gcloud/**)`, `Read(~/.npmrc)`,
  `Edit/Write(~/CLAUDE.md)` (the guard's HARD tier assumes this rule exists).
- `permissions.allow`: removed arbitrary-execution-capable prefixes —
  `find:*`, `fd:*`, `wsl:*`, `hyperfine:*`, `sed -n:*`, `terraform plan:*`.
- `sandbox`: enabled, with `denyRead` mirroring the credential deny list and
  `denyWrite` on `~/.claude`, `~/CLAUDE.md`, and the external auditor script.
  The sandbox is deliberately broader than the Edit/Write deny rules so
  memories stay file-tool-writable while Bash sees `~/.claude` read-only.
- WSL2 prerequisite: bwrap needs `C:\Program Files\ClaudeCode\managed-settings.json`
  (containing `{}`) and `managed-settings.d\` to exist (create as Windows
  admin), or **every** Bash call fails at sandbox setup.

## Verify

```sh
# 1. Guard denies Bash writes to hard policy paths (expect deny, no file):
#    run inside a session: echo canary > ~/.claude/hooks/CANARY-delete-me.txt

# 2. Taint marking (outside a session, simulating the payload):
printf '{"session_id":"testsid","tool_name":"WebFetch"}' \
  | python3 ~/.claude/hooks/web-taint-mark.py && ls /tmp/cc-web-taint/testsid

# 3. Tainted session + soft policy write → ask:
printf '{"session_id":"testsid","tool_name":"Write","tool_input":{"file_path":"%s/.claude/skills/x/SKILL.md"}}' "$HOME" \
  | python3 ~/.claude/hooks/guard-trusted-writes.py   # expect permissionDecision "ask"
rm -f /tmp/cc-web-taint/testsid
```

## Known accepted gaps

- Taint only marks `WebSearch|WebFetch` — MCP web tools need adding to the
  matcher by name.
- Taint does not propagate between parent and subagent sessions.
- Bash write detection is regex heuristics, not a shell parse; obfuscated
  writes can evade it. Backstops: sandbox `denyWrite ~/.claude` and the
  PostToolUse config audit.
- **Known false positive:** prose inside a command is scanned as if it were
  shell. In particular, `git commit -m` with a heredoc message is denied
  whenever the message names a hard policy path, because the standard
  `Co-Authored-By: ... <noreply@anthropic.com>` trailer's closing `>` matches
  the redirect regex (verified 2026-07-09). Workaround: write the message to a
  scratch file and use `git commit -F <file>`. Possible regex fix if the
  friction recurs: add `\w` to the redirect lookbehind
  (`(?<![0-9&\w])>>?(?![&])`) so `word>` — as in an email address — no longer
  counts as a redirect; legitimate redirects nearly always follow whitespace
  or a bare fd digit, which the pattern already skips.
