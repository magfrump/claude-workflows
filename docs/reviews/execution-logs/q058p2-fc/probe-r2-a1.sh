#!/usr/bin/env bash
# Probe R2 (6ec64c3) and A1 (c700270). Hermetic: temp HOME, no system git
# config, stubbed pgrep/docker, throwaway fake repo, every destination under
# a temp dir. The pty comes from util-linux `script`, as in install-host.bats.
# Usage: probe-r2-a1.sh <path to install.sh under test>
set -uo pipefail

INSTALL_SRC="$1"
S="$(mktemp -d "${TMPDIR:-/tmp}/q058p2-r2.XXXXXX")"
export HOME="$S/home" TMPDIR="$S/tmp" GIT_CONFIG_NOSYSTEM=1 SHELL=/bin/bash
export CLAUDE_HOME_DIR="$HOME/.claude" CLAUDE_DEVC_CONFIG_DIR="$HOME/.config/cd" CLAUDE_DEVC_BIN_DIR="$HOME/.local/bin"
unset CLAUDE_CONFIG_DIR CLAUDECODE
mkdir -p "$HOME" "$TMPDIR" "$S/stub"
printf '#!/bin/bash\nexit 1\n' > "$S/stub/pgrep"
printf '#!/bin/bash\nexit 0\n' > "$S/stub/docker"
chmod +x "$S/stub/pgrep" "$S/stub/docker"
export PATH="$S/stub:$PATH"
ROOT="$S/repo"
INSTALL="$ROOT/devcontainer-config/install.sh"

fake_repo() {
  local cfg="$ROOT/devcontainer-config" f
  rm -rf "$ROOT" "$CLAUDE_HOME_DIR" "$CLAUDE_DEVC_CONFIG_DIR" "$CLAUDE_DEVC_BIN_DIR"
  mkdir -p "$cfg/egress" "$ROOT/global-instructions" "$ROOT/skills/a" "$ROOT/workflows" \
           "$ROOT/guides" "$ROOT/patterns" "$ROOT/hooks/lib" "$ROOT/scripts"
  cp "$INSTALL_SRC" "$INSTALL"
  printf 'g\n' > "$ROOT/global-instructions/CLAUDE.md"
  printf 's\n' > "$ROOT/skills/a/SKILL.md"
  for f in workflows/w.md guides/g.md patterns/p.md hooks/h.sh hooks/lib/x.sh hooks/wiring.json scripts/s.sh; do
    printf 'x\n' > "$ROOT/$f"
  done
  for f in devcontainer.json Dockerfile init-firewall.sh cc-sni-proxy.py link-claude-home.sh; do
    printf 'stub %s\n' "$f" > "$cfg/$f"
  done
  printf '#!/usr/bin/env bash\necho "BLESS-STUB $*"\n' > "$cfg/cc-isolated.sh"
  chmod +x "$cfg/cc-isolated.sh"
  printf 'api.anthropic.com\n' > "$cfg/egress/base.txt"
  printf 'devcontainer-config/claude-home/\n' > "$ROOT/.gitignore"
  git -C "$ROOT" init -q
  git -C "$ROOT" add -A
  git -C "$ROOT" -c user.email=t@t -c user.name=t commit -q -m init
}

state() {  # print what is left behind under the host destination and TMPDIR
  echo "    dest exists: $([ -e "$CLAUDE_HOME_DIR" ] && echo yes || echo no)"
  echo "    dest entries: $(find "$CLAUDE_HOME_DIR" -mindepth 1 -maxdepth 1 -printf '%f ' 2>/dev/null)"
  echo "    TMPDIR leftovers: $(find "$TMPDIR" -mindepth 1 -maxdepth 1 -printf '%f ' 2>/dev/null)"
}

# signal_at_host_prompt <label> <SIG>: decline target 1, wait for the host
# prompt, then send <SIG> to the install.sh bash process.
signal_at_host_prompt() {
  local out="$S/out.$2.txt" pid
  : > "$out"
  { printf 'n\n'; sleep 12; } | env -u CLAUDECODE script -qec "bash '$INSTALL'" /dev/null > "$out" 2>&1 &
  for _i in $(seq 150); do grep -q 'Install these files' "$out" && break; sleep 0.1; done
  pid="$(/usr/bin/pgrep -f "^bash $INSTALL\$" | head -n 1)"
  echo "### $1: host prompt reached: $(grep -c 'Install these files' "$out"); copies before signal: $(find "$CLAUDE_HOME_DIR" -maxdepth 1 -name '.cw-new.*' -printf '%f ' 2>/dev/null)"
  kill "-$2" "$pid"
  for _i in $(seq 50); do kill -0 "$pid" 2>/dev/null || break; sleep 0.1; done
  echo "    install.sh pid $pid alive after $2: $(kill -0 "$pid" 2>/dev/null && echo yes || echo no)"
  wait 2>/dev/null
  state
}

