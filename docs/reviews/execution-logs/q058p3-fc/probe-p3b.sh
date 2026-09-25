#!/usr/bin/env bash
# Pass-3 fact-check probes, part b (P8 with a corrected perl stub; P9b) against install.sh at 516124d.
# Hermetic: temp HOME/TMPDIR, GIT_CONFIG_NOSYSTEM=1, empty GIT_CONFIG_GLOBAL,
# stubbed pgrep/docker, a throwaway fake repo holding a COPY of install.sh.
# Never touches the real ~/.claude or ~/.config.
# Usage: probe-p3.sh <path to install.sh under test>
set -uo pipefail

INSTALL_SRC="$1"
S="$(mktemp -d "${TMPDIR:-/tmp}/q058p3.XXXXXX")"
export HOME="$S/home" TMPDIR="$S/tmp" GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL="$S/empty.gitconfig"
export CLAUDE_HOME_DIR="$HOME/.claude" CLAUDE_DEVC_CONFIG_DIR="$HOME/.config/claude-devcontainer" CLAUDE_DEVC_BIN_DIR="$HOME/.local/bin"
export SHELL=/bin/bash
unset CLAUDE_CONFIG_DIR CLAUDECODE GIT_DIR GIT_WORK_TREE
mkdir -p "$HOME" "$TMPDIR" "$S/stub"
: > "$GIT_CONFIG_GLOBAL"
REALCP="$(command -v cp)"
STUB="$S/stub"
stub_default() {
  rm -f "$STUB"/*
  printf '#!/bin/bash\nexit 1\n' > "$STUB/pgrep"
  printf '#!/bin/bash\nexit 0\n' > "$STUB/docker"
  chmod +x "$STUB/pgrep" "$STUB/docker"
}
stub_default
BASEPATH="$STUB:$PATH"
export PATH="$BASEPATH"

ROOT="$S/repo"
INSTALL="$ROOT/devcontainer-config/install.sh"
G() { git -c user.email=t@t -c user.name=t "$@"; }
fake_repo() {
  local cfg="$ROOT/devcontainer-config" f
  chmod -R u+w "$S" 2>/dev/null
  rm -rf "$ROOT" "$HOME/.claude" "$HOME/.config" "$HOME/.local"
  mkdir -p "$cfg/egress" "$ROOT/global-instructions" "$ROOT/skills/a" "$ROOT/workflows" \
           "$ROOT/guides" "$ROOT/patterns" "$ROOT/hooks/lib" "$ROOT/scripts"
  "$REALCP" "$INSTALL_SRC" "$cfg/install.sh"
  printf 'g\n' > "$ROOT/global-instructions/CLAUDE.md"
  printf 'skill a\n' > "$ROOT/skills/a/SKILL.md"
  for f in workflows/w.md guides/g.md patterns/p.md hooks/lib/x.sh hooks/wiring.json scripts/s.sh; do
    printf 'x\n' > "$ROOT/$f"
  done
  printf '#!/bin/bash\nexit 0\n' > "$ROOT/hooks/h.sh"
  for f in devcontainer.json Dockerfile init-firewall.sh cc-sni-proxy.py link-claude-home.sh; do
    printf 'stub %s\n' "$f" > "$cfg/$f"
  done
  printf '#!/usr/bin/env bash\necho "BLESS-STUB $*"\n' > "$cfg/cc-isolated.sh"
  chmod +x "$cfg/cc-isolated.sh"
  printf 'api.anthropic.com\n' > "$cfg/egress/base.txt"
  printf 'devcontainer-config/claude-home/\n' > "$ROOT/.gitignore"
  git -C "$ROOT" init -q
  G -C "$ROOT" add -A
  G -C "$ROOT" commit -q -m init
}
# pty <answers> <cmd...>: run under a pty, answers fed on stdin.
pty() {
  local input="$1"; shift
  # shellcheck disable=SC2016  # expanded by the inner bash
  bash -c 'set -o pipefail; printf "%b" "$1" | script -qec "$2" /dev/null | tr -d "\r"' _ "$input" "$*"
}
# pty_feed <shell snippet> <cmd...>
pty_feed() {
  local feed="$1"; shift
  # shellcheck disable=SC2016  # expanded by the inner bash
  bash -c 'set -o pipefail; { eval "$1"; } | script -qec "$2" /dev/null | tr -d "\r"' _ "$feed" "$*"
}
hdr() { echo; echo "######## $*"; }

echo "== $(date -u +%Y-%m-%dT%H:%M:%SZ) git: $(git --version); install.sh: $INSTALL_SRC"

# --- P8 (fixed stub: only vis's `perl -pe` is intercepted) ---------------------------
hdr "P8 vis fails only on a MODE line; the only change is a chmod"
fake_repo
pty 'n\ny\n' bash "$INSTALL" > /dev/null 2>&1
chmod +x "$ROOT/guides/g.md"; G -C "$ROOT" commit -qam mode
realperl="$(command -v perl)"
printf '#!/bin/bash\n[ "$1" = -pe ] || exec %s "$@"\nin="$(cat; echo x)"; in="${in%%x}"\ncase "$in" in MODE*) exit 3;; esac\nprintf "%%s" "$in" | %s "$@"\n' "$realperl" "$realperl" > "$STUB/perl"; chmod +x "$STUB/perl"
pty 'n\nn\n' bash "$INSTALL" > "$S/out" 2>&1; rc=$?
echo "rc=$rc"; sed -n '/Host target/,$p' "$S/out" | sed "s|$S|\$S|g"
stub_default
echo "control, same repo, real perl:"
pty 'n\nn\n' bash "$INSTALL" > "$S/out" 2>&1; rc=$?
echo "rc=$rc"; grep -E '^MODE|none|Install these' "$S/out" | sed "s|$S|\$S|g"

# --- P9b: links_in fails on its LAST item (claude-home) after the devcontainer copy -------
hdr "P9b devcontainer: unreadable dir planted in the claude-home copy (links_in's last find fails)"
fake_repo
bash "$INSTALL" --yes </dev/null > /dev/null 2>&1
printf '{"v":2}\n' > "$ROOT/devcontainer-config/devcontainer.json"; G -C "$ROOT" commit -qam v2
printf '#!/bin/bash\n%s "$@" || exit\ncase "${@: -1}" in */claude-devcontainer/cc-isolated.sh) echo "echo TAMPERED" >> "${@: -1}";; */claude-devcontainer/claude-home) mkdir -p "${@: -1}/locked" && chmod 000 "${@: -1}/locked";; esac\n' "$REALCP" > "$STUB/cp"
chmod +x "$STUB/cp"
rc=0; bash "$INSTALL" --yes </dev/null > "$S/out" 2>&1 || rc=$?
echo "rc=$rc"; sed "s|$S|\$S|g" "$S/out" | grep -vE '^(NOTE|Checking|Canonical|Installed|===|$)' | tail -8
echo "cc-isolated.sh left in DEST: $([ -e "$CLAUDE_DEVC_CONFIG_DIR/cc-isolated.sh" ] && echo yes || echo no); TAMPERED lines in it: $(grep -c TAMPERED "$CLAUDE_DEVC_CONFIG_DIR/cc-isolated.sh" 2>/dev/null); bin link resolves: $([ -e "$CLAUDE_DEVC_BIN_DIR/cc-isolated" ] && echo yes || echo no); blessed: $(grep -c BLESS-STUB "$S/out")"
chmod -R u+rwx "$CLAUDE_DEVC_CONFIG_DIR" 2>/dev/null
stub_default

echo; echo "== done $(date -u +%Y-%m-%dT%H:%M:%SZ)"
chmod -R u+w "$S" 2>/dev/null
rm -rf "$S"
