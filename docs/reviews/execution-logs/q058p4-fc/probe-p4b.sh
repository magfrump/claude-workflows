#!/usr/bin/env bash
# Pass-4 fact-check, part b: what a MISSING item at the host links_in site lets
# through when it reappears before the hash, plus the exact lines of B1 and C1a.
# Hermetic, same scaffolding as probe-p4.sh. A find stub (logs nothing, then
# execs the real find) stands in for a writer acting between links_in and the
# hash, a window that is otherwise microseconds wide.
# Usage: probe-p4b.sh <path to install.sh under test>
set -uo pipefail

INSTALL_SRC="$1"
S="$(mktemp -d "${TMPDIR:-/tmp}/q058p4b.XXXXXX")"
export HOME="$S/home" TMPDIR="$S/tmp" GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL="$S/global.gitconfig"
export CLAUDE_HOME_DIR="$HOME/.claude" CLAUDE_DEVC_CONFIG_DIR="$HOME/.config/claude-devcontainer" CLAUDE_DEVC_BIN_DIR="$HOME/.local/bin"
export SHELL=/bin/bash
unset CLAUDE_CONFIG_DIR CLAUDECODE GIT_DIR GIT_WORK_TREE
mkdir -p "$HOME" "$TMPDIR" "$S/stub"
: > "$GIT_CONFIG_GLOBAL"
REALCP="$(command -v cp)"
REALFIND="$(command -v find)"
STUB="$S/stub"
export S REALCP REALFIND
stub_default() {
  rm -f "$STUB"/*
  printf '#!/bin/bash\nexit 1\n' > "$STUB/pgrep"
  printf '#!/bin/bash\nexit 0\n' > "$STUB/docker"
  chmod +x "$STUB/pgrep" "$STUB/docker"
}
stub_default
export PATH="$STUB:$PATH"

ROOT="$S/repo"
INSTALL="$ROOT/devcontainer-config/install.sh"
G() { git -c user.email=t@t -c user.name=t "$@"; }
fake_repo() {
  local cfg="$ROOT/devcontainer-config" f
  chmod -R u+rwx "$S" 2>/dev/null
  rm -rf "$ROOT" "$HOME/.claude" "$HOME/.config" "$HOME/.local" "${TMPDIR:?}"/* "$S"/aside "$S"/victim "$S"/flag
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
stub_cp() {
  printf '#!/bin/bash\n"%s" "$@" || exit\ndst="${@: -1}"; srcarg="${@: -2:1}"\ncase "$dst" in %s) %s ;; esac\nexit 0\n' \
    "$REALCP" "$1" "$2" > "$STUB/cp"
  chmod +x "$STUB/cp"
}
# stub_find_once <snippet>: before the first `find <.cw-new.CLAUDE.md> -printf`
# (tree_hash's first call, right after links_in), run the snippet once.
stub_find_once() {
  printf '#!/bin/bash\nif [ -e "$S/flag" ] && [ "${1##*/}" = .cw-new.CLAUDE.md ] && [ "${2:-}" = -printf ]; then rm -f "$S/flag"; %s; fi\nexec "$REALFIND" "$@"\n' \
    "$1" > "$STUB/find"
  chmod +x "$STUB/find"
}
pty() {
  local input="$1"; shift
  # shellcheck disable=SC2016  # expanded by the inner bash
  bash -c 'set -o pipefail; printf "%b" "$1" | script -qec "$2" /dev/null | tr -d "\r"' _ "$input" "$*"
}
hdr() { echo; echo "######## $*"; }
filt() { sed "s|$S|\$S|g" "$S/out" | grep -v 'setlocale'; }

echo "== $(date -u +%Y-%m-%dT%H:%M:%SZ) install.sh: $INSTALL_SRC ($(wc -l < "$INSTALL_SRC") lines)"

hdr "M1 host: .cw-new.manifest missing at links_in, back as a LINK before the hash (pty, n then y)"
fake_repo
echo "victim-before" > "$S/target-file"
# shellcheck disable=SC2016
stub_cp '*/.claude/.cw-new.manifest' '"$REALCP" "$dst" "$S/victim"; rm -f "$dst"; touch "$S/flag"'
# shellcheck disable=SC2016
stub_find_once 'cat "$S/victim" > "$S/target-file"; ln -s "$S/target-file" "$CLAUDE_HOME_DIR/.cw-new.manifest"'
pty 'n\ny\n' bash "$INSTALL" > "$S/out" 2>&1; rc=$?
echo "rc=$rc"; filt | grep -E '^(ERROR|Installed into|Install these)|symlink' | head
echo "  installed manifest is a link: $([ -L "$CLAUDE_HOME_DIR/.claude-workflows-manifest" ] && echo "yes -> $(readlink "$CLAUDE_HOME_DIR/.claude-workflows-manifest" | sed "s|$S|\$S|")" || echo no)"
echo "  link target got the install's append: $(grep -c '^installed_at=' "$S/target-file")"
stub_default

hdr "M2 host: .cw-new.hooks missing at links_in, back with a link inside before the hash (pty, n then y)"
fake_repo
printf '#!/bin/bash\necho agent-writable\n' > "$S/agent.sh"
# shellcheck disable=SC2016
stub_cp '*/.claude/.cw-new.hooks' 'mv "$dst" "$S/aside"; touch "$S/flag"'
# shellcheck disable=SC2016
stub_find_once 'ln -s "$S/agent.sh" "$S/aside/evil.sh"; mv "$S/aside" "$CLAUDE_HOME_DIR/.cw-new.hooks"'
pty 'n\ny\n' bash "$INSTALL" > "$S/out" 2>&1; rc=$?
echo "rc=$rc"; filt | grep -E '^(ERROR|Installed into|Install these)|evil' | head
echo "  installed hooks/evil.sh is a link: $([ -L "$CLAUDE_HOME_DIR/hooks/evil.sh" ] && echo yes || echo no)"
stub_default

hdr "C1a' (lines) host reinstall: .cw-new.guides removed right after its copy: what the review showed"
fake_repo
pty 'n\ny\n' bash "$INSTALL" > /dev/null 2>&1
printf 'guide v2\n' > "$ROOT/guides/g.md"; G -C "$ROOT" commit -qam v2
# shellcheck disable=SC2016
stub_cp '*/.claude/.cw-new.guides' 'rm -rf "$dst"'
pty 'n\ny\n' bash "$INSTALL" > "$S/out" 2>&1; rc=$?
echo "rc=$rc"; filt | sed -n '/=== Host target/,$p'
stub_default

hdr "B1' (lines) stage site unreadable: the refusal's full text"
fake_repo
# shellcheck disable=SC2016
stub_cp '*/devcontainer-config/claude-home/' 'chmod 000 "${srcarg%/claude-home/.}/egress"'
rc=0; bash "$INSTALL" --yes </dev/null > "$S/out" 2>&1 || rc=$?
echo "rc=$rc"; filt | grep -A4 '^ERROR'
echo "  stage left in TMPDIR: $(compgen -G "$TMPDIR/cw-devc-stage.*" | wc -l)"
stub_default

chmod -R u+rwx "$S" 2>/dev/null
rm -rf "$S"
echo; echo "== done $(date -u +%Y-%m-%dT%H:%M:%SZ)"
