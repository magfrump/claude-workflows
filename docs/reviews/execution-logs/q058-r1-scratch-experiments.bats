#!/usr/bin/env bats
# @category slow
# Hermetic tests for install.sh's host ~/.claude target (decision 037,
# plan docs/working/plan-copy-install-bare-host.md, T1-T24).
#
# HERMETICITY. install.sh writes real host paths by default. Every test pins
# HOME, CLAUDE_HOME_DIR, CLAUDE_DEVC_CONFIG_DIR, CLAUDE_DEVC_BIN_DIR and TMPDIR
# into BATS_TEST_TMPDIR, and unsets CLAUDE_CONFIG_DIR (set in Claude Code
# sessions; install.sh honours it as a destination). The installer under test is
# a COPY inside a throwaway fake repo, never this checkout's live paths.
#
# The y path needs a TTY, which is the point of the host target's skip rule. The
# pty tests get one from util-linux `script -qec CMD /dev/null`, fed the answers
# on stdin ("n\ny\n" = decline the devcontainer target, accept the host one).
# They also unset CLAUDECODE, which the installer treats as "running inside a
# Claude Code session" (T22).
#
# Usage: bats test/install-host.bats

bats_require_minimum_version 1.5.0

setup() {
  CONFIG_SRC="/workspace/.claude/wt-copyinstall/devcontainer-config"
  S="$BATS_TEST_TMPDIR"
  export HOME="$S/home"
  export CLAUDE_HOME_DIR="$HOME/.claude"
  export CLAUDE_DEVC_CONFIG_DIR="$HOME/.config/claude-devcontainer"
  export CLAUDE_DEVC_BIN_DIR="$HOME/.local/bin"
  export TMPDIR="$S/tmp"
  export SHELL=/bin/bash   # `script -c` runs the command under $SHELL
  unset CLAUDE_CONFIG_DIR USAGE_LOG_FILE
  mkdir -p "$HOME" "$TMPDIR"
  ROOT="$S/repo"
  INSTALL="$ROOT/devcontainer-config/install.sh"
  # The no-agent gate (Q-058) asks pgrep and docker what is running. The session
  # running these tests is itself a Claude Code process, so both are stubbed to
  # "nothing running" by default; a test that wants an agent rewrites a stub.
  # Every stub call is logged to $S/probe.log.
  STUB="$S/stub"
  mkdir -p "$STUB"
  stub_pgrep 'exit 1'
  stub_docker 'exit 0'
  export PATH="$STUB:$PATH"
}

# stub_pgrep / stub_docker <body>: replace the stub's body (after logging argv).
stub_pgrep() {
  printf '#!/bin/bash\necho "pgrep $*" >> "%s/probe.log"\n%s\n' "$S" "$1" > "$STUB/pgrep"
  chmod +x "$STUB/pgrep"
}
stub_docker() {
  printf '#!/bin/bash\necho "docker $*" >> "%s/probe.log"\n%s\n' "$S" "$1" > "$STUB/docker"
  chmod +x "$STUB/docker"
}

# path_without <cmd...>: print a PATH (stubs first) under which each named
# command is absent: every other executable on the current PATH is linked
# into one directory, skipping the named ones.
path_without() {
  local farm="$S/farm" dir f skip
  mkdir -p "$farm"
  local IFS=:
  for dir in $PATH; do
    [ "$dir" = "$STUB" ] && continue
    for f in "$dir"/*; do
      [ -x "$f" ] && [ ! -d "$f" ] || continue
      for skip in "$@"; do [ "${f##*/}" = "$skip" ] && continue 2; done
      [ -e "$farm/${f##*/}" ] || ln -s "$f" "$farm/${f##*/}"
    done
  done
  for skip in "$@"; do rm -f "$STUB/$skip"; done
  printf '%s:%s\n' "$STUB" "$farm"
}

teardown() {
  # T16 makes the destination read-only; let bats clean it up.
  [ -d "$S/home/.claude" ] && chmod -R u+w "$S/home/.claude" 2>/dev/null || true
}

need_script() {
  command -v script >/dev/null || skip "util-linux script not installed (needed for a pty)"
}

# A throwaway git repo holding a copy of install.sh, the seven claude-home
# sources and a stub devcontainer payload. cc-isolated.sh is an executable stub,
# so a devcontainer "y" runs a fake --bless instead of anything real.
fake_repo() {
  local cfg="$ROOT/devcontainer-config" f
  rm -rf "$ROOT"
  mkdir -p "$cfg/egress" "$ROOT/global-instructions" "$ROOT/skills/a" "$ROOT/workflows" \
           "$ROOT/guides" "$ROOT/patterns" "$ROOT/hooks/lib" "$ROOT/scripts"
  cp "$CONFIG_SRC/install.sh" "$cfg/install.sh"
  printf 'global instructions\n' > "$ROOT/global-instructions/CLAUDE.md"
  printf 'skill a\n'  > "$ROOT/skills/a/SKILL.md"
  printf 'workflow\n' > "$ROOT/workflows/w.md"
  printf 'guide\n'    > "$ROOT/guides/g.md"
  printf 'pattern\n'  > "$ROOT/patterns/p.md"
  printf '#!/bin/bash\nexit 0\n' > "$ROOT/hooks/h.sh"
  printf '#!/bin/bash\n' > "$ROOT/hooks/lib/x.sh"
  printf '{"hooks":{}}\n' > "$ROOT/hooks/wiring.json"
  printf '#!/bin/bash\n' > "$ROOT/scripts/s.sh"
  for f in devcontainer.json Dockerfile init-firewall.sh cc-sni-proxy.py link-claude-home.sh; do
    printf 'stub %s\n' "$f" > "$cfg/$f"
  done
  printf '#!/usr/bin/env bash\necho "BLESS-STUB $*"\n' > "$cfg/cc-isolated.sh"
  chmod +x "$cfg/cc-isolated.sh"
  printf 'api.anthropic.com\n' > "$cfg/egress/base.txt"
  printf 'devcontainer-config/claude-home/\n' > "$ROOT/.gitignore"
  git -C "$ROOT" init -q
  commit_all init
}

