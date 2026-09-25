#!/usr/bin/env bash
# Security review pass 4 (2026-09-25): does git_state_gate's read, with the
# GIT_EXEC_KEYS_RE of install.sh at f5e3029, list every spelling of a
# config-based hook key a writer can put in .git/config or config.worktree?
# Each case writes the RAW config text (not `git config`), so case, legacy
# subsection syntax, whitespace and continuation lines are exercised as git's
# parser sees them. The read is install.sh:209's command, verbatim.
# Hermetic: temp HOME, empty global config, no system config, all state in a
# mktemp dir under $TMPDIR. Writes hookkeys-probe.log next to this script.
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_SH=/workspace/.claude/wt-q058p2/devcontainer-config/install.sh
GIT_EXEC_KEYS_RE="$(sed -n "s/^GIT_EXEC_KEYS_RE='\\(.*\\)'$/\\1/p" "$INSTALL_SH")"
P="$(mktemp -d "${TMPDIR:-/tmp}/hookkeys.XXXXXX")"
export HOME="$P/home" GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL="$P/empty"
mkdir -p "$HOME"; : > "$GIT_CONFIG_GLOBAL"

gate_read() {   # install.sh:209, verbatim apart from the file
  git --no-pager -c core.hooksPath=/dev/null config --file "$1" --no-includes --get-regexp "$GIT_EXEC_KEYS_RE"
}

case_() {   # case_ <label> <raw config text>
  local f="$P/cfg" out rc=0
  printf '%b' "$2" > "$f"
  out="$(gate_read "$f" 2>&1)" || rc=$?
  # What git itself parses out of the file, to show the key is real.
  printf '%-44s parsed: %-34s gate rc=%s listed: %s\n' "$1" \
    "$(git config --file "$f" --no-includes --list 2>&1 | tr '\n' ' ')" "$rc" "${out:-<nothing>}"
}

{
  git --version
  echo "GIT_EXEC_KEYS_RE=$GIT_EXEC_KEYS_RE"
  echo "(rc 0 + a listed key = refused; rc 1 + <nothing> = passes the gate)"
  echo
  case_ 'H1 [hook "x"] command'              '[hook "x"]\n\tcommand = /p/x.sh\n\tevent = pre-commit\n'
  case_ 'H2 [HOOK "X"] COMMAND (upper case)'  '[HOOK "X"]\n\tCOMMAND = /p/x.sh\n'
  case_ 'H3 [Hook "x"] Event (mixed case)'    '[Hook "x"]\n\tEvent = post-index-change\n'
  case_ 'H4 [hook.x] legacy subsection'       '[hook.x]\n\tcommand = /p/x.sh\n'
  case_ 'H5 [hook] command (no subsection)'   '[hook]\n\tcommand = /p/x.sh\n'
  case_ 'H6 [hook "a.b c"] dotted subsection' '[hook "a.b c"]\n\tcommand = /p/x.sh\n'
  case_ 'H7 leading whitespace before section' '   [hook "x"]\n\tcommand = /p/x.sh\n'
  case_ 'H8 value with line continuation'     '[hook "x"]\n\tcommand = /p/\\\n x.sh\n'
  case_ 'H9 key on the section line'          '[hook "x"] command = /p/x.sh\n'
  case_ 'H10 [hook ""] empty subsection'      '[hook ""]\n\tcommand = /p/x.sh\n'
  case_ 'H11 bare boolean key'                '[hook "x"]\n\tenabled\n'
  case_ 'C1 control: [hooks "x"] (not hook.)' '[hooks "x"]\n\tcommand = /p/x.sh\n'
  case_ 'C2 control: [core] hooksPath'        '[core]\n\thooksPath = /p\n'
  case_ 'C3 control: [includeIf "gitdir:/"]'  '[includeIf "gitdir:/"]\n\tpath = /p/inc\n'
  echo
  echo "Linked worktree: is config.worktree read (extensions.worktreeConfig on)?"
  git init -q "$P/r"; git -C "$P/r" -c user.email=t@t -c user.name=t commit -q --allow-empty -m i
  git -C "$P/r" worktree add -q "$P/wt" 2>/dev/null
  git -C "$P/r" config extensions.worktreeConfig true
  git -C "$P/wt" config --worktree hook.w.command /p/w.sh
  f="$(git -C "$P/wt" rev-parse --git-path config.worktree)"
  case "$f" in /*) ;; *) f="$P/wt/$f" ;; esac
  echo "  config.worktree = $f"
  echo "  gate listed: $(gate_read "$f" || echo '<nothing>')"
} > "$here/hookkeys-probe.log" 2>&1
cat "$here/hookkeys-probe.log"