echo "== R2-a: first install (dest absent), answer n at the host prompt"
fake_repo
printf 'n\nn\n' | env -u CLAUDECODE script -qec "bash '$INSTALL'" /dev/null > "$S/out.n.txt" 2>&1
echo "    review names the copies: $(grep -c 'are the copies to install\|ADD .*/.claude/' "$S/out.n.txt"); aborted: $(grep -c 'Aborted. Nothing was changed. (host' "$S/out.n.txt")"
state

for sig in TERM INT HUP; do
  echo "== R2-b: first install, SIG$sig at the host prompt"
  fake_repo
  signal_at_host_prompt "SIG$sig" "$sig"
done

echo "== R2-c: existing dest, SIGTERM at the host prompt"
fake_repo
mkdir -p "$CLAUDE_HOME_DIR"; printf 'old\n' > "$CLAUDE_HOME_DIR/CLAUDE.md"; printf 'u\n' > "$CLAUDE_HOME_DIR/settings.json"
signal_at_host_prompt "existing dest SIGTERM" TERM
echo "    CLAUDE.md still old: $(cat "$CLAUDE_HOME_DIR/CLAUDE.md")"

echo "== A1-a: post-copy mismatch on a REINSTALL (a cp stub alters devcontainer.json as it lands)"
fake_repo
bash "$INSTALL" --yes </dev/null > "$S/out.a1-first.txt" 2>&1
echo "    first install exit $?; blessed: $(grep -c BLESS-STUB "$S/out.a1-first.txt")"
mkdir -p "$CLAUDE_DEVC_CONFIG_DIR/projects/p1"; printf 'reg\n' > "$CLAUDE_DEVC_CONFIG_DIR/projects/p1/egress.txt"
printf 'marker-of-bless\n' > "$CLAUDE_DEVC_CONFIG_DIR/.blessed-manifest-probe"
printf '{"v":2}\n' > "$ROOT/devcontainer-config/devcontainer.json"
git -C "$ROOT" -c user.email=t@t -c user.name=t commit -qam v2
mkdir -p "$S/cpstub"
# shellcheck disable=SC2016  # the stub body is literal; its $@ expands when the stub runs
printf '#!/bin/bash\n%s "$@" || exit\ncase "${@: -1}" in */cd/devcontainer.json) echo TAMPERED >> "${@: -1}";; esac\n' "$(command -v cp)" > "$S/cpstub/cp"
chmod +x "$S/cpstub/cp"
rc=0; PATH="$S/cpstub:$PATH" bash "$INSTALL" --yes </dev/null > "$S/out.a1.txt" 2>&1 || rc=$?
echo "    second install exit $rc; blessed: $(grep -c BLESS-STUB "$S/out.a1.txt"); message: $(grep -c 'differs from what the review' "$S/out.a1.txt")"
echo "    \$DEST entries now: $(find "$CLAUDE_DEVC_CONFIG_DIR" -mindepth 1 -maxdepth 1 -printf '%f ')"
echo "    \$DEST/projects kept: $(find "$CLAUDE_DEVC_CONFIG_DIR/projects" -type f -printf '%P ')"
echo "    bin link: $(readlink "$CLAUDE_DEVC_BIN_DIR/cc-isolated"); target exists: $([ -e "$CLAUDE_DEVC_BIN_DIR/cc-isolated" ] && echo yes || echo no)"
rc=0; "$CLAUDE_DEVC_BIN_DIR/cc-isolated" --list > "$S/out.a1-run.txt" 2>&1 || rc=$?
echo "    running the bin link: exit $rc ($(head -n 1 "$S/out.a1-run.txt"))"

echo "== A1-b: first install, the same post-copy mismatch"
fake_repo
rc=0; PATH="$S/cpstub:$PATH" bash "$INSTALL" --yes </dev/null > "$S/out.a1b.txt" 2>&1 || rc=$?
echo "    exit $rc; blessed: $(grep -c BLESS-STUB "$S/out.a1b.txt")"
echo "    \$DEST entries now: $(find "$CLAUDE_DEVC_CONFIG_DIR" -mindepth 1 -maxdepth 1 -printf '%f ')"
echo "    bin link present: $([ -L "$CLAUDE_DEVC_BIN_DIR/cc-isolated" ] && echo yes || echo no)"

echo "== probe dir: $S"
