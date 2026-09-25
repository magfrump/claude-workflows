#!/usr/bin/env bash
# Probe the doc claims of c460912: the NOTE count per run with docker
# unreachable, DOCKER_HOST/DOCKER_CONTEXT reaching docker, and an in-session
# run exiting 1 at startup. Hermetic: temp HOME, no system git config,
# throwaway fake repo, destinations under a temp dir. Section 3 uses the REAL
# pgrep (read-only: it lists this uid's processes, which include the Claude
# Code session running this probe); docker is always a stub.
# Usage: probe-docs.sh <path to install.sh under test>
set -uo pipefail

INSTALL_SRC="$1"
S="$(mktemp -d "${TMPDIR:-/tmp}/q058p2-docs.XXXXXX")"
export HOME="$S/home" TMPDIR="$S/tmp" GIT_CONFIG_NOSYSTEM=1 SHELL=/bin/bash
export CLAUDE_HOME_DIR="$HOME/.claude" CLAUDE_DEVC_CONFIG_DIR="$HOME/.config/cd" CLAUDE_DEVC_BIN_DIR="$HOME/.local/bin"
unset CLAUDE_CONFIG_DIR
mkdir -p "$HOME" "$TMPDIR" "$S/stub" "$S/stubnopgrep"
printf '#!/bin/bash\nexit 1\n' > "$S/stub/pgrep"
# shellcheck disable=SC2016  # stub body is literal; it expands when the stub runs
printf '#!/bin/bash\necho "DOCKER_HOST=${DOCKER_HOST-unset} DOCKER_CONTEXT=${DOCKER_CONTEXT-unset}" >> "%s/docker.log"\necho "Cannot connect to the Docker daemon" >&2\nexit 1\n' "$S" > "$S/stub/docker"
cp "$S/stub/docker" "$S/stubnopgrep/docker"
chmod +x "$S/stub/pgrep" "$S/stub/docker" "$S/stubnopgrep/docker"
BASEPATH="$PATH"
ROOT="$S/repo"
INSTALL="$ROOT/devcontainer-config/install.sh"
cfg="$ROOT/devcontainer-config"
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
git -C "$ROOT" init -q && git -C "$ROOT" add -A && git -C "$ROOT" -c user.email=t@t -c user.name=t commit -q -m init

reset_dest() { rm -rf "$CLAUDE_HOME_DIR" "$CLAUDE_DEVC_CONFIG_DIR" "$CLAUDE_DEVC_BIN_DIR"; }
notes() { printf 'exit %s; NOTE lines: %s' "$1" "$(grep -c '^NOTE: docker is unreachable' "$2")"; }

echo "== 1. NOTE lines per run, docker unreachable (stub pgrep: no agent)"
export PATH="$S/stub:$BASEPATH"
reset_dest; rc=0; env -u CLAUDECODE bash "$INSTALL" </dev/null > "$S/o1" 2>&1 || rc=$?
echo "   no TTY, no --yes (target 1 declined at EOF, host skipped): $(notes "$rc" "$S/o1")"
reset_dest; rc=0; env -u CLAUDECODE bash "$INSTALL" --yes </dev/null > "$S/o2" 2>&1 || rc=$?
echo "   --yes (target 1 installed, host skipped):                  $(notes "$rc" "$S/o2")"
reset_dest; rc=0; printf 'n\ny\n' | env -u CLAUDECODE script -qec "bash '$INSTALL'" /dev/null > "$S/o3" 2>&1 || rc=$?
echo "   pty n,y (target 1 declined, host installed):               $(notes "$rc" "$S/o3")"
reset_dest; rc=0; printf 'y\ny\n' | env -u CLAUDECODE script -qec "bash '$INSTALL'" /dev/null > "$S/o4" 2>&1 || rc=$?
echo "   pty y,y (both installed):                                  $(notes "$rc" "$S/o4")"
reset_dest; rc=0; printf 'n\nn\n' | env -u CLAUDECODE script -qec "bash '$INSTALL'" /dev/null > "$S/o5" 2>&1 || rc=$?
echo "   pty n,n (both declined):                                   $(notes "$rc" "$S/o5")"

echo "== 2. DOCKER_HOST / DOCKER_CONTEXT reach the docker call unchanged"
: > "$S/docker.log"
reset_dest; DOCKER_HOST=tcp://probe.invalid:2375 DOCKER_CONTEXT=probe-ctx env -u CLAUDECODE bash "$INSTALL" --yes </dev/null > /dev/null 2>&1
sort -u "$S/docker.log" | sed 's/^/   docker saw: /'

echo "== 3. In-session run, REAL pgrep (this probe runs inside a Claude Code session)"
export PATH="$S/stubnopgrep:$BASEPATH"
reset_dest; rm -rf "$cfg/claude-home"; rc=0; env -u CLAUDECODE bash "$INSTALL" --yes </dev/null > "$S/o6" 2>&1 || rc=$?
echo "   exit $rc; refused at startup: $(grep -c 'Nothing was staged or installed' "$S/o6"); staged anything: $([ -e "$cfg/claude-home" ] && echo yes || echo no); blessed: $(grep -c BLESS-STUB "$S/o6")"
grep -m1 'Claude Code processes of uid' "$S/o6" | sed 's/^/   /'
echo "== probe dir: $S"
