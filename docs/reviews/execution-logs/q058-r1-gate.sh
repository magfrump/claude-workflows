#!/usr/bin/env bash
set -euo pipefail
vis() {
  LC_ALL=C perl -pe '
    s/\x1b/^[/g; s/\r/^M/g;
    s/[\x00-\x08\x0b\x0c\x0e-\x1a\x1c-\x1f\x7f]/?/g;
    s/\xc2[\x80-\x9f]/?/g;
    s/([\xc2-\xdf][\x80-\xbf]|[\xe0-\xef][\x80-\xbf]{2}|[\xf0-\xf4][\x80-\xbf]{3})|[\x80-\x9f]/defined $1 ? $1 : "?"/ge;
  '
}
CLAUDE_PROC_RE='(^|/)claude(\.exe)?( |$)|/@anthropic-ai/claude-code/'
agent_gate() {
  local what="$1" procs rc=0 ctrs err errf
  if ! command -v pgrep >/dev/null 2>&1; then
    echo "ERROR: pgrep is not installed, so install.sh cannot check that no Claude Code" >&2
    echo "       session is running (Q-058). Install procps and rerun. $what" >&2
    exit 1
  fi
  procs="$(pgrep -u "$(id -u)" -af -- "$CLAUDE_PROC_RE")" || rc=$?
  if [ "$rc" -gt 1 ]; then
    echo "ERROR: pgrep failed (exit $rc) while checking for Claude Code sessions (Q-058). $what" >&2
    exit 1
  fi
  procs="$(printf '%s\n' "$procs" | awk -v self="$$" 'NF && $1 != self')"
  # cc-isolated's containers carry the label cc-project=<id> (its --id-label).
  ctrs=""
  if ! command -v docker >/dev/null 2>&1; then
    echo "NOTE: docker not found: cc-isolated containers not checked, treated as none running."
  else
    # Only stdout is the container list. stderr carries warnings (a locale
    # warning, a docker CLI deprecation notice) that must not read as a running
    # container, so it is kept apart and shown only when the call fails.
    errf="$(mktemp "${TMPDIR:-/tmp}/cw-docker-err.XXXXXX")"
    if ! ctrs="$(timeout 20 docker ps --filter label=cc-project \
                   --format '{{.Names}} cc-project={{.Label "cc-project"}}' 2>"$errf")"; then
      err="$(head -n 1 "$errf" 2>/dev/null)"
      echo "NOTE: docker is unreachable ($err): cc-isolated containers not checked, treated as none running." | vis
      ctrs=""
    fi
    rm -f "$errf"
    ctrs="$(printf '%s\n' "$ctrs" | awk 'NF')"
  fi
  if [ -z "$procs" ] && [ -z "$ctrs" ]; then return 0; fi
  {
    echo "ERROR: an agent is running. install.sh installs only while no agent can run, because"
    echo "       one could change what you review before it is installed (Q-058)."
    if [ -n "$procs" ]; then
      echo "       Claude Code processes of uid $(id -u) (PID and command line):"
      printf '%s\n' "$procs" | sed 's/^/           /'
      echo "       Stop them: end each Claude Code session (/exit), or kill <PID>."
    fi
    if [ -n "$ctrs" ]; then
      echo "       Running cc-isolated containers (name and project id):"
      printf '%s\n' "$ctrs" | sed 's/^/           /'
      echo "       Stop them: docker stop <name>"
    fi
    echo "       Then rerun install.sh. $what"
  } | vis >&2
  exit 1
}
agent_gate "WHAT"; echo "gate returned 0"
