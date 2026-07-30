#!/usr/bin/env bash
# PostToolUse hook: security audit of edited Claude trusted-policy files.
#
# Fires after Edit/Write/MultiEdit and, ONLY when the edited file is a
# trusted-policy file (settings*.json, CLAUDE.md/AGENTS.md, .mdc rules,
# anything under a .claude/skills/memories/commands/agents dir), runs
# claude_config_audit.py against that single file. Trusted-policy files are
# read as INSTRUCTIONS by the harness, so a prompt-injection or
# sandbox-escape payload smuggled into one is worth interrupting for;
# ordinary source files are DATA and are deliberately not scanned here.
#
# Behavior:
#   - No HIGH-severity findings → silent exit 0 (the common case).
#   - HIGH-severity findings   → findings on stderr + exit 2, which feeds
#     them back to Claude as post-edit feedback so the edit gets reviewed
#     or reverted. The edit itself has already happened; nothing is blocked
#     for the user.
#   - Audit script missing, python3 missing, malformed payload, non-policy
#     file → silent exit 0. The hook must never break ordinary editing.
#
# WHERE THE AUDITOR LIVES. It ships in this repo at scripts/, resolved
# relative to this hook's own real path — the same trick log-usage.sh uses,
# and the reason `scripts` is in the image payload (decision 023). It used to
# live at ~/private_reviews/, outside the repo, so that a policy-file attacker
# could not also edit the scanner; that path is still honored as a fallback
# for bare-host installs. In cc-isolated the property is preserved more
# strongly than the old location managed: the payload at /opt/claude-workflows
# is root-owned 0555, so the agent cannot edit the auditor at all, whereas
# ~/private_reviews was node-writable. See decision 023, amendment A.
#
# Resolution order: CLAUDE_CONFIG_AUDIT_SCRIPT → repo/payload scripts/ →
# ~/private_reviews/. Disable entirely with CLAUDE_CONFIG_AUDIT_DISABLE=1.
#
# Input:  JSON on stdin (PostToolUse payload; .tool_input.file_path holds
#         the edited path).
# Output: nothing on success; HIGH findings on stderr with exit 2.

# Deliberately no `set -e`: any internal failure must fall through to a
# clean exit 0 rather than surface a hook error on every edit.

[[ "${CLAUDE_CONFIG_AUDIT_DISABLE:-0}" == "1" ]] && exit 0

if [[ -n "${CLAUDE_CONFIG_AUDIT_SCRIPT:-}" ]]; then
  AUDIT_SCRIPT="$CLAUDE_CONFIG_AUDIT_SCRIPT"
else
  # readlink -f so this resolves through ~/.claude/hooks -> /opt/claude-workflows/hooks.
  HOOK_DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
  AUDIT_SCRIPT="$HOOK_DIR/../scripts/claude_config_audit.py"
  [[ -f "$AUDIT_SCRIPT" ]] || AUDIT_SCRIPT="$HOME/private_reviews/claude_config_audit.py"
fi
[[ -f "$AUDIT_SCRIPT" ]] || exit 0
command -v python3 >/dev/null 2>&1 || exit 0

INPUT=$(cat)

if command -v jq >/dev/null 2>&1; then
  TOOL=$(printf '%s' "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null)
  FILE=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // ""' 2>/dev/null)
else
  exit 0
fi

case "$TOOL" in
  Edit|Write|MultiEdit) ;;
  *) exit 0 ;;
esac

[[ -n "$FILE" && -f "$FILE" ]] || exit 0

# Trusted-policy gate, mirroring is_policy_file() in claude_config_audit.py.
# The gate lives here (not in the auditor) because the auditor scans an
# explicit file argument unconditionally — without this gate every source
# edit would be scanned and ESCAPE/HIDDEN patterns in ordinary code (e.g.
# this repo's own hooks) would fire on every save.
is_policy_file() {
  local path="$1" name lower ext
  name=$(basename "$path")
  lower=$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]')
  ext=""
  [[ "$lower" == *.* ]] && ext=".${lower##*.}"

  case "$lower" in
    claude.md|agents.md|claude.local.md) return 0 ;;
    settings*.json) return 0 ;;
    *.mdc) return 0 ;;
    *rule*) return 0 ;;
  esac

  local policy_exts=".md .json .yaml .yml .toml .txt"
  if [[ "$path" == */.claude/* ]]; then
    if [[ -z "$ext" || " $policy_exts " == *" $ext "* ]]; then
      return 0
    fi
  fi
  if [[ "$path" == */skills/* || "$path" == */memories/* \
     || "$path" == */commands/* || "$path" == */agents/* ]]; then
    if [[ -z "$ext" || "$ext" == ".md" || "$ext" == ".txt" ]]; then
      return 0
    fi
  fi
  return 1
}

is_policy_file "$FILE" || exit 0

OUTPUT=$(python3 "$AUDIT_SCRIPT" "$FILE" 2>/dev/null)
RC=$?

# The auditor exits nonzero iff HIGH-severity findings exist, but a crashed
# run also exits nonzero — require the HIGH banner in the output too, so a
# traceback or partial run never produces a false alarm.
if [[ $RC -ne 0 ]] && printf '%s' "$OUTPUT" | grep -q "HIGH-severity"; then
  # Strip ANSI color codes; the findings are consumed as plain text.
  CLEAN=$(printf '%s\n' "$OUTPUT" | sed $'s/\033\\[[0-9;]*m//g')
  {
    printf 'SECURITY AUDIT: HIGH-severity finding(s) in trusted-policy file %s\n' "$FILE"
    printf 'This file is read as instructions by Claude Code. Review the finding(s) below;\n'
    printf 'if you did not intend them, revert or fix the edit before continuing.\n\n'
    printf '%s\n' "$CLEAN"
  } >&2
  exit 2
fi

exit 0