# install.sh stages COMMITTED content only, so a fixture edit that should be
# installed has to be committed.
commit_all() {
  git -C "$ROOT" add -A
  git -C "$ROOT" -c user.email=t@t -c user.name=t commit -q -m "${1:-edit}"
}

# The README's symlink install, plus host-owned user state that must survive.
symlink_install() {
  local d="$CLAUDE_HOME_DIR" n
  mkdir -p "$d/hooks" "$d/projects/x" "$d/memory" "$d/logs"
  ln -s "$ROOT/global-instructions/CLAUDE.md" "$d/CLAUDE.md"
  for n in workflows skills patterns guides scripts; do ln -s "$ROOT/$n" "$d/$n"; done
  ln -s "$ROOT/hooks/h.sh" "$d/hooks/h.sh"           # per-file hook link
  printf 'copied security hook\n' > "$d/hooks/guard.py"  # README's copied hooks
  printf '{"user":"settings"}\n' > "$d/settings.json"
  printf '{"local":1}\n'        > "$d/settings.local.json"
  printf 'p\n'                  > "$d/projects/x/p.json"
  printf 'm\n'                  > "$d/memory/m.md"
  printf '{"l":1}\n'            > "$d/logs/usage.jsonl"
  printf 'secret\n'             > "$d/.credentials.json"
}

# Listing + content hashes of a tree, not following links. Excludes the
# devcontainer staging dir (every run reassembles it) and .git.
snap() {
  local dir="$1"
  [ -e "$dir" ] || { echo "ABSENT"; return; }
  (cd "$dir" && find . -path ./.git -prune -o -path ./devcontainer-config/claude-home -prune \
     -o -printf '%p %y %l\n' | sort
   cd "$dir" && find . -path ./.git -prune -o -path ./devcontainer-config/claude-home -prune \
     -o -type f -print0 | sort -z | xargs -0 -r sha256sum)
}

# Run install.sh inside a pty. $1 = answers (printf %b), rest = command words.
run_pty() {
  local input="$1"; shift
  run bash -c 'set -o pipefail; printf "%b" "$1" | env -u CLAUDECODE script -qec "$2" /dev/null | tr -d "\r"' \
      _ "$input" "$*"
}

# Like run_pty, but stdin comes from the shell snippet $1, so a test can act
# while install.sh waits at a prompt (e.g. tamper with the stage, then answer).
run_pty_feed() {
  local feed="$1"; shift
  run bash -c 'set -o pipefail; { eval "$1"; } | env -u CLAUDECODE script -qec "$2" /dev/null | tr -d "\r"' \
      _ "$feed" "$*"
}

# Feed snippet: answer n to the devcontainer target, wait (max ~20 s) for the
# host stage, give the review time to finish, run $TAMPER, then answer y.
# shellcheck disable=SC2034  # copied from install-host.bats; probe files do not use it
FEED_TAMPER='printf "n\n"
  for _i in $(seq 200); do compgen -G "$TMPDIR/cw-host-stage.*/payload/.manifest" >/dev/null && break; sleep 0.1; done
  sleep 2; eval "$TAMPER"; printf "y\n"'

no_host_stage_left() {
  ! compgen -G "$TMPDIR/cw-host-stage.*" >/dev/null
}


vis_fails() {
  printf '#!/bin/bash\ncase "$1" in -pe) cat >/dev/null; exit 1 ;; esac\nexec %s "$@"\n' \
    "$(command -v perl)" > "$STUB/perl"
  chmod +x "$STUB/perl"
}

@test "X1 host first install, entries over 200 lines, vis failing: does it stop before the prompt?" {
  need_script; fake_repo
  for i in $(seq 300); do echo "line $i"; done > "$ROOT/global-instructions/CLAUDE.md"
  commit_all big
  vis_fails
  run_pty 'n\ny\n' bash "$INSTALL"
  echo "STATUS=$status"; echo "$output"
  [[ "$output" != *'Install these files'* ]]
  [ ! -e "$CLAUDE_HOME_DIR/CLAUDE.md" ]
}

@test "X2 host REPLACE/MOVE lines with vis failing: does it stop before the prompt?" {
  need_script; fake_repo; symlink_install
  vis_fails
  run_pty 'n\ny\n' bash "$INSTALL"
  echo "STATUS=$status"; echo "$output"
  [[ "$output" != *'Install these files'* ]]
  [ -L "$CLAUDE_HOME_DIR/CLAUDE.md" ]
}

@test "X3 docker absent, --yes run: how many NOTE lines?" {
  fake_repo
  p=$(path_without docker)
  run env -u CLAUDECODE PATH="$p" bash "$INSTALL" --yes </dev/null
  echo "STATUS=$status"; echo "$output"
  echo "NOTES=$(grep -c 'docker not found' <<<"$output")"
}

@test "X4 docker lists a container but exits non-zero: treated as unreachable?" {
  fake_repo
  stub_docker 'echo "brave_turing cc-project=0123"; echo "error during connect" >&2; exit 1'
  run env -u CLAUDECODE bash "$INSTALL" --yes </dev/null
  echo "STATUS=$status"; echo "$output"
}
